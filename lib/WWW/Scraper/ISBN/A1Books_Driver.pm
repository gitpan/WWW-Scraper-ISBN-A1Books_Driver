package WWW::Scraper::ISBN::A1Books_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.01';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::A1Books_Driver - Search driver for A1Books online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from A1Books online book catalog

=cut

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use WWW::Mechanize;

###########################################################################
# Constants

use constant	SEARCH	=> 'http://www.a1books.co.in/searchresult.do?searchType=books&fromSearchBox=Y&partnersite=a1india&imageField=Go&keyword=';
use constant	IN2MM   => 25.4;        # number of inches in a millimetre (mm)
use constant	LB2G    => 453.59237;   # number of grams in a pound (lb)

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the A1Books
server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn          (now returns isbn13)
  isbn10        
  isbn13
  ean13         (industry name)
  author
  title
  book_link
  image_link
  description
  pubdate
  publisher
  binding       (if known)
  pages         (if known)
  weight        (if known) (in grammes)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)

The book_link and image_link refer back to the A1Books website.

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

	my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

    eval { $mech->get( SEARCH . $isbn ) };
    return $self->handler("A1Books website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

	# The Book page
    my $html = $mech->content();

	return $self->handler("Failed to find that book on A1Books website.")
		if($html =~ m!No results found.!si);
    
#print STDERR "\n# content1=[\n$html\n]\n";

    my $data;
    ($data->{image})                    = $html =~ m!'(http://images.a1books.co.in/rimages/catalog\?largeImage=\d+[^']+)'!si;
    ($data->{thumb})                    = $html =~ m!<img name="smenu1" src="(http://images.a1books.co.in/rimages/catalog[^"]+)"!si;
    ($data->{isbn13})                   = $html =~ m!<span class="label">\s*ISBN-13:\s*</span>\s*</td>\s*<td>&nbsp;</td>\s*<td align=left nowrap valign=top>\s*([^<]+)\s*</td>!si;
    ($data->{isbn10})                   = $html =~ m!<span class="label">\s*ISBN:\s*</span>\s*</td>\s*<td>&nbsp;</td>\s*<td align=left nowrap valign=top>\s*([^<]+)\s*</td>!si;
    ($data->{title},$data->{author})    = $html =~ m!<h1 class="title3">\s*([^<]+)\s*</h1>\s*([^<]+)!si;
    ($data->{publisher})                = $html =~ m!<span class="label">\s*Publisher:\s*</span>\s*</td>\s*<td>&nbsp;</td>\s*<td align=left nowrap valign=top>\s*([^<]+)\s*</td>!si;
    ($data->{pubdate})                  = $html =~ m!<span class="label">\s*Pub. Year:\s*</span>\s*</td>\s*<td>&nbsp;</td>\s*<td align=left nowrap valign=top>\s*([^<]+)\s*</td>!si;
    ($data->{binding})                  = $html =~ m!<span class="label">\s*Binding:\s*</span>\s*</td>\s*<td>&nbsp;</td>\s*<td align=left nowrap valign=top>\s*([^<]+)\s*</td>!si;
    ($data->{pages})                    = $html =~ m!<span class="label">\s*Pages:&nbsp;\s*</span>\s*</td>\s*<td>&nbsp;</td>\s*<td align=left nowrap valign=top>\s*([\d.]+)\s*</td>\s*</tr>!si;
    ($data->{weight})                   = $html =~ m!<span class="label">\s*Weight:&nbsp;\s*</span>\s*</td>\s*<td>&nbsp;</td>\s*<td align=left nowrap valign=top>\s*([\d.]+) Pounds\s*</td>\s*</tr>!si;
    ($data->{height},$data->{width})    = $html =~ m!<tr>\s*<td valign=top align=right nowrap>\s*<span class="label">\s*Dimension:\s*</span>\s*</td>\s*<td>&nbsp;</td>\s*<td align=left nowrap valign=top>\s*([\d.]+) x ([\d.]+) x ([\d.]+) Inches\s*</td>!si;
    ($data->{description})              = $html =~ m!<span class="label">\s*Description:\s*</span>\s*<span class="annotation">\s*<div align=justify>(.*?)</div>\s*</span>!si;
    ($data->{description})              = $html =~ m!<span class="label">\s*Description:\s*</span>\s*<span class="annotation">\s*<div align=justify>([^<]+)!si  unless($data->{description});

    $data->{weight} = int($data->{weight} * LB2G)   if($data->{weight});
    $data->{width}  = int($data->{width}  * IN2MM)  if($data->{width});
    $data->{height} = int($data->{height} * IN2MM)  if($data->{height});
    $data->{author}         =~ s!<[^>]+>!!g         if($data->{author});
    $data->{publisher}      =~ s!<[^>]+>!!g         if($data->{publisher});
    $data->{description}    =~ s!</?br\s*/?>!\n!gsi if($data->{description});
    $data->{description}    =~ s!<[^>]+>!!gsi       if($data->{description});
    $data->{description}    =~ s!&nbsp;! !gsi       if($data->{description});

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

	return $self->handler("Could not extract data from A1Books result page.")
		unless(defined $data);

	# trim top and tail
	foreach (keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

	my $bk = {
		'ean13'		    => $data->{isbn13},
		'isbn13'		=> $data->{isbn13},
		'isbn10'		=> $data->{isbn10},
		'isbn'			=> $data->{isbn13},
		'author'		=> $data->{author},
		'title'			=> $data->{title},
		'book_link'		=> $mech->uri(),
		'image_link'	=> $data->{image},
		'thumb_link'	=> $data->{thumb},
		'description'	=> $data->{description},
		'pubdate'		=> $data->{pubdate},
		'publisher'		=> $data->{publisher},
		'binding'	    => $data->{binding},
		'pages'		    => $data->{pages},
		'weight'		=> $data->{weight},
		'width'		    => $data->{width},
		'height'		=> $data->{height}
	};

#use Data::Dumper;
#print STDERR "\n# book=".Dumper($bk);

    $self->book($bk);
	$self->found(1);
	return $self->book;
}

1;
__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-A1Books_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2004-2010 Barbie for Miss Barbell Productions

  This module is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut

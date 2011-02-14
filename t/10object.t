#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 40;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'A1Books';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '0099547937' => [
        [ 'is',     'isbn',         '9780099547938' ],
        [ 'is',     'isbn10',       '0099547937'    ],
        [ 'is',     'isbn13',       '9780099547938' ],
        [ 'is',     'ean13',        '9780099547938' ],
        [ 'is',     'title',        'Ford Country'  ],
        [ 'is',     'author',       'Grisham, John' ],
        [ 'like',   'publisher',    qr|Random House|],
        [ 'is',     'pubdate',      undef           ],
        [ 'is',     'binding',      'Paperback'     ],
        [ 'is',     'pages',        272             ],
        [ 'is',     'width',        undef           ],
        [ 'is',     'height',       undef           ],
        [ 'is',     'weight',       undef           ],
        [ 'is',     'image_link',   'http://images.a1books.co.in/rimages/catalog?largeImage=0099547937&id=57-100-177-130-228-202-113-14' ],
        [ 'is',     'thumb_link',   'http://images.a1books.co.in/rimages/catalog?id=57-100-177-130-228-202-113-14&itemCode=0099547937' ],
        [ 'like',   'description',  qr|Worldwide No.1 bestseller John Grisham takes you into the heart| ],
        [ 'like',   'book_link',    qr|http://www.a1books.co.in/searchresult.do\?searchType=books&fromSearchBox=Y&partnersite=a1india&imageField=Go&keyword=0099547937| ]
    ],
    '9780471430490' => [
        [ 'is',     'isbn',         '9780471430490'             ],
        [ 'is',     'isbn10',       '0471430498'                ],
        [ 'is',     'isbn13',       '9780471430490'             ],
        [ 'is',     'ean13',        '9780471430490'             ],
        [ 'is',     'author',       ''                          ],
        [ 'is',     'title',        q|The Viking|               ],
        [ 'is',     'publisher',    'Wiley'  ],
        [ 'is',     'pubdate',      '2004'                      ],
        [ 'is',     'binding',      'Hardcover'                 ],
        [ 'is',     'pages',        224                         ],
        [ 'is',     'width',        147                         ],
        [ 'is',     'height',       226                         ],
        [ 'is',     'weight',       362                         ],
        [ 'is',     'image_link',   'http://images.a1books.co.in/rimages/catalog?largeImage=0471430498&id=169-112-134-7-80-130-77-66'   ],
        [ 'is',     'thumb_link',   'http://images.a1books.co.in/rimages/catalog?id=169-112-134-7-80-130-77-66&itemCode=0471430498'     ],
        [ 'like',   'description',  qr|One moment they were a mere speck on the sea;|   ],
        [ 'like',   'book_link',    qr|http://www.a1books.co.in/searchresult.do\?searchType=books&fromSearchBox=Y&partnersite=a1india&imageField=Go&keyword=9780471430490| ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }


###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests+1   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    # this ISBN doesn't exist
	my $isbn = "1234567890";
    my $record;

    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    }
    elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
		like($record->error,qr/Failed to find that book|website appears to be unavailable/);
    }

    for my $isbn (keys %tests) {
        $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);
            skip "Book unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /Failed to find that book/ || !$record->found);

            unless($record->found) {
                diag($record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $book = $record->book;
            for my $test (@{ $tests{$isbn} }) {
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

            }

            #use Data::Dumper;
            #diag("book=[".Dumper($book)."]");
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    eval { system($cmd) }; 
    if($@) {                # can't find ping, or wrong arguments?
        diag();
        return 1;
    }

    my $retcode = $? >> 8;  # ping returns 1 if unable to connect
    return $retcode;
}

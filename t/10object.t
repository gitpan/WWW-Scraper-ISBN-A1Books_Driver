#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 40;
use WWW::Scraper::ISBN;

###########################################################

my $CHECK_DOMAIN = 'www.google.com';

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", 39   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers("A1Books");

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
		like($record->error,qr/Failed to find that book on A1Books website|website appears to be unavailable/);
    }

	$isbn   = "0099547937";
	$record = $scraper->search($isbn);
    my $error  = $record->error || '';

    SKIP: {
        skip "Website unavailable", 19   if($error =~ /website appears to be unavailable/);

        unless($record->found) {
            diag($record->error);
        } else {
            is($record->found,1);
            is($record->found_in,'A1Books');

            my $book = $record->book;
            is($book->{'isbn'},         '9780099547938'         ,'.. isbn found');
            is($book->{'isbn10'},       '0099547937'            ,'.. isbn10 found');
            is($book->{'isbn13'},       '9780099547938'         ,'.. isbn13 found');
            is($book->{'ean13'},        '9780099547938'         ,'.. ean13 found');
            is($book->{'title'},        'Ford Country'          ,'.. title found');
            is($book->{'author'},       'Grisham, John'         ,'.. author found');
            like($book->{'book_link'},  qr|http://www.a1books.co.in/searchresult.do\?searchType=books&fromSearchBox=Y&partnersite=a1india&imageField=Go&keyword=0099547937|);
            is($book->{'image_link'},   'http://images.a1books.co.in/rimages/catalog?largeImage=0099547937&id=57-100-177-130-228-202-113-14');
            is($book->{'thumb_link'},   'http://images.a1books.co.in/rimages/catalog?id=57-100-177-130-228-202-113-14&itemCode=0099547937');
            like($book->{'description'},qr|Worldwide No.1 bestseller John Grisham takes you into the heart|);
            is($book->{'publisher'},    'Century'               ,'.. publisher found');
            is($book->{'pubdate'},      undef                   ,'.. pubdate found');
            is($book->{'binding'},      'Paperback'             ,'.. binding found');
            is($book->{'pages'},        272                     ,'.. pages found');
            is($book->{'width'},        undef                   ,'.. width found');
            is($book->{'height'},       undef                   ,'.. height found');
            is($book->{'weight'},       undef                   ,'.. weight found');
        }
    }

    $isbn   = "9780471430490";
	$record = $scraper->search($isbn);
    $error  = $record->error || '';

    SKIP: {
        skip "Website unavailable", 19   if($error =~ /website appears to be unavailable/);

        unless($record->found) {
            diag($record->error);
        } else {
            is($record->found,1);
            is($record->found_in,'A1Books');

            my $book = $record->book;
            is($book->{'isbn'},         '9780471430490'         ,'.. isbn found');
            is($book->{'isbn10'},       '0471430498'            ,'.. isbn10 found');
            is($book->{'isbn13'},       '9780471430490'         ,'.. isbn13 found');
            is($book->{'ean13'},        '9780471430490'         ,'.. ean13 found');
            is($book->{'author'},       ''                      ,'.. author found');
            is($book->{'title'},        q|The Viking|           ,'.. title found');
            like($book->{'book_link'},  qr|http://www.a1books.co.in/searchresult.do\?searchType=books&fromSearchBox=Y&partnersite=a1india&imageField=Go&keyword=9780471430490|);
            is($book->{'image_link'},   'http://images.a1books.co.in/rimages/catalog?largeImage=0471430498&id=169-112-134-7-80-130-77-66');
            is($book->{'thumb_link'},   'http://images.a1books.co.in/rimages/catalog?id=169-112-134-7-80-130-77-66&itemCode=0471430498');
            like($book->{'description'},qr| One moment they were a mere speck on the sea; |);
            is($book->{'publisher'},    'Wiley'                 ,'.. publisher found');
            is($book->{'pubdate'},      '2004'                  ,'.. pubdate found');
            is($book->{'binding'},      'Hardcover'             ,'.. binding found');
            is($book->{'pages'},        224                     ,'.. pages found');
            is($book->{'width'},        147                     ,'.. width found');
            is($book->{'height'},       226                     ,'.. height found');
            is($book->{'weight'},       362                     ,'.. weight found');

            #use Data::Dumper;
            #diag("book=[".Dumper($book)."]");
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    system("ping -q -c 1 $domain >/dev/null 2>&1");
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}

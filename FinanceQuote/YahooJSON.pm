#!/usr/bin/perl -w
#    This module is based on the Finance::Quote::BSERO module
#    It was first called BOMSE but has been renamed to yahooJSON
#    since it gets a lot of quotes besides Indian
#
#    The code has been modified by Abhijit K to
#    retrieve stock information from Yahoo Finance through json calls
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#    02110-1301, USA

package Finance::Quote::YahooJSON;

require 5.005;

use strict;
use JSON qw( decode_json );
use vars qw($VERSION $YIND_URL_HEAD $YIND_URL_TAIL);
use LWP::UserAgent;
use HTTP::Request::Common;
use HTML::TableExtract;
use Time::Piece;

use HTTP::CookieJar::LWP;
use HTML::Form;
use URI;
use URI::QueryParam;

use threads;
use Thread::Queue;
use Data::Dumper;

# VERSION

my $can_use_threads = eval 'use threads; 1';
### [<now>] can_use_threads : $can_use_threads 

my $YIND_URL_HEAD = 'https://query2.finance.yahoo.com/v11/finance/quoteSummary/?symbols=';
my $YIND_URL_TAIL = '&modules=price,summaryDetail,defaultKeyStatistics';
my $browser = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36';

sub methods {
    return ( yahoo_json => \&yahoo_json,
    );
}
{
    my @labels = qw/name last date isodate volume currency method exchange type
        div_yield eps pe year_range open high low close/;

    sub labels {
        return ( yahoo_json => \@labels,
        );
    }
}

sub yahoo_json {

    my $quoter = shift;
    my @stocks = @_;
    my ( %info, $reply, $url, $te, $ts, $row, @cells, $ce );
    my ( $my_date, $amp_stocks );
    my ( $crumb );
    my $ua = $quoter->user_agent();

    my $cookie_jar = HTTP::CookieJar::LWP->new;
    my $browser = LWP::UserAgent->new(
        cookie_jar        => $cookie_jar,
        agent             => $browser,
        );

    # get Yahoo cookies that are needed for crumb
    my $req = HTTP::Request->new(GET => 'https://login.yahoo.com');
    my $res = $browser->request($req);

    # get the crumb that corrosponds to cookies retrieved previously
    $req->uri('https://query2.finance.yahoo.com/v1/test/getcrumb');
    my $res = $browser->request($req);
    
    $crumb = $res->content;

    ### [<now>]    cookie_jar : $cookie_jar 
    ### [<now>]         crumb : $crumb 

    $ua->cookie_jar( $cookie_jar );

    my $result_q = Thread::Queue->new;
    my $lock_var : shared;

    if ($can_use_threads) {

        my @threads = map {
            threads->create(
                sub {
                    my $stocks = shift;

                    ($amp_stocks = $stocks) =~ s/&/%26/g;
                    $url = $YIND_URL_HEAD . $amp_stocks . '&crumb=' . $crumb . $YIND_URL_TAIL;

                    ### [<now>:THREAD]    url : $url 
                    my $result = $ua->request( GET $url );
                    ### [<now>:THREAD] result : $result

                    lock ( $lock_var );
                    $result_q->enqueue( $stocks );
                    $result_q->enqueue( $result );
                }, 
            $_)
        } @stocks;

        $_->join() for @threads;

        $result_q->end;
        
    } else {

        foreach my $stocks (@stocks) {       ### Evaluating |===[%]    |
            # Issue 202 - Fix symbols with Ampersand
            # Can also be written as
            # $amp_stocks = $stocks =~ s/&/%26/gr;
            ($amp_stocks = $stocks) =~ s/&/%26/g;
            $url = $YIND_URL_HEAD . $amp_stocks . '&crumb=' . $crumb . $YIND_URL_TAIL;

            ### [<now>]    url : $url 
            my $result = $ua->request( GET $url );
            ### [<now>] result : $result

            $result_q->enqueue( $stocks );
            $result_q->enqueue( $result );
            }

        $result_q->end;

    }

    while (defined (my $stocks = $result_q->dequeue())) {        ### Evaluating |===[%]    |
    
        my $reply   = $result_q->dequeue;

        my $code    = $reply->code;
        my $headers = $reply->headers_as_string;
        my $body    = $reply->content;

        my $desc    = HTTP::Status::status_message($code);
        
        #Response variables available:
        #Response code: 	$code
        #Response description: 	$desc
        #HTTP Headers:		$headers
        #Response body		$body

        $info{ $stocks, "symbol" } = $stocks;

        if ( $code == 200 ) {

            #HTTP_Response succeeded - parse the data
            my $json_data = JSON::decode_json $body;

            # Requests for invalid symbols sometimes return 200 with an empty
            # JSON result array
            my $json_data_count
                = scalar @{ $json_data->{'quoteSummary'}{'result'} };

            if ( $json_data_count < 1 ) {
                $info{ $stocks, "success" } = 0;
                $info{ $stocks, "errormsg" } =
                    "Error retrieving quote for $stocks - no listing for this name found. Please check symbol and the two letter extension (if any)";

            } else {

                my $json_resources_price = $json_data->{'quoteSummary'}{'result'}[0]{'price'};
                my $json_resources_summaryDetail = $json_data->{'quoteSummary'}{'result'}[0]{'summaryDetail'};
                my $json_resources_defaultKeyStatistics = $json_data->{'quoteSummary'}{'result'}[0]{'defaultKeyStatistics'};

                # TODO: Check if $json_response_type is "Quote"
                # before attempting anything else
                my $json_symbol = $json_resources_price->{'symbol'};
                #    || $json_resources->{'resource'}{'fields'}{'symbol'};
                my $json_volume = $json_resources_price->{'regularMarketVolume'}{'raw'};
                my $json_timestamp =
                    $json_resources_price->{'regularMarketTime'};
                my $json_name = $json_resources_price->{'shortName'};
                my $json_type = $json_resources_price->{'quoteType'};
                my $json_price =
                    $json_resources_price->{'regularMarketPrice'}{'raw'};

                $info{ $stocks, "success" } = 1;
                $info{ $stocks, "exchange" } =
                    $json_resources_price->{'exchangeName'};
                $info{ $stocks, "method" } = "yahoo_json";
                $info{ $stocks, "name" }   = $stocks . ' (' . $json_name . ')';
                $info{ $stocks, "type" }   = $json_type;
                $info{ $stocks, "last" }   = $json_price;
                $info{ $stocks, "currency"} = $json_resources_price->{'currency'};
                $info{ $stocks, "volume" }   = $json_volume;

                # The Yahoo JSON interface returns London prices in GBp (pence) instead of GBP (pounds)
                # and the Yahoo Base had a hack to convert them to GBP.  In theory all the callers
                # would correctly handle GBp as not the same as GBP, but they don't, and since
                # we had the hack before, let's add it back now.
                #
                # Convert GBp or GBX to GBP (divide price by 100).

                if ( ($info{$stocks,"currency"} eq "GBp") ||
                     ($info{$stocks,"currency"} eq "GBX")) {
                    $info{$stocks,"last"}=$info{$stocks,"last"}/100;
                    $info{ $stocks, "currency"} = "GBP";
                }

                # Apply the same hack for Johannesburg Stock Exchange
                # (JSE) prices as they are returned in ZAc (cents)
                # instead of ZAR (rands). JSE symbols are suffixed
                # with ".JO" when querying Yahoo e.g. ANG.JO

                if ($info{$stocks,"currency"} eq "ZAc") {
                    $info{$stocks,"last"}=$info{$stocks,"last"}/100;
                    $info{ $stocks, "currency"} = "ZAR";
                }

                # Apply the same hack for Tel Aviv Stock Exchange
                # (TASE) prices as they are returned in ILA (Agorot)
                # instead of ILS (Shekels). TASE symbols are suffixed
                # with ".TA" when querying Yahoo e.g. POLI.TA

                if ($info{$stocks,"currency"} eq "ILA") {
                    $info{$stocks,"last"}=$info{$stocks,"last"}/100;
                    $info{ $stocks, "currency"} = "ILS";
                }

                # Add extra fields using names as per yahoo to make it easier
                #  to switch from yahoo to yahooJSON
                # Code added by goodvibes
                {
                  # turn off warnings in this block to fix bogus
                  # 'Use of uninitialized value in multiplication' warning
                  # in Strawberry perl 5.18.2 in Windows
                  local $^W = 0;
                  $info{ $stocks, "div_yield" } =
                    $json_resources_summaryDetail->{'trailingAnnualDividendYield'}{'raw'} * 100;
                }
                $info{ $stocks, "eps"} =
                    $json_resources_defaultKeyStatistics->{'trailingEps'}{'raw'};
	        	# $json_resources_summaryDetail->{'epsTrailingTwelveMonths'};
                $info{ $stocks, "pe"} = $json_resources_summaryDetail->{'trailingPE'}{'raw'};
                $info{ $stocks, "year_range"} =
                    sprintf("%12s - %s",
                        $json_resources_summaryDetail->{"fiftyTwoWeekLow"}{'raw'},
                        $json_resources_summaryDetail->{'fiftyTwoWeekHigh'}{'raw'});
                $info{ $stocks, "open"} =
                    $json_resources_price->{'regularMarketOpen'}{'raw'};
                $info{ $stocks, "high"} =
                    $json_resources_price->{'regularMarketDayHigh'}{'raw'};
                $info{ $stocks, "low"} =
                    $json_resources_price->{'regularMarketDayLow'}{'raw'};
                $info{ $stocks, "close"} =
                    $json_resources_summaryDetail->{'regularMarketPreviousClose'}{'raw'};

                # MS Windows strftime() does not support %T so use %H:%M:%S
                #  instead.
                $my_date =
                    localtime($json_timestamp)->strftime('%d.%m.%Y %H:%M:%S');

                $quoter->store_date( \%info, $stocks,
                                     { eurodate => $my_date } );

            }
        } else { #HTTP request fail
            $info{ $stocks, "success" } = 0;
            $info{ $stocks, "errormsg" } =
                "Error retrieving quote for $stocks. Attempt to fetch the URL $url resulted in HTTP response $code ($desc)";
        }

    }

    return wantarray() ? %info : \%info;
    return \%info;
}

1;

=head1 NAME

Finance::Quote::YahooJSON - Obtain quotes from Yahoo Finance through JSON call

=head1 SYNOPSIS

    use Finance::Quote;

    $q = Finance::Quote->new;

    %info = $q->fetch('yahoo_json','SBIN.NS');

=head1 DESCRIPTION

This module fetches information from Yahoo as JSON

This module is loaded by default on a Finance::Quote object. It's
also possible to load it explicitly by placing "YahooJSON" in the argument
list to Finance::Quote->new().

This module provides the "yahoo_json" fetch method.

=head1 LABELS RETURNED

The following labels may be returned by Finance::Quote::YahooJSON :
name, last, isodate, volume, currency, method, exchange, type,
div_yield eps pe year_range open high low close.

=head1 SEE ALSO

=cut

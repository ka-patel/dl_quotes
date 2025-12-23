#!/usr/bin/perl -w
#    This module is based on the Finance::Quote::YahooJSON module
#
#    The code has been writtem/modified by Kalpesh Patel to
#    retrieve stock information from Yahoo Finance Chart API call and 
#    parse through json
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

require 5.005;

use strict;

#-## For *nix, call GNC as follows:
#-##   DEBUG=1 /usr/bin/gnucash <options1> <option2> ...

#-## For Windows, call GNC as follows:
#-##   set DEBUG=1 & "c:\Program Files (x86)\gnucash\bin\gnucash.exe" <options1> <option2> ...
#-##
#-## To unset an env variable in Windows, just leave out the value for the env variable. I. E., : 
#-##   set DEBUG=  & ...
#-## 

#
# See: https://cryptocointracker.com/yahoo-finance/yahoo-finance-api
#
# Example:
#
# https://query1.finance.yahoo.com/v8/finance/chart/aapl?metrics=high?&interval=1d&range=5d
#
# {
#    "chart":{
#       "result":[
#          {
#             "meta":{
#                "currency":"USD",
#                "symbol":"AAPL",
#                "exchangeName":"NMS",
#                "instrumentType":"EQUITY",
#                "firstTradeDate":345479400,
#                "regularMarketTime":1656432291,
#                "gmtoffset":-14400,
#                "timezone":"EDT",
#                "exchangeTimezoneName":"America/New_York",
#                "regularMarketPrice":138.867,
#                "chartPreviousClose":135.87,
#                "priceHint":2,
#                "currentTradingPeriod":{
#                   "pre":{
#                      "timezone":"EDT",
#                      "start":1656403200,
#                      "end":1656423000,
#                      "gmtoffset":-14400
#                   },
#                   "regular":{
#                      "timezone":"EDT",
#                      "start":1656423000,
#                      "end":1656446400,
#                      "gmtoffset":-14400
#                   },
#                   "post":{
#                      "timezone":"EDT",
#                      "start":1656446400,
#                      "end":1656460800,
#                      "gmtoffset":-14400
#                   }
#                },
#                "dataGranularity":"1d",
#                "range":"5d",
#                "validRanges":[
#                   "1d",
#                   "5d",
#                   "1mo",
#                   "3mo",
#                   "6mo",
#                   "1y",
#                   "2y",
#                   "5y",
#                   "10y",
#                   "ytd",
#                   "max"
#                ]
#             },
#             "timestamp":[
#                1655904600,
#                1655991000,
#                1656077400,
#                1656336600,
#                1656432291
#             ],
#             "indicators":{
#                "quote":[
#                   {
#                      "volume":[
#                         73409200,
#                         72433800,
#                         89047400,
#                         70149200,
#                         27762238
#                      ],
#                      "low":[
#                         133.91000366210938,
#                         135.6300048828125,
#                         139.77000427246094,
#                         140.97000122070312,
#                         138.82000732421875
#                      ],
#                      "open":[
#                         134.7899932861328,
#                         136.82000732421875,
#                         139.89999389648438,
#                         142.6999969482422,
#                         142.1300048828125
#                      ],
#                      "high":[
#                         137.75999450683594,
#                         138.58999633789062,
#                         141.91000366210938,
#                         143.49000549316406,
#                         143.4219970703125
#                      ],
#                      "close":[
#                         135.35000610351562,
#                         138.27000427246094,
#                         141.66000366210938,
#                         141.66000366210938,
#                         138.86669921875
#                      ]
#                   }
#                ],
#                "adjclose":[
#                   {
#                      "adjclose":[
#                         135.35000610351562,
#                         138.27000427246094,
#                         141.66000366210938,
#                         141.66000366210938,
#                         138.86669921875
#                      ]
#                   }
#                ]
#             }
#          }
#       ],
#       "error":null
#    }
# }
#

use constant DEBUG => $ENV{DEBUG} || $ENV{FQ_DEBUG} || $ENV{FQ_YAHOOCHART_DEBUG};
use constant TESTING => $ENV{FQ_TESTING};

use if DEBUG, 'Smart::Comments', '###';

package Finance::Quote::YahooChart;

use JSON qw( decode_json );
use vars qw( $VERSION $YIND_URL_HEAD $YIND_URL_TAIL );
use LWP::UserAgent;
use HTTP::Request::Common;
use Time::Piece;
use threads;
use Thread::Queue;
use HTTP::Cookies;
use URI::Escape;
use File::HomeDir;

# VERSION

my $endepoc = time(); # now in UNIX epoc seconds
my $startepoc = $endepoc - (7 * 24 * 60 * 60); # 7 days ago in UNIX epoc seconds

my $browser = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36';
$browser = 'Mozilla/5.0';

# https://query1.finance.yahoo.com/v8/finance/chart/AAPL?symbol=AAPL&period1=0&period2=9999999999&interval=1d&includePrePost=true&events=div%7Csplit
# Valid intervals: [1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo, 6mo, ytd, 1y, 2y, 5y, 10y, max]
my $YIND_URL_HEAD = 'https://query1.finance.yahoo.com/v8/finance/chart/';
my $YIND_URL_TAIL = '?interval=1d&period1=' . $startepoc . '&period2=' . $endepoc;

my $result_q = Thread::Queue->new;
my $lock_var : shared;
my $HOME = File::HomeDir->my_home;

my $file = $HOME . '/yahoo_cookies_and_crumb.dat';

our $DISPLAY    = 'YahooChart';
our @LABELS     = qw/name last date isodate volume currency method exchange type
        div_yield eps pe year_range open high low close/;
our $METHODHASH = {subroutine => \&yahoo_chart, 
                   display => $DISPLAY, 
                   labels => \@LABELS};

sub methodinfo {
    return ( 
        yahoo_chart => $METHODHASH,
        yahoochart  => $METHODHASH,
        nyse        => $METHODHASH,
        nasdaq      => $METHODHASH,
        usa         => $METHODHASH,
    );
}

sub labels {
  my %m = methodinfo();
  return map {$_ => [@{$m{$_}{labels}}] } keys %m;
}

sub methods {
  my %m = methodinfo(); return map {$_ => $m{$_}{subroutine} } keys %m;
}

sub round($$)
{
  my ($value, $places) = @_;
  my $factor = 10**$places;
  return int($value * $factor + 0.5) / $factor; # +0.5 is magical sauce to do rounding instead of truncating
}

my $can_use_threads = eval 'use threads; 1';
### [<now>] can_use_threads : $can_use_threads 

sub yahoo_chart {

    my $quoter = shift;
    my @stocks = @_;
    my ( %info, $reply, $url, $te, $ts, $row, @cells, $ce );
    my ( $my_date, $amp_stocks );
    
    my $result_q = Thread::Queue->new;
    my $lock_var : shared;

    my $ua = $quoter->user_agent(keep_alive => -1);
    $ua->agent ($browser);

    my $cookie_jar = HTTP::Cookies->new(
                  file => $file,
              autosave => 1,
        ignore_discard => 1,
    );
    
    $cookie_jar->load ($file);
    my $crumb = $cookie_jar->get_cookies('127.0.0.1', 'crumb');

    if ($crumb) {
        ### [<now>] Reusing crumb : $crumb
        ;
    } else {
            
        # Redirect handler deals with cookie consent workflow applicable to EU countries
        # credit to John Weber from Germany for injecting redirect handler
        my $gcrumb = "";
        $ua->add_handler("response_redirect", sub {
            my($response, $ua, $h) = @_;

            # Check where we've been redirected and act accordingly
            my $redirect_uri = URI->new($response->header("Location"));
            if ($redirect_uri->path eq "/consent") {

                # Remember gcrumb value for collectConsent request later
                my %params = $redirect_uri->query_form;
                $gcrumb = $params{'gcrumb'};

            } elsif ($redirect_uri->path eq "/v2/collectConsent") {

                my %params = $redirect_uri->query_form;
                my $sessionId = $params{'sessionId'};

                # Turn this request into a POST with form data to confoo accept cookies
                my $request = POST($redirect_uri, [
                    'csrfToken' => $gcrumb,
                    'sessionId' => $sessionId,
                    'originalDoneUrl' => 'https://www.yahoo.com/?guccounter=1',
                    'namespace' => 'yahoo',
                # For the EU consent, either can :
                #   'agree' => 'agree'
                # to it or
                    'reject' => 'reject'
                ]);
                return $request;
            }
            return;
        });

        $ua->cookie_jar($cookie_jar);
        $ua->agent($browser);

        # Tell user agent to redirect POSTs in additional to GET AND HEAD
        $ua->requests_redirectable(['GET', 'HEAD', 'POST']);

        # get necessary cookies
        $reply = $ua->get('https://www.yahoo.com/', "Accept" => "text/html");

        if ($reply->code != 200) {
            foreach my $symbol (@stocks) {
                $info{$symbol, "success"} = 0;
                $info{$symbol, "errormsg"} = "Error accessing www.yahoo.com: $@";
            }     
            return wantarray() ? %info : \%info;
        }

        # get the crumb that corresponds to cookies retrieved
        $reply = $ua->request(GET 'https://query2.finance.yahoo.com/v1/test/getcrumb');
        if ($reply->code != 200) {
            foreach my $symbol (@stocks) {
                $info{$symbol, "success"} = 0;
                $info{$symbol, "errormsg"} = "Error accessing https://query2.finance.yahoo.com/v1/test/getcrumb: $@";
            }     
            return wantarray() ? %info : \%info;
        }
        
        $crumb = uri_escape($reply->content);

        $cookie_jar->set_cookie(undef, "crumb", $crumb, "/", '127.0.0.1', undef, undef, undef, 365 * 86400, undef, {});
        $cookie_jar->save;

        ### [<now>]     new crumb : $crumb

    }

    ### [<now>]    cookie_jar : $cookie_jar

    my $YIND_CRUMB = '&crumb=' . $crumb;

    if ($can_use_threads) {

        my @threads = map {
            threads->create(
                sub {
                    my $stocks = shift;

                    ($amp_stocks = $stocks) =~ s/&/%26/g;
                    $url = $YIND_URL_HEAD . $amp_stocks . $YIND_URL_TAIL . $YIND_CRUMB ;

                    ### [<now>:THREAD]   url : $url
                    my $request = GET $url;
                    $request->protocol('HTTP/1.0');

                    my $reply   = $ua->request( $request );
                    my $code    = $reply->code;
                    my $headers = $reply->headers_as_string;
                    my $body    = $reply->content;
                    ### [<now>:THREAD] reply : $reply

                    #HTTP_Response succeeded - parse the data
                    my $json_info = JSON::decode_json $body;
                    my $json_data = $json_info->{'chart'}{'result'}[0];
                    my $error_msg = $json_info->{'chart'}{'error'};

                    {
                        lock ( $lock_var );
                        $result_q->enqueue( $stocks );
                        $result_q->enqueue( $code );
                        $result_q->enqueue( $error_msg );
                        $result_q->enqueue( $json_data );
                    }
                }, 
            $_)
        } @stocks;

        $_->join() for @threads;

        $result_q->end;
        
    } else {

        foreach my $stocks (@stocks) {       ### Evaluating |===[%]    |
            ($amp_stocks = $stocks) =~ s/&/%26/g;
            $url = $YIND_URL_HEAD . $amp_stocks . $YIND_URL_TAIL . $YIND_CRUMB ;

            ### [<now>]   url : $url
            my $request =  GET $url;
            $request->protocol('HTTP/1.0');

            my $reply   = $ua->request( $request );
            my $code    = $reply->code;
            my $headers = $reply->headers_as_string;
            my $body    = $reply->content;
            ### [<now>] reply : $reply

            #HTTP_Response succeeded - parse the data
            my $json_info = JSON::decode_json $body;
            my $json_data = $json_info->{'chart'}{'result'}[0];
            my $error_msg = $json_info->{'chart'}{'error'};

            $result_q->enqueue( $stocks );
            $result_q->enqueue( $code );
            $result_q->enqueue( $error_msg );
            $result_q->enqueue( $json_data );

            }

        $result_q->end;

    }

    while (defined (my $stocks = $result_q->dequeue())) {        ### Evaluating |===[%]    |

        my $code        = $result_q->dequeue;
        my $error_msg   = $result_q->dequeue;
        my $json_data   = $result_q->dequeue;

        my $desc        = HTTP::Status::status_message($code);
        
        $info{ $stocks, "success" } = 0;
        $info{ $stocks, "symbol" } = $stocks;
        $info{ $stocks, "method" } = "yahoo_chart";

        if ( $code == 200 ) {

#            if (not defined $json_data->{'indicators'}{'quote'}) {
            if (defined $error_msg) {

                $info{ $stocks, "errormsg" } = 
                    "Error retrieving quote for $stocks - no listing for this name found. Please check symbol and the two letter extension (if any). \
                     Received " . $error_msg . " error.";
                next;
            }
            else {

                # instrumentType shows whether the stock is equity, index, currency, or commodity
                $info{ $stocks, 'type'    } = $json_data->{'meta'}{'instrumentType'};
                $info{ $stocks, 'exchange'} = $json_data->{'meta'}{'exchangeName'};
                $info{ $stocks, 'currency'} = $json_data->{'meta'}{'currency'};
                $info{ $stocks, 'timezone'} = $json_data->{'meta'}{'timezone'};

                my $timestamps = $json_data->{'timestamp'};

                my $price_type = 'last';
                if ($info{ $stocks, 'type' } =~ m/mutualfund/i) {
                    $price_type = 'nav';
                }

                if (not defined ($timestamps)) {
                    $info{ $stocks, "errormsg" } = 
                        "Error retrieving quote for $stocks - No historical pricing data found in the data returned by the API.";
                    next;
                }

                my $tablerows = scalar (@{$timestamps});
                ### [<now>] table size received : $tablerows

                # if (not defined($json_data->{'indicators'}{'quote'}[0]{'close'}[$tablerows])) {
                while (($tablerows >= 0) and not defined ($json_data->{'indicators'}{'quote'}[0]{'close'}[$tablerows])) {
                    $tablerows -= 1;
                }
                ### [<now>] valid data row index : $tablerows
                
                my $json_timestamp;

                if ($tablerows < 0) {
                    $json_timestamp = $json_data->{'meta'}{'regularMarketTime'};
                    $info{ $stocks, "errormsg" } = 
                        "Error retrieving quote for $stocks - No valid pricing data row found in the data returned by the API.";
                    next;
                } else {
                    $json_timestamp = $json_data->{'timestamp'}[$tablerows];
                }

                for my $element (keys %{$json_data->{'meta'}}) {
                    if (not $element =~ m/(currentTradingPeriod|validRanges)/i) {
                        $info{ $stocks, $element } 
                            = $json_data->{'meta'}{$element};
                    }
                }

                for my $period (keys %{$json_data->{'meta'}{'currentTradingPeriod'}}) {
                    for my $attrib (keys %{$json_data->{'meta'}{'currentTradingPeriod'}{$period}}) {
                        if ($attrib =~ m/(start|end)/i) { 
                            $info{ $stocks, $period . '_trading_' . $attrib } 
                                = localtime($json_data->{'meta'}{'currentTradingPeriod'}{$period}{$attrib})->strftime('%d.%m.%Y %H:%M:%S');
                        }
                        else {
                            $info{ $stocks, $period . '_trading_' . $attrib } 
                                = $json_data->{'meta'}{'currentTradingPeriod'}{$period}{$attrib};   
                        }
                    }
                }

                $info{ $stocks, 'firstTradeDate' } 
                    = localtime ($info{ $stocks, 'firstTradeDate' })->strftime('%d.%m.%Y %H:%M:%S');
                $info{ $stocks, 'regularMarketTime' }
                    = localtime ($info{ $stocks, 'regularMarketTime' })->strftime('%d.%m.%Y %H:%M:%S');

                for my $prices (keys %{$json_data->{'indicators'}{'quote'}[0]}) {
                    $info{ $stocks, $prices } = $json_data->{'indicators'}{'quote'}[0]{$prices}[$tablerows];
                }

                for my $prices (keys %{$json_data->{'indicators'}{'adjclose'}[0]}) {
                    $info{ $stocks, $prices } = $json_data->{'indicators'}{'adjclose'}[0]{$prices}[$tablerows];
                }

                # We always provide the adjclose as that is the real price for the security. 
                # The adjusted close metric returns the closing price of the stock for that day, adjusted for 
                # splits and dividends unless commodity is still trading at the time of getting quotes.
                
                if (defined ($json_data->{'meta'}{'regularMarketTime'}) 
                    && defined ($json_data->{'meta'}{'regularMarketPrice'})) {
                    $info{ $stocks, $price_type } = 
                        $json_data->{'meta'}{'regularMarketPrice'};
                    $json_timestamp = $json_data->{'meta'}{'regularMarketTime'};
                } else {
                    $info{ $stocks, $price_type } = $info{ $stocks, 'adjclose' };
                }

                # Need to make sure that numeric values are 9 decimal places.
                for my $price (qw/open high low close last nav price adjclose regularMarketPrice chartPreviousClose/) {
                    if (defined ($info{$stocks, $price})) {
                        $info{$stocks,$price} = round ($info{$stocks,$price}, 9);
                    }
                }

                # The Yahoo JSON interface returns London prices in GBp (pence) instead of GBP (pounds)
                # and the Yahoo Base had a hack to convert them to GBP.  In theory all the callers
                # would correctly handle GBp as not the same as GBP, but they don't, and since
                # we had the hack before, let's add it back now.
                #
                # Convert GBp or GBX to GBP (divide price by 100).

                if (($info{$stocks,"currency"} eq "GBp") ||
                     ($info{$stocks,"currency"} eq "GBX")) {
                    for my $price (qw/open high low close last nav price adjclose regularMarketPrice chartPreviousClose/) {
                        if (defined ($info{$stocks, $price})) {
                            $info{$stocks,$price}=$info{$stocks,$price}/100;
                        }
                    }
                    $info{ $stocks, "currency"} = "GBP";
                }

                # Apply the same hack for Johannesburg Stock Exchange
                # (JSE) prices as they are returned in ZAc (cents)
                # instead of ZAR (rands). JSE symbols are suffixed
                # with ".JO" when querying Yahoo e.g. ANG.JO

                if ($info{$stocks,"currency"} eq "ZAc") {
                    for my $price (qw/open high low close last nav price adjclose regularMarketPrice chartPreviousClose/) {
                        if (defined ($info{$stocks, $price})) {
                            $info{$stocks,$price}=$info{$stocks,$price}/100;
                        }
                    }
                    $info{ $stocks, "currency"} = "ZAR";
                }

                # Apply the same hack for Tel Aviv Stock Exchange
                # (TASE) prices as they are returned in ILA (Agorot)
                # instead of ILS (Shekels). TASE symbols are suffixed
                # with ".TA" when querying Yahoo e.g. POLI.TA

                if ($info{$stocks,"currency"} eq "ILA") {
                    for my $price (qw/open high low close last nav price adjclose regularMarketPrice chartPreviousClose/) {
                        if (defined ($info{$stocks, $price})) {
                            $info{$stocks,$price}=$info{$stocks,$price}/100;
                        }
                    }
                    $info{ $stocks, "currency"} = "ILS";
                }

                # MS Windows strftime() does not support %T so use %H:%M:%S
                #  instead.
                $my_date =
                    localtime($json_timestamp)->strftime('%d.%m.%Y %H:%M:%S');

                $quoter->store_date( \%info, $stocks,
                                     { eurodate => $my_date } );

                $info{ $stocks, "success" } = 1;

            }
        }

        #HTTP request fail
        else {
            $info{ $stocks, "success" } = 0;
            $info{ $stocks, "errormsg" } = 
                "Error retrieving quote for $stocks. Attempt to fetch the URL $url resulted in HTTP response $code ($desc)";
        }

    }

    return wantarray() ? %info : \%info;
    return \%info;
}

1;

# testing: perl "c:\Program Files (x86)\gnucash\bin\gnc-fq-dump" -v yahoochart BK FSPSX SBIN.NS

=head1 NAME

Finance::Quote::YahooChart - Obtain quotes from Yahoo Finance's Chart API call

=head1 SYNOPSIS

    use Finance::Quote;
    $q = Finance::Quote->new;
    %info = $q->fetch('yahoochart','BK');

=head1 DESCRIPTION

This module fetches information from Yahoo using Chart sub-API. 

This module is loaded by default on a Finance::Quote object. It's also 
possible to load it explicitly by placing "YahooChart" in the argument 
list to Finance::Quote->new().

This module provides the "yahoochart" fetch method.

=head1 LABELS RETURNED

The following labels may be returned by Finance::Quote::YahooChart :
success date isodate volume currency method exchange type symbol
open high low close nav price adjclose 

=head1 SEE ALSO

=cut

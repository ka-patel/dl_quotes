#!/usr/bin/perl -w

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

package Finance::Quote::AlpacaCrypto;

use strict;
use warnings;

use constant DEBUG => $ENV{DEBUG};
use constant DEBUG => $ENV{FQ_DEBUG};
use constant DEBUG => $ENV{FQ_ALPACACRYPTO_DEBUG};
use if DEBUG, 'Smart::Comments';

use LWP::UserAgent;
use JSON qw( decode_json );
use String::Util qw(trim);
use DateTime::Format::ISO8601;

# VERSION

our $DISPLAY = 'Alpaca';
our @LABELS = qw/open high low close volume timestamp/;
our $METHODHASH = {subroutine => \&alpaca_crypto,
                   display => \$DISPLAY,
                   labels => \@LABELS};

sub methodinfo {
    return (
        alpaca_crypto => $METHODHASH,
    );
}

sub labels {
  my %m = methodinfo(); return map {$_ => [@{$m{$_}{labels}}] } keys %m;
}

sub methods {
  my %m = methodinfo(); return map {$_ => $m{$_}{subroutine} } keys %m;
}


sub alpaca_crypto {
  my $quoter  = shift;
  my @symbols = @_;
  my $ua      = $quoter->user_agent();
  my %info;

  foreach my $symbol (@_) {
    eval {
      my $url         = 'https://data.alpaca.markets/v1beta3/crypto/us/latest/bars?symbols=';
      my $reply       = $ua->get($url . $symbol);
      my $json_data   = JSON::decode_json $reply->content;

      ### $reply : $reply
      ### $json_data : $json_data

# {
#   "bars": {
#     "BTC/USD": {
#       "c": 95253.461,
#       "h": 95253.461,
#       "l": 95136,
#       "n": 1,
#       "o": 95136,
#       "t": "2025-01-08T22:43:00Z",
#       "v": 0.1,
#       "vw": 95136
#     }
#   }
# }

      my $data = $json_data->{"bars"}{$symbol};

      $info{$symbol, "symbol" }  = $symbol;
      $info{$symbol, "method" }  = "alpaca_crypto";
      $info{$symbol, 'close'}    = $data->{"c"};
      $info{$symbol, 'high'}     = $data->{"h"};
      $info{$symbol, 'low'}      = $data->{"l"};
      $info{$symbol, 'open'}     = $data->{"o"};
      $info{$symbol, 'volume'}   = $data->{"v"};
      $info{$symbol, 'last'}     = $data->{"c"};
      $info{$symbol, 'currency'} = "USD";
      
      my $dt = DateTime::Format::ISO8601->parse_datetime($data->{"t"});
      $quoter->store_date(\%info, $symbol, {isodate => $dt->ymd});
      
      $info{$symbol, 'success'} = 1;
    };

    if ($@) {
      my $error = "AlpacaCrypto failed: $@";
      $info{$symbol, 'success'}  = 0;
      $info{$symbol, 'errormsg'} = trim($error);
    }
  }

  return wantarray() ? %info : \%info;
}

1;

=head1 NAME

Finance::Quote::AlpacaCrypto - Obtain quotes from crypto currency via trading API
of Alpaca.
See https://alpaca.markets/ for more details. 

=head1 SYNOPSIS

    use Finance::Quote;

    $q = Finance::Quote->new;

    %info = Finance::Quote->fetch('alpaca_crypto', 'ETH/USD');

=head1 DESCRIPTION

This module fetches information from the Alpaca's free crypto API.


This module is loaded by default on a Finance::Quote object. It's also possible
to load it explicitly by placing 'AlpacaCrypto' in the argument list to
Finance::Quote->new().

=head1 LABELS RETURNED

The following labels may be returned by Finance::Quote::AlpacaCrypto :
open, high, low, close, volume, timestamp 

=head1 TERMS & CONDITIONS

Use of https://alpaca.markets/ is governed by any terms & conditions of that site.

Finance::Quote is released under the GNU General Public License, version 2,
which explicitly carries a "No Warranty" clause.

=cut

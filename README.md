```
# dl_quotes

#-## This project contains various scripts written to download quotes from
various sources that are importable into GNUCash and/or Quicken 2017. For 
Quicken, it has been tested with 2017 version but it is likely to work for 
all version from 2014 and onward as they all use same format for importing 
in prices via CSV import.

Currently following two sets of buckets are supported:

 - US Securities from Yahoo Finance (yahoo_fin or yfinance directory)
    Note that these variation are because each uses different built-in Python 
    modules but they function identically.
 - US Gov't Trift Savings Plan -- aka TSP (TSP directory)

This repo also contains FinaceQuote directory at has dditional unofficial 
Finance::Quote modules that are developed by me. It includes YahooChart
module which fetches cookies and crumb to future proof it, and multi-threading 
if installed Perl is capable of. You simply would overlay these files into
your .../site/lib/Finance directory. This is as of version 1.67 for 
Finance::Quote.

```

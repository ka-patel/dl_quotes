```
# dl_quotes

#-## Script to download historical quotes from Yahoo Finance using yfinance module

Install steps (for Windows 11) as of 12/07/2025:

1) Install Python 3.14 from Microsoft Store.
    Note that process to install Python on Windows has changed. You must now first install Python manager
    and then install a specific version of a Python from Python manager
    (see https://www.python.org/downloads/release/pymanager-250/). Install latest v3.14 as follows:
        py install 3.14

2) Requires requests_html, datetime, lxml, lxml_html_clean, pandas and yfinance Python modules. 
    Run following command to install these needed modules from within Python manager:
        py -V:3.14 -m pip install requests requests_html datetime lxml lxml_html_clean pandas yfinance

3) Create a text file with list of tickers for which to retrieve quotes for. Format of the text file is one 
   ticker per line. While each blank line is ignored, any non-blank line is assumed to be a ticker symbol. An
   index ticker is to be prefixed with 'INDEX:' fixed text and then followed by the ticker for the index.
    Example:
        echo BRK-B     >  my_tickers.example
        echo VFIAX     >> my_tickers.example
        echo INDEX:XAX >> my_tickers.example

4) Format of invocation is as follows with optional fixed positional parameters:
    py -V:3.14 get_historic_quotes.py <file_with_tickers> <number_of_days_to_retrieve> <interval>
    Example (to retrieve today's prices):
        py -V:3.14 get_historic_quotes.py my_tickers 1 1d

    Of course if you don't specify parameters then the script uses few hard coded tickers and retrieves 30 days
    of end of day historical data for each ticker. The script has been tested with and works for equity, mutual
    funds and indexes. Likely is to work for currency exchange but untested at this time.

    <file_with_tickers> is a file name that can be specified with either relative or full path prepended that 
    contains list of tickers as specified in Step 3.

    <number_of_days_to_retrieve> is any positive greater than zero which sets a window from today to number of
    days back specified in this parameter. This value is calculated to provide start and end period of quotes to
    get.

    <interval> is optional and by default is set to one day ("1d") if not provided. Valid interval for type of
    quotes to get are one day ("1d"), five days ("5d"), one week ("1w"), one month ("1mo") and three month 
    ("3mo"). This parameter is directly passed to yfinance API.



The execution will produce four files:
 - gnucash_quotes.csv
    this file is importable into GNC via 'File' -> 'Import' -> 'Import prices from CSV file' option and then
    selecting this file. The comma separated format of the file is: From Namespace (as per Yahoo), From Symbol,
    Date (m-d-y format), Amount, Currency To
 - quicken_quotes.csv
    this file is importable into Quicken 2017 (and most other version but untested)
    via 'File' -> 'File Import' -> 'Import security prices from CSV file...' option and then selecting this
    file.
 - quotes.qif
    this file is importable into Quicken 2017 (and most other version but untested) via
    'File' -> 'File Import' -> 'Import QIF...' option and then selecting this file. Note that you will have
    to check 'Security list' in the 'Include in import:' section for it to succeed in the importation.
 - quotes_error.csv
    this file contains list of tickers that were not found at Yahoo Finance via yahoo_fin module.


While I may not be able to respond to all comments, suggestions and criticism personally and in timely manner,
it is nonetheless welcome. You can write to me at: kalpesh (period) patel (at) usa (period) net .
```

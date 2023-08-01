```
# dl_quotes

#-## Script to download historical quotes from Yahoo Finance

Install steps (for Windows 11):

1) Install Python 3.11 from Microsoft Store.

2) Requires lxml, requests and yahoo_fin Python modules. 
    Run following command to install these needed modules:
        python -m pip install lxml requests yahoo_fin

3) Create a text file with list of tickers for which to retrieve quotes for. Format of the text file is one 
   ticker per line. While each blank line is ignored, any non-blank line is assumned to be a ticker symbol. An index 
   ticker is to be prefixed with 'INDEX:' fixed text and then followed by the ticker for the index.
    Example:
        echo BRK-B     >  my_tickers.example
        echo VFIAX     >> my_tickers.example
        echo INDEX:XAX >> my_tickers.example

4) Format of invocation is as follows with optional fixed positional parameters:
    python get_historic_quotes.py <file_with_tickers> <number_of_days_to_retrieve>
    Example (to retrieve today's prices):
        python get_historic_quotes.py my_tickers 1

    Of course if you don't specify parametes then the script uses few hard coded tickers and retrieves 30 days of
    historical data for each ticker. The script has been tested with and works for equity, mutual funds and indexes.


The execution will produce four files:
 - gnucash_quotes.csv
    this file is importable into GNC via 'File' -> 'Import' -> 'Import prices from CSV file' option and then
    selecting this file. The comma seperated format of the file is: From Namespace (as per Yahoo), From Symbol,
    Date (m-d-y format), Amount, Currency To
 - quicken_quotes.csv
    this file is importable into Quicken 2017 (and most other version but untested) via 'File' -> 'File Import' ->
    'Import security prices from CSV file...' option and then selecting this file.
 - quotes.qif
    this file is importable into Quicken 2017 (and most other version but untested) via 'File' -> 'File Import' ->
    'Import QIF...' option and then selecting this file. Note that you will have to check 'Security list' in the
    'Include in import:' section for it to succeed in the importation.
 - quotes_error.csv
    this file contains list of tickers that were not found at Yahoo Finance via yahoo_fin module.


While I may not be able to respond to all comments, suggetions and criticisiom personally and in timely manner, it is
nonetheless welcome. You can write to me at: kalpesh (period) patel (at) usa (period) net 
```

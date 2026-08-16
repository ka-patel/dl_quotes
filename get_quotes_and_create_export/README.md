```
# get_quotes_and_create_export

#-## This folder contains Python script that kind of combines Python script located
in display_namespace_for_ticker folder and at the same time pass an optional argument
to download quotes and generate prices file named "prices.csv" that can be imported 
into GNUCash. This is mostly likely for folks that are unable to install supplemental 
Perl Finance::Quote module for GNUCash on their system for one reason or another. 
Unlike Finance::Quote module, this one sources quotes only from Yahoo Finance 
(yfinance) Python library. See https://pypi.org/project/yfinance/ for more details. 

It can display either duplicates only, or all if second parameter is specified. Each 
ticker will be shown with its namespace(s) separated with colon, and namespaces 
separated by commas.

If you want to generate the quotes file then you must pass a third parameter of 
"quotes" to the script and second parameter becomes mandatory in which case you
can substitute some junk to display only duplicates or "all". IMHO, it doesn't 
make sense not to use "all" for second parameter if creating quotes as at times 
script will feel silent even though it is working. It would be weird but option 
is there in case wanted. The script will download end-of-day prices for past one 
week from Yahoo via yfinance Python module. Do note that prices are auto adjusted
for dividends, splits, etc. No errors are displayed for failure to retrieve 
quotes for a ticker and is silently skipped. 

prices.csv file look like this:

  "NONCURRENCY","AAPL","08/10/2026",308.260009765625,"USD"

with column of namespace, symbol, date, price, and currency, that are comma 
separated respectively.

Python v3.x with yfinance, lxml, gzip and sys libraries will be needed. 

Invoke it as:

  python get_quotes_for_tickets <data_file_name> [all|any_thing_junk] [quotes]

If ran with just data file name, it will display all duplicate tickers. Output 
example:

C:\Users\ka-patel\git\dl_quotes\display_namespace_for_ticker>python display_namespaces.py c:\data\gnucash\info2000.gnucash

C:NONCURRENCY, TSP
NANC:CBOE, CBOE - US
QMMLQ:MONEY MARKET, NONCURRENCY
VBTLX:FUND, NONCURRENCY
VEMAX:FUND, NONCURRENCY
VEUSX:FUND, NONCURRENCY
VOO:NONCURRENCY, NYSEARCA
VTI:NONCURRENCY, NYSEARCA
VTIAX:FUND, NONCURRENCY
VXF:FUND, NONCURRENCY
^RUT:CHICAGOOPTIONS, NASDAQ

C:\Users\ka-patel\git\dl_quotes\display_namespace_for_ticker>

One note:
yfinance can take multiple tickers at the same time but script iterate one at a time
in order to not overwhelm Yahoo systems. If there is a long list then get popcorn and
enjoy the display on screen as it goes about its work.

```

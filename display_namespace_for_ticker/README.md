```
# display_namespace_for_ticker

#-## This folder contains Python script to find and display namespace for tickers
that are defined in a compressed XML data file for GNUCash.

It can display either duplicates only, or all. Each ticker will be shown with its  
namespace(s) separated with colon, and namespaces separated by commas.

Python v3.x with lxml, gzip and sys libraries will be needed. Invoke it as:

  python display_namespaces.py <data_file_name> [all]


Output example:

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
```

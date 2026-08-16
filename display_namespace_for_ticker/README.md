```
# display_namespace_for_ticker

#-## This folder contains Python script to find and display namespace for tickers
that are defined in a compressed XML data file for GNUCash.

It can display either duplicates only, or all. Each ticker will be shown with its  
namespace(s) separated with colon, and namespaces separated by commas.

Python v3.x with lxml, gzip and sys libraries will be needed. Invoke it as:

  python display_namespaces.py [all]

```

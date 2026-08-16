# --- Start of script ---

from lxml import etree
import gzip
import sys

import yfinance as yf

yf.config.debug.hide_exceptions = True
yf.config.debug.logging = False

onlyMultiple = True
createQuotes = False
quotesFile = "prices.csv"

if len(sys.argv) > 3:
    if "quotes" in sys.argv[3].lower():
        createQuotes = True
  
if len(sys.argv) > 2:
    if "all" in sys.argv[2].lower():
        onlyMultiple = False
  
if len(sys.argv) > 1:
	data_file = sys.argv[1]
else:
    print ("\nProvide one or two positional parameters:")
    print ("   Required first argument: GNC data file.")
    print ("   Required second argument: 'all' to display all tickers, not just those with multiple namespaces; else any non blank string.")
    print ("   Optional third argument: 'quotes' to create GNUCash importable 'prices.csv' file.\n")
    exit()

namespaces = dict()

try:
    with gzip.open(data_file, "rb") as f:
        context = etree.iterparse(f, tag='{http://www.gnucash.org/XML/gnc}commodity')
        
        for event, elem in context:
            symbol = elem[1].text
            namespace = elem[0].text
            elem.clear()
            
            if symbol in namespaces:
                namespaces[symbol] = namespaces[symbol] + "," +namespace
            else:
                namespaces[symbol] = namespace

    if createQuotes:
        with open(quotesFile, "w", encoding="utf-8") as file:
            if not file.writable():
                print ("Error: Unable to write to file '{}'.".format(quotesFile))
                createQuotes = False
                            
    for ticker in sorted(namespaces.keys()):
        
        if onlyMultiple:
            if namespaces[ticker].count(",") > 0:
                print ("{}:{}".format(ticker, namespaces[ticker]))
        else:
            print ("{}:{}".format(ticker, namespaces[ticker]))

        if createQuotes and all(namespace != "CURRENCY" for namespace in namespaces[ticker].split(",")): 
            try:
                quotes = yf.Ticker(ticker)
                info = quotes.info
                
                prices = quotes.history(period="1wk", auto_adjust=True)
                    
                if not prices.empty:
                    
                    currency = "USD"
                    infoAttr = info.keys()
                                            
                    prices.reset_index(inplace=True)
                    prices['Date'] = prices['Date'].dt.strftime('%m/%d/%Y')
                    prices.drop(['Dividends','Stock Splits'], inplace=True, axis=1)
                    prices.to_dict(orient='records')
                  
                    if 'financialCurrency' in infoAttr:
                        currency = info['financialCurrency']
                    if 'currency' in infoAttr:
                        currency = info['currency']
                        
                    with open(quotesFile, "a", encoding="utf-8") as file:
                        for namespace in namespaces[ticker].split(","):
                            for i in prices.index:

                                close = prices['Close'][i]
                                date = prices['Date'][i]
                                high = prices['High'][i]
                                low = prices['Low'][i]
                                volume = prices['Volume'][i]/100

                                file.write('"{}","{}","{}",{},"{}"\n'.format(namespace, ticker, date, close, currency))
            
            except Exception as e:
                pass

except Exception as e:
    print ("Error: {}".format(e))

# --- End of script ---

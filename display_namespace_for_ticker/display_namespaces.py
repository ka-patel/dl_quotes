# --- Start of script ---

from lxml import etree
import gzip
import sys

onlyMultiple = True

if len(sys.argv) > 2:
    if "all" in sys.argv[2].lower():
        onlyMultiple = False
  
if len(sys.argv) > 1:
	data_file = sys.argv[1]
else:
    print ("\nProvide one or two positional parameters:")
    print ("   File name as the first argument.")
    print ("   Optional second argument: 'all' to display all tickers, not just those with multiple namespaces.\n")
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
				namespaces[symbol] = namespaces[symbol] + ", " +namespace
			else:
				namespaces[symbol] = namespace
  
	for ticker in sorted(namespaces.keys()):
		if onlyMultiple:
			if namespaces[ticker].count(",") > 0:
				print ("{}:{}".format(ticker, namespaces[ticker]))
		else:
			print ("{}:{}".format(ticker, namespaces[ticker]))

except Exception as e:
	print ("Error: {}".format(e))
   
# --- End of script ---

                

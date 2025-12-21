import os
import sys
import pandas as pd
import yfinance as yf
import yfinance.shared as shared
from datetime import date

today = date.today()
path_to_file = './/'

debug = os.environ.get('DEBUG') or os.environ.get('FQ_DEBUG') or os.environ.get('FQ_GENERICEXECUTOR_DEBUG')
gencsv = os.environ.get('FQ_GENERATE_CSV')

def eprint(*args, **kwargs) :
    print(*args, file=sys.stderr, **kwargs)

def stream_out(lhs, rhs) :
	print ('!{}:{}'.format(lhs.replace(" ", "_"), rhs), end='')
	if debug :
		eprint (lhs, rhs, sep=":")

def main() -> int:
	
	if debug :
		yf.enable_debug_mode()

	tickers = "^DJI!BK"
	if len (sys.argv) > 1 :
		tickers = sys.argv[1]

	symbols = tickers.split("!")
	tickers = yf.Tickers(symbols)

	for ticker in tickers.tickers :
		success = 0

		stream_out ("ticker", ticker)
		stream_out ("isin", tickers.tickers[ticker].isin)
		
		info = tickers.tickers[ticker].info
		for key,value in sorted(info.items()) :
			stream_out (key, value)

		fast_info = tickers.tickers[ticker].fast_info
		for key,value in sorted(fast_info.items()) :
			stream_out (key, value)
			# if "lastprice" in key.lower():
			# 	stream_out ("last", round(value, 9))
			# 	stream_out ("date", today)
			# 	success = 1
			# if "lastvolume" in key.lower():
			# 	stream_out ("volume", round(value, 9))
			# 	stream_out ("date", today)

		hist = tickers.tickers[ticker].history(period='1mo', auto_adjust=True)

		for ts in hist.index : # hist.index gives date timestamps
			date = pd.Timestamp(ts)
			quotedate = date.strftime('%m/%d/%Y')
			exchange = ''
			volume = 0
			close = 0
			high = 0
			low = 0

			stream_out ('isodate', ts)
			stream_out ('date', date.strftime('%m/%d/%Y'))
			for pricing in hist.columns : # hist.columns give us column names such as high, low, etc
				attrib = pricing.lower()
				stream_out (attrib, round(hist[pricing][ts], 9))
				if "close" in attrib:
					success = 1
					if "MUTUALFUND" in fast_info['quoteType'] :
						stream_out ("nav", round(hist[pricing][ts], 9))
					else : 
						stream_out ("last", round(hist[pricing][ts], 9))

				if 'vol' in attrib :
				 	volume = hist[pricing][ts]
				if 'close' in attrib :
				 	close = hist[pricing][ts]
				if 'high' in attrib :
				 	high = hist[pricing][ts]
				if 'low' in attrib :
				 	low = hist[pricing][ts]
				if 'exchange' in attrib :
					exchange = hist[pricing][ts]

			if gencsv :
				with open(path_to_file + 'quotes.qif', 'w') as qif,\
					open(path_to_file + 'quicken_quotes.csv', 'w') as quicken,\
					open(path_to_file + 'gnucash_quotes.csv', 'w') as gnucash :

						quicken.write("{},{},---,{},---,{},{},{},*\n".format (ticker.replace("^", "INDEX:"), close, quotedate, high, low, volume))
						gnucash.write("\"{}\",\"{}\",\"{}\",{},\"{}\"\n".format (exchange, ticker, quotedate, close, "USD"))
						qif.write("!Type:Prices\n\"{}\",{},\"{}\"\n^\n".format(ticker.replace("^", "INDEX:"), close, quotedate))

		if ticker in shared._ERRORS :
			stream_out ("error", shared._ERRORS[ticker])

		stream_out ("success", success)
			
	return 0

if __name__ == '__main__' :
	sys.exit(main())


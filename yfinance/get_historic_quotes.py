
#-########################################################################################################################
#-##
#-## Script to download historical quotes from Yahoo Finance
#-##
#-## History:
#-##   20251207 - Single ticker is send as a Python array of one when passing it to yfinance module.
#-##
#-## Required modules:
#-##     yfinance
#-##     pandas
#-##     datetime
#-##     sys
#-##
#-## Author: Kalpesh Patel (kalpesh <dot> patel <at> usa <dot> net)
#-##
#-######################################################################################################################## 

import pandas
import yfinance as yf
import sys
import datetime

path_to_file = '.\\'
days_of_quotes = 30

tickers = [
"ABNIX",
"IDCC",
"BK",
"INDEX:XAX",
]

if len(sys.argv) > 2 :
	updated_days_of_quotes = int(sys.argv[2])
	if updated_days_of_quotes > 0 :
		days_of_quotes = updated_days_of_quotes

if len(sys.argv) > 1 :
	with open (sys.argv[1]) as file :
		read_tickers = file.readlines()
	if len(read_tickers) > 0 :
		tickers = [ticker.strip() for ticker in read_tickers]
	
today = datetime.date.today()	
window_end = today + datetime.timedelta(days = 1)
window_start = window_end - datetime.timedelta(days = days_of_quotes)

qif_file = open(path_to_file + 'quotes.qif', 'w')
quicken_csv_file = open(path_to_file + 'quicken_quotes.csv', 'w')
gnucash_csv_file = open(path_to_file + 'gnucash_quotes.csv', 'w')
err_file = open(path_to_file + 'quotes_error.csv', 'w')

for symbol in tickers :

	ticker = symbol.replace("INDEX:", "^")

	try:
		data = yf.Ticker(ticker)
		quotes = yf.download(ticker, progress=False, interval="1d", start=window_start, group_by="ticker", auto_adjust=True)
	except:
		err_file.write(ticker + "\n")
	else:

		download=quotes[ticker]
		exchange = data.info["exchange"]
		currency = data.info["currency"]
		closings=download["Close"]
		
		for ts,close in closings.items() :

			date = ts.strftime("%Y-%m-%d")
			
			high = download["High"][date]
			low = download["Low"][date]
			vol = download["Volume"][date]

			date = ts.strftime("%m/%d/%Y")

			csv_quote_line = '{},{},---,{},---,{},{},{},*'.format(symbol, close, date, high, low, vol)
			gnc_quote_line = '"{}","{}","{}",{},"{}"'.format(exchange, ticker, date, close, currency)
			qif_quote_line = '!Type:Prices\n"{}",{},"{}"\n^'.format(symbol, close, date) 

			print(gnc_quote_line)
			quicken_csv_file.write(csv_quote_line + "\n")
			gnucash_csv_file.write(gnc_quote_line + "\n")
			qif_file.write(qif_quote_line + "\n")

gnucash_csv_file.close()
quicken_csv_file.close()
err_file.close()
qif_file.close()

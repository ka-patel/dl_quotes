
#-########################################################################################################################
#-##
#-## Script to download historical quotes from Yahoo Finance
#-##
#-## Required modules:
#-##     requests
#-##     sys
#-##     datetime
#-##     lxml
#-##     yahoo_fin
#-##
#-## Author: Kalpesh Patel (kalpesh <dot> patel <at> usa <dot> net)
#-##
#-######################################################################################################################## 

from lxml import html
import datetime
import requests
import sys

# import stock_info module from yahoo_fin
from yahoo_fin import stock_info as si

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

qif_file = open(path_to_file + 'quotes.qif', 'w')
quicken_csv_file = open(path_to_file + 'quicken_quotes.csv', 'w')
gnucash_csv_file = open(path_to_file + 'gnucash_quotes.csv', 'w')
err_file = open(path_to_file + 'quotes_error.csv', 'w')

userAgent = {'user-agent' : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36 Edg/91.0.864.59'}
userAgent = {'user-agent' : 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0'}

for ticker in tickers :
	
	today = datetime.date.today()
	
	window_end = today + datetime.timedelta(days = 1)
	window_start = window_end - datetime.timedelta(days = days_of_quotes)

	actual_ticker = ticker.replace ("INDEX:", '^')

	try:
		# print(si.get_quote_table(ticker.replace ("INDEX:", '^'), dict_result = True))
		records = si.get_data(actual_ticker, start_date = window_start, end_date = window_end, index_as_date = False, interval = "1d")
	except:
		err_file.write(ticker + "\n")
	else:
		if records.size > 0 :
			try:
			    url = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query={}&region=1&lang=en".format(actual_ticker)
			    result = requests.get(url).json()
			except:
				pass
			else:
				qif_file.write('!Type:Security\n')
				for x in result['ResultSet']['Result'] :
					if x['symbol'] == (actual_ticker) :
						qif_file.write('N' + x['name'] + '\n')
				qif_file.write('S' + ticker + '\n')

				security_type = 'Stock'
				for x in result['ResultSet']['Result'] :
					if x['type'] == 'M' :
						security_type = 'Mutual Fund'
					if x['type'] == 'I' :
						security_type = 'Market Index'

				qif_file.write('T' + security_type + '\n')
				qif_file.write('^' + '\n')

			try:
				info_url = "https://finance.yahoo.com/quote/{}/".format(actual_ticker)
			except:
				pass
			else:
				info_result = requests.get(info_url, headers=userAgent) #.json()
				tree = html.fromstring(info_result.content)
				namespace = tree.xpath('//*[@id="quote-header-info"]/div[2]/div[1]/div[2]/span/text()')
				exchange = str(namespace)[2:-2].split("-",1)[0].replace(" ","").upper()
			
			for index, row in records.iterrows() :
				
				# security = row['ticker']
				security = ticker
				
				closing_price = str(row['adjclose']).replace(",", "")
				high = str(row['high'])
				low = str(row['low'])
				vol = str(row['volume']/100)
				
				price_date = row['date']
				date = price_date.strftime("%m/%d/%Y")

				csv_quote_line = security + ", " + closing_price + ", ---, " + date + ", ---, " + high + ", " + low + ", " + vol + ', *'
				gnc_quote_line = "\"" + exchange +"\",\"" + actual_ticker + "\",\"" + date + "\"," + closing_price + ",\"USD\""
				qif_quote_line = '!Type:Prices' + "\n" + '"' + security + '",' + closing_price + ',"' + date + '"' + "\n" + '^'

				print(gnc_quote_line)
				if closing_price != "nan" :
				    quicken_csv_file.write(csv_quote_line + "\n")
				    gnucash_csv_file.write(gnc_quote_line + "\n")
				    qif_file.write(qif_quote_line + "\n")

# print(records)
# print(records[["ticker","close","date"]])
gnucash_csv_file.close()
quicken_csv_file.close()
err_file.close()
qif_file.close()

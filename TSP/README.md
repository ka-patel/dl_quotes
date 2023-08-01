```
#-## Script to download one year worth of historical quotes for US Gov't trift savings plan (aka TSP)

Install steps (for Windows 11):

1) Install Perl (tested with Strawberry perl v5.28.1 from https://strawberryperl.com/).

2) Requires WWW::Mechanize, HTML::TreeBuilder, HTTP::CookieJar::LWP, Data::Dumper and HTML::TableExtract modules. 
    Run following commands to install these needed modules:
        perl -MCPAN -e shell #bring up cpan shell
        cpan> install WWW::Mechanize HTML::TreeBuilder HTTP::CookieJar::LWP Data::Dumper HTML::TableExtract

3) Format of invocation is as simple as invocking the script as follows:
    perl tsp_end_of_day_quotes_for_quicken.pl

    Script will retrieves 365 days of historical data for all funds.

The execution will produce three files:
 - gnucash_quotes.csv
    this file is importable into GNC via 'File' -> 'Import' -> 'Import prices from CSV file' option and then
    selecting this file. The comma seperated format of the file is: From Namespace ("FUND"), From Symbol,
    Date (m-d-y format), Amount, Currency To ("USD")
 - quicken_quotes.csv
    this file is importable into Quicken 2017 (and most other version but untested) via 'File' -> 'File Import' ->
    'Import security prices from CSV file...' option and then selecting this file.
 - quotes.qif
    this file is importable into Quicken 2017 (and most other version but untested) via 'File' -> 'File Import' ->
    'Import QIF...' option and then selecting this file. Note that you will have to check 'Security list' in the
    'Include in import:' section for it to succeed in the importation.


While I may not be able to respond to all comments, suggetions and criticisiom personally and in timely manner, it is
nonetheless welcome. You can write to me at: kalpesh (period) patel (at) usa (period) net 
```

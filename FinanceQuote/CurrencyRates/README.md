```
#-## This is a replacement yahooJSON module for Finance::Quote which also adds the cookie and the crumb that may be required for the currncy version of it.

This version is modified based on version 1.59 of the release and works as of 04/12/2024.

Install steps (for Windows 11 using Strawberry perl):

1) Install Strawberry perl.

2) Install Finance::Quote module using following method:
   #perl -MCPAN -e shell
   cpan> install Finance::Quote
   cpan> exit

3) Install HTTP::Cookies module using following method which is needed to deal with cookies and crumb:
   #perl -MCPAN -e shell
   cpan> install HTTP::Cookies
   cpan> exit

4) Overwrite YahooJSON.pm found in .../perl/site/lib/Finance/Quote/CurrencyRates directory (did you make back-up of the original?).

```

```
#-## This is a replacement yahooJSON module for Finance::Quote which also adds the cookie and the crumb that may be required. This is retained for historical reason and currently it is not needed, thus use the one provided as part of the oficial release. This version is modified based on version 1.59 of the release.


Install steps (for Windows 11 using Strawberry perl):

1) Install Strawberry perl.

2) Install Finance::Quote module using following method:
   #perl -MCPAN -e shell
   cpan> install Finance::Quote

3) Overwrite YahooJSON.pm found in .../perl/site/lib/Finance/Quote directory (did you make back-up of the original?).

```

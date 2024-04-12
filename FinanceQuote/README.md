```
#-## This is a replacement yahooJSON module for Finance::Quote which also adds the cookie and the crumb that may be required. This mods also make the use of multi-threading, if available,
during the retrieval.

This version is modified based on version 1.59 of the release and works as of 04/12/2024.


Install steps (for Windows 11 using Strawberry perl):

1) Install Strawberry perl.

2) Install Finance::Quote module using following method:
   #perl -MCPAN -e shell
   cpan> install Finance::Quote

3) Overwrite YahooJSON.pm found in .../perl/site/lib/Finance/Quote directory (did you make back-up of the original?).

```

import pandas as pd
import requests
from io import StringIO

#my $url = 'http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=BK&region=1&lang=en';
#my $url = 'https://finance.yahoo.com/quote/BK?p=BK&.tsrc=fin-srch';
url = 'https://www.tsptalk.com/tracker/tsp_fund_price.php';

headers = {
#    "User-Agent" : "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0",
    "User-Agent" : "Mozilla/5.0"
    }

response = requests.get(url, headers=headers)
html_data = StringIO(response.text)

tables = pd.read_html(html_data)
headers = []

table = tables.find("Closing Date")
print (table)

for table in tables:
    if not table.empty:
        for row in table:
            print (row)


# print (len(tables))
# # Access the first table
# first_table = tables[0]

# # Print the head of the DataFrame
# print(first_table)

# # Print the head of the DataFrame
# print(first_table.head())

# $agent->get($url);

# # my $te = HTML::TableExtract->new( headers => [qw('Closing Date' G F C S I L2065 L2060 L2055 L2050 L2045 L2040 L2035 L2030 L2025 Income)] );
# my $te = HTML::TableExtract->new();
# $te->parse($agent->content());

# my @fund;
# my @price;

# open(my $qif_file, ">", $path_to_file . '\quotes.qif')
#     or die "Can't open > .../quotes.qif: $!";
# open(my $quicken_csv_file, ">", $path_to_file . '\quicken_quotes.csv')
#     or die "Can't open > .../quicken_quotes.csv: $!";
# open(my $gnucash_csv_file, ">", $path_to_file . '\gnucash_quotes.csv')
#     or die "Can't open > .../gnucash_quotes.csv: $!";

# # Examine all matching tables; we assume each header and each date price table has only ONE row!
# foreach my $ts ($te->tables) {
#    print "Table found at ", join(',', $ts->coords), ":\n";
#    my $foundHeader = FALSE;
#    foreach my $row ($ts->rows) {
#       if ($ts->cell(0,0) =~ /Closing Date/i) {
#         my @indices = (0..length ($row)-1);
#         $foundHeader = TRUE;
#         print " -- Header found.\n";
#         foreach my $index (@indices) {
#             $fund[$index] = $ts->cell(0, $index);
#         }
#       }
#       my $hdate = $ts->cell(0,0);
#       $hdate =~ s/[*]//g;
#       if ((foundHeader) and ($hdate =~ m/^(\d){4,4}-(\d){2,2}-(\d){2,2}$/)) {
#         my @indices = (1..length ($row)-1);
#         (my $y, my $m, my $d) = split ('-', $hdate);
#         my $date = $m . '/' . $d . '/' . $y;
#         print " -- Pricing row found: date " . $hdate . "\n";
#         foreach my $index (@indices) {
#             $price = $ts->cell(0, $index);
#             my $csv_quote_line = @fund[$index] . ', ' . $price . ', ---, ' . $date . ', ---, ' . $price . ', ' . $price . ', 0.0, *' . "\n";
#             my $gnc_quote_line = '"FUND","' . @fund[$index] . '","' . $date . '",' . $price . ',"USD"' . "\n";
#             my $qif_quote_line = '!Type:Prices' . "\n" . '"' . @fund[$index] . '",' . $price . ',"' . $date . '"' . "\n" . '^' ."\n";
#             print $gnucash_csv_file $gnc_quote_line;
#             print $quicken_csv_file $csv_quote_line;
#             print $qif_file $qif_quote_line;
#         }
#       }
#    }
# }

# close($gnucash_csv_file);
# close($quicken_csv_file);
# close($qif_file);

# # foreach my $row ($te->rows) {
# #    print join(',', @$row), "\n";
# # }
 

# # my $html_page = $agent->text;
 
# # my $stream = HTML::Parser->new();
# # print Dumper($html_page);


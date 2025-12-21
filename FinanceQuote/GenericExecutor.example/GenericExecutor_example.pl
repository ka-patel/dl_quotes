use Finance::Quote;
use Data::Dumper;

use constant DEBUG => $ENV{FQ_GENERICEXECUTOR_DEBUG} || $ENV{FQ_DEBUG} || $ENV{DEBUG};

use if DEBUG, 'Smart::Comments';

my $my_executor = 'python';
$my_executor = $ENV{'GENERIC_EXECUTOR'} if exists $ENV{'GENERIC_EXECUTOR'};
### [<now>]   $my_executor : $my_executor

my $my_fetcher = 'python_example.py';
$my_fetcher = $ENV{'GENERIC_FETCHER'} if exists $ENV{'GENERIC_FETCHER'};
### [<now>]   $my_fetcher  : $my_fetcher

$q = Finance::Quote->new(
        "GenericExecutor", 
        parameters => { EXECUTOR => $my_executor, 
                        FETCHER  => $my_fetcher
                        }
        );

my @ticker = @ARGV;

if (!@ticker) {
    @ticker = (
        "USDUSD=X",
        "^DJI",
    );
}

%info = $q->fetch('run_executor', @ticker);
print Dumper(%info);

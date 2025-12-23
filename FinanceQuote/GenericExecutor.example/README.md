# EXTRA

This directory contains example use of GenericExecutor module that calls 
a Python script. 

Python script utilizes yfinance to fetch and then pandas library for date 
conversion, thus they will need to be installed in Python.

In order for GNUCash to use the module, two required environment variables 
named `GENERIC_EXECUTOR` and `GENERIC_FETCHER` will need to be set. 
`GENERIC_EXECUTOR` set to your favorite interpreter (for enclosed example 
it will simply be 'python') and for `GENERIC_FETCHER` it will be a script
name (for enclosed example it will  be './python_example.py'). Either or 
both can be relative path if they are located in OS's search path, or full 
path that includes the runnable as part of that path.

If F::Q is properly set up then running enclosed perl script will retrieve 
data for Apple and confirm that all is working correctly:

    perl GenericExecutor_example.pl AAPL

With that something like below on stdout should be seen:

$VAR1 = 'AAPLforwardPE';
$VAR2 = '29.629297';
$VAR3 = 'AAPLregion';
$VAR4 = 'US';
...



    use Finance::Quote;
    use Data::Dumper;

    $q = Finance::Quote->new;

    %info = $q->fetch('yahoo_json',"BK");
    print Dumper(%info);


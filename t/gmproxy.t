use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Proxy;
use HTTP::Proxy::GreaseMonkey;
use File::Spec;

ok 1, 'is OK';

my $proxy = HTTP::Proxy->new( port => 8030 );
my $gm = HTTP::Proxy::GreaseMonkey->new();
$proxy->push_filter( response => $gm );
$gm->add_script( File::Spec->catfile( 'gm', 'cpansearch.user.js' ) );

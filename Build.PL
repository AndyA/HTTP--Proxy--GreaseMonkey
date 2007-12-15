use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'HTTP::Proxy::GreaseMonkey',
    license           => 'perl',
    dist_author       => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from => 'lib/HTTP/Proxy/GreaseMonkey.pm',
    requires          => {
        'Test::More' => 0,
    },
    add_to_cleanup => ['HTTP-Proxy-GreaseMonkey-*'],
);

$builder->create_build_script();

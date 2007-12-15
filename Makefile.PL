use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'HTTP::Proxy::GreaseMonkey',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/HTTP/Proxy/GreaseMonkey.pm',
    ABSTRACT_FROM => 'lib/HTTP/Proxy/GreaseMonkey.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'HTTP-Proxy-GreaseMonkey-*' },
);

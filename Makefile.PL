use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

require 5.008;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'HTTP::Proxy::GreaseMonkey',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/HTTP/Proxy/GreaseMonkey.pm',
    ABSTRACT_FROM => 'lib/HTTP/Proxy/GreaseMonkey.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'  => 0,
        'File::Spec'  => 0,
        'Carp'        => 0,
        'HTTP::Proxy' => '0.20',
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTTP-Proxy-GreaseMonkey-*' },
);
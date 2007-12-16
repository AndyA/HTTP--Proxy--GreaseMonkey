#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Proxy;
use HTTP::Proxy::GreaseMonkey;
use HTTP::Proxy::GreaseMonkey::ScriptHome;
use File::Spec;

my $proxy = HTTP::Proxy->new( port => 8030, start_servers => 5 );
my $gm = HTTP::Proxy::GreaseMonkey::ScriptHome->new;
$gm->add_dir( 'gm' );
$proxy->push_filter(
    mime     => 'text/html',
    response => $gm
);
$proxy->start;

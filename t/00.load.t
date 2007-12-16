use Test::More tests => 4;

BEGIN {
    use_ok( 'App::GreaseMonkeyProxy' );
    use_ok( 'HTTP::Proxy::GreaseMonkey' );
    use_ok( 'HTTP::Proxy::GreaseMonkey::Script' );
    use_ok( 'HTTP::Proxy::GreaseMonkey::ScriptHome' );
}

diag(
    "Testing HTTP::Proxy::GreaseMonkey $HTTP::Proxy::GreaseMonkey::VERSION"
);

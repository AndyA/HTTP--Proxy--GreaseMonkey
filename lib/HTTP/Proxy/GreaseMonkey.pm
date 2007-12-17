package HTTP::Proxy::GreaseMonkey;

use warnings;
use strict;
use Carp;
use HTTP::Proxy::GreaseMonkey::Script;
use HTML::Tiny;

use base qw( HTTP::Proxy::BodyFilter );

=head1 NAME

HTTP::Proxy::GreaseMonkey - Run GreaseMonkey scripts in any browser

=head1 VERSION

This document describes HTTP::Proxy::GreaseMonkey version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use HTTP::Proxy;
    use HTTP::Proxy::GreaseMonkey;

    my $proxy = HTTP::Proxy->new( port => 8030 );
    my $gm = HTTP::Proxy::GreaseMonkey->new;
    $gm->add_script( 'gm/myscript.js' );
    $proxy->push_filter(
        mime     => 'text/html',
        response => $gm
    );
    $proxy->start;
  
=head1 DESCRIPTION

GreaseMonkey allows arbitrary user defined Javascript to be run against
specific pages. Unfortunately GreaseMonkey only works with FireFox.

C<HTTP::Proxy::GreaseMonkey> creates a local HTTP proxy that allows
GreaseMonkey user scripts to be used with any browser.

When you install C<HTTP::Proxy::GreaseMonkey> a program called
F<gmproxy> is installed in your default bin directory. To launch the
GreaseMonkey proxy issue a command something like this:

    $ gmproxy ~/.userscripts

By default the proxy will listen on port 8030. The supplied directory is
scanned before each request; any scripts that have been updated or added
will be reloaded and any that have been deleted will be discarded.

=head2 Mac OS

On MacOS F<net.hexten.gmproxy.plist> is created in the project home
directory. Create a directory called F<~/.userscripts> and then add gmproxy
as a launch item:

    $ cp net.hexten.gmproxy.plist ~/Library/LaunchAgents
    $ launchctl load ~/Library/LaunchAgents/net.hexten.gmproxy.plist
    $ launchctl start net.hexten.gmproxy

Then change your network settings to route HTTP through proxy
localhost:8030. Once this is done F<gmproxy> will load automatically
when you log in.

Important: As of 2007-12-17 PubSubAgent crashes periodically (actually
during .mac synchronisation) when HTTP is proxied. The solution appears
to be to add *.mac.com to the list of domains that bypass the proxy. As
far as I'm aware this is a Mac OS problem that has nothing specifically
to do with HTTP::Proxy::GreaseMonkey.

=head2 Other Platforms

Patches welcome from anyone who has equivalent instructions for other
platforms.

=head2 Limitations

Currently none of the GM_* functions are supported. If anyone has a good
idea about how to support them please drop me a line.

=head1 INTERFACE 

=head2 C<< add_script( $script ) >>

Add a GM script to the proxy. The argument may be the filename of a
script or an existing L<HTTP::Proxy::GreaseMonkey::Script>.

=cut

sub add_script {
    my ( $self, $script ) = @_;

    $script = HTTP::Proxy::GreaseMonkey::Script->new( $script )
      unless eval { $script->can( 'script' ) };

    push @{ $self->{script} }, $script;
}

=head2 C<< verbose >>

Set / get verbosity.

=cut

sub verbose {
    my $self = shift;
    $self->{verbose} = shift if @_;
    return $self->{verbose};
}

=head2 C<< will_modify >>

Will this filter modify content? Called by L<HTTP::Proxy>.

=cut

sub will_modify { scalar @{ shift->{to_run} } }

=head2 C<< begin >>

Called at the start of processing.

=cut

sub begin {
    my ( $self, $message ) = @_;

    my $uri = $self->{uri} = $message->request->uri;

    print "Proxying $uri\n" if $self->verbose;

    $self->{to_run} = [];
    for my $script ( @{ $self->{script} } ) {
        if ( $script->match_uri( $uri ) ) {
            # Wrap each script in an anon function to give it a
            # private scope.
            push @{ $self->{to_run} },
              $self->_js_scope( $script->script );
            print "  Filtering with ", $script->name, "\n"
              if $self->verbose;
        }
    }
}

sub _js_scope {
    my $self = shift;
    return join "\n", '( function() {', @_, '} )()';
}

=head2 C<< filter >>

The filter entry point. Called for each chunk of input.

=cut

sub filter {
    my ( $self, $dataref, $message, $protocol, $buffer ) = @_;

    if ( $self->will_modify ) {
        if ( defined $buffer ) {
            $$buffer  = $$dataref;
            $$dataref = "";
        }
        else {
            my $insert = "<script>\n//<![CDATA[\n"
              . $self->_js_scope( $self->get_gm_globals,
                $self->get_support_script, @{ $self->{to_run} } )
              . "\n//]]>\n</script>\n";

            # TODO: Fragile - needs a fairly normal looking </body>
            $$dataref =~ s{</body>}{$insert</body>}ig;
        }
    }
}

=head2 C<< end >>

Finished processing.

=cut

sub end {
    my $self = shift;
    $self->{to_run} = [];
}

=head2 C<< get_passthru_key >>

Get the passthru key that is used to signal to the proxy that it should
rewrite request URLs.

=cut

sub get_passthru_key {
    my $self = shift;
    return $self->{_key} ||= '1234567';
}

=head2 C<< get_gm_globals >>

Return a block of Javascript that initialises various globals that are
required by the GreaseMonkey environment.

=cut

sub get_gm_globals {
    my $self = shift;
    my $h = $self->{_html} ||= HTML::Tiny->new;
    return 'var GM__global = '
      . $h->json_encode(
        {
            uri      => $self->{uri},
            passthru => $self->get_passthru_key
        }
      ) . ";\n";
}

=head2 C<< get_support_script >>

Returns a block of Javascript that is injected before any user scripts.
Typically this code provides the GM_* support functions.

=cut

sub get_support_script {
    my $self = shift;

    return $self->{_support_js} ||= do { local $/; <DATA> };
}

1;

=head1 CONFIGURATION AND ENVIRONMENT
  
HTTP::Proxy::GreaseMonkey requires no configuration files or environment
variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-http-proxy-greasemonkey@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

__DATA__
// GM Support script

function GM_xmlhttpRequest(details) {
    
}

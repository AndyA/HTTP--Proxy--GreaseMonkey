package HTTP::Proxy::GreaseMonkey;

use warnings;
use strict;
use Carp;
use HTTP::Proxy::GreaseMonkey::Script;

use base qw( HTTP::Proxy::BodyFilter );

=head1 NAME

HTTP::Proxy::GreaseMonkey - Run GreaseMonkey scripts in any browser

=head1 VERSION

This document describes HTTP::Proxy::GreaseMonkey version 0.01

=cut

our $VERSION = '0.01';

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

=head2 C<< will_modify >>

Will this filter modify content? Called by L<HTTP::Proxy>.

=cut

sub will_modify { scalar @{ shift->{to_run} } }

=head2 C<< begin >>

Called at the start of processing.

=cut

sub begin {
    my ( $self, $message ) = @_;

    my $uri = $message->request->uri;

    $self->{to_run} = [];
    for my $script ( @{ $self->{script} } ) {
        if ( $script->match_uri( $uri ) ) {
            # Wrap each script in an anon function to give it a
            # private scope.
            push @{ $self->{to_run} },
              '( function() { ' . $script->script . ' } )()';
        }
    }
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
            my $insert
              = "<script>\n//<![CDATA[\n"
              . join( "\n", @{ $self->{to_run} } )
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

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
HTTP::Proxy::GreaseMonkey requires no configuration files or environment variables.

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

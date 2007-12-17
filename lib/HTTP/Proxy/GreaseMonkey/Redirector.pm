package HTTP::Proxy::GreaseMonkey::Redirector;

use warnings;
use strict;
use Carp;

use base qw( HTTP::Proxy::HeaderFilter );

=head1 NAME

HTTP::Proxy::GreaseMonkey::Redirector - Proxy cross-site requests

=head1 VERSION

This document describes HTTP::Proxy::GreaseMonkey::Redirector version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS
  
=head1 DESCRIPTION

=head1 INTERFACE 

=head2 C<< passthru >>

Set the passthru key.

=cut

sub passthru {
    my $self = shift;
    my $key  = quotemeta shift;
    $self->{key} = qr{^/ $key 
                     / ( [-a-z0-9]+ (?: \. [-a-z0-9]+ )+ ) 
                     (/.*) $}xi;
}

=head2 C<< filter >>

Filter the request headers.

=cut

sub filter {
    my ( $self, $headers, $message ) = @_;

    my $key = $self->{key} || return;

    my $uri  = $message->uri;
    my $path = $uri->path;

    if ( $path =~ $key ) {
        # Redirect
        my $real_uri = $uri->scheme . '://' . $1 . $2;
        if ( my $query = $uri->query ) {
            $real_uri = join '?', $real_uri, $query;
        }
        $message->uri( $real_uri );
        $headers->header( host => $1 );
    }
}

1;

__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
HTTP::Proxy::GreaseMonkey::Redirector requires no configuration files or
environment variables.

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

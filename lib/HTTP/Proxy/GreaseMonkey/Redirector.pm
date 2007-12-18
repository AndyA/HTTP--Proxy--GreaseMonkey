package HTTP::Proxy::GreaseMonkey::Redirector;

use warnings;
use strict;
use Carp;
use JSON;
use HTTP::Response;
use HTML::Tiny;
use YAML;

use base qw( HTTP::Proxy::HeaderFilter );

=head1 NAME

HTTP::Proxy::GreaseMonkey::Redirector - Proxy cross-site requests

=head1 VERSION

This document describes HTTP::Proxy::GreaseMonkey::Redirector version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS
  
=head1 DESCRIPTION

=head1 INTERFACE 

=head2 C<< passthru >>

Set the passthru key.

=cut

sub passthru {
    my $self = shift;
    my $key  = quotemeta shift;
    $self->{passthru} = qr{ ^/ $key 
                 / ( [-a-z0-9]+ (?: \. [-a-z0-9]+ )+ ) 
                 (/.*) $}xi;
    $self->{internal} = qr{ ^/ $key 
                 / \$ internal \$ $ }xi;
}

=head2 C<< filter >>

Filter the request headers.

=cut

sub filter {
    my ( $self, $headers, $message ) = @_;

    my $passthru = $self->{passthru} || return;

    my $uri  = $message->uri;
    my $path = $uri->path;

    if ( $path =~ $self->{internal} ) {
        $self->proxy->response(
            $self->_despatch_internal(
                $headers, $message, $uri->query
            )
        );
    }
    elsif ( $path =~ $passthru ) {
        # Redirect
        my $real_uri = $uri->scheme . '://' . $1 . $2;
        if ( my $query = $uri->query ) {
            $real_uri = join '?', $real_uri, $query;
        }
        $message->uri( $real_uri );
        $headers->header( host => $1 );
    }
}

sub _despatch_internal {
    my ( $self, $headers, $message, $query ) = @_;
    return eval {
        # JSON == YAML, right?
        my %handler = (
            setValue => sub { my $args = shift; return 1; },
            getValue => sub { my $args = shift; return 1; },
            log      => sub {
                my $args = shift;
                print join( ': ', $args->{n},
                    join( ' ', @{ $args->{a} } ) ), "\n";
                return 1;
            },
        );

        my $h    = $self->{_html} ||= HTML::Tiny->new;
        my $qs   = $h->url_decode( $query );
        my $args = jsonToObj( $qs );
        # use Data::Dumper;
        # print Dumper( $args );

        my $method = delete $args->{m}
          || die "Missing 'm' arg";
        my $code = $handler{$method}
          || die "No method $method";

        my $result = $code->( $args );

        return HTTP::Response->new(
            200, 'OK',
            [ 'content_type' => 'application/json' ],
            $h->json_encode( $result )
        );
    };

    if ( $@ ) {
        ( my $err = $@ ) =~ s/\s+/ /g;
        return HTTP::Response->new( 500, $err );
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

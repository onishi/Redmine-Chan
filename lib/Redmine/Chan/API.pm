package Redmine::Chan::API;
use strict;
use warnings;

use base qw(WebService::Simple);

use URI;

use Class::Accessor::Lite (
    rw  => [ qw(api_key) ],
);

__PACKAGE__->config(
    base_url        => 'DUMMY',
    response_parser => 'JSON',
);

for my $method (qw/users issue_statuses/) {
    no strict 'refs';
    *{ __PACKAGE__ . "\::$method" } = sub {
        my ($self, %param) = @_;
        return eval {
            $self->get("${method}.json" => { key => $self->{api_key} } )->parse_response->{$method};
        };
    };
}

sub base_url {
    my $self = shift;
    $self->{base_url} = $_[0] ? URI->new($_[0]) : $self->{base_url};
}

1;

__END__

=head1 NAME

Redmine::Chan::API

=head1 SYNOPSIS

    use Redmine::Chan::API;
    my $api = Redmine::Chan::API->new;
    $api->base_url($url);
    $api->api_key($api_key);

=head1 AUTHOR

Yasuhiro Onishi  C<< <yasuhiro.onishi@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Yasuhiro Onishi C<< <yasuhiro.onishi@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


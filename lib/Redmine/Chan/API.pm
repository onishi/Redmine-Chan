package Redmine::Chan::API;
use strict;
use warnings;

use base qw(WebService::Simple);

use URI;

use Class::Accessor::Lite (
    rw  => [ qw(api_key _users _issue_statuses _projects) ],
);

__PACKAGE__->config(
    base_url        => 'DUMMY',
    response_parser => 'JSON',
);

sub base_url {
    my $self = shift;
    $self->{base_url} = $_[0] ? URI->new($_[0]) : $self->{base_url};
}

sub get_data {
    my $self = shift;
    my $url  = shift or return;
    my $key  = shift || $url;
    my $data = eval { $self->get($url => { key => $self->api_key } )->parse_response } or return;
    return $data->{$key};
}

for my $method (qw/users issue_statuses projects/) {
    no strict 'refs';
    *{ __PACKAGE__ . "\::$method" } = sub {
        my ($self, %param) = @_;
        my $cache = '_' . $method;
        return $self->$cache() if $self->$cache();
        return $self->$cache( $self->get_data($method . '.json', $method) );
    };
}

sub reload {
    my $self = shift;
    for my $method (qw/users issue_statuses projects/) {
        my $cache = '_' . $method;
        $self->$cache( $self->get_data($method . '.json', $method) );
    }
}

sub issue {
    my $self = shift;
    my $issue_id = shift or return;
    my $issue = $self->get_data("issues/${issue_id}.json", 'issue');
    return $issue;
}

sub issue_detail {
    my $self = shift;
    my $issue = $self->issue(shift) or return;
    my $subject = join ' ', map {"[$_]"} grep {$_} (
        $issue->{subject},
        $issue->{assigned_to}->{name},
        $issue->{status}->{name},
        #$issue->{custom_fields}->[1]->{value},
    );

    my $uri = $self->base_url->clone;
    my $authority = $uri->authority;
    $authority =~ s{^.*?\@}{}; # URLに認証が含まれてたら消す
    $uri->authority($authority);
    $uri->path("/issues/$issue->{id}");

    return "$uri : $subject\n";
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


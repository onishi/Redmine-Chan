package Redmine::Chan::API;
use strict;
use warnings;

use base qw(WebService::Simple);

use JSON;
use URI;
use Encode qw/decode_utf8/;

my @keys;

BEGIN { @keys = qw/ users issue_statuses projects trackers/ }

use Class::Accessor::Lite (
    rw  => [ qw(api_key issue_fields), map { '_'.$_, $_.'_regexp_hash' } @keys ],
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
    $url .= '.json' unless $url =~ /[.]json$/;
    my $data = eval { $self->get($url => { key => $self->api_key } )->parse_response } or return;
    return $data->{$key};
}

for my $method (@keys) {
    no strict 'refs';
    *{ __PACKAGE__ . "\::$method" } = sub {
        my ($self, %param) = @_;
        my $cache = '_' . $method;
        return $self->$cache() if $self->$cache();
        return $self->$cache( $self->get_data($method) );
    };
    *{ __PACKAGE__ . "\::${method}_summary" } = sub {
        my ($self, %param) = @_;
        my $data = $self->$method;
        my @summary;
        for my $item (sort {$a->{id} <=> $b->{id}} @$data) {
            push @summary, sprintf "%d : %s", $item->{id}, $item->{login} || $item->{name};
        }
        return join ' , ', @summary;
    };
}

sub reload {
    my $self = shift;
    for my $method (@keys) {
        my $cache = '_' . $method;
        my $data = $self->get_data($method);
        $self->$cache($data);
        my $regexp = $method . '_regexp_hash';
        my $hash;
        for my $item (@$data) {
            # TODO: 自由に指定できるように
            my $re = join '|', map { quotemeta } ($item->{login} || $item->{name});
            $hash->{$re} = $item->{id};
        }
        $self->$regexp($hash);
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
    my $fiedls = $self->issue_fields || [qw/subject assigned_to status/];
    my $subject = join ' ', map {"[$_]"} grep {$_} map {
        warn $_;
        /^\d+$/ ? $issue->{custom_fields}->[$_]->{value}
            : ref($issue->{$_}) ? $issue->{$_}->{name} : $issue->{$_}
    } @$fiedls;
    my $uri = $self->base_url->clone;
    my $authority = $uri->authority;
    $authority =~ s{^.*?\@}{}; # URLに認証が含まれてたら消す
    $uri->authority($authority);
    $uri->path("/issues/$issue->{id}");

    return "$uri : $subject\n";
}

sub detect_user_id {
    my $self = shift;
    my $msg = shift;
    my ($user_id, $user_name);
    for my $name ($msg =~ /[\w\-]{3,}/g) {
        for my $user (@{$self->users}) {
            $user->{login} eq $name or next;
            $user_id = $user->{id};
            $user_name = $name;
            last;
        }
    }
    if ($user_id) {
        $msg =~ s{>?\s*\Q$user_name\E}{};
    }
    return ($user_id, $msg);
}

sub detect_tracker_id {
    my $self = shift;
    my $msg = shift;
    my $hash = $self->trackers_regexp_hash;
    my $tracker_id;
    for my $key (keys %{$hash || {}}) {
        if ($msg =~ s{\b\Q$key\E\b}{}) {
            $tracker_id = $hash->{$key};
            last;
        }
    }
    return ($tracker_id, $msg);
}

sub detect_status_id {
    my $self = shift;
    my $msg = shift;
    my $hash = $self->issue_statuses_regexp_hash;
    my $status_id;
    for my $key (keys %{$hash || {}}) {
        if ($msg =~ s{\b\Q$key\E\b}{}) {
            $status_id = $hash->{$key};
            last;
        }
    }
    return ($status_id, $msg);
}

sub detect_due_date {
    my $self = shift;
    my $msg = shift;
    my $due_date;
    if ($msg =~ s|\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b||) {
        $due_date = sprintf '%04d-%02d-%02d', $1, $2, $3;
    }
    return ($due_date, $msg);
}

sub create_issue {
    my ($self, $msg, $project_id) = @_;
    my $issue = {};
    ($msg, $issue) = $self->detect_issue($msg);
    length($msg) or return;
    $issue = {
        %$issue,
        project_id => $project_id,
        subject    => $msg,
    };

    my $res = eval { $self->post(
        'issues.json',
        Content_Type => 'application/json',
        Content => encode_json {
            issue      => $issue,
            project_id => $project_id,
            key        => $self->api_key,
        }
    )->parse_response };
    return $self->issue_detail($res->{issue}->{id});

}

sub update_issue {
    my ($self, $issue_id, $msg) = @_;
    my $issue = {};
    ($msg, $issue) = $self->detect_issue($msg);
    scalar %$issue or return;

    # XXX: WebService::Simple に put 実装されてないので LWP::UserAgent の put 叩いてる
    return $self->put(
        $self->base_url . "issues/${issue_id}.json",
        Content_Type => 'application/json',
        Content => encode_json {
            issue => $issue,
            key   => $self->api_key,
        },
    );
}

sub detect_issue {
    my ($self, $msg) = @_;
    my ($assigned_to_id, $tracker_id, $status_id, $due_date);
    ($assigned_to_id, $msg) = $self->detect_user_id($msg);
    ($tracker_id, $msg)     = $self->detect_tracker_id($msg);
    ($status_id, $msg)      = $self->detect_status_id($msg);
    ($due_date, $msg)       = $self->detect_due_date($msg);
    $msg =~ s{\s+$}{};
    my $issue = {};
    $issue->{assigned_to_id} = $assigned_to_id if $assigned_to_id;
    $issue->{tracker_id} = $tracker_id if $tracker_id;
    $issue->{status_id} = $status_id if $status_id;
    $issue->{due_date} = $due_date if $due_date;
    return ($msg, $issue);
}

sub note_issue {
    my ($self, $issue_id, $note) = @_;

    # XXX: WebService::Simple に put 実装されてないので LWP::UserAgent の put 叩いてる
    return $self->put(
        $self->base_url . "issues/${issue_id}.json",
        Content_Type => 'application/json',
        Content => encode_json {
            issue => {notes => $note},
            key   => $self->api_key,
        },
    );
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


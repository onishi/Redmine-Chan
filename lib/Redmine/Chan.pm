package Redmine::Chan;

use warnings;
use strict;
our $VERSION = '0.01';

use AnyEvent;
use AnyEvent::IRC::Connection;
use AnyEvent::IRC::Client;

use Redmine::Chan::API;
use Redmine::Chan::Recipe;

use Class::Accessor::Lite (
    rw => [ qw(
        irc_server
        irc_port
        irc_channels
        irc_password
        nick
        redmine_url
        redmine_api_key
        api
        recipe
        issue_fields
        status_commands
        custom_field_prefix
        custom_users
     ) ],
);

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;
    my $cv = AnyEvent->condvar;
    my $irc = AnyEvent::IRC::Client->new;
    $self->nick($self->nick || 'minechan');

    my $api = Redmine::Chan::API->new;
    $api->base_url($self->redmine_url);
    $api->api_key($self->redmine_api_key);
    $api->issue_fields($self->issue_fields);
    $api->status_commands($self->status_commands);
    $api->custom_field_prefix($self->custom_field_prefix);
    $api->custom_users($self->custom_users);
    $self->api($api);

    my $recipe = Redmine::Chan::Recipe->new(
        api      => $self->api,
        nick     => $self->nick,
        channels => $self->irc_channels,
    );
    $self->recipe($recipe);

    $irc->reg_cb(
        registered => sub {
            print "registered.\n";
        },
        disconnect => sub {
            print "disconnected.\n";
        },
        publicmsg => sub {
            my ($irc, $channel, $ircmsg) = @_;
            my (undef, $who) = $irc->split_nick_mode($ircmsg->{prefix});
            my $msg = $self->recipe->cook(
                irc     => $irc,
                channel => $channel,
                ircmsg  => $ircmsg,
                who     => $who,
            );
            $irc->send_chan($channel, "NOTICE", $channel, $msg) if $msg;
        },
        privatemsg => sub {
            # TODO
            my ($irc, $channel, $ircmsg) = @_;
            my (undef, $who) = $irc->split_nick_mode($ircmsg->{prefix});
            my $key = $ircmsg->{params}[1];
            my $msg = $api->set_api_key($who, $key);
            $irc->send_msg("PRIVMSG", $who, $msg);
        },
    );
    $self->{cv}  = $cv;
    $self->{irc} = $irc;
}

sub cook {
    my $self = shift;

    $self->api->reload;
    my $cv  = $self->{cv};
    my $irc = $self->{irc};
    my $info = {
        nick     => $self->nick,
        real     => $self->nick,
        password => $self->irc_password,
    };
    $irc->connect($self->irc_server, $self->irc_port || 6667, $info);
    for my $name (keys %{$self->irc_channels}) {
        $irc->send_srv("JOIN", $name);
    }
    $cv->recv;
    $irc->disconnect;
}

*run = \&cook;

1;

__END__

=head1 NAME

Redmine::Chan

=head1 SYNOPSIS

    use Redmine::Chan;
    my $minechan = Redmine::Chan->new(
        irc_server      => 'irc.example.com', # irc
        irc_port        => 6667,
        irc_password    => '',
        irc_channels    => {
            '#channel' => { # irc channel name
                key        => '', # irc channel key
                project_id => 1,  # redmine project id
                charset    => 'iso-2022-jp',
            },
        },
        redmine_url     => $redmine_url,
        redmine_api_key => $redmine_api_key,

        # optional config
        status_commands => {
            1 => [qw/hoge/], # change status command
        },
        custom_field_prefix => {
            1 => [qw(prefix)], # prefix to change custome field
        },
        issue_fields => [qw/subject/], # displayed issue fields
    );
    $minechan->cook;

=head1 AUTHOR

Yasuhiro Onishi  C<< <yasuhiro.onishi@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Yasuhiro Onishi C<< <yasuhiro.onishi@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


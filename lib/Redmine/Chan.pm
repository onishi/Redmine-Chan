package Redmine::Chan;

use warnings;
use strict;
our $VERSION = '0.01';

use AnyEvent;
use AnyEvent::IRC::Connection;
use AnyEvent::IRC::Client;

use Redmine::Chan::API;

use Class::Accessor::Lite (
    rw => [ qw( irc_server irc_port irc_channel irc_password nick redmine_url redmine_api_key ) ],
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
    $irc->reg_cb(
        connect => sub {
            my ($irc, $err) = @_;
            if (defined $err) {
                warn "connect error: $err\n";
                $cv->send;
            }
        },
        publicmsg => sub {
            my ($irc, $channel, $ircmsg) = @_;
            my $msg = $ircmsg->{params}[1];
            $irc->send_chan($channel, "PRIVMSG", $channel, $msg);
        },
        privatemsg => sub {
            # TODO
            my ($irc, $channel, $ircmsg) = @_;
            my (undef, $who) = $irc->split_nick_mode($ircmsg->{prefix});
            my $msg = $ircmsg->{params}[1];
            $irc->send_srv("JOIN", $who);
            $irc->send_msg("PRIVMSG", $who, $msg);
        },
        registered => sub {
            print "registered.\n";
        },
        disconnect => sub {
            print "disconnected.\n";
        },
    );
    $self->{cv}  = $cv;
    $self->{irc} = $irc;

    $self->{api} = Redmine::Chan::API->new;
    $self->{api}->base_url($self->redmine_url);
    $self->{api}->api_key($self->redmine_api_key);
}

sub run {
    my $self = shift;
    my $cv  = $self->{cv};
    my $irc = $self->{irc};
    my $info = {
        nick     => $self->nick || 'minechan',
        real     => $self->nick || 'minechan',
        password => $self->irc_password,
    };
    my $channel = $self->irc_channel;
    $irc->connect($self->irc_server, $self->irc_port || 6667, $info);
    $irc->send_srv("JOIN", $channel);
    $cv->recv;
    $irc->disconnect;
}

*cook = \&run;

1;

__END__

=head1 NAME

Redmine::Chan

=head1 SYNOPSIS

    use Redmine::Chan;
    my $minechan = Redmine::Chan->new(
        irc_server      => $irc_server,
        irc_port        => $irc_port,
        irc_password    => $irc_password,
        irc_channel     => $irc_channel,
        redmine_url     => $redmine_url,
        redmine_api_key => $redmine_api_key,
    );
    $minechan->cook;

=head1 AUTHOR

Yasuhiro Onishi  C<< <yasuhiro.onishi@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Yasuhiro Onishi C<< <yasuhiro.onishi@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


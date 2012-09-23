package Redmine::Chan::Recipe;
use strict;
use warnings;

use Encode qw/decode encode/;

use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw( api nick channels ) ],
);

sub cook {
    my ($self, %args) = @_;
    my $irc     = $args{irc} or return;
    my $ircmsg  = $args{ircmsg} or return;
    my $channel = $self->channel($args{channel}) or return;
    my $api     = $self->api;
    my $msg     = $ircmsg->{params}[1];
    my $charset = $channel->{charset} || 'iso-2022-jp';
    $msg = decode $charset, $msg;

    # 1行バッファにためる
    $self->{buffer} = $msg;

    # TODO
    # issue 登録

    my $reply = '';
    if ($msg =~ /\#(\d+)/) {
        # issue 確認
        my $issue_id = $1;
        $reply = $api->issue_detail($issue_id);
    }

    if (1) {
    } else {
        # 何もしない
        return;
    }
    $reply or return;
    $reply = encode $charset, $reply;
    return $reply;
}

sub channel {
    my $self = shift;
    my $name = shift or return;
    my $channel = $self->channels->{$name};
    $channel->{name} = $name;
    return $channel;
}

1;

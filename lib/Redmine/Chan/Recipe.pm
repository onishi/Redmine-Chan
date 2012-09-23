package Redmine::Chan::Recipe;
use strict;
use warnings;

use Encode qw/decode/;

use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw( api nick channels ) ],
);

sub cook {
    my ($self, %args) = @_;
    my $irc     = $args{irc} or return;
    my $ircmsg  = $args{ircmsg} or return;
    my $channel = $self->channel($args{channel}) or return;
    my $msg     = $ircmsg->{params}[1];
    $msg = decode $channel->{charset} || 'iso-2022-jp', $msg;

    # 1行バッファにためる
    $self->{buffer} = $msg;

    # $irc->send_msg("PRIVMSG", $channel, $msg);

    # issue 登録
    # issue 確認
    # 
}

sub channel {
    my $self = shift;
    my $name = shift or return;
    return $self->channels->{$name};
}

1;

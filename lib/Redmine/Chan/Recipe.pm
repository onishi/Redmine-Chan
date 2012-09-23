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
    my $nick    = $self->nick;
    my $msg     = $ircmsg->{params}[1];
    my $charset = $channel->{charset} || 'iso-2022-jp';
    $msg = decode $charset, $msg;

    # TODO
    # issue に note
    # issue 更新
    # - assign
    # - トラッカー
    # custom_fields
    # - 更新
    # - 表示
    # - 期日

    my $reply = '';

    # if ($msg =~ /^(users|trackers|projects|issue_statuses)$/) {
    #     # API サマリ
    #     my $method = $1 . '_summary';
    #     my $summary = $api->$method;
    #     $irc->send_long_message(undef, 0, "PRIVMSG\001ACTION", $channel, $summary);
    #     return;
    # }

    if ($msg =~ /^reload$/) {
        # 設定再読み込み
        $api->reload;
        $reply = 'reloaded';
    } elsif ($msg =~ /^\Q$nick\E:?\s+(.+)/) {
        # issue 登録
        $reply = $api->create_issue($1, $channel->{project_id});
    } elsif ($msg =~ /\#(\d+)/) {
        # issue 確認/update
        my $issue_id = $1;
        $api->update_issue($1, $msg);
        $reply = $api->issue_detail($issue_id);
    } else {
        # 何もしない
        # 1行バッファにためる
        $self->{buffer} = $msg;
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

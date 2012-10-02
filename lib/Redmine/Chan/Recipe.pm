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
    my $who     = $args{who} or return;
    my $channel = $self->channel($args{channel}) or return;
    my $api     = $self->api;
    my $nick    = $self->nick;
    my $msg     = $ircmsg->{params}[1];
    my $charset = $channel->{charset} || 'iso-2022-jp';
    $api->who($who);
    $msg = decode $charset, $msg;

    my $reply = '';

    if ($msg =~ /^(users|trackers|projects|issue_statuses|issues)$/) {
        # API サマリ
        my $method = $1 . '_summary';
        my @args;
        if ($method eq 'issues_summary') {
            @args = (
                nick        => $who,
                project_id  => $channel->{project_id},
            );
        }
        my $summary = $api->$method(@args);
        $irc->send_long_message($charset, 0, "NOTICE", $channel->{name}, $summary);
        return;
    }

    if ($msg eq 'reload') {
        # 設定再読み込み
        $api->reload;
        $reply = 'reloaded';
    } elsif ($msg eq '..') {
        # 上の行をissue登録
        $reply = $api->create_issue(delete $self->{buffer} || '', $channel->{project_id});
    } elsif ($msg =~ /^\Q$nick\E:?\s+(.+)/) {
        # issue 登録
        $reply = $api->create_issue($1, $channel->{project_id});
    } elsif ($msg =~ /^(.+?)\s*>\s*\#(\d+)$/) {
        # note 追加
        my ($note, $issue_id) = ($1, $2);
        $api->note_issue($issue_id, $note);
        $reply = $api->issue_detail($issue_id);
    } elsif ($msg =~ /\#(\d+)/) {
        # issue 確認/update
        my $issue_id = $1;
        $api->update_issue($issue_id, $msg);
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

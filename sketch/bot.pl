#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Config::Pit;
use Redmine::Chan;
use utf8;

my $minechan = Redmine::Chan->new(%{pit_get('redmine', require => {
    irc_server      => '',
    irc_port        => '',
    irc_password    => '',
    redmine_url     => '',
    redmine_api_key => '',
})},
    irc_channels    => {
        '#onishi'  => { project_id => 6 },
        '#onitest' => { project_id => 6 },
    },
    status_commands => {
        1 => [qw/new/], # 新規
        2 => [qw/ongoing doing/], # 進行中
        3 => [qw/レビューお願いします レビューおねがいします/], # レビュー待ち
        4 => [qw/レビューします/], # レビュー中
        7 => [qw/レビューしました/], # リリース待ち
        6 => [qw/done/], # 終了
    },
    issue_fields => [qw/subject assigned_to status 1/],
);
$minechan->cook;

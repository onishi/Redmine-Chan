#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Config::Pit;
use Redmine::Chan;

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
);
$minechan->cook;

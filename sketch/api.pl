#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Redmine::Chan::API;
use Data::Dumper;
use Config::Pit;

my $config = pit_get('redmine', require => {
    base_url => 'base_url',
    api_key  => 'api_key',
});

my $api = Redmine::Chan::API->new();
$api->base_url($config->{base_url});
$api->api_key($config->{api_key});

warn Dumper($api->users);
warn Dumper($api->issue_statuses);
warn Dumper($api->projects);

$api->reload;

warn $api->users;
warn $api->issue_statuses;
warn $api->projects;

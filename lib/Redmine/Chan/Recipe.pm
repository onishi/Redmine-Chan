package Redmine::Chan::Recipe;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw( api nick ) ],
);

sub cook {
    my ($self, %args) = @_;
    my $irc     = $args{irc} or return;
    my $channel = $args{channel} or return;
    my $ircmsg  = $args{ircmsg} or return;
    my $msg     = $ircmsg->{params}[1];
    
    $irc->send_msg("PRIVMSG", $channel, $msg);
}

1;

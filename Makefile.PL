use inc::Module::Install;
name 'Redmine-Chan';
all_from 'lib/Redmine/Chan.pm';

requires 'AnyEvent::IRC::Client';
requires 'WebService::Simple';
requires 'Config::Pit';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;

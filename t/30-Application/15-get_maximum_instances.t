#!perl

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 4;

use lib 't/';
use LocalTest;

use IPC::Concurrency::DBI::Application;


can_ok(
	'IPC::Concurrency::DBI::Application',
	'get_maximum_instances',
);

my $dbh = LocalTest::ok_database_handle();

my $application;
lives_ok(
	sub
	{
		$application = IPC::Concurrency::DBI::Application->new(
			database_handle   => $dbh,
			name              => 'cron_script.pl',
		);
	},
	'Instantiate application.',
);

is(
	$application->get_maximum_instances(),
	10,
	'Check the maximum instances allowed.',
);

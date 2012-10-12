#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 4;

use lib 't/';
use LocalTest;

use IPC::Concurrency::DBI::Application;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'IPC::Concurrency::DBI::Application',
	'get_database_handle',
);

my $application;
lives_ok(
	sub
	{
		$application = IPC::Concurrency::DBI::Application->new(
			database_handle   => $dbh,
			id                => 1,
		);
	},
	'Instantiate application.',
);

is(
	$application->get_database_handle(),
	$dbh,
	'The database connection handle returned by get_database_handle() matches the one passed to create the object.',
);


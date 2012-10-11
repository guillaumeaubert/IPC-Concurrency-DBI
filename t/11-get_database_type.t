#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 4;

use lib 't/';
use LocalTest;

use IPC::Concurrency::DBI;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'IPC::Concurrency::DBI',
	'get_database_type',
);

my $concurrency_manager;
lives_ok(
	sub
	{
		$concurrency_manager = IPC::Concurrency::DBI->new(
			'database_handle' => $dbh,
		);
	},
	'Instantiate a new IPC::Concurrency::DBI object.',
);

like(
	$concurrency_manager->get_database_type(),
	qr/^(?:SQLite|mysql|Pg)$/,
	'The database type is correctly determined.',
);


#!perl

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 2;

use lib 't/';
use LocalTest;

use IPC::Concurrency::DBI;


my $dbh = LocalTest::ok_database_handle();

my $concurrency_manager = IPC::Concurrency::DBI->new(
	'database_handle' => $dbh,
	'verbose'         => 0,
);

lives_ok(
	sub
	{
		$concurrency_manager->create_tables(
			database_type => 'SQLite',
		);
	},
	'Create table(s).',
);

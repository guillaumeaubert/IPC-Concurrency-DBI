#!perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/';
use LocalTest;

use IPC::Concurrency::DBI;


my $dbh = LocalTest::ok_database_handle();

my $concurrency_manager = IPC::Concurrency::DBI->new(
	'database_handle' => $dbh,
	'verbose'         => 0,
);

eval
{
	$concurrency_manager->create_tables(
		database_type => 'SQLite',
	);
};

ok(
	!$@,
	'Create table(s).',
) || diag( $@ );

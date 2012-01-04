#!perl

use strict;
use warnings;

use Test::More tests => 2;
use DBI;

use IPC::Concurrency::DBI;


ok(
	my $dbh = DBI->connect(
		'dbi:SQLite:dbname=test_database',
		'',
		'',
		{
			RaiseError => 1,
		}
	),
	'Create connection to a SQLite database',
);

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

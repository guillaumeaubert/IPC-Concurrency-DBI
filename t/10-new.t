#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
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

my $concurrency_manager;
eval
{
	# Configure the concurrency object.
	$concurrency_manager = IPC::Concurrency::DBI->new(
		'database_handle' => $dbh,
		'verbose'         => 0,
	);
};
ok(
	!$@,
	'Create a new IPC::Concurrency::DBI object.',
) || diag( $@ );

ok(
	defined( $concurrency_manager ),
	'The object is defined.',
);

ok(
	$concurrency_manager->isa( 'IPC::Concurrency::DBI' ),
	'The object is of type IPC::Concurrency::DBI.',
);

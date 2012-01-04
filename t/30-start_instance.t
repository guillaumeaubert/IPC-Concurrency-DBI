#!perl

use strict;
use warnings;

use Test::More tests => 6;
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

ok(
	$concurrency_manager->register_application(
		name              => 'program_with_maximum_2_instances',
		maximum_instances => 2,
	),
	'Register an application with a maximum of 2 parallel instances.',
);

my $application = $concurrency_manager->get_application(
	name => 'program_with_maximum_2_instances',
);
ok(
	defined( $application ),
	'Retrieve application.',
);

my $instance = $application->start_instance();
ok(
	defined( $instance ),
	'Start a first instance.',
);

my $instance2 = $application->start_instance();
ok(
	defined( $instance2 ),
	'Start a second instance.',
);

my $instance3 = $application->start_instance();
ok(
	!defined( $instance3 ),
	'Fail to start a third instance.',
);

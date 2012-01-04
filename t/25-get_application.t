#!perl

use strict;
use warnings;

use Test::More tests => 4;
use DBI;

use IPC::Concurrency::DBI;


my $tests_by_name =
[
	{
		test_name         => 'Get application cron_script.pl.',
		name              => 'cron_script.pl',
		expected_result   => 'success',
	},
	{
		test_name         => 'Get application cron_script2.pl.',
		name              => 'cron_script2.pl',
		expected_result   => 'success',
	},
	{
		test_name         => 'Fail to retrieve an application that was not registered.',
		name              => 'cron_script3.pl',
		expected_result   => 'failure',
	},
];

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

foreach my $test ( @$tests_by_name )
{
	my $application;
	eval
	{
		$application = $concurrency_manager->get_application(
			name => $test->{'name'},
		);
	};
	
	is(
		$@ || !defined( $application ) ? 'failure' : 'success',
		$test->{'expected_result'},
		$test->{'test_name'},
	) || diag( $@ ? "Error: $@." : "No error reported." );
}

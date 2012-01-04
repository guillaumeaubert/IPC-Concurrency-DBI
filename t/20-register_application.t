#!perl

use strict;
use warnings;

use Test::More tests => 8;
use DBI;

use IPC::Concurrency::DBI;


my $tests =
[
	{
		test_name         => 'Do not allow registering an application without name.',
		name              => undef,
		maximum_instances => 10,
		expected_result   => 'failure',
	},
	{
		test_name         => 'Do not allow registering an application without maximum instances set.',
		name              => 'cron_script.pl',
		maximum_instances => undef,
		expected_result   => 'failure',
	},
	{
		test_name         => 'Do not allow registering an application with an incorrect value for maximum instances.',
		name              => 'cron_script.pl',
		maximum_instances => 'a',
		expected_result   => 'failure',
	},
	{
		test_name         => 'Register application cron_script.pl.',
		name              => 'cron_script.pl',
		maximum_instances => 10,
		expected_result   => 'success',
	},
	{
		test_name         => 'Do not allow registering twice an application with the same name.',
		name              => 'cron_script.pl',
		maximum_instances => 10,
		expected_result   => 'failure',
	},
	{
		test_name         => 'Register application cron_script2.pl.',
		name              => 'cron_script2.pl',
		maximum_instances => 5,
		expected_result   => 'success',
	},
	{
		test_name         => 'Do not allow registering an application with a name longer than 255 characters.',
		name              => ( '=' x 256 ),
		maximum_instances => 5,
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

foreach my $test ( @$tests )
{
	eval
	{
		# If we expect a failure, don't warn.
		# If we expect a success, output the warnings normally.
		local $SIG{__WARN__} = sub
		{
			warn $_[0]
				if $test->{'expected_result'} eq 'success';
		};
		
		$concurrency_manager->register_application(
			name              => $test->{'name'},
			maximum_instances => $test->{'maximum_instances'},
		);
	};
	
	is(
		$@ ? 'failure' : 'success',
		$test->{'expected_result'},
		$test->{'test_name'},
	) || diag( $@ ? "Error: $@." : "No error reported." );
}

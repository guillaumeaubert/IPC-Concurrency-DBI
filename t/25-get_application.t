#!perl

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 4;

use lib 't/';
use LocalTest;

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

my $dbh = LocalTest::ok_database_handle();

my $concurrency_manager = IPC::Concurrency::DBI->new(
	'database_handle' => $dbh,
	'verbose'         => 0,
);

foreach my $test ( @$tests_by_name )
{
	my $test_sub = sub
	{
		my $application = $concurrency_manager->get_application(
			name => $test->{'name'},
		);
		
		die 'Application not instantiated'
			if !defined( $application );
	};
	
	if ( $test->{'expected_result'} eq 'success' )
	{
		lives_ok(
			sub { $test_sub->() },
			$test->{'test_name'},
		);
	}
	else
	{
		dies_ok(
			sub { $test_sub->() },
			$test->{'test_name'},
		);
	}
}


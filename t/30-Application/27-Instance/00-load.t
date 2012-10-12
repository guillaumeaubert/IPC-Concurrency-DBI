#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
	use_ok( 'IPC::Concurrency::DBI::Application::Instance' ) || print "Bail out!\n";
}

diag( "IPC::Concurrency::DBI::Application::Instance $IPC::Concurrency::DBI::Application::Instance::VERSION, Perl $], $^X" );

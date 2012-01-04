#!perl

use strict;
use warnings;

use Test::More tests => 1;

SKIP:
{
	skip( 'Temporary database file does not exist.', 1 )
		if ! -e 'test_database';
	
	ok(
		unlink( 'test_database' ),
		'Remove temporary database file',
	);
}
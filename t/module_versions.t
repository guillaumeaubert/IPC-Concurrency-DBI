#!perl -T

use strict;
use warnings;

use Test::More tests => 9;
use Data::Dumper;


ok(
	open( MANIFEST, 'MANIFEST' ),
	'Retrieve MANIFEST file.',
) || diag( "Failed to open MANIFEST file: $!." );

my $modules = [];
foreach my $file ( <MANIFEST> )
{
	chomp( $file );
	next unless $file =~ m/^lib\/(.*)\.pm$/;
	
	my $module = $1;
	$module =~ s/\//::/g;
	push( @$modules, $module );
}

isnt(
	scalar( @$modules ),
	0,
	'Find modules to verify.',
);

my $versions = {};
foreach my $module ( @$modules )
{
	use_ok( $module );
	
	my $version = $module->VERSION();
	ok(
		defined( $version ),
		"Module $module declares a version.",
	);
	
	$versions->{ $version } ||= [];
	push( @{ $versions->{ $version } }, $module );
}

is(
	scalar( keys %$versions ),
	1,
	'The modules declare only one version.',
) || diag( 'Versions and the modules they were found in: ' . Dumper( $versions ) );

package IPC::Concurrency::DBI;

use warnings;
use strict;

use Data::Dumper;
use Carp;

use IPC::Concurrency::DBI::Application;


=head1 NAME

IPC::Concurrency::DBI - Control how many instances of an application run in parallel, using DBI as the IPC method.


=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module controls how many instances of a given program are allowed to run
in parallel. It does not manage forking or starting those instances.

You can use this module for example to prevent more than one instance of a
program from running at any given time, or to never have more than N instances
running in parallel to prevent exhausting all the available resources.

It uses DBI as a storage layer for information about instances and applications,
which is particularly useful in contexts where Sarbanes-Oxley regulations allow
you database access but not file write rights in production environments.

Note that currently only MySQL and SQLite are fully tested. Patches or testing
environments for other DBD::* modules are welcome.

	# Configure the concurrency object.
	use IPC::Concurrency::DBI;
	my $concurrency_manager = IPC::Concurrency::DBI->new(
		'database_handle' => $dbh,
		'verbose'         => 1,
	);
	
	# Create the tables that the concurrency manager needs to store information
	# about the applications and instances.
	$concurrency_manager->create_tables();
	
	# Register cron_script.pl as an application we want to limit to 10 parallel
	# instances. We only need to do this once, obviously.
	$concurrency_manager->register_application(
		name              => 'cron_script.pl',
		maximum_instances => 10,
	);
	
	# Retrieve the application.
	my $application = $concurrency_manager->get_application(
		name => 'cron_script.pl',
	);
	
	# Count how many instances are currently running.
	my $instances_count = $application->get_instances_count();
	
	# NOT IMPLEMENTED YET: Get a list of what instances are currently running.
	# my $instances = $application->get_instances_list()
	
	# Start a new instance of the application. If this returns undef, we've
	# reached the limit.
	unless ( my $instance = $application->start_instance() )
	{
		print "Too many instances of $0 are already running.\n";
		exit;
	}
	
	# [...] Do some work.
	
	# Now that the application is about to exit, flag the instance as completed.
	# (note: this is implicit when $instance is destroyed).
	$instance->finish();


=head1 METHODS

=head2 new()

Create a new IPC::Concurrency::DBI object.

	my $concurrency_manager = IPC::Concurrency::DBI->new(
		'database_handle'   => $dbh,
		'verbose'           => 1,
	);

'database handle': mandatory, a DBI object.

'verbose': optional, see verbose() for options.

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $database_handle = delete( $args{'database_handle'} );
	my $verbose = delete( $args{'verbose'} );
	
	# Check parameters.
	croak "Argument 'database_handle' is required to create a new IPC::Concurrency::DBI object"
		unless defined( $database_handle );
	croak "Argument 'database_handle' is not a DBI object"
		unless $database_handle->isa( 'DBI::db' );
	
	# Create the object.
	my $self = bless(
		{
			'database_handle' => $database_handle,
			'verbose'         => 0,
		},
		$class,
	);
	
	$self->verbose( $verbose )
		if defined( $verbose );
	
	return $self;
}


=head2 verbose()

Control the verbosity of the warnings in the code.

	$queue->verbose(1); # turn on verbose information
	
	$queue->verbose(0); # quiet now!
	
	warn 'Verbose' if $queue->verbose(); # getter-style
	
Allows turning on/off debugging information.

=cut

sub verbose
{
	my ( $self, $verbose ) = @_;
	
	$self->{'verbose'} = ( $verbose || 0 )
		if defined( $verbose );
	
	return $self->{'verbose'};
}


=head2 register_application()

Register a new application with the concurrency manager and define the maximum
number of instances that should be allowed to run in parallel.

	$concurrency_manager->register_application(
		name              => 'cron_script.pl',
		maximum_instances => 10,
	);

'name' is a unique name for the application. It can be the name of the script
for a cron script, for example.

'maximum_instances' is the maximum number of instances that should be allowed to
run in parallel.

=cut

sub register_application
{
	my ( $self, %args ) = @_;
	my $name = delete( $args{'name'} );
	my $maximum_instances = delete( $args{'maximum_instances'} );
	
	# Check parameters.
	croak 'The name of the application must be defined'
		if !defined( $name ) || ( $name eq '' );
	croak 'The application name is longer than 255 characters'
		if length( $name ) > 255;
	croak 'The maximum number of instances must be defined'
		if !defined( $maximum_instances ) || ( $maximum_instances eq '' );
	croak 'The maximum number of instances must be a strictly positive integer'
		if ( $maximum_instances !~ m/^\d+$/ ) || ( $maximum_instances <= 0 );
	
	# Insert the new application.
	my $database_handle = $self->_get_database_handle();
	my $time = time();
	my $rows_affected = $database_handle->do(
		q|
			INSERT INTO ipc_concurrency_applications( name, current_instances, maximum_instances, created, modified )
			VALUES( ?, 0, ?, ?, ? )
		|,
		{},
		$name,
		$maximum_instances,
		$time,
		$time,
	);
	
	return defined( $rows_affected ) && $rows_affected == 1 ? 1 : 0;
}


=head2 get_application()

Retrieve an application by name or by application ID.

	# Retrieve the application by name.
	my $application = $concurrency_manager->get_application(
		name => 'cron_script.pl',
	);
	die 'Application not found'
		unless defined( $application );
	
	# Retrieve the application by ID.
	my $application = $concurrency_manager->get_application(
		id => 12345,
	);
	die 'Application not found'
		unless defined( $application );

=cut

sub get_application
{
	my ( $self, %args ) = @_;
	my $name = delete( $args{'name'} );
	my $application_id = delete( $args{'id'} );
	my $database_handle = $self->_get_database_handle();
	
	return IPC::Concurrency::DBI::Application->new(
		name            => $name,
		id              => $application_id,
		database_handle => $database_handle,
	);
}


=head2 create_tables()

Create the tables that the concurrency manager needs to store information about
the applications and instances.

	$concurrency_manager->create_tables(
		drop_if_exist => $boolean,      #default 0
		database_type => $database_type #default SQLite
	);

By default, it won't drop any table but you can force that by setting
'drop_if_exist' to 1.

'database_type' currently supports 'SQLite' and 'MySQL'. Patches or requests
for other DBD::* modules are welcome!

=cut

sub create_tables
{
	my ( $self, %args ) = @_;
	my $drop_if_exist = delete( $args{'drop_if_exist'} );
	my $database_type = delete( $args{'database_type'} );
	my $database_handle = $self->_get_database_handle();
	
	# Defaults.
	$drop_if_exist = 0
		unless defined( $drop_if_exist ) && $drop_if_exist;
	$database_type = 'MySQL'
		unless defined( $database_type );
	
	# Check parameters.
	croak 'This database type is not supported yet. Please email the maintainer of the module for help.'
		unless $database_type =~ m/^(SQLite|MySQL)$/;
	
	# Create the table that will hold the list of applications as well as
	# a summary of the information about instances.
	$database_handle->do( q|DROP TABLE IF EXISTS ipc_concurrency_applications| )
		if $drop_if_exist;
	$database_handle->do(
		$database_type eq 'SQLite'
		? q|
			CREATE TABLE ipc_concurrency_applications
			(
				ipc_concurrency_application_id INTEGER PRIMARY KEY AUTOINCREMENT,
				name varchar(255) NOT NULL,
				current_instances INTEGER NOT NULL default '0',
				maximum_instances INTEGER NOT NULL default '0',
				created bigint(20) NOT NULL default '0',
				modified bigint(20) NOT NULL default '0',
				UNIQUE (name)
			)
		|
		: q|
			CREATE TABLE ipc_concurrency_applications
			(
				ipc_concurrency_application_id BIGINT(20) UNSIGNED NOT NULL auto_increment,
				name VARCHAR(255) NOT NULL,
				current_instances INT(10) UNSIGNED NOT NULL default '0',
				maximum_instances INT(10) UNSIGNED NOT NULL default '0',
				created bigint(20) UNSIGNED NOT NULL default '0',
				modified bigint(20) UNSIGNED NOT NULL default '0',
				PRIMARY KEY (ipc_concurrency_application_id),
				UNIQUE KEY idx_name (name)
			)
			ENGINE=InnoDB
		|
	);
	
	# TODO: create a separate table to hold information about what instances
	# are currently running.
	
	return 1;
}


=head1 INTERNAL METHODS

=head2 _get_database_handle()

Returns the database handle used for this queue.

	my $database_handle = $concurrency_manager->_get_database_handle();

=cut

sub _get_database_handle
{
	my ( $self ) = @_;
	
	return $self->{'database_handle'};
}


=head1 AUTHOR

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-concurrency-dbi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-Concurrency-DBI>. 
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc IPC::Concurrency::DBI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-Concurrency-DBI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-Concurrency-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-Concurrency-DBI>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC-Concurrency-DBI/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to ThinkGeek (L<http://www.thinkgeek.com/>) and its corporate overlords
at Geeknet (L<http://www.geek.net/>), for footing the bill while I eat pizza
and write code for them!

Thanks to Jacob Rose C<< <jacob at thinkgeek.com> >> for suggesting the idea of
this module and brainstorming with me about the features it should offer.


=head1 COPYRIGHT & LICENSE

Copyright 2011-2012 Guillaume Aubert.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/

=cut

1;

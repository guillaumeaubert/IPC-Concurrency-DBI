package IPC::Concurrency::DBI::Application::Instance;

use warnings;
use strict;

use Data::Dumper;
use Carp;


=head1 NAME

IPC::Concurrency::DBI::Application::Instance - Application instance that represents consumption of the limited resource.


=head1 VERSION

Version 1.0.2

=cut

our $VERSION = '1.0.2';


=head1 SYNOPSIS

This module represents one instance of an application managed by
IPC::Concurrency::DBI.

See the documentation of IPC::Concurrency::DBI for more information.

	my $instance = $concurrent_program->start_instance();
	unless ( defined( $instance ) )
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

Create a new IPC::Concurrency::DBI::Application::Instance object.

This function should not be called directly and its API could change, instead
use IPC::Concurrency::DBI::Application::start_instance().

	# Retrieve the application by name.
	my $instance = IPC::Concurrency::DBI::Application::Instance->new(
		application => $application,
	);

'application': mandatory, an IPC::Concurrency::DBI::Application object.

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $application = delete( $args{'application'} );
	
	# Check parameters.
	croak "Argument 'application' is required to create a new IPC::Concurrency::DBI::Application::Instance object"
		unless defined( $application );
	croak "Argument '$application' is not an IPC::Concurrency::DBI::Application"
		unless $application->isa( 'IPC::Concurrency::DBI::Application' );
	
	# Create the object.
	my $self = bless(
		{
			application => $application,
			finished    => 0,
		},
		$class,
	);
	
	return $self;
}


=head2 finish()

Declare that the current instance has finished running and free the slot for
a new instance.

=cut

sub finish
{
	my ( $self ) = @_;
	my $application = $self->_get_application();
	my $database_handle = $application->_get_database_handle();
	
	# If the object has already been destroyed, we have a problem.
	croak 'The instance has already been marked as finished'
		if $self->{'finished'};
	
	# Decrement the count of running instances, provided that it's > 0.
	# We should never encounter the case that would make it go negative, but
	# being careful never hurts.
	my $rows_affected = $database_handle->do(
		q|
			UPDATE ipc_concurrency_applications
			SET current_instances = current_instances - 1, modified = ?
			WHERE ipc_concurrency_application_id = ?
				AND current_instances > 0
		|,
		{},
		time(),
		$application->get_id(),
	);
	
	$self->{'finished'} = 1;
	
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
	
	my $application = $self->get_application();
	croak 'The Instance object does not reference an application'
		unless defined( $application );
	
	return $application->_get_database_handle();
}


=head2 _get_application()

Returns the parent IPC::Concurrency::DBI::Application object.

	my $application = $instance->_get_application();

=cut

sub _get_application
{
	my ( $self ) = @_;
	
	return $self->{'application'};
}


=head2 DESTROY()

Automatically clear the slot used by the current instance when the object
is destroyed, if finish() has not been called already.

=cut

sub DESTROY
{
	my( $self ) = @_;
	
	$self->finish()
		unless $self->{'finished'};
	
	$self->SUPER::DESTROY()
		if $self->can( 'SUPER::DESTROY' );
	
	return;
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

package LocalTest;

use strict;
use warnings;

use DBI;
use Test::More;


=head1 NAME

LocalTest - Test functions for L<IPC::Concurrency::DBI>.


=head1 VERSION

Version 2.4.2

=cut

our $VERSION = '2.4.2';


=head1 SYNOPSIS

	use lib 't/';
	use LocalTest;
	
	my $dbh = LocalTest::ok_database_handle();


=head1 FUNCTIONS

=head2 ok_database_handle()

Verify that a database handle can be created, and return it.

	my $dbh = LocalTest::ok_database_handle();

=cut

sub ok_database_handle
{
	$ENV{'IPC_CONCURRENCY_DBI_DATABASE'} ||= 'dbi:SQLite:dbname=t/test_database||';
	
	my ( $database_dsn, $database_user, $database_password ) = split( /\|/, $ENV{'IPC_CONCURRENCY_DBI_DATABASE'} );
	
	ok(
		my $database_handle = DBI->connect(
			$database_dsn,
			$database_user,
			$database_password,
			{
				RaiseError => 1,
			}
		),
		'Create connection to a database.',
	);
	
	my $database_type = $database_handle->{'Driver'}->{'Name'} || '';
	note( "Testing $database_type database." );
	
	return $database_handle;
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

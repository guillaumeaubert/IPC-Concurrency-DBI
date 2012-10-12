use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'IPC::Concurrency::DBI',
	license             => 'GPL_3',
	dist_author         => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from   => 'lib/IPC/Concurrency/DBI.pm',
	build_requires      =>
	{
		'DBD::SQLite'          => 0,
		'DBI'                  => 0,
		'Test::Exception'      => 0,
		'Test::More'           => 0,
	},
	requires            =>
	{
		'Carp'                 => 0,
		'Data::Dumper'         => 0,
		'Data::Validate::Type' => 0,
		'perl'                 => 5.006,
	},
	add_to_cleanup      =>
	[
		'IPC-Concurrency-DBI-*',
	],
	create_makefile_pl  => 'traditional',
	configure_requires  =>
	{
		'Module::Build' => 0,
	},
	meta_merge          =>
	{
		resources       =>
		{
			repository  => 'https://github.com/guillaumeaubert/IPC-Concurrency-DBI',
			homepage    => 'https://metacpan.org/release/IPC-Concurrency-DBI',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ipc-concurrency-dbi',
		},
		no_index                =>
		{
			file        =>
			[
				't/LocalTest.pm',
			],
		},
	},
);

$builder->create_build_script();

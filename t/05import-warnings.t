use strict;
use warnings;
use Test::More;
use Test::Warnings qw( :all );

use builtins::compat ();

do {
	my $w = warnings {
		eval q[ 'builtins::compat'->import( 'foobar' ); ]
	};
	like $w->[0], qr/^"foobar" is not exported by the builtins::compat module/;
};

do {
	my $w = warnings {
		eval q[ 'builtins::compat'->import( ':foobar' ); ]
	};
	like $w->[0], qr/^"foobar" is not defined in builtins::compat::EXPORT_TAGS/;
};

done_testing;

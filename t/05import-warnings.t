use strict;
use warnings;
use Test::More;
use Test::Warnings qw( :all );

use builtins::compat ();

do {
	my $w = warning {
		'builtins::compat'->import( 'foobar' );
	};
	like $w, qr/^"foobar" is not exported by the builtins::compat module/;
};

do {
	my $w = warning {
		'builtins::compat'->import( ':foobar' );
	};
	like $w, qr/^"foobar" is not defined in builtins::compat::EXPORT_TAGS/;
};

done_testing;

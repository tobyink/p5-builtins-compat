use 5.008001;
use strict;
use warnings;

package builtins::compat;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

sub _true () {
	!!1;
}

sub _false () {
	!!0;
}

BEGIN {
	*LEGACY_PERL = ( $] lt '5.036' ) ? \&_true : \&_false;
};

sub import {
	goto \&import_compat if LEGACY_PERL;

	'warnings'->unimport('experimental::builtin');
	'builtin'->import( qw<
		true false is_bool
		weaken unweaken is_weak
		blessed refaddr reftype
		created_as_string created_as_number
		ceil floor
		trim
		indexed
	> );
}

sub import_compat {
	my $class = shift;

	my $caller = caller;
	my $subs   = $class->get_subs;

	while ( my ( $name, $code ) = each %$subs ) {
		no strict 'refs';
		*{"$caller\::$name"} = $code;
	}

	require namespace::clean;
	'namespace::clean'->import(
		-cleanee => $caller,
		keys %$subs,
	);
}

{
	my $subs;
	sub get_subs {
		require Scalar::Util;
		'Scalar::Util'->VERSION( '1.36' );

		$subs ||= {
			true               => \&_true,
			false              => \&_false,
			is_bool            => \&_is_bool,
			weaken             => \&Scalar::Util::weaken,
			unweaken           => \&Scalar::Util::unweaken,
			is_weak            => \&Scalar::Util::isweak,
			blessed            => \&Scalar::Util::blessed,
			refaddr            => \&Scalar::Util::refaddr,
			reftype            => \&Scalar::Util::reftype,
			weaken             => \&Scalar::Util::weaken,
			created_as_string  => \&_created_as_string,
			created_as_number  => \&_created_as_number,
			ceil               => \&_ceil,   # POSIX::ceil has wrong prototype
			floor              => \&_floor,  # POSIX::floor has wrong prototype
			trim               => \&_trim,
			indexed            => \&_indexed,
		};
	}
}

if ( LEGACY_PERL ) {
	my $subs = __PACKAGE__->get_subs;
	while ( my ( $name, $code ) = each %$subs ) {
		no strict 'refs';
		*{"builtin::$name"} = $code
			unless exists &{"builtin::$name"};
	}
}

sub _is_bool ($) {
	my $value = shift;

	return _false unless defined $value;
	return _false if ref $value;
	return _false unless Scalar::Util::isdual( $value );
	return !! (
		( "$value" eq "1" or "$value" eq "" )
		and ( $value+0 == 1 or $value+0 == 0 )
	);
}

sub _created_as_number ($) {
	require B;

	my $value = shift;

	my $b_obj = B::svref_2object(\$value);
	my $flags = $b_obj->FLAGS;
	return _true if $flags & ( B::SVp_IOK() | B::SVp_NOK() ) and !( $flags & B::SVp_POK() );
	return _false;
}

sub _created_as_string ($) {
	my $value = shift;

	defined($value)
		&& !ref($value)
		&& !_is_bool($value)
		&& !_created_as_number($value);
}

sub _indexed {
	my $ix = 0;
	return map { $ix++, $_ } @_;
}

sub _trim ($) {
	my $value = shift;

	$value =~ s{^\s+|\s+$}{}g;
	return $value;
}

sub _ceil ($) {
	require POSIX;
	return POSIX::ceil( $_[0] );
}

sub _floor ($) {
	require POSIX;
	return POSIX::floor( $_[0] );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

builtins::compat - install all the new builtins from the builtin namespace (Perl 5.36+), and try our best on older versions of Perl

=head1 SYNOPSIS

  use 5.008001;          # Or later
  use builtins::compat;  # Loads all new builtins into lexical scope
  
  # So now we can write...
  if (reftype($x) eq 'ARRAY' || blessed($x) {
      print refaddr($x), "\n";
      if (is_weak($x)) {
          unweaken($x);
          print ceil( refaddr(($x)) / floor($y) ), "\n";
          weaken($x);
          print trim($description), "\n";
      }
  }

=head1 DESCRIPTION

This module does the same as L<builtins> on Perl 5.36 and above.
On older versions of Perl, it tries to implement the same functions
and then clean them from your namespace using L<namespace::clean>.

The pre-5.36 versions of C<created_as_number>, C<created_as_string>,
and C<is_bool> may not be 100% perfect implementations.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=builtins-compat>.

=head1 SEE ALSO

L<builtins>, L<builtin>, L<Scalar::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.



package Tree::Simple::Visitor;

use strict;
use warnings;

our $VERSION = '0.14';
 
## class constants

use constant RECURSIVE     => 0x01;
use constant CHILDREN_ONLY => 0x10;

### constructor

sub new {
	my ($_class, $func, $depth) = @_;
	if (defined($depth)){
		($depth == RECURSIVE || $depth == CHILDREN_ONLY) 
			|| die "Insufficient Arguments : Depth arguement must be either RECURSIVE or CHILDREN_ONLY";
	}
	(defined($func) && ref($func) eq "CODE") 
		|| die "Insufficient Arguments : func argument must be a subroutine reference";
	my $class = ref($_class) || $_class;
	my $visitor = {
		func => $func,
		depth => $depth || 0
		};
	bless($visitor, $class);
	return $visitor;
}

### methods

# visit routine
sub visit {
	my ($self, $tree) = @_;
	(defined($tree) && ref($tree) && $tree->isa("Tree::Simple"))
		|| die "Insufficient Arguments : You must supply a valid Tree::Simple object.";
	# always apply the function 
	# to the tree's node
	$self->{func}->($tree);
	# then recursively to all its children
	# if the object is configured that way
	my $func = $self->{func};
	$tree->traverse($func) if ($self->{depth} == RECURSIVE);
	# or just visit its immediate children
	# if the object is configured that way
	if ($self->{depth} == CHILDREN_ONLY) {
		$self->{func}->($_) foreach $tree->getAllChildren();
	}
}

1;

__END__

=head1 NAME

Tree::Simple::Visitor - Visitor object for Simple Tree data-structures

=head1 SYNOPSIS

  use Tree::Simple::Visitor;

=head1 DESCRIPTION

This is a very basic Visitor object for Tree::Simple objects.

=head1 CONSTANTS

=over 4

=item RECURSIVE

If passed this constant in the constructor, the function will be applied recursively down the heirarchy of B<Tree::Simple> objects. 

=item CHILDREN_ONLY

If passed this constant in the constructor, the function will be applied to the immediate children of the B<Tree::Simple> object. 

=back

=head1 METHODS

=over 4

=item new (CODE, $depth)

The first argument to the constructor is a code reference to a function which expects a B<Tree::Simple> object as its only argument. The second argument is optional, it can be used to set the depth to which the function is applied. If no depth is set, the function is applied to the current B<Tree::Simple> instance. If C<$depth> is set to C<CHILDREN_ONLY>, then the function will be applied to the current B<Tree::Simple> instance and all its immediate children. If C<$depth> is set to C<RECURSIVE>, then the function will be applied to the current B<Tree::Simple> instance and all its immediate children, and all of their children recursively on down the tree. 

=item visit ($tree)

The C<visit> method accepts a B<Tree::Simple> and applies the function set in C<new> appropriately. 

=back

=head1 SEE ALSO

B<Tree::Simple>

Gang Of Four Design Patterns Book. Specifically, the Visitor Pattern.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
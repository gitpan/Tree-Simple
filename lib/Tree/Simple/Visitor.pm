
package Tree::Simple::Visitor;

use strict;
use warnings;

our $VERSION = '1.0';
 
## class constants

use constant RECURSIVE     => 0x01;
use constant CHILDREN_ONLY => 0x10;

### constructor

sub new {
	my ($_class, $func, $depth) = @_;
	if (defined($depth)){
		($depth =~ /\d+/ && ($depth == RECURSIVE || $depth == CHILDREN_ONLY)) 
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
	(defined($tree) && ref($tree) && UNIVERSAL::isa($tree, "Tree::Simple"))
		|| die "Insufficient Arguments : You must supply a valid Tree::Simple object";
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

Tree::Simple::Visitor - Visitor object for Tree::Simple objects

=head1 SYNOPSIS

  use Tree::Simple::Visitor;
  use Tree::Simple;
  
  # create an array here, it will valid within the
  # the closure of the subroutine below
  my @accumulator;
  
  # create a visitor with a subroutine and tell it
  # what depth we want to do too (RECURSIVE)
  my $visitor = Tree::Simple::Visitor->new(sub {
                        my ($tree) = @_;  
                        push @accumlator, $tree->getNodeValue();
                        }, 
                        Tree::Simple::Visitor->RECURSIVE);
  
  # create a tree to visit
  my $tree = Tree::Simple->new(Tree::Simple->ROOT)
                         ->addChildren(
                             Tree::Simple->new("1.0"),
                             Tree::Simple->new("2.0")
                                         ->addChild(
                                             Tree::Simple->new("2.1.0")
                                             ),
                             Tree::Simple->new("3.0")
                             );
  
  # now pass the visitor to the tree							 
  $tree->accept($visitor);							 							 						

  # now the @accumulator will have all the nodes in it
  print join ", ", @accumulator;  # prints "1.0, 2.0, 2.1.0, 3.0"

=head1 DESCRIPTION

This is a very basic Visitor object for B<Tree::Simple> objects. It is really just an OO wrapper around the C<traverse> method of the B<Tree::Simple> object. 

I consider this module to be production stable, it is based on a module which has been in use on a few production systems for approx. 2 years now with no issue. The only difference is that the code has been cleaned up a bit, comments added and thorough tests written for its public release. I comment on this more in the B<DESCRIPTION> section in B<Tree::Simple>. 

=head1 CONSTANTS

=over 4

=item B<RECURSIVE>

If passed this constant in the constructor, the function will be applied recursively down the heirarchy of B<Tree::Simple> objects. 

=item B<CHILDREN_ONLY>

If passed this constant in the constructor, the function will be applied to the immediate children of the B<Tree::Simple> object. 

=back

B<NOTE:>

If not constant is passed to the constructor, then the function will only be applied to the current B<Tree::Simple> object and none of its children.

=head1 METHODS

=over 4

=item B<new (CODE, $depth)>

The first argument to the constructor is a code reference to a function which expects a B<Tree::Simple> object as its only argument. The second argument is optional, it can be used to set the depth to which the function is applied. If no depth is set, the function is applied to the current B<Tree::Simple> instance. If C<$depth> is set to C<CHILDREN_ONLY>, then the function will be applied to the current B<Tree::Simple> instance and all its immediate children. If C<$depth> is set to C<RECURSIVE>, then the function will be applied to the current B<Tree::Simple> instance and all its immediate children, and all of their children recursively on down the tree. 

=item B<visit ($tree)>

The C<visit> method accepts a B<Tree::Simple> and applies the function set in C<new> appropriately. 

=back

=head1 BUGS

None that I am aware of. The code is pretty thoroughly tested (see B<CODE COVERAGE> section in B<Tree::Simple>) and is based on an (non-publicly released) module which I had used in production systems for about 2 years without incident. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 SEE ALSO

B<Tree::Simple>

Design Patterns by the Gang Of Four. Specifically the Visitor Pattern.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
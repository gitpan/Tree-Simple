
package Tree::Simple;

use strict;
use warnings;

our $VERSION = '0.03';

## ----------------------------------------------------------------------------
## Tree::Simple
## ----------------------------------------------------------------------------

## class constants
use constant ROOT => "root";

### constructor

sub new {
	my ($_class, $node, $parent) = @_;
	my $class = ref($_class) || $_class;
	my $tree = {};
	bless($tree, $class);
	$tree->_init($node, $parent, []);
	return $tree;
}

### ---------------------------------------------------------------------------
### methods
### ---------------------------------------------------------------------------

## ----------------------------------------------------------------------------
## private methods

sub _init {
	my ($self, $node, $parent, $children) = @_;
	# set the value of the node
	$self->{_node} = $node;
	# and set the value of _children
	$self->{_children} = $children;	
	# Now check our parent value
	if (defined($parent)) {
		# and set it as our parent
		$parent->addChild($self);
	}
	else {
		$self->{_parent} = ROOT;
		$self->{_depth} = -1;
	}
}

sub _setParent {
	my ($self, $parent) = @_;
	(defined($parent) && 
		(($parent eq ROOT) || (ref($parent) && $parent->isa("Tree::Simple"))))
		|| die "Insufficient Arguments : parent also must be a Tree::Simple object";
	$self->{_parent} = $parent;
	if ($parent eq ROOT) {
		$self->{_depth} = -1;
	}
	else {
		$self->{_depth} = $parent->getDepth() + 1;
	}
}

## ----------------------------------------------------------------------------
## mutators

sub setNodeValue {
	my ($self, $node_value) = @_;
	(defined($node_value)) || die "Insufficient Arguments : must supply a value for node";
	$self->{_node} = $node_value;
}

## ----------------------------------------------
## child methods

sub addChild {
	my ($self, $tree) = @_;
	(defined($tree) && ref($tree) && $tree->isa("Tree::Simple")) 
		|| die "Insufficient Arguments : Child must be a Tree::Simple object";
	$tree->_setParent($self);
	$tree->fixDepth() unless $tree->isLeaf();
	push @{$self->{_children}} => $tree;	
	$self;
}

sub addChildren {
	my ($self, @trees) = @_;
	$self->addChild($_) foreach @trees;
	$self;
}

sub insertChildren {
	my ($self, $index, @trees) = @_;
	(defined($index)) 
		|| die "Insufficient Arguments : Cannot insert child without index";
	# check the bounds of our children 
	# against the index given
	($index <= $self->getChildCount()) 
		|| die "Index Out of Bounds : got ($index) expected no more than (" . $self->getChildCount() . ")";
	(@trees) 
		|| die "Insufficient Arguments : no tree(s) to insert";	
	foreach my $tree (@trees) {
		(defined($tree) && ref($tree) && $tree->isa("Tree::Simple")) 
			|| die "Insufficient Arguments : Child must be a Tree::Simple object";	
		$tree->_setParent($self);
		$tree->fixDepth() unless $tree->isLeaf();
	}
	# if index is zero, use this optimization
	if ($index == 0) {
		unshift @{$self->{_children}} => @trees;
	}
	# otherwise do some heavy lifting here
	else {
		$self->{_children} = [
			@{$self->{_children}}[0 .. ($index - 1)],
			@trees,
			@{$self->{_children}}[$index .. $#{$self->{_children}}],
			];
	}
}

# insertChild is really the same as
# insertChildren, you are just inserting
# and array of one tree
*insertChild = \&insertChildren;

sub removeChild {
	my ($self, $index) = @_;
	(defined($index)) 
		|| die "Insufficient Arguments : Cannot remove child without index.";
	($self->getChildCount() != 0) 
		|| die "Illegal Operation : There are no children to remove";		
	# check the bounds of our children 
	# against the index given		
	($index < $self->getChildCount()) 
		|| die "Index Out of Bounds : got ($index) expected no more than (" . $self->getChildCount() . ")";		
	my $removed_child;
	# if index is zero, use this optimization	
	if ($index == 0) {
		$removed_child = shift @{$self->{_children}};
	}
	# if index is equal to the number of children
	# then use this optimization	
	elsif ($index == $#{$self->{_children}}) {
		$removed_child = pop @{$self->{_children}};	
	}
	# otherwise do some heavy lifting here	
	else {
		$removed_child = $self->{_children}->[$index];
		$self->{_children} = [
			@{$self->{_children}}[0 .. ($index - 1)],
			@{$self->{_children}}[($index + 1) .. $#{$self->{_children}}],
			];
	}
	# make sure that the removed child
	# is no longer connected to the parent
	# so we change its parent to ROOT
	$removed_child->_setParent(ROOT);
	# and now we make sure that the depth 
	# of the removed child is aligned correctly
	$removed_child->fixDepth() unless $removed_child->isLeaf();	
	# return ths removed child
	# it is the responsibility 
	# of the user of this module
	# to properly dispose of this
	# child (and all its sub-children)
	return $removed_child;
}

## ----------------------------------------------
## Sibling methods

# these addSibling and addSiblings functions 
# just pass along their arguments to the addChild
# and addChildren method respectively, this 
# eliminates the need to overload these method
# in things like the Keyable Tree object

sub addSibling {
	my ($self, @args) = @_;
	(!$self->isRoot()) 
		|| die "Insufficient Arguments : cannot add a sibling to a ROOT tree";
	$self->{_parent}->addChild(@args);
}

sub addSiblings {
	my ($self, @args) = @_;
	(!$self->isRoot()) 
		|| die "Insufficient Arguments : cannot add siblings to a ROOT tree";
	$self->{_parent}->addChildren(@args);
}

sub insertSiblings {
	my ($self, @args) = @_;
	(!$self->isRoot()) 
		|| die "Insufficient Arguments : cannot insert sibling(s) to a ROOT tree";
	$self->{_parent}->insertChildren(@args);
}

# insertSibling is really the same as
# insertSiblings, you are just inserting
# and array of one tree
*insertSibling = \&insertSiblings;

# I am not permitting the removal of siblings 
# as I think in general it is a bad idea

## ----------------------------------------------------------------------------
## accessors

sub getParent {
	my ($self)= @_;
	return $self->{_parent};
}

sub getDepth {
	my ($self) = @_;
	return $self->{_depth};
}

sub getNodeValue {
	my ($self) = @_;
	return $self->{_node};
}

sub getChildCount {
	my ($self) = @_;
	return scalar @{$self->{_children}};
}

sub getChild {
	my ($self, $index) = @_;
	(defined($index)) 
		|| die "Insufficient Arguments : Cannot get child without index";
	return $self->{_children}->[$index];
}

sub getAllChildren {
	my ($self) = @_;
	return wantarray ?
		@{$self->{_children}}
		:
		$self->{_children};
}

sub getSibling {
	my ($self, $index) = @_;
	(!$self->isRoot()) 
		|| die "Insufficient Arguments : cannot get siblings from a ROOT tree";	
	$self->getParent()->getChild($index);
}

sub getAllSiblings {
	my ($self) = @_;
	(!$self->isRoot()) 
		|| die "Insufficient Arguments : cannot get siblings from a ROOT tree";	
	$self->getParent()->getAllChildren();
}

## ----------------------------------------------------------------------------
## informational

sub isLeaf {
	my ($self) = @_;
	return (scalar @{$self->{_children}} == 0);
}

sub isRoot {
	my ($self) = @_;
	return ($self->{_parent} eq ROOT);
}

## ----------------------------------------------------------------------------
## misc

# NOTE:
# Occasionally one wants to have the 
# depth available for various reasons
# of convience. Sometimes that depth 
# field is not always correct.
# If you create your tree in a top-down
# manner, this is usually not an issue
# since each time you either add a child
# or create a tree you are doing it with 
# a single tree and not a heirarchy.
# If however you are creating your tree
# bottom-up, then you might find that 
# when adding heirarchies of trees, your
# depth fields are all out of whack.
# This is where this method comes into play
# it will recurse down the tree and fix the
# depth fields appropriately.
# This method is called automatically when 
# a subtree is added to a child array
sub fixDepth {
	my ($self) = @_;
	# make sure the tree's depth 
	# is up to date all the way down
	$self->traverse(sub {
			my ($tree) = @_;
			$tree->{_depth} = $tree->getParent()->getDepth() + 1;
		}
	);
}

sub traverse {
	my ($self, $func) = @_;
	(defined($func)) || die "Insufficient Arguments : Cannot traverse without traversal function";
	(ref($func) eq "CODE") || die "Incorrect Object Type : traversal function is not a function";
	foreach my $child ($self->getAllChildren()) { 
		$func->($child);
		$child->traverse($func);
	}
}

# It accepts a Tree::Simple::Visitor object
# (or somethings derived
# from a Tree::Simple::Visitor) and runs
# the Visitor's "visit" method.
# We verify with an assertion
# that it is in fact a valid
# Tree::Simple::Visitor object and that it does
# have a method "visit" at 
# its disposal. 
sub accept {
	my ($self, $visitor) = @_;
	(defined($visitor) && ref($visitor) && $visitor->isa("Tree::Simple::Visitor")) 
		|| die "Insufficient Arguments : You must supply a valid Tree::Simple::Visitor object";
	$visitor->visit($self);
}

## ----------------------------------------------------------------------------
## cloning 

sub clone {
	my ($self) = @_;
	# create a empty tree
	my $cloned_tree = {
		# do not clone the parent, this
		# would cause serious recursion
		_parent => $self->{_parent},
		# depth is just a number so can 
		# be copied by value
		_depth => $self->{_depth},
		# leave node undefined for now
		_node => undef,
		# and _children empty for now
		_children => []
		};
	# we need to clone the node	
	my $temp_node = $self->{_node};	
	# if the node is not a reference, 
	# a subroutine reference, a RegEx reference 
	# or a filehandle reference, then just copy
	# it to the new object. 
	if (not ref($temp_node)       || 
		ref($temp_node) eq "CODE" || 
		ref($temp_node) eq "IO"   || 
		ref($temp_node) eq "Regexp") {
		$cloned_tree->{_node} = $temp_node;
	}
	# if the current slot is a scalar reference, then
	# dereference it and copy it into the new object
	elsif (ref($temp_node) eq "SCALAR") {
		my $temp_scalar = ${$temp_node};
		$cloned_tree->{_node} = \$temp_scalar;
	}
	
		## NOTE:
		# a Hash or an Array reference can potentially hold 
		# other references within them, such as a multi-dimensional
		# array or an array of hashes, or a hash of arrays, or any
		# such combination. So if you need this structure to be 
		# copied in depth, it is advised to override this method
		# with a more appropriate one. Otherwise you will receive
		# a shallow copy of these data-structures. Of course, there
		# will be times when a shallow copy is most appropriate. 
		# And at other times it may make more sense to not
		# incur the overhead of the while loop and all the testing that
		# is going on in here.
		
	# if the current slot is an array reference
	# then dereference it and copy it
	elsif (ref($temp_node) eq "ARRAY") {
		$cloned_tree->{_node} = [ @{$temp_node} ];
	}
	# if the current reference is a hash reference
	# then dereference it and copy it
	elsif (ref($temp_node) eq "HASH") {
		$cloned_tree->{_node} = { %{$temp_node} };
	}
	# if the current slot is another object
	# see if the object has a clone method, 
	#  and if so, use it to clone it.
	elsif (UNIVERSAL::isa($temp_node, "UNIVERSAL") && $temp_node->can("clone")){
		$cloned_tree->{_node} = $temp_node->clone();
	}
	else {
		# all other instances where the current slot is
		# a reference but not cloneable are assumed to be
		# un-cloneable object of some sort
		# and the author of the code intends it to not
		# be cloneable as such.
		$cloned_tree->{_node} = $temp_node;
	}	
	# now we run through the _children and 
	# clone each one of them too
	$cloned_tree->{_children} = [
				map { $_->clone() } @{$self->{_children}}
				] unless $self->isLeaf();
	bless($cloned_tree, ref($self));
	return $cloned_tree;
}

# this allows cloning of single nodes while retaining connections to a tree
sub cloneShallow {
	my ($self) = @_;
	my $cloned_tree = { %{$self} };
	# just clone the node (if you can)
	$cloned_tree->{_node} = $self->{_node}->clone()
		if (UNIVERSAL::isa($self->{_node}, "UNIVERSAL") && $self->{_node}->can("clone"));
	# if it can not clone, then we can
	# just rely on the copy of node that
	# already there
	bless($cloned_tree, ref($self));
	return $cloned_tree;	
}

## ----------------------------------------------------------------------------
## Desctructor

sub DESTROY {
	my ($self) = @_;
	# if we are a leaf then just let 
	# the DESTRUCTION happen but if 
	# we are a not a leaf, then we want
	# to call DESTORY on all our children
	# (first checking if they are defined
	# though since we never know how perl's
	# garbage collector will work)
	unless ($self->isLeaf()) {
		map {
			defined $_ && $_->DESTROY()
		} @{$self->{_children}};
	}
}

## ----------------------------------------------------------------------------
## end Tree::Simple
## ----------------------------------------------------------------------------

1;

__END__

=head1 NAME

Tree::Simple - A simple recursive tree object

=head1 SYNOPSIS

  use Tree::Simple;
  
  # make a tree root
  my $tree = Tree::Simple->new(Tree::Simple->ROOT);
  
  # explicity add a child to it
  $tree->addChild(Tree::Simple->new("1"));
  
  # specify the parent when creating
  # the child and add the child implicity
  my $sub_tree = Tree::Simple->new("2", $tree);
  
  # chain method calls
  $tree->getChild(0)->addChild(Tree::Simple->new("1.1"));
  
  # add more than one child at a time
  $sub_tree->addChildren(
            Tree::Simple->new("2.1"),
            Tree::Simple->new("2.2")
            );

  # add siblings
  $sub_tree->addSibling(Tree::Simple->new("3"));
  
  # insert children a specified index
  $sub_tree->insertChild(1, Tree::Simple->new("2.1a"));

=head1 DESCRIPTION

This module implements a simple recursive hierarchal tree-like object structure. It is built upon the idea of parent-child relationships, so therefore every B<Tree::Simple> object has both a parent and a set of children (who themselves have children, and so on). 

=head1 CONSTANTS

=over 4

=item ROOT

This class constant serves as a placeholder for the root of our tree.

=back

=head1 METHODS

=head2 Constructor

=over 4

=item new ($node, $parent)

The constructor accepts two arguments a C<$node> value and an optional C<$parent>. The C<$node> value can be any scalar value (which includes references and objects). The optional C<$parent> value must be a B<Tree::Simple> object, or an object derived from B<Tree::Simple>. Setting this value implies that your new tree is a child of the parent tree, and therefore adds it to the parent's children. If the C<$parent> is not specified then its value defaults to ROOT.

=back

=head2 Private Methods

=over 4

=item _init ($node, $parent, $children)

This method is here largely to facilitate subclassing. This method is called by new to initialize the object, where new's primary responsibility is creating the instance.

=item _setParent ($parent)

This method sets up the parental relationship. It is for internal use only.

=back

=head2 Mutators

=over 4

=item setNodeValue ($node_value)

This sets the node value to the scalar C<$node_value>, an exception is thrown if C<$node_value> is not defined.

=item addChild ($tree)

This method accepts only B<Tree::Simple> objects or objects derived from B<Tree::Simple>, an exception is thrown otherwise. This method will append the given C<$tree> to the end of the children list, and set up the correct parent-child relationships. This method is set up to return its invocant so that method call chaining can be possible. Such as:

  my $tree = Tree::Simple->new("root")->addChild(Tree::Simple->new("child one"));

Or the more complex:

  my $tree = Tree::Simple->new("root")->addChild(
                         Tree::Simple->new("1.0")->addChild(
                                     Tree::Simple->new("1.0.1")     
                                     )
                         );

=item addChildren (@trees)

This method accepts an array of B<Tree::Simple> objects, and adds them to the children list. Like C<addChild> this method will return its invocant to allow for method call chaining.

=item insertChild ($index, $tree)

This method accepts a numeric C<$index> and a B<Tree::Simple> object (C<$tree>), and inserts the C<$tree> into the children list at the specified C<$index>. This results in the shifting down of all children after the C<$index>. The C<$index> is checked to be sure it is the bounds of the child list. The C<$tree> argument's type is verified to be a B<Tree::Simple> or B<Tree::Simple> derived object. If either of these two conditions fail, an exception is thrown. 

=item insertChildren ($index, @trees)

This method functions much as insertChild does, but instead of inserting a single B<Tree::Simple>, it inserts an array of B<Tree::Simple> objects. It too bounds checks the value of C<$index> and type checks the objects in C<@trees>.

=item removeChild ($index)

This method accepts a numeric C<$index> and removes the C<$tree> from the children list at the specified C<$index>. This results in the shifting up of all children after the C<$index>. The C<$index> is checked to be sure it is the bounds of the child list, if this condition fail, an exception is thrown. The removed child is then returned.

=item addSibling ($tree)

=item addSiblings (@trees)

=item insertSibling ($index, $tree)

=item insertSiblings ($index, @trees)

The C<addSibling>, C<addSiblings>, C<insertSibling> and C<insertSiblings> methods pass along their arguments to the C<addChild>, C<addChildren>, C<insertChild> and C<insertChildren> methods of their parent object respectively. This eliminates the need to overload these methods in subclasses which may have specialized versions of the *Child(ren) methods. The one execeptions is that if an attempt it made to add or insert siblings to the B<ROOT> of the tree then an exception is thrown.

=back

B<NOTE:>
There is no C<removeSibling> method as I felt it was probably a bad idea. The same effect can be achieved by manual upwards traversal. 

=head2 Accessors

=over 4

=item getNodeValue

This returns the value stored in the object's node field.

=item getChild ($index)

This returns the child (a B<Tree::Simple> object) found at the specified C<$index>. Note that we do use standard zero-based array indexing.

=item getAllChildren

This returns an array of all the children (all B<Tree::Simple> objects). It will return an array reference in scalar context. 

=item getSibling ($index)

=item getAllSiblings

Much like C<addSibling> and C<addSiblings>, these two methods simply call C<getChild> and C<getAllChildren> on the invocant's parent.

=item getDepth

Returns a number representing the invocant's depth within the heirarchy of B<Tree::Simple> objects.

=item getParent

Returns the invocant's parent, which could be either B<ROOT> or a B<Tree::Simple> object.

=item getChildCount

Returns the number of children the invocant contains.

=back

=head2 Predicates

=over 4

=item isLeaf

Returns true (1) if the invocant does not have any children, false (0) otherwise.

=item isRoot

Returns true (1) if the invocant's parent is B<ROOT>, returns false (0) otherwise.

=back

=head2 Misc. Functions

=over 4

=item traverse (CODE)

This method takes a single arguement of a subroutine reference C<$func>. If the argument is not defined and is not infact a CODE reference then an exception is thrown. The function is them applied recursively to all the children of the invocant. Here is an example of a traversal function that will print out the hierarchy as a tabed in list.

  $tree->traverse(sub {
        my ($_tree) = @_;
        print (("\t" x $_tree->getDepth()), $_tree->getNodeValue(), "\n");
        });

=item accept ($visitor)

It accepts a B<Tree::Simple::Visitor> object (or somethings derived from a B<Tree::Simple::Visitor>) and runs the Visitor's C<visit> method. We verify with an assertion that it is in fact a valid B<Tree::Simple::Visitor> object and that it does have a method B<visit> at its disposal. 

=item clone 

The clone method does a full deep-copy clone of the object, calling clone recursively on all its children. This does not call clone on the parent object however. Doing this would result in a slowly degenerating spiral of recursive death, so it is not recommended and therefore not implemented. What it does do is to copy the parent reference, which is a much more sensable act, and tends to be closer to what we are looking for. This can be a very expensive operation, and should only be undertaken with great care. More often than not, this method will not be appropriate. I recommend using the C<cloneShallow> method instead.

=item cloneShallow

This method is an alternate option to the plain C<clone> method. This method allows the cloning of single B<Tree::Simple> object while retaining connections to the rest of the tree/heirarchy. This will attempt to call C<clone> on the invocant's node if the node is an object (and responds to C<$obj->can('clone')>) otherwise it will just copy it.

=item DESTROY

To avoid memory leaks through uncleaned-up circular references, we implement the DESTROY method. This method will attempt to call DESTROY on each of its children (if it as any). This will result in a cascade of calls to DESTORY on down the tree. This may not be a good idea, we will have to see how it works out in practice.

=back

=head1 SEE ALSO

B<Tree::Simple::Visitor>

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

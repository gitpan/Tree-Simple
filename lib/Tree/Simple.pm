
package Tree::Simple;

use strict;
use warnings;

our $VERSION = '1.09';

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
    # set the value of the unique id
    ($self->{_uid}) = ("$self" =~ /\((.*?)\)$/);
	# set the value of the node
	$self->{_node} = $node;
	# and set the value of _children
	$self->{_children} = $children;	
    # initialize the parent and depth here
    $self->{_parent} = undef;
    $self->{_depth} = undef;    
	# Now check our $parent value
	if (defined($parent)) {
        if (ref($parent) && UNIVERSAL::isa($parent, "Tree::Simple")) {
            # and set it as our parent
            $parent->addChild($self);
        }
        elsif ($parent eq ROOT) {
            $self->{_parent} = $parent;
            $self->{_depth} = -1;
        }
        else {
            die "Insufficient Arguments : parent argument must be a Tree::Simple object";
        }
	}
	else {
		$self->{_parent} = ROOT;
		$self->{_depth} = -1;
	}
}

sub _setParent {
	my ($self, $parent) = @_;
	(defined($parent) && 
		(($parent eq ROOT) || (ref($parent) && UNIVERSAL::isa($parent, "Tree::Simple"))))
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

sub setUID {
    my ($self, $uid) = @_;
    ($uid) || die "Insufficient Arguments : Custom Unique ID's must be a true value";
    $self->{_uid} = $uid;
}

## ----------------------------------------------
## child methods

sub addChild {
	my ($self, $tree) = @_;
	(defined($tree) && ref($tree) && UNIVERSAL::isa($tree, "Tree::Simple")) 
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
		(defined($tree) && ref($tree) && UNIVERSAL::isa($tree, "Tree::Simple")) 
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

sub removeChildAt {
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

sub removeChild {
    my ($self, $child_to_remove) = @_;
    (defined($child_to_remove))
        || die "Insufficient Arguments : you must specify a child to remove";
    # maintain backwards compatability
    # so any non-ref arguments will get 
    # sent to removeChildAt
    return $self->removeChildAt($child_to_remove) unless ref($child_to_remove);
    # now that we are confident its a reference
    # make sure it is the right kind
    (UNIVERSAL::isa($child_to_remove, "Tree::Simple")) 
        || die "Insufficient Arguments : Only valid child type is a Tree::Simple object";
    my $index = 0;
    foreach my $child ($self->getAllChildren()) {
        ("$child" eq "$child_to_remove") && return $self->removeChildAt($index);
        $index++;
    }
    die "Child Not Found : cannot find object ($child_to_remove) in self";
}

sub getIndex {
    my ($self) = @_;
    return -1 if $self->{_parent} eq ROOT;
    my $index = 0;
    foreach my $sibling ($self->{_parent}->getAllChildren()) {
        ("$sibling" eq "$self") && return $index;
        $index++;
    }
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

sub getUID {
    my ($self) = @_;
    return $self->{_uid};
}

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
	return (!defined($self->{_parent}) || $self->{_parent} eq ROOT);
}

sub size {
    my ($self) = @_;
    my $size = 1;
    foreach my $child ($self->getAllChildren()) {
        $size += $child->size();    
    }
    return $size;
}

sub height {
    my ($self) = @_;
    my $max_height = 0;
    foreach my $child ($self->getAllChildren()) {
        my $child_height = $child->height();
        $max_height = $child_height if ($max_height < $child_height); 
    }
    return $max_height + 1;
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
# a single tree and not a hierarchy.
# If however you are creating your tree
# bottom-up, then you might find that 
# when adding hierarchies of trees, your
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

# this is an improved version of the 
# old accept method, it now it more
# accepting of its arguments
sub accept {
	my ($self, $visitor) = @_;
    # it must be defined, a reference type and ...
	(defined($visitor) && ref($visitor) && 
        # either a Tree::Simple::Visitor object, or ...
        (UNIVERSAL::isa($visitor, "Tree::Simple::Visitor") || 
            # it must be an object which has a 'visit' method avaiable
            (UNIVERSAL::isa($visitor, "UNIVERSAL") && $visitor->can('visit')))) 
		|| die "Insufficient Arguments : You must supply a valid Visitor object";
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
	unless (!$self->{_children} && $self->isLeaf()) {
		foreach my $child (@{$self->{_children}}) { 
			defined $child && $child->DESTROY();
		}
	}
    $self->{_parent} = undef unless $self->isRoot();
}

## ----------------------------------------------------------------------------
## end Tree::Simple
## ----------------------------------------------------------------------------

1;

__END__

=head1 NAME

Tree::Simple - A simple tree object

=head1 SYNOPSIS

  use Tree::Simple;
  
  # make a tree root
  my $tree = Tree::Simple->new("0", Tree::Simple->ROOT);
  
  # explicity add a child to it
  $tree->addChild(Tree::Simple->new("1"));
  
  # specify the parent when creating
  # an instance and it adds the child implicity
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
  
  # clean up circular references
  $tree->DESTROY();

=head1 DESCRIPTION

This module in an fully object-oriented implementation of a simple n-ary tree. It is built upon the concept of parent-child relationships, so therefore every B<Tree::Simple> object has both a parent and a set of children (who themselves may have children, and so on). Every B<Tree::Simple> object also has siblings, as they are just the children of their immediate parent. 

It is can be used to model hierarchal information such as a file-system, the organizational structure of a company, an object inheritance hierarchy, versioned files from a version control system or even an abstract syntax tree for use in a parser. It makes no assumptions as to your intended usage, but instead simply provides the structure and means of accessing and traversing said structure. 

This module uses exceptions and a minimal Design By Contract style. All method arguments are required unless specified in the documentation, if a required argument is not defined an exception will usually be thrown. Many arguments are also required to be of a specific type, for instance the C<$parent> argument to the constructor B<must> be a B<Tree::Simple> object or an object derived from B<Tree::Simple>, otherwise an exception is thrown. This may seems harsh to some, but this allows me to have the confidence that my code works as I intend, and for you to enjoy the same level of confidence when using this module. Note however that this module does not use any Exception or Error module, the exceptions are just strings thrown with C<die>. 

I consider this module to be production stable, it is based on a module which has been in use on a few production systems for approx. 2 years now with no issue. The only difference is that the code has been cleaned up a bit, comments added and the thorough tests written for its public release. I am confident it behaves as I would expect it to, and is (as far as I know) bug-free. I have not stress-tested it under extreme duress, but I don't so much intend for it to be used in that type of situation. If this module cannot keep up with your Tree needs, i suggest switching to one of the modules listed in the L<OTHER TREE MODULES> section below.

=head1 CONSTANTS

=over 4

=item B<ROOT>

This class constant serves as a placeholder for the root of our tree. If a tree does not have a parent, then it is considered a root. 

=back

=head1 METHODS

=head2 Constructor

=over 4

=item B<new ($node, $parent)>

The constructor accepts two arguments a C<$node> value and an optional C<$parent>. The C<$node> value can be any scalar value (which includes references and objects). The optional C<$parent> value must be a B<Tree::Simple> object, or an object derived from B<Tree::Simple>. Setting this value implies that your new tree is a child of the parent tree, and therefore adds it to the parent's children. If the C<$parent> is not specified then its value defaults to ROOT.

=back

=head2 Mutators

=over 4

=item B<setNodeValue ($node_value)>

This sets the node value to the scalar C<$node_value>, an exception is thrown if C<$node_value> is not defined.

=item B<setUID ($uid)>

This allows you to set your own unique ID for this specific Tree::Simple object. A default value derived from the object's hex address is provided for you, so use of this method is entirely optional. It is the responsibility of the user to ensure the value's uniqueness, all that is tested by this method is that C<$uid> is a true value (evaluates to true in a boolean context). For even more information about the Tree::Simple UID see the C<getUID> method.

=item B<addChild ($tree)>

This method accepts only B<Tree::Simple> objects or objects derived from B<Tree::Simple>, an exception is thrown otherwise. This method will append the given C<$tree> to the end of it's children list, and set up the correct parent-child relationships. This method is set up to return its invocant so that method call chaining can be possible. Such as:

  my $tree = Tree::Simple->new("root")->addChild(Tree::Simple->new("child one"));

Or the more complex:

  my $tree = Tree::Simple->new("root")->addChild(
                         Tree::Simple->new("1.0")->addChild(
                                     Tree::Simple->new("1.0.1")     
                                     )
                         );

=item B<addChildren (@trees)>

This method accepts an array of B<Tree::Simple> objects, and adds them to it's children list. Like C<addChild> this method will return its invocant to allow for method call chaining.

=item B<insertChild ($index, $tree)>

This method accepts a numeric C<$index> and a B<Tree::Simple> object (C<$tree>), and inserts the C<$tree> into the children list at the specified C<$index>. This results in the shifting down of all children after the C<$index>. The C<$index> is checked to be sure it is the bounds of the child list, if it out of bounds an exception is thrown. The C<$tree> argument's type is verified to be a B<Tree::Simple> or B<Tree::Simple> derived object, if this condition fails, an exception is thrown. 

=item B<insertChildren ($index, @trees)>

This method functions much as insertChild does, but instead of inserting a single B<Tree::Simple>, it inserts an array of B<Tree::Simple> objects. It too bounds checks the value of C<$index> and type checks the objects in C<@trees> just as C<insertChild> does.

=item B<removeChild> ($child | $index)>

Accepts two different arguemnts. If given a B<Tree::Simple> object (C<$child>), this method finds that specific C<$child> by comparing it with all the other children until it finds a match. At which point the C<$child> is removed. If no match is found, and exception is thrown. If a non-B<Tree::Simple> object is given as the C<$child> argument, an exception is thrown. 

This method also accepts a numeric C<$index> and removes the child found at that index from it's list of children. The C<$index> is bounds checked, if this condition fail, an exception is thrown.

When a child is removed, it results in the shifting up of all children after it, and the removed child is returned. The removed child is properly disconnected from the tree and all its references to its old parent are removed. However, in order to properly clean up and circular references the removed child might have, it is advised to call it's C<DESTROY> method. See the L<CIRCULAR REFERENCES> section for more information.

=item B<addSibling ($tree)>

=item B<addSiblings (@trees)>

=item B<insertSibling ($index, $tree)>

=item B<insertSiblings ($index, @trees)>

The C<addSibling>, C<addSiblings>, C<insertSibling> and C<insertSiblings> methods pass along their arguments to the C<addChild>, C<addChildren>, C<insertChild> and C<insertChildren> methods of their parent object respectively. This eliminates the need to overload these methods in subclasses which may have specialized versions of the *Child(ren) methods. The one exceptions is that if an attempt it made to add or insert siblings to the B<ROOT> of the tree then an exception is thrown.

=back

B<NOTE:>
There is no C<removeSibling> method as I felt it was probably a bad idea. The same effect can be achieved by manual upwards traversal. 

=head2 Accessors

=over 4

=item B<getNodeValue>

This returns the value stored in the object's node field.

=item B<getUID>

This returns the unique ID associated with this particular tree. This can be custom set using the C<setUID> method, or you can just use the default. The default is the hex-address extracted from the stringified Tree::Simple object. This may not be a I<universally> unique identifier, but it should be adequate for at least the current instance of your perl interpreter. If you need a UUID, one can be generated with an outside module (there are many to choose from on CPAN) and the C<setUID> method (see above).

=item B<getChild ($index)>

This returns the child (a B<Tree::Simple> object) found at the specified C<$index>. Note that we do use standard zero-based array indexing.

=item B<getAllChildren>

This returns an array of all the children (all B<Tree::Simple> objects). It will return an array reference in scalar context. 

=item B<getSibling ($index)>

=item B<getAllSiblings>

Much like C<addSibling> and C<addSiblings>, these two methods simply call C<getChild> and C<getAllChildren> on the invocant's parent.

=item B<getDepth>

Returns a number representing the invocant's depth within the hierarchy of B<Tree::Simple> objects.

=item B<getParent>

Returns the invocant's parent, which could be either B<ROOT> or a B<Tree::Simple> object.

=item B<getChildCount>

Returns the number of children the invocant contains.

=item B<getIndex>

Returns the index of this tree within its parent's child list. Returns -1 if the tree is the root.

=back

=head2 Predicates

=over 4

=item B<isLeaf>

Returns true (1) if the invocant does not have any children, false (0) otherwise.

=item B<isRoot>

Returns true (1) if the invocant's "parent" field is B<ROOT>, returns false (0) otherwise.

=back

=head2 Recursive Functions

=over 4

=item B<traverse ($func)>

This method takes a single argument of a subroutine reference C<$func>. If the argument is not defined and is not in fact a CODE reference then an exception is thrown. The function is then applied recursively to all the children of the invocant. Here is an example of a traversal function that will print out the hierarchy as a tabbed in list.

  $tree->traverse(sub {
        my ($_tree) = @_;
        print (("\t" x $_tree->getDepth()), $_tree->getNodeValue(), "\n");
        });
        
=item B<size>

Returns the total number of nodes in the current tree and all its sub-trees.

=item B<height>

Returns the length of the longest path from the current tree to the furthest leaf node.

=back

=head2 Misc. Functions

=over 4     

=item B<accept ($visitor)>

It accepts either a B<Tree::Simple::Visitor> object (which includes classes derived from B<Tree::Simple::Visitor>), or an object who has the C<visit> method available (tested with C<$visitor-E<gt>can('visit')>). If these qualifications are not met, and exception will be thrown. We then run the Visitor's C<visit> method giving the current tree as its argument. 

I have also created a number of Visitor objects and packaged them into the B<Tree::Simple::VisitorFactory>. 

=item B<clone>

The clone method does a full deep-copy clone of the object, calling C<clone> recursively on all its children. This does not call C<clone> on the parent tree however. Doing this would result in a slowly degenerating spiral of recursive death, so it is not recommended and therefore not implemented. What it does do is to copy the parent reference, which is a much more sensible act, and tends to be closer to what we are looking for. This can be a very expensive operation, and should only be undertaken with great care. More often than not, this method will not be appropriate. I recommend using the C<cloneShallow> method instead.

=item B<cloneShallow>

This method is an alternate option to the plain C<clone> method. This method allows the cloning of single B<Tree::Simple> object while retaining connections to the rest of the tree/hierarchy. This will attempt to call C<clone> on the invocant's node if the node is an object (and responds to C<$obj-E<gt>can('clone')>) otherwise it will just copy it.

=item B<DESTROY>

To avoid memory leaks through uncleaned-up circular references, we implement the C<DESTROY> method. This method will attempt to call C<DESTROY> on each of its children (if it has any). This will result in a cascade of calls to C<DESTROY> on down the tree. It also cleans up it's parental relations as well. 

Because of perl's reference counting scheme and how that interacts with circular references, if you want an object to be properly reaped you should manually call C<DESTROY>. This is especially nessecary if your object has any children. See the section on L<CIRCULAR REFERENCES> for more information.

=item B<fixDepth>

For the most part, Tree::Simple will manage your tree's depth fields for you. But occasionally your tree's depth may get out of place. If you run this method, it will traverse your tree correcting the depth as it goes.

=back

=head2 Private Methods

=over 4

=item B<_init ($node, $parent, $children)>

This method is here largely to facilitate subclassing. This method is called by new to initialize the object, where new's primary responsibility is creating the instance.

=item B<_setParent ($parent)>

This method sets up the parental relationship. It is for internal use only.

=back

=head1 CIRCULAR REFERENCES

Perl uses reference counting to manage the destruction of objects, and this can cause problems with circularly referencing object like Tree::Simple. In order to properly manage your circular references, it is nessecary to manually call the C<DESTROY> method on a Tree::Simple instance. Here is some example code:

  # create a root
  my $root = Tree::Simple->new()
  
  { # create a lexical scope
  
      # create a subtree (with a child)
      my $subtree = Tree::Simple->new("1")
                          ->addChild(
                              Tree::Simple->new("1.1")
                          );
                          
      # add the subtree to the root                    
      $root->addChild($subtree);                    
      
      # ... do something with your trees 
      
      # remove the first child
      $root->removeChild(0);
  }

At this point you might expect perl to reap C<$subtree> since it has been removed from the C<$root> and is no longer available outside the lexical scope of the block. However, since C<$subtree> itself has a child, its reference count is still (at least) one and perl will not reap it. The solution to this is to call the C<DESTROY> method manually at the end of the lexical block, this will result in the breaking of all relations with the DESTROY-ed object and allow that object to be reaped by perl. Here is a corrected version of the above code.

  # create a root
  my $root = Tree::Simple->new()
  
  { # create a lexical scope
  
      # create a subtree (with a child)
      my $subtree = Tree::Simple->new("1")
                          ->addChild(
                              Tree::Simple->new("1.1")
                          );
                          
      # add the subtree to the root                    
      $root->addChild($subtree);                    
      
      # ... do something with your trees 
      
      # remove the first child and capture it
      my $removed = $root->removeChild(0);
      
      # now force destruction of the removed child
      $removed->DESTROY();
  }

As you can see if the corrected version we used a new variable to capture the removed tree, and then explicitly called C<DESTROY> upon it. Only when a removed subtree has no children (it is a leaf node) can you safely ignore the call to C<DESTROY>. It is even nessecary to call C<DESTROY> on the root node if you want it to be reaped before perl exits, this is especially important in long running environments like mod_perl.

=head1 BUGS

None that I am aware of. The code is pretty thoroughly tested (see L<CODE COVERAGE> below) and is based on an (non-publicly released) module which I had used in production systems for about 2 years without incident. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module's test suite.
 
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 File                       stmt branch   cond    sub    pod   time  total
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Tree/Simple.pm            100.0   97.9   86.7  100.0   96.7   94.7   97.4
 Tree/Simple/Visitor.pm    100.0   96.2   90.0  100.0  100.0    5.3   97.7
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Total                     100.0   97.5   87.5  100.0   97.4  100.0   97.5
 ------------------------ ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

I have written a number of other modules which use or augment this module, they are describes below and available on CPAN.

=over 4

=item B<Tree::Parser> - A module for parsing formatted files into Tree::Simple hierarchies.

=item B<Tree::Simple::View> - A set of classes for viewing Tree::Simple hierarchies in various output formats.

=item B<Tree::Simple::VisitorFactory> - A set of useful Visitor objects for Tree::Simple objects.

=back

Also, the author of B<Data::TreeDumper> and I have worked together to make sure that B<Tree::Simple> and his module work well together. If you need a quick and handy way to dump out a Tree::Simple heirarchy, this module does an excellent job (and plenty more as well).

I have also recently stumbled upon some packaged distributions of Tree::Simple for the various Unix flavors. Here  are some links:

=over 4

=item FreeBSD Port - L<http://www.freshports.org/devel/p5-Tree-Simple/>

=item Debian Package - L<http://packages.debian.org/unstable/perl/libtree-simple-perl>

=item Linux RPM - L<http://rpmpan.sourceforge.net/Tree.html>

=back

=head1 OTHER TREE MODULES

There are a few other Tree modules out there, here is a quick comparison between B<Tree::Simple> and them. Obviously I am biased, so take what I say with a grain of salt, and keep in mind, I wrote B<Tree::Simple> because I could not find a Tree module that suited my needs. If B<Tree::Simple> does not fit your needs, I recommend looking at these modules. Please note that I only list registered Tree::* modules here, I have only seen a few other modules outside of that namespace that seem to fit, although most of them are part of another distribution (B<HTML::Tree>, B<Pod::Tree>, etc). 

=over 4

=item B<Tree::DAG_Node>

This module seems pretty stable and very robust, but it is also very large module. It is approx. 3000 lines with POD, and 1,500 without the POD. The shear depth and detail of the documentation and the ratio of code to documentation is impressive, and not to be taken lightly. B<Tree::Simple>, by comparison, is around 500 lines of code and another 330 lines of documentation. B<Tree::DAG_Node> is part of the reason why I wrote B<Tree::Simple>, the author contends that you can use B<Tree::DAG_Node> for simpler purposes if you so desire, for me it is too beefy. 

My other issue with B<Tree::DAG_Node> is its test-suite. There is one test, and that is that the module loads. This is not acceptable to me, no matter how good a module is.

=item B<Tree::Nary>

It is a (somewhat) direct translation of the N-ary tree from the GLIB library, and the API is based on that. GLIB is a C library, which means this is a very C-ish API. That doesn't appeal to me, it might to you, to each their own.

This module is similar in intent to B<Tree::Simple>. It implements a tree with I<n> branches and has polymorphic node containers. It implements much of the same methods as B<Tree::Simple> and a few others on top of that, but being based on a C library, is not very OO. In most of the method calls the C<$self> argument is not used and the second argument C<$node> is. B<Tree::Simple> is a much more OO module than B<Tree::Nary>, so while they are similar in functionality they greatly differ in implementation style.

=item B<Tree>

This module is pretty old, it has not been updated since Oct. 31, 1999 and is still on version 0.01. It also seems to be (from the limited documentation) a balanced tree, B<Tree::Simple> makes no attempt to balance anything.

=item B<Tree::Ternary>

This module is older than B<Tree>, last update was Sept. 24th, 1999. It seems to be a special purpose tree, for storing and accessing strings, not general purpose like B<Tree::Simple>. 

=item B<Tree::Ternary_XS>

This module is an XS implementation of the above tree type. 

=item B<Tree::Trie>

This too is a specialized tree type, it sounds similar to the B<Tree::Ternary>, but it much newer (latest release in 2003). It seems specialized for the lookup and retrieval of information like a hash.

=item B<Tree::M>

Is a wrapper for a C++ library, whereas B<Tree::Simple> is pure-perl. It also seems to be a more specialized implementation of a tree, therefore not really the same as B<Tree::Simple>. 

=item B<Tree::Fat>

Is a wrapper around a C library, again B<Tree::Simple> is pure-perl. The author describes FAT-trees as a combination of a Tree and an array. It looks like a pretty mean and lean module, and good if you need speed and are implementing a custom data-store of some kind. The author points out too that the module is designed for embedding and there is not default embedding, so you can't really use it "out of the box".

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks to Nadim Ibn Hamouda El Khemir for making L<Data::TreeDumper> work with B<Tree::Simple>.

=item Thanks to Brett Nuske for his idea for the C<getUID> and C<setUID> methods.

=item Thanks to whoever submitted the memory leak bug to RT (#7512). 

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

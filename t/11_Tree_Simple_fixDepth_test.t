#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

## ----------------------------------------------------------------------------
## fixDepth Tests for Tree::Simple
## ----------------------------------------------------------------------------
# NOTE:
# This specifically tests the fixDepth function, which is run when a non-leaf
# tree is added to a tree. It basically fixes the depth field so that it 
# correctly reflects the new depth 
## ----------------------------------------------------------------------------

use Tree::Simple;

# create our tree to later add-in
my $tree = Tree::Simple->new("2.1")
					->addChildren(
						Tree::Simple->new("2.1.1"),
						Tree::Simple->new("2.1.2"),
						Tree::Simple->new("2.1.2")						
					);

# make sure its a root	
ok($tree->isRoot());

# and it is not a leaf
ok(!$tree->isLeaf());
					
# and that its depth is -1 					
cmp_ok($tree->getDepth(), '==', -1, '... our depth should be -1');		

# and check our child count
# while we are at it
cmp_ok($tree->getChildCount(), '==', 3, '... we have 3 children');			

# now check each subtree 		
foreach my $sub_tree ($tree->getAllChildren()) {
	# they are not root
	ok(!$sub_tree->isRoot());
	# they are leaves
	ok($sub_tree->isLeaf());
	# and their parent is $tree
	is($sub_tree->getParent(), $tree, '... these should both be equal');
	# their depth should be 0
	cmp_ok($sub_tree->getDepth(), '==', 0, '... our depth should be 0');
	# and their siblings should match 
	# the children of their parent
	ok eq_array([ $tree->getAllChildren() ], [ $sub_tree->getAllSiblings() ]);
}	

# at this point we know we have a 
# solid correct structure in $tree
# we can now test against that 
# correctness

# now create our other tree 
# which we will add $tree too
my $parent_tree = Tree::Simple->new(Tree::Simple->ROOT);
$parent_tree->addChildren(
	Tree::Simple->new("1"),
	Tree::Simple->new("2")
	);

# make sure its a root
ok($parent_tree->isRoot());

# and that its not a leaf
ok(!$parent_tree->isLeaf());
		
# check the depth, which should be -1
cmp_ok($parent_tree->getDepth(), '==', -1, '... our depth should be -1');		

# and our child count is 2
cmp_ok($parent_tree->getChildCount(), '==', 2, '... we have 2 children');			

# now check our subtrees		
foreach my $sub_tree ($parent_tree->getAllChildren()) {
	# make sure they are not roots
	ok(!$sub_tree->isRoot());
	# and they are leaves
	ok($sub_tree->isLeaf());
	# and their parent is $parent_tree
	is($sub_tree->getParent(), $parent_tree, '... these should both be equal');
	# and their depth is 0
	cmp_ok($sub_tree->getDepth(), '==', 0, '... our depth should be 0');
	# and that all their siblinds match
	# the children of their parent
	ok eq_array([ $parent_tree->getAllChildren() ], [ $sub_tree->getAllSiblings() ]);
}

# now here comes the heart of this test
# we now add in $tree (2.1) as a child  
# of the second child of the parent (2)
$parent_tree->getChild(1)->addChild($tree);	
	
# now we verify that $tree no longer 
# thinks that its a root	
ok(!$tree->isRoot());
					
# that $tree's depth has been 
# updated to reflect its new place
# in the hierarchy (1)			
cmp_ok($tree->getDepth(), '==', 1, '... our depth should be 1');

# that $tree's parent is not shown to be
# the second child of $parent_tree
is($tree->getParent(), $parent_tree->getChild(1), '... these should both be equal');
				
# and now we check $tree's children				
foreach my $sub_tree ($tree->getAllChildren()) {
	# their depth should have been 
	# updated to reflect their new
	# place in the hierarchy, so they
	# are now at a depth of 2
	cmp_ok($sub_tree->getDepth(), '==', 2, '... our depth should be 2');
	
}	

## ----------------------------------------------------------------------------
## end fixDepth Tests for Tree::Simple
## ----------------------------------------------------------------------------
							
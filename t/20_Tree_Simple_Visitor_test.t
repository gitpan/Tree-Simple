#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

BEGIN { 
	use_ok('Tree::Simple::Visitor'); 	
};

## ----------------------------------------------------------------------------
## Test for Tree::Simple::Visitor
## ----------------------------------------------------------------------------

use Tree::Simple;

# check that we have a constructor
can_ok("Tree::Simple::Visitor", 'new');
# and that our RECURSIVE constant is properly defined
can_ok("Tree::Simple::Visitor", 'RECURSIVE');
# and that our CHILDREN_ONLY constant is properly defined
can_ok("Tree::Simple::Visitor", 'CHILDREN_ONLY');

# make a root for our tree
my $visitor = Tree::Simple::Visitor->new(sub {}, Tree::Simple::Visitor->RECURSIVE);
isa_ok($visitor, 'Tree::Simple::Visitor');

# and make sure we can call the visit method
can_ok($visitor, 'visit');

# now make a tree
my $tree = Tree::Simple->new(Tree::Simple->ROOT);
isa_ok($tree, 'Tree::Simple');

# and pass the visitor to accept
lives_ok {
	$tree->accept($visitor);
} '.. this passes fine';

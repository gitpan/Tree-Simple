#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

BEGIN { 
	use_ok('Tree::Simple::Visitor'); 	
};

## ----------------------------------------------------------------------------
## Test for Tree::Simple::Visitor
## ----------------------------------------------------------------------------
# Code coverage stats for this test:
# -----------------------------------------------------------------------------
# File                              stmt branch   cond    sub   time  total
# ------------------------------- ------ ------ ------ ------ ------ ------
# /Tree/Simple.pm                   18.2    8.1    6.7   25.0    3.7   14.6
# /Tree/Simple/Visitor.pm           82.4   50.0   35.3  100.0    2.6   58.3
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

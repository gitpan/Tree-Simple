#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { 
	use_ok('Tree::Simple::Visitor'); 
};

## ----------------------------------------------------------------------------
## Test for Tree::Simple::Visitor
## ----------------------------------------------------------------------------

# check that we have a constructor
can_ok("Tree::Simple::Visitor", 'new');
# and that our RECURSIVE constant is properly defined
can_ok("Tree::Simple::Visitor", 'RECURSIVE');
# and that our CHILDREN_ONLY constant is properly defined
can_ok("Tree::Simple::Visitor", 'CHILDREN_ONLY');

# make a root for our tree
my $visitor = Tree::Simple::Visitor->new(sub {}, Tree::Simple::Visitor->RECURSIVE);
isa_ok($visitor, 'Tree::Simple::Visitor');

# and make sure we cna call the visit method
can_ok($visitor, 'visit');

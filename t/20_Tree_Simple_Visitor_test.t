#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

BEGIN { 
	use_ok('Tree::Simple::Visitor'); 	
};

## ----------------------------------------------------------------------------
## Test for Tree::Simple::Visitor
## ----------------------------------------------------------------------------
# Code coverage stats for this test:
# -----------------------------------------------------------------------------
# File                       stmt branch   cond    sub   time  total
# ------------------------ ------ ------ ------ ------ ------ ------
# /Tree/Simple.pm            33.8   12.2   17.8   39.3    4.6   31.7
# /Tree/Simple/Visitor.pm   100.0  100.0   90.0  100.0    3.3   96.2
## ----------------------------------------------------------------------------

use Tree::Simple;

my $SIMPLE_SUB = sub { "test sub" };
# execute this otherwise Devel::Cover gives odd stats
$SIMPLE_SUB->();

# check that we have a constructor
can_ok("Tree::Simple::Visitor", 'new');
# and that our RECURSIVE constant is properly defined
can_ok("Tree::Simple::Visitor", 'RECURSIVE');
# and that our CHILDREN_ONLY constant is properly defined
can_ok("Tree::Simple::Visitor", 'CHILDREN_ONLY');

# -----------------------------------------------
# test the different depth arguements
# -----------------------------------------------

# no depth
my $visitor1 = Tree::Simple::Visitor->new($SIMPLE_SUB);
isa_ok($visitor1, 'Tree::Simple::Visitor');

# children only
my $visitor2 = Tree::Simple::Visitor->new($SIMPLE_SUB, Tree::Simple::Visitor->CHILDREN_ONLY);
isa_ok($visitor2, 'Tree::Simple::Visitor');

# recursive
my $visitor3 = Tree::Simple::Visitor->new($SIMPLE_SUB, Tree::Simple::Visitor->RECURSIVE);
isa_ok($visitor3, 'Tree::Simple::Visitor');

# -----------------------------------------------
# test the exceptions
# -----------------------------------------------

# we pass a bad depth (string)
throws_ok {
	my $test = Tree::Simple::Visitor->new($SIMPLE_SUB, "Fail")
} qr/Insufficient Arguments \: Depth arguement must be either RECURSIVE or CHILDREN_ONLY/, 
   '... we are expecting this error';
   
# we pass a bad depth (numeric)
throws_ok {
	my $test = Tree::Simple::Visitor->new($SIMPLE_SUB, 100)
} qr/Insufficient Arguments \: Depth arguement must be either RECURSIVE or CHILDREN_ONLY/, 
   '... we are expecting this error';   

# we pass a no func argument
throws_ok {
	my $test = Tree::Simple::Visitor->new();
} qr/Insufficient Arguments \: func argument must be a subroutine reference/,
   '... we are expecting this error';   

# we pass a non-ref func argument
throws_ok {
	my $test = Tree::Simple::Visitor->new("Fail");
} qr/Insufficient Arguments \: func argument must be a subroutine reference/,
   '... we are expecting this error';

# we pass a non-code-ref func arguement   
throws_ok {
	my $test = Tree::Simple::Visitor->new([]);
} qr/Insufficient Arguments \: func argument must be a subroutine reference/,
   '... we are expecting this error';   

# -----------------------------------------------
# test other exceptions
# -----------------------------------------------

# and make sure we can call the visit method
can_ok($visitor1, 'visit');

# test no arg
throws_ok {
	$visitor1->visit();
} qr/Insufficient Arguments \: You must supply a valid Tree\:\:Simple object/,
   '... we are expecting this error'; 
   
# test non-ref arg
throws_ok {
	$visitor1->visit("Fail");
} qr/Insufficient Arguments \: You must supply a valid Tree\:\:Simple object/,
   '... we are expecting this error'; 	 
   
# test non-object ref arg
throws_ok {
	$visitor1->visit([]);
} qr/Insufficient Arguments \: You must supply a valid Tree\:\:Simple object/,
   '... we are expecting this error'; 	   
   
my $BAD_OBJECT = bless({}, "Test");   
   
# test non-Tree::Simple object arg
throws_ok {
	$visitor1->visit($BAD_OBJECT);
} qr/Insufficient Arguments \: You must supply a valid Tree\:\:Simple object/,
   '... we are expecting this error'; 	   

# -----------------------------------------------
# Test accept & visit
# -----------------------------------------------
# Note: 
# this test could be made more robust by actually
# getting results and testing them from the 
# Visitor object. But for right now it is good
# enough to have the code coverage, and know
# all the peices work.
# -----------------------------------------------

# now make a tree
my $tree = Tree::Simple->new(Tree::Simple->ROOT)
					   ->addChildren(
							Tree::Simple->new("1.0"),
							Tree::Simple->new("2.0"),
							Tree::Simple->new("3.0"),							
					   );
isa_ok($tree, 'Tree::Simple');

cmp_ok($tree->getChildCount(), '==', 3, '... there are 3 children here');

# and pass the visitor1 to accept
lives_ok {
	$tree->accept($visitor1);
} '.. this passes fine';

# and pass the visitor2 to accept
lives_ok {
	$tree->accept($visitor2);
} '.. this passes fine';

# and pass the visitor3 to accept
lives_ok {
	$tree->accept($visitor3);
} '.. this passes fine';

# -----------------------------------------------

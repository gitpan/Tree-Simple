#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 41;
use Test::Exception;

## ----------------------------------------------------------------------------
## Exception Tests for Tree::Simple
## ----------------------------------------------------------------------------
# Code coverage stats for this test:
# -----------------------------------------------------------------------------
# File                       stmt branch   cond    sub   time  total
# ------------------------ ------ ------ ------ ------ ------ ------
# /Tree/Simple.pm            49.3   47.3   57.8   71.4  100.0   55.5
## ----------------------------------------------------------------------------

use Tree::Simple;

my $BAD_OBJECT = bless({}, "Fail");
my $TEST_SUB_TREE = Tree::Simple->new("test");

my $tree = Tree::Simple->new(Tree::Simple->ROOT);

# -----------------------------------------------
# exceptions for setNodeValue
# -----------------------------------------------

# not giving an argument for setNodeValue
throws_ok {
	$tree->setNodeValue();
} qr/^Insufficient Arguments \: must supply a value for node/, '... this should die';

# -----------------------------------------------
# exceptions for addChild
# -----------------------------------------------

# not giving an argument for addChild
throws_ok {
	$tree->addChild();
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';

# giving an bad argument for addChild
throws_ok {
	$tree->addChild("fail");
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';

# giving an bad argument for addChild
throws_ok {
	$tree->addChild([]);
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';


# giving an bad object argument for addChild
throws_ok {
	$tree->addChild($BAD_OBJECT);
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';

# -----------------------------------------------
# exceptions for insertChild
# -----------------------------------------------

# giving no index argument for insertChild
throws_ok {
	$tree->insertChild();
} qr/^Insufficient Arguments \: Cannot insert child without index/, '... this should die';

# giving an out of bounds index argument for insertChild
throws_ok {
	$tree->insertChild(5);
} qr/^Index Out of Bounds \: got \(5\) expected no more than \(0\)/, '... this should die';

# giving an good index argument but no tree argument for insertChild
throws_ok {
	$tree->insertChild(0);
} qr/^Insufficient Arguments \: no tree\(s\) to insert/, '... this should die';

# giving an good index argument but an undefined tree argument for insertChild
throws_ok {
	$tree->insertChild(0, undef);
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';

# giving an good index argument but a non-object tree argument for insertChild
throws_ok {
	$tree->insertChild(0, "Fail");
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';

# giving an good index argument but a non-object-ref tree argument for insertChild
throws_ok {
	$tree->insertChild(0, []);
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';


# giving an good index argument but a bad object tree argument for insertChild
throws_ok {
	$tree->insertChild(0, $BAD_OBJECT);
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';

# -----------------------------------------------
# exceptions for insertChildren
# -----------------------------------------------
# NOTE:
# even though insertChild and insertChildren are
# implemented in the same function, it makes sense
# to future-proof our tests by checking it anyway
# this will help to save us the trouble later on

# giving no index argument for insertChild
throws_ok {
	$tree->insertChildren();
} qr/^Insufficient Arguments \: Cannot insert child without index/, '... this should die';

# giving an out of bounds index argument for insertChild
throws_ok {
	$tree->insertChildren(5);
} qr/^Index Out of Bounds \: got \(5\) expected no more than \(0\)/, '... this should die';

# giving an good index argument but no tree argument for insertChild
throws_ok {
	$tree->insertChildren(0);
} qr/^Insufficient Arguments \: no tree\(s\) to insert/, '... this should die';

# giving an good index argument but an undefined tree argument for insertChild
throws_ok {
	$tree->insertChildren(0, undef);
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';

# giving an good index argument but a non-object tree argument for insertChild
throws_ok {
	$tree->insertChildren(0, "Fail");
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';

# giving an good index argument but a non-object-ref tree argument for insertChild
throws_ok {
	$tree->insertChildren(0, []);
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';


# giving an good index argument but a bad object tree argument for insertChild
throws_ok {
	$tree->insertChildren(0, $BAD_OBJECT);
} qr/^Insufficient Arguments \: Child must be a Tree\:\:Simple object/, '... this should die';


# -----------------------------------------------
# exceptions for removeChild
# -----------------------------------------------

# giving no index argument for removeChild
throws_ok {
	$tree->removeChild();
} qr/^Insufficient Arguments \: Cannot remove child without index/, '... this should die';

# attempt to remove a child when there are none
throws_ok {
	$tree->removeChild(5);
} qr/^Illegal Operation \: There are no children to remove/, '... this should die';

# add a child now
$tree->addChild($TEST_SUB_TREE);

# giving no index argument for removeChild
throws_ok {
	$tree->removeChild(5);
} qr/^Index Out of Bounds \: got \(5\) expected no more than \(1\)/, '... this should die';

is($tree->removeChild(0), $TEST_SUB_TREE, '... these should be the same');

# -----------------------------------------------
# exceptions for *Sibling methods
# -----------------------------------------------

# attempting to add sibling to root trees
throws_ok {
	$tree->addSibling($TEST_SUB_TREE);
} qr/^Insufficient Arguments \: cannot add a sibling to a ROOT tree/, '... this should die';

# attempting to add siblings to root trees
throws_ok {
	$tree->addSiblings($TEST_SUB_TREE);
} qr/^Insufficient Arguments \: cannot add siblings to a ROOT tree/, '... this should die';

# attempting to insert sibling to root trees
throws_ok {
	$tree->insertSibling(0, $TEST_SUB_TREE);
} qr/^Insufficient Arguments \: cannot insert sibling\(s\) to a ROOT tree/, '... this should die';

# attempting to insert sibling to root trees
throws_ok {
	$tree->insertSiblings(0, $TEST_SUB_TREE);
} qr/^Insufficient Arguments \: cannot insert sibling\(s\) to a ROOT tree/, '... this should die';

# -----------------------------------------------
# exceptions for getChild
# -----------------------------------------------

# not giving an index to the getChild method
throws_ok {
	$tree->getChild();
} qr/^Insufficient Arguments \: Cannot get child without index/, '... this should die';

# -----------------------------------------------
# exceptions for getSibling
# -----------------------------------------------

# trying to get siblings of a root tree
throws_ok {
	$tree->getSibling();
} qr/^Insufficient Arguments \: cannot get siblings from a ROOT tree/, '... this should die';

# trying to get siblings of a root tree
throws_ok {
	$tree->getAllSiblings();
} qr/^Insufficient Arguments \: cannot get siblings from a ROOT tree/, '... this should die';

# -----------------------------------------------
# exceptions for traverse
# -----------------------------------------------

# passing no args to traverse
throws_ok {
	$tree->traverse();
} qr/^Insufficient Arguments \: Cannot traverse without traversal function/, '... this should die';

# passing non-ref arg to traverse
throws_ok {
	$tree->traverse("Fail");
} qr/^Incorrect Object Type \: traversal function is not a function/, '... this should die';

# passing non-code-ref arg to traverse
throws_ok {
	$tree->traverse($BAD_OBJECT);
} qr/^Incorrect Object Type \: traversal function is not a function/, '... this should die';

# -----------------------------------------------
# exceptions for accept
# -----------------------------------------------

# passing no args to accept
throws_ok {
	$tree->accept();
} qr/^Insufficient Arguments \: You must supply a valid Tree\:\:Simple\:\:Visitor object/, '... this should die';

# passing non-ref arg to accept
throws_ok {
	$tree->accept("Fail");
} qr/^Insufficient Arguments \: You must supply a valid Tree\:\:Simple\:\:Visitor object/, '... this should die';

# passing non-object-ref arg to accept
throws_ok {
	$tree->accept([]);
} qr/^Insufficient Arguments \: You must supply a valid Tree\:\:Simple\:\:Visitor object/, '... this should die';


# passing non-Tree::Simple::Visitor arg to accept
throws_ok {
	$tree->accept($BAD_OBJECT);
} qr/^Insufficient Arguments \: You must supply a valid Tree\:\:Simple\:\:Visitor object/, '... this should die';

# -----------------------------------------------
# exceptions for _setParent
# -----------------------------------------------

# if no parent is given
throws_ok {
	$tree->_setParent();
} qr/^Insufficient Arguments/, '... this should croak';

# if the parent that is given is not an object
throws_ok {
	$tree->_setParent("Test");
} qr/^Insufficient Arguments/, '... this should croak';

# if the parent that is given is a ref but not an object
throws_ok {
	$tree->_setParent([]);
} qr/^Insufficient Arguments/, '... this should croak';

# and if the parent that is given is an object but
# is not a Tree::Simple object
throws_ok {
	$tree->_setParent($BAD_OBJECT);
} qr/^Insufficient Arguments/, '... this should croak';

## ----------------------------------------------------------------------------
## end Exception Tests for Tree::Simple
## ----------------------------------------------------------------------------	

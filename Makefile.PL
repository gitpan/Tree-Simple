use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile
(
	'NAME'         => 'Tree::Simple',
	'VERSION_FROM' => 'lib/Tree/Simple.pm',
	'PREREQ_PM'    =>
	{
		'Scalar::Util'    => '1.18',
		'Test::Exception' => '0.15',
		'Test::More'      => '0.47'
	},
	'INSTALLDIRS' => 'site',
	'EXE_FILES'   => [],
	'PL_FILES'    => {}
);

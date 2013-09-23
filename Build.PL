use 5.006;
use strict;
use warnings;

use Module::Build;

Module::Build -> new
(
	module_name        => 'Tree::Simple',
	dist_version_from  => 'lib/Tree/Simple.pm',
	license            => 'perl',
	configure_requires =>
	{
		'Module::Build' => 0.40,
	},
	requires          =>
	{
		'perl'         => '5.6.0',
		'Scalar::Util' => '1.18',
	},
	build_requires =>
	{
		'Test::More'      => '0.47',
		'Test::Exception' => '0.15',
	},
) -> create_build_script;

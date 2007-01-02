# add_get_default test

use strict ;
use warnings ;
use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn ;
use Test::NoWarnings qw(had_no_warnings) ;

use Test::More 'no_plan';
use Test::Block qw($Plan);
  
use Config::Hierarchical ; 

{
local $Plan = {'SILENT_NOT_EXISTS' => 1} ;

dies_ok
	{
	my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES  => ['CLI', 'CURRENT'],
				) ;
	} "must define DEFAULT_CATEGORY" ;
}

{
local $Plan = {'SILENT_NOT_EXISTS' => 1} ;

dies_ok
	{
	my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES    => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURENT',
				) ;
	} "default category must be part of the categories" ;
}

{
local $Plan = {'initial values' => 10} ;

my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES    => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				INITIAL_VALUES  =>
					[
					[CATEGORY => 'CLI', NAME => 'CC', VALUE => 1],
					[CATEGORY => 'CLI', NAME => 'CC', VALUE => 2],
					[CATEGORY => 'CURRENT', NAME => 'LD', VALUE => 3, LOCK => 1],
					[NAME => 'AS', VALUE => 4, LOCK => 1],
					] ,
				) ;
				
is(defined $config, 1, 'constructor with initial values') ;

is($config->IsLocked(NAME => 'CC', CATEGORY => 'CLI'), 0, 'config not locked') ;
is($config->IsLocked(NAME => 'LD'), 1, 'config locked') ;

is($config->Get(NAME => 'CC'), '2', 'initialized ok') ;
is($config->Get(NAME => 'LD'), '3', 'initialized ok') ;
is($config->Get(CATEGORY => 'CURRENT', NAME => 'AS'), 4, 'initialized ok') ;

is($config->Exists(NAME => 'LD'), 1, 'exist') ;
is($config->Exists(NAME => 'CC'), 1, 'exist') ;
is($config->Exists(NAME => 'NOT_EXIST'), 0, 'not exist') ;

dies_ok
	{
	$config->Exists(CATEGORY => 'CURRENT', NAME => 'DOESNT_MATTER') ;
	} 'no category allowed' ;

}

{
local $Plan = {'initial values' => 3} ;

dies_ok
	{
	new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				
				INITIAL_VALUES  =>
					[
					[CATEGORY => 'CLI', NAME => 'CC'],
					] ,
				) ;
	} "missing  parameter" ;
	
dies_ok
	{
	new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				
				INITIAL_VALUES   =>
					[
					[CATEGORY => 'CLI', NAMEX => 'CC', VALUE => 1],
					] ,
				) ;
	} "bad parameter" ;
	
dies_ok
	{
	new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				
				INITIAL_VALUES   =>
					[
					[CATEGORY => 'BAD_CATEGORY', NAME => 'CC', VALUE => 1],
					] ,
				) ;
	} "bad category" ;
}

{
local $Plan = {'initial values' => 8} ;

my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				) ;
				
$config->Set(CATEGORY => 'CLI', NAME => 'CC', VALUE => 1) ;
is($config->Get(NAME => 'CC'), 1, 'Set ok') ;

warning_like
	{
	is($config->Get(NAME => 'AS'), undef, 'Not set ok') ;
	} qr/Returning undef/i, "element doesn't exist";
	

is($config->Get(CATEGORY => 'XYZ', NAME => 'CC'), 1, 'Category ignored in Get') ;

warning_like
	{
	$config->Set(CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2) ;
	} qr/Precedence will be given/i, "precedence will be given";

is($config->Get(NAME => 'CC'), 1, 'High priority category')  or diag DumpTree $config ;

warning_like
	{
	$config->Set(CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2, OVERRIDE => 1) ;
	} qr/Overriding config/i, "override";

is($config->Get(NAME => 'CC'), 2, 'override') ;
}

{
local $Plan = {'override is not time dependent' => 1} ;

my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES   =>
				[
				[CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2, OVERRIDE => 1],
				[CATEGORY => 'CLI', NAME => 'CC', VALUE => 1],
				] ,
			) ;

is($config->Get(NAME => 'CC'), 2, 'override is not time dependent')  or diag DumpTree $config ;
}

{
local $Plan = {'override and no silent override' => 1} ;

my $config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 1, 
			
			CATEGORY_NAMES   => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES   =>
				[
				[CATEGORY => 'CLI', NAME => 'CC', VALUE => 1],
				[CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2, OVERRIDE => 1],
				] ,
			) ;

is($config->Get(NAME => 'CC'), 2, 'override is not time dependent')  or diag DumpTree $config ;
}

{
local $Plan = {'SILENT_NOT_EXISTS' => 3} ;

my $config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES  => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES  =>
				[
				[CATEGORY => 'CLI', NAME => 'CLI', VALUE => 1],
				[CATEGORY => 'CURRENT', NAME => 'CURRENT', VALUE => 1],
				] ,
			) ;

my $ cc = $config->Get(CATEGORY => 'CLI', NAME => 'CC', SILENT_NOT_EXISTS => 1) ;
had_no_warnings("getting non existing variable, warning localy disabled") ; 

warning_like
	{
	$cc = $config->Get(CATEGORY => 'CLI', NAME => 'CC') ;
	} qr/'CC' doesn't exist/, "getting non existing variable" ;
	
$config->SetDisableSilentOptions(1) ;

$cc = $config->Get(CATEGORY => 'CLI', NAME => 'CC') ;
had_no_warnings("getting existing variable, warning disabled") ; 
}


{
local $Plan = {'SILENT_OVERRIDE' => 3} ;

my $config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES  => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES  =>
				[
				[CATEGORY => 'CLI', NAME => 'CLI', VALUE => 1],
				[CATEGORY => 'CLI', NAME => 'CLI2', VALUE => 1],
				[CATEGORY => 'CLI', NAME => 'CLI3', VALUE => 1],
				] ,
			) ;

$config->Set(CATEGORY => 'CURRENT', NAME => 'CLI', VALUE => 'override', SILENT_OVERRIDE => 1) ;
had_no_warnings("overriding variable, warning localy disabled") ; 

warning_like
	{
	$config->Set(CATEGORY => 'CURRENT', NAME => 'CLI2', VALUE => 'override') ;
	} qr/Precedence will be given to 'CLI::CLI2'/, "overriding variable" ;
	
$config->SetDisableSilentOptions(1) ;
$config->Set(CATEGORY => 'CURRENT', NAME => 'CLI3', VALUE => 'override') ;
had_no_warnings("overriding variable, warning globaly disabled") ; 
}

{
local $Plan = {'GetHash' => 2} ;

my $config ;

warning_like
	{
	$config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES  => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES  =>
				[
				[CATEGORY => 'CLI',     NAME => 'CLI',     VALUE => 'CLI_CLI'],
				[CATEGORY => 'CLI',     NAME => 'CLI2',    VALUE => 'CLI_CLI2'],
				[CATEGORY => 'CURRENT', NAME => 'CURRENT', VALUE => 'CURRENT'],
				[CATEGORY => 'CURRENT', NAME => 'CLI',     VALUE => 'CURRENT_CLI'],
				[CATEGORY => 'CURRENT', NAME => 'CLI2',    VALUE => 'CURRENT_CLI2', OVERRIDE => 1],
				] ,
			) ;
	} 
	[
	qr/Setting 'CURRENT::CLI'. Precedence will be given to 'CLI::CLI'/,
	qr/Setting 'CURRENT::CLI2'. Overriding config 'CLI2' in category 'CLI'/,
	], "initialisation" ;

is_deeply(scalar($config->GetHashRef()),{CLI => 'CLI_CLI', CLI2 => 'CURRENT_CLI2', CURRENT => 'CURRENT'}, 'expected values') ;
}

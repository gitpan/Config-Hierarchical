
# t/001_load.t - check module loading

use strict ;
use warnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'Config::Hierarchical' ); } ;

my $config = new Config::Hierarchical() ;

is(defined $config, 1, 'default constructor') ;
isa_ok($config, 'Config::Hierarchical');

my $new_config = $config->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , 'Config::Hierarchical');


dies_ok
	{
	Config::Hierarchical::new () ;
	} "invalid constructor" ;


my $alarm_reached = 0 ;
eval
	{
	local $SIG{ALRM} = sub {$alarm_reached++ ; die} ;
	alarm 1 ;
	
	eval
		{
		my $input = <STDIN> ;
		} ;
	
	alarm 0 ;
	} ;

alarm 0 ;

if($alarm_reached)
	{
	SKIP: 
		{
		skip 'Syntax ok and use strict (press key to run)', 1 ;
		}
	}
else
	{
	use Test::Strict;
	all_perl_files_ok();
	}
	
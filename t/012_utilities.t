# utilities test

use strict ;
use warnings ;
use Test::Exception ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Test::NoWarnings ;
use Test::Warn ;

use Config::Hierarchical ; 

{
local $Plan = {'empty history' => 13} ;

my $config = new Config::Hierarchical() ;

my $history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "unexisting variable history") ;

$history = $config->GetHistory(CATEGORY => 'CURRENT', NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "unexisting variable history") ;

# do stuff that don't change history
$config->Set(NAME => 'XYZ', VALUE => 1) ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "Set") ;

$config->SetMultiple([NAME => 'XYZ', VALUE => 1], [NAME => 'ABC', VALUE => 1]) ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "SetMultiple") ;

# do stuff that don't change history
my $xyz = $config->Get(NAME => 'XYZ') ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "Get") ;

my @multiple = $config->GetMultiple('XYZ', 'ABC') ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "GetMultiple") ;

my $hash_ref = $config->GetHashRef() ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "GetHashRed") ;

$config->SetDisableSilentOptions(1) ;
$config->SetDisableSilentOptions(0) ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "SetDisableSilentOptions") ;

$config->IsLocked(NAME => 'CC') ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "IsLocked") ;

$config->GetDump() ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "GetDump") ;

$config->GetHistory(NAME => 'XYZ') ;
$history = $config->GetHistory(NAME => 'CC') ;
like($history, qr/Variable '.*::CC' doesn't exist!$/, "GetHistory") ;

throws_ok
	{
	$config->GetHistory(FILE => 'my file', LINE => 'my line') ;
	} qr/my file:my line/, "location options used in die" ;

dies_ok
	{
	$config->GetHistory(CATEGORY => 'NOT_EXIT', NAME => 'CC') ;
	} "bad category" ;
}

{
local $Plan = {'history' => 19} ;

my $creation_line = __LINE__ + 1 ;
my $config = new Config::Hierarchical
				(
				INITIAL_VALUES  =>
					[
					[NAME => 'CC', VALUE => 1],
					[NAME => 'CC', VALUE => 2],
					[NAME => 'AS', VALUE => 4],
					] ,
				) ;

is($config->Get(NAME => 'CC'), 2, 'right value') ;

my $history = $config->GetHistory(NAME => 'CC') ;

is(scalar(@{$history}), 2, '2 entries')  ;

my $lock_line = __LINE__ + 1 ;
$config->Lock(NAME => 'CC') ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 3, '3 entries')  ;

my $unlock_line = __LINE__ + 1 ;
$config->Unlock(NAME => 'CC') ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 4, '4 entries') ;

$config->IsLocked(NAME => 'CC') ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 4, '4 entries') ;

$config->GetDump() ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 4, '4 entries') ;

$config->GetHistory(NAME => 'CC') ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 4, '4 entries') ;

like($history->[0]{STATUS}, qr/Set: Success, did not exist/, 'history entry 1')  ;
is($history->[0]{FILE}, __FILE__, 'from this file') ;
is($history->[0]{LINE}, $creation_line, 'line') ;

like($history->[1]{STATUS}, qr/Set: Success/, 'history entry 2')  ;
is($history->[1]{FILE}, __FILE__, 'from this file') ;
is($history->[1]{LINE}, $creation_line, 'line') ;

like($history->[2]{STATUS}, qr/Lock: success/, 'history entry 3')  ;
is($history->[2]{FILE}, __FILE__, 'from this file') ;
is($history->[2]{LINE}, $lock_line, 'line') ;

like($history->[3]{STATUS}, qr/Unlock: success/, 'history entry 4')  ;
is($history->[3]{FILE}, __FILE__, 'from this file') ;
is($history->[3]{LINE}, $unlock_line, 'line') ;
}

{
local $Plan = {'Dump' => 1} ;

my $config = new Config::Hierarchical
				(
				INITIAL_VALUES  =>
					[
					[NAME => 'CC', VALUE => 1],
					[NAME => 'CC', VALUE => 2],
					[NAME => 'AS', VALUE => 4],
					] ,
				) ;

my $dump = $config->GetDump() ;
isnt($dump, '', 'dump not empty') ;
}


{
local $Plan = {'verbose' => 44} ;

#TODO add checking of the message and that the location is reported properly

my @messages ;
my $info = sub {push @messages, @_} ;
	
my $config = new Config::Hierarchical
				(
				NAME            => 'verbose test',
				VERBOSE         => 1,
				INITIAL_VALUES  => [[NAME => 'CC', VALUE => 1]],
				INTERACTION     => {INFO => $info},
				) ;

is(@messages, 2, "Create and Set messages") ;

my $file_regex = __FILE__ ; $file_regex = qr/$file_regex/ ;

like($messages[0], $file_regex, 'verbose reports right file') ;
like($messages[0], qr/Create/, 'creation message') ;
like($messages[1], $file_regex, 'verbose reports right file') ;
like($messages[1], qr/Set/, 'Set message') ;

my $cc = $config->Get(NAME => 'CC') ;
is(@messages, 3, "Get message") ;
like($messages[2], $file_regex, 'verbose reports right file') ;
like($messages[2], qr/Get/, 'Get message') ;

$config->GetDump() ;
is(@messages, 3, "Dump generates no message") ;

my $hash_ref = $config->GetHashRef() ;
is(@messages, 4, "GetHashRef generates a message per variable") ;
like($messages[3], $file_regex, 'verbose reports right file') ;
like($messages[3], qr/Get/, 'Get message') ;

$config->GetHistory(NAME => 'CC') ;
is(@messages, 4, "GetHistory generates no message") ;

$config->Set(NAME => 'LD', VALUE => 2) ;
is(@messages, 5, "set message") ;
like($messages[4], $file_regex, 'verbose reports right file') ;
like($messages[4], qr/Set/, 'Set message') ;

$config->SetMultiple([NAME => 'M1', VALUE => 1], [NAME => 'M2', VALUE => 1]) ;
is(@messages, 7, "SetMultiple messages") ;
like($messages[5], $file_regex, 'verbose reports right file') ;
like($messages[5], qr/Set/, 'Set message') ;
like($messages[6], $file_regex, 'verbose reports right file') ;
like($messages[6], qr/Set/, 'Set message') ;

my @multiple = $config->GetMultiple('M1', 'M2') ;
is(@messages, 9, "GetMultiple messages") ;
like($messages[7], $file_regex, 'verbose reports right file') ;
like($messages[7], qr/Get/, 'Get message') ;
like($messages[8], $file_regex, 'verbose reports right file') ;
like($messages[8], qr/Get/, 'Get message') ;

$config->IsLocked(NAME => 'CC') ;
is(@messages, 10, "IsLocked message") ;
like($messages[9], $file_regex, 'verbose reports right file') ;
like($messages[9], qr/Check/, 'checking message') ;

$config->Lock(NAME => 'CC') ;
is(@messages, 11, "Lock message") ;
like($messages[10], $file_regex, 'verbose reports right file') ;
like($messages[10], qr/locking/i, 'locking message') ;

$config->Unlock(NAME => 'CC') ;
is(@messages, 12, "Unlock message") ;
like($messages[11], $file_regex, 'verbose reports right file') ;
like($messages[11], qr/unlocking/i, 'unlocking message') ;

$config->SetDisableSilentOptions(1) ;
is(@messages, 13, "SetDisableSilentOptions message") ;
like($messages[12], $file_regex, 'verbose reports right file') ;
like($messages[12], qr/DISABLE_SILENT_OPTIONS/, 'DISABLE_SILENT_OPTIONS') ;

$config->SetDisableSilentOptions(0) ;
is(@messages, 14, "SetDisableSilentOptions message") ;
like($messages[13], $file_regex, 'verbose reports right file') ;
like($messages[13], qr/DISABLE_SILENT_OPTIONS/, 'DISABLE_SILENT_OPTIONS') ;

$config->Exists(VERBOSE => 1, NAME => 'CC') ;
is(@messages, 15, "Exists message") ;
like($messages[14], $file_regex, 'verbose reports right file') ;
like($messages[14], qr/Checking Existance/, 'Checking Existance') ;

#~ diag @messages ;
}




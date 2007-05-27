
use Test::Cookbook ;

=head1 Config::Hierarchical cookbook

=head2 Simple usage

=head3	Creating a Config::Hierarchical configuration container

=begin common

	use Config::Hierarchical ;
	
	# give the config a name to get user friendly errors
	
	my $config = new Config::Hierarchical(NAME => 'Simple usage example config') ;

=end common

=begin test

	# Config::Hierarchical allows us to get its generated warning and errors
	
	my ($warnings, $die) ;
	$config->{INTERACTION}{WARN} = sub{$warnings = join('', @_) ; use Carp ;carp $warnings; } ;
	$config->{INTERACTION}{DIE} = sub{$die= join('', @_) ; use Carp ;croak $die} ; 

=end test

This will create a container with default values. You can modify the container behavior by passing options
to the constructor. See the L<Config::Hierarchical> manual for all initialization options.

=head3	Setting and getting configuration variables

=begin common

	$config->Set(NAME => 'CC', VALUE => 'gcc') ;
	$config->Set(NAME => 'LD', VALUE => 'ld') ;
	
	print "Value for 'CC' is '" . $config->Get(NAME => 'CC') . "'.\n" ;
	print "'LD' exists.\n" if $config->Exists(NAME => 'LD') ;

=end common

Would display:

=begin test

	my $cc_value = $config->Get(NAME => 'CC') ;
	is($cc_value, 'gcc', 'Get returns right value') ;
	generate_pod("\tValue for 'CC' is '$cc_value'.\n") ; # note the \t in the string so the pod is presented properly
	generate_pod("\t'LD' exists.\n") if $config->Exists(NAME => 'LD') ;
	generate_pod("\n") ;

=end test

=head3 Set the same variable multiple time with different values

=begin common

	$config->Set(NAME => 'CC', VALUE => 'gcc') ;
	$config->Set(NAME => 'CC', VALUE => 'cl') ;
	
	print "Value for 'CC' is '" . $config->Get(NAME => 'CC') . "'.\n\n" ;

=end common

Would display:

=begin test

	$cc_value = $config->Get(NAME => 'CC') ;
	is($cc_value, 'cl', 'Get returns right value') ;
	generate_pod("\tValue for 'CC' is '$cc_value'.\n\n") ;

=end test

B<Config::Hierarchical> does not generate any warning when you override a variable's value. If you would like to get an error,
lock the variable.

=head4 Locking variables

	$config->Set(NAME => 'CC', VALUE => 'gcc') ;
	$config->Lock(NAME => 'CC') ;
	$config->Set(NAME => 'CC', VALUE => 'cl') ;

This would generate the following error followed by a stack trace.

=begin test

# the code above generates an error and dies so we can't run it directly in a common section

	dies_ok
		{
		$config->Set(NAME => 'CC', VALUE => 'gcc') ;
		$config->Lock(NAME => 'CC') ;
		$config->Set(NAME => 'CC', VALUE => 'cl') ;
		} 'Setting locked variable' ;
	
	$die =~ s/^/\t/gm ;
	generate_pod($die . "\n") ;
	
	$cc_value = $config->Get(NAME => 'CC') ;
	is($cc_value, 'gcc', 'Get returns right value') ;

=end test

=head4 Setting Locked variables

=begin common

	$config->Set(FORCE_LOCK => 1, NAME => 'CC', VALUE => 'cl') ;
	print "Value for 'CC' is '" . $config->Get(NAME => 'CC') . "'.\n\n" ;

=end common

Would display:

=begin test

	$cc_value = $config->Get(NAME => 'CC') ;
	is($cc_value, 'cl', 'Get returns right value') ;
	generate_pod("\t$warnings\n") ;
	generate_pod("\tValue for 'CC' is '$cc_value'.\n\n") ;

=end test

=head4 Getting the lock state

	print "'CC' is locked.\n" if $config->IsLocked(NAME => 'CC') ;
	print "'LD' is locked.\n" if $config->IsLocked(NAME => 'LD') ;

Would display:

=begin test

	is($config->IsLocked(NAME => 'LD'), 0, 'config not locked') ;
	is($config->IsLocked(NAME => 'CC'), 1, 'config locked') ;
	
	generate_pod("\t'CC' is locked.\n") if $config->IsLocked(NAME => 'CC') ;
	generate_pod("\t'LD' is locked.\n") if $config->IsLocked(NAME => 'LD') ;
	generate_pod("\n") ;

=end test

=for POD::Tested reset

=head2 Setting variable  in the constructor

=begin common

	use Config::Hierarchical ;
	
	my $config = new Config::Hierarchical
				(
				NAME => 'Config initialized in constructor',
				INITIAL_VALUES =>
					[
					{NAME => 'CC', VALUE => 1},
					{NAME => 'CC', VALUE => 2},
					{NAME => 'LD', VALUE => 3, LOCK => 1},
					{NAME => 'AS', VALUE => 4, LOCK => 1},
					],
				) ;

=end common

=begin test

	my ($warnings, $die) ;
	$config->{INTERACTION}{WARN} = sub{$warnings = join('', @_) ; use Carp ;carp $warnings; } ;
	$config->{INTERACTION}{DIE} = sub{$die= join('', @_) ; use Carp ;croak $die} ; 
	
	is($config->IsLocked(NAME => 'CC'), 0, 'config not locked') ;
	is($config->IsLocked(NAME => 'LD'), 1, 'config locked') ;
	
	is($config->Get(NAME => 'CC'), '2', 'initialized ok') or diag  $config->GetDump();
	is($config->Get(NAME => 'LD'), '3', 'initialized ok') ;
	is($config->Get(CATEGORY => 'CURRENT', NAME => 'AS'), 4, 'initialized ok') ;
	
	is($config->Exists(NAME => 'AS'), 1, 'exist') ;

=end test

=head2 Getting a non existing variable value

=begin common

	my $value = $config->Get(NAME => 'NON_EXISTING') ;
	print "Value for 'NON_EXISTING' is defined\n" if defined $value ;

=end common

Would display:

=begin test

	generate_pod("\t$warnings\n") ;
	generate_pod("Value for 'NON_EXISTING' is defined\n") if defined $value ;

=end test

=head2 Getting multiple variable values

=begin common

	my @variables = qw(CC LD AS) ;
	my %values ;
	
	@values{@variables} = $config->GetMultiple(@variables) ;
	
	use Data::TreeDumper ;
	
	my $dump = DumpTree \%values, 'Variables', INDENTATION => "\t", DISPLAY_ADDRESS => 0 ; 
	print $dump ;

=end common

Would display:

=begin test

	is_deeply(\%values, {CC => 2, LD => 3, AS => 4}, 'GetMultiple OK') ;
	
	generate_pod("$dump\n") ;
	generate_pod("\n") ;

=end test

=head2 history and comments

B<Config::Hierarchical> will keep an history  for each variable in you config.

=begin common

	print $config->GetHistoryDump(NAME => 'CC') ;

=end common

=begin test

	generate_pod($config->GetHistoryDump(NAME => 'CC', DATA_TREEDUMPER_OPTIONS => [INDENTATION => "\t"])) ;
	generate_pod("\n") ;

=end test

The reference manual describes a L<Data::TreeDumper> filter that you can use to generate a history in the
following format:

=begin test

	sub Compact
	{
	my ($s, $level, $path, $keys, $setup, $arg) = @_ ;
	
	if('ARRAY' eq ref $s)
		{
		my ($index, @replacement, @keys) = (0) ;
		
		for my $entry( @$s)
			{
			if(exists $entry->{EVENT})
				{
				push @replacement, $entry->{EVENT} ; #. 'time: ' . $entry->{TIME};
				push@keys, $index++ ;
				}
			else
				{
				my ($aliased_history_name) = grep {$_ ne 'TIME'} keys %$entry ;
				
				push @replacement, $entry->{$aliased_history_name} ;
				push@keys, [$index, "$index = $aliased_history_name"] ;
				$index++ ;
				}
			}
		
		return('ARRAY', \@replacement, @keys) ;
		}
	}
	
	my $compact_dump = DumpTree $config->GetHistory( NAME => 'CC'), 'CC', DISPLAY_ADDRESS => 0, FILTER => \&Compact, INDENTATION => "\t" ;
	
	generate_pod($compact_dump) ;
	generate_pod("\n") ;

=end test

You can also add a comment to the history when you manipulate variables.

=begin common

	$config->Set(NAME => 'LD', VALUE => 'new LD value', FORCE_LOCK => 1, COMMENT => 'why we forced the lock') ;

=end common

Would give this history:

=begin test

	generate_pod($config->GetHistoryDump(NAME => 'LD', DATA_TREEDUMPER_OPTIONS => [INDENTATION => "\t"])) ;
	generate_pod("\n") ;

=end test

See I<GetHistory> in the manual if you want to handle the history data directly.

=head2 Validators

You can assign validators to variables. If a validator return B<false>, B<Config::Hierarchical> will generate and error.

Validators can be defined in the B<Config::Hierarchical> constructor or can be local in a I<Set> call.

=begin common

	sub PositiveValueValidator
	{
	my ($value) = @_; 
	return($value >= 0)
	} ;

=end common

	$config->Set
		(
		NAME => 'CC',
		VALUE => -1, 
		VALIDATORS => {positive_value => \&PositiveValueValidator,},
		) ;	

Will generate the following error:

=begin test

	throws_ok
		{
		$config->Set
			(
			NAME => 'CC',
			VALUE => -1, 
			VALIDATORS => {positive_value => \&PositiveValueValidator,},
			) ;	
		} qr/Invalid value for variable 'CC'. Local validator 'positive_value' defined at .*/, "local validator" ;
		
	$die =~ s/^/\t/gm ;
	generate_pod($die . "\n") ;

=end test

=head2 GetKeys

You can get a list of all the variable names.

=begin common

	my @variable_names = $config->GetKeys() ;
	
	print 'The config contains the following variables: ' . join(', ', @variable_names) . ".\n" ;

=end common

Would display:

=begin test

	generate_pod("\tThe config contains the following variables: " . join(', ', @variable_names) . ".\n\n") ;

=end test

=head2 Key and value tuples

You can also get a list containing a tuple for each of the config variable. The Tuple is a hash reference. This lets you
write code like :

	map
		{
		my $name =  $_->{NAME} ;
		my $value = $_->{VALUE} ;
		
		# your code here
		
		} $config->GetKeyValueTuples() ;

=head2 Categories

=for POD::Tested reset

	my $config = new Config::Hierarchical
				(
				NAME => 'config with categories',
				
				CATEGORY_NAMES   => ['A', 'B'],
				DEFAULT_CATEGORY => 'B',
				
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'A', NAME => 'CC', VALUE => 'A_CC'},
					{CATEGORY => 'B', NAME => 'CC', VALUE => 'B_CC'},
					{CATEGORY => 'A', NAME => 'LD', VALUE => 'A_LD'},
					{CATEGORY => 'B', NAME => 'LD', VALUE => 'B_LD'},
					{CATEGORY => 'A', NAME => 'AS', VALUE => 'A_AS'},
					] ,
				) ;

=begin test

# initialisation above generates warnings we need to catch

	my ($warnings, $die) ;
	
	my $config = new Config::Hierarchical
				(
				NAME => 'config with categories',
				
				CATEGORY_NAMES   => ['A', 'B'],
				DEFAULT_CATEGORY => 'B',
				
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'A', NAME => 'CC', VALUE => 'A_CC'},
					{CATEGORY => 'B', NAME => 'CC', VALUE => 'B_CC'},
					{CATEGORY => 'A', NAME => 'LD', VALUE => 'A_LD'},
					{CATEGORY => 'B', NAME => 'LD', VALUE => 'B_LD'},
					{CATEGORY => 'A', NAME => 'AS', VALUE => 'A_AS'},
					] ,
					
				INTERACTION =>
					{
					WARN => sub{$warnings .= "\t" . join('', @_) . "\n"; use Carp ;carp join('', @_); },
					DIE => sub{$die .= join('', @_) ; use Carp ;croak join('', @_)},
					} ,
				) ;
	
=end test

Would generate the following warnings:

=begin test

	generate_pod("$warnings\n") ;
	$warnings = '' ;

=end test

And the config would be:

=begin test

	my $hash = $config->GetHashRef() ;
	
	generate_pod(DumpTree($hash, 'Config contains:', DISPLAY_ADDRESS => 0 , INDENTATION => "\t")) ;
	generate_pod("\n") ;

=end test

B<Config::Hierarchical> will display a warning anytime you set a variable and that a higher level configuration takes precedence.

=head3 Lower categories warning

By default, no warning are displayed when a lower category value will be ignored. You can make B<Config::Hierarchical> check
lower categories this way:

=begin common

  $config->Set(CATEGORY => 'A', NAME => 'CC', VALUE => 'A_CC_2', CHECK_LOWER_LEVEL_CATEGORIES => 1) ;

=end common

Would generate the following warnings:

=begin test

	generate_pod("$warnings\n") ;
	$warnings = '' ;

=end test

The config is now:

=begin test

	$hash = $config->GetHashRef() ;
	
	generate_pod(DumpTree($hash, 'Config contains:', DISPLAY_ADDRESS => 0 , INDENTATION => "\t")) ;
	generate_pod("\n") ;

=end test

=head3 Overriding a higher level category

Is done this way:

=begin common

  $config->Set(CATEGORY => 'B', NAME => 'CC', VALUE => 'B_CC_2', OVERRIDE => 1) ;

=end common

And would generate the following warnings:

=begin test

	generate_pod("$warnings\n") ;
	$warnings = '' ;

=end test

The config is now:

=begin test

	$hash = $config->GetHashRef() ;
	
	generate_pod(DumpTree($hash, 'Config contains:', DISPLAY_ADDRESS => 0 , INDENTATION => "\t")) ;
	generate_pod("\n") ;

=end test

=head3 History from multiple categories

=begin common

	print $config->GetHistoryDump(NAME => 'CC') ;

=end common

=begin test

	generate_pod($config->GetHistoryDump(NAME => 'CC', DATA_TREEDUMPER_OPTIONS => [INDENTATION => "\t"])) ;
	generate_pod("\n") ;

=end test


=head2 Tie::Readonly

You can tie your configuration to a read only hash. this lets you manipulate your config like a normal hash. Interpolation
in strings is also much easier.

=begin common

	my %hash ;
	tie %hash, 'Config::Hierarchical::Tie::ReadOnly' => $config ;
	
	my $keys = join(', ', sort keys %hash) ;
	
	print "The config variables are: $keys\n" ;
	
	print "CC's value is '$hash{CC}'\n" ;
	
=end common

Would display:

=begin test

	generate_pod("\tThe config variables are: $keys\n") ;
	generate_pod("\tCC's value is '$hash{CC}'\n") ;
	generate_pod("\n") ;

=end test

Remember that the hash is read only. Trying to modify a variable is not allowed:

	$hash{CC} = 2 ;

Would generate this error:

=begin test

	dies_ok
		{
		$hash{CC} = 2 ;
		} 'setting a read only variable' ;
		
	$die =~ s/^/\t/gm ;
	generate_pod($die . "\n") ;

=end test

=head2 Copying data from another config

Use the code below to initialized a category from data copied from another category:

=begin common

	my $config_2 = new Config::Hierarchical
					(
					NAME => 'config initialized from another config',
					
					CATEGORY_NAMES         => ['PARENT', 'CURRENT'],
					DEFAULT_CATEGORY       => 'CURRENT',
					
					INITIAL_VALUES =>
						[
						# Initializing a category from another config
						map
							({
								{
								NAME     => $_->{NAME},
								VALUE    => $_->{VALUE}, 
								CATEGORY => 'PARENT',
								LOCK     => 1,
								HISTORY  => $config->GetHistory(NAME => $_->{NAME}),
								}
							} $config->GetKeyValueTuples()),
						
						{NAME => 'VALUE_IN_CURRENT_CATEGORY', VALUE => 1,},
						],
					) ;

=end common

And the config would be:

=begin test

	$hash = $config_2->GetHashRef() ;
	
	generate_pod(DumpTree($hash, 'Config 2 contains:', DISPLAY_ADDRESS => 0 , INDENTATION => "\t")) ;
	generate_pod("\n") ;

=end test


=head2 Aliasing other configurations

=begin common

	my $config_3 = new Config::Hierarchical
					(
					NAME => 'config with aliases',
					
					CATEGORY_NAMES         => ['PARENT', 'CURRENT'],
					DEFAULT_CATEGORY       => 'CURRENT',
					
					INITIAL_VALUES =>
						[
						{
						CATEGORY => 'PARENT',
						ALIAS    => $config,
						},
						
						# more initialization if necessary
						],
					) ;

=end common

=begin test

	my ($warnings_3, $die_3) ;
	$config_3->{INTERACTION}{WARN} = sub{$warnings_3 = join('', @_) ; use Carp ;carp $warnings_3; } ;
	$config_3->{INTERACTION}{DIE} = sub{$die_3 = join('', @_) ; use Carp ;croak $die_3} ; 

=end test

=begin common

	$config_3->Set(NAME => 'LD', VALUE => 'new LD') ;

=end common

Would generate this warning:

=begin test

	generate_pod("\t$warnings_3\n") ;

=end test

And the config would be:

=begin test

	$hash = $config_3->GetHashRef() ;
	
	generate_pod(DumpTree($hash, 'Config 3 contains:', DISPLAY_ADDRESS => 0 , INDENTATION => "\t")) ;
	generate_pod("\n") ;

=end test

=head3 History from aliased configuration

B<Config::Hierarchical> will, display aliased categories history.

=begin common

	print $config_3->GetHistoryDump(NAME => 'LD') ;

=end common

=begin test

	generate_pod($config_3->GetHistoryDump(NAME => 'LD', DATA_TREEDUMPER_OPTIONS => [INDENTATION => "\t"])) ;
	generate_pod("\n") ;

=end test

=cut


package Config::Hierarchical ;
use base Exporter ;

use strict;
use warnings ;

BEGIN 
{
use Exporter ();

use vars qw ($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 0.01;
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

#~ use Data::TreeDumper ;
use Carp ;
use Data::Compare;
use Sub::Install;

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

#-------------------------------------------------------------------------------

=head1 NAME

 Config::Hierarchical - Hierarchical configuration container

=head1 SYNOPSIS

  
  my $config = new Config::Hierarchical(); 
  
  # or
  
  my $config = new Config::Hierarchical
			(
			NAME                   => 'some_namespace',
			VERBOSE                => 0,
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES         => ['<CLI>', '<PBS>', 'PARENT', 'LOCAL', 'CURRENT'],
			DEFAULT_CATEGORY       => 'CURRENT',
				
			GET_CATEGORIES         => 
				{
				Inheritable => ['CLI', 'PBS', 'PARENT', 'CURRENT'],
				},
				
			INTERACTION            =>
				{
				INFO  => \&sub,
				WARN  => \&sub,
				DIE   => \&sub,
				DEBUG => \&sub,
				},
				
			INITIAL_VALUES         =>
				[
				[CATEGORY => 'CLI', NAME => 'CC', VALUE => 1,],
				[CATEGORY => 'CLI', NAME => 'LD', VALUE => 2, LOCK => 1],
				
				[CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 3, OVERRIDE => 1],
				[CATEGORY => 'CURRENT', NAME => 'AS', VALUE => 4,],
				} ,
			) ;
	
  $config->Set(NAME => 'CC', VALUE => 'gcc') ;
  $config->Set(NAME => 'CC', VALUE => 'gcc', CATEGORY => 'CLI') ;
  $config->Set(NAME => 'CC', VALUE => 'gcc', IGNORE_LOCK => 1) ;
  $config->Set(NAME => 'CC', VALUE => 'gcc', LOCK => 1) ;
  $config->Set(NAME => 'CC', VALUE => 'gcc', SILENT_OVERRIDE => 1) ;
  
  $config->SetMultiple
	(
	{FORCE_LOCK => 1}
	[NAME => 'CC', VALUE => 'gcc', SILENT_OVERRIDE => 1],
	[NAME => 'LD', VALUE => 'ld'],
	) ;
  
  $config->Set(CC => 'gcc') ;
  
  $value = $config->Get(NAME => 'CC') ;
  $value = $config->Get(NAME => 'NON_EXISTANT', SILENT_NOT_EXISTS => 1) ;
  
  @values = $config->GetMultiple(@config_variables_names) ;
  @values = $config->GetMultiple({SILENT_NOT_EXISTS => 1}, @config_variables_names) ;
  
  $hash_ref = $config->GetHashRef() ; # no warnings
  
  $config->GetInheritedConfigs() ;
  
  $config->SetDisableSilentOptions(1) ;
	
  $config->Lock(NAME => 'CC') ;
  $config->Unlock(NAME => 'CC', CATEGORY => 'CLI') ;
  $config->IsLocked(NAME => 'CC') ;
  
  $history = $config->GetHistory(NAME => 'CC') ;
  $dump = $config->GetDump() ;
  

=head1 DESCRIPTION

This module implements a configuration variable container. The container has multiple categories which are 
declared in decreasing priority order.

A variable can exist in multiple categories within the container. When queried for a variable, the container
will return the variable in the category with the highest priority.

When setting a variable, the container will display a warning message if it is set in a category with lower priority
than a category already containing the same variable.

Priority overriding is also possible.

=head1 DOCUMENTATION

I'll start by giving a usage example. In a build system, configuration variables can have different source.

=over 2

=item * the build tool

=item * the command line

=item * the parent build file (in a hierarchical build system)

=item * the current build file

=back

It is likely that a configuration variable set on the command line should be used regardless of a local
setting. Also, a configuration variable set by the build tool itself should constant.

Among the most difficult errors to find are configuration errors in complex build systems. Build tools
generally don't help much when variables are overridden. it's also difficult to get a variable's history.

This module provides the necessary functionality to handle most of the cases needed in a modern build system.

=head1 SUBROUTINES/METHODS

=cut


#-------------------------------------------------------------------------------

sub new
{

=head2 new

Create a Config::Hierarchical .  

  my $config = new Config::Hierarchical() ;
  
  my $config = new Config::Hierarchical(OPTIONS) ;  

=head3 Options

The options are named, the order is not important.

  my $config = new Config::Hierarchical(NAME => 'some_namespace', VERBOSE  => 1) ;

=over 2

=item *	NAME

A string that will be used in all the dumps and interaction with the user.

=item *	CATEGORY_NAMES

A list of category names. The first named category has the highest priority.
Only categories listed in this list can be manipulated. Using an unregistered
category in a L<Set> or L<Get> operation will generate an error.

  my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['CLI', '<PBS>', 'PARENT', 'CURRENT', 'LOCAL'],	
			DEFAULT_CATEGORY => 'CURRENT',
			) ;

A category can be B<protected> by enclosing its name in angle bracket, e.g. B<<PBS>>. Protected 
categories will not be overridden by lesser priority categories even if the OVERRIDE option is used.

If no category names are given, a default name B<CURRENT> will be used and L<DEFAULT_CATEGORY> will
be set accordingly.

=item * DEFAULT_CATEGORY

The name of the category used when L<Set> is called without a I<CATEGORY> argument.

If the B<CATEGORY_NAMES> list contains more than one entry, B<DEFAULT_CATEGORY> must be set or
an error will be generated.

=item * DISABLE_SILENT_OPTIONS

  my $config = new Config::Hierarchical(NAME => 'some_namespace',	DISABLE_SILENT_OPTIONS => 1) ;

When this option is set, B<SILENT_OVERRIDE> and B<SILENT_NOT_EXISTS> will be ignored and a
warning will be displayed.

=item * GET_CATEGORIES 

This option allows you to define functions that fetch variables in a specific category
list and in a specific order.

  my $config = new Config::Hierarchical
			(
			GET_CATEGORIES =>
				{
				CATEGORY_NAMES   => ['CLI', '<PBS>', 'PARENT', 'LOCAL', 'CURRENT'],	
				}
			Inheritable => ['CLI', '<PBS>', 'PARENT', 'CURRENT'],
			...
			) ;
			
  my $value = $config->GetInheritable(NAME => 'CC') ;
  my $hash_ref = $config->GetInheritableHashRef() ;
  

In the example above, the B<LOCAL> variables will not be returned by B<GetInherited>.

=item * VERBOSE

This module will display information about its actions when this option is set. See L<INTERACTION>.

=item * INTERACTION

Lets you define subs used to interact with the user.

  my $config = new Config::Hierarchical
			(
			INTERACTION      =>
				{
				INFO  => \&sub,
				WARN  => \&sub,
				DIE   => \&sub,
				DEBUG => \&sub,
				}
			) ;

=over 4

=item INFO

This sub will be used when displaying B<verbose> information.

=item WARN

This sub will be used when a warning is displayed. e.g. a configuration that is refused or an override.

=item DIE

Used when an error occurs. E.g. a locked variable is set.

=item DEBUG

If this option is set, Config::Hierarchical will call the sub before and after acting on the configuration.
This can act as a breakpoint in a debugger or allows you to pinpoint a configuration problem.

=back

The functions default to:

=over 2

=item * INFO => print

=item * WARN => Carp::carp

=item * DIE => Carp::confess

=back

=item * FILE and LINE

These will be used in the information message and the history information if set. If not set, the values
returned by I<caller> will be used. These options allow you to write wrapper functions that report the
callers location properly.


=item * INITIAL_VALUES

Lets you initialize the Config::Hierarchical object. Each entry will be passed to L<Set>.

  my $config = new Config::Hierarchical
			(
			...
			INITIAL_VALUES =>
				[
				[CATEGORY => 'CLI', NAME => 'CC', VALUE => 1],
				[CATEGORY => 'CLI', NAME => 'LD', VALUE => 2, LOCK => 1],
				
				[CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 3, OVERRIDE => 1],
				[CATEGORY => 'CURRENT', NAME => 'AS', VALUE => 4,],
				} ,
			) ;

=back

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;

confess 'Invalid constructor call!' unless defined $class ;

my $self = {} ;

my ($package, $file_name, $line) = caller() ;
bless $self, $class ;

$self->Setup($package, $file_name, $line, @setup_data) ;

return($self) ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 Setup

Helper sub called by new. This shall not be used directly.

=cut

my ($self, $package, $file_name, $line, @setup_data) = @_ ;

my %setup_data = @setup_data ;
if(exists $setup_data{CATEGORIES})
	{
	croak "Invalid argument 'CATEGORIES' at '$file_name, $line'! Did you mean 'CATEGORY_NAMES'?" ;
	}
undef %setup_data ;

%{$self} = 
	(
	NAME                   => "Anonymous created at $file_name:$line",
	CATEGORY_NAMES         => ['CURRENT'],
	DISABLE_SILENT_OPTIONS => 0,
		
	@setup_data,
	
	CATEGORIES             => {},
	TIME_STAMP             => 1,
	FILE                   => $file_name,
	LINE                   => $line,
	) ;

$self->{VALID_OPTIONS} = 
	{ 
	map{$_ => 1}
		qw( NAME VALUE
			CATEGORY CATEGORIES_TO_EXTRACT_FROM
			LOCK FORCE_LOCK
			OVERRIDE
			SILENT_NOT_EXISTS SILENT_OVERRIDE
			VERBOSE
			FILE LINE )
	} ;

my $location = "$self->{FILE}:$self->{LINE}" ;

$self->{INTERACTION}{INFO} ||= \&CORE::print ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::confess ;

# find the protected categories and removes the brackets from the name
$self->{PROTECTED_CATEGORIES} = 
	{
	map 
		{
		#~ /^<(.*)>$/xm ? ($1 => 1) : () ;
		if(/^<(.*)>$/xm) {$1 => 1} else {} ;
		} @{ $self->{CATEGORY_NAMES} }
	} ;
	
$self->{PROTECTED_CATEGORIES} = { map{ if(/^<(.*)>$/xm) {$1 => 1} else {} } @{ $self->{CATEGORY_NAMES} } } ;
	
for my $name (@{$self->{CATEGORY_NAMES}})
	{
	if($name =~ /^<(.*)>$/xm)
		{
		my $name_without_brackets = $1 ;
		
		if($name_without_brackets =~ /<|>/xm)
			{
			$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category name '$name_without_brackets' at '$location'!") ;
			}
		else
			{
			$name = $1 ;
			}
		}
	}

$self->{VALID_CATEGORIES} = { map{$_ => 1} @{$self->{CATEGORY_NAMES}}} ;

# set and check the default category
if(1 == @{$self->{CATEGORY_NAMES}})
	{
	$self->{DEFAULT_CATEGORY} = @{$self->{CATEGORY_NAMES}}[0] ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: No default category at '$location'!") unless exists $self->{DEFAULT_CATEGORY} ;
	}

unless(exists $self->{VALID_CATEGORIES}{$self->{DEFAULT_CATEGORY}})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid default category '$self->{DEFAULT_CATEGORY}' at at '$location'!") ;
	}

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}('Created ' . ref($self) . " '$self->{NAME}' at $location.\n") ;
	}

if(exists $self->{INITIAL_VALUES})
	{
	for my $element_data (@{$self->{INITIAL_VALUES}})
		{
		$self->Set(@{$element_data}, FILE => $self->{FILE}, LINE => $self->{LINE}) ;
		}
		
	delete $self->{INITIAL_VALUES} ;
	}
	
CreateCustomGetFunctions(keys %{ $self->{GET_CATEGORIES} }) ;

return(1) ;
}

sub CreateCustomGetFunctions
{
	
=head2 CreateCustomGetFunctions

Creates custom B<Get*> functions. This shall not be used directly.

=cut

my (@function_names) = @_ ;

for my $function_name (@function_names)
	{
	my $get_code = sub 
			{
			my($self, @arguments) = @_ ;
			
			return
				(
				$self->Get(@arguments, CATEGORIES_TO_EXTRACT_FROM => $self->{GET_CATEGORIES}{$function_name})
				) ;
			} ;
		
	Sub::Install::install_sub
		({
		code => $get_code,
		as   => 'Get' . $function_name
		});
		
	my $get_hash_ref_code = sub 
			{
			my($self, @arguments) = @_ ;
			
			return
				(
				$self->GetHashRef(CATEGORIES_TO_EXTRACT_FROM => $self->{GET_CATEGORIES}{$function_name})
				) ;
			} ;
		
	Sub::Install::install_sub
		({
		code => $get_hash_ref_code ,
		as   => 'Get' . $function_name . 'HashRef'
		});
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub CheckOptionNames
{

=head2 CheckOptionNames

Verifies the options passed to the members of this class. Calls B<{INTERACTION}{DIE}> in case
of error. This shall not be used directly.

=cut

my ($self, %options) = @_ ;

for my $option_name (keys %options)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'!") unless exists $self->{VALID_OPTIONS}{$option_name} ;
	}

if
	(
	   (defined $options{FILE} && ! defined $options{LINE})
	|| (!defined $options{FILE} && defined $options{LINE})
	)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Incomplete option FILE::LINE!") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub Set
{

=head2 Set

  my $config = new Config::Hierarchical() ;
  
  $config->Set(NAME => 'CC', VALUE => 'gcc') ;
  
  $config->Set
		(
		NAME => 'CC', VALUE => 'gcc',
		
		# options
		CATEGORY        => 'CLI',
		IGNORE_LOCK     => 1,
		LOCK            => 1,
		OVERRIDE        => 1,
		SILENT_OVERRIDE => 1,
		FILE            => 'some_file',
		LINE            => 1
		) ;

B<NAME> and B<VALUE> must be passed as arguments.

=head3 Options

=over 2

=item * CATEGORY

The name of the category where the variable resides. If no B<CATEGORY> is given, the default category is used.

=item * FORCE_LOCK

If a variable is locked, trying to set it will generate an error. It is possible to temporarily force
the lock with this option. A warning is displayed when a lock is forced.

=item * LOCK

Will lock the variable if set to 1, unlock if set to 0.

=item * OVERRIDE

This allows the variable in a category to override the variable in a category with higher priority.

=item * SILENT_OVERRIDE

Disables the warning displayed when overriding a variable.

=item * FILE and LINE

See B<FILE and LINE> in L<new>.

=back

=head3 History

B<Config::Hierarchical> will keep a history of all the setting you make. The history can be retrieved with L<GetHistory>.
The history is also part of the dump generated by L<GetDump>.

=cut

my ($self, %options) = @_ ;

$self->CheckOptionNames(%options) ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

#~ use Data::TreeDumper ;
#~ print DumpTree {Options => \%options, Self => $self} ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$options{CATEGORY}' at at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing value at '$location'!") unless defined $options{VALUE} ;

# inform of action if option set
if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Setting '$options{CATEGORY}::$options{NAME}' to '$options{VALUE}' at '$location'.\n") ;
	}

# run debug hook if any
if(defined $self->{INTERACTION}{DEBUG})
	{
	$self->{INTERACTION}{DEBUG}->
		(
		"Setting '$options{CATEGORY}::$options{NAME}' to '$options{VALUE}' at '$location'.",
		$self,
		\%options,
		) ;
	}
	
my $set_status = $self->CheckHigherPriorityCategories(\%options, $location) ;

$self->CheckAndSetVariable(\%options, $set_status, $location) ;

return(1) ;
}

sub CheckHigherPriorityCategories
{

=head2 CheckHigherPriorityCategories

Check if a config variable setting overrides a higher priority category. This shall not be used directly.

=cut

my ($self, $options, $location) = @_ ;

my $set_status = $EMPTY_STRING ;

my ($current_category_has_higher_priority, @higher_priority_categories) = (0, ()) ;

for my $category (@{$self->{CATEGORY_NAMES}})
	{
	if($category eq $options->{CATEGORY})
		{
		last ;
		}
	else
		{
		push @higher_priority_categories, $category ;
		}
	}
	
for my $category (reverse @higher_priority_categories)
	{
	# categories are travesed in reverse order as it is not allowed to override across a protected category
	
	# check all higher priority categories and warn of override
	
	if
		(
		exists $self->{CATEGORIES}{$category}{$options->{NAME}}
		&& ! Compare
			(
			$self->{CATEGORIES}{$category}{$options->{NAME}}{VALUE},
			$options->{VALUE}
			)
		)
		{
		if(exists $self->{PROTECTED_CATEGORIES}{$category})
			{
			$self->{INTERACTION}{WARN}->("$self->{NAME}: Setting '$options->{CATEGORY}::$options->{NAME}'. Precedence will be given to '${category}::$options->{NAME}' (protected category) at '$location'.\n") ;
			$set_status .= "Set: Precedence will be given to config in protected category '$category'.\n" ;
			
			last; # can't override over a protected category
			}
		else
			{
			my $no_silent_override = (! ($options->{SILENT_OVERRIDE} || $self->{DISABLE_SILENT_OPTIONS})) ;
			
			if($options->{OVERRIDE})
				{
				if($no_silent_override)
					{
					$self->{INTERACTION}{WARN}->("$self->{NAME}: Setting '$options->{CATEGORY}::$options->{NAME}'. Overriding config '$options->{NAME}' in category '$category' at '$location'.\n") ;
					}
					
				$set_status .= "Set: Overriding config in category '$category'.\n" ;
				
				$self->{CATEGORIES}{$category}{$options->{NAME}}{OVERRIDDEN} = $location ;
				}
			else
				{
				if($no_silent_override)
					{
					$self->{INTERACTION}{WARN}->("$self->{NAME}: Setting '$options->{CATEGORY}::$options->{NAME}'. Precedence will be given to '${category}::$options->{NAME}' at '$location'.\n") ;
					}
				
				$set_status .= "Set: Precedence will be given to config in category '$category'.\n" ;
				}
			}
		}
	else
		{
		# doesn't exist or exists and has the same value
		if($options->{OVERRIDE})
			{
			$self->{CATEGORIES}{$category}{$options->{NAME}}{OVERRIDDEN} = $location ;
			}
		}
	}
	
return($set_status) ;
}

sub CheckAndSetVariable
{

=head2 CheckAndSetVariable

Set the variable in its category, verify lock, etc.. This shall not be used directly.

=cut

my($self, $options, $set_status, $location) = @_ ;

my $config_variable ;
my $config_variable_exists = exists $self->{CATEGORIES}{$options->{CATEGORY}}{$options->{NAME}} ;

unless($config_variable_exists)
	{
	#~ didn't exist before this call, create and set
	$config_variable = $self->{CATEGORIES}{$options->{CATEGORY}}{$options->{NAME}} = {} ;
	
	$config_variable->{VALUE} = $options->{VALUE} ;
	$config_variable->{TIME_STAMP} = $self->{TIME_STAMP} ;
	
	$set_status .= "Set: Success, did not exist\n" ;
	}
else
	{
	$config_variable = $self->{CATEGORIES}{$options->{CATEGORY}}{$options->{NAME}} ;
	 
	if(exists $config_variable->{OVERRIDE} && !$options->{OVERRIDE})
		{
		$set_status .= "Set: Failed, variable was is overridden and OVERRIDE option is not set\n" ;
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Variable '$options->{CATEGORY}::$options->{NAME}' was overridden at '$config_variable->{OVERRIDE}' and OVERRIDE option is not set at '$location'.\n") ;
		}
		
	if(! Compare($config_variable->{VALUE}, $options->{VALUE}))
		{
		# not the same value
		
		unless(exists $config_variable->{LOCKED})
			{
			#~ Not locked, set
			$config_variable->{VALUE} = $options->{VALUE} ;
			$config_variable->{TIME_STAMP} = $self->{TIME_STAMP} ;
			
			$set_status .= "Set: Success\n" ;
			}
		else
			{
			if($options->{FORCE_LOCK})
				{
				$config_variable->{VALUE} = $options->{VALUE} ;
				$config_variable->{TIME_STAMP} = $self->{TIME_STAMP} ;
				
				$set_status .= "Set: Success, forced lock\n" ;
				$self->{INTERACTION}{WARN}->("$self->{NAME}: Forcing locked variable '$options->{CATEGORY}::$options->{NAME}' at '$location'.\n") ;
				}
			else 
				{
				$set_status .= "Set: Failed, variable was locked\n" ;
				$self->{INTERACTION}{DIE}->("$self->{NAME}: Variable '$options->{CATEGORY}::$options->{NAME}' was locked and couldn't be set at '$location'.\n") ;
				}
			}
		}
	#else
		# same value, nothing to do with the value. locking, override are handled below
	}

#~ set lock state
if(exists $options->{LOCK})
	{
	if($options->{LOCK})
		{
		$config_variable->{LOCKED} = $location  ;
		}
	else
		{
		delete $config_variable->{LOCKED} ;
		}
	}
	
$config_variable->{OVERRIDE} = $location if(exists $options->{OVERRIDE}) ;

# update history
my $options_to_remember = { %{$options} } ; # keep local copy
delete $options_to_remember->{CATEGORY} ;
delete $options_to_remember->{NAME} ;
$options_to_remember->{STATUS}     = $set_status ;
$options_to_remember->{TIME_STAMP} = $self->{TIME_STAMP} ;
$self->{TIME_STAMP}++ ;

push @{$config_variable->{HISTORY}}, $options_to_remember ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub Get
{

=head2 Get

  my $config = new Config::Hierarchical(INITIAL_VALUES => [[NAME => 'CC', VALUE => 'gcc']]) ;
  
  my $cc = $config->Get(NAME => 'CC') ;
  my $ld = $config->Get(NAME => 'LD', SILENT_NOT_EXISTS => 1) ;


Returns the value associated with the variable passed as argument. If more than one category contains the variable,
the variable from the category with the highest priority, which is not overridden, will be used.

This function verifies its calling context and will generate a warning if it is called in void or array context.
Use L<GetMultiple> in an array context.

If the variable doesn't exist in the container, a warning is displayed and B<undef> is returned.

=head3 Options

=over 2

=item * SILENT_NOT_EXISTS

Setting this option will disable the warning generated when the variable doesn't exist in the container.

=back

=cut

my ($self, %options) = @_ ;

$self->CheckOptionNames(%options) ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}
my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

#~ use Data::TreeDumper ;
#~ print DumpTree {Options => \%options, Self => $self} ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at $location!") unless defined $options{NAME} ;

# inform of action if option set
if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Getting '$options{NAME}' $location.\n") ;
	}
	
if(defined wantarray)
	{
	if(wantarray)
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: Getting '$options{NAME}' in array context at '$location'!\n") ;
		}
	}
else
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: Getting '$options{NAME}' in void context at '$location'!\n") ;
	}

# run debug hook if any
if(defined $self->{INTERACTION}{DEBUG})
	{
	$self->{INTERACTION}{DEBUG}->
		(
		"Getting '$options{CATEGORY}::$options{NAME}' at $location.",
		$self,
		\%options,
		) ;
	}
	
my @categories_to_extract_from ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	@categories_to_extract_from = @{$options{CATEGORIES_TO_EXTRACT_FROM}} ;
	}
else
	{
	@categories_to_extract_from = @{$self->{CATEGORY_NAMES}} ;
	}
	
my ($value_not_found, $value) = (1, undef) ;

for my $category (@categories_to_extract_from)
	{
	if(exists $self->{CATEGORIES}{$category}{$options{NAME}})
		{
		# remember the value in case the overriding category is not in the list of categories to 
		# extract from
		($value_not_found, $value) = (0, $self->{CATEGORIES}{$category}{$options{NAME}}{VALUE}) ;
		
		# check if lower priority category did an override
		if(exists $self->{CATEGORIES}{$category}{$options{NAME}}{OVERRIDDEN})
			{
			# get value from overriding category
			}
		else
			{
			# stop searching
			last ;
			}
		}
	}
	
if($value_not_found)
	{
	if(! ($options{SILENT_NOT_EXISTS} ||  $self->{DISABLE_SILENT_OPTIONS}))
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: Variable '$options{NAME}' doesn't exist in categories [@categories_to_extract_from]at '$location'. Returning undef!\n") ;
		}
	}

return($value) ;
}

#-------------------------------------------------------------------------------

sub SetMultiple
{
	
=head2 SetMultiple

  $config->SetMultiple
	(
	{FORCE_LOCK => 1},
	
	[NAME => 'CC', VALUE => 'gcc', SILENT_OVERRIDE => 1],
	[NAME => 'LD', VALUE => 'ld'],
	) ;

If the first argument is a hash reference, the elements of the hash will be used for each element to set.

see L<Set>.

=cut

my ($self, $options, @sets) = @_ ;

my ($package, $file_name, $line) = caller() ;

if('HASH' eq ref $options)
	{
	unless(defined $options->{FILE})
		{
		$options->{FILE} = $file_name ;
		$options->{LINE} = $line ;
		}
		
	}
else
	{
	unshift @sets, $options if defined $options ; 
	
	$options = {FILE => $file_name, LINE => $line} ;
	}
	
my $location = "$options->{FILE}:$options->{LINE}" ;

for my $set (@sets)
	{
	unless( 'ARRAY' eq ref $set)
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: 'SetMultiple' must be passed array reference at '$location'!\n") ;
		}
	
	$self->Set(%{$options}, @{$set}) ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub GetMultiple
{

=head2 GetMultiple

  my $config = new Config::Hierarchical(INITIAL_VALUES => [[NAME => 'CC', VALUE => 'gcc']]) ;
  
  my @values = $config->GetMultiple('CC') ;
  
  my @other_values = $config->GetMultiple
			(
			{SILENT_NOT_EXISTS => 1},
			'CC',
			'AR'
			) ;


If the first argument is a hash reference, the elements of the hash will be used for each element to set.

see L<Get>.

=cut

my ($self, $options, @names) = @_ ;

my ($package, $file_name, $line) = caller() ;

if('HASH' eq ref $options)
	{
	unless(defined $options->{FILE})
		{
		$options->{FILE} = $file_name ;
		$options->{LINE} = $line ;
		}
		
	}
else
	{
	unshift @names, $options if defined $options ; 
	
	$options = {FILE => $file_name, LINE => $line} ;
	}
	
my $location = "$options->{FILE}:$options->{LINE}" ;

if(defined wantarray)
	{
	unless(wantarray)
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetMultiple' is not called in scalar context at '$location'!\n") ;
		}
	}
else
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetMultiple' called in void context at '$location'!\n") ;
	}

my @values ;
for my $name (@names)
	{
	unless( $EMPTY_STRING eq ref $name)
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: 'GetMultiple' must be passed scalars at '$location'!\n") ;
		}
	
	push @values, scalar($self->Get(%{$options}, NAME => $name)) ;
	}
	
return(@values) ;
}

#-------------------------------------------------------------------------------

sub GetHashRef
{

=head2 GetHashRef

  my $hash_ref = $config->GetHash() ;

Returns a hash reference containing all the elements in the container. The elements value are extracted with the rules
used in L<Get>.

This function will generate an error if:

=over 2

=item any argument is passed to it

=item it is called in void context

=item it is called in array context

=back

=cut

my ($self, @options) = @_ ;
my ($package, $file_name, $line) = caller() ;
my (%options) ;

if(@options)
	{
	if(@options == 2)
		{
		# Note: CATEGORIES_TO_EXTRACT_FROM is not publicly documented
		
		if($options[0] eq 'CATEGORIES_TO_EXTRACT_FROM')
			{
			%options = @options ;
			}
		else
			{
			$self->{INTERACTION}{DIE}->("$self->{NAME}: 'GetHashRef' doesn't take arguments at '$file_name:$line'!\n") ;
			}
		}
	else
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: 'GetHashRef' doesn't take arguments at '$file_name:$line'!\n") ;
		}
	}
#else
	# OK no options passed to function

if(defined wantarray)
	{
	if(wantarray)
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetHashRef' is called in array context at '$file_name:$line'!\n") ;
		}
	}
else
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetHashRef' called in void context at '$file_name:$line'!\n") ;
	}
	
my (%variables, @categories_to_extract_from) ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	@categories_to_extract_from = @{$options{CATEGORIES_TO_EXTRACT_FROM}} ;
	}
else
	{
	@categories_to_extract_from = @{$self->{CATEGORY_NAMES}} ;
	}
	
return 
	{
	map
		{
		$_ => scalar($self->Get(NAME => $_, CATEGORIES_TO_EXTRACT_FROM => [@categories_to_extract_from], FILE => $file_name, LINE => $line))
		} map
			{
			keys %{$self->{CATEGORIES}{$_}} ;
			}  @categories_to_extract_from
	} ;
}


#-------------------------------------------------------------------------------

sub SetDisableSilentOptions
{

=head2 SetDisableSilentOptions

  $config->SetDisableSilentOptions(1) ;
  $config->SetDisableSilentOptions(0) ;

When set, warning messages will be displayed regardless of local warning disabling options,
i.e. B<SILENT_OVERRIDE> and B<SILENT_NOT_EXIST>.

This is useful when debugging your configuration as it forces all the warning to be displayed.

=cut

my ($self, $silent) = @_ ;

$self->{DISABLE_SILENT_OPTIONS} = $silent ;

if($self->{VERBOSE})
	{
	my ($package, $file_name, $line) = caller() ;
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Setting 'DISABLE_SILENT_OPTIONS' to '$silent' at '$file_name:$line'.\n") ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------
	
sub Lock
{

=head2 Lock

  $config->Lock(NAME => 'CC') ;
  $config->Lock(NAME => 'CC', CATEGORY => 'PARENT') ;

Locks a variable in the default category or an explicit category. A locked variable can not be set.
An attempt to set a locked variable will generate an error. To set a locked variable, B<FORCE_LOCK>
can be used. B<FORCE_LOCK> usually pinpoints a problem in your configuration.

An error is generated if you try to lock a variable that doesn't exist.

See L<Set>.

=cut

my ($self, %options) = @_ ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

$self->CheckOptionNames(%options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Locking '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}

if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	my $config_variable = $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}} ;
	
	$config_variable->{LOCKED} = $location ;
	
	# update history
	my $options_to_remember = {%options} ;
	delete $options_to_remember->{CATEGORY} ;
	delete $options_to_remember->{NAME} ;
	$options_to_remember->{STATUS}     = 'Lock: success' ;
	$options_to_remember->{TIME_STAMP} = $self->{TIME_STAMP} ;
	$self->{TIME_STAMP}++ ;

	push @{$config_variable->{HISTORY}}, $options_to_remember ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Locking unexisting '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub Unlock
{

=head2 Unlock

  $config->Unlock(NAME => 'CC') ;
  $config->Unlock(NAME => 'CC', CATEGORY => 'PARENT') ;

See L<Lock>.

=cut

my ($self, %options) = @_ ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

$self->CheckOptionNames(%options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Unlocking '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}
	
if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	my $config_variable = $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}} ;
	
	delete $config_variable->{LOCKED} ;
	
	# update history
	my $options_to_remember = {%options} ;
	delete $options_to_remember->{CATEGORY} ;
	delete $options_to_remember->{NAME} ;
	$options_to_remember->{STATUS}     = 'Unlock: success' ;
	$options_to_remember->{TIME_STAMP} = $self->{TIME_STAMP} ;
	$self->{TIME_STAMP}++ ;

	push @{$config_variable->{HISTORY}}, $options_to_remember ;
	}

return(1) ;
}
  
#-------------------------------------------------------------------------------

sub IsLocked
{

=head2 IsLocked

  $config->IsLocked(NAME => 'CC') ;
  $config->IsLocked(NAME => 'CC', CATEGORY => 'PARENT') ;

Query the lock state of a variable. Querying the lock state of a variable that doesn't exist does not generate an error.

=cut

my ($self, %options) = @_ ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

$self->CheckOptionNames(%options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Checking Lock of '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}
	
my $locked = undef ;

if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}}{LOCKED})
		{
		$locked = 1 ;
		}
	else
		{
		$locked = 0 ;
		}
	}

return($locked) ;
}
  
#-------------------------------------------------------------------------------

sub Exists
{

=head2 Exists

  $config->Exists(NAME => 'CC') ;

Returns B<true> if the variable exist, B<false> otherwise. All the categories are checked.

=cut

my ($self, %options) = @_ ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$self->CheckOptionNames(%options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: 'CATEGORY' not used at '$location'!") if exists $options{CATEGORY} ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Checking Existance of '$options{NAME}' at '$location'.\n") ;
	}
	
my @categories_to_extract_from ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	if(defined $options{CATEGORIES_TO_EXTRACT_FROM})
		{
		@categories_to_extract_from = @{$options{CATEGORIES_TO_EXTRACT_FROM}} ;
		}
	else
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: undefined category 'CATEGORIES_TO_EXTRACT_FROM' at '$location'!") ;
		}
	}
else
	{
	@categories_to_extract_from = @{$self->{CATEGORY_NAMES}} ;
	}
	
my ($exists) = (0) ;

for my $category (@categories_to_extract_from)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$category' at '$location'!") unless exists $self->{VALID_CATEGORIES}{$category} ;
		
	if(exists $self->{CATEGORIES}{$category}{$options{NAME}})
		{
		$exists++ ;
		}
	}

return($exists) ;
}
  
#-------------------------------------------------------------------------------
  
sub GetHistory
{

=head2 GetHistory

  $history = $config->GetHistory(NAME => 'CC') ;
  $history = $config->GetHistory(NAME => 'CC', CATEGORY => 'CLI') ;

Returns a reference to the variable's history if any. Returns an error string if no history is found.

=cut

my ($self, %options) = @_ ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

$self->CheckOptionNames(%options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;

my $history = $EMPTY_STRING ;

if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	$history = $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}}{HISTORY} ;
	}
else
	{
	$history = "$self->{NAME}: Variable '$options{CATEGORY}::$options{NAME}' doesn't exist!" ;
	}
	
return($history) ;
}

#-------------------------------------------------------------------------------

sub GetDump
{

=head2 GetDump

  $dump = $config->GetDump() ;
  $dump = $config->GetDump(DATA_TREEDUMPER_OPTIONS) ;

Returns a dump generated by B<Data::TreeDumper::DumpTree>. The arguments are forwarded to the dumper.

See L<Data::TreeDumper>.

=cut

my ($self, @data_treedumper_options) = @_ ;

my ($package, $file_name, $line) = caller() ;

use Data::TreeDumper ;
return(DumpTree($self, $self->{NAME}, @data_treedumper_options)) ;
}
  
#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

Copyright 2006-2006 Khemir Nadim. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Hierarchical

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Hierarchical>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-config-hierarchical@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Hierarchical>

=back

=head1 SEE ALSO


=cut

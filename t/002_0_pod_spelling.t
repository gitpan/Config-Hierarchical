# pod and pod_coverage pod_spelling test

use strict ;
use warnings ;

use Test::Spelling;

add_stopwords
	(
	qw(
		AddValidator
		AddValidators
		AddVariableValidator
		AnnoCPAN
		CPAN
		Category
		CheckHigherPriorityCategories
		CheckLowerPriorityCategories
		CheckAndSetVariable
		CreateCustomGetFunctions
		CheckOptionNames
		GetDump
		GetHashRef
		GetHistory
		GetInheritable
		GetMultiple
		IsLocked
		OverrideVariable
		SetDisableSilentOptions
		SetMultiple
		SetDisplayExplicitCategoryWarningOption
		
		VALIDATORS
		PositiveValueValidator
		SecondValidator
		Validators
		validator
		validators
		
		Nadim
		nadim
		Khemir
		khemir
		)
	) ;
	
all_pod_files_spelling_ok();

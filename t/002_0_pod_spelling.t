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
		CheckSetArguments
		CheckVariableInCategory
		CreateCustomGetFunctions
		CheckOptionNames
		GetAttribute
		GetDump
		GetHashRef
		GetHistory
		GetHistoryDump
		GetInformation
		GetVariableHistory
		GetInheritable
		GetKeys
		GetKeyValueTuples
		GetMultiple
		IsCategoryLocked
		IsLocked
		LockCategories
		OverrideVariable
		SetAlias
		SetAttribute
		SetDisableSilentOptions
		SetDisplayExplicitCategoryWarningOption
		SetMultiple
		SetupCategories
		UnlockCategories
		
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
		
		FIRSTKEY
		NEXTKEY
		TIEHASH
		
		DumpConfigHierarchicalDelta
		GetConfigDelta
		GetConfigHierarchicalDelta
		lhs
		rhs
		)
	) ;
	
all_pod_files_spelling_ok();

# pod and pod_coverage pod_spelling test

use strict ;
use warnings ;

use Test::Spelling;

add_stopwords
	(
	qw(
		AnnoCPAN
		CPAN
		Category
		CheckHigherPriorityCategories
		CheckAndSetVariable
		CreateCustomGetFunctions
		CheckOptionNames
		GetDump
		GetHashRef
		GetHistory
		GetInherited
		GetMultiple
		IsLocked
		SetDisableSilentOptions
		SetMultiple
		
		Nadim
		nadim
		Khemir
		khemir
		)
	) ;
	
all_pod_files_spelling_ok();

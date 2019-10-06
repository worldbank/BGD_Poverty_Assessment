/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                                BANGLADESH CONSUMPTION AGGREGATES 2016                            **
**                                                                                                  **
** COUNTRY			BANGLADESH
** COUNTRY ISO CODE	BGD
** YEAR				2016
** SURVEY NAME		HOUSEHOLD INCOME AND EXPENDITURE SURVEY 		
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS
** Modified	        12/22/2017                                                                                               
******************************************************************************************************
*****************************************************************************************************/
/*This do file creates several tables in excel with all the poverty numbers */
/*****************************************************************************************************
*                                                                                                    *
                                   INITIAL COMMANDS
*                                                                                                    *
*****************************************************************************************************/


	** INITIAL COMMANDS
		clear
		set more off
		set max_memory ., perm
		tempfile temp temp1
	
	
	
/*****************************************************************************************************
*                                                                                                    *
                                    AVERAGE PER CAPITA EXPENDITURES
*                                                                                                    *
*****************************************************************************************************/	
	
	use "$output/poverty_indicators2016_detailed", clear
	cap erase `temp'
	
	*Per capita expenditures, use population weights
	svyset psu [pweight=popwgt], strata(stratum) 
	drop zila_name 
		
	egen divur=concat(division_code urbrural)
	destring divur, replace


	local cons = "pcexp pcfexp pcnfexp rpcexp rpcfe rpcnfe"
	foreach k of local cons {
		
		*National		
		qui svy: mean `k' if pcexp!=.
		preserve
		qui gen vars="`k' - National Annual"
		mat B=e(b)
		mat V=e(V)
		gen average   =B[1,1]
		gen serror  =V[1,1]^0.5
		gen lb=average-1.96*serror
		gen ub=average+1.96*serror
		mat drop B V		
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		
	
		* Rural and urban
		qui levelsof urbrural, local(area)
		foreach s of local area {
		qui svy: mean `k' if pcexp!=., over(urbrural)
		preserve
		qui gen vars="`k' - Urbrur `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`s']
			gen serror  =V[`s',`s']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		
		* Division		
		qui levelsof division_code, local(div)
		local i=0
		foreach s of local div {
		qui svy: mean `k' if pcexp!=., over(division_code)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Division `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		* Division - rural and urban
		qui levelsof divur, local(divur)
		local i=0
		foreach s of local divur {
		qui svy: mean `k' if pcexp!=., over(divur)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Division `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		* Zilas
		qui levelsof zila_code, local(zila)
		local i=0
		foreach s of local zila {
		qui svy: mean `k' if pcexp!=., over(zila_code)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Zila `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
     }

	use `temp', clear
	format average serror lb ub %9.4f
	gen n=_n
	gsort - n
	drop n
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("Average percapita cons") sheetreplace
	

/*****************************************************************************************************
*                                                                                                    *
                                    AVERAGE HOUSEHOLD EXPENDITURES
*                                                                                                    *
*****************************************************************************************************/	
	
	*Household expenditures, use household weights
	use "$output/poverty_indicators2016_detailed", clear
	cap erase `temp'
	
	*Per capita expenditures, use population weights
	svyset psu [pweight=hhwgt], strata(stratum) 
	drop zila_name 
		
	egen divur=concat(division_code urbrural)
	destring divur, replace


	local cons = "consexp2 fexp nfexp2 rhexp rhfe rhnfe"
	foreach k of local cons {
		
		*National		
		qui svy: mean `k' if pcexp!=.
		preserve
		qui gen vars="`k' - National Annual"
		mat B=e(b)
		mat V=e(V)
		gen average   =B[1,1]
		gen serror  =V[1,1]^0.5
		gen lb=average-1.96*serror
		gen ub=average+1.96*serror
		mat drop B V		
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		
	
		* Rural and urban
		qui levelsof urbrural, local(area)
		foreach s of local area {
		qui svy: mean `k' if pcexp!=., over(urbrural)
		preserve
		qui gen vars="`k' - Urbrur `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`s']
			gen serror  =V[`s',`s']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		
		* Division		
		qui levelsof division_code, local(div)
		local i=0
		foreach s of local div {
		qui svy: mean `k' if pcexp!=., over(division_code)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Division `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		* Division - rural and urban
		qui levelsof divur, local(divur)
		local i=0
		foreach s of local divur {
		qui svy: mean `k' if pcexp!=., over(divur)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Division `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		* Zilas
		qui levelsof zila_code, local(zila)
		local i=0
		foreach s of local zila {
		qui svy: mean `k' if pcexp!=., over(zila_code)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Zila `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
     }

	use `temp', clear
	format average serror lb ub %9.4f
	gen n=_n
	gsort - n
	drop n
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("Average household cons") sheetreplace


	
/*****************************************************************************************************
*                                                                                                    *
                         POVERTY LINES, TORNQVIST INDEX AND COMPOSITE PRICE INDEX
*                                                                                                    *
*****************************************************************************************************/


	use "$output/poverty_indicators2016_detailed", clear
	
	*Quarters
	preserve
	collapse (mean) zl16quarters zu16quarters ttquarters indexquarters, by(stratum quarter)
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("Lines quarters") sheetreplace
	restore
	
	*Annual
	preserve
	collapse (mean) zl16 zu16 tt index, by(stratum)
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("Lines annual") sheetreplace
	restore
	
	
	
	
/*****************************************************************************************************
*                                                                                                    *
                          ANNUAL POVERTY RATES AND PER CAPITA EXPENDITURE
*                                                                                                    *
*****************************************************************************************************/
	
	*****************************
	* FGT 0, 1 AND 2
	*****************************
	
	use "$output/poverty_indicators2016_detailed", clear
	cap erase `temp'
	svyset psu [pweight=popwgt], strata(stratum) 
	
		
	egen divur=concat(division_code urbrural)
	destring divur, replace


	local rate = "fgt0_upper fgt1_upper fgt2_upper fgt0_lower fgt1_lower fgt2_lower rpcexp pcexp pcfexp pcnfexp "
	foreach k of local rate {
		
		*National		
		svy: mean `k' if pcexp!=.
		preserve
		qui gen vars="`k' - National Annual"
		mat B=e(b)
		mat V=e(V)
		gen average   =B[1,1]
		gen serror  =V[1,1]^0.5
		gen lb=average-1.96*serror
		gen ub=average+1.96*serror
		mat drop B V		
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore

		* Rural and urban
		qui levelsof urbrural, local(area)
		foreach s of local area {
		qui svy: mean `k' if pcexp!=., over(urbrural)
		preserve
		qui gen vars="`k'- Urbrur `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`s']
			gen serror  =V[`s',`s']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		
		* Division		
		qui levelsof division_code, local(div)
		local i=0
		foreach s of local div {
		qui svy: mean `k' if pcexp!=., over(division_code)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Division `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		* Division - rural and urban
		qui levelsof divur, local(divur)
		local i=0
		foreach s of local divur {
		qui svy: mean `k' if pcexp!=., over(divur)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Division `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		* Zilas
		qui levelsof zila_code, local(zila)
		local i=0
		foreach s of local zila {
		qui svy: mean `k' if pcexp!=., over(zila_code)
		local i=`i'+1
		preserve
		qui gen vars="`k'- Zila `s'"
			mat B=e(b)
			mat V=e(V)
			gen average   =B[1,`i']
			gen serror  =V[`i',`i']^0.5
			gen lb  =average-1.96*serror
			gen ub  =average+1.96*serror
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
}

	use `temp', clear
	format average serror lb ub %9.4f
	gen n=_n
	gsort - n
	drop n
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("annual FGT and expenditure pc b") sheetreplace


	
/*****************************************************************************************************
*                                                                                                    *
                                    GINI PER CAPITA EXPENDITURE
*                                                                                                    *
*****************************************************************************************************/	
	
	
	use "$output/poverty_indicators2016_detailed", clear
	cap erase `temp'
	
	local rate = "pcexp rpcexp pcexpend rpcexpend"
	foreach k of local rate {
		
	    *National
	    fastgini `k' [w=popwgt] if rpcexp!=.
	    preserve
	    qui gen vars="National Annual `k'"
	    gen gini=r(gini)
	    keep vars gini
	    keep if _n==1
	    cap append using `temp'
	    save `temp', replace
	    restore
	
	
	    qui levelsof urbrural, local(area)
	    foreach s of local area {
		fastgini `k' [w=popwgt] if rpcexp!=. & urbrural==`s'
		preserve
		qui gen vars="Urbrur `s' `k'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
	    }
		
		* Division		
		qui levelsof division_code, local(div)
		foreach d of local div {
        fastgini `k' [w=popwgt] if division_code==`d'
		preserve
		qui gen vars="Division `d' `k'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		
		
		* Division - rural and urban
	qui levelsof urbrural, local(area)
	qui levelsof division_code, local(div)
		foreach s of local area {
		foreach d of local div {
		fastgini `k' [w=popwgt] if rpcexp!=. & urbrural==`s' & division_code==`d'
		preserve
		qui gen vars="Urbrural `s' Division `d' `k'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
	}
	}
	
	    * Zilas
	qui levelsof zila_code, local(zila)
		foreach s of local zila {
		fastgini `k' [w=popwgt] if rpcexp!=. & zila_code==`s'
		preserve
		qui gen vars="Zila `s' `k'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
	}
	}
	
	use `temp', clear
	gen n=_n
	gsort - n
	drop n
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("Gini annual perca b") sheetreplace
	
	
/*****************************************************************************************************
*                                                                                                    *
                                    GINI HOUSEHOLD EXPENDITURE
*                                                                                                    *
*****************************************************************************************************/	
	
	
	use "$output/poverty_indicators2016_detailed", clear
	cap erase `temp'
	
	local rate = "consexp2 rhexp hexpend rhexpend"
	foreach k of local rate {
		
	    *National
	    fastgini `k' [w=hhwgt] if rpcexp!=.
	    preserve
	    qui gen vars="National Annual `k'"
	    gen gini=r(gini)
	    keep vars gini
	    keep if _n==1
	    cap append using `temp'
	    save `temp', replace	
	    restore
	
	
	    qui levelsof urbrural, local(area)
	    foreach s of local area {
		fastgini `k' [w=hhwgt] if rpcexp!=. & urbrural==`s'
		preserve
		qui gen vars="Urbrur `s' `k'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
	    }
		
		* Division		
		qui levelsof division_code, local(div)
		foreach d of local div {
        fastgini `k' [w=hhwgt] if rpcexp!=. & division_code==`d'
		preserve
		qui gen vars="Division `d' `k'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
		}
		
		
		
		* Division - rural and urban
	qui levelsof urbrural, local(area)
	qui levelsof division_code, local(div)
		foreach s of local area {
		foreach d of local div {
		fastgini `k' [w=hhwgt] if rpcexp!=. & urbrural==`s' & division_code==`d'
		preserve
		qui gen vars="Urbrural `s' Division `d' `k'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
	}
	}
	
	    * Zilas
	qui levelsof zila_code, local(zila)
		foreach s of local zila {
		fastgini `k' [w=hhwgt] if rpcexp!=. & zila_code==`s'
		preserve
		qui gen vars="Zila `s' `k'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp'
		save `temp', replace
		restore
	}
	}
	
	use `temp', clear
	gen n=_n
	gsort - n
	drop n
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("Gini annual hh b") sheetreplace
	

	
/*****************************************************************************************************
*                                                                                                    *
                                    QUARTERLY POVERTY RATES
*                                                                                                    *
*****************************************************************************************************/
	
	
	use "$output/poverty_indicators2016_detailed", clear
	
		
	svyset psu [pweight=popwgt], strata(stratum16) 

	local rate = "fgt0q_upper fgt1q_upper fgt2q_upper fgt0q_lower fgt1q_lower fgt2q_lower pcexp pcfexp pcnfexp rpcexp"
	foreach k of local rate {
		
		qui levelsof quarter, local(quarter)
		foreach s of local quarter {
		svy: mean `k' if pcexp!=., over (quarter)
		preserve
		qui gen vars="`k' -Quarter `s'"
		mat B=e(b)
		mat V=e(V)
		gen average   =B[1,`s']
		gen serror  =V[`s',`s']^0.5
		gen lb=average-1.96*serror
		gen ub=average+1.96*serror
		mat drop B V		
		keep vars average serror lb ub
		keep if _n==1
		cap append using `temp1'
		save `temp1', replace
		restore
		}
		
}
			
	use `temp1', clear
	gen n=_n
	gsort - n
	drop n
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("FGTs and exp per quarter") sheetreplace
	erase `temp1'
	
	
	* Gini
	use "$output/poverty_indicators2016_detailed", clear
	
	forvalues i=1(1)4 {
		fastgini rpcexp [w=popwgt] if rpcexp!=. & quarter==`i'
		preserve
		qui gen vars="Gini - Quarter `i'"
		gen gini=r(gini)
		keep vars gini
		keep if _n==1
		cap append using `temp1'
		save `temp1', replace
		restore
	}
	use `temp1', clear
	export excel using "$output/results2016.xlsx", firstrow(var) sheet("Gini quarters") sheetreplace
	erase `temp1'
	exit
	
	


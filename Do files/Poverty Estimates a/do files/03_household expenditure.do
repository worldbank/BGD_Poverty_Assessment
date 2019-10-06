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
** Modified	        12/19/2017                                                                                               
******************************************************************************************************
*****************************************************************************************************/
/*This do file computes food and non-food household expenditure from various files, and then aggregates 
the totals */
/*****************************************************************************************************
*                                                                                                    *
                                   INITIAL COMMANDS
*                                                                                                    *
*****************************************************************************************************/


** INITIAL COMMANDS
	clear
    set more off
    set max_memory ., perm
	
/*****************************************************************************************************
*                                                                                                    *
                                          FOOD EXPENDITURE
*                                                                                                    *
*****************************************************************************************************/

	** Daily consumption**

	use "$temporary/HH_SEC_9A2_Q1Q2Q3Q4adj" if quantity~=. & value~=., clear	
	sort hhid	
			
	drop if quantity==. & value==.	
	
	drop if mod(item,10)==0
	collapse (sum) fexpday=value (mean) stratum16, by(psu hhid hhid day)

	*Remove those days for which no consumption is reported
	drop if (fexpday==0 | fexpday==.)

	*Make 14 days food consumption
	collapse (sum) fexptot1=fexpday (count) ndays=day (mean) stratum16, by(psu hhid hhid)
	replace fexptot1=fexptot1*14/ndays
	sort hhid

	*Make monthly food consumption
	gen fexp1 = fexptot1*(365/(14*12))
	save "$temporary/temp1", replace
	

	** Weekly consumption**
	use "$temporary\HH_SEC_9B2_Q1Q2Q3Q4adj", clear
	sort hhid	

	drop if mod(item,10)==0
	collapse (sum) fexpwk=value (mean) stratum16, by(psu hhid hhid week)

	*To remove those days for which no consumption is reported
	drop if fexpwk==0

	*Make 14 days(2 weeks) food consumption
	collapse (sum) fexptot2=fexpwk (count) nweeks=week (mean) stratum16, by(psu hhid hhid)
	replace fexptot2=fexptot2*2/nweeks
	sort hhid

	*Make monthly food consumption
	gen fexp2 = fexptot2*(365/(14*12))
	save "$temporary/temp2", replace

	
	use "$temporary/temp1", clear
	merge 1:1 hhid using "$temporary/temp2"
	tab _merge
	egen fexp = rowtotal(fexp1 fexp2)
	label var fexp "Monthly food consumption"
	summarize
	drop fexptot1 fexptot2 _merge
	sort hhid
	save  "$temporary/fexp_hies2016", replace
	
    erase "$temporary/temp1.dta"
	erase "$temporary/temp2.dta"


/*****************************************************************************************************
*                                                                                                    *
                                         NON-FOOD EXPENDITURE
*                                                                                                    *
*****************************************************************************************************/
	* Section 9, Part C
	
	use "$input/HH_SEC_9C_Q1Q2Q3Q4", clear

	*There are not repeated observations	
	rename (s9cq00 s9cq03) (item value)	
	duplicates report hhid item
																	
	drop if mod(item,10)==0
	collapse (sum) nfood1=value (mean) stratum16, by(psu hhid hhid)
	sort hhid
	save "$temporary/temp1", replace


	* Section 9, Part D (items 311 - 362)
	use "$temporary/HH_SEC_9D1_Q1Q2Q3Q4adj", clear
	collapse (sum) nfood2=value (mean) stratum16, by(psu hhid hhid)
	replace nfood2=nfood2/12
	sort hhid
	save "$temporary/temp2", replace

	
	* Section 9, Part D (items 371 - 563)
	use "$input/HH_SEC_9D2_Q1Q2Q3Q4", clear
	drop if s9d2q00==.

	*There are not repeated observations	
	rename (s9d2q00 s9d2q01) (item value)	
	duplicates report hhid item
	drop if mod(item,10)==0

	
	* Separate education & health expenditure 
	gen code=1 if (item >=401 & item<=413) | (item >=421 & item<=434)
    replace code=2 if (item >=441 & item<=448) | (item >=451 & item<=458)
    replace code=3 if code==.
    label define code 1 "Health"
    label define code 2 "Education",add
    label define code 3 "Others",add
    label values code code
    gen hlth_exp=value/12 if code==1
    gen edu_exp=value/12  if code==2
    gen oth_exp=value/12  if code==3


	* drop lumpy life-cycle expenditures
	drop if item >=466 & item <= 472
	* drop income tax
	drop if item==501
	* drop interest charges
	drop if item==502
	*drop insurance
	drop if item >=561 & item <= 563
	collapse (sum) nfood3=value hlth_exp edu_exp oth_exp, by(psu hhid hhid)
	replace nfood3=nfood3/12
	sort hhid
	save "$temporary/temp3", replace
	

	use "$temporary\edu_hlth_exp_modified",clear
    sort hhid
    merge 1:1 hhid using "$temporary\temp3"
    tab _m
    keep if _m==3
    drop _m
    replace edu_exp=edu_exp_9d2 
    replace hlth_exp=hlth_exp_9d2
    egen non_food3=rsum(edu_exp hlth_exp oth_exp)
    sort hhid
    save "$temporary\temp4",replace


	use "$temporary\temp1", clear
    merge 1:1 hhid using "$temporary\temp2"
    tab  _merge
    drop _merge
    sort hhid
    merge hhid using "$temporary\temp4"
    tab  _merge
    drop _merge
    sort hhid
    egen nfexp = rowtotal(nfood1  nfood2 non_food3)
    summarize
    sort hhid
    save "$temporary\nfexp_hies2016", replace
    erase "$temporary\temp1.dta"
    erase "$temporary\temp2.dta"
    erase "$temporary\temp3.dta"	
    erase "$temporary\temp4.dta"	

	

/*****************************************************************************************************
*                                                                                                    *
                                    AGGREGATING TOGETHER THE VARIOUS TOTALS
*                                                                                                    *
*****************************************************************************************************/
	

	use "$temporary/fexp_hies2016", clear
	sort hhid
	merge 1:1 hhid using "$temporary/nfexp_hies2016"
	tab  _merge
	drop _merge
	egen hhexp = rowtotal(fexp nfexp)

	keep psu hhid hhid fexp nfexp hhexp 
	
/*****************************************************************************************************
*                                                                                                    *
                            REPLACING AS MISSING HHOLDS WITH PARTIAL CONSUMPTION DATA
*                                                                                                    *
*****************************************************************************************************/

	sum fexp nfexp hhexp
	replace fexp=.  if  nfexp==. 
	replace nfexp=. if fexp==. 
	replace hhexp=. if (fexp==. | nfexp==.)
	sum fexp nfexp hhexp
	
	list hhid if fexp==.
	list hhid if nfexp==.
	list hhid if (nfexp==. | fexp==.)	
	save "$temporary/hhexp_hies2016", replace

	erase "$temporary/fexp_hies2016.dta"
	erase "$temporary/nfexp_hies2016.dta"

	


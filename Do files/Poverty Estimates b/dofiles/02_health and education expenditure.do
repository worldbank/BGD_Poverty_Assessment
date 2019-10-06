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

/* On May 2nd, 2017, it was decided to use education and health expenditure from sections 2B and 3A 
for thoses houhseholds who did not report these expenditures in section 9D (they have missing or zero). 
Quarterly estimates were updated to include this modification. */

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
                                    EDUCATION EXPENDITURES
*                                                                                                    *
*****************************************************************************************************/

** Education expenditure from education module (HH_SEC_2B)

use "$input\HH_SEC_2B_Q1Q2Q3Q4.dta",clear
keep if  s2bq01==1 & s2bq00~=.
egen tot_exp=rowtotal(s2bq08a - s2bq08p) 
collapse (sum) edu_exp_2B=tot_exp (max) wgt post_factor ruc ,by(hhold)

** make it monthly expenditure **
replace edu_exp_2B=edu_exp_2B/12
sort hhold
save "$temporary\t0",replace



/*****************************************************************************************************
*                                                                                                    *
                         EDUCATION AND HEALTH EXPENDITURES SECTION 9D
*                                                                                                    *
*****************************************************************************************************/

** Education & health expenditure from yearly non-food expenditure (HH_SEC_9D2)

use "$input\HH_SEC_9D2_Q1Q2Q3Q4.dta",clear
drop if s9d2q00==.
gen hlth_exp_9d2=s9d2q01/12 if (s9d2q00>=401 & s9d2q00<=413) | (s9d2q00>=421 & s9d2q00<=434)
gen edu_exp_9d2=s9d2q01/12 if (s9d2q00>=441 & s9d2q00<=448) | (s9d2q00>=451 & s9d2q00<=458)
collapse (sum) edu_exp_9d2=edu_exp_9d2 hlth_exp_9d2=hlth_exp_9d2,by(hhold)
sort hhold
save "$temporary\t1",replace 


/*****************************************************************************************************
*                                                                                                    *
                                      HEALTH EXPENDITURES
*                                                                                                    *
*****************************************************************************************************/

*** Health expenditure from health module (HH_SEC_3A)
use "$input\HH_SEC_3A_Q1Q2Q3Q4.dta",clear
drop if s3aq00==.
egen hlth_exp1_3A=rowtotal(s3aq14a - s3aq14d)
egen hlth_exp2_3A=rowtotal(s3aq15a - s3aq15e)
egen hlth_exp3_3A=rowtotal(s3aq20a - s3aq20ic)
replace hlth_exp3_3A=hlth_exp3_3A/12
collapse (sum) hlth_exp1_3A=hlth_exp1_3A hlth_exp2_3A=hlth_exp2_3A hlth_exp3_3A=hlth_exp3_3A,by(hhold) 
egen hlth_exp_3A=rsum(hlth_exp1_3A hlth_exp2_3A hlth_exp3_3A)
sort hhold
save "$temporary\t2",replace


/*****************************************************************************************************
*                                                                                                    *
                                     MERGING ALL DATABASES
*                                                                                                    *
*****************************************************************************************************/

use "$temporary\t0",clear
sort hhold
merge 1:1 hhold using "$temporary\t1"
tab _m
drop _m
sort hhold
merge 1:1 hhold using "$temporary\t2"
tab _m
drop _m

sum hlth_exp_3A hlth_exp_9d2 edu_exp_2B edu_exp_9d2

save "$temporary\edu_hlth_exp_original.dta",replace
count if edu_exp_2B>0 & edu_exp_2B~=. & (edu_exp_9d2==. | edu_exp_9d2==0)
count if hlth_exp_3A>0 & hlth_exp_3A~=. & (hlth_exp_9d2==. | hlth_exp_9d2==0)

**replace missing education in SEC-9D2 with expenditure from SEC_2B
replace edu_exp_9d2=edu_exp_2B if (edu_exp_9d2==. | edu_exp_9d2==0) & (edu_exp_2B>0 & edu_exp_2B~=.) 
save "$temporary\edu_hlth_exp_modified.dta",replace


erase "$temporary\t0.dta"
erase "$temporary\t1.dta"
erase "$temporary\t2.dta"


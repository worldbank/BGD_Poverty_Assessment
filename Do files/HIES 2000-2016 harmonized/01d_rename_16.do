/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                                    HARMONIZATION 2016                                            **
**                                                                                                  **
** COUNTRY	Bangladesh
** COUNTRY ISO CODE	BGD
** YEAR	2016
** SURVEY NAME	HOUSEHOLD INCOME AND EXPENDITURE SURVEY 2016
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS
** 
** Created	01/14/2016, 
** Modified	12/19/2017
**                                                                                                  **
*****************************************************************************************************

This dofile harmonizes and merges datasets and variables for year 2016.

Variables are defined as  s#_q#_yy_t
s# = Section number
q# = Question number	
yy = year, 00 for 2000, 05 for 2005, 10 for 2010, 16 for 2016
t = Type of information: Raw=r or Constructed=c 

*****************************************************************************************************
*                                                                                                    *
                                         INITIAL COMMANDS
*	                                                                                                 *
*****************************************************************************************************/										 

** INITIAL COMMANDS
   clear
   set more off, perm
   
   
**TEMPORARY FILES    
#d;
tempfile geo2016 HH_SEC_1A HH_SEC_1B HH_SEC_2A HH_SEC_2B HH_SEC_3A HH_SEC_4A HH_SEC_4B
HH_SEC_6A HH_SEC_6B HH_SEC_7A 
HH_SEC_7B HH_SEC_7C1 HH_SEC_7C2 HH_SEC_7C3 HH_SEC_7C4 HH_SEC_7D HH_SEC_7E
HH_SEC_8A HH_SEC_8B HH_SEC_8D1 HH_FILTER HH_SEC_9D1 HH_SEC_9D2
individual2016 employment2016 enterprise2016 household2016 migration2016 microcredit2016 
agriculture2016 food12016 food22016 food32016 monthlynfood2016 annualnfood2016 durable2016    
;
#d cr   
     
	 
/*****************************************************************************************************
*                                                                                                    *
					*  ASSEMBLE WEIGHTS AND GEOGRAPHIC INFORMATION
*                                                                                                    *
*****************************************************************************************************/

*Count Household Members 
use "$input16/HH_SEC_1A_Q1Q2Q3Q4", clear	

*Duplicated observations
duplicates report hhid indid
duplicates tag hhid indid, gen(flag)
	
*Drops automatically duplicated observations	
sort hhid indid
duplicates drop hhid indid, force
egen member= count(indid), by(hhid)
drop if member==0

*This duplicates acts as a collapse, it drops lots of observations to convert roster into hhid level dataset
sort hhid
duplicates drop hhid, force
gen popwgt= hhwgt * member
keep hhid stratum16 hhwgt popwgt division_code division_name zila_code zila_name ruc
g year=2016

merge 1:1 hhid using  "$input16/HH_META_Q1Q2Q3Q4.dta",keepusing(id_01_name zl id_02_name id_03_code id_03_name div)

drop if _merge!=3
drop _merge
rename ( stratum16 division_code ruc zila_code ) ///
	( stratum division spc district )
la drop stratum16

gen urbrural=spc
replace urbrural=2 if spc==3



order hhid year strat hhwgt pop spc urb division division_name district zila_name

foreach var of varlist stratum-id_03_name{
rename `var' `var'_16
}																

compress

save `geo2016', replace	
 
/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE INDIVIDUAL DATABASE
*                                                                                                    *
*****************************************************************************************************/

/* Files HH_SEC_1A, HH_SEC_1B,  SECTION 1: HOUSEHOLD INFORMATION ROSTER
   Files HH_SEC_2A, HH_SEC_2B,  SECTION 2: EDUCATION
   Files HH_SEC_3A,    		    SECTION 3: HEALTH */

foreach file in HH_SEC_1A HH_SEC_1B	HH_SEC_2A HH_SEC_2B HH_SEC_3A{
use "$input16/`file'_Q1Q2Q3Q4", clear

duplicates report hhid indid
cap drop if indid==.
duplicates drop hhid indid, force
save ``file'', replace
}

use `HH_SEC_1A', clear
foreach file in HH_SEC_1B HH_SEC_2A HH_SEC_2B HH_SEC_3A{
merge 1:1 hhid indid using ``file''
tab _m
drop _m
}

rename s*q0* s*q*
rename s*q* s*_q*_16_r
rename s2bq8_q_16_r s2b_q8q_16_r

cap drop    zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop div_16 id_01_name_16 zl_16 id_02_name_16 id_03_code_16 id_03_name_16)
drop _m

#delimit;
glo variables psu hhid indid ruc urbrural stratum16 hhwgt quarter 
division_code division_name zila_code zila_name;
#delimit cr 
order $variables
foreach var in $variables {
rename `var' `var'_16
}

gen year=2016
order year


**********************Correction to household head variable*********************

*members of household
bys hhid_16: egen member=count(indid_16)

*Household heads
replace s1a_q2_16_r=. if s1a_q2_16_r==0
replace s1a_q2_16_r=14 if s1a_q2_16_r==. & hhid_16==387041 & indid_16==2

gen head=(s1a_q2_16_r==1) if s1a_q2_16_r!=.
bys hhid_16: egen heads=total(head) 
replace heads=. if head==.

egen hh=tag(hhid_16)
tab heads if hh==1

*Maximum age inside the household
bys hhid_16: egen maxage=max(s1a_q3_16_r)
gen oldest=(s1a_q3_16_r==maxage)

*Highest age of males in the household
bys hhid_16: egen maxageman=max(s1a_q3_16_r) if s1a_q1_16_r==1
gen oldestman=(s1a_q3_16_r==maxageman)


*Household head is male married
gen menmarriedhh= (s1a_q1_16_r==1 & s1a_q2_16_r==1 & s1a_q5_16_r==1) 
bys hhid_16: egen menmarriedhht=total(menmarriedhh)


*Male married
gen malemarried=(s1a_q5_16_r==1 & s1a_q1_16_r==1)
bys hhid_16: egen malemarriedt=total(malemarried) if s1a_q1_16_r!=.

*Household head is female
gen femalehh=(s1a_q1_16_r==2 & s1a_q2_16_r==1)
bys hhid_16: egen femalehht=total(femalehh)

*Are there any households in our sample that have a male in the household that is older than the married male household head? 
gen aux=1 if oldestman==1 & head==0 & menmarriedhht==1 & femalehht==0
bys hhid_16: egen auxt=total(aux) 
tab auxt if hh==1
tab s1a_q2_16_r if inlist(auxt,1) & oldest==1

*Count number of males in the household
gen men= (s1a_q1_16_r==1) if s1a_q1_16_r!=.
bys hhid_16: egen ment=total(men) if s1a_q1_16_r!=.

*Female is the oldest member in the household
gen oldestisfemale=(s1a_q3_16_r==maxage & s1a_q1_16_r==2)
bys hhid: egen oldestisfemalet=total(oldestisfemale)

*males aged 16 years and above
gen young=(s1a_q3_16_r>15 & s1a_q1_16_r==1)
bys hhid: egen youngt=total(young)



****************Apply rules to correct household head***************************

	
*Create the new household head variable
gen p=.
gen headnew=.
replace headnew=1 if head==1 & heads==1


*1. Households with only one member and they have zero household head 
replace p=1 if heads==0 & member==1 
bys hhid: egen heads2=total(p)
tab heads2 if hh==1
replace headnew=p if heads2==1
replace heads=heads2 if heads2==1
tab heads if hh==1

*2. Highest age and male married
cap drop heads2
replace p=.
replace p=1 if inlist(heads,0,2,3,4,6) & oldest==1  &  malemarried==1  
bys hhid: egen heads2=total(p)
tab heads2 if hh==1
replace headnew=p if heads2==1
replace heads=heads2 if heads2==1
tab heads if hh==1

*3. Male married
cap drop heads2
replace p=.
replace p=1 if inlist(heads,0,2,3,4,6) & malemarried==1 
bys hhid: egen heads2=total(p)
tab heads2 if hh==1
replace headnew=p if heads2==1
replace heads=heads2 if heads2==1
tab heads if hh==1


*4. Among males in the household the one with highest age if a female is not the oldest member in the household
cap drop heads2
replace p=.
replace p=1 if inlist(heads,0,2,3,4,6) & oldestman==1 & oldestisfemalet==0
bys hhid: egen heads2=total(p)
tab heads2 if hh==1
replace headnew=p if heads2==1
replace heads=heads2 if heads2==1
tab heads if hh==1


*5. Female with highest age and zero males aged 16 years and above in the household
cap drop heads2
replace p=.
replace p=1 if inlist(heads,0,2,3,4,6) & oldest==1 & s1a_q1_16_r==2 & youngt==0
bys hhid: egen heads2=total(p)
tab heads2 if hh==1
replace headnew=p if heads2==1
replace heads=heads2 if heads2==1
tab heads if hh==1

*6. Male with highest age
cap drop heads2
replace p=.
replace p=1 if inlist(heads,0,2,3,4,6) & oldestman==1
bys hhid: egen heads2=total(p)
tab heads2 if hh==1
replace headnew=p if heads2==1
replace heads=heads2 if heads2==1
tab heads if hh==1

*1 household without information to indentify the household head
replace headnew=. if heads==0

*Correct relationship of members with the head of household variable
replace headnew=0 if headnew==. & s1a_q2_16_r!=.
replace  s1a_q2_16_r=14 if headnew==0 & s1a_q2_16_r==1
replace s1a_q2_16_r=1 if headnew==1

#delimit ;
for any member head heads hh  maxage oldest malemarried p headnew heads2
maxageman oldestman menmarriedhh menmarriedhht malemarriedt femalehh femalehht 
aux auxt men ment oldestisfemale oldestisfemalet young youngt: cap drop X ;
#delimit cr



save individual2016, replace


/*****************************************************************************************************
*                                                                                                    *
                              * ASSEMBLE SAFETY NETS PROGRAMMES DATABASE
*                                                                                                    *
*****************************************************************************************************/

*HH_SEC_1C, SECTION 1: HOUSEHOLD INFORMATION ROSTER, PART C:SOCIAL SAFETY NETS PROGRAMME

use "$input16/HH_SEC_1C_Q1Q2Q3Q4", clear


duplicates report hhid indid
cap drop if indid==.
duplicates drop hhid indid, force

rename s*q0* s*q*
rename s*q* s*_q*_16_r

cap drop    zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop div_16 id_01_name_16 zl_16 id_02_name_16 id_03_code_16 id_03_name_16)
drop if _m==2
drop  _m

#delimit ;
glo variables psu hhid indid ruc urbrural stratum16 hhwgt quarter 
division_code division_name zila_code zila_name;
#delimit cr 
order $variables
foreach var in $variables {
rename `var' `var'_16
}

gen year=2016
order year

save "$output/safety2016.dta", replace



/*****************************************************************************************************
*                                                                                                    *
                                  * ASSEMBLE EMPLOYMENT DATABASE
*                                                                                                    *
*****************************************************************************************************/

foreach file in HH_SEC_4A HH_SEC_4B {
use "$input16/`file'_Q1Q2Q3Q4", clear

rename *q00 idcode
cap drop if idcode==.
rename *q0a as

tab as, missing

*We assume the numbers correspond to letters
replace as="A" if as=="1"
replace as="B" if as=="2"
replace as="C" if as=="3"
replace as="D" if as=="4"
replace as="E" if as=="5"
replace as="F" if as=="6"
replace as="G" if as=="7"
replace as="H" if as=="8"

*There is not information for this household when idcode=0
drop if idcode==0 & hhid==1724017

save `file', replace
}

***********************Duplicated observations section 4B***********************
use HH_SEC_4B, clear
duplicates report hhid idcode as
duplicates tag hhid idcode as, gen(flag)
tab flag


******Three cases of duplicated observations where all the information is zero

*All the information is zero in this case
drop if flag==17

*All the informarion is zero in this case
drop if hhid==1696086 & idcode==0

*All the informarion is zero in this case
drop if hhid==2083006 & idcode==0


rename as as4b
save HH_SEC_4B, replace



****Create a new activity code variable to merge sections 4A and 4B
foreach file in HH_SEC_4A HH_SEC_4B {
use `file', clear

sort hhid idcode 
bys hhid idcode: egen activity=seq()
save `file', replace
}

use  HH_SEC_4A
merge 1:1 hhid idcode activity using HH_SEC_4B
tab _m
drop _m


rename ( idcode) ( indid)
merge m:1 hhid using `geo2016', keepusing(pop div_16 id_01_name_16 zl_16 id_02_name_16 id_03_code_16 id_03_name_16)
drop if _m==2
drop _merge

#delimit ;
glo variables psu hhid indid ruc stratum16 hhwgt quarter  activity
division_code division_name zila_code zila_name;
#delimit cr 
order $variables
foreach var in $variables {
rename `var' `var'_16
}

rename s*q0* s*q*
rename s*q* s*_q*_16_r

gen year=2016
order year

save employment2016, replace 


*Erase temporary files
erase "HH_SEC_4A.dta"
erase "HH_SEC_4B.dta"


/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE HOUSEHOLD DATABASE
*                                                                                                    *
*****************************************************************************************************/

/*	File HH_SEC_6A SECTION 6: HOUSING, PART A: HOUSING INFORMATION									
	File HH_SEC_7A SECTION 7: AGRICULTURE, PART A: LANDHOLDING, PART C: NON-CROP ACTIVITIES (questions 1,9, and 13)									
	Files HH_SEC_8A HH_SEC_8B HH_SEC_8D1, SECTION 8: OTHER ASSETS AND INCOME,
	PART B: OTHER INCOME, PART C: MIGRATION AND REMITTANCE (question 1 and 2)									
	PART D: MICRO CREDIT (question 1,2,3 and 4)	*/		

foreach file in HH_SEC_6A HH_SEC_6B HH_SEC_7A HH_SEC_8A HH_SEC_8B HH_SEC_8D1 {
use "$input16/`file'_Q1Q2Q3Q4", clear
noi di as error "`file'"
duplicates report hhid
save ``file'', replace
}

use `HH_SEC_6A', clear
foreach file in  HH_SEC_7A HH_SEC_8A HH_SEC_8B HH_SEC_8D1 {
noi di as error "`file'"
merge 1:1 hhid using ``file''
tab _m
drop _m
}

merge 1:1 hhid using COVER
tab _m
drop _m

rename s*q0* s*q*
rename s*q* s*_q*_16_r

cap drop    zila zilaid wgt post_factor


merge 1:1 hhid using `geo2016', keepusing(pop div_16 id_01_name_16 zl_16 id_02_name_16 id_03_code_16 id_03_name_16)
drop _m

#delimit;
glo variables psu hhid ruc urbrural stratum16 hhwgt quarter 
division_code division_name zila_code zila_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year
save household2016, replace

exit


/*****************************************************************************************************
*                                                                                                    *
                            * ASSEMBLE NON-AGRICULTURAL ENTERPRISES DATABASE
*                                                                                                    *
*****************************************************************************************************/

*File HH_SEC_05, SECTION 5:  NON-AGRICULTURAL ENTERPRISES 

use "$input16/HH_SEC_05_Q1Q2Q3Q4", clear

drop if s5q00==.
duplicates report hhid s5q00
duplicates drop hhid s5q00, force

rename s*q0* s*q*
rename s*q* s*_q*_16_r
rename s5_q0_16_r enterprise

cap drop   zila zilaid wgt post_factor

merge m:1 hhid using `geo2016', keepusing(pop)
drop if _m==2
drop _m

#delimit ;
glo variables psu hhid enterprise ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables {
rename `var' `var'_16
}

gen year=2016
order year

save enterprise2016, replace


/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE MIGRATION DATABASE
*                                                                                                    *
*****************************************************************************************************/

*File HH_SEC_8C, SECTION 8: OTHER ASSETS AND INCOME, PART C:  MIGRATION AND REMITTANCE

use "$input16/HH_SEC_8C_Q1Q2Q3Q4", clear

drop    zila zilaid wgt post_factor
rename s8cq00 indid

drop  *_r 

rename s*q0*  s*q*
rename s*q*   s*_q*_16_r

merge m:1 hhid using `geo2016', keepusing(pop)
drop _m

#delimit;
glo variables psu hhid indid ruc stratum16 hhwgt quarter 
div id_01_name zl id_02_name id_03_code id_03_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year

save migration2016, replace

/*****************************************************************************************************
*                                                                                                    *
                                  * ASSEMBLE MICRO CREDIT DATABASE
*                                                                                                    *
*****************************************************************************************************/

*File HH_SEC_8D2, SECTION 8: OTHER ASSETS AND INCOME, PART D: MICRO CREDIT

use "$input16/HH_SEC_8D2_Q1Q2Q3Q4", clear

drop    zila zilaid wgt post_factor
rename s8d2q0b indid

drop  *_r 

rename s*q0*  s*q*
rename s*q*   s*_q*_16_r

merge m:1 hhid using `geo2016', keepusing(pop)
drop _m

#delimit;
glo variables psu hhid indid ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year
save microcredit2016, replace

/*****************************************************************************************************
*                                                                                                    *
                                  * ASSEMBLE AGRICULTURE DATABASE
*                                                                                                    *
*****************************************************************************************************/
/*
Files HH_SEC_7B HH_SEC_7C1 HH_SEC_7C2 HH_SEC_7C3 HH_SEC_7C4 HH_SEC_7D HH_SEC_7E
SECTION 7: AGRICULTURE, PART B: CROP PRODUCTION
SECTION 7: AGRICULTURE, PART C: NON-CROP ACTIVITIES
SECTION 7: AGRICULTURE, PART D: EXPENSES ON AGRICULTURAL INPUTS
SECTION 7: AGRICULTURE, PART E: AGRICULTURAL ASSETS */

foreach file in HH_SEC_7B HH_SEC_7C1 HH_SEC_7C2 HH_SEC_7C3 HH_SEC_7C4 HH_SEC_7D HH_SEC_7E{
noi di as error "`file'_Q1Q2Q3Q4"
use "$input16/`file'_Q1Q2Q3Q4", clear

if "`file'"=="HH_SEC_7B"{
drop if s7bq02==.
}

rename *q00 code
duplicates report hhid code
drop if code==.
duplicates report hhid code
duplicates drop hhid code, force
save ``file'', replace
}

use `HH_SEC_7B', clear
foreach file in HH_SEC_7C1 HH_SEC_7C2 HH_SEC_7C3 HH_SEC_7C4 HH_SEC_7D HH_SEC_7E{
noi di as error "`file'"
append using ``file''
}

drop  *_r 

rename s*q0*  s*q*
rename s*q* s*_q*_16_r

drop   zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop)
drop if _m==2
drop _m

#delimit;
glo variables psu hhid code  ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen type_16=1 if inrange(code_16, 1, 49)
replace type_16=2 if inrange(code_16, 201, 210) 
replace type_16=3 if inrange(code_16, 211, 220) 
replace type_16=4 if inrange(code_16, 221, 230) 
replace type_16=5 if inrange(code_16, 231, 240) 
replace type_16=6 if inrange(code_16, 301, 330) 
replace type_16=7 if inrange(code_16, 401, 420) 

gen year=2016
order year
order type_16, after(hhid_16)

save agriculture2016, replace

/*****************************************************************************************************
*                                                                                                    *
                                      * ASSEMBLE FOOD DATABASE
*                                                                                                    *
*****************************************************************************************************/

*File HH_SEC_9A1, SECTION 9: CONSUMPTION, PART A:DAILY CONSUMPTION 

use "$input16/HH_SEC_9A1_Q1Q2Q3Q4", clear

/*Household with hhold=77089 in Q2 appears twice with different information. One of these 
observations is randomly deleted (July) */
duplicates report hhid day
drop if hhid==77089 & s9a1q05b==7


rename (s9a1q01 s9a1q02 s9a1q03 s9a1q04 s9a1q05a s9a1q05b s9a1q05c) ///
	(nboys_16 ngirls_16 nmen_16 nwomen_16 date_day_16 date_month_16 date_year_16)
drop id

drop   zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop)
drop if _m==2
drop _m

#delimit;
glo variables psu hhid day ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year

save food12016, replace


*File  HH_SEC_9A2, SECTION 9: CONSUMPTION, PART A:DAILY CONSUMPTION
use "$input16/HH_SEC_9A2_Q1Q2Q3Q4", clear
rename s9a2q01 foodcode

/*Household with hhold=77089 in Q2 appears twice with different information. One of these 
observations is randomly deleted */

duplicates report hhid day foodcode
duplicates drop hhid day foodcode, force

rename (s9a2q02 s9a2q03 s9a2q04 s9a2q05 s9a2_os) (quantity_16 unit_16 value_16 source1_16 source2_16)
drop id aux dup

drop   zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop)
drop if _m==2
drop _m

#delimit;
glo variables psu hhid day foodcode ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year
save food22016, replace


*Files  HH_SEC_9B1, HH_SEC_9B2, SECTION 9: CONSUMPTION, PART B:WEEKLY CONSUMPTION

use "$input16/HH_SEC_9B2_Q1Q2Q3Q4", clear
merge m:1 hhid week using "$input16/HH_SEC_9B1_Q1Q2Q3Q4", keepusing(s9b1q01a s9b1q01b s9b1q01c)
tab _m
drop if _m==2
drop _m
rename s9b2q01 foodcode
duplicates report hhid week foodcode

rename (s9b1q01a s9b1q01b s9b1q01c) (date_day_16 date_month_16 date_year_16)
rename (s9b2q02 s9b2q03 s9bbq04 s9bbq05) (quantity_16 unit_16 value_16 source_16)

drop id   zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop)
drop if _m==2
drop _m

#delimit;
glo variables psu hhid week foodcode ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year

save food32016, replace

/*****************************************************************************************************
*                                                                                                    *
                                     * ASSEMBLE NON-FOOD DATABASE
*                                                                                                    *
*****************************************************************************************************/

*File  HH_SEC_9C, SECTION 9: CONSUMPTION, PART C: MONTHLY NON-FOOD EXPENDITURE

use "$input16/HH_SEC_9C_Q1Q2Q3Q4", clear
rename s9cq00 code
duplicates report  code

rename (s9cq01 s9cq02 s9cq03) (s9c_q1_16_r s9c_q2_16_r s9c_q3_16_r)
drop id   zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop)
drop if _m==2
drop _m

#delimit;
glo variables psu hhid code ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year
save monthlynfood2016, replace


*File  HH_SEC_9D1 HH_SEC_9D2, SECTION 9: CONSUMPTION, PART D: ANNUAL NON-FOOD EXPENDITURE

foreach file in HH_SEC_9D1 HH_SEC_9D2 {
use "$input16/`file'_Q1Q2Q3Q4", clear

	if "`file'"=="HH_SEC_9D1"{
	rename (s9d1q00 s9d1q01 s9d1q02) (code s9d_q1_16_r s9d_q2_16_r) 
	}
	else {
	rename (s9d2q00 s9d2q01) (code s9d_q2_16_r)
	}

/*13 observations appear twice with different information in database  HH_SEC_9D1_Q1. 
One of these observations is randomly deleted  */
duplicates report hhid code 
duplicates drop hhid code, force
save ``file'', replace
}

use `HH_SEC_9D1'
append using `HH_SEC_9D2', force

drop id    zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop)
drop if _m==2
drop _m

#delimit;
glo variables psu hhid code ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year

save annualnfood2016, replace

/*****************************************************************************************************
*                                                                                                    *
                                      * ASSEMBLE DURABLE DATABASE
*                                                                                                    *
*****************************************************************************************************/

*File HH_SEC_9E, SECTION 9: CONSUMPTION, PART E: INVENTORY OF CONSUMER DURABLE GOODS

use "$input16/HH_SEC_9E_Q1Q2Q3Q4", clear
rename s9eq00 code
duplicates report hhid code


/*11 households answered yes and no at the same time, variables s9eq01a and s9eq01b. 
Among these 11 houeholds 2 answered a quantity different to zero or missing, 
we assume these 2 own the item. The remainig 9 households are treated as missings.  */

gen aux=1 if s9eq01a=="X" & s9eq01b=="X" 
gen own=0 if  s9eq01a=="X"
replace own=1 if  s9eq01b=="X"
replace own=. if aux==1
replace own=1 if inlist(hhid, 2074038, 272052) & aux==1
rename (own s9eq02 s9eq03 s9eq04)(s9e_q1_16_r s9e_q2_16_r s9e_q3_16_r s9e_q4_16_r)
order s9e_q1_16_r, before(s9e_q2_16_r) 
la var s9e_q1_16_r "Does your household own the following items?"

drop aux s9eq01a s9eq01b id   zila zilaid wgt post_factor


merge m:1 hhid using `geo2016', keepusing(pop)
drop if _m==2
drop _m

#delimit;
glo variables psu hhid code ruc stratum16 hhwgt team term quarter 
div id_01_name zl id_02_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name
facilitator_code facilitator_name interviewer_code interviewer_name supervisor_code supervisor_name;
#delimit cr 
order $variables
foreach var in $variables{
rename `var' `var'_16
}

gen year=2016
order year

save durable2016, replace




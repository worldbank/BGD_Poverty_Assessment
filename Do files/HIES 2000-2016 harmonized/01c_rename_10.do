/*****************************************************************************************************									
******************************************************************************************************									
**                                                                                                  **									
**                                    HARMONIZATION 2010                                            **									
**                                                                                                  **									
** COUNTRY	Bangladesh								
** COUNTRY ISO CODE	BGD								
** YEAR	2010								
** SURVEY NAME	HOUSEHOLD INCOME AND EXPENDITURE SURVEY 2010								
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS								
**						
** Created	24/02/2015								
** Modified	12/19/2017							
                                                                                                    **									
******************************************************************************************************									
*****************************************************************************************************/									
/*This dofile harmonizes and merges datasets and variables for year 2010.  														
														
Variables are defined as  s#_q#_yy_t														
s# = Section number														
q# = Question number														
yy = year, 00 for 2000, 05 for 2005, and 10 for 2010														
t = Type of information: Raw=r or Constructed=c */																
/*****************************************************************************************************									
*                                                                                                    *									
                                   INITIAL COMMANDS									
*                                                                                                    *									
*****************************************************************************************************/									
** INITIAL COMMANDS									
   clear
   set more off, perm	

**TEMPORARY FILES    
#d;
tempfile geo2010 individual2010 employment2010 microcredit2010 enterprise2010 rt005 household2010    
rt006 rt007 rt008 rt009 rt010 rt011 rt012 agriculture2010 migration2010 food12010 food22010 food32010
monthlynfood2010 rt018 rt019 annualnfood2010 durable2010 t1_sec_1 t2_sec_1a t3_sec_2 t4_sec_3 t5_sec_4a
t6_sec_4b t7_sec_4b1 t8_sec_4c t9_sec_5 t10_sec_6 t11_sec_6b community2010
;
#d cr
    
   
/*****************************************************************************************************
*                                                                                                    *
                         *  ASSEMBLE WEIGHTS AND GEOGRAPHIC INFORMATION 
*                                                                                                    *
*****************************************************************************************************/
    
use "$input10/rt001.dta", clear									
destring stratum, replace
gen psu1= string(psu,"%003.0f")
gen hhold1= string(hhold,"%003.0f")
drop psu hhold
rename (psu1 hhold1) (psu hhold)
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold
							
*Thana Geocode needs to be genenerated combining District code and Thana code
gen thana2 = string(thana,"%02.0f")									
egen thana3 = concat(dis thana2)									
destring thana3, replace
drop thana		
rename thana3 thana
rename (wgt region) (hhwgt division)

*Create urban-rural variable
encode spc, gen(spc2)
drop spc
rename spc2 spc

gen urbrural=.
replace urbrural=1 if spc==2
replace urbrural=2 if inlist(spc,1,3)

*Variable population weights come from file consumption_00_05_10.dta
preserve
use "$input10/consumption_00_05_10", clear
keep if year==3
destring id, gen(hhid)
tempfile cons
save `cons'
restore

merge 1:1 hhid using `cons', keepusing(popwgt)
tab _m
drop _m

gen year=2010
#delimit;
glo geo10 year stratum hhwgt popwgt
spc urbanrur urbrural division district thana union mouza ;
#delimit cr 
keep $geo10 hhid
order $geo10, after(hhid)

foreach var of varlist stratum-mouza{
rename `var' `var'_10
}																
save `geo2010', replace									

	  							 
/*****************************************************************************************************									
*                                                                                                    *									
                                   * ASSEMBLE INDIVIDUAL DATABASE									
*                                                                                                    *									
*****************************************************************************************************/									
/* File rt002:									
SECTION 1: HOUSEHOLD INFORMATION ROSTER									
SECTION 2: EDUCATION 									
SECTION 3: HEALTH  */  									
									
use "$input10/rt002.dta", clear
destring idcode, replace																										
forval i = 1/3{  									
  rename s0`i'*  s`i'*																		
 }  	 								
rename s1a_q0# s1a_q# 									
rename s1b_q0# s1b_q# 									
rename s1c_q0# s1c_q# 									
rename s2a_q0# s2a_q# 									
rename s2b_q0# s2b_q# 									
rename s3a_q0# s3a_q# 									
rename s3b_q0# s3b_q# 									
rename s3c_q0# s3c_q# 									
rename s3d_q0# s3d_q#    									
rename s*  s*_10_r									

gen psu1= string(psu,"%003.0f")
gen hhold1= string(hhold,"%003.0f")
drop psu hhold
rename (psu1 hhold1) (psu hhold)
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold
rename re* re*_10	

*Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

rename idcode indid
glo id psu hhid indid
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10
save individual2010, replace

#delimit;
keep year psu_10 hhid_10 indid_10 stratum_10 hhwgt_10 popwgt_10 spc_10 urbanrur_10 
urbrural_10 division_10 thana_10 union_10 mouza_10 resid1c_10 s1c*;
# delimit cr
save "$output/safety2010.dta", replace


/*****************************************************************************************************
*                                                                                                    *
                                  * ASSEMBLE EMPLOYMENT DATABASE
*                                                                                                    *
*****************************************************************************************************/
											
/* File rt003: 									
SECTION 4: ECONOMIC ACTIVITIES AND WAGE EMPLOYMENT 									
PART A: ACTIVITIES (ALL PERSONS 5 YEARS AND OLDER), PART B:WAGE EMPLOYMENT */									
									
use "$input10/rt003.dta", clear									
glo variables serial idcode s04a_q_1 s04a_q_2 s04a_q_3  									
foreach var in $variables{									
destring `var', replace force									
}																		
rename s04*  s4*									
rename s4a_q0# s4a_q# 									
rename s4b_q0# s4b_q# 									
rename s4*  s4*_10_r									
rename (idcode idcode2 serial) (indid idcode2_10 activity)								
sort psu hhold idcode  activity
order psu hhold idcode activity	
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold	

*Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid indid activity
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10
save employment2010, replace									
								
												
									
/*****************************************************************************************************									
*                                                                                                    *									
                                   * ASSEMBLE HOUSEHOLD DATABASE									
*                                                                                                    *									
*****************************************************************************************************/									
/* File rt001:									
SECTION 6: HOUSING, PART A: HOUSING INFORMATION									
SECTION 7: AGRICULTURE, PART A: LANDHOLDING, PART B: CROP PRODUCTION (question 1), PART C: NON-CROP ACTIVITIES (question 1,9, and 13)									
SECTION 8: OTHER ASSETS AND INCOME, PART B: OTHER INCOME, PART C:MIGRATION AND REMITTANCE (question 1 and 2)									
PART D: MICRO CREDIT (question 1,2,3 and 4)	*/							
																																								
/* File rt005:									
SECTION 6: HOUSING, PART B: SHOCKS AND COPING									
									
s#_q#_yyyy_u_t_sh#									
									
sh# = Shock Code*/									
									
use "$input10/rt005.dta", clear		
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold
							
rename s0*  s*
rename s6* s6*_10_r
reshape wide s6*, i(psu hhid) j(shock_co)
rename s6*# s6*_sh#
sort psu hhid
save `rt005', replace

																	
/*Household Dataset*/																	
use "$input10/rt001.dta", clear									
destring stratum, replace									
gen psu1= string(psu,"%003.0f")
gen hhold1= string(hhold,"%003.0f")
drop psu hhold
rename (psu1 hhold1) (psu hhold)	
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold									
							
*Thana Geocode needs to be genenerated combining District code and Thana code
gen thana2 = string(thana,"%02.0f")									
egen thana3 = concat(dis thana2)									
destring thana3, replace
drop thana		
rename thana3 thana
rename (wgt region) (hhwgt division)

*Create urban-rural variable
encode spc, gen(spc2)
drop spc
rename spc2 spc

gen urbrural=.
replace urbrural=1 if spc==2
replace urbrural=2 if inlist(spc,1,3)

*rename variables
drop s09* s09b1w1_ s09b1w2_ thana2									
rename s0*  s*
rename s#*  s#*_10_r

*Variable population weights come from file consumption_00_05_10.dta
preserve
use "$input10/consumption_00_05_10", clear
keep if year==3
destring id, gen(hhid)
tempfile cons
save `cons'
restore

merge 1:1 hhid using `cons', keepusing(popwgt)
tab _m
drop _m

merge 1:1 hhid using `rt005', 
tab _m
drop _m

gen year=2010
glo vars psu hhid stratum hhwgt popwgt spc urbanrur urbrural division district thana union mouza team term
foreach var in $vars{
rename `var' `var'_10
}
order year $vars															
save household2010, replace									
		

exit 		
/*****************************************************************************************************
*                                                                                                    *
                                  * ASSEMBLE MICRO CREDIT DATABASE
*                                                                                                    *
*****************************************************************************************************/
													
/*File rt014:									
SECTION 8: OTHER ASSETS AND INCOME, PART D: MICRO CREDIT (question 5 to 14)*/									
									
use "$input10/rt014.dta", clear									
rename s0*  s*									
rename s8d_q0# s8d_q# 									
rename s*  s*_10_r									
sort psu hhold idcode loan_num

gen hhid=psu+hhold
destring psu hhid, replace
drop hhold	
rename (idcode loan_num) (indid loannum)

*Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid indid loannum
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10
save microcredit2010, replace


/*****************************************************************************************************
*                                                                                                    *
                            * ASSEMBLE NON-AGRICULTURAL ENTERPRISES DATABASE
*                                                                                                    *
*****************************************************************************************************/

/* File rt004:									
SECTION 5: NON-AGRICULTURAL ENTERPRISES */									
									
use "$input10/rt004.dta", clear									
destring s05a_q_1, replace									
rename s0*  s*									
rename s*  s*_10_r									
sort psu hhold enumber
/*2 observations appear twice with different information. 2 observations are deleted randomly. 
1 observation appears twice with the same information. 1 observation is deleted*/
duplicates report psu hhold enumber						
duplicates drop psu hhold enumber, force	

gen hhid=psu+hhold
destring psu hhid, replace
drop hhold	
rename enumber enterprise

**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid enterprise
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10
save enterprise2010, replace			
										
									
/*****************************************************************************************************									
*                                                                                                    *									
                                   * ASSEMBLE AGRICULTURE DATABASE									
*                                                                                                    *									
*****************************************************************************************************/									
/* File rt006:									
SECTION 7: AGRICULTURE, PART B: CROP PRODUCTION */									
									
use "$input10/rt006.dta", clear									
drop ln 									
rename s0*  s*									
rename s*  s*_10_r									
sort psu hhold crop_cod									
rename crop_cod code
gen type=1
order type, after(code)									
save `rt006', replace									
									
									
/* File rt007, rt008,rt009, rt010: 									
SECTION 7: AGRICULTURE, PART C: NON-CROP ACTIVITIES */									
									
use "$input10/rt007.dta", clear									
rename s0*  s*									
rename s*  s*_10_r									
sort psu hhold liv_code									
rename liv_code code
gen type=2	
order type, after(code)																	
save `rt007', replace									
									
									
use "$input10/rt008.dta", clear									
rename ( s07c_q_1 s07c_q_2 s07c_q_3) ( s07c_q_5 s07c_q_6 s07c_q_7)								
rename s0*  s*									
rename s*  s*_10_r									
sort psu hhold	prod_cod								
rename prod_cod code
gen type=3	
order type, after(code)																									
save `rt008', replace									
									
									
use "$input10/rt009.dta", clear									
rename (s07c_q_1 s07c_q_2 s07c_q_3) (s07c_q_8 s07c_q_9 s07c_q_10)								
rename s0*  s*									
rename s*  s*_10_r									
sort psu hhold	fish_act								
rename fish_act code
gen type=4
order type, after(code)																																		
save `rt009', replace									
									
									
use "$input10/rt010.dta", clear									
rename s07c_q_1  s07c_q_11								
rename s0*  s*									
rename s*  s*_10_r									
sort psu hhold forestry									
rename forestry code
gen type=5
order type, after(code)																																											
save `rt010', replace									
									
									
/* File rt011:									
SECTION 7: AGRICULTURE, PART D: EXPENSES ON AGRICULTURAL INPUTS. */									
									
use "$input10/rt011.dta", clear									
drop ln									
rename s0*  s*									
rename s*  s*_10_r									
sort psu hhold exp_agri									
rename exp_agri	code
gen type=6
order type, after(code)																																										
save `rt011', replace									
									
									
/*File rt012:									
SECTION 7: AGRICULTURE,	PART E: AGRICULTURAL ASSETS */								
									
use "$input10/rt012.dta", clear									
drop ln									
rename s0*  s*									
rename s*  s*_10_r									
sort psu hhold agric_as									
rename agric_as code
gen type=7
order type, after(code)																																											
save `rt012', replace									
									

/*Agriculture Dataset*/	
									
use `rt006', replace									
forval i=7/9{									
append using `rt00`i''									
}									
forval i=10/12{									
append using `rt0`i''										
}	
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold
rename price price_10

**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid code type
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10
save agriculture2010, replace	

									
/*****************************************************************************************************									
*                                                                                                    *									
                                   * ASSEMBLE MIGRATION DATABASE									
*                                                                                                    *									
*****************************************************************************************************/									
/*File rt013:									
SECTION 8: OTHER ASSETS AND INCOME, PART C:SOCIAL MIGRATION AND REMITTANCE (question 3 to 17) */									
									
use "$input10/rt013.dta", clear									
destring s08c_q07 s08c_q12, replace									
rename s0*  s*									
rename s8c_q0# s8c_q# 									
rename s*  s*_10_r	
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold									
sort psu hhid 
rename sbc_q13_10_r s8c_q13_10_r

**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid migrant
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10										
save migration2010, replace																		
 									
									
/*****************************************************************************************************									
*                                                                                                    *									
                                   * ASSEMBLE FOOD DATABASES									
*                                                                                                    *									
*****************************************************************************************************/									
/* File rt001:									
SECTION 9: CONSUMPTION, PART A: DAILY CONSUMPTION (Number of boys, girls, men, women)									
SECTION 9: CONSUMPTION, PART B: WEEKLY CONSUMPTION (Dates) */									
use "$input10/rt001.dta", clear									
gen psu1= string(psu,"%003.0f")
gen hhold1= string(hhold,"%003.0f")
drop psu hhold
rename (psu1 hhold1) (psu hhold)	
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold					
keep psu hhid s09*									
drop  s09b1w1_ s09b1w2_	

forval i=1/9{
rename s09a1d0`i' boys`i'
}
forval i=10/14{
rename s09a1d`i' boys`i'
}
local j = 1
forval  i = 1(4)9 {
rename s09a1d_`i' girls`j'
local j = `j'+1
}
local j = 4
forval  i = 13(4)53 {
rename s09a1_`i' girls`j'
local j = `j'+1
}
local j = 1
forval  i = 2(4)6 {
rename s09a1d_`i' men`j'
local j = `j'+1
}
local j = 3
forval  i = 10(4)54 {
rename s09a1_`i' men`j'
local j = `j'+1
}
local j = 1
forval  i = 3(4)7 {
rename s09a1d_`i' women`j'
local j = `j'+1
}
local j = 3
forval  i = 11(4)55 {
rename s09a1_`i' women`j'
local j = `j'+1
}
local j = 1
forval  i = 4(4)8 {
rename s09a1d_`i' date`j'
local j = `j'+1
}
local j = 3
forval  i = 12(4)56 {
rename s09a1_`i' date`j'
local j = `j'+1
}

reshape long boys girls men women date, i(psu hhid) j(day)					
sort psu hhid day		
rename (boys girls men women date) (nboys_10 ngirls_10 nmen_10 nwomen_10 date_10)	


**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid day
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10																								
save food12010, replace									
									
									
/*File rt015:									
SECTION 9:  CONSUMPTION, PART A: DAILY CONSUMPTION*/																							
use "$input10/rt015.dta", clear									
drop ln t kcal
drop if hhold==""

/*1 observation appears twice with the same information. 1 observation is deleted*/
duplicates report psu hhold item
duplicates drop psu hhold item, force	

gen hhid=psu+hhold
destring psu hhid, replace
drop hhold									
sort psu hhid 

forval i=1/9{
rename s09a1d0`i' quantity`i'
}
forval i=10/14{
rename s09a1d`i' quantity`i'
}
local j = 1 
forval  i = 1(3)7 {
rename s09a1d_`i' unit`j'
local j = `j'+1
}
local j = 4
forval  i = 10(3)40 {
rename s09a1_`i' unit`j'
local j = `j'+1
}
local j = 1 
forval  i = 2(3)8 {
rename s09a1d_`i' value`j'
local j = `j'+1
}
local j = 4
forval  i = 11(3)41 {
rename s09a1_`i' value`j'
local j = `j'+1
}
local j = 1
forval  i = 3(3)9 {
rename s09a1d_`i' source`j'
local j = `j'+1
}
local j = 4
forval  i = 12(3)42 {
rename s09a1_`i' source`j'
local j = `j'+1
}

reshape long quantity unit value source, i(psu hhid item) j(day)								
sort psu hhid item day															
rename (item quantity unit value source) (foodcode quantity_10 unit_10 value_10 source_10)
drop if mod(foodcode,10)==0

**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid foodcode day
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10								
save food22010, replace									
									
									
/*File rt016: 									
SECTION 9:  CONSUMPTION, PART B: WEEKLY CONSUMPTION	*/								
									
use "$input10/rt001.dta", clear	
gen psu1= string(psu,"%003.0f")
gen hhold1= string(hhold,"%003.0f")
drop psu hhold
rename (psu1 hhold1) (psu hhold)
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold								
								
keep psu hhid  s09b1w1_ s09b1w2_
rename (s09b1w1_ s09b1w2_) (date1 date2)
sort psu hhid	
tempfile food2dates									
save `food2dates' , replace	
									
use "$input10/rt016.dta", clear	
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold ln								
sort psu hhid								

merge m:m psu hhid using `food2dates'
drop if _merge==2									
drop _merge	
sort psu hhid item

rename (s09b1w1_ s09b1w2_) (quantity1 quantity2)
rename (s09b1w_1 s09b1w_4) (unit1 unit2)
rename (s09b1w_2 s09b1w_5) (value1 value2)
rename (s09b1w_3 s09b1w_6) (source1 source2)

reshape long quantity unit value source date, i(psu hhid item) j(week)
rename (item quantity unit value source kcal date) ///
(foodcode quantity_10 unit_10 value_10 source_10 kcal_10 date_10)
drop if mod(foodcode,10)==0

**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid foodcode week
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10
save food32010, replace									
																		
									
/*****************************************************************************************************									
*                                                                                                    *									
                                   * ASSEMBLE NON-FOOD DATABASE									
*                                                                                                    *									
*****************************************************************************************************/									
/*File rt017:									
SECTION 9:CONSUMPTION, PART C: MONTHLY NON-FOOD EXPENDITURE	*/																	
									
use "$input10/rt017.dta", clear									
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold ln
sort psu hhid item								
rename (item s09c1_q0 s09c1__1 s09c1__2)(code s9c_q1_10_r s9c_q2_10_r s9c_q3_10_r)
drop if mod(code,10)==0

**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid code
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10
save monthlynfood2010, replace
									
									
/*File rt018:									
SECTION 9:  CONSUMPTION, PART D1: ANNUAL NON-FOOD EXPENDITURE */																		
									
use "$input10/rt018.dta", clear									
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold ln
sort psu hhid item	
rename (item s09d1_q0 s09d1__1) (code s9d_q1_10_r s9d_q2_10_r)																		
save `rt018', replace									
									
									
/*File rt019:									
SECTION 9: CONSUMPTION	PART, D2: ANNUAL NON-FOOD EXPENDITURE */								
																		
use "$input10/rt019.dta", clear									

/*1 observation appears twice with the same information. 1 observation is deleted*/																				
duplicates report psu hhold item								
duplicates drop psu hhold item, force

gen hhid=psu+hhold
destring psu hhid, replace
drop hhold ln
sort psu hhid item										
rename (item s09d2_q0) (code s9d_q2_10_r)																
save `rt019', replace									
									

use `rt018', clear									
append using `rt019'
drop if mod(code,10)==0

**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid code
foreach var in $id{
rename `var' `var'_10
}	
order year $id $geo10
save annualnfood2010, replace 


/*****************************************************************************************************									
*                                                                                                    *									
                                   * ASSEMBLE DURABLE DATABASE									
*                                                                                                    *									
*****************************************************************************************************/									
/*File rt020:									
SECTION 9:  CONSUMPTION	PART E:  INVENTORY OF CONSUMER DURABLE GOODS */																
									
use "$input10/rt020.dta", clear
gen hhid=psu+hhold
destring psu hhid, replace
drop hhold ln
sort psu hhid dg_code
rename (dg_code s09e_q01 s09e_q02 s09e_q03 s09e_q04)(code s9e_q1_10_r s9e_q2_10_r s9e_q3_10_r s9e_q4_10_r)

**Getting Geographical information and weights
merge m:1 hhid using `geo2010'
tab _m
drop if _m==2
drop _m

glo id psu hhid code
foreach var in $id{
rename `var' `var'_10
}
order year $id $geo10
save durable2010, replace
																	
									
/*****************************************************************************************************									
*                                                                                                    *									
                                   * ASSEMBLE COMMUNITY DATABASE									
*                                                                                                    *									
*****************************************************************************************************/									


/*File t1_sec_1.dta:									
SECTION 1: GENERAL INFORMATION AND ECONOMIC ACTIVITIES (Question 1 to 7)*/									
									
use "$inputcom10\t1_sec_1.dta", clear									
drop type 									
destring psu team div zl uz un mz s1q1, replace																		
rename s1*  s1_*_10_r									
rename q*  s1_q*_10_r	
/*1 observation appears twice with the same information. 1 observation is deleted*/																				
duplicates report psu team div zl uz un mz
duplicates drop psu team div zl uz un mz, force								
save `t1_sec_1', replace									
									
									
/*File t2_sec_1a:									
SECTION 1: GENERAL INFORMATION AND ECONOMIC ACTIVITIES (Question 8)*/									
use "$inputcom10\t2_sec_1a.dta", clear									
destring psu team div zl uz un mz prog ngo, replace																
									
/*Duplicate information is deleted*/									
duplicates report psu team div zl uz un mz prog ngo									
duplicates tag psu team div zl uz un mz prog ngo, gen(flag)									
sort psu team div zl uz un mz prog ngo									
duplicates drop psu team div zl uz un mz prog ngo, force									
drop type stat status flag									
									
egen indi=seq(), by(mz)									
reshape wide prog ngo, i(psu team div zl uz un mz) j(indi)									
rename pr* s1_q8_10_r_pr*									
rename ng* s1_q8_10_r_ng*									
save `t2_sec_1a', replace									
									
									
/*File t3_sec_2:									
SECTION 2: AGRICULTURE AND AGRICULTURAL PRODUCTION */									
									
use "$inputcom10\t3_sec_2.dta", clear									
drop type									
glo variables psu team div zl uz un mz s*									
foreach var in $variables{									
destring `var', replace force									
}									
rename s2*  s2_*_10_r									
save `t3_sec_2', replace									
									
									
/*File t4_sec_3:									
SECTION 3: FACILITIES */									
									
use "$inputcom10\t4_sec_3.dta", clear									
drop type									
glo variables psu team div zl uz un mz s*									
foreach var in $variables{									
destring `var', replace force									
}									
rename s3*  s3_*_10_r									
save `t4_sec_3', replace									
									
									
/*File t5_sec_4a:									
SECTION 4: PHYSICAL AND SOCIAL INFRASTRUCTURE (Question 1) */									
									
use "$inputcom10\t5_sec_4a.dta", clear									
drop type									
destring psu team div zl uz un mz inf_ty sl dt hrs min mt ct1 ct2, replace																		
rename (dt hrs min mt ct1 ct2) (s4_q1a_10_r s4_q1b_10_r s4_q1c_10_r s4_q1d_10_r s4_q1e1_10_r s4_q1e2_10_r)																		
egen infracode=concat(inf_ty sl)									
destring infracode, replace force									
tab infracode									
/*As can be seen in the previous table infrastructures with codes 19, 25, 410 do not exist, 									
for that reason they are deleted.*/									
drop if infracode==19 | infracode==25 | infracode==410									
									
/*Some infrastructure types are duplicated. Duplicate information is deleted */									
duplicates tag psu team div zl uz un mz infracode, generate(indi)									
duplicates report psu team div zl uz un mz infracode s4_q1a_10_r s4_q1b_10_r s4_q1c_10_r s4_q1d_10_r s4_q1e1_10_r									
duplicates drop psu team div zl uz un mz infracode s4_q1a_10_r s4_q1b_10_r s4_q1c_10_r s4_q1d_10_r s4_q1e1_10_r, force									
									
/*Some infrastructure types are twice in a Mouza. In this case the nearest infrastructure in distance is kept,									
Followed by time needed to reach in hours and minutes*/									
sort psu team div zl uz un mz infracode s4_q1a_10_r s4_q1b_10_r s4_q1c_10_r									
duplicates list  psu team div zl uz un mz infracode s4_q1a_10_r s4_q1b_10_r s4_q1c_10_r s4_q1d_10_r s4_q1e1_10_r									

drop if 	zl==	19	&	uz==	67	&	un==	65	&	mz==	84	&	inf_ty==	3	&	sl==	3	&	s4_q1a_10_r==	3		
drop if 	zl==	30	&	uz==	25	&	un==	94	&	mz==	170	&	inf_ty==	3	&	sl==	1	&	s4_q1a_10_r==	19		
drop if 	zl==	30	&	uz==	25	&	un==	94	&	mz==	170	&	inf_ty==	3	&	sl==	3	&	s4_q1a_10_r==	2		
drop if 	zl==	30	&	uz==	25	&	un==	94	&	mz==	170	&	inf_ty==	3	&	sl==	6	&	s4_q1a_10_r==	4		
drop if 	zl==	30	&	uz==	25	&	un==	94	&	mz==	170	&	inf_ty==	3	&	sl==	7	&	s4_q1a_10_r==	4		
drop if 	zl==	30	&	uz==	25	&	un==	94	&	mz==	170	&	inf_ty==	3	&	sl==	8	&	s4_q1a_10_r==	0	& s4_q1c_10_r==25	
drop if 	zl==	75	&	uz==	10	&	un==	76	&	mz==	926	&	inf_ty==	3	&	sl==	6	&	s4_q1a_10_r==	10		
drop if 	zl==	26	&	uz==	14	&	un==	65	&	mz==	809	&	inf_ty==	3	&	sl==	4	&	s4_q1a_10_r==	2		
drop if 	zl==	35	&	uz==	43	&	un==	27	&	mz==	757	&	inf_ty==	3	&	sl==	3	&	s4_q1a_10_r==	1		
drop if 	zl==	48	&	uz==	11	&	un==	83	&	mz==	994	&	inf_ty==	1	&	sl==	2	&	s4_q1a_10_r==	12	& s4_q1d_10_r== 2	
drop if 	zl==	48	&	uz==	11	&	un==	83	&	mz==	994	&	inf_ty==	4	&	sl==	5	&	s4_q1a_10_r==	2	& s4_q1d_10_r== 0	
drop if 	zl==	48	&	uz==	42	&	un==	34	&	mz==	210	&	inf_ty==	3	&	sl==	1	&	s4_q1a_10_r==	22		
drop if 	zl==	48	&	uz==	42	&	un==	34	&	mz==	210	&	inf_ty==	3	&	sl==	2	&	s4_q1a_10_r==	20		
drop if 	zl==	48	&	uz==	42	&	un==	34	&	mz==	210	&	inf_ty==	3	&	sl==	3	&	s4_q1a_10_r==	200		
drop if 	zl==	48	&	uz==	42	&	un==	94	&	mz==	924	&	inf_ty==	1	&	sl==	2	&	s4_q1a_10_r==	25		
drop if 	zl==	61	&	uz==	81	&	un==	45	&	mz==	128	&	inf_ty==	3	&	sl==	2	&	s4_q1a_10_r==	32		
drop if 	zl==	61	&	uz==	81	&	un==	45	&	mz==	128	&	inf_ty==	3	&	sl==	3	&	s4_q1a_10_r==	148		
drop if 	zl==	18	&	uz==	7	&	un==	94	&	mz==	397	&	inf_ty==	3	&	sl==	5	&	s4_q1a_10_r==	0	& s4_q1d_10_r== 4	
drop if 	zl==	18	&	uz==	31	&	un==	47	&	mz==	114	&	inf_ty==	3	&	sl==	5	&	s4_q1a_10_r==	6		
drop if 	zl==	47	&	uz==	17	&	un==	31	&	mz==	835	&	inf_ty==	3	&	sl==	3	&	s4_q1a_10_r==	1		
drop if 	zl==	10	&	uz==	81	&	un==	37	&	mz==	727	&	inf_ty==	3	&	sl==	5	&	s4_q1a_10_r==	40		
drop if 	zl==	32	&	uz==	24	&	un==	36	&	mz==	219	&	inf_ty==	2	&	sl==	3	&	s4_q1a_10_r==	350		
drop if 	zl==	49	&	uz==	6	&	un==	19	&	mz==	672	&	inf_ty==	3	&	sl==	3	&	s4_q1a_10_r==	2		
drop if 	zl==	49	&	uz==	94	&	un==	61	&	mz==	340	&	inf_ty==	1	&	sl==	1	&	s4_q1a_10_r==	30		
drop if 	zl==	85	&	uz==	3	&	un==	25	&	mz==	353	&	inf_ty==	3	&	sl==	4	&	s4_q1a_10_r==	6		
drop if 	zl==	85	&	uz==	27	&	un==	42	&	mz==	845	&	inf_ty==	3	&	sl==	5	&	s4_q1a_10_r==	15		
drop if 	zl==	85	&	uz==	27	&	un==	42	&	mz==	845	&	inf_ty==	3	&	sl==	9	&	s4_q1a_10_r==	0	& s4_q1d_10_r== 3	
drop if 	zl==	85	&	uz==	49	&	un==	23	&	mz==	213	&	inf_ty==	3	&	sl==	5	&	s4_q1a_10_r==	15	& s4_q1e1_10_r== 1	
drop if 	zl==	94	&	uz==	82	&	un==	94	&	mz==	884	&	inf_ty==	3	&	sl==	3	&	s4_q1a_10_r==	48		

drop  inf_ty sl indi									
reshape wide s4*, i(psu team div zl uz un mz) j(infracode)									
save `t5_sec_4a', replace									
									
																		
/*File t6_sec_4b:									
SECTION 4: PHYSICAL AND SOCIAL INFRASTRUCTURE (Question 2) */									
use "$inputcom10\t6_sec_4b.dta", clear									
drop type									
glo variables psu team div zl uz un mz shift year boys girls men women									
foreach var in $variables{									
destring `var', replace force									
}									
rename (name shift year boys girls men women) (s4_q2a_10_r s4_q2b_10_r s4_q2c_10_r ///									
s4_q2d_10_r s4_q2e_10_r s4_q2f_10_r s4_q2g_10_r)									
save `t6_sec_4b', replace									
									
									
/*File t7_sec_4b1:									
SECTION 4: PHYSICAL AND SOCIAL INFRASTRUCTURE (Question 3) */									
use "$inputcom10\t7_sec_4b1.dta", clear									
drop type									
glo variables psu team div zl uz un mz shift year boys girls men women sscapp pass a_plus									
foreach var in $variables{									
destring `var', replace force									
}									
rename (name shift year boys girls men women sscapp pass a_plus ) (s4_q3a_10_r s4_q3b_10_r ///									
s4_q3c_10_r s4_q3d_10_r s4_q3e_10_r s4_q3f_10_r s4_q3g_10_r s4_q3h_10_r  ///									
s4_q3i_10_r  s4_q3j_10_r)									
save `t7_sec_4b1', replace									
									
									
/*File t8_sec_4c:									
SECTION 4: PHYSICAL AND SOCIAL INFRASTRUCTURE (Question 4) */									
use "$inputcom10\t8_sec_4c.dta", clear									
drop type									
glo variables psu team div zl uz un mz slno yes_no dt1 hrs1 min1 mt1									
foreach var in $variables{									
destring `var', replace force									
}									
rename (yes_no dt1 hrs1 min1 mt1) (s4_q4a_10_r s4_q4b_10_r s4_q4c_10_r s4_q4d_10_r s4_q4e_10_r)									
									
/*Some facilities are duplicated. Duplicate information is deleted */									
duplicates report psu team div zl uz un mz slno									
sort psu team div zl uz un mz slno s4_q4b_10_r s4_q4c_10_r s4_q4d_10_r									
duplicates drop psu team div zl uz un mz slno s4_q4b_10_r, force									
									
/*Some facilities are twice in a Mouza. In this case the nearest facility in distance is kept*/									
drop if zl==39 & uz==85 & un==52 & mz==536 & sl==1  & s4_q4b_10_r==12									
drop if zl==72 & uz==74	& un==94 & mz==49  & sl==1  & s4_q4b_10_r==10								
drop if zl==64 & uz==3 	& un==31 & mz==397 & sl==1  & s4_q4b_10_r==20								
drop if zl==73 & uz==45	& un==60 & mz==255 & sl==5  & s4_q4b_10_r==8								
drop if zl==58 & uz==56	& un==17 & mz==968 & sl==1  & s4_q4b_10_r==12								
									
reshape wide s4*, i(psu team div zl uz un mz) j(slno)									
save `t8_sec_4c', replace									
 									
									
/*File t9_sec_5:									
SECTION 5: NATURAL IMPACT */									
use "$inputcom10\t9_sec_5.dta", clear									
drop type									
glo variables psu team div zl uz un mz s* f*									
foreach var in $variables{									
destring `var', replace force									
}									
rename s5q2*  s5_q2*_10_r									
rename sl*    s5_q2sl*_10_r									
rename f*     s5_q2f*_10_r									
rename s5sl*  s5_q1sl*_10_r									
rename s5dt*  s5_q1dt*_10_r									
rename s5hr*  s5_q1hr*_10_r									
rename s5q3   s5_q3_10_r									
save `t9_sec_5', replace									
									
									
/*File t10_sec_6:									
SECTION 6: PRICE AND WAGES */									
use "$inputcom10\t10_sec_6.dta", clear									
drop type									
glo variables psu team div zl uz un mz s* q*									
foreach var in $variables{									
destring `var', replace force									
}									
rename s6* s6_q1*_10_r									
rename sl* s6_q2sl*_10_r									
rename  q3* s6_q3*_10_r									
rename  q4a_tk s6_q4a_10_r									
rename  q4b_tk s6_q4b_10_r									
save `t10_sec_6', replace									
 									
									
/*File t11_sec_6b:									
SECTION 6: PRICE AND WAGES (question 5) */									
use "$inputcom10\t11_sec_6b.dta", clear									
drop type 									
glo variables psu team div zl uz un mz s* w*									
foreach var in $variables{									
destring `var', replace force									
}									
									
rename w* s6_q5w*_10_r									
									
duplicates report psu team div zl uz un mz  s6sl1									
duplicates tag psu team div zl uz un mz  s6sl1, gen(indi)									
									
/*Observation with div=60 zl=61	 uz=72	un=15 mz=140 appears twice with female.  The second category is 
assumed	to be 2=male because in the file wages are usually higher for male in agricultural labour. */					
																	
replace  s6sl1=2 if  s6_q5wrp1_10_r==150 & div==60 & zl==61 & uz==72 & un==15 & mz==140									
drop indi									
reshape wide s6_*, i(psu team div zl uz un mz) j(s6sl1)  									
save `t11_sec_6b', replace									 									
									
									
/*Community Dataset*/	
*Division variable for community is taken from household databases. 
use "$input10/rt001.dta", clear	
tempfile division
keep psu region
rename region div
destring psu, replace
sort psu div
duplicates drop psu, force
save `division' , replace									
						
use `t1_sec_1', clear	
foreach file in t2_sec_1a t3_sec_2 t4_sec_3 t5_sec_4a t6_sec_4b t7_sec_4b1 t8_sec_4c t9_sec_5 t10_sec_6 t11_sec_6b {
noi di as error "`file'"
merge m:m psu team div zl uz un mz using ``file''
tab _m
drop _m
}

																
*Thana Geocode needs to be genenerated combining District code and Thana code									
gen thana2 = string(uz,"%02.0f")									
egen thana3 = concat(zl thana2)									
destring thana3, replace
rename thana3 thana2_10	
drop thana2

*Division variable for community is taken from household databases. 
drop div	
merge m:m psu using `division'
drop if _merge==2
drop _merge
rename (psu team div zl uz un mz) (psu_10 team_10 division_10 district_10 thana_10 union_10 mouza_10)									

gen s1_q8_10_r=.
replace s1_q8_10_r=1 if s1_q8_10_r_prog1!=. | s1_q8_10_r_prog2!=. | s1_q8_10_r_prog3!=. | s1_q8_10_r_prog4!=. | s1_q8_10_r_prog5!=. ///
| s1_q8_10_r_prog6!=. | s1_q8_10_r_prog7!=. | s1_q8_10_r_prog8!=. | s1_q8_10_r_prog9!=. | s1_q8_10_r_prog10!=. | s1_q8_10_r_prog11!=. ///
| s1_q8_10_r_prog12!=. | s1_q8_10_r_prog13!=.
replace s1_q8_10_r=2 if s1_q8_10_r==.
la de ngo 1"Grameen Bank" 2"Brac" 3"Proshika" 4"Asa" 5"Tmss" 6"Padakhep" 7"Aspada" 8"Basar" 9"Swanivar" ///
10"World Vision" 11"Solidarity" 12"Care" 13"Step" 14"Pally Unnayan" 15"Rdrs" 16"Caritus" 17"Danida" ///
18"Upakul" 19"Dakdeya Jai" 20"Uddipon" 21"Sheba" 22"Rupantar" 23"Bureau" 24"Akas" 25"Grameen Shakti" ///
26"Pusti" 27"Vosed" 28"Wave" 29"Other2010"
forval i=1/13{
la val s1_q8_10_r_ngo`i' ngo
decode s1_q8_10_r_ngo`i', gen(s1_q8_10_rngo`i')
}	
drop s1_q8_10_r_ngo*													
gen year=2010
order year psu_10 team_10 division_10 district_10 thana_10 thana2_10 union_10 mouza_10
label drop _all								
save community2010, replace									
									

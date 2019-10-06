/*****************************************************************************************************														
******************************************************************************************************														
**                                                                                                  **														
**                                    HARMONIZATION 2000                                            **														
**                                                                                                  **														
** COUNTRY	Bangladesh													
** COUNTRY ISO CODE	BGD													
** YEAR	2000													
** SURVEY NAME	HOUSEHOLD INCOME AND EXPENDITURE SURVEY 2000													
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS													
											
** Created	02/20/2015													
** Modified	12/19/2017													
                                                                                                    **														
******************************************************************************************************														
*****************************************************************************************************/														
/*This dofile harmonizes and merges datasets and variables for year 2000. 					
														
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
tempfile geo2000 individual2000 employment2000 enterprise2000 hh_s2_8_hhlist
agri01 household2000 agri02 agri03 agri04 agri05 agri06 agri07 agri08
agriculture2000 food12000 food22000 food32000 monthlynfood2000
hh_s9d_nfood02 hh_s9d_nfood03 hh_s9d_nfood03 annualnfood2000 durable2000
comm_section1 comm_section2 comm_section3 comm_section4 comm_section5
comm_section6 community2000
;
#d cr
   
/*****************************************************************************************************
*                                                                                                    *
                         *  ASSEMBLE WEIGHTS AND GEOGRAPHIC INFORMATION 
*                                                                                                    *
*****************************************************************************************************/
   
use "$input00/hh_s2_8_hhlist.dta", clear
keep hhcode division area region district thana uw mm hhwght weight urbrural class
rename (hhwght weight uw mm) (hhwgt popwgt union mouza)

/*Next lines create 16 stratum codes for year 2000.
To make division code of 2000 compatible with 2005 and 2010, create a new division code 60 
which is the sylhet division. */
rename division div
gen division=.
forval i=1/5{
replace division=`i'*10 if div==`i'
}
replace division=60 if region==90
drop div
gen stratum=. 
replace stratum=1 if division==10 & class==1 
replace stratum=2 if division==10 & class==2 
replace stratum=3 if division==20 & class==1 
replace stratum=4 if division==20 & class==2 
replace stratum=5 if division==20 & (class==4 | class==5) 
replace stratum=6 if division==30 & class==1 
replace stratum=7 if division==30 & class==2 
replace stratum=8 if division==30 & (class==4 | class==5)
replace stratum=9 if division==40 & class==1 
replace stratum=10 if division==40 & class==2 
replace stratum=11 if division==40 & (class==4 | class==5)
replace stratum=12 if division==50 & class==1 
replace stratum=13 if division==50 & class==2 
replace stratum=14 if division==50 & (class==4 | class==5) 
replace stratum=15 if division==60 & class==1 
replace stratum=16 if division==60 & class==2 

*Create Rangpur division, code 55
replace division=55 if inlist(region, 35, 85)

gen year=2000
#delimit;
glo geo00 year stratum hhwgt popwgt
urbrural division area region district thana union mouza;
#delimit cr 
order $geo00, after(hhcode)

foreach var of varlist stratum hhwgt popwgt urbrural division area region district thana union mouza class{
rename `var' `var'_00
}
drop class
save `geo2000', replace 
   
/*****************************************************************************************************														
*                                                                                                    *														
                                   * ASSEMBLE INDIVIDUAL DATABASE														
*                                                                                                    *														
*****************************************************************************************************/														
/*File hh_s1_3_4_plist: 														
Section 1: HOUSEHOLD ROSTER														
Section 2: EDUCATION														
Section 3: HEALTH */														
														
use "$input00/hh_s1_3_4_plist.dta", clear
sort hhcode psu idcode														
												
rename sex      s1a_q2_00_r														
rename relation s1a_q3_00_r														
rename age      s1a_q4_00_r														
rename religion s1a_q5_00_r														
rename mstatus  s1a_q6_00_r														
rename spouseid  s1a_q7_00_r														
rename fatherid  s1a_q8_00_r														
rename motherid  s1a_q9_00_r														
														
rename s1b0#   s1b_q#_00_r														
rename s3a0#   s3a_q#_00_r														
rename s3b0#   s3b_q#_00_r														
rename s3b08*  s3b_q8*_00_r														
rename s4a0#*  s4a_q#*_00_r														
rename s4a#*   s4a_q#*_00_r														
rename s4b0#*  s4b_q#*_00_r														
rename s4c0#*  s4c_q#*_00_r														
rename s4c#*   s4c_q#*_00_r	

*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop _m
rename idcode indid		
drop hhid
rename hhcode hhid

glo id psu hhid indid
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save individual2000, replace


/*****************************************************************************************************
*                                                                                                    *
                                  * ASSEMBLE EMPLOYMENT DATABASE
*                                                                                                    *
*****************************************************************************************************/
																												
/*File activity:														
SECTION 5: ECONOMIC ACTIVITIES AND WAGE EMPLOYMENT														
PART A: ACTIVITIES (ALL PERSONS 5 YEARS AND OLDER), PART B:WAGE EMPLOYMENT */ 														
														
use "$input00/activity.dta", clear
sort hhcode psu idcode
rename activity activity2														
encode activity2, gen(activity)														
drop activity2														
rename s5a0#*  s5a_q#*_00_r														
rename s5b0#*  s5b_q#*_00_r														
rename s5b#*  s5b_q#*_00_r														

*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
rename idcode indid		
drop hhid
rename hhcode hhid

glo id psu hhid indid activity
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save employment2000, replace
																																										

/*****************************************************************************************************														
*                                                                                                    *														
                                   * ASSEMBLE HOUSEHOLD DATABASE														
*                                                                                                    *														
*****************************************************************************************************/														
/*File hh_s2_8_hhlist:														
SECTION 0: COVER														
SECTION 2: HOUSING														
SECTION 8: OTHER ASSETS AND INCOME  */ 														
														
use "$input00/hh_s2_8_hhlist.dta", clear
rename s20#  s2_q#_00_r														
rename s2#  s2_q#_00_r														
rename s8a0#  s8a_q#_00_r														
rename s8a#  s8a_q#_00_r														
rename s8b0#  s8b_q#_00_r														
rename s8b#*  s8b_q#*_00_r	
order psu hhcode													
save `hh_s2_8_hhlist', replace														
clear														
																																								
/*File agri01:														
SECTION 7: AGRICULTURE,	PART A: LANDHOLDING  */													
														
use "$input00/agri01.dta", clear														
destring hhid, replace force														
rename s7a0#  s7a_q#_00_r														
sort psu hhcode	
order psu hhid													
save `agri01', replace														
clear														
																											
/*Household Dataset*/														
use `hh_s2_8_hhlist', clear														
merge m:m hhcode using `agri01', nogenerate														

gen year=2000	
drop hhid												
rename (hhcode uw mm hhwght weight)(hhid union mouza hhwgt popwgt)	

/*Next lines create 16 stratum codes for year 2000.
To make division code of 2000 compatible with 2005 and 2010, create a new division code 6 
which is the sylhet division. */
rename division div
gen division=.
forval i=1/5{
replace division=`i'*10 if div==`i'
}
replace division=60 if region==90
drop div
gen stratum=. 
replace stratum=1 if division==10 & class==1 
replace stratum=2 if division==10 & class==2 
replace stratum=3 if division==20 & class==1 
replace stratum=4 if division==20 & class==2 
replace stratum=5 if division==20 & (class==4 | class==5) 
replace stratum=6 if division==30 & class==1 
replace stratum=7 if division==30 & class==2 
replace stratum=8 if division==30 & (class==4 | class==5)
replace stratum=9 if division==40 & class==1 
replace stratum=10 if division==40 & class==2 
replace stratum=11 if division==40 & (class==4 | class==5)
replace stratum=12 if division==50 & class==1 
replace stratum=13 if division==50 & class==2 
replace stratum=14 if division==50 & (class==4 | class==5) 
replace stratum=15 if division==60 & class==1 
replace stratum=16 if division==60 & class==2 
																							
*Create Rangpur division
replace division=55 if inlist(region, 35, 85)
												
glo variables psu hhid stratum hhwgt popwgt urbrural division area region district thana union mouza ///
class team month dc  ///
fexptot ndays nweeks fexp nfexp hhexp pcexp quintile nfood1 nfood2 nfood3 hhsize lclass oclass 														
order $variables
foreach var in $variables{														
rename `var' `var'_00														
}														
order year															
save household2000, replace														
																												exit	

/*****************************************************************************************************
*                                                                                                    *
                            * ASSEMBLE NON-AGRICULTURAL ENTERPRISES DATABASE
*                                                                                                    *
*****************************************************************************************************/					

/*File hh_s6_business:														
SECTION 6:  NON-AGRICULTURAL ENTERPRISES   */ 														
														
use "$input00/hh_s6_business.dta", clear
rename s60(#)*  s6_q(#)*_00_r
rename s6(#)*  s6_q(#)*_00_r	
rename business enterprise													
	
*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
drop hhid
rename hhcode hhid

glo id psu hhid enterprise
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save enterprise2000, replace
																													
/*****************************************************************************************************														
*                                                                                                    *														
                                   * ASSEMBLE AGRICULTURE DATABASE														
*                                                                                                    *														
*****************************************************************************************************/														
/*File agri02:														
SECTION 7: AGRICULTURE,	PART B: CROP PRODUCTION */									
														
use "$input00/agri02.dta", clear														
destring hhid, replace 														
rename s7b0#*  s7b_q#*_00_r																								
sort psu hhcode	cropcode
rename cropcode code
gen type=1	
order type, after(code)	
order psu											
save `agri02', replace														
														
														
/*Files agri03, agri04, agri05, agri06:														
SECTION 7: AGRICULTURE,	PART C: NON-CROP ACTIVITIES */														
														
use "$input00/agri03.dta", clear														
destring hhid, replace 														
rename s7c0#*  s7c_q#*_00_r																												
sort psu hhcode	animcode
rename animcode code
gen type=2	
order type, after(code)
order psu																														
save `agri03', replace														
														
														
use "$input00/agri04.dta", clear														
destring hhid, replace 														
rename s7c0#*  s7c_q#*_00_r	
rename (s7c_q1a_00_r s7c_q1b_00_r s7c_q2a_00_r s7c_q2b_00_r s7c_q3a_00_r s7c_q3b_00_r)  ///
(s7c_q6a_00_r s7c_q6b_00_r s7c_q7a_00_r s7c_q7b_00_r s7c_q8a_00_r s7c_q8b_00_r)																											
sort psu hhcode	prodcode
rename prodcode code
gen type=3
order type, after(code)
order psu																									
save `agri04', replace														
														
														
use "$input00/agri05.dta", clear														
destring hhid, replace 														
rename s7c0#*  s7c_q#*_00_r	
rename ( s7c_q1a_00_r s7c_q1b_00_r s7c_q2a_00_r s7c_q2b_00_r s7c_q3a_00_r s7c_q3b_00_r) ///
(s7c_q10a_00_r s7c_q10b_00_r s7c_q11a_00_r s7c_q11b_00_r s7c_q12a_00_r s7c_q12b_00_r)																										
sort psu hhcode	scode
rename scode code
gen type=4	
order type, after(code)
order psu																								
save `agri05', replace														
														
														
use "$input00/agri06.dta", clear														
destring hhid, replace 														
rename s7c0#*  s7c_q#*_00_r	
rename (s7c_q1a_00_r s7c_q1b_00_r s7c_q2_00_r s7c_q3_00_r) ///
( s7c_q14a_00_r s7c_q14b_00_r s7c_q15_00_r s7c_q16_00_r)																									
sort psu hhcode	treecode
rename treecode code
gen type=5
order type, after(code)	
order psu																								
save `agri06', replace														
														
														
/*File agri07:														
SECTION 7: AGRICULTURE, PART D: EXPENSES ON AGRICULTURAL INPUTS */																												
														
use "$input00/agri07.dta", clear														
destring hhid, replace 														
rename s7d0#*  s7d_q#*_00_r																												
sort psu hhcode expcode
rename expcode code
gen type=6	
order type, after(code)	
order psu																								
save `agri07', replace														
														
														
/*File agri08:														
SECTION 7: AGRICULTURE,	PART E: AGRICULTURAL ASSETS */		
												
use "$input00/agri08.dta", clear														
destring hhid, replace 														
rename s7e0#*  s7e_q#*_00_r																											
sort psu hhcode assetcd
rename assetcd code
gen type=7	
order type, after(code)	
order psu																								
save `agri08', replace														
														

/*Agriculture Dataset*/	
														
use `agri02', clear														
forval i=2/8{														
append using `agri0`i''													
}			

*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
drop hhid
rename hhcode hhid

glo id psu hhid code type
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save agriculture2000, replace

	
/*****************************************************************************************************														
*                                                                                                    *														
                                   * ASSEMBLE FOOD DATABASES														
*                                                                                                    *														
*****************************************************************************************************/														
/*File hh_s9a_food01:														
SECTION 9:  CONSUMPTION, PART A: DAILY CONSUMPTION */													
																																									
use "$input00/hh_s9a_food01.dta", clear	
rename (date nboys nmen ngirls nwomen)(date_00 nboys_00 nmen_00 ngirls_00 nwomen_00) 

*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
drop hhid
rename hhcode hhid

glo id psu hhid day
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save food12000, replace														
  														
														
/*File hh_s9a_food02:														
SECTION 9:  CONSUMPTION, PART A: DAILY CONSUMPTION */																										
														
use "$input00/hh_s9a_food02.dta", clear														
rename (quantity value source) (quantity_00 value_00 source_00) 	
																									
*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
drop hhid
rename hhcode hhid

glo id psu hhid day foodcode
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save food22000, replace														
														
														
/*File hh_s9a_food03:														
SECTION 9: CONSUMPTION, PART B: WEEKLY CONSUMPTION */																											
														
use "$input00/hh_s9b_food03", clear														
rename (quantity value source)(quantity_00 value_00 source_00) 

*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
drop hhid
rename hhcode hhid

glo id psu hhid week foodcode
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save food32000, replace																																										
														
/*****************************************************************************************************														
*                                                                                                    *														
                                   * ASSEMBLE NON-FOOD DATABASE														
*                                                                                                    *														
*****************************************************************************************************/														
/*File hh_s9c_nfood01:														
SECTION 9:  CONSUMPTION, PART C:  MONTHLY NON-FOOD EXPENDITURE	*/																									
														
use "$input00/hh_s9c_nfood01.dta", clear														
sort psu hhcode itemcode
rename itemcode code
rename (purchase homegift totvalue)(s9c_q1_00_r s9c_q2_00_r s9c_q3_00_r)

*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
drop hhid
rename hhcode hhid

glo id psu hhid code
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save monthlynfood2000, replace														
														
														
/*File hh_s9c_nfood02:														
SECTION 9:  CONSUMPTION	PART D1: ANNUAL NON-FOOD EXPENDITURE */																										
														
use "$input00/hh_s9d_nfood02.dta", clear														
sort psu hhcode itemcode
order psu
rename itemcode code
rename (quantity value)(s9d_q1_00_r s9d_q2_00_r)																											
save `hh_s9d_nfood02', replace														
														
														
/*File hh_s9c_nfood03:														
SECTION 9:  CONSUMPTION, PART D2: ANNUAL NON-FOOD EXPENDITURE */																																										
use "$input00/hh_s9d_nfood03.dta", clear														
sort psu hhcode itemcode
order psu 
rename itemcode code
rename value s9d_q2_00_r																	
save `hh_s9d_nfood03', replace														
														
														
use `hh_s9d_nfood02', clear														
append using `hh_s9d_nfood03 '

*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
drop hhid
rename hhcode hhid

glo id psu hhid code
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00	
save annualnfood2000, replace 

														
/*****************************************************************************************************														
*                                                                                                    *														
                                   * ASSEMBLE DURABLE DATABASE														
*                                                                                                    *														
*****************************************************************************************************/																										
/*File hh_s9e_durables:														
SECTION 9:  CONSUMPTION, PART E: INVENTORY OF CONSUMER DURABLE GOODS */																											
														
use "$input00/hh_s9e_durables.dta", clear																											
sort psu hhcode	itemcode
rename itemcode code
rename (number value)(s9e_q2_00_r s9e_q3_00_r)

*Getting Geographical information and weights
merge m:1 hhcode using `geo2000'
tab _m
drop if _m==2
drop _m
drop hhid
rename hhcode hhid

glo id psu hhid code
foreach var in $id{
rename `var' `var'_00
}	
order year $id $geo00
save durable2000, replace
														
													
/*****************************************************************************************************														
*                                                                                                    *														
                                   * ASSEMBLE COMMUNITY DATABASE														
*                                                                                                    *														
*****************************************************************************************************/														
														
/*Questions 3 and 4 from section 1:General Information and Economic Activities are not in the database*/																											
														
forval i = 1/6{														
    use "$inputcom00/comm_section`i'.dta", clear														
	rename s`i'0(#)*  s`i'_q(#)*_00_r													
	sort psu	
	save `comm_section`i'', replace													 													
	}	
	
*Section 2, qestion 1: percentages in year 2000 are organized to harmonize with year 2010
use `comm_section2', clear
tempfile grain	
keep psu  s2_q1a_00_r s2_q1b_00_r s2_q1c_00_r s2_q1d_00_r s2_q1e_00_r 
rename (s2_q1a_00_r s2_q1b_00_r s2_q1c_00_r s2_q1d_00_r s2_q1e_00_r )(p1 p2 p3 p4 p5)	
reshape long p, i(psu) j(cropcode)
gsort +psu - p
by psu: gen position = sum(p != p[_n-1]) 
drop p
sort psu cropcode
reshape wide position, i(psu) j(cropcode)
rename (position1 position2 position3 position4 position5)(s2_q1a_00_r s2_q1b_00_r s2_q1c_00_r s2_q1d_00_r s2_q1e_00_r )
label variable s2_q1a_00_r ""
label variable s2_q1b_00_r ""
label variable s2_q1c_00_r ""
label variable s2_q1d_00_r ""
label variable s2_q1e_00_r ""
save `grain', replace

use `comm_section2', clear
merge 1:1 psu using `grain',  replace update nogenerate
save `comm_section2', replace

	
use "$input00/hh_s2_8_hhlist.dta", clear														
tempfile geoinfo									
keep psu division area region district thana uw mm 
duplicates drop psu, force									
save `geoinfo' , replace
								

use `comm_section1', clear	
label drop _all																																													
merge 1:1 psu using `geoinfo'									
drop if _merge==2									
drop _merge														
														
forval i = 2/6{														
    merge 1:1 psu using `comm_section`i'', nogenerate 														
   }														
														
*ssc install nsplit														
nsplit V2, digits(3 2 2) gen(ps2 team month)														
drop ps2	
rename (uw mm) (union mouza)

/*To make division code of 2000 compatible with 2005 and 2010, create a new division code 6 
which is the sylhet division. */
replace division=6 if region==90
																								
glo variables psu V2  division area region district thana union mouza team month														
foreach var in $variables{														
rename `var' `var'_00														
}														
rename  s310  s3_q10_00_r
glo variables  s1_q7a2_00_r s1_q7b2_00_r s1_q7c2_00_r s1_q7d2_00_r s1_q7e2_00_r s1_q7f2_00_r s1_q7g2_00_r s1_q7h2_00_r s1_q7i2_00_r s1_q7j2_00_r
foreach var in $variables{
label define `var' 1"Grameen Bank" 2"Brac" 3"Proshika" 4"Caritas" 5"Asha" 6 "Other2000"
la val `var' `var'
}

foreach var in $variables{
decode `var', gen(`var'ngo)
}
drop $variables
rename s1_q7*ngo s1_q7*
gen year=2000
order year psu_00 V2_00 team_00 month_00 division_00 region_00 district_00 thana_00 union_00 mouza_00 area_00
save community2000, replace																												
														

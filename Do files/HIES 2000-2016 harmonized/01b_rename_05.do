/*****************************************************************************************************											
******************************************************************************************************											
**                                                                                                  **											
**                                    HARMONIZATION 2005                                            **											
**                                                                                                  **											
** COUNTRY	Bangladesh										
** COUNTRY ISO CODE	BGD										
** YEAR	2005										
** SURVEY NAME	HOUSEHOLD INCOME AND EXPENDITURE SURVEY 2005										
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS										
									
** Created	02/23/2015										
** Modified	12/19/2017										
                                                                                                    **											
******************************************************************************************************											
*****************************************************************************************************/											
/*This dofile harmonizes and merges datasets and variables for year 2005. 										
														
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
tempfile geo2005 s1a s1b s3a s3b1 s3b2 s4a1 s4a2 s4a3 s4b s4c individual2005 s5a s5b employment2005 
s8c1 s8c2 s8c3 s8c s61 s62 enterprise2005 s2 s7a s8a s8b household2005 s7b s7c1 s7c2 s7c3 
s7c4 s7d s7e agriculture2005 food12005 food22005 food32005 monthlynfood2005 s9d1 s9d2 
annualnfood2005 durable2005 s0 s1 s2 s3 s4 s5 s6 community2005       
;
#d cr
 
   
/*****************************************************************************************************
*                                                                                                    *
                         *  ASSEMBLE WEIGHTS AND GEOGRAPHIC INFORMATION 
*                                                                                                    *
*****************************************************************************************************/   
  
*Getting Geographical information
use "$input05/s0.dta", clear

*Variable population weights come from file consumption_00_05_10.dta
preserve
use "$input05/consumption_00_05_10", clear
keep if year==2
destring id, replace
gen hhold= string(id,"%0010.0f")
tempfile cons
save `cons'
restore

merge 1:1 hhold using `cons', keepusing(popwgt)
tab _m
drop _m

merge m:1 hhold using "$input05/s2.dta", keepusing(div stratum wgt)
tab _m
drop _m	

destring div,replace
rename (div reg dis tha  wgt)(division region district thana hhwgt)

*Create Rangpur division
replace division=55 if inlist(region, 35, 85)

				
*Next thana codes need to be genenerated combining District code and Thana code																
gen indi=1 if tha==7 | tha==14 | tha==36  | tha==46 | tha==58 | tha==65 | tha==70 | tha==77 | tha==91	 	 	 	 	 	 	 				
gen thana2 = string(tha,"%02.0f") if indi==1											
egen thana3 = concat(district thana2) if indi==1											
destring thana3, replace	 										
drop thana2											
replace thana=thana3 if indi==1											
drop thana3 indi	

/*In 2005 household with hhid 802715181 has a district code=46 and Thana code=7670 which is not equivalent 																																					
to a Thana geo-code(first number:district, second number:Thana code), we change Thana code to 4670*/																																					
replace thana=4670 if thana==7670 

*Mistakes in the upazila codification
replace thana=391  if thana==397 																																				
replace thana=4665 if thana==4646 

*Mistakes in the division and district codification
replace div=20 if div==.
replace district=49 if hhold=="4651313152"
replace district=84 if hhold=="0962712028"

*Create PSU variable. Psu is 7 digits of the household id (See community databases)
gen psu=substr(hhold,1,7)

drop rec_type
gen year=2005
#delimit;
glo geo05 year stratum hhwgt popwgt
rmo division region district thana ;
#delimit cr 
order $geo05, after(hhold)
order psu, before(hhold)

foreach var of varlist stratum hhwgt popwgt rmo division region district thana  {
rename `var' `var'_05
}	
save `geo2005', replace    

																						
/*****************************************************************************************************											
*                                                                                                    *											
                                   * ASSEMBLE INDIVIDUAL DATABASE											
*                                                                                                    *											
*****************************************************************************************************/											
/*File s1a:											
SECTION 1: HOUSEHOLD INFORMATION ROSTER, PART A: HOUSEHOLD INFORMATION  */											
											
use "$input05/s1a.dta", clear											
					
**********************Correction to household head variable*********************

*Household heads
gen head=(q03_1a==1) if q03_1a!=.
bys hhold: egen heads=total(head) 

egen hh=tag(hhold)
tab heads if hh==1


*Maximum age inside the household
bys hhold: egen maxage=max(q04_1a)
gen oldest=(q04_1a==maxage)


*Male married
gen malemarried=(q06_1a==1 & q02_1a==1)


*new household head variable
gen p=.
gen headnew=.
replace headnew=1 if head==1 & heads==1


*Highest age and male married (No cases)

*Male married
replace p=1 if  heads==0 &  malemarried==1
bys hhold: egen heads2=total(p)
tab heads2 if hh==1
replace headnew=p if heads2==1
replace heads=heads2 if heads2==1
tab heads if hh==1

**Male with highest age (No cases)


**Female with highest age
cap drop heads2
replace p=.
replace p=1 if heads==0  & oldest==1 & q02_1a==2 
bys hhold: egen heads2=total(p)
tab heads2 if hh==1
replace headnew=p if heads2==1
replace heads=heads2 if heads2==1
tab heads if hh==1

*Correct relationship of members with the head of household variable
replace q03_1a=1 if headnew==1 
 
  
drop rec_type											
rename q0(#)*  s1a_q(#)_05_r											
rename q10*   s1a_q10_05_r											
sort hhold idc						
save `s1a', replace																				
										
/*File s1b:											
SECTION 1: HOUSEHOLD INFORMATION ROSTER, PART B: EMPLOYMENT INFORMATION */											
											
use "$input05/s1b.dta", clear											
drop rec_type											
rename q0(#)*  s1b_q(#)_05_r											
sort hhold idc	
/*5 observations appear twice with different information. 5 observations are deleted randomly. 
5 observations appear twice with the same information. 5 observations are deleted*/										
duplicates report hhold idc 	
duplicates drop hhold idc, force														
save `s1b', replace											
																				
/*File s3a:											
SECTION 3: EDUCATION, PART A: LITERACY AND EDUCATIONAL ATTAINMENT */											
											
use "$input05/s3a.dta", clear											
drop rec_type sex age											
rename q0(#)*  s3a_q(#)_05_r											
sort hhold idc	
/*4 observations appear twice with different information. 4 observations are deleted randomly.
4 observations appear twice with the same information. 4 observations are deleted*/								
duplicates report hhold idc 										
duplicates drop hhold idc, force											
save `s3a', replace											
																														
/*File s3b1:											
SECTION 3: EDUCATION, PART B1: CURRENT ENROLLMENT */											
											
use "$input05/s3b1.dta", clear											
drop rec_type sex age											
rename q0(#)*  s3b1_q(#)_05_r											
sort hhold idc
/*6 observations appear twice with different information. 6 observations are deleted randomly. 
21 observations appear twice with the same information. 21 observations are deleted*/											
duplicates report hhold idc 											
duplicates drop hhold idc, force																					
save `s3b1', replace											
																						
/*File s3b2:											
SECTION 3: EDUCATION, PART B2: CURRENT ENROLLMENT */											
											
use "$input05/s3b2.dta", clear											
drop rec_type											
rename *_3b2 *											
rename q0(#)* s3b2_q(#)*_05_r											
sort hhold idc											
save `s3b2', replace											
																					
/*File s4a1:											
SECTION 4: HEALTH, PART A1: ILLNESSES AND INJURIES */											
											
use "$input05/s4a1.dta", clear											
drop rec_type q02_1a q04_1a	wgt rmo stratum div	up									
rename *_4a1 *											
rename q0(#)*  s4a1_q(#)*_05_r											
sort hhold idc
/*6 observations appear twice with the same information. 6 observations are deleted*/											
duplicates report hhold idc 											
duplicates drop hhold idc, force											
save `s4a1', replace																						
											
/*File s4a2:											
SECTION 4:HEALTH, PART A2:ILLNESSES AND INJURIES 											
*/											
											
use "$input05/s4a2.dta", clear											
drop rec_type q02_1a q04_1a	wgt rmo stratum div	up										
rename *_4a2 *											
rename q0(#)*     s4a2_q(#)*_05_r											
rename q(#)*      s4a2_q(#)*_05_r											
sort hhold idc
save `s4a2', replace																						
											
/*File s4a3:											
SECTION 4: HEALTH, PART A3: ILLNESSES AND INJURIES  */											
											
use "$input05/s4a3.dta", clear											
drop rec_type											
rename *_4a3 *											
rename q(#)* s4a3_q(#)*_05_r											
sort hhold idc											
save `s4a3', replace																						
											
/*File s4b:											
SECTION 4:HEALTH, PART B:CHILD HEALTH AND IMMUNIZATION  */											
											
use "$input05/s4b.dta", clear											
drop rec_type											
rename *_4b *											
rename q0(#)* s4b_q(#)*_05_r											
sort hhold idc											
save `s4b', replace																						
											
/*File s4c:											
SECTION 4:HEALTH, PART C:PRE- AND POST-NATAL CARE */											
											
use "$input05/s4c.dta", clear											
drop rec_type											
rename *_4c *											
rename q0(#)* s4c_q(#)*_05_r											
rename q(#)* s4c_q(#)*_05_r											
sort hhold idc											
save `s4c', replace												
								
				
use `s1a', clear
sort hhold idc	
foreach file in s1b s3a s3b1 s3b2 s4a1 s4a2 s4a3 s4b s4c {
merge 1:1 hhold idc using ``file''
tab _m
drop _m
}

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold idc, replace
rename (hhold idc) (hhid indid)

glo id psu hhid indid
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05
save individual2005, replace


/*****************************************************************************************************
*                                                                                                    *
                                  * ASSEMBLE EMPLOYMENT DATABASE
*                                                                                                    *
*****************************************************************************************************/
																		
/*File s5a:											
SECTION 5:ECONOMIC ACTIVITIES AND WAGE EMPLOYMENT, PART A: ACTIVITIES */											
											
use "$input05/s5a.dta", clear											
drop rec_type div rmo stratum wgt up											
encode as, gen(activity)											
drop as											
rename *_5a *											
rename q0(#)* s5a_q(#)*_05_r											
sort hhold idc	
save `s5a', replace											
																				
/*File s5b:											
SECTION 5: ECONOMIC ACTIVITIES AND WAGE EMPLOYMENT, PART B: WAGE EMPLOYMENT */											
											
use "$input05/s5b.dta", clear											
drop rec_type											
rename *_5b *											
rename q0(#)* s5b_q(#)*_05_r											
sort hhold idc											
encode as, gen(activity)											
drop as	
order hhold idc activity
/*1 observation appears twice with the same information. 1 observation is deleted*/																				
duplicates report hhold idc activity											
duplicates drop hhold idc activity, force												
save `s5b', replace											
	

use `s5a', clear										
merge 1:1 hhold idc activity using `s5b' 											
tab  _m
drop _m		

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold idc, replace
rename (hhold idc) (hhid indid)

glo id psu hhid indid activity
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05
save employment2005, replace	


/*****************************************************************************************************
*                                                                                                    *
                              * ASSEMBLE SAFETY NETS PROGRAMMES DATABASE
*                                                                                                    *
*****************************************************************************************************/
										
/*File s8c1:											
SECTION 8:OTHER ASSETS AND INCOME, PART C: SOCIAL SAFETY NETS PROGRAMME (questions 1 to 8)*/											
											
use "$input05/s8c1.dta", clear											
drop if sl=="0"											
drop  q10a_8c2 rec_type div rmo stratum wgt	up										
rename *_8c1 *											
rename q0(#)* s8c_q(#)*_05_r											
sort hhold sl	
save `s8c1', replace																					
											
/*File s8c2:											
SECTION 8:OTHER ASSETS AND INCOME, PART C: SOCIAL SAFETY NETS PROGRAMME (questions 9 to 18)*/											
											
use "$input05/s8c2.dta", clear											
drop rec_type ccf											
rename *_8c2 *											
rename q0(#)* s8c_q(#)*_05_r											
rename q(#)*  s8c_q(#)*_05_r											
sort hhold sl											
save `s8c2', replace																					
											
/*File s8c3:											
SECTION 8:OTHER ASSETS AND INCOME, PART C: SOCIAL SAFETY NETS PROGRAMME (questions 19 to 22)*/											
											
use "$input05/s8c3.dta", clear											
drop rec_type											
rename *_8c3 *											
rename q(#)* s8c_q(#)*_05_r											
sort hhold sl											
save `s8c3', replace																					
											
use `s8c1',replace											
merge m:m hhold sl using `s8c2', nogenerate											
merge m:m hhold sl using `s8c3', nogenerate											
save `s8c', replace	

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold sl, replace
rename hhold hhid

glo id psu hhid sl 
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05
save "$output/safety2005.dta", replace


									
/*****************************************************************************************************											
*                                                                                                    *											
                                   * ASSEMBLE HOUSEHOLD DATABASE											
*                                                                                                    *											
*****************************************************************************************************/											
/*File s2:											
SECTION 6:  HOUSING */											
											
use "$input05/s2.dta", clear
destring rmo, replace																				
drop rec_type
rename q0(#)*  s2_q(#)_05_r											
rename q#*  s2_q#_05_r																						
sort hhold 	
order hhold wgt rmo stratum div										
save `s2', replace											
																																											
/*File s7a:											
SECTION 7: AGRICULTURE, PART A: LANDHOLDING  */											
											
use "$input05/s7a.dta", clear											
drop rec_type											
rename *_7a *											
rename q0(#)* s7_q(#)*_05_r											
sort hhold 											
save `s7a', replace											
	
	
/*File s8a: 											
SECTION 8: OTHER ASSETS AND INCOME, PART A: OTHER PROPERTY AND ASSETS  */											
											
use "$input05/s8a.dta", clear											
drop rec_type											
rename *_8a *											
rename q0(#)* s8a_q(#)*_05_r											
rename q(#)* s8a_q(#)*_05_r											
sort hhold 											
save `s8a', replace											
											
											
/*File s8B:											
SECTION 8:OTHER ASSETS AND INCOME, PART B:OTHER INCOME  */											
											
use "$input05/s8b.dta", clear											
drop rec_type											
rename *_8b *											
rename q0(#)* s8b_q(#)*_05_r											
rename q(#)* s8b_q(#)*_05_r											
sort hhold 											
save `s8b', replace											
										
																						
/*Household Dataset*/
											
use "$input05/s0", clear	
drop rec_type											
merge m:m hhold  using `s2'
tab _m				
drop _m																		
merge m:m hhold  using `s7a'	
tab _m
drop _m										
merge m:m hhold  using `s8a'
tab _m
drop _m											
merge m:m hhold  using `s8b'
tab _m
drop if _m==2
drop _m	

*Create PSU variable. Psu is 7 digits of the household id (See community databases)
gen psu=substr(hhold,1,7)	

*get population weights
merge m:1 hhold using `geo2005', keepusing(popwgt)
tab _m
drop _m
	
destring div, replace
rename (hhold reg dis tha div wgt) (hhid region district thana division hhwgt)	

*Create Rangpur division
replace division=55 if inlist(region, 35, 85)										

*Next thana codes need to be genenerated combining District code and Thana code																
gen indi=1 if tha==7 | tha==14 | tha==36  | tha==46 | tha==58 | tha==65 | tha==70 | tha==77 | tha==91	 	 	 	 	 	 	 				
gen thana2 = string(tha,"%02.0f") if indi==1											
egen thana3 = concat(district thana2) if indi==1											
destring thana3, replace	 										
drop thana2											
replace thana=thana3 if indi==1											
drop thana3 indi	

/*In 2005 household with hhid 802715181 has a district code=46 and Thana code=7670 which is not equivalent 																																					
to a Thana geo-code(first number:district, second number:Thana code), we change Thana code to 4670*/																																					
replace thana=4670 if thana==7670 

*Mistakes in the upazila codification
replace thana=391  if thana==397 																																				
replace thana=4665 if thana==4646 

destring psu hhid, replace
order psu hhid hhwgt popwgt region division district thana  rmo stratum 
															
glo variables  psu hhid region district thana rmo  division stratum hhwgt											
foreach var in $variables{											
rename `var' `var'_05											
}											
gen year=2005
order year											
save household2005, replace											
																												exit											  										
/*****************************************************************************************************
*                                                                                                    *
                            * ASSEMBLE NON-AGRICULTURAL ENTERPRISES DATABASE
*                                                                                                    *
*****************************************************************************************************/											

/*File s61:											
SECTION 6:  NON-AGRICULTURAL ENTERPRISES  */											
											
use "$input05/s61.dta", clear											
drop rec_type											
rename *_61 *											
rename q0(#)* s6_q(#)*_05_r											
rename q(#)* s6_q(#)*_05_r	
sort hhold 											
save `s61', replace											
																						
use "$input05/s62.dta", clear											
drop rec_type											
rename *_62 *											
rename q(#)* s6_q(#)*_05_r											
sort hhold 								
save `s62', replace	

use `s61', clear
merge 1:1 hhold en using `s62'
tab _m
drop _m

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold en, replace
rename (hhold en) (hhid enterprise)

glo id psu hhid enterprise 
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05
save enterprise2005, replace		
																						
/*****************************************************************************************************											
*                                                                                                    *											
                                   * ASSEMBLE AGRICULTURE DATABASE											
*                                                                                                    *											
*****************************************************************************************************/											
/*File s7b:											
SECTION 7: AGRICULTURE, PART B: CROP PRODUCTION	*/										
																							
use "$input05/s7b.dta", clear
drop rec_type
rename *_7b *											
rename q0(#)* s7b_q(#)*_05_r																																
sort hhold ccbp
rename ccbp code
gen type=1
order type, after(code)											
save `s7b', replace											
										
											
/*File s7c1, s7c2, s7c3, s7c4											
SECTION 7: AGRICULTURE, PART C: NON-CROP ACTIVITIES	*/										
																
use "$input05/s7c1.dta", clear											
drop rec_type
rename *_7c1 *									
rename q0(#)* s7c_q(#)*_05_r											
/*1 observation appears twice with the same information. 1 observation is deleted*/																				
duplicates report hhold anc											
duplicates drop hhold anc, force																						
sort hhold 	anc
rename anc code	
gen type=2
order type, after(code)																				
save `s7c1', replace											
											
											
use "$input05/s7c2.dta", clear											
drop rec_type
rename *_7c2 *											
rename q0(#)* s7c_q(#)*_05_r
rename (s7c_q1a_05_r s7c_q1b_05_r s7c_q2a_05_r s7c_q2b_05_r s7c_q3a_05_r s7c_q3b_05_r) ///
(s7c_q6a_05_r s7c_q6b_05_r s7c_q7a_05_r s7c_q7b_05_r s7c_q8a_05_r s7c_q8b_05_r)																																
sort hhold apc
rename apc code	
gen type=3	
order type, after(code)																													
save `s7c2', replace											
											
											
use "$input05/s7c3.dta", clear											
drop rec_type
rename *_7c3 *											
rename q0(#)* s7c_q(#)*_05_r
rename (s7c_q1a_05_r s7c_q1b_05_r s7c_q2a_05_r s7c_q2b_05_r s7c_q3a_05_r s7c_q3b_05_r) ///
(s7c_q10a_05_r s7c_q10b_05_r s7c_q11a_05_r s7c_q11b_05_r s7c_q12a_05_r s7c_q12b_05_r)																																	
sort hhold soc
rename soc code
gen type=4	
order type, after(code)																																					
save `s7c3', replace											
											
											
use "$input05/s7c4.dta", clear											
drop rec_type
rename *_7c4 *											
rename q0(#)* s7c_q(#)*_05_r
/*2 observations appear twice with the same information. 2 observations are deleted*/																				
duplicates report hhold trc											
duplicates drop hhold trc, force
rename (s7c_q1a_05_r s7c_q1b_05_r s7c_q2_05_r s7c_q3_05_r) ///
(s7c_q14a_05_r s7c_q14b_05_r s7c_q15_05_r s7c_q16_05_r)																					
sort hhold trc
rename trc code
gen type=5
order type, after(code)																																																
save `s7c4', replace											
											
											
/*File s7d:											
SECTION 7:  AGRICULTURE, PART D: EXPENSES ON AGRICULTURAL INPUTS  */																					
											
use "$input05/s7d.dta", clear											
drop rec_type
rename *_7d *											
rename q0(#)* s7d_q(#)*_05_r																																	
sort hhold exc
rename exc code
gen type=6
order type, after(code)																																																
save `s7d', replace											
											
											
/*File s7e:											
SECTION 7: AGRICULTURE,  PART E: AGRICULTURAL ASSETS */																						
											
use "$input05/s7e.dta", clear										
drop rec_type
rename *_7e *											
rename q0(#)* s7e_q(#)*_05_r																															
sort hhold fac
rename fac code
gen type=7		
order type, after(code)																																													
save `s7e', replace											
		

/*Agriculture Dataset*/		
															
use	`s7b', clear
forval i=1/4{														
append using `s7c`i''														
}																			
append  using `s7d'											
append  using `s7e'	


*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold code, replace
rename hhold hhid

glo id psu hhid code type
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05
save agriculture2005, replace
																				
																															
/*****************************************************************************************************											
*                                                                                                    *											
                                   * ASSEMBLE FOOD DATABASES											
*                                                                                                    *											
*****************************************************************************************************/											
/*File s9a1											
SECTION 9:CONSUMPTION, PART A:DAILY CONSUMPTION	*/																					
											
use "$input05/s9a1.dta", clear																						
drop rec_type
/*Household with id:2632004188 in Day:2 appears twice with different information. One of these 
observations is deleted randomly */
duplicates report hhold day
duplicates drop hhold day, force
rename (date nboy nmen ngir nwom) (date_05 nboys_05 nmen_05 ngirls_05 nwomen_05)	

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold, replace
rename hhold hhid

glo id psu hhid day 
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05		
save food12005, replace											
 											
										
 /*File s9a2:											
SECTION 9:  CONSUMPTION, PART A: DAILY CONSUMPTION */
																																
use "$input05/s9a2.dta", clear
drop rec_type code
/*43 observations appear twice with different information. 43 observations are deleted randomly.
82 observations appear twice with the same information. 82 observations are deleted*/	
duplicates report hhold day foodcode										
duplicates drop hhold day foodcode, force											
rename (quan valu orig) (quantity_05 value_05 source_05)
drop if mod(foodcode,10)==0	
drop hhold																		
gen  hhold=string(hhcode,"%0010.0f")
drop hhcode

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold, replace
rename hhold hhid

glo id psu hhid day foodcode  
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05
save food22005, replace
										
										
/*File s9b:											
SECTION 9: CONSUMPTION, PART B: WEEKLY CONSUMPTION */																			
											
use "$input05/s9b", clear	
destring code, gen(foodcode)
drop rec_type code
/*1 observation appears twice with different information. One observation is deleted randomly.
12 observations appear twice with the same information. 12 observations are deleted*/	
duplicates report hhold week foodcode
duplicates drop hhold week foodcode, force
rename (quan valu orig) (quantity_05 value_05 source_05)
drop if mod(foodcode,10)==0	

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold, replace
rename hhold hhid

glo id psu hhid week foodcode  
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05
save food32005, replace
																					
											
/*****************************************************************************************************											
*                                                                                                    *											
                                   * ASSEMBLE NON-FOOD DATABASE											
*                                                                                                    *											
*****************************************************************************************************/											
/*File s9c:											
SECTION 9:CONSUMPTION, PART C: MONTHLY NON-FOOD EXPENDITURE	*/																		
																			
use "$input05/s9c.dta", clear	
destring code, replace
drop rec_type
sort hhold code
rename (q01_9c q02_9c q03_9c)(s9c_q1_05_r s9c_q2_05_r s9c_q3_05_r) 
drop if mod(code,10)==0	| code==123

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold, replace
rename hhold hhid

glo id psu hhid code 
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05										
save monthlynfood2005, replace											
										
											
/*File s9d1, s9d2											
SECTION 9:  CONSUMPTION, PART D:  ANNUAL NON-FOOD EXPENDITURE */																						
											
use "$input05/s9d1.dta", clear	
destring code, replace																																							
drop rec_type
sort hhold code
/*6 observations appear twice with the same information. 6 observations are deleted*/																				
duplicates report hhold code
duplicates drop hhold code, force
rename (q01_9d1 q02_9d1) (s9d_q1_05_r s9d_q2_05_r)										
save `s9d1', replace											
																						
use "$input05/s9d2.dta", clear	
destring code, replace																																																
drop rec_type
sort hhold code	
/*2 observations appear twice with the same information. 2 observations are deleted*/																				
duplicates report hhold code
duplicates drop hhold code, force
rename q01_9d2 s9d_q2_05_r
save `s9d2', replace
																		
use `s9d1', clear
append using `s9d2'
drop if mod(code,10)==0

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold, replace
rename hhold hhid

glo id psu hhid code 
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05
save annualnfood2005, replace 

											
/*****************************************************************************************************											
*                                                                                                    *											
                                   * ASSEMBLE DURABLE DATABASE											
*                                                                                                    *											
*****************************************************************************************************/											
/*File s9e:											
SECTION 9:CONSUMPTION, PART E:INVENTORY OF CONSUMER DURABLE GOODS */											
																																	
use "$input05/s9e", clear
destring code, replace
drop rec_type																			
sort hhold code	
/*7 observations appear twice with the same information. 7 observations are deleted*/																				
duplicates report hhold code
duplicates drop hhold code, force	

rename (q01_9e q02_9e q03_9e q04_9e)(s9e_q1_05_r s9e_q2_05_r s9e_q3_05_r s9e_q4_05_r)

*Getting Geographical information and weights
merge m:1 hhold using `geo2005'
tab _m
drop if _m==2
drop _m
destring psu hhold, replace
rename hhold hhid

glo id psu hhid code 
foreach var in $id{
rename `var' `var'_05
}	
order year $id $geo05						
save durable2005, replace											
										
																					
/*****************************************************************************************************											
*                                                                                                    *											
                                   * ASSEMBLE COMMUNITY DATABASE											
*                                                                                                    *											
*****************************************************************************************************/											

use "$inputcom05/s0.dta", clear											
drop rec_type											
save `s0', replace											
											
											
forval i = 1/6{											
  	use "$inputcom05/s`i'.dta", clear										
	drop rec_type										
	rename *_s`i' *										
    rename q0(#)* s`i'_q(#)*_05_r											
	sort psu										
	save `s`i'', replace										
	clear 										
	}										

	
*Section 2, qestion 1: percentages in year 2005 are organized to harmonize with year 2010
use `s2', clear
tempfile grain	
keep psu  s2_q1a_05_r s2_q1b_05_r s2_q1c_05_r s2_q1d_05_r s2_q1e_05_r 
rename (s2_q1a_05_r s2_q1b_05_r s2_q1c_05_r s2_q1d_05_r s2_q1e_05_r )(p1 p2 p3 p4 p5)	
reshape long p, i(psu) j(cropcode)
gsort +psu - p
by psu: gen position = sum(p != p[_n-1]) 
drop p
sort psu cropcode
reshape wide position, i(psu) j(cropcode)
rename (position1 position2 position3 position4 position5)(s2_q1a_05_r s2_q1b_05_r s2_q1c_05_r s2_q1d_05_r s2_q1e_05_r )
label variable s2_q1a_05_r ""
label variable s2_q1b_05_r ""
label variable s2_q1c_05_r ""
label variable s2_q1d_05_r ""
label variable s2_q1e_05_r ""
save `grain', replace

use  `s2', clear
merge 1:1 psu using `grain',  replace update nogenerate
save  `s2', replace

											
use `s3', clear											
rename q(#)* s3_q(#)*_05_r											
save `s3', replace											
											
											
											
use `s0', clear
label drop _all												
forval i = 1/6{											
    merge 1:1 psu using `s`i'', nogenerate 											
   }											

destring psu div reg dis tha , replace 

*Next thana codes need to be genenerated combining District code and Thana code																		
gen indi=1 if tha==7 | tha==14 | tha==43  | tha==51 | tha==58 | tha==70 | tha==77 	 	 	 	 	 	 	 				
gen thana2 = string(tha,"%02.0f") if indi==1											
egen thana3 = concat(dis thana2) if indi==1											
destring thana3, replace	 										
drop thana2											
gen thana2= tha											
replace thana2=thana3 if indi==1											
drop thana3 indi	

rename (div reg dis tha  supe) (division region district thana supervisor)											
glo variables  psu division region district thana thana2  supervisor date											
foreach var in $variables{											
rename `var' `var'_05											
}
drop s1_q7a_05_r 
gen s1_q7a_05_r =.
replace s1_q7a_05_r=2 if s1_q7b1_05_r==0 & s1_q7c1_05_r==0 & s1_q7d1_05_r==0 & s1_q7e1_05_r==0 ///
& s1_q7f1_05_r==0 & s1_q7g1_05_r==0 & s1_q7h1_05_r==0 & s1_q7i1_05_r==0 & s1_q7j1_05_r==0 & s1_q7k1_05_r==0
replace s1_q7a_05_r=2 if s1_q7b1_05_r==. & s1_q7c1_05_r==. & s1_q7d1_05_r==. & s1_q7e1_05_r==. ///
& s1_q7f1_05_r==. & s1_q7g1_05_r==. & s1_q7h1_05_r==. & s1_q7i1_05_r==. & s1_q7j1_05_r==. & s1_q7k1_05_r==.
replace s1_q7a_05_r=1 if s1_q7a_05_r==.

glo variables  s1_q7b2_05_r s1_q7c2_05_r s1_q7d2_05_r s1_q7e2_05_r s1_q7f2_05_r s1_q7g2_05_r ///
s1_q7h2_05_r s1_q7i2_05_r s1_q7j2_05_r s1_q7k2_05_r
foreach var in $variables{
replace `var'=6 if `var'==7
label define `var' 1"Grameen Bank" 2"Brac" 3"Proshika" 4"Caritas" 5"Asha" 6 "Other2005"
la val `var' `var'
}

foreach var in $variables{
decode `var', gen(`var'ngo)
}
drop $variables
rename s1_q7*ngo s1_q7*											
gen year=2005
order year
order division_05, after(region_05)
order thana2_05, after(thana_05)
										
save community2005, replace											
											

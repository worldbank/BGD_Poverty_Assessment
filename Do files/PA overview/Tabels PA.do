*================================================================================
*project:       Bangladesh: Poverty analysis
**Dependencies:  World Bank
*---------------------------------------------------------------------------
*Creation Date:    April, 2019
*===============================================================================================
*                                  0: Program set up
*===============================================================================================

clear all
set maxvar 10000
tempfile temp

local in ="..."


*Input
glo input_urban_fix "`in'\Do files\Data\HIES 2000-2016 harmonized"
glo input_final     "`in'\Do files\Data\HIES 2000-2016 harmonized"
						 
*output                                 
glo output          "`in'\Do files\PA overview"

cd "$output"



*==========================================================================
*                                             HH level data
*==========================================================================
*poverty data
use "$input_final\consumption2000_2016.dta"

for any urbrural urbruralcomparable zf zl zu znfu pcexp pline_nat spindex realpcexp rent imprent pr_rent hsvalhh fexp consexp2 nfexp2 quarter zf16quarters zu16quarters zl16quarters lowerpoorquarters upperpoorquarters lowerpoor upperpoor lowerpoorper upperpoorper lowerpoorquarterper upperpoorquarterper pline_nat16 timedef realpce qcons5: rename X_b X

lab var urbrural "Rural=1 and Urban==2 Urban Fix"
gen urbrural_urb_fix=urbrural
*HH characteristics
merge 1:1 year hhid using "$input_final\final00_16_household.dta"
tab _merge
drop if _merge==2
drop _merge

/*Stratum in HIES 2016 is different to previous years and has 132 strata.
To compute means with standard errors and confidence intervals we create a harmonized 
stratum variable.
Since stratum in 2016 has 2 equal numbers (11,12) to stratum16 we create a variable with 
2016 before the stratum variable 2016 */

egen stratum2016=concat(year stratum) if year==2016
destring stratum2016, replace

gen stratumharmonized=stratum16 if inrange(year,2000, 2010)
replace stratumhar=stratum2016 if year==2016

*generate vulnerable and middle_class 

gen vulnerable=(pcexp>zu & pcexp<=zu*2)

gen middle_class=(pcexp>zu*2)

*generate pov depth and severity for upperpoorand lowerpoor

gen pov_depth=0
replace pov_depth=(zu-pcexp)/zu if upperpoor==1
gen pov_sev=pov_depth*pov_depth

gen pov_depth_ext=0
replace pov_depth_ext=(zl-pcexp)/zl if lowerpoor==1
gen pov_sev_ext=pov_depth_ext*pov_depth_ext


*East and west  
gen east=(division==10 | division==20 | division==30 | division==60)

*Household is urban
gen urban=(urbrural==2)

tempfile temp
save `temp'



/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE INDIVIDUAL DATABASE
*                                                                                                    *
*****************************************************************************************************/

use "$input_final/final00_16_individual.dta", clear
drop urbrural

*East and west  
gen east=(division==10 | division==20 | division==30 | division==60)

*age ranges 
gen age_6_18=(roster_a_4>=6 & roster_a_4<=18)
*age range and attending school 
gen age_6_18_atten=(roster_a_4>=6 & roster_a_4<=18& educ_b1_1==1 )
replace age_6_18_atten=. if age_6_18==0

*no education
gen no_ever_attended_educ=(educ_a_4==2)
*HH head tag 
gen hh_head=(roster_a_3==1)
*HH size
bys year hhid : gen member=_N
*generate number of kids under 8 
gen age_uder_8_aux=(roster_a_4<8 & roster_a_4!=.)
bys year hhid : egen age_uder_8=total(age_uder_8_aux)


recode educ_a_3 (1=1) (2=0) if roster_a_4>=18, gen(lit)
replace lit=0 if lit==.


drop if year==.
*drop roster_a_1
tempfile individual
save `individual'


/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE EMPLOYMENT DATABASE
*                                                                                                    *                                                                                                    *
*****************************************************************************************************/

use "$input_final/final00_16_employment.dta", clear
drop urbrural
glo var year hhid indid activity labor*
replace activity=99 if activity==.
keep  $var 
order $var

*-------------------------------------------------------------------*
*		Checking for right Industrial and Occupational codes
*-------------------------------------------------------------------*

/* This parts checks if the industrial and occupational codes are right, 
according to the document "Occupation and Industrial code in English", 
available in the documentation folder*/

* Occupation code
gen aux1=labor_a_1b
#d ;
gen correct1 = (aux1 >=  1 & aux1 <= 10)|(aux1 >= 12 & aux1 <= 21) 
	      |(aux1 >= 30 & aux1 <= 40)|(aux1 >= 42 & aux1 <= 46)
	      |(aux1 >= 50 & aux1 <= 56)|(aux1 >= 58 & aux1 <= 61) 
	      | aux1 == 63 | aux1 == 64 
	      |(aux1 >= 70 & aux1 <= 72)|(aux1 >= 74 & aux1 <= 92)
;
#d cr
rename aux1 aux2

* Industry code
gen aux1=labor_a_1c
#d ;
gen correct = aux1 == 1 | aux1 == 2   | aux1 ==  5 | aux1 == 10 
	    | aux1 == 11|(aux1 >= 14 & aux1 <= 37) | aux1 == 40 
	    | aux1 == 41 | aux1 == 45 |(aux1 >= 50 & aux1 <= 52)
	    | aux1 == 55 | (aux1 >= 60 & aux1 <= 67)
	    |(aux1 >= 70 & aux1 <= 75)| aux1 == 80 | aux1 ==81  
	    | aux1 == 90 | aux1 ==92 | aux1 ==99
;
#d cr

ta correct correct1

* Keep only those workers with correct Industrial & Occupation Codes
drop if correct  == 0 
drop if correct1 == 0
drop correct* aux*

*-------------------------------------------------------------------*
*		Hours, days and months of work
*-------------------------------------------------------------------*

for var labor_a_2 labor_a_3 labor_a_4: recode X 0 = .

* Upper bound = no more than what is asked or reasonable value
replace labor_a_2 = 12 if labor_a_2 > 12 & labor_a_2 != .
replace labor_a_3 = 30 if labor_a_3 > 30 & labor_a_3 != .
replace labor_a_4 = 16 if labor_a_4 > 16 & labor_a_4 != .

*-------------------------------------------------------------------*
* . LABOR RELATION						    *
*-------------------------------------------------------------------*

/* For this part, only the variables labor_a_7 and labor_a_8 should be 
taken into account. In case of having an answer in both, corrections 
should be made using labor_a_6*/

* Kind of activity (Including sector)
generat activity_kind=1 if labor_a_7==1
replace activity_kind=2 if labor_a_7==2
replace activity_kind=3 if labor_a_7==3
replace activity_kind=4 if labor_a_7==4
replace activity_kind=5 if labor_a_8==1
replace activity_kind=6 if labor_a_8==2
replace activity_kind=7 if labor_a_8==3
replace activity_kind=8 if labor_a_8==4

* Corrections
ta labor_a_7 labor_a_8 if labor_a_6==1
replace activity_kind=1 if labor_a_6==1 & labor_a_7==1 & labor_a_8==1
replace activity_kind=2 if labor_a_6==1 & labor_a_7==2 & inlist(labor_a_8,1,2,3,4)

la def activity_kind 1 "Agr-Daily labor" 2 "Agr-Self employed" 3 "Agr-Employer" 4 "Agr-Employee" 5 "Non agr-Daily labor" 6 "Non agr-Self employed" 7 "Non agr-Employer" 8 "Non agr-Employee"
la val activity_kind activity_kind

notes activity_kind: This variable for year 2000 is not comparable with years 2005, 2010 and 2016

*--------------------------------------------------------------------*
*  INCOME DETAILS                             *
*--------------------------------------------------------------------*

mvdecode labor_b_1-labor_b_9, mv(0)

** Monthly wage
* Some individuals report monthly wage but not net monthly wage taken to home
replace labor_b_8=labor_b_7 if labor_b_8==. & labor_b_7!=.
gen oth_benef_month=labor_b_9/12
egen monthly_wage=rowtotal(labor_b_8 oth_benef_month)

** Total daily wage (by month, cash and kind)
egen daily_wage=rowtotal(labor_b_2c labor_b_5c)
gen tot_daily_wage=daily_wage*24


* 1. CORRECTIONS
* a- Check for inconsistencies 
* 1. Those who say DAILY BASIS but have SALARIED WAGE 
gen e = labor_b_1 == 1 & !inlist(monthly_wage,.,0)
replace monthly_wage = . if e == 1

* 2. Those who say SALARIED WAGE but have DAILY BASIS 
gen t = labor_b_1 == 2 & !inlist(tot_daily_wage,.,0)
replace tot_daily_wage = . if t == 1
drop e t

* Income by activity
g act_inc=monthly_wage if labor_b_1==2
replace act_inc=tot_daily_wage if labor_b_1==1
 
drop labor_a_1a labor_a_7-labor_a_8 labor_b_* oth_benef_month monthly_wage daily_wage tot_daily_wage


ren (labor_a_1b      labor_a_1c    labor_a_2      labor_a_3  labor_a_4 labor_a_5a   labor_a_5b) ///
	(occupation_code industry_code month_lastyear days_month hrs_day   act_urbrural act_district)

drop activity
bysort year hhid indid: gen activity=_n
bysort year hhid indid: gen n_activity=_N

reshape wide occupation_code-act_inc, i(year hhid indid) j(activity) 

la var n_activity "# of reported activities"

forvalues i=1/9{
labvars occupation_code`i' "Occupation code, act #`i'" industry_code`i' "Industry code, act #`i'" ///
	month_lastyear`i' "# of months working in act #`i' last year" ///
	days_month`i' "Average days per month, act #`i'" hrs_day`i' "Average hours per day, act #`i'" ///
	act_urbrural`i' "Area of act #`i'" act_district`i' "District of act #`i'" ///
	activity_kind`i' "Kind of activity, act #`i'" act_inc`i' "Income from act #`i'", alternate
}

*HH head sector

 gen in_agg=(labor_a_61==1 | labor_a_62==1 | labor_a_63==1 | labor_a_64==1 | labor_a_65==1 | labor_a_66==1 | labor_a_67==1 | labor_a_68==1 | labor_a_69==1)


* Hours worker in each sector
for num 1/9: gen hrsyearX=month_lastyearX*days_monthX*hrs_dayX
for num 1/9: gen ag_hrsX=hrsyearX if industry_codeX<=5
for num 1/9: gen ind_hrsX=hrsyearX if industry_codeX<=45 & industry_codeX>=10
for num 1/9: gen serv_hrsX=hrsyearX if industry_codeX>=50 & industry_codeX<=99
for any ag ind serv: egen X_hrs=rsum(X_hrs1-X_hrs9)

* Hours worker in each type of work
for num 1/9: gen wage_hrsX=hrsyearX if inlist(activity_kindX,4,8)
for num 1/9: gen daily_hrsX=hrsyearX if inlist(activity_kindX,1,5)
for num 1/9: gen self_hrsX=hrsyearX if inlist(activity_kindX,2,6,3,7)
for any wage daily self : egen X_hrs=rsum(X_hrs1-X_hrs9)


* Hours worker in each sector+type
for num 1/9: gen agr_wage_hrsX=hrsyearX if inlist(activity_kindX,1,4,5,8) & industry_codeX<=5
for num 1/9: gen agr_self_hrsX=hrsyearX if inlist(activity_kindX,2,3,6,7) & industry_codeX<=5
for num 1/9: gen ser_wage_hrsX=hrsyearX if inlist(activity_kindX,1,4,5,8) & inrange(industry_codeX,50,99)
for num 1/9: gen ser_self_hrsX=hrsyearX if inlist(activity_kindX,2,3,6,7) & inrange(industry_codeX,50,99)
for num 1/9: gen ind_wage_hrsX=hrsyearX if inlist(activity_kindX,1,4,5,8) & inrange(industry_codeX,10,45)
for num 1/9: gen ind_self_hrsX=hrsyearX if inlist(activity_kindX,2,3,6,7) & inrange(industry_codeX,10,45)
for any agr_wage agr_self ser_wage ser_self ind_wage ind_self: egen X_hrs=rsum(X_hrs1-X_hrs9)

* Hours worker in each sector (disaggregation)
for num 1/9: gen garm_hrsX=hrsyearX if inrange(industry_codeX,17,19)
for num 1/9: gen omanu_hrsX=hrsyearX if inlist(industry_codeX,15,16) | inrange(industry_codeX,20,37)
for num 1/9: gen cons_hrsX=hrsyearX if industry_codeX==45
for num 1/9: gen oind_hrsX=hrsyearX if inrange(industry_codeX,10,14) | inrange(industry_codeX,40,41)
for num 1/9: gen comm_hrsX=hrsyearX if inrange(industry_codeX,50,55)
for num 1/9: gen trans_hrsX=hrsyearX if inrange(industry_codeX,60,64)
for num 1/9: gen oser_hrsX=hrsyearX if inrange(industry_codeX,65,99)

for any garm omanu cons oind comm trans oser: egen X_hrs=rsum(X_hrs1-X_hrs9)

preserve

collapse (sum) *_hrs, by(year hhid)

for any ag_hrs ind_hrs serv_hrs wage_hrs daily_hrs self_hrs agr_wage_hrs agr_self_hrs ser_wage_hrs ser_self_hrs ind_wage_hrs ind_self_hrs garm_hrs omanu_hrs cons_hrs oind_hrs comm_hrs trans_hrs oser_hrs : rename X hh_X

sort year hhid 
tempfile hhlevel_emp
save `hhlevel_emp', replace
	
restore

sort year hhid indid
tempfile employment
save `employment'

/*****************************************************************************************************
*                                                                                                    *
                                           Profiles 
*                                                                                                    *
*****************************************************************************************************/

use `individual'

merge 1:1 year indid hhid using `employment'
tab _m
drop if _m==2
drop _m
 
merge m:1 year hhid using `temp'
tab _m
drop if _m!=3
drop _m

sort year hhid roster_a_3
*Tag households
egen hh_tag=tag(year hhid)


************************Define all the variables********************************



*Dependency ratio
gen dep=1 if (roster_a_4<=14 | roster_a_4>65) 
bys year hhid: egen tot_dep = total(dep)
gen workpop=1 if roster_a_4>14 & roster_a_4<=65
bys year hhid: egen tot_work = total(workpop)
gen depratio=tot_dep/tot_work

*household head age
gen headage_=roster_a_4 if roster_a_3==1
bys year hhid:egen headage=mean(headage_)

*Household head is female
gen femalehead_=1 if roster_a_2==2 & roster_a_3==1 
bysort year hhid:egen femalehead=mean(femalehead_)

*Household head is married
gen headmarried_=1 if roster_a_3==1 & roster_a_6a==1
bys year hhid:egen headmarried=mean(headmarried_)

*Household head is literate, literate is defined as people who can write a letter
gen literatehead_=1 if educ_a_3==1 & roster_a_3==1
bysort year hhid:egen literatehead=mean(literatehead_)

*Education variables

*Head has no education 
gen edu1_=1 if educ_a_5==0 & roster_a_3==1
bys year hhid:egen edu1=mean(edu1_)

*Head has some primary education 
gen edu2_=1 if inrange(educ_a_5,1,4) & roster_a_3==1
bys year hhid:egen edu2=mean(edu2_)

*Head has completed primary education 
gen edu3_=1 if inlist(educ_a_5,5) & roster_a_3==1
bys year hhid:egen edu3=mean(edu3_)


*Head has some secondary education
gen edu4_=1 if inrange(educ_a_5,6,10) & roster_a_3==1
bys year hhid:egen edu4=mean(edu4_)

*Head has completed secondary education  
gen edu5_=1 if inlist(educ_a_5,11) & roster_a_3==1
bys year hhid:egen edu5=mean(edu5_)

*Head has tertiary education 
gen edu6_=1 if inrange(educ_a_5,12,18) & roster_a_3==1
bys year hhid:egen edu6=mean(edu6_)

*Head has at least some secondary education 
gen edu7_=1 if inrange(educ_a_5,6,18) & roster_a_3==1
bys year hhid:egen edu7=mean(edu7_)

*Household owns a mobile phone 2016
gen mobile161=1 if roster_a_13==1
bys year hhid:egen mobile162=total(mobile161)
gen mobile16=1 if mobile162>0 & mobile162!=.
replace mobile16=0 if mobile162==0 & mobile162!=.

*Members with disability
gen any_disability=1 if inrange(roster_a_15,2,4)
forvalues i=16(1)20{
replace any_disability=1 if inrange(roster_a_`i',2,4)
}

*Household receives remittances from outside the country
gen remi_out=1 if ~inlist(oincome_b_9, 0, .)
replace remi_out=0 if oincome_b_9==0

*Household receives remittances from within the country
gen remi_within=1 if ~inlist(oincome_b_8, 0, .)
replace remi_within=0 if oincome_b_8==0

*Household receives microcredit
recode oincome_d_4 (1=1) (2=0), gen(micro)

bysort year hhid: egen member_disab=mean(any_disability)

*main sector by hours,  
egen   hrsmax=rmax(ag_hrs ind_hrs serv_hrs)
recode hrsmax (0=.)

gen sector_h=.
	replace sector_h=1 if ag_hrs==hrsmax   & ag_hrs!=.
	replace sector_h=2 if serv_hrs==hrsmax & serv_hrs!=. & sector_h==.
	replace sector_h=3 if ind_hrs==hrsmax  & ind_hrs!=.  & sector_h==.
	recode  sector_h (.=4) if roster_a_4>=15
	
	lab var sector_h "Main sector of employment of the Head HOURS"
	la  de  sector_h 1	"Agriculture" 2	"Services" 3 "Industry" 4 "Undefined"
	la val  sector_h sector_h

	
*sector of the Head
tab sector_h if roster_a_3==1, gen(sectorhead_)

*Proportion of adults in agriculture
gen agri_=(in_agg==1 & roster_a_4>=15 & hrsmax!=.)
bys year hhid:egen agri=mean(agri_)

*Share of adults who are earners
gen earner_=(roster_a_7==1 & roster_a_4>=15 & roster_a_4!=.)
bys year hhid:egen earner=mean(earner_)


*go to HH level
keep if hh_tag==1

*Household owns a mobile phone 2000 to 2010
recode housing_a_16 (1=1) (nonmissing=0), gen(mobile)
replace mobile=mobile16 if year==2016
replace mobile=0 if year==2000

*Has electricity 
recode housing_a_14 (1=1) (nonmissing=0), gen(electricity)

*Has piped water 
recode  housing_a_9 (1=1) (nonmissing=0), gen(water)

*Has sanitary
recode   housing_a_8a (1=1) (nonmissing=0), gen(sanitary)

*Owns land 
gen land=1 if agri_a_1>0 & agri_a_1!=.
replace land=0 if agri_a_1==0  & agri_a_1!=.

*A household member has a chronic illness/disability
gen disability=1 if health_a1_2a>0 & health_a1_2a!=.
replace disability=1 if (inlist(roster_a_15,3,4)|inlist(roster_a_16,3,4)|inlist(roster_a_17,3,4)|inlist(roster_a_18,3,4)|inlist(roster_a_19,3,4)|inlist(roster_a_20,3,4)) & roster_a_3==1
replace disability=1 if (inlist(health_d_5,3,4)|inlist(health_d_11,3,4)|inlist(health_d_8,3,4)|inlist(health_d_14,3,4)|inlist(health_d_17,3,4)|health_d_20a==1|health_d_20b==1|health_d_20c==1) & roster_a_3==1
replace disability=0 if disability!=1

*Household receives social protection program

preserve
use "$input_final/safety2005.dta", clear
drop if inlist(s8c_q1a_05_r, 5)
recode s8c_q1a_05_r (1=1) (2=0), gen(social1)
drop if social1==.
bys hhid: egen social2= total(social1)
gen social=(social2!=0)
collapse year social, by(hhid)
rename hhid_05 hhid
tempfile social05
save `social05', replace

use "$input_final/safety2010.dta", clear
drop if resid1c_10==.
recode s1c_q1_10_r (1=1) (2=0) (0 9=.), gen(social1)
drop if social1==.
bys hhid: egen social2= total(social1)
gen social=(social2!=0)
collapse year social, by(hhid)
rename hhid_10 hhid
tempfile social10
save `social10', replace

use "$input_final/safety2016.dta", clear
drop if inlist(s1c_q1_16_r, 0,4,7)
recode s1c_q1_16_r (1=1) (2=0), gen(social1)
drop if social1==.
bys hhid: egen social2= total(social1)
gen social=(social2!=0)
collapse year social, by(hhid)
rename hhid_16 hhid
tempfile social16
save `social16', replace

use `social05' 
append using `social10' `social16'
tempfile social
save `social',replace
restore

merge 1:1 year hhid using `social'
tab _m
drop if _m==2
drop _m

cap drop headage_ femalehead_ headmarried_ literatehead_  agri_ edu1_ edu2_ edu3_ edu4_ edu5_ edu6_ mobile161 mobile162

foreach var in femalehead headmarried literatehead edu1 edu2 edu3 edu4 edu5 edu6 edu7 {
replace `var'=0 if `var'==.
}


*******************************
** * HH sector fro Ravallion and Huppi 
*******************************

merge 1:1 year hhid using `hhlevel_emp'
tab _merge
drop if _merge==2
drop _merge

***************************************
** Main sector (hour) **
**************************

egen hh_hrsmax=rmax(hh_ag_hrs hh_ind_hrs hh_serv_hrs)
recode hh_hrsmax (0=.)

gen hh_fam_hmain_sect=.
	replace hh_fam_hmain=1 if hh_hrsmax~=. & hh_ag_hrs~=. & hh_ag_hrs==hh_hrsmax
	replace hh_fam_hmain=2 if hh_serv_hrs==hh_hrsmax & hh_fam_hmain==.
	replace hh_fam_hmain=3 if hh_ind_hrs ==hh_hrsmax & hh_fam_hmain==.
	recode  hh_fam_hmain (.=4)
	replace hh_fam_hmain=4 if hh_hrsmax==.
la de hh_fam_hmain 1	"Agriculture" 2	"Services" 3 "Industry" 4 "Undefined"
la val hh_fam_hmain hh_fam_hmain


*******************************
** Disaggregation by sector (hours) **
*******************************

egen hh_maxsecth=rmax(hh_ag_hrs hh_garm_hrs hh_omanu_hrs hh_cons_hrs hh_oind_hrs hh_comm_hrs hh_trans_hrs hh_oser_hrs)
replace hh_maxsecth=. if hh_maxsecth==0


gen hh_fam_emp_secth=.
	replace hh_fam_emp_secth=1 if hh_ag_hrs  ==hh_maxsecth
	replace hh_fam_emp_secth=2 if hh_garm_hrs==hh_maxsecth  & hh_fam_emp_secth==.
	replace hh_fam_emp_secth=3 if hh_omanu_hrs==hh_maxsecth  & hh_fam_emp_secth==.
	replace hh_fam_emp_secth=4 if hh_cons_hrs ==hh_maxsecth  & hh_fam_emp_secth==.
	replace hh_fam_emp_secth=5 if hh_oind_hrs ==hh_maxsecth  & hh_fam_emp_secth==.
	replace hh_fam_emp_secth=6 if hh_comm_hrs ==hh_maxsecth  & hh_fam_emp_secth==.
	replace hh_fam_emp_secth=7 if hh_trans_hrs==hh_maxsecth  & hh_fam_emp_secth==.
	replace hh_fam_emp_secth=8 if hh_oser_hrs ==hh_maxsecth  & hh_fam_emp_secth==.
	recode  hh_fam_emp_secth (.=9)
	replace hh_fam_emp_secth=9 if hh_maxsecth==.
	
la de hh_fam_emp_secth 1 "Agriculture" 2 "Garment" 3 "Other Manufacturing" 4 "Construction" 5 "Other Industry" 6 "Commerce" 7 "Transport" 8 "Other Services" 9 "Undefined"
la val hh_fam_emp_secth hh_fam_emp_secth 

recode hh_fam_emp_secth (3=2),gen(hh_fam_emp_secth_j)
la de hh_fam_emp_secth_j 1 "Agriculture" 2 "Manufacturing" 4 "Construction" 5 "Other Industry" 6 "Commerce" 7 "Transport" 8 "Other Services" 9 "Undefined"
la val hh_fam_emp_secth_j hh_fam_emp_secth_j 


**************************************************
** Tipe of income by sectors (hours) **
*******************************

egen hh_maxtypeh=rmax(hh_agr_wage_hrs hh_agr_self_hrs hh_ser_wage_hrs hh_ser_self_hrs hh_ind_wage_hrs hh_ind_self_hrs)
replace hh_maxtypeh=. if hh_maxtypeh==0
gen hh_emptypeh=.
	replace hh_emptypeh=1 if hh_agr_self_hrs==hh_maxtypeh
	replace hh_emptypeh=2 if hh_agr_wage_hrs==hh_maxtypeh & hh_emptypeh==.
	replace hh_emptypeh=3 if hh_ser_self_hrs==hh_maxtypeh & hh_emptypeh==.
	replace hh_emptypeh=4 if hh_ser_wage_hrs==hh_maxtypeh & hh_emptypeh==.
	replace hh_emptypeh=5 if hh_ind_self_hrs==hh_maxtypeh & hh_emptypeh==.
	replace hh_emptypeh=6 if hh_ind_wage_hrs==hh_maxtypeh & hh_emptypeh==.
	recode  hh_emptypeh (.=7)

la de hh_emptypeh 1 "Agriculture self-employment" 2  "Agriculture wage" 3 "Services self-employment" 4  "Services wage" 5 "Industry self-employment" 6 "Industry wage" 7 "Undefined"
la val hh_emptypeh hh_emptypeh 


**************************************************
** Multiple sectors (hours) **
*******************************

** All household hours to only one sector
gen hh_agr_only=(hh_hrsmax==hh_ag_hrs&  hh_ind_hrs==0&hh_serv_hrs==0)
gen hh_ind_only=(hh_hrsmax==hh_ind_hrs& hh_ag_hrs==0 &hh_serv_hrs==0)
gen hh_ser_only=(hh_hrsmax==hh_serv_hrs&hh_ind_hrs==0&hh_ag_hrs==0)

** Combined variables for main and secondary amount of hours by sectors
gen hh_agri_indu=(hh_hrsmax==hh_ag_hrs		&hh_ind_hrs>0	&hh_serv_hrs==0)
gen hh_agri_serv=(hh_hrsmax==hh_ag_hrs		&hh_serv_hrs>0  &hh_ind_hrs==0)
gen hh_serv_agri=(hh_hrsmax==hh_serv_hrs	&hh_ag_hrs>0	&hh_ind_hrs==0		&hh_agri_serv==0)
gen hh_serv_indu=(hh_hrsmax==hh_serv_hrs	&hh_ind_hrs>0	&hh_ag_hrs==0)
gen hh_indu_agri=(hh_hrsmax==hh_ind_hrs	&hh_ag_hrs>0	    &hh_serv_hrs==0 	&hh_agri_indu==0)
gen hh_indu_serv=(hh_hrsmax==hh_ind_hrs	&hh_serv_hrs>0	    &hh_ag_hrs==0		&hh_serv_indu==0)
* From the three sectors
gen hh_three_sectors=(!inlist(hh_ag_hrs,.,0)&!inlist(hh_ind_hrs,0,.)&!inlist(hh_serv_hrs,0,.))

gen hh_mult_sector= (hh_serv_agri==1 | hh_agri_indu==1 | hh_agri_serv==1 | hh_serv_indu==1 | hh_indu_agri==1 | hh_indu_serv==1 | hh_three_sectors==1)

* No sector identified
gen hh_no_sector=(hh_ag_hrs==0&hh_ind_hrs==0&hh_serv_hrs==0&hh_mult_sector==0)

gen hh_various_sector=.
replace hh_various_sector=1 if hh_agr_only==1
replace hh_various_sector=2 if hh_ser_only==1
replace hh_various_sector=3 if hh_ind_only==1
replace hh_various_sector=4 if hh_mult_sector==1
recode  hh_various_sector (.=5)

la de hh_various_sector 1	"Only agriculture" 2 "Only services" 3 "Only industry" 4 "Multiple Sectors" 5 "Undefined"
la val hh_various_sector hh_various_sector

*la de urbrural 1	"Rural" 2 "Urban" 
la val urbrural urbrural

*for subpop
gen national=1

*div old
recode division (55=50),gen(division_old)
*div new
gen division_new=division
replace division_new=45 if inlist(district_code,39,61,72,89)

tempfile profiles
save `profiles'




*===============================================================================================
*                                  *Figure 1 and table 1
*===============================================================================================

use `temp',replace

svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)

putexcel set "$output\overview_tables.xlsx", sheet(Fig 1) replace
putexcel  C1="Poverty rate with SE under" D2="2000" E2="2005" F2="2010" G2="2016"  C3="Poverty" C4="Headcount" C6="Depth" C8="Severity" C10="Extreme poverty" C11="Headcount" C13="Depth" C15="Severity", bold hcenter vcenter 

local  count= 4
foreach pov_ind in upperpoor pov_depth pov_sev lowerpoor pov_depth_ext pov_sev_ext{

if "`pov_ind'"=="lowerpoor"{ 
local count =`count'+1
}
local  count_se=`count'+1
svy: mean `pov_ind', over(year)

*std errors
mat var_mat= e(V)
mat SE_mat= [sqrt(var_mat[1,1]),sqrt(var_mat[2,2]),sqrt(var_mat[3,3]),sqrt(var_mat[4,4])]
*export
putexcel D`count'= matrix(e(b)) D`count_se'= matrix(SE_mat), nformat(percent_d2)
local  count= `count_se'+1
}




******************************


putexcel  C19="People under the poverty line, vulnerable (pov line<pcexp<2*pov line), Mid clase (pcexp>2*pov line)" D22="2000" E22="2005" F22="2010" G22="2016"  C23="Poverty" C24="Headcount" C26="Vulnerable" C28="Middle Class", bold hcenter vcenter 

local  count= 24
foreach pov_ind in upperpoor vulnerable middle_class{

local  count_se=`count'+1
svy: mean `pov_ind', over(year)

*std errors
mat var_mat= e(V)
mat SE_mat= [sqrt(var_mat[1,1]),sqrt(var_mat[2,2]),sqrt(var_mat[3,3]),sqrt(var_mat[4,4])]
*export
putexcel D`count'= matrix(e(b)) D`count_se'= matrix(SE_mat), nformat(percent_d2)
local  count= `count_se'+1
}







/*****************************************************************************************************
*                                                                                                    *
                             table 1.2 						
*                                                                                                    *
*****************************************************************************************************/
use `temp', clear

svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)


putexcel set "$output\overview_tables.xlsx", sheet(Table 1.2) modify

putexcel C19="Poverty rate with SE under" D2="2000" E2="2005" F2="2010" G2="2016"  I2="2000" J2="2005" K2="2010" L2="2016"  C3="Poverty by division"  H3="Extreme poverty by division" C4="Barisal" C6="Chittagong" C8="Dhaka" C10="Khulna" C12="Rajshahi" C14="Rangpur" C16="Sylhet", bold hcenter vcenter 

foreach pov_ind in upperpoor lowerpoor  {

foreach year in 2000 2005 2010 2016{
svy: mean `pov_ind' if year==`year', over(division )

mat var_mat_`year'= e(V)
mat pov_mat_`year'= e(b)
mat a_`year'_`pov_ind'=[0,0,0,0,0,0,0,0,0,0,0,0,0,0]
loc aux = 1
foreach div in 1 2 3 4 5 6 7{
mat a_`year'_`pov_ind'[1,`aux']=pov_mat_`year'[1,`div']
loc aux = `aux'+1
mat a_`year'_`pov_ind'[1,`aux']=sqrt(var_mat_`year'[`div',`div'])
loc aux = `aux'+1
mat list a_`year'_`pov_ind'
}
}
}

putexcel D4= matrix(a_2000_upperpoor') E4= matrix(a_2005_upperpoor') F4= matrix(a_2010_upperpoor') G4= matrix(a_2016_upperpoor') I4= matrix(a_2000_lowerpoor') J4= matrix(a_2005_lowerpoor') K4= matrix(a_2010_lowerpoor') L4= matrix(a_2016_lowerpoor'), nformat(percent_d2)



/*****************************************************************************************************
*                                                                                                    *
                             table 2.1 						
*                                                                                                    *
*****************************************************************************************************/

use `profiles'

svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)

*table 2.1 Share of households receiving remittances and social protection transfers
putexcel set "$output\overview_tables.xlsx", sheet(Table 2.1) modify

#delimit
putexcel B2="Table 2.1. Share of households receiving remittances and social protection transfers"	
		B5="International remittances"
		B6="Domestic remittances"
		B7="Social protection transfers"
		B8="Source: Own calculations using HIES 2010 and 2016"
		B9=	"Note: Bottom 40 denotes the poorest 40 percent of the per capita consumption distribution."
		C4="All"	
		D4="Bottom 40"
		F4="All"	
		G4="Bottom 40"
		I4="All"	
		J4="Bottom 40"
		L4="All"	
		M4="Bottom 40"
		, bold hcenter vcenter ;
		
putexcel C3:D3="2000"
		 F3:G3="2005"
		 I3:J3="2010"
		 L3:M3="2016"
		 , merge bold hcenter vcenter;
# del cr


*generate decile of consumption

table year  [aw=hhwgt], c(m  remi_out m remi_within  m social)
tabstat  remi_out  remi_within  social [aw=hhwgt],by(year) stat(mean) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)

putexcel C5=matrix(v_2000') F5=matrix(v_2005')  I5=matrix(v_2010')  L5=matrix(v_2016') , hcenter vcenter nformat(number_d2)

table year  [aw=hhwgt] if qcons5<3, c(m  remi_out m remi_within  m social)
tabstat  remi_out  remi_within  social [aw=hhwgt] if qcons5<3 ,by(year) stat(mean) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)

putexcel D5=matrix(v_2000') G5=matrix(v_2005')  J5=matrix(v_2010')  M5=matrix(v_2016') , hcenter vcenter nformat(number_d2)





/*****************************************************************************************************
*                                                                                                    *
                             Table 2.2 HH dem HH acces and Education  					
*                                                                                                    *
*****************************************************************************************************/

putexcel set "$output\overview_tables.xlsx", sheet(Table 2.2) modify
putexcel B2="Table 2.2. Progress in non-monetary dimensions", bold hcenter vcenter


use `temp', clear

svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)


*acces to service and 
*sanitary
gen sanitary=(housing_a_8a==1)
gen water_supply=(housing_a_9==1)
gen electricity=(housing_a_14==1)
gen tubwell=(housing_a_13==2)
*Owns land 
gen land=1 if agri_a_1>0 & agri_a_1!=.
replace land=0 if agri_a_1==0  & agri_a_1!=.


table year [aw=hhwgt], c(m sanitary m water_supply m electricity m tubwell)
tabstat sanitary tubwell water_supply electricity land [aw=hhwgt], by(year) stat(mean) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)



*export part of the table
putexcel D3="2000" E3="2005" F3="2010" G3="2016", bold hcenter vcenter
putexcel B5="Household demographics", bold hcenter vcenter
putexcel C6="Average household Size"
putexcel C7="Average number of children under 8"
putexcel B8="Household access to housing services and land ownership", bold hcenter vcenter
putexcel C9="% of households with sanitary toilet" D9=matrix(v_2000') E9=matrix(v_2005')  F9=matrix(v_2010')  G9=matrix(v_2016') , hcenter vcenter nformat(number_d2)
putexcel C10="% of households with tubewell water"
putexcel C11="% of households with piped water"
putexcel C12="% of households with electricity"
putexcel C13="% of households that own cultivable land"
putexcel B14="Education", bold hcenter vcenter
putexcel C15="Literacy (% of adults older than 18 years)"
putexcel C16="Years of education (average adults older than 18 years)"
putexcel C17="School attendance (% 6-18 years old)"

*stats at the Inividual level 
clear 

use `individual'

 *table 2 individual variables 
 
 
table year  [aw=hhwgt] if hh_head==1, c(m member m age_uder_8)
tabstat  member age_uder_8 [aw=hhwgt] if hh_head==1 ,by(year) stat(mean) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)

putexcel D6=matrix(v_2000') E6=matrix(v_2005')  F6=matrix(v_2010')  G6=matrix(v_2016') , hcenter vcenter nformat(number_d2)

table year  [aw=hhwgt], c(m age_6_18_atten m years_educ)
tabstat  years_educ age_6_18_atten  [aw=hhwgt],by(year) stat(mean) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)

putexcel D16=matrix(v_2000') E16=matrix(v_2005')  F16=matrix(v_2010')  G16=matrix(v_2016') , hcenter vcenter nformat(number_d2)


table year  [aw=hhwgt] if roster_a_4>=18, c( m lit)
tabstat  lit [aw=hhwgt] if roster_a_4>=18 ,by(year) stat(mean) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)

putexcel D15=matrix(v_2000') E15=matrix(v_2005')  F15=matrix(v_2010')  G15=matrix(v_2016') , hcenter vcenter nformat(number_d2)



/*****************************************************************************************************
*                                                                                                    *
                             Figure 1.2							
*                                                                                                    *
*****************************************************************************************************/


use `temp', clear 

svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)

putexcel set "$output\overview_tables.xlsx", sheet(figure 1.2) modify
*putexcel  C19="Poverty rate with SE under" D2="2000" E2="2005" F2="2010" G2="2016"  C3="Poverty" C4="Headcount" C6="Depth" C8="Severity" C10="Extreme poverty" C11="Headcount" C13="Depth" C15="Severity" F2="2000" G2="2005" H2="2010" I2="2016" F2:I2="Rural", bold hcenter vcenter 


putexcel C19="Poverty rate with SE under" D2="2000" E2="2005" F2="2010" G2="2016"  I2="2000" J2="2005" K2="2010" L2="2016"  C3="Poverty"  H3="Extreme poverty" C4="Rural" C6="Urban" C8="Depth" C10="Rural" C12="Urban" C16="Severity" C18="Rural" C20="Urban", bold hcenter vcenter 


foreach pov_ind in upperpoor pov_depth pov_sev lowerpoor pov_depth_ext pov_sev_ext  {

foreach year in 2000 2005 2010 2016{
svy: mean `pov_ind' if year==`year', over(urbrural )


mat var_mat_`year'= e(V)
mat pov_mat_`year'= e(b)
mat a_`year'_`pov_ind'=[0,0,0,0]
loc aux = 1
foreach div in 1 2{
mat a_`year'_`pov_ind'[1,`aux']=pov_mat_`year'[1,`div']
loc aux = `aux'+1
mat a_`year'_`pov_ind'[1,`aux']=sqrt(var_mat_`year'[`div',`div'])
loc aux = `aux'+1
 mat list a_`year'_`pov_ind'
}
}
}

putexcel D4= matrix(a_2000_upperpoor') E4= matrix(a_2005_upperpoor') F4= matrix(a_2010_upperpoor') G4= matrix(a_2016_upperpoor') I4= matrix(a_2000_lowerpoor') J4= matrix(a_2005_lowerpoor') K4= matrix(a_2010_lowerpoor') L4= matrix(a_2016_lowerpoor') ///
D10= matrix(a_2000_pov_depth') E10= matrix(a_2005_pov_depth') F10= matrix(a_2010_pov_depth') G10= matrix(a_2016_pov_depth') ///
D18= matrix(a_2000_pov_sev') E18= matrix(a_2005_pov_sev') F18= matrix(a_2010_pov_sev') G18= matrix(a_2016_pov_sev') ///
I10= matrix(a_2000_pov_depth_ext') J10= matrix(a_2005_pov_depth_ext') K10= matrix(a_2010_pov_depth_ext') L10= matrix(a_2016_pov_depth_ext') ///
I18= matrix(a_2000_pov_sev_ext') J18= matrix(a_2005_pov_sev_ext') K18= matrix(a_2010_pov_sev_ext') L18= matrix(a_2016_pov_sev_ext') ///
, nformat(percent_d2)



/*****************************************************************************************************
*                                                                                                    *
                             Figure 1.3 GINI and THEIL (alpha=1)						
*                                                                                                    *
*****************************************************************************************************/

use `temp'

putexcel set "$output\overview_tables.xlsx", sheet(Figure 1.3) modify

putexcel  D2="2000" E2="2005" F2="2010" G2="2016"  I2="2000" J2="2005" K2="2010" L2="2016"  C3="Gini"  H3="Theil alpha==1" C4="National" C5="Rural" C6="Urban", bold hcenter vcenter 

for any n r u:mat X=0.1
foreach num of numlist 2000 2005 2010 2016 {
ineqdeco realpce [aw=popwgt] if year==`num', by(urbrural)
mat ng_`num'=r(gini) 
mat rg_`num'=r(gini_1) 
mat ug_`num'=r(gini_2) 
mat nt_`num'=r(ge1) 
mat rt_`num'=r(ge1_1) 
mat ut_`num'=r(ge1_2) 
}

putexcel D4=matrix(ng_2000) D5=matrix(rg_2000) D6=matrix(ug_2000), nformat(number_d2)
putexcel E4=matrix(ng_2005) E5=matrix(rg_2005) E6=matrix(ug_2005), nformat(number_d2) 
putexcel F4=matrix(ng_2010) F5=matrix(rg_2010) F6=matrix(ug_2010), nformat(number_d2) 
putexcel G4=matrix(ng_2016) G5=matrix(rg_2016) G6=matrix(ug_2016), nformat(number_d2)  
putexcel I4=matrix(nt_2000) I5=matrix(rt_2000) I6=matrix(ut_2000), nformat(number_d2)
putexcel J4=matrix(nt_2005) J5=matrix(rt_2005) J6=matrix(ut_2005), nformat(number_d2)
putexcel K4=matrix(nt_2010) K5=matrix(rt_2010) K6=matrix(ut_2010), nformat(number_d2)
putexcel L4=matrix(nt_2016) L5=matrix(rt_2016) L6=matrix(ut_2016), nformat(number_d2)


/*****************************************************************************************************
*                                                                                                    *
                             Figure 1.1 a, b,c and 1.5 a, b (growth incidence curves)						
*                                                                                                    *
*****************************************************************************************************/


cd "$output\GIC's"

*
putexcel set "$output\overview_tables.xlsx", sheet(GICc) modify
putexcel A4="Percentile", bold hcenter vcenter
putexcel A5="0"
for any B C L M V W: putexcel X3= "National", bold hcenter vcenter  
for any D E N O X Y: putexcel X3= "Rural", bold hcenter vcenter  
for any F G P Q Z AA:  putexcel X3= "Urban", bold hcenter vcenter 
for any H I R S AB AC:  putexcel X3= "East", bold hcenter vcenter 
for any J K T U AD AE:  putexcel X3= "West", bold hcenter vcenter 
for any B C D E F G H I J K:  putexcel X2= "2000-2005", bold hcenter vcenter 
for any L M N O P Q R S T U: putexcel X2= "2005-2010", bold hcenter vcenter 
for any V W X Y Z AA AB AC AD AE: putexcel X2= "2010-2016", bold hcenter vcenter 

for any B D F H J L N P R T V X Z AB AD:  putexcel X4= "Average annualized growth rate", bold hcenter vcenter 
for any:  putexcel X4= "2005-2010", bold hcenter vcenter 
for any : putexcel X4= "2010-2016", bold hcenter vcenter 

for any C E G I K M O Q S U W Y AA AC AE:  putexcel X4= "Standard error", bold hcenter vcenter 

use `temp'

*National
levelsof year, local(years)
foreach y of local years {
preserve
keep if year==`y'
keep realpce popwgt urbrural east
rename realpce realpce`y'
tempfile bgd`y'
save `bgd`y''

*urbrural
foreach zone in 1 2 {
use `bgd`y''
drop east
keep if urbrural==`zone'
dis in red "bgd`y'_`zone'_ur"
tempfile bgd`y'_`zone'_ur
save `bgd`y'_`zone'_ur'
}

*east-west
foreach zone in 0 1{
use `bgd`y''
drop urbrural
keep if east==`zone'
dis in red "bgd`y'_`zone'_ew"
tempfile bgd`y'_`zone'_ew
save `bgd`y'_`zone'_ew'
}

restore
}


*Growth incidence curves national/urban/rural
*National
use `bgd2000'
gicurve using `bgd2005' [aw=popwgt], var1(realpce2000) var2(realpce2005) outputfile(gic00_05nat)  /// 
np(100) ginmean ci(95) yperiod(5) nograph 
use gic00_05nat.dta
mkmat pctl pr_growth pg_sd, matrix(A)
putexcel A6= matrix(A) 


*Rural, urban
foreach zone in 1 2 {
use `bgd2000_`zone'_ur'
tab urbrural
gicurve using `bgd2005_`zone'_ur' [aw=popwgt], var1(realpce2000) var2(realpce2005) outputfile(gic00_05_ur_`zone')  /// 
np(100) ginmean ci(95) yperiod(5)  nograph 

local place ="D"
if "`zone'"=="2"{ 
local place ="F"
}

use gic00_05_ur_`zone'.dta
mkmat pr_growth pg_sd, matrix(A)
putexcel `place'6= matrix(A) 

}

*East West
foreach zone in 0 1 {
use `bgd2000_`zone'_ew'
tab east
gicurve using `bgd2005_`zone'_ew' [aw=popwgt], var1(realpce2000) var2(realpce2005) outputfile(gic00_05_ew_`zone')  /// 
np(100) ginmean ci(95) yperiod(5)  nograph 

local place ="H"
if "`zone'"=="0"{ 
local place ="J"
}

use gic00_05_ew_`zone'.dta
mkmat pr_growth pg_sd, matrix(A)
putexcel `place'6= matrix(A) 

}
  
  
  
*Growth incidence curves 2005-2010 national/urban/rural
*National
use `bgd2005'
gicurve using `bgd2010' [aw=popwgt], var1(realpce2005) var2(realpce2010) outputfile(gic05_10nat)  /// 
np(100) ginmean ci(95) yperiod(5) nograph  
use gic05_10nat.dta
mkmat pr_growth pg_sd, matrix(A)
putexcel L6= matrix(A) 



*Rural, urban
foreach zone in 1 2 {
use `bgd2005_`zone'_ur'
tab urbrural
gicurve using `bgd2010_`zone'_ur' [aw=popwgt], var1(realpce2005) var2(realpce2010) outputfile(gic05_10_ur_`zone')  /// 
np(100) ginmean ci(95) yperiod(5)  nograph 


local place ="N"
if "`zone'"=="2"{ 
local place ="P"
}

use gic05_10_ur_`zone'.dta
mkmat pr_growth pg_sd, matrix(A)
putexcel `place'6= matrix(A) 


}


*East-west
foreach zone in 0 1 {
use `bgd2005_`zone'_ew'
tab east
gicurve using `bgd2010_`zone'_ew' [aw=popwgt], var1(realpce2005) var2(realpce2010) outputfile(gic05_10_ew_`zone')  /// 
np(100) ginmean ci(95) yperiod(5)  nograph 

local place ="R"
if "`zone'"=="0"{ 
local place ="T"
}

use gic05_10_ew_`zone'.dta
mkmat pr_growth pg_sd, matrix(A)
putexcel `place'6= matrix(A) 


}


*Growth incidence curves 2010-2016 national/urban/rural
*National
use `bgd2010'
gicurve using `bgd2016' [aw=popwgt], var1(realpce2010) var2(realpce2016) outputfile(gic10_16nat)  /// 
np(100) ginmean ci(95) yperiod(6)  nograph
use gic10_16nat.dta
mkmat pr_growth pg_sd, matrix(A)
putexcel V6= matrix(A) 


*Rural, urban
foreach zone in 1 2 {
use `bgd2010_`zone'_ur'
gicurve using `bgd2016_`zone'_ur' [aw=popwgt], var1(realpce2010) var2(realpce2016) outputfile(gic10_16_ur_`zone')  /// 
np(100) ginmean ci(95) yperiod(6)  nograph


local place ="X"
if "`zone'"=="2"{ 
local place ="Z"
}

use gic10_16_ur_`zone'.dta
mkmat pr_growth pg_sd, matrix(A)
putexcel `place'6= matrix(A) 


}


*East -west
foreach zone in 0 1 {
use `bgd2010_`zone'_ew'
gicurve using `bgd2016_`zone'_ew' [aw=popwgt], var1(realpce2010) var2(realpce2016) outputfile(gic10_16_ew_`zone')  /// 
np(100) ginmean ci(95) yperiod(6)  nograph

local place ="AB"
if "`zone'"=="0"{ 
local place ="AD"
}

use gic10_16_ew_`zone'.dta
mkmat pr_growth pg_sd, matrix(A)
putexcel `place'6= matrix(A) 

}



/*****************************************************************************************************
*                                                                                                    *
                             Figure 1.1 d Shared prosperity 2000-2016					
*                                                                                                    *
*****************************************************************************************************/

use `temp',clear

dis in red "1"
*Shared prosperity  National

loc count=0
loc y0 = 2000
loc y1 = 2005

tempfile shared_prosperity

foreach x in 0 5 5{
dis in red "a"

local count=`count'+`x'
dis in red "1"

local y0 = `y0'+`x'
local y1 = `y1'+`x'
dis in red "2"


if `count'==10{
loc y1 = `y1'+1
}
use `temp'
dis in red "3"
keep if inlist(year, `y0', `y1')
dis in red "4"
local ten=   10
local forty= 40
local sixty= 60
dis in red "5"


xtile _pctile0=realpce [aw=popwgt] if year == `y0',   nq(100) 
xtile _pctile1=realpce [aw=popwgt] if year == `y1',   nq(100) 
dis in red "6"



*Total
qui :su realpce [aw=popwgt] if year == `y0' 
gen a0 =r(mean)

qui :su realpce [aw=popwgt] if year == `y1' 
gen a1 =r(mean)

*Ten %
qui :su realpce [aw=popwgt] if year == `y0' & inrange(_pctile0,0,`ten') 
gen b0 =r(mean)		

qui :su realpce [aw=popwgt] if year == `y1' & inrange(_pctile1,0,`ten') 
gen b1 =r(mean)

*Forty %
qui :su realpce [aw=popwgt] if year == `y0' & inrange(_pctile0,0,`forty') 
gen c0 =r(mean)		

qui :su realpce [aw=popwgt] if year == `y1' & inrange(_pctile1,0,`forty') 
gen c1 =r(mean)

*All %
qui :su realpce [aw=popwgt] if year == `y0' & inrange(_pctile0,0,100) 
gen d0 =r(mean)		

qui :su realpce [aw=popwgt] if year == `y1' & inrange(_pctile1,0,100) 
gen d1 =r(mean)

gen y0=`y0'
gen y1=`y1'


collapse (mean)  y0 y1 a0 a1 b0 b1 c0 c1 d0 d1

gen growth_total = ((a1/a0)^(1/(y1-y0))-1)*100
gen growth_ten   = ((b1/b0)^(1/(y1-y0))-1)*100
gen growth_forty = ((c1/c0)^(1/(y1-y0))-1)*100
gen growth_sixty = ((d1/d0)^(1/(y1-y0))-1)*100
gen location=3

cap append using `shared_prosperity'
save `shared_prosperity', replace

}

*urban and rural

loc count=0
loc y0 = 2000
loc y1 = 2005

foreach x in 0 5 5{

loc count=`count'+`x'

loc y0 = `y0'+`x'
loc y1 = `y1'+`x'

if `count'==10{
loc y1 = `y1'+1
}

foreach zone in 1 2 {
use `temp'

dis in red "`y0'-`y1' in `zone'"
keep if inlist(year, `y0', `y1')
keep if urbrural==`zone'

xtile _pctile0=realpce [aw=popwgt] if year == `y0',   nq(100) 
xtile _pctile1=realpce [aw=popwgt] if year == `y1',   nq(100) 

*Total
qui :su realpce [aw=popwgt] if year == `y0' 
gen a0 =r(mean)

qui :su realpce [aw=popwgt] if year == `y1' 
gen a1 =r(mean)

*Ten %
qui :su realpce [aw=popwgt] if year == `y0' & inrange(_pctile0,0,`ten') 
gen b0 =r(mean)		

qui :su realpce [aw=popwgt] if year == `y1' & inrange(_pctile1,0,`ten') 
gen b1 =r(mean)

*Forty %
qui :su realpce [aw=popwgt] if year == `y0' & inrange(_pctile0,0,`forty') 
gen c0 =r(mean)		

qui :su realpce [aw=popwgt] if year == `y1' & inrange(_pctile1,0,`forty') 
gen c1 =r(mean)

*sixty %
qui :su realpce [aw=popwgt] if year == `y0' & inrange(_pctile0,0,`sixty') 
gen d0 =r(mean)		

qui :su realpce [aw=popwgt] if year == `y1' & inrange(_pctile1,0,`sixty') 
gen d1 =r(mean)

gen y0=`y0'
gen y1=`y1'


collapse (mean)  y0 y1 urbrural a0 a1 b0 b1 c0 c1 d0 d1

gen growth_total = ((a1/a0)^(1/(y1-y0))-1)*100
gen growth_ten   = ((b1/b0)^(1/(y1-y0))-1)*100
gen growth_forty = ((c1/c0)^(1/(y1-y0))-1)*100
gen growth_sixty = ((d1/d0)^(1/(y1-y0))-1)*100
gen location=urbrural

cap append using `shared_prosperity'
save `shared_prosperity', replace

}
}

lab def location_alt 1 "Rural" 2 "Urban" 3 "National"
lab val location location_alt

for any 0 1: rename aX total_mean_X
for any 0 1: rename bX ten_mean_X
for any 0 1: rename cX forty_mean_X
for any 0 1: rename dX all_mean_X

*decode location, gen(location_s)
*order y0 y1 location location_s
sort y0 y1 location

*Export
putexcel set "$output\overview_tables.xlsx", sheet(Figure 1.1.d) modify
putexcel B2="Shared prosperity 2000-2016" B3="Location=3=National" E3="Location=1=Rural" H3="Location=2=Urban", bold hcenter vcenter


mkmat _all, matrix(A) 
matrix rownames A = Rural Urban National Rural Urban National  Rural Urban National 

putexcel A6= matrix(A) , names nformat(number_d2)




/*****************************************************************************************************
*                                                                                                    *
                             table div urban rural				
*                                                                                                    *
*****************************************************************************************************/

use `profiles',clear

svyset psu [pweight=popwgt], strata(stratumharmonized)

*urban


foreach ur_ru in urban rural{
putexcel set "$output\overview_tables.xlsx", sheet(Table `ur_ru' division) modify

putexcel C19="Poverty rate with SE under" D2="2000" E2="2005" F2="2010" G2="2016"  I2="2000" J2="2005" K2="2010" L2="2016"  C3="Poverty by division `ur_ru'"  H3="Extreme poverty by division `ur_ru'" C4="Barisal" C6="Chittagong" C8="Dhaka" C10="Khulna" C12="Rajshahi" C14="Rangpur" C16="Sylhet", bold hcenter vcenter 

foreach pov_ind in upperpoor lowerpoor  {

foreach year in 2000 2005 2010 2016{
svy, subpop(`ur_ru'): mean `pov_ind' if year==`year', over(division )

mat var_mat_`year'= e(V)
mat pov_mat_`year'= e(b)
mat a_`year'_`pov_ind'=[0,0,0,0,0,0,0,0,0,0,0,0,0,0]
loc aux = 1
foreach div in 1 2 3 4 5 6 7{
mat a_`year'_`pov_ind'[1,`aux']=pov_mat_`year'[1,`div']
loc aux = `aux'+1
mat a_`year'_`pov_ind'[1,`aux']=sqrt(var_mat_`year'[`div',`div'])
loc aux = `aux'+1
*mat list a_`year'_`pov_ind'
}
}
}

putexcel D4= matrix(a_2000_upperpoor') E4= matrix(a_2005_upperpoor') F4= matrix(a_2010_upperpoor') G4= matrix(a_2016_upperpoor') I4= matrix(a_2000_lowerpoor') J4= matrix(a_2005_lowerpoor') K4= matrix(a_2010_lowerpoor') L4= matrix(a_2016_lowerpoor'), nformat(percent_d2)
}

/*****************************************************************************************************
*                                                                                                    *
                             table poverty by sector urban rural national					
*                                                                                                    *
*****************************************************************************************************/

use `profiles',clear


*National
svyset psu [pweight=popwgt], strata(stratumharmonized) 



putexcel set "$output\overview_tables.xlsx", sheet(Table sector) modify

putexcel C12="Poverty rate with SE under" D2="2000" E2="2005" F2="2010" G2="2016"  I2="2000" J2="2005" K2="2010" L2="2016"  C3="Poverty by sector"  H3="Extreme poverty by sector" C4="Agriculture" C6="Services" C8="Industry" C10="Undefined", bold hcenter vcenter 

foreach pov_ind in upperpoor lowerpoor  {

foreach year in 2000 2005 2010 2016{
svy: mean `pov_ind' if year==`year', over(hh_fam_hmain_sect )

mat var_mat_`year'= e(V)
mat pov_mat_`year'= e(b)
mat a_`year'_`pov_ind'=[0,0,0,0,0,0,0,0,0,0,0,0,0,0]
loc aux = 1
foreach div in 1 2 3 4 5 6 7{
mat a_`year'_`pov_ind'[1,`aux']=pov_mat_`year'[1,`div']
loc aux = `aux'+1
mat a_`year'_`pov_ind'[1,`aux']=sqrt(var_mat_`year'[`div',`div'])
loc aux = `aux'+1
*mat list a_`year'_`pov_ind'
}
}
}

putexcel D4= matrix(a_2000_upperpoor') E4= matrix(a_2005_upperpoor') F4= matrix(a_2010_upperpoor') G4= matrix(a_2016_upperpoor') I4= matrix(a_2000_lowerpoor') J4= matrix(a_2005_lowerpoor') K4= matrix(a_2010_lowerpoor') L4= matrix(a_2016_lowerpoor'), nformat(percent_d2)


foreach ur_ru in urban rural{
putexcel set "$output\overview_tables.xlsx", sheet(Table `ur_ru' sector) modify

putexcel C12="Poverty rate with SE under" D2="2000" E2="2005" F2="2010" G2="2016"  I2="2000" J2="2005" K2="2010" L2="2016"  C3="Poverty by sector `ur_ru'"  H3="Extreme poverty by sector `ur_ru'" C4="Agriculture" C6="Services" C8="Industry" C10="Undefined", bold hcenter vcenter 

foreach pov_ind in upperpoor lowerpoor  {

foreach year in 2000 2005 2010 2016{
svy,subpop(`ur_ru'): mean `pov_ind' if year==`year', over(hh_fam_hmain_sect )

mat var_mat_`year'= e(V)
mat pov_mat_`year'= e(b)
mat a_`year'_`pov_ind'=[0,0,0,0,0,0,0,0,0,0,0,0,0,0]
loc aux = 1
foreach div in 1 2 3 4 5 6 7{
mat a_`year'_`pov_ind'[1,`aux']=pov_mat_`year'[1,`div']
loc aux = `aux'+1
mat a_`year'_`pov_ind'[1,`aux']=sqrt(var_mat_`year'[`div',`div'])
loc aux = `aux'+1
*mat list a_`year'_`pov_ind'
}
}
}

putexcel D4= matrix(a_2000_upperpoor') E4= matrix(a_2005_upperpoor') F4= matrix(a_2010_upperpoor') G4= matrix(a_2016_upperpoor') I4= matrix(a_2000_lowerpoor') J4= matrix(a_2005_lowerpoor') K4= matrix(a_2010_lowerpoor') L4= matrix(a_2016_lowerpoor'), nformat(percent_d2)

}

/*****************************************************************************************************
*                                                                                                    *
                             Ravallion and Huppi decomposition raw data						
*                                                                                                    *
*****************************************************************************************************/


*====================================================================================
*                              				    * figures 2.11 2.15
*====================================================================================

use `profiles', clear


svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)

putexcel set "$output\overview_tables.xlsx", sheet(Fig 2.11 2.15) modify

#delimit
putexcel B4="2000" 
C4="2005" 
D4="2010" 
E4="2016"  
F4="2000" 
G4="2005" 
H4="2010" 
I4="2016" 
A5="Agriculture"  
A6="Services" 
A7="Industry" 
A8="Undefined" 
A10="Total" 
J10="Total Change" 
B3="Share of population By sector" 
F3="Poverty Rates" 
B2="National"
, bold hcenter vcenter;


putexcel 
B16="2000" 
C16="2005" 
D16="2010" 
E16="2016"  
F16="2000" 
G16="2005" 
H16="2010" 
I16="2016" 
A17="Agriculture"  
A18="Services" 
A19="Industry" 
A20="Undefined" 
A22="Total" 
J22="Total Change" 
B15="Share of population By sector" 
F15="Poverty Rates" 
B14="Rural"
, bold hcenter vcenter;


putexcel B4="2000" 
C28="2005" 
D28="2010" 
E28="2016"  
F28="2000" 
G28="2005" 
H28="2010" 
I28="2016" 
A29="Agriculture"  
A30="Services" 
A31="Industry" 
A32="Undefined" 
A34="Total" 
J34="Total Change" 
B27="Share of population By sector" 
F27="Poverty Rates" 
B26="Urban"
, bold hcenter vcenter;

#delimit cr

*dummy by sector
tab hh_fam_hmain_sect, gen(hh_sec_) 


tabstat hh_sec_1 hh_sec_2 hh_sec_3 hh_sec_4 [aw=popwgt], by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B5=matrix(v_2000') C5=matrix(v_2005')  D5=matrix(v_2010')  E5=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

tabstat hh_sec_1 hh_sec_2 hh_sec_3 hh_sec_4 [aw=popwgt] if urbrural==1, by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B17=matrix(v_2000') C17=matrix(v_2005')  D17=matrix(v_2010')  E17=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

tabstat hh_sec_1 hh_sec_2 hh_sec_3 hh_sec_4 [aw=popwgt] if urbrural==2, by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B29=matrix(v_2000') C29=matrix(v_2005')  D29=matrix(v_2010')  E29=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

	
foreach y in  2000 2005 2010 2016{
tabstat upperpoor [aw=popwgt] if  year==`y', by(hh_fam_hmain_sect) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat j_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y']
mat list  j_`y'

tabstat upperpoor [aw=popwgt] if  year==`y' & urbrural==1, by(hh_fam_hmain_sect) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat j_ru_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y']

tabstat upperpoor [aw=popwgt] if  year==`y' & urbrural==2, by(hh_fam_hmain_sect) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat u_ur_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y']
}


putexcel F5=matrix(j_2000) G5=matrix(j_2005)  H5=matrix(j_2010)  I5=matrix(j_2016) , hcenter vcenter nformat(percent_d2)

putexcel F17=matrix(j_ru_2000) G17=matrix(j_ru_2005)  H17=matrix(j_ru_2010)  I17=matrix(j_ru_2016) , hcenter vcenter nformat(percent_d2)

putexcel F29=matrix(u_ur_2000) G29=matrix(u_ur_2005)  H29=matrix(u_ur_2010)  I29=matrix(u_ur_2016) , hcenter vcenter nformat(percent_d2)

*===============================================================================================
*                              				    * figures 2.11 2.15
*===============================================================================================


putexcel set "$output\overview_tables.xlsx", sheet(Fig 2.11.b) modify

#delimit
putexcel B4="2000" 
C4="2005" 
D4="2010" 
E4="2016"  
F4="2000" 
G4="2005" 
H4="2010" 
I4="2016" 
A5="Just Agriculture"  
A6="Just Services" 
A7="Just Industry" 
A8="Multiple Sectors"
A9="Undefined" 
B3="Share of population By sector" 
F3="Poverty Rates" 
B2="National"
, bold hcenter vcenter;


putexcel 
B16="2000" 
C16="2005" 
D16="2010" 
E16="2016"  
F16="2000" 
G16="2005" 
H16="2010" 
I16="2016" 
A17="Just Agriculture"  
A18="Just Services" 
A19="Just Industry" 
A20="Multiple Sectors" 
A21="Undefined" 
B15="Share of population By sector" 
F15="Poverty Rates" 
B14="Rural"
, bold hcenter vcenter;


putexcel B4="2000" 
C28="2005" 
D28="2010" 
E28="2016"  
F28="2000" 
G28="2005" 
H28="2010" 
I28="2016" 
A29="Just Agriculture"
A30="Just Services" 
A31="Just Industry" 
A32="Multiple Sectors"
A33="Undefined" 
B27="Share of population By sector" 
F27="Poverty Rates" 
B26="Urban"
, bold hcenter vcenter;

#delimit cr

*dummy by sector
tab hh_various_sector, gen(hh_vsec_) 


tabstat hh_vsec_1 hh_vsec_2 hh_vsec_3 hh_vsec_4 hh_vsec_5 [aw=popwgt], by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B5=matrix(v_2000') C5=matrix(v_2005')  D5=matrix(v_2010')  E5=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

tabstat hh_vsec_1 hh_vsec_2 hh_vsec_3 hh_vsec_4 hh_vsec_5 [aw=popwgt] if urbrural==1, by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B17=matrix(v_2000') C17=matrix(v_2005')  D17=matrix(v_2010')  E17=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

tabstat hh_vsec_1 hh_vsec_2 hh_vsec_3 hh_vsec_4 hh_vsec_5  [aw=popwgt] if urbrural==2, by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B29=matrix(v_2000') C29=matrix(v_2005')  D29=matrix(v_2010')  E29=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

	
foreach y in  2000 2005 2010 2016{
tabstat upperpoor [aw=popwgt] if  year==`y', by(hh_various_sector) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat j_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y']
mat list  j_`y'

tabstat upperpoor [aw=popwgt] if  year==`y' & urbrural==1, by(hh_various_sector) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat j_ru_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y']

tabstat upperpoor [aw=popwgt] if  year==`y' & urbrural==2, by(hh_various_sector) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat u_ur_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y']
}


putexcel F5=matrix(j_2000) G5=matrix(j_2005)  H5=matrix(j_2010)  I5=matrix(j_2016) , hcenter vcenter nformat(percent_d2)

putexcel F17=matrix(j_ru_2000) G17=matrix(j_ru_2005)  H17=matrix(j_ru_2010)  I17=matrix(j_ru_2016) , hcenter vcenter nformat(percent_d2)

putexcel F29=matrix(u_ur_2000) G29=matrix(u_ur_2005)  H29=matrix(u_ur_2010)  I29=matrix(u_ur_2016) , hcenter vcenter nformat(percent_d2)



*===============================================================================================
*                              				    * figures  2.16 2.17 
*===============================================================================================
putexcel set "$output\overview_tables.xlsx", sheet(Fig 2.16) modify


#delimit
putexcel B4="2000" 
C4="2005" 
D4="2010" 
E4="2016"  
F4="2000" 
G4="2005" 
H4="2010" 
I4="2016" 
A5="Agriculture"  
A6="Garment" 
A7="Other Manufacturing" 
A8="Construction" 
A9="Other Industry"
A10="Commerce" 
A11="Transport"
A12="Other Services"
A13="Undefined"

B3="Share of population By sector" 
F3="Poverty Rates" 
B2="National"
, bold hcenter vcenter;


putexcel 
B16="2000" 
C16="2005" 
D16="2010" 
E16="2016"  
F16="2000" 
G16="2005" 
H16="2010" 
I16="2016" 

A17="Agriculture"  
A18="Garment" 
A19="Other Manufacturing" 
A20="Construction" 
A21="Other Industry"
A22="Commerce" 
A23="Transport"
A24="Other Services"
A25="Undefined"

B15="Share of population By sector" 
F15="Poverty Rates" 
B14="Rural"
, bold hcenter vcenter;


putexcel B28="2000" 
C28="2005" 
D28="2010" 
E28="2016"  
F28="2000" 
G28="2005" 
H28="2010" 
I28="2016" 

A29="Agriculture"  
A30="Garment" 
A31="Other Manufacturing" 
A32="Construction" 
A33="Other Industry"
A34="Commerce" 
A35="Transport"
A36="Other Services"
A37="Undefined"

B27="Share of population By sector" 
F27="Poverty Rates" 
B26="Urban"
, bold hcenter vcenter;

#delimit cr

*dummy by sector
tab hh_fam_emp_secth, gen(hh_sec_det_) 


tabstat hh_sec_det_1 hh_sec_det_2 hh_sec_det_3 hh_sec_det_4 hh_sec_det_5 hh_sec_det_6 hh_sec_det_7 hh_sec_det_8 hh_sec_det_9  [aw=popwgt], by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B5=matrix(v_2000') C5=matrix(v_2005')  D5=matrix(v_2010')  E5=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

tabstat hh_sec_det_1 hh_sec_det_2 hh_sec_det_3 hh_sec_det_4 hh_sec_det_5 hh_sec_det_6 hh_sec_det_7 hh_sec_det_8 hh_sec_det_9 [aw=popwgt] if urbrural==1, by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B17=matrix(v_2000') C17=matrix(v_2005')  D17=matrix(v_2010')  E17=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

tabstat hh_sec_det_1 hh_sec_det_2 hh_sec_det_3 hh_sec_det_4 hh_sec_det_5 hh_sec_det_6 hh_sec_det_7 hh_sec_det_8 hh_sec_det_9 [aw=popwgt] if urbrural==2, by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)

putexcel B29=matrix(v_2000') C29=matrix(v_2005')  D29=matrix(v_2010')  E29=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

	
foreach y in  2000 2005 2010 2016{
tabstat upperpoor [aw=popwgt] if  year==`y', by(hh_fam_emp_secth) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat f_`y'=r(Stat6)
mat g_`y'=r(Stat7)
mat h_`y'=r(Stat8)
mat i_`y'=r(Stat9)
mat j_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y' \ f_`y' \ g_`y' \ h_`y' \ i_`y']


tabstat upperpoor [aw=popwgt] if  year==`y' & urbrural==1, by(hh_fam_emp_secth) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat f_`y'=r(Stat6)
mat g_`y'=r(Stat7)
mat h_`y'=r(Stat8)
mat i_`y'=r(Stat9)
mat j_ru_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y' \ f_`y' \ g_`y' \ h_`y' \ i_`y']

tabstat upperpoor [aw=popwgt] if  year==`y' & urbrural==2, by(hh_fam_emp_secth) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat f_`y'=r(Stat6)
mat g_`y'=r(Stat7)
mat h_`y'=r(Stat8)
mat i_`y'=r(Stat9)
mat u_ur_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y' \ f_`y' \ g_`y' \ h_`y' \ i_`y']
}


putexcel F5=matrix(j_2000) G5=matrix(j_2005)  H5=matrix(j_2010)  I5=matrix(j_2016) , hcenter vcenter nformat(percent_d2)

putexcel F17=matrix(j_ru_2000) G17=matrix(j_ru_2005)  H17=matrix(j_ru_2010)  I17=matrix(j_ru_2016) , hcenter vcenter nformat(percent_d2)

putexcel F29=matrix(u_ur_2000) G29=matrix(u_ur_2005)  H29=matrix(u_ur_2010)  I29=matrix(u_ur_2016) , hcenter vcenter nformat(percent_d2)



*====================================================================================
*                              				    * figures   2.17 
*====================================================================================
putexcel set "$output\overview_tables.xlsx", sheet(Fig 2.17) modify


#delimit
putexcel B4="2000" 
C4="2005" 
D4="2010" 
E4="2016"  
F4="2000" 
G4="2005" 
H4="2010" 
I4="2016" 
A5="Agriculture self-employment"  
A6="Agriculture wage" 
A7="Services self-employment" 
A8="Services wage" 
A9="Industry self-employment"
A10="Industry wage" 
A11="Undefined"

B3="Share of population By sector" 
F3="Poverty Rates" 
B2="National"
, bold hcenter vcenter;

putexcel 
B16="2000" 
C16="2005" 
D16="2010" 
E16="2016"  
F16="2000" 
G16="2005" 
H16="2010" 
I16="2016" 

A17="Agriculture self-employment"  
A18="Agriculture wage" 
A19="Services self-employment" 
A20="Services wage" 
A21="Industry self-employment"
A22="Industry wage" 
A23="Undefined"

B15="Share of population By sector" 
F15="Poverty Rates" 
B14="Rural"
, bold hcenter vcenter;


putexcel B4="2000" 
C28="2005" 
D28="2010" 
E28="2016"  
F28="2000" 
G28="2005" 
H28="2010" 
I28="2016" 

A29="Agriculture self-employment"  
A30="Agriculture wage" 
A31="Services self-employment" 
A32="Services wage" 
A33="Industry self-employment"
A34="Industry wage" 
A35="Undefined"

B27="Share of population By sector" 
F27="Poverty Rates" 
B26="Urban"
, bold hcenter vcenter;

#delimit cr

*dummy by sector
tab hh_emptypeh, gen(hh_typ_det_) 


tabstat hh_typ_det_1 hh_typ_det_2 hh_typ_det_3 hh_typ_det_4 hh_typ_det_5 hh_typ_det_6 hh_typ_det_7  [aw=popwgt], by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B5=matrix(v_2000') C5=matrix(v_2005')  D5=matrix(v_2010')  E5=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

tabstat hh_typ_det_1 hh_typ_det_2 hh_typ_det_3 hh_typ_det_4 hh_typ_det_5 hh_typ_det_6 hh_typ_det_7  [aw=popwgt] if urbrural==1, by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B17=matrix(v_2000') C17=matrix(v_2005')  D17=matrix(v_2010')  E17=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

tabstat hh_typ_det_1 hh_typ_det_2 hh_typ_det_3 hh_typ_det_4 hh_typ_det_5 hh_typ_det_6 hh_typ_det_7  [aw=popwgt] if urbrural==2, by(year) save
mat v_2000=r(Stat1)
mat v_2005=r(Stat2)
mat v_2010=r(Stat3)
mat v_2016=r(Stat4)
putexcel B29=matrix(v_2000') C29=matrix(v_2005')  D29=matrix(v_2010')  E29=matrix(v_2016') , hcenter vcenter nformat(percent_d2)

	
foreach y in  2000 2005 2010 2016{
tabstat upperpoor [aw=popwgt] if  year==`y', by(hh_emptypeh) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat f_`y'=r(Stat6)
mat g_`y'=r(Stat7)
mat j_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y' \ f_`y' \ g_`y']
mat list  j_`y'

tabstat upperpoor [aw=popwgt] if  year==`y' & urbrural==1, by(hh_emptypeh) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat f_`y'=r(Stat6)
mat g_`y'=r(Stat7)
mat j_ru_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y' \ f_`y' \ g_`y']

tabstat upperpoor [aw=popwgt] if  year==`y' & urbrural==2, by(hh_emptypeh) save
mat a_`y'=r(Stat1)
mat b_`y'=r(Stat2)
mat c_`y'=r(Stat3)
mat d_`y'=r(Stat4)
mat e_`y'=r(Stat5)
mat f_`y'=r(Stat6)
mat g_`y'=r(Stat7)
mat u_ur_`y'=[a_`y' \ b_`y' \ c_`y' \ d_`y' \ e_`y' \ f_`y' \ g_`y']
}


putexcel F5=matrix(j_2000) G5=matrix(j_2005)  H5=matrix(j_2010)  I5=matrix(j_2016) , hcenter vcenter nformat(percent_d2)

putexcel F17=matrix(j_ru_2000) G17=matrix(j_ru_2005)  H17=matrix(j_ru_2010)  I17=matrix(j_ru_2016) , hcenter vcenter nformat(percent_d2)

putexcel F29=matrix(u_ur_2000) G29=matrix(u_ur_2005)  H29=matrix(u_ur_2010)  I29=matrix(u_ur_2016) , hcenter vcenter nformat(percent_d2)


tabstat upperpoor if year==2010 & urbrural==2 [aw=popwgt], by(sector_h)

*/
/*****************************************************************************************************
*                                                                                                    *
                             Wald Test table A.1 Profiles poor non poor						
*                                                                                                    *
*****************************************************************************************************/

use `profiles',clear

* Profile of the poor for 2000, 2005, 2010 and 2016


*Wald test
svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)

glo indepvar2000 urban member depratio headage femalehead headmarried literatehead         remi_out remi_within	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2005 urban member depratio headage femalehead headmarried literatehead  earner remi_out remi_within		   social agri	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2010 urban member depratio headage femalehead headmarried literatehead  earner remi_out remi_within	micro  social agri	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2016 urban member depratio headage femalehead headmarried earner agri sectorhead_1 sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 edu7 land mobile electricity water sanitary remi_out remi_within micro social 

  
foreach year in 2016{
dis in red "`year'"
*foreach var in ${indepvar`year'} {
foreach var in ${indepvar`year'} {
dis in red "`var'"
*mean
svy: mean `var' if year==`year', over(upperpoor)
mat m_`var'=e(b)
dis in red `var'
*test
test [`var']_Not_poor=[`var']Poor
gen double pval_`var'_`year'=r(p)
mat pval_`var'=r(p)
tab  pval_`var'_`year'
*pval
gen p_`var'_`year'=""
replace  p_`var'_`year'="" if pval_`var'_`year'>0.1
replace  p_`var'_`year'="***" if pval_`var'_`year' <0.01
replace  p_`var'_`year'="**"  if pval_`var'_`year' >=0.01 & pval_`var'_`year' <0.05
replace  p_`var'_`year'="*"   if pval_`var'_`year' >=0.05 & pval_`var'_`year' <0.1

*mkmat p_`var'_`year' if _n==1, matrix(p_`var')
*mat to export
*mat e_`var'=[m_`var', pval_`var',p_`var']
mat e_`var'=[m_`var', pval_`var']

if "`var'"=="urban"{
	dis in red "`var'"
	mat res_`year'=e_`var'
	*mat list res_`year'
}

else if "`var'"!="urban" {
dis in red "else works!"
	*mat list res_`year'
    mat res_`year'=[res_`year' \ e_`var']
	mat list res_`year'
}
}
}

*export data
putexcel set "$output\overview_tables.xlsx", sheet(Table A.1) modify
putexcel C5=matrix(res_2016),nformat(percent_d2)

*export stars
loc n=5
foreach var in $indepvar2016{
 loc a="p_`var'_2016"
 dis in red `a'
 putexcel F`n'=`a' ,bold hcenter vcenter
 loc n=`n'+1
}

#delimit ;

putexcel	A2="Table A1. Characteristics of poor and non-poor households (average)" 
			A5="Demographics"                                                        
			A11="Labor market"                                                       
			A17="Human capital"                                                      
			A22="Assets"                                                             
			A27="Transfers and credit"                                               
			C3="Non-poor"                                                            
			D3="Poor"                                                                
			E3="Pvalue of difference (1)"                                              
 
			F3="Test of difference (1)"                               
			G3="Test of difference (2)" 
			,bold hcenter vcenter ;
			
putexcel 			
			B5="Household lives in an urban area (%)"
			B6="Household size"
			B7="Household dependency ratio (3)"
			B8="Age of household head"
			B9="Household head is female (%)"
			B10="Household head is married (%)"
			
			B11="Share of adults who are earners"
			B12="Share of adults in agriculture"
			B13="Household head in agriculture (%)"
			B14="Household head in industry (%)"
			B15="Household head in services (%)"
			B16="Household member has a chronic illness/disability"
			
			B17="Household head is literate (can write a letter, %)"
			B18="Household head has no education (%)"
			B19="Household head has some primary education (%)"
			B20="Household head has completed primary education (%)"
			B21="Household head has at least some secondary education (%)"
			
			B22="Household owns land (%)"
			B23="Household owns a mobile phone (%)"
			B24="Household has electricity (%)"
			B25="Household has piped water (%)"
			B26="Household has sanitary toilet (%)"
			
			B27="Household receives international remittances (%)"
			B28="Household receives domestic remittances (%)"
			B29="Household receives microcredit (%)"
			B30="Household receives social protection program (%)"
			B33="Source: Calculations using HIES 2000, 2005, 2010 and 2016. Note 1: Stars indicate whether mean for non-poor and poor is significantly different using a Wald test. Significance at the *10%, **5%, and *** 1% level. Note 2:  Significance values are calculated for each year separately including division fixed effects. Significance at the *10%, **5%, and *** 1% level of probit regression correcting for the clustered nature of the errors. Note 3: Dependency ratio was calculated as the population aged zero to 14 and over the age of 65, to the total population aged 15 to 65." ;
			

#d cr

*probit reg for 2016

glo indepvar2016 urban member depratio headage femalehead headmarried earner agri  sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 land mobile electricity water sanitary remi_out remi_within micro social 



xi: probit upperpoor $indepvar2016 i.division  [pw=hhwgt] if year==2016, vce(cluster psu)

glo indepvar2016 urban member depratio headage femalehead headmarried earner agri sectorhead_1 sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 edu7 land mobile electricity water sanitary remi_out remi_within micro social 


*for any $indepvar2016: gen pval_prob_X=2*normal(-abs(_b[X]/_se[X])
foreach x in $indepvar2016{
	cap gen p_prb_`x'=""
	dis in red "`x'"
	if "`x'"=="sectorhead_1" | "`x'"=="edu7"{
		replace p_prb_`x'="Ref. group"
		}
		dis in red "`x'"
	else if "`x'"!="sectorhead_1" & "`x'"!="edu7"{
	dis in red "`x'"
		cap gen pval_prob_`x'=2*normal(-abs(_b[`x']/_se[`x']))
		replace p_prb_`x'="***" if pval_prob_`x'<0.01
		replace p_prb_`x'="**" if pval_prob_`x'>=0.01 & pval_prob_`x'<0.05
		replace p_prb_`x'="*" if pval_prob_`x'>=0.05 & pval_prob_`x'<0.10
		}
}

*export stars
loc n=5
foreach var in $indepvar2016{
 loc a="p_prb_`var'"
 *loc b ="pval_prob_`var'"
 dis in red `a'
 *putexcel F`n'=`b' ,bold hcenter vcenter
 putexcel G`n'=`a' ,nformat(percent_d2)
 loc n=`n'+1
}

 


/*****************************************************************************************************
*                                                                                                    *
                             Wald Test table A.2 Profiles Urban Rural
*                                                                                                    *
*****************************************************************************************************/

use `profiles',clear

* Profile of the poor for 2000, 2005, 2010 and 2016


*Wald test
svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)

glo indepvar2000 urban member depratio headage femalehead headmarried literatehead         remi_out remi_within	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2005 urban member depratio headage femalehead headmarried literatehead  earner remi_out remi_within		   social agri	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2010 urban member depratio headage femalehead headmarried literatehead  earner remi_out remi_within	micro  social agri	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2016 urban member depratio headage femalehead headmarried earner agri sectorhead_1 sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 edu7 land mobile electricity water sanitary remi_out remi_within micro social 

*for subpopulation of rural
drop rural
recode urbrural_urb_fix (2=0),gen(rural)


foreach year in 2016{
dis in red "`year'"
*foreach var in ${indepvar`year'} {
foreach var in ${indepvar`year'} {
dis in red "`var'"
*mean
svy, subpop(rural) : mean `var' if year==`year', over(upperpoor)
mat m_`var'=e(b)
dis in red
*test
test [`var']_Not_poor=[`var']Poor
gen double pval_`var'_`year'=r(p)
mat pval_`var'=r(p)
tab  pval_`var'_`year'
*pval
gen p_`var'_`year'=""
replace  p_`var'_`year'="" if pval_`var'_`year'>0.1
replace  p_`var'_`year'="***" if pval_`var'_`year' <0.01
replace  p_`var'_`year'="**"  if pval_`var'_`year' >=0.01 & pval_`var'_`year' <0.05
replace  p_`var'_`year'="*"   if pval_`var'_`year' >=0.05 & pval_`var'_`year' <0.1

*mkmat p_`var'_`year' if _n==1, matrix(p_`var')
*mat to export
*mat e_`var'=[m_`var', pval_`var',p_`var']
mat e_`var'=[m_`var', pval_`var']

if "`var'"=="urban"{
	dis in red "`var'"
	mat res_`year'=e_`var'
	*mat list res_`year'
}

else if "`var'"!="urban" {
dis in red "else works!"
	*mat list res_`year'
    mat res_`year'=[res_`year' \ e_`var']
	mat list res_`year'
}
}
}

*export data
putexcel set "$output\overview_tables.xlsx", sheet(Table A.2 Rural) modify
putexcel C5=matrix(res_2016),nformat(percent_d2)

*export stars
loc n=5
foreach var in $indepvar2016{
 loc a="p_`var'_2016"
 dis in red `a'
 putexcel F`n'=`a' ,bold hcenter vcenter
 loc n=`n'+1
}

#delimit ;

putexcel	A2="Table A1. Characteristics of Rural Poor households (average)" 
			A5="Demographics"                                                        
			A11="Labor market"                                                       
			A17="Human capital"                                                      
			A22="Assets"                                                             
			A27="Transfers and credit"                                               
			C3="Non-Poor"                                                            
			D3="Poor"                                                                
			E3="Pvalue of difference (1)"                                              
 
			F3="Test of difference (1)"                               
			G3="Test of difference (2)" 
			,bold hcenter vcenter ;
			
putexcel 			
			B5="Household lives in an urban area (%)"
			B6="Household size"
			B7="Household dependency ratio (3)"
			B8="Age of household head"
			B9="Household head is female (%)"
			B10="Household head is married (%)"
			
			B11="Share of adults who are earners"
			B12="Share of adults in agriculture"
			B13="Household head in agriculture (%)"
			B14="Household head in industry (%)"
			B15="Household head in services (%)"
			B16="Household member has a chronic illness/disability"
			
			B17="Household head is literate (can write a letter, %)"
			B18="Household head has no education (%)"
			B19="Household head has some primary education (%)"
			B20="Household head has completed primary education (%)"
			B21="Household head has at least some secondary education (%)"
			
			B22="Household owns land (%)"
			B23="Household owns a mobile phone (%)"
			B24="Household has electricity (%)"
			B25="Household has piped water (%)"
			B26="Household has sanitary toilet (%)"
			
			B27="Household receives international remittances (%)"
			B28="Household receives domestic remittances (%)"
			B29="Household receives microcredit (%)"
			B30="Household receives social protection program (%)"
			B33="Source: Calculations using HIES 2000, 2005, 2010 and 2016. Note 1: Stars indicate whether mean for Rural non-poor and poor is significantly different using a Wald test. Significance at the *10%, **5%, and *** 1% level. Note 2:  Significance values are calculated for each year separately including division fixed effects. Significance at the *10%, **5%, and *** 1% level of probit regression correcting for the clustered nature of the errors. Note 3: Dependency ratio was calculated as the population aged zero to 14 and over the age of 65, to the total population aged 15 to 65." ;
			

#d cr

*probit reg for 2016

glo indepvar2016 urban member depratio headage femalehead headmarried earner agri  sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 land mobile electricity water sanitary remi_out remi_within micro social 



xi: probit upperpoor $indepvar2016 i.division  [pw=hhwgt] if year==2016, vce(cluster psu)

glo indepvar2016 urban member depratio headage femalehead headmarried earner agri sectorhead_1 sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 edu7 land mobile electricity water sanitary remi_out remi_within micro social 


*for any $indepvar2016: gen pval_prob_X=2*normal(-abs(_b[X]/_se[X])
foreach x in $indepvar2016{
	cap gen p_prb_`x'=""
	dis in red "`x'"
	if "`x'"=="sectorhead_1" | "`x'"=="edu7"{
		replace p_prb_`x'="Ref. group"
		}
		dis in red "`x'"
	else if "`x'"!="sectorhead_1" & "`x'"!="edu7"{
	dis in red "`x'"
		cap gen pval_prob_`x'=2*normal(-abs(_b[`x']/_se[`x']))
		replace p_prb_`x'="***" if pval_prob_`x'<0.01
		replace p_prb_`x'="**" if pval_prob_`x'>=0.01 & pval_prob_`x'<0.05
		replace p_prb_`x'="*" if pval_prob_`x'>=0.05 & pval_prob_`x'<0.10
		}
}

*export stars
loc n=5
foreach var in $indepvar2016{
 loc a="p_prb_`var'"
 *loc b ="pval_prob_`var'"
 dis in red `a'
 *putexcel F`n'=`b' ,bold hcenter vcenter
 putexcel G`n'=`a' ,nformat(percent_d2)
 loc n=`n'+1
}

/*****************************************************************************************************
*                                                                                                    *
                             Wald Test table A.3 Profiles Urban 
*                                                                                                    *
*****************************************************************************************************/

use `profiles',clear

* Profile of the poor for 2000, 2005, 2010 and 2016


*Wald test
svyset psu [pweight=hhwgt], strata(stratumharmonized) singleunit(centered)

glo indepvar2000 urban member depratio headage femalehead headmarried literatehead         remi_out remi_within	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2005 urban member depratio headage femalehead headmarried literatehead  earner remi_out remi_within		   social agri	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2010 urban member depratio headage femalehead headmarried literatehead  earner remi_out remi_within	micro  social agri	sectorhead_1 sectorhead_2 sectorhead_3 land mobile electricity water sanitary disability edu1 edu2 edu3 edu4 edu5 edu6
glo indepvar2016 urban member depratio headage femalehead headmarried earner agri sectorhead_1 sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 edu7 land mobile electricity water sanitary remi_out remi_within micro social 

*for subpopulation of rural
drop urban 
recode urbrural_urb_fix (2=1) (1=0),gen(urban)

  
foreach year in 2016{
dis in red "`year'"
*foreach var in ${indepvar`year'} {
foreach var in ${indepvar`year'} {
dis in red "`var'"
*mean
svy, subpop(urban) : mean `var' if year==`year', over(upperpoor)
mat m_`var'=e(b)
dis in red
*test
test [`var']_Not_poor=[`var']Poor
gen double pval_`var'_`year'=r(p)
mat pval_`var'=r(p)
tab  pval_`var'_`year'
*pval
gen p_`var'_`year'=""
replace  p_`var'_`year'="" if pval_`var'_`year'>0.1
replace  p_`var'_`year'="***" if pval_`var'_`year' <0.01
replace  p_`var'_`year'="**"  if pval_`var'_`year' >=0.01 & pval_`var'_`year' <0.05
replace  p_`var'_`year'="*"   if pval_`var'_`year' >=0.05 & pval_`var'_`year' <0.1

*mkmat p_`var'_`year' if _n==1, matrix(p_`var')
*mat to export
*mat e_`var'=[m_`var', pval_`var',p_`var']
mat e_`var'=[m_`var', pval_`var']

if "`var'"=="urban"{
	dis in red "`var'"
	mat res_`year'=e_`var'
	*mat list res_`year'
}

else if "`var'"!="urban" {
dis in red "else works!"
	*mat list res_`year'
    mat res_`year'=[res_`year' \ e_`var']
	mat list res_`year'
}
}
}

*export data
putexcel set "$output\overview_tables.xlsx", sheet(Table A.3 Urban) modify
putexcel C5=matrix(res_2016),nformat(percent_d2)

*export stars
loc n=5
foreach var in $indepvar2016{
 loc a="p_`var'_2016"
 dis in red `a'
 putexcel F`n'=`a' ,bold hcenter vcenter
 loc n=`n'+1
}

#delimit ;

putexcel	A2="Table A1. Characteristics of Urban Poor households (average)" 
			A5="Demographics"                                                        
			A11="Labor market"                                                       
			A17="Human capital"                                                      
			A22="Assets"                                                             
			A27="Transfers and credit"                                               
			C3="Non-Poor"                                                            
			D3="Poor"                                                                
			E3="Pvalue of difference (1)"                                              
			F3="Test of difference (1)"                               
			G3="Test of difference (2)" 
			,bold hcenter vcenter ;
			
putexcel 			
			B5="Household lives in an urban area (%)"
			B6="Household size"
			B7="Household dependency ratio (3)"
			B8="Age of household head"
			B9="Household head is female (%)"
			B10="Household head is married (%)"
			
			B11="Share of adults who are earners"
			B12="Share of adults in agriculture"
			B13="Household head in agriculture (%)"
			B14="Household head in industry (%)"
			B15="Household head in services (%)"
			B16="Household member has a chronic illness/disability"
			
			B17="Household head is literate (can write a letter, %)"
			B18="Household head has no education (%)"
			B19="Household head has some primary education (%)"
			B20="Household head has completed primary education (%)"
			B21="Household head has at least some secondary education (%)"
			
			B22="Household owns land (%)"
			B23="Household owns a mobile phone (%)"
			B24="Household has electricity (%)"
			B25="Household has piped water (%)"
			B26="Household has sanitary toilet (%)"
			
			B27="Household receives international remittances (%)"
			B28="Household receives domestic remittances (%)"
			B29="Household receives microcredit (%)"
			B30="Household receives social protection program (%)"
			B33="Source: Calculations using HIES 2000, 2005, 2010 and 2016. Note 1: Stars indicate whether mean for Urban non-poor and poor is significantly different using a Wald test. Significance at the *10%, **5%, and *** 1% level. Note 2:  Significance values are calculated for each year separately including division fixed effects. Significance at the *10%, **5%, and *** 1% level of probit regression correcting for the clustered nature of the errors. Note 3: Dependency ratio was calculated as the population aged zero to 14 and over the age of 65, to the total population aged 15 to 65." ;
			

#d cr

*probit reg for 2016

glo indepvar2016 urban member depratio headage femalehead headmarried earner agri  sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 land mobile electricity water sanitary remi_out remi_within micro social 



xi: probit upperpoor $indepvar2016 i.division  [pw=hhwgt] if year==2016, vce(cluster psu)

glo indepvar2016 urban member depratio headage femalehead headmarried earner agri sectorhead_1 sectorhead_3 sectorhead_2 disability literatehead edu1 edu2 edu3 edu7 land mobile electricity water sanitary remi_out remi_within micro social 


*for any $indepvar2016: gen pval_prob_X=2*normal(-abs(_b[X]/_se[X])
foreach x in $indepvar2016{
	cap gen p_prb_`x'=""
	dis in red "`x'"
	if "`x'"=="sectorhead_1" | "`x'"=="edu7"{
		replace p_prb_`x'="Ref. group"
		}
		dis in red "`x'"
	else if "`x'"!="sectorhead_1" & "`x'"!="edu7"{
	dis in red "`x'"
		cap gen pval_prob_`x'=2*normal(-abs(_b[`x']/_se[`x']))
		replace p_prb_`x'="***" if pval_prob_`x'<0.01
		replace p_prb_`x'="**" if pval_prob_`x'>=0.01 & pval_prob_`x'<0.05
		replace p_prb_`x'="*" if pval_prob_`x'>=0.05 & pval_prob_`x'<0.10
		}
}

*export stars
loc n=5
foreach var in $indepvar2016{
 loc a="p_prb_`var'"
 *loc b ="pval_prob_`var'"
 dis in red `a'
 *putexcel F`n'=`b' ,bold hcenter vcenter
 putexcel G`n'=`a' ,nformat(percent_d2)
 loc n=`n'+1
}


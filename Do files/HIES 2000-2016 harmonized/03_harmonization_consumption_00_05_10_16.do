/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                        HARMONIZATION CONSUMPTION 2000, 2005, 2010, 2016                          **
**                                                                                                  **
** COUNTRY	Bangladesh
** COUNTRY ISO CODE	BGD
** YEAR	2016
** SURVEY NAME	HOUSEHOLD INCOME AND EXPENDITURE SURVEY 2016
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS
** Modified	12/19/2017
**                                                                                                  **
*****************************************************************************************************/

/*This dofile creates real per capita consumption expenditures for HIES 2000 to 2016 */

/*****************************************************************************************************
*                                                                                                    *
                                         INITIAL COMMANDS
*	                                                                                                 *
*****************************************************************************************************/
** INITIAL COMMANDS
   clear
   set more off, perm

   
   
/*****************************************************************************************************
*                                                                                                    *
                                ASSEMBLE CONSUMPTION 2000, 2005, 2010
*                                                                                                    *
*****************************************************************************************************/

use "$input10/consumption_00_05_10", clear

recode year (1=2000) (2=2005) (3=2010)  
gen year2=year
drop year
rename year2 year

glo var1 year id wgt popwgt member stratum urbrural p_cons pcexp ///
zu00 zu05 zu10 zl00 zl05 zl10 zf00 zf05 zf10 znf00 znf05 znf10 
keep $var1

rename (stratum id wgt) (stratum16 hhid hhwgt)
destring stratum16 hhid, replace
sort year hhid
replace pcexp=p_cons if year==2010

*Food poverty line
gen     zf=zf00 if year==2000
replace zf=zf05 if year==2005
replace zf=zf10 if year==2010

*Lower poverty line
gen     zl=zl00 if year==2000
replace zl=zl05 if year==2005
replace zl=zl10 if year==2010

*Upper poverty line
gen     zu=zu00 if year==2000
replace zu=zu05 if year==2005
replace zu=zu10 if year==2010

*Upper non-food allowance
gen     znfu=znf00 if year==2000
replace znfu=znf05 if year==2005
replace znfu=znf10 if year==2010

preserve
*Calculating household size for year 2010
use "$input10/rt002", clear
gen psu1= string(psu,"%003.0f")
gen hhold1= string(hhold,"%003.0f")
drop psu hhold
rename (psu1 hhold1) (psu hhold)
gen hhid=psu+hhold
gen hhcode=real(hhid)
egen member10= count(idcode), by(hhcode)
duplicates drop hhcode, force
keep hhcode member10
rename hhcode hhid
gen year=2010
tempfile member10
save `member10', replace
restore

merge 1:1 year hhid using `member10'
tab _m
drop _m
replace member=member10 if year==2010
drop member10 

*Get psu variable for every year
preserve 
use  "$output/final00_16_household.dta", clear
keep if inlist(year,2000,2005,2010)
keep year hhid psu division
tempfile hh
save `hh', replace
restore

merge 1:1 year hhid using `hh'
tab _m
drop if _m==2
tab year 

gen stratum=stratum16
gen stratum16comparable=stratum16
gen urbruralcomparable=urbrural 

glo var2 year psu hhid hhwgt popwgt member division stratum stratum16  urbrural stratum16comparable urbruralcomparable zf zl zu znfu pcexp
keep  $var2
order $var2
sort year hhid stratum16

bysort year: table stratum [aw=popwgt], c(m zf m zl m zu m znfu)
bysort year: table stratum [aw=popwgt], c(m pcexp m member)

label var psu     "Primary sampling unit"
la var year       "Survey year"
la var hhid       "Household id"
la var hhwgt      "Household weight"
la var popwgt     "Population weight"
la var member     "Household size"
la var stratum16  "16 Stratums for all years"
la var division   "7 administrative divisions"
la var urbrural   "1 Rural, 2 Urban"
la var pcexp      "Nominal monthly per capita expenditure"
la var zf         "Food poverty line"
la var zl         "Lower poverty line" 
la var zu         "Upper poverty line"
la var znfu       "Upper non-food allowance 2000, 2005, 2010"


/*****************************************************************************************************
*                                                                                                    *
                                SPATIAL ADJUSTMENT 2000, 2005, 2010
*                                                                                                    *
*****************************************************************************************************/

*1) Create national poverty line (population weighted) in LCU (monthly) for each year

g pline_nat=.
forval i=2000(5)2010{
sum zu [aw=popwgt] if year==`i'
replace pline_nat=r(mean) if year==`i'
}

table year [aw=popwgt], c(mean pline_nat)
la var pline_nat "National poverty line population weighted"

/*2) Create nominal montly per capita expenditure (deflated across space only) using 
national poverty line (population weighted) */

g spindex=zu/pline_nat
g realpcexp=pcexp/spindex if pcexp~=.
table year [aw=popwgt], c(mean pcexp mean realpcexp)

lab var realpcexp "Nominal monthly per capita expenditure (deflated across space only)"
note realpcexp: Variable deflated using as deflators the prices implicit in the ///
			    population weighted national poverty lines. Nominal expenditure ///
			    have not been deflated across time.
la var spindex    "Spatial deflator"
				

/*3) The variables food, non-food expenditure, rent, imputed rent, predicted rent 
were computed as part of a replication exercise for years 2000, 2005 and 2016 
because they were not available in the official poverty database "consumption_00_05_10.dta"  */	


preserve
forval i=2000(5)2010{
use "${pov`i'}/poverty_indicators", clear
gen year=`i'
tempfile pov`i'
save `pov`i'', replace
}

use `pov2000'
append using `pov2005'
append using `pov2010'

keep year hhcode fexp consexp2 nfexp2 rent imprent pr_rent hsvalhh 
rename hhcode hhid
tempfile replicatedcons
save `replicatedcons', replace
restore

*Merge with official per capita consumption database
merge 1:1 year hhid using `replicatedcons'
tab _m
drop _m

tempfile consumption2000_2010
save `consumption2000_2010'
			
/*****************************************************************************************************
*                                                                                                    *
                                    APPEND WITH CONSUMPTION 2016 A
*                                                                                                    *
*****************************************************************************************************/	
		
preserve
use "$cons16\poverty_indicators2016_detailed", clear
g year=2016
rename (division_code zf16 zl16 zu16) (division zf zl zu)

#delimit ;
glo vars year quarter psu hhid hhwgt popwgt member division stratum stratum16 urbrural stratum16comparable urbruralcomparable
zf zl zu zf16quarters zu16quarters zl16quarters lowerpoorquarters upperpoorquarters
pcexp rent imprent pr_rent hsvalhh fexp consexp2 nfexp2;
#delimit cr 
keep $vars
order $vars
 
 
*Create 7 divisions	

/*Mymensingh Division was created in 2015 from districts previously comprising the northern part of Dhaka Division.
We combine Mymensingh with Dhaka in this database */
replace  division=30 if division==45

	
*1) In order to compute all the indicators, we remove those households who do not have per capita expenditure 
drop if pcexp==.


*2) Create national poverty line (population weighted) in LCU (monthly) for each year

sum zu [aw=popwgt] 
gen pline_nat=r(mean) 

table year [aw=popwgt], c(mean pline_nat)
la var pline_nat "National poverty line population weighted"


/*3) Create nominal montly per capita expenditure (deflated across space only) using 
national poverty line (population weighted) */

g spindex=zu/pline_nat
g realpcexp=pcexp/spindex if pcexp~=.
table year [aw=popwgt], c(mean pcexp mean realpcexp)

lab var realpcexp "Nominal monthly per capita expenditure (deflated across space only)"
note realpcexp: Variable deflated using as deflators the prices implicit in the ///
			    population weighted national poverty lines. Nominal expenditure ///
			    have not been deflated across time.
la var spindex    "Spatial deflator"


sort year hhid stratum16
tempfile cons2016
save `cons2016', replace
restore 
		

***Append 2000, 2005, 2010 with 2016 
append using `cons2016'
order stratum, after(hhid)
order stratum16 stratum16comparable, after(stratum)		
		
***Create poverty variables

gen lowerpoor=pcexp<zl if pcexp!=.
la var lowerpoor "People below lower poverty lines"

gen upperpoor=pcexp<zu if pcexp!=.
la var upperpoor "People below upper poverty lines"

gen lowerpoorper=lowerpoor*100
la var lowerpoorper "People below lower poverty lines (%)"

gen upperpoorper=upperpoor*100
la var upperpoorper "People below upper poverty lines (%)"

*Quarters 2016
gen lowerpoorquarterper=lowerpoorquarters*100
la var lowerpoorquarterper "People below quarterly lower poverty lines 2016 (%)"

gen upperpoorquarterper=upperpoorquarters*100
la var upperpoorquarterper "People below quarterly upper poverty lines 2016 (%)"
		
		
la val lowerpoor poor 
la val upperpoor poor 
la val lowerpoorper poor
la val upperpoorper poor


la var stratum "Stratum 132 for 2016, stratum 16 for previous years"
la var stratum16 "Stratum 16 original for 2016, not changes for previous years"
la var stratum16comparable "Stratum 16 comparable to previous years"
la var urbruralcomparable  "1 Rural, 2 Urban comparable to previous years"


/*****************************************************************************************************
*                                                                                                    *
                                           TEMPORAL ADJUSTMENTS 
*                                                                                                    *
*****************************************************************************************************/

*1) Express all consumptions in 2016 prices using the national poverty line population weighted from 2016 

gen pline_nat16_=pline_nat if year==2016   
egen pline_nat16=mean(pline_nat16), by (stratum16)
drop pline_nat16_

g timedef=pline_nat16/pline_nat

*Time deflator across years
table year,c(m timedef) 

*Per capita expenditure deflated across space and at 2016 prices
g realpce=realpcexp*timedef 
table year,c(m pcexp m realpcexp m realpce) 


la var pline_nat16  "National poverty line population weighted 2016"
la var realpce "Monthly per capita expenditure deflated across space and at 2016 prices"
la var timedef "Time deflator base 2016"
la var quarter "Quarters 2016"
sort year psu hhid
format hhid %10.0f


/*****************************************************************************************************
*                                                                                                    *
                                            QUINTILES
*                                                                                                    *
*****************************************************************************************************/

*Quintiles

xtile q_cons1=realpce [aw=popwgt] if year==2000, nq(5)
xtile q_cons2=realpce [aw=popwgt] if year==2005, nq(5)
xtile q_cons3=realpce [aw=popwgt] if year==2010, nq(5)
xtile q_cons4=realpce [aw=popwgt] if year==2016, nq(5)

g       qcons5= q_cons1 if year==2000
replace qcons5= q_cons2 if year==2005
replace qcons5= q_cons3 if year==2010
replace qcons5= q_cons4 if year==2016
drop q_cons*
la var qcons5 "Quintiles for each year using realpce"

for any urbrural urbruralcomparable zf zl zu znfu pcexp pline_nat spindex realpcexp rent imprent pr_rent hsvalhh fexp consexp2 nfexp2 quarter zf16quarters zu16quarters zl16quarters lowerpoorquarters upperpoorquarters lowerpoor upperpoor lowerpoorper upperpoorper lowerpoorquarterper upperpoorquarterper pline_nat16 timedef realpce qcons5: rename X X_a

label data "Consumption for 2000 to 2016 estimates, _a and _b have different urban and rural classifications for 2016 estimates (_b was used to produce the 2016 Poverty Assesment)"


tempfile consumption2000_2016_a
save `consumption2000_2016_a'


/*****************************************************************************************************
*                                                                                                    *
                        APPEND WITH CONSUMPTION 2016 B (urban urban change)
*                                                                                                    *
*****************************************************************************************************/	

use `consumption2000_2010'
	
preserve
use "$cons16_b\poverty_indicators2016_detailed", clear
g year=2016
rename (division_code zf16 zl16 zu16) (division zf zl zu)

#delimit ;
glo vars year quarter psu hhid hhwgt popwgt member division stratum stratum16 urbrural stratum16comparable urbruralcomparable
zf zl zu zf16quarters zu16quarters zl16quarters lowerpoorquarters upperpoorquarters
pcexp rent imprent pr_rent hsvalhh fexp consexp2 nfexp2;
#delimit cr 
keep $vars
order $vars
 
 
*Create 7 divisions	

/*Mymensingh Division was created in 2015 from districts previously comprising the northern part of Dhaka Division.
We combine Mymensingh with Dhaka in this database */
replace  division=30 if division==45

	
*1) In order to compute all the indicators, we remove those households who do not have per capita expenditure 
drop if pcexp==.


*2) Create national poverty line (population weighted) in LCU (monthly) for each year

sum zu [aw=popwgt] 
gen pline_nat=r(mean) 

table year [aw=popwgt], c(mean pline_nat)
la var pline_nat "National poverty line population weighted"


/*3) Create nominal montly per capita expenditure (deflated across space only) using 
national poverty line (population weighted) */

g spindex=zu/pline_nat
g realpcexp=pcexp/spindex if pcexp~=.
table year [aw=popwgt], c(mean pcexp mean realpcexp)

lab var realpcexp "Nominal monthly per capita expenditure (deflated across space only)"
note realpcexp: Variable deflated using as deflators the prices implicit in the ///
			    population weighted national poverty lines. Nominal expenditure ///
			    have not been deflated across time.
la var spindex    "Spatial deflator"


sort year hhid stratum16
tempfile cons2016
save `cons2016', replace
restore 
		

***Append 2000, 2005, 2010 with 2016 
append using `cons2016'
order stratum, after(hhid)
order stratum16 stratum16comparable, after(stratum)		
		
***Create poverty variables

gen lowerpoor=pcexp<zl if pcexp!=.
la var lowerpoor "People below lower poverty lines"

gen upperpoor=pcexp<zu if pcexp!=.
la var upperpoor "People below upper poverty lines"

gen lowerpoorper=lowerpoor*100
la var lowerpoorper "People below lower poverty lines (%)"

gen upperpoorper=upperpoor*100
la var upperpoorper "People below upper poverty lines (%)"

*Quarters 2016
gen lowerpoorquarterper=lowerpoorquarters*100
la var lowerpoorquarterper "People below quarterly lower poverty lines 2016 (%)"

gen upperpoorquarterper=upperpoorquarters*100
la var upperpoorquarterper "People below quarterly upper poverty lines 2016 (%)"
		
		
la val lowerpoor poor 
la val upperpoor poor 
la val lowerpoorper poor
la val upperpoorper poor


la var stratum "Stratum 132 for 2016, stratum 16 for previous years"
la var stratum16 "Stratum 16 original for 2016, not changes for previous years"
la var stratum16comparable "Stratum 16 comparable to previous years"
la var urbruralcomparable  "1 Rural, 2 Urban comparable to previous years"


/*****************************************************************************************************
*                                                                                                    *
                                           TEMPORAL ADJUSTMENTS 
*                                                                                                    *
*****************************************************************************************************/

*1) Express all consumptions in 2016 prices using the national poverty line population weighted from 2016 

gen pline_nat16_=pline_nat if year==2016   
egen pline_nat16=mean(pline_nat16), by (stratum16)
drop pline_nat16_

g timedef=pline_nat16/pline_nat

*Time deflator across years
table year,c(m timedef) 

*Per capita expenditure deflated across space and at 2016 prices
g realpce=realpcexp*timedef 
table year,c(m pcexp m realpcexp m realpce) 


la var pline_nat16  "National poverty line population weighted 2016"
la var realpce "Monthly per capita expenditure deflated across space and at 2016 prices"
la var timedef "Time deflator base 2016"
la var quarter "Quarters 2016"
sort year psu hhid
format hhid %10.0f


/*****************************************************************************************************
*                                                                                                    *
                                            QUINTILES
*                                                                                                    *
*****************************************************************************************************/

*Quintiles

xtile q_cons1=realpce [aw=popwgt] if year==2000, nq(5)
xtile q_cons2=realpce [aw=popwgt] if year==2005, nq(5)
xtile q_cons3=realpce [aw=popwgt] if year==2010, nq(5)
xtile q_cons4=realpce [aw=popwgt] if year==2016, nq(5)

g       qcons5= q_cons1 if year==2000
replace qcons5= q_cons2 if year==2005
replace qcons5= q_cons3 if year==2010
replace qcons5= q_cons4 if year==2016
drop q_cons*
la var qcons5 "Quintiles for each year using realpce"

for any urbrural urbruralcomparable zf zl zu znfu pcexp pline_nat spindex realpcexp rent imprent pr_rent hsvalhh fexp consexp2 nfexp2 quarter zf16quarters zu16quarters zl16quarters lowerpoorquarters upperpoorquarters lowerpoor upperpoor lowerpoorper upperpoorper lowerpoorquarterper upperpoorquarterper pline_nat16 timedef realpce qcons5: rename X X_b


label data "Consumption for 2000 to 2016 estimates, _a and _b have different urban and rural classifications for 2016 estimates (_b was used to produce the 2016 Poverty Assesment)"


tempfile consumption2000_2016_b
save `consumption2000_2016_b'


use `consumption2000_2016_a'

merge 1:1 year psu hhid using `consumption2000_2016_b'
drop _merge

label data "Consumption for 2000 to 2016 estimates, for details on _a and _b see notes "
note: "Consumption for 2000 to 2016 estimates, _a and _b have different urban and rural classifications for 2016 estimates (_b was used to produce the 2016 Poverty Assesment) to undestand the diference plese see Chapter 1 of Volume 2 of the Poverty Assessmet 2016"

save "$output/consumption2000_2016",replace
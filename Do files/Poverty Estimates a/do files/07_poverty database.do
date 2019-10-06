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
** Modified	      05_20_2019                                                                                              
******************************************************************************************************
*****************************************************************************************************/
/*This do file assembles the database to compute all the poverty numbers */
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
                               CREATE DATABASE TO COMPUTE POVERTY RATES
*                                                                                                    *
*****************************************************************************************************/

	use "$output/expenditure_2016", clear
	
	*Merge with household size database
	merge 1:1 hhold using "$temporary/memberall"
	tab _m
	drop if _merge==2
	drop if member==.
	drop _merge

	
	*Merge with quarterly poverty lines
    rename qtr quarter
	merge m:1 stratum16 quarter using "$output/povline16quarters"
	tab _m
    drop _m
	
	rename (zf16 zu16 zl16 share10 share16 tt x index nfcpi) (zf16quarters zu16quarters zl16quarters share10quarters share16quarters ttquarters xquarters indexquarters nfcpiquarters)
    drop zf10 zu10 zl10 zf10 zu10
		
		
	*Merge with annual poverty lines database
	merge m:1 stratum16 using "$output/povline16all"
	tab _m
	drop _m
	
	
	*Create annual population weights
	gen popwgt=hhwgt*member
	
	
	*Create Per capita consumption
	gen pcexp=consexp2/member

	
	
	*Calculate Expenditure variable (Consumption + lumpy expenditures)
	preserve
	use "$input/HH_SEC_9D2_Q1Q2Q3Q4", clear
	drop if s9d2q00==.

	*There are not repeated observations	
	rename (s9d2q00 s9d2q01) (item value)	
	duplicates report hhid item
	drop if mod(item,10)==0

    keep if inrange(item,466,472) | inlist(item, 501, 502) | inrange(item, 561,563)
	collapse (sum) lumpyexp=value, by(psu hhid hhid)
	replace lumpyexp=lumpyexp/12
    save "$temporary/lumpyexpenditure", replace
	restore
	
	
	*Merge with lumpy expenditure
	merge 1:1 hhid using "$temporary/lumpyexpenditure"
	tab _m
	drop if _m==2
	drop _m
		
	
	*Add geographical variables
	merge 1:1 hhid using "$input/HH_SEC_A_Q1Q2Q3Q4.dta", keepusing(id_01_name zl id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name) 
	keep if _m==3
	drop _m	
		
	*Create household and per capita expenditures (Consumption + lumpy expenditures)
	egen  hexpend =rowtotal(consexp2 lumpyexp)
	gen   pcexpend=hexpend/member	
	
		
	*Create quarterly poverty rates 
	gen lowerpoorquarters=pcexp<zl16quarters if pcexp!=.
	gen upperpoorquarters=pcexp<zu16quarters if pcexp!=.
	

	*Create quarterly Foster-Greer-Thorbecke poverty indices 
	gen aux_lower=zl16quarters
	gen aux_upper=zu16quarters
	
	gen fgt0q_lower = (pcexp<=aux_lower) 
	gen fgt1q_lower = fgt0q_lower*(1-pcexp/aux_lower) 
	gen fgt2q_lower = fgt0q_lower*(1-pcexp/aux_lower)^2 
	
	gen fgt0q_upper = (pcexp<=aux_upper) 
	gen fgt1q_upper = fgt0q_upper*(1-pcexp/aux_upper) 
	gen fgt2q_upper = fgt0q_upper*(1-pcexp/aux_upper)^2 
	
	drop aux_upper aux_lower	
	
    *Create annual poverty rates 
	gen lowerpoor=pcexp<zl16 if pcexp!=.
	gen upperpoor=pcexp<zu16 if pcexp!=.
	
	
	*Create annual Foster-Greer-Thorbecke poverty indices 
	gen aux_lower=zl16
	gen aux_upper=zu16

	gen fgt0_lower = (pcexp<=aux_lower) 
	gen fgt1_lower = fgt0_lower*(1-pcexp/aux_lower) 
	gen fgt2_lower = fgt0_lower*(1-pcexp/aux_lower)^2 

	gen fgt0_upper = (pcexp<=aux_upper) 
	gen fgt1_upper = fgt0_upper*(1-pcexp/aux_upper) 
	gen fgt2_upper = fgt0_upper*(1-pcexp/aux_upper)^2 
		
	drop aux_upper aux_lower
	
	la de poor 0 "Not poor" 1 "Poor"
	la val lowerpoor poor 
	la val upperpoor poor 
	la val lowerpoorquarters poor
	la val upperpoorquarters poor
	
		
    *Create national poverty line (population weighted) in LCU (monthly) 
    sum zu16 [aw=popwgt] 
    gen pline_nat=r(mean) 
    la var pline_nat "National poverty line population weighted"


   /*Create nominal montly per capita expenditure (deflated across space only) using 
   national poverty line (population weighted) */

   g spindex=zu16/pline_nat
   g rpcexp=pcexp/spindex if pcexp~=.

   lab var rpcexp "Nominal monthly per capita expenditure (deflated across space only)"
   note rpcexp: Variable deflated using as deflators the prices implicit in the ///
			    population weighted national poverty lines. Nominal expenditure ///
			    have not been deflated across time.
   la var spindex    "Spatial deflator" 
	
	
	
	************************Components of consumption***************************
	*Per capita
	g pcfexp=fexp/member 
	g pcnfexp=nfexp2/member 
	g pcrent=rent/member
	g pcimprent=imprent/member
	g pcprrent=pr_rent/member
	
	*Per capita expenditures spatially deflated
	g rpcfe=pcfexp/spindex 
	g rpcnfe=pcnfexp/spindex 
	g rpcrent=pcrent/spindex
    g rpcimprent=pcimprent/spindex
	g rpcprrent=pcprrent/spindex
	
	*Household expenditures spatially deflated
	g rhexp=consexp2/spindex 
	g rhfe=fexp/spindex 
	g rhnfe=nfexp2/spindex 
	g rhrent=rent/spindex
    g rhimprent=imprent/spindex
	g rhprrent=pr_rent/spindex
	
	*Expenditure (Consumption + lumpy expenditures)
	gen   rhexpend=hexpend/spindex
	gen   rpcexpend=pcexpend/spindex
	
	
	
/*****************************************************************************************************
*                                                                                                    *
                                        INCORPORATE INCOME
*                                                                                                    *
*****************************************************************************************************/
	
merge 1:1 hhid using "$output\household_income2016", generate(merge_inc) keepusing(hhincome) 
tab merge_inc
drop if  merge_inc==2
drop  merge_inc

*Per capita Income
gen pcincome=hhincome/member

*Real Household Income
g rhhincome=hhincome/spindex  

*Real Per Capita Income
gen rpcincome=pcincome/spindex  if hhincome>=0


/*****************************************************************************************************
*                                                                                                    *
                             CREATE STRATUM 16 COMPARABLE TO PREVIOUS YEARS
*                                                                                                    *
*****************************************************************************************************/


*Create variable stratum 16 that is comparable with previous years
preserve
use "$input2010/Mr Faiz/mza_hh_pop_2011",clear
keep mzaid rmo rmo_new ruc
rename ruc ruc_new
sort mzaid
tempfile temp1
save `temp1',replace


use "$input/HH_SEC_A_Q1Q2Q3Q4",clear
rename id_03_code upz
rename id_04_code uni
rename id_05_code mza
gen double mzaid=((zl*100+upz)*100+uni)*1000+mza
sort mzaid
merge mzaid using `temp1'
tab _m
keep if _m==3

** to put rmo code of barisal  & sylhet city corporation to 2 instead of 9 **
replace rmo_new=2 if (stratum==2 | stratum==16) & rmo_new==9
replace ruc_new=1 if rmo_new==1 
replace ruc_new=2  if  rmo_new==2 | rmo_new==3 | rmo_new==4 | rmo_new==5
replace ruc_new=3 if rmo_new==9

cap drop strat_new
gen     strat_new=1 if div==10 & ruc_new==1
replace strat_new=2 if div==10 & ruc_new==2

replace strat_new=3 if div==20 & ruc_new==1
replace strat_new=4 if (div==20 & ruc_new==2)  
replace strat_new=5 if zl==15 & (ruc_new==2 | ruc_new==3) & (upz==06 | upz==10 | upz==19 | upz==20 | upz==28 ///
     |  upz==35 | upz==37 |upz==39 | upz==41 | upz==43 | upz==55 ///
     |  upz==57 | upz==61 | upz==65 | upz==86)
     
replace strat_new=6 if (div==30 | div==45) & ruc_new==1
replace strat_new=7 if (div==30 | div==45)  & ruc_new==2
replace strat_new=8 if zl==26 & (ruc_new==2 | ruc_new==3) & (upz==02 | upz==04 | upz==05 | upz==06   /// 
   | upz==08 | upz==09 | upz==10 | upz==11   | upz==12 | upz==16 | upz==24 | upz==26 ///
      | upz==28 | upz==29 | upz==30 | upz==32 |upz==33 | upz==34 | upz==36 ///
       | upz==37 | upz==38 | upz==40 | upz==42 ///
      | upz==48 | upz==50 | upz==54 | upz==63 | upz==64 | upz==65 | upz==66 | upz==67 ///
      |  upz==68 | upz==72 | upz==74 | upz==75 | upz==76 | upz==80 |  upz==88 | upz==90 ///
      | upz==92 | upz==93 | upz==95 | upz==96 ) 
replace strat_new=8 if zl==33 & (ruc_new==2 | ruc_new==3) & upz==30 
replace strat_new=8 if zl==67 & (ruc_new==2 | ruc_new==3) & (upz==06 | upz==58) 
   
replace strat_new=9  if div==40 & ruc_new==1
replace strat_new=10 if div==40 & ruc_new==2
replace strat_new=11 if zl==47 & (ruc_new==2 | ruc_new==3) & (upz==21 | upz==40 | upz==45 | upz==48 ///
 | upz==51 | upz==75 | upz==85)
   
replace strat_new=12 if (div==50 | div==55) & ruc_new==1
replace strat_new=13 if (div==50 | div==55) & ruc_new==2
replace strat_new=14 if zl==81 & (ruc_new==2 | ruc_new==3) & (upz==22 | upz==40 | upz==72 | upz==85 | upz==90)
	   
replace strat_new=15 if div==60 & ruc_new==1
replace strat_new=16 if div==60 & (ruc==2| ruc==3)

keep hhid rmo_new ruc_new strat_new
rename (strat_new ruc_new) (stratum16comparable ruccomparable)

g 		urbruralcomparable=.
replace urbruralcomparable=1 if ruccomparable==1
replace urbruralcomparable=2 if (ruccomparable==2 | ruccomparable==3)	 
la var  urbruralcomparable " 1 Rural, 2 Urban"
la de urbruralcomparable    1"Rural" 2"Urban"
la val urbruralcomparable urbruralcomparable

keep hhid stratum16comparable ruccomparable urbruralcomparable
tempfile stratum16comparable
save `stratum16comparable', replace
restore 


*Merge with stratum 16 comparable
merge 1:1 hhid using `stratum16comparable'	
keep if _m==3
drop _m

#delimit ;
la de stratum16comparable
1	"Barisal Rural"
2	"Barisal Urban"
3	"Chittagong Rural"
4	"Chittagong Urban"
5	"Chittagong SMA"
6	"Dhaka Rural"
7	"Dhaka Urban"
8	"Dhaka SMA"
9	"Khulna Rural" 
10	"Khulna Urban"
11	"Khulna SMA"
12	"Rajshahi Rural"
13	"Rajshahi Urban"
14	"Rajshahi SMA"
15	"Sylhet Rural"
16	"Sylhet Urban"
;
#delimit cr
la val stratum16comparable stratum16comparable

/*****************************************************************************************************
*                                                                                                    *
                                         LABELS
*                                                                                                    *
*****************************************************************************************************/
 
    la var psu              "Primary sampling Unit"	
	la var xquarters         "Average share 2010, 2016 quarters"
	la var x                 "Average share 2010, 2016 annual"
	la var share10quarters   "share10 quarters"
	la var share16quarters   "share16 quarters"
    la var share10           "share10 annual"
	la var share16           "share16 annual"	
	la var nfcpi             "Annual non-food CPI"
	la var stratum16         "Stratum 16 quarterly estimates"
	la var zilaid            "Stratum 132 annual estimates"
	la var zila              "Zila/District code"
	la var zila_name         "Zila/District name"
	
	la var stratum16comparable "Stratum 16 comparable to previous years"
	la var ruccomparable       "Ruc comparable to previous years"
	la var urbruralcomparable  "1 Rural, 2 Urban comparable to previous years"
	
	la var zf16quarters  "Quarterly food poverty lines"
	la var zu16quarters  "Quarterly upper poverty lines"
	la var zl16quarters  "Quarterly lower poverty lines"
	
	la var zf16          "Annual food poverty lines"
	la var zu16          "Annual upper poverty lines"
	la var zl16          "Annual lower poverty lines"
	
	la var indexquarters "Quarterly composite price index"
	la var ttquarters    "Quarterly Torqvist index"
		
	la var tt            "Annual Torqvist index"
    la var index         "Annual composite price index"
	
	la var member        "Household size"
	la var popwgt        "Annual population weight"

	la var pcexp         "Monthly per capita consumption expenditure"
	la var pcfexp        "Monthly per capita food expenditure"
	la var pcnfexp       "Monthly per capita non-food expenditure"
	la var pcrent        "Monthly per capita rent"
	la var pcimprent     "Monthly per capita imputed rent"
	la var pcprrent      "Monthly per capita predicted rent"
	
	la var rpcexp        "Monthly real per capita expenditure (deflated across space only)"
	la var rpcfe         "Monthly real per capita food expenditure (deflated across space only)"
	la var rpcnfe        "Monthly real per capita non-food expenditure (deflated across space only)"
	la var rpcrent       "Monthly real per capita rent expenditure (deflated across space only)"
	la var rpcimprent    "Monthly real per capita imputed rent expenditure (deflated across space only)"
	la var rpcprrent     "Monthly real per capita predicted rent  expenditure (deflated across space only)"

	la var rhexp         "Monthly real hh expenditure (deflated across space only)"
	la var rhfe          "Monthly real hh food expenditure (deflated across space only)"
	la var rhnfe         "Monthly real hh non-food expenditure (deflated across space only)"
	la var rhrent        "Monthly real hh rent expenditure (deflated across space only)"
	la var rhimprent     "Monthly real hh imputed rent expenditure (deflated across space only)"
	la var rhprrent      "Monthly real hh predicted rent  expenditure (deflated across space only)"
	
	la var lumpyexp      "Lumpy expenditures"
	la var hexpend       "Monthly hh expenditure (include lumpy exp)"
	la var pcexpend      "Monthly per capita expenditure (include lumpy exp)"
	la var rhexpend      "Monthly real hh expenditure (include lumpy exp) (deflated across space only)"
	la var rpcexpend     "Monthly real per capita expenditure (include lumpy exp) (deflated across space only)"
		
	la var lowerpoorquarters "People below quarterly lower poverty lines"
	la var upperpoorquarters "People below quarterly upper poverty lines"
	la var lowerpoor         "People below annual lower poverty lines"
	la var upperpoor         "People below annual upper poverty lines"
		
	la var fgt0q_upper "Headcount quarters upper poverty lines"
	la var fgt1q_upper "Poverty depth quarters upper poverty lines"
	la var fgt2q_upper "Poverty severity quarters upper poverty lines"
	la var fgt0q_lower "Headcount ratio quarters lower poverty lines"
	la var fgt1q_lower "Poverty depth quarters lower poverty lines"
	la var fgt2q_lower "Poverty severity quarters lower poverty lines"
	
	la var fgt0_upper "Headcount annual upper poverty lines"
	la var fgt1_upper "Poverty depth annual upper poverty lines"
	la var fgt2_upper "Poverty severity annual upper poverty lines"
	la var fgt0_lower "Headcount ratio annual lower poverty lines"
	la var fgt1_lower "Poverty depth annual lower poverty lines"
	la var fgt2_lower "Poverty severity annual lower poverty lines"
    
	la var hhincome   "Monthly Household Income"
	la var pcincome   "Monthly Per Capita Income"
	la var rhhincome  "Monthly Real Household Income (deflated across space only)"
	la var rpcincome  "Monthly Real Per Capita Income (deflated across space only)"
	
	rename (div id_01_name zila) (division_code division_name zila_code)
	drop zl
		
	#delimit ;
	drop hhid st1-st16
	lnroom dining kitchen brickwall tapwater electricity telephone 
	ownership lndwsize rental dummy1 dummy2 dum1 dum2 lnrent lnimprent 
	hat lnrent_h2 diff1 diff2 lnrent_h x1 x2 lnimprent_h x3 lnimprent_h2 x4
	;
	#delimit cr
	
	
	*keep only households with consumption information
	drop if pcexp==.
	
	
	#delimit ;
    order psu hhid term quarter hhwgt popwgt zilaid stratum16 ruc urbrural stratum16comparable ruccomparable urbruralcomparable 
	division_code division_name zila_code zila_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name	
	share10quarters share16quarters nfcpiquarters ttquarters xquarters indexquarters 
	zf16quarters zu16quarters zl16quarters share10 share16  nfcpi tt x index zf10 zu10 zl10 zf16 zu16 zl16
	member fexp nfexp consexp rent imprent pr_rent hsvalhh nfexp2 consexp2 lumpyexp hexpend hhincome
	pcexp pcfexp pcnfexp pcrent pcimprent pcprrent pcexpend pcincome
	pline_nat spindex 
	rhexp  rhfe  rhnfe  rhrent  rhimprent  rhprrent  rhexpend rhhincome
	rpcexp rpcfe rpcnfe rpcrent rpcimprent rpcprrent rpcexpend  rpcincome
	lowerpoorquarters upperpoorquarters lowerpoor upperpoor
	fgt0q_lower fgt1q_lower fgt2q_lower fgt0q_upper fgt1q_upper fgt2q_upper
	fgt0_lower fgt1_lower fgt2_lower fgt0_upper fgt1_upper fgt2_upper
	;
	#delimit cr
	
	rename (zilaid) (stratum)
	
	la var urbrural " 1 Rural, 2 Urban"
    la de urbrural 1"Rural" 2"Urban"
    la val urbrural urbrural
	
	save "$output/poverty_indicators2016_detailed", replace

	
	*Database for microdata catalog 
	*Keep main variables	
		
	#delimit ;
    keep psu hhid quarter hhwgt popwgt stratum stratum16 ruc urbrural 
	division_code division_name zila_code zila_name id_03_code id_03_name id_04_code id_04_name id_05_code id_05_name	
	member fexp nfexp2 hsvalhh consexp2 hhincome 
	pcexp pcincome pline_nat rpcexp rpcincome zu16quarters zl16quarters zu16 zl16
	lowerpoorquarters upperpoorquarters lowerpoor upperpoor
	;
	#delimit cr
	save "$output/poverty_indicators2016", replace
	
	*Save final file in microdata catalog folder
	save "$output/poverty_indicators2016", replace
		
	
		
	*Erase temporary files
		forval i=1/4 {
	cap erase "$temporary/budg2016`i'.dta"
	cap erase "$temporary/member`i'.dta"
	cap erase "$temporary/price2016`i'.dta"
    cap erase "$temporary/priceindex16_10_hies2016`i'.dta"
	}


    cap erase "$temporary/hhexp_hies2016.dta"
	cap erase "$temporary/lumpyexpenditure.dta"
	cap erase "$temporary/rent2.dta"
    cap erase "$temporary/priceindex16_10_hies2016all.dta"
	cap erase "$temporary/price2016all.dta"
	cap erase "$temporary/household_income2016.dta"


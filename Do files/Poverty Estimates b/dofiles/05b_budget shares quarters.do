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
/*This do file computes 2016 quarterly budget shares and  prices to calculate a torqvist index. 
The upper and lower poverty lines for each quarter are created updating the poverty lines from 
2010 with a quarterly composite price index. */
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
                                          2016 BUDGET SHARES
*                                                                                                    *
*****************************************************************************************************/
	*Count Household Members 
	forval i=1/4 {
	preserve
	use "$input/HH_SEC_1A_Q1Q2Q3Q4", clear
	keep if qtr==`i'
	ren id_02_name zila_name
	*Duplicated observations
	duplicates report hhold s1aq00
	duplicates tag hhold s1aq00, gen(flag)
	*Drops automatically one of the duplicated observations
	sort hhold s1aq00
	duplicates drop hhold s1aq00, force
	egen member= count(s1aq00), by(hhold)
	drop if member==0
	*This duplicates acts as a collapse, it drops lots of observations to convert roster into hhold level dataset
	sort hhold
	duplicates drop hhold, force
	keep psu hhid hhold member stratum16 div ruc zilaid zila zila_name
	save "$temporary/member`i'", replace
	restore
	}

	forval i=1/4 {
	preserve
	use "$output/expenditure_2016", clear
	keep if qtr==`i'
	* To calculate budget shares, HIES traditionally uses consexp variable (i.e. consumption before adjusting for rent)
	rename consexp cons_exp
	keep psu hhid hhold stratum16 hhwgt cons_exp urbrural term
	merge 1:1 hhold using "$temporary/member`i'"
	tab _merge
	drop if _merge==2
	*drop if member==.
	drop _merge  
	sort hhold	
	save "$temporary/temp0`i'", replace
	restore
	}

	*Daily consumption, count days 
	forval i=1/4 {
	preserve
	use "$temporary/HH_SEC_9A2_Q1Q2Q3Q4adj", clear
	keep if qtr==`i'
	drop if  (quantity==. | quantity==0) & (value==. | value==0)

	drop if mod(item,10)==0
	collapse (sum) fexpday=value, by(psu hhid hhold day)
	drop if (fexpday==0 | fexpday==.)
	*Remove those days for which no consumption is reported
	collapse (sum) fexptot=fexpday (count) ndays=day, by(psu hhid hhold)
	sort hhold
	save "$temporary/ndays`i'", replace
	restore
	}

	*Group daily food items into 12 main categories 
	forval i=1/4 {
	preserve
	use "$temporary/HH_SEC_9A2_Q1Q2Q3Q4adj", clear
	keep if qtr==`i'

	drop if  (quantity==. | quantity==0) & (value==. | value==0)
	
	sort hhold item day
	ren item foodcode
	
	drop if mod(foodcode,10)==0

	gen     itemcode = 01 if foodcode>= 11 & foodcode<= 24
	replace itemcode = 02 if foodcode>= 31 & foodcode<= 36
	replace itemcode = 03 if foodcode>= 41 & foodcode<= 58
	replace itemcode = 04 if foodcode>= 61 & foodcode<= 63
	replace itemcode = 05 if foodcode>= 71 & foodcode<= 77
	replace itemcode = 06 if foodcode>= 81 & foodcode<= 97
	replace itemcode = 07 if foodcode>=101 & foodcode<=106 
	replace itemcode = 08 if (foodcode>=111 & foodcode<=114) | (foodcode>=161 & foodcode<=166) 
	replace itemcode = 09 if foodcode>=121 & foodcode<=126 
	replace itemcode = 11 if foodcode>=131 & foodcode<=148 
	replace itemcode = 12 if foodcode>=151 & foodcode<=156 
	replace itemcode = 13 if foodcode>=201 & foodcode<=204

	collapse (sum) v=value, by(psu hhid hhold itemcode)
	drop if itemcode==.
	sort hhold

	merge m:1 hhold using "$temporary/ndays`i'"
	tab _m
    keep if _m==3
	drop _m

	*Convert daily consumption to monthly consumption (factor is 365/12)
	replace v=(30.42/ndays)*v
	drop ndays
	reshape wide v, i(psu hhid hhold) j(itemcode)
	save "$temporary/temp1`i'", replace
	restore
	}

	* Weekly consumption
	forval i=1/4 {
	preserve
	use "$temporary/HH_SEC_9B2_Q1Q2Q3Q4adj", clear
	keep if qtr==`i'

	drop if  (quantity==. | quantity==0) & (value==. | value==0)

	drop if mod(item,10)==0

	collapse (sum) fexpwk=value, by(psu hhid hhold week)
	drop if (fexpwk==0 | fexpwk==.)
	collapse (sum) fexptot2=fexpwk (count) nweeks=week, by(psu hhid hhold)
	sort hhold
	save "$temporary/temp1a`i'", replace
	restore
	}

	forval i=1/4 {
	preserve
	use "$temporary/HH_SEC_9B2_Q1Q2Q3Q4adj", clear
	keep if qtr==`i'

	drop if  (quantity==. | quantity==0) & (value==. | value==0)
    rename item foodcode
	
	gen itemcode = 10 if foodcode>=211 & foodcode<=223
	replace itemcode=132 if foodcode>=231 & foodcode<=237 /*add this to itemcode 13*/
	collapse (sum) v=value, by(psu hhid hhold itemcode)
	drop if itemcode==.
	
	sort hhold
	merge hhold using "$temporary/temp1a`i'"
	tab _m
	drop _m
	*Convert weekly to monthly expenditure
	replace v=(30.42/7)*(1/nweeks)*v
	
	drop nweeks
	mvencode _all, mv(0) override
	reshape wide v, i(psu hhid hhold) j(itemcode)
	save "$temporary/temp1b`i'", replace
	restore
	}

	forval i=1/4 {
	use "$temporary/temp1`i'", clear
	merge 1:1 hhold using "$temporary/temp1b`i'"
	tab _m
	drop _m

	egen v131= rowtotal(v13 v132)
	drop v13 v132
	rename v131 v13
	sort hhold
	
	mvencode _all, mv(0) override /* replace missing values with 0 */

	*Merge with consumption expenditure database
	merge 1:1 hhold using "$temporary/temp0`i'"
	tab _merge
	
	*we drop households when is not possible to calculate v1-v13
	drop if _m==2
	keep psu hhid hhold stratum16 hhwgt v1-v13 cons_exp 
	order psu hhid hhold stratum16 hhwgt v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13
	
	*Generate budget shares for each hhold
	egen exp=rowtotal(v1-v13)
	gen share16 = exp/cons_exp
	replace share16=. if cons_exp==.
	for var v1-v13: replace X=. if cons_exp==. 
	for var v1-v13: gen X_16=X/exp

	*Weighted Avg. of budget shares, by stratum
	collapse (mean)  v1_16-v13_16 share16 [aw=hhwgt], by(stratum16)

	label var v1_16 "Food grains  "
	label var v2_16 "Pulses       "
	label var v3_16 "Fish         "
	label var v4_16 "Eggs         "
	label var v5_16 "Meat         "
	label var v6_16 "Vegetables   "
	label var v7_16 "Milk         "
	label var v8_16 "Sugar        "
	label var v9_16 "Cooking oils "
	label var v10_16 "Salt, spices"
	label var v11_16 "Fruits      "
	label var v12_16 "Soft drinks "
	label var v13_16 "Betel+tobacco"

	save "$temporary/budg2016`i'.dta", replace
	}

* ----------------------------------------------------------------------
* PRICES: HIES 2016
* ----------------------------------------------------------------------
   	forval i=1/4 {
	preserve
	use "$temporary/HH_SEC_9A2_Q1Q2Q3Q4adj", clear
	keep if qtr==`i'

	drop if  (quantity==. | quantity==0) & (value==. | value==0)
	
	sort hhold item day	
	ren item foodcode
	drop if mod(foodcode,10)==0
	
	cap drop itemcode
	gen     itemcode = 01 if foodcode== 13
	replace itemcode = 02 if foodcode== 31
	replace itemcode = 03 if foodcode== 49
	replace itemcode = 04 if foodcode== 61
	replace itemcode = 05 if foodcode== 71
	replace itemcode = 06 if foodcode== 81
	replace itemcode = 07 if foodcode==101
	replace itemcode = 08 if foodcode==161
	replace itemcode = 09 if foodcode==121
	replace itemcode = 11 if foodcode==131
	replace itemcode = 12 if foodcode==151
	replace itemcode = 13 if foodcode==201
	drop if itemcode==.
	
	*Prices were already created and cleaned up from outliers in do file 01_price adjustment
	*gen p = (value/quantity) 	
	
	drop if outlier==1

	
	collapse (mean) p, by(psu hhid hhold itemcode)
	sort hhold
	merge hhold using "$temporary/temp0`i'"
	tab _merge
    keep if _merge==3
	drop _merge
	keep psu hhid hhold itemcode stratum16 p hhwgt 
	save "$temporary/temp2`i'", replace
	restore
	}

	forval i=1/4 {
	preserve
	use "$temporary/HH_SEC_9B2_Q1Q2Q3Q4adj", clear
	keep if qtr==`i'

	drop if  (quantity==. | quantity==0) & (value==. | value==0)
	
	sort hhold item week
	ren item foodcode
	drop if mod(foodcode,10)==0
	
	cap drop itemcode
	gen itemcode = 10 if foodcode==216
	drop if itemcode==.
	
	*Prices were already created and cleaned up from outliers in do file 01_price adjustment
	*gen p = (value/quantity)
	
	drop if outlier==1

	
	collapse (mean) p, by(psu hhid hhold itemcode)
	sort hhold
	merge hhold using "$temporary/temp0`i'"
	tab _merge
	keep if _m==3
	drop _merge
	keep psu hhid hhold  itemcode stratum16  p hhwgt 
	append using "$temporary/temp2`i'"
	
	collapse (median) p [aw=hhwgt], by(itemcode stratum16)
	replace p = p*1000
	
	*Eggs
	replace p = p/1000  if itemcode== 4
	* Soft drinks
	replace p = p*375/1000 if itemcode==12
	* Prepared betel leaves, 
	replace p = p/1000 if itemcode==13
	reshape wide p, i(stratum16) j(itemcode)
	for var p1-p13: rename X X_16

	label var p1_16 "Food grains  "
	label var p2_16 "Pulses       "
	label var p3_16 "Fish         "
	label var p4_16 "Eggs         "
	label var p5_16 "Meat         "
	label var p6_16 "Vegetables   "
	label var p7_16 "Milk         "
	label var p8_16 "Sugar        "
	label var p9_16 "Cooking oils "
	label var p10_16 "Salt, spices"
	label var p11_16 "Fruits      "
	label var p12_16 "Soft drinks "
	label var p13_16 "Betel & cigarrete"

	sort stratum16
	save "$temporary/price2016`i'", replace
	restore
	}


/*****************************************************************************************************
*                                                                                                    *
                                       COMPOSITE PRICE INDEX
*                                                                                                    *
*****************************************************************************************************/
    forval i=1/4 {
	use "$input2010/Mr Faiz/budgsh10_new.dta", clear
	ren stratum stratum16
	tempfile hies2010
	save `hies2010', replace
	
	use "$input2010/Mr Faiz/price10_new.dta",clear
	ren stratum stratum16
	merge 1:1 stratum16 using `hies2010'
	tab _m
	drop _m
	sort stratum16
	merge 1:1 stratum16 using "$temporary/price2016`i'"
	tab _m
	drop _m
	sort stratum16
	merge 1:1 stratum16 using "$temporary/budg2016`i'.dta"
	drop _m
		  
	* 2016  to 2010
	*ln(relative prices)
		for num 1/13: gen rpX_16=ln(pX_16/pX_10)
	*avg. budget shares
		for num 1/13: gen vX_m=(vX_16+vX_10)/2
	*product of avg shares and relative prices
		for num 1/13: gen prodX=vX_m*rpX_16
	*index
		egen lntt=rowtotal(prod1-prod13)
		gen tt16_10=exp(lntt)
	drop rp1_16-lntt
	drop p* v*
	sort stratum16
	rename tt16_10 tt
	la var tt "Torqvist Index"
	save "$temporary/priceindex16_10_hies2016`i'", replace
	}
	
	
	*Append quarterly prices and shares
	use "$temporary\priceindex16_10_hies20161", clear
	g quarter=1
	
	append using "$temporary\priceindex16_10_hies20162"
	replace quarter=2 if quarter==.

	append using "$temporary\priceindex16_10_hies20163"
	replace quarter=3 if quarter==.
	
	append using "$temporary\priceindex16_10_hies20164"
	replace quarter=4 if quarter==.
	
	*Create urban-rural variable
	gen     urbrural = 1 if stratum16==1 | stratum16==3 | stratum16==6 | stratum16==9 | stratum16==12 | stratum16==15
	replace urbrural = 2 if urbrural==.
	
	*Non-food CPI, see file "CPI 2016_2017.xlsx" to check out how these numbers were computed
	gen nfcpi=.
	replace nfcpi=1.513   if quarter==1 & urbrural==1
    replace nfcpi=1.528   if quarter==1 & urbrural==2

	replace nfcpi=1.524   if quarter==2 & urbrural==1
    replace nfcpi=1.544   if quarter==2 & urbrural==2

	replace nfcpi=1.530   if quarter==3 & urbrural==1
    replace nfcpi=1.552   if quarter==3 & urbrural==2
	
	replace nfcpi=1.553   if quarter==4 & urbrural==1
    replace nfcpi=1.589   if quarter==4 & urbrural==2
	

    *Combine the tornqvist index and the non-food CPI into a composite price index	
	gen x = (share16+share10)/2
	
	
    *The composite price index is a weighted average of the tornqvist index and the non-food CPI
	gen     index = x*tt + (1-x)*nfcpi     
	
	
	*Merge with 2010 poverty lines
	merge m:1 stratum16 using "$input2010/povline10"
	drop _m
	
	*Poverty lines in each quarter are created  updating the lower and upper poverty lines from 2010
	gen zf16=zf10*index
	gen zu16=zu10*index
	gen zl16=zl10*index
		
	la var nfcpi  "Quarterly non-food CPI"
    la var index "Composite price index"	
	la var zf10  "Food Poverty line 2010"
	la var zl10  "Lower poverty line 2010"
	la var zu10  "Upper poverty line 2010"
	la var zf16  "Quarterly food Poverty lines 2016"
	la var zl16  "Quarterly lower poverty lines 2016"
	la var zu16  "Quarterly upper poverty lines 2016"
	
	save "$output/povline16quarters", replace

	forval i=1/4 {
	erase "$temporary/ndays`i'.dta"
	erase "$temporary/temp0`i'.dta"
	erase "$temporary/temp1`i'.dta"
	erase "$temporary/temp1a`i'.dta"
	erase "$temporary/temp1b`i'.dta"
	erase "$temporary/temp2`i'.dta"
    }


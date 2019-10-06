******************************************************************************************************
**                            BANGLADESH INCOME 2016 PRELIMINARY REPORT BBS                         **
**                                                                                                  **
** COUNTRY			BANGLADESH
** COUNTRY ISO CODE	BGD
** YEAR				2016
** SURVEY NAME		HOUSEHOLD INCOME AND EXPENDITURE SURVEY 		
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS
** Modified	        12/19/2017                                                                                               
******************************************************************************************************
*****************************************************************************************************/
/*This do file computes household income for BBS preliminary report */
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
                                            LABOR INCOME
*                                                                                                    *
*****************************************************************************************************/

foreach file in HH_SEC_4A HH_SEC_4B {
use "$input/`file'_Q1Q2Q3Q4", clear

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

save `file', replace
}

***********************Duplicated observations section 4B***********************
use HH_SEC_4B, clear
duplicates report hhold idcode as
duplicates tag hhold idcode as, gen(flag)
tab flag


******Three cases of duplicated observations where all the information is zero

*All the information is zero in this case
drop if flag==17

*All the informarion is zero in this case
drop if hhold==1696086 & idcode==0

*All the informarion is zero in this case
drop if hhold==2083006 & idcode==0
save HH_SEC_4B, replace



****Create a new activity code variable to merge sections 4A and 4B
foreach file in HH_SEC_4A HH_SEC_4B {
use `file', clear

sort hhold idcode occ
bys hhold idcode: egen activity=seq()
save `file', replace
}

use HH_SEC_4A,clear
rename s4aq01c ind
merge 1:1 hhold idcode activity using HH_SEC_4B
tab _m


*Keep daily and salaried workers
keep if (s4aq07==1 |s4aq07==4) | (s4aq08==1|s4aq08==4)
rename s4bq02c avgdwage
rename s4bq05b dwagekind
rename s4bq08  msalary
rename s4bq09  othbeni	


count if (avgdwage==. & s4bq01==1) | (msalary==. & s4bq01==2)

replace s4bq01=1 if (s4aq07==1 | s4aq08==1) & s4bq01==. 
replace s4bq01=2 if (s4aq07==4 | s4aq08==4) & s4bq01==. 



	*1) Calculate medians 
	*A-calculate median by stratum	
		 
    foreach var in avgdwage dwagekind msalary othbeni {
	gen medstr`var'=.
	}
	
     qui levelsof stratum16, local(strat)
	 qui levelsof ind, local(industry)     
	 foreach var in avgdwage dwagekind msalary othbeni {
	      foreach s of local strat {
	          foreach i of local industry {
		qui su `var' [aw = hhwgt] if stratum == `s' & ind==`i' & `var'!=0, detail
		qui replace medstr`var' = r(p50) if stratum == `s' & ind==`i' & medstr`var' == .

              }
	      }
     }
		
		
	
	 *B-calculate median by urban/rural		 
	 gen urbrural=1 if ruc==1
	 replace urbrural=2 if urbrural==.
	 
    foreach var in avgdwage dwagekind msalary othbeni {
	gen medur`var'=.
	}
	 	  
	 qui levelsof urbrural, local(strat)
	 qui levelsof ind, local(industry)	  	 
	   foreach var in avgdwage dwagekind msalary othbeni {
	 	   foreach s of local strat {
	           foreach i of local industry {
	             qui su `var' [aw = hhwgt] if urbrural == `s' & ind==`i' & `var'!=0, detail
		         qui replace medur`var' = r(p50) if urbrural == `s' & ind==`i' & medur`var' == .
	  	       }
	       } 
	    }
	  
	  
	   	  
	  *C- Calculate median by country
	foreach var in avgdwage dwagekind msalary othbeni {
	gen medcnt`var'=.
	}
	  qui levelsof ind, local(industry)	 
	  foreach var in avgdwage dwagekind msalary othbeni {
	  	      foreach i of local industry {
	           qui sum `var' [aw = hhwgt] if ind==`i' & `var'!=0, detail
	           replace medcnt`var'= r(p50) if medcnt`var' == .
	          }
	     }
   
		
	*2) Count number of observations without missings and zeros by stratum, urban and rural and industry
    foreach var in avgdwage dwagekind msalary othbeni {
	bysort stratum16 ind: egen countstratum`var'=count(`var') if `var'!=0
	bysort urbrural  ind: egen countarea`var'  = count(`var') if `var'!=0
	}
	  
  	
	 /* 
     *3) We impute the MEDIAN values at different levels. We start from the lowest or 
	 closest level (stratum) to the highest level (National):
	 
	 
	 A- STRATUM: 
	 
	 B- URBAN/RURAL: 
	 
	 C- NATIONAL: 	 */	
	
	noi di as error "Replacing missing values by stratum median values per industry"	

	replace avgdwage=medstravgdwage if avgdwage==. & s4bq01==1    & countstratumavgdwage>30
    replace dwagekind=medstrdwagekind if dwagekind==. & s4bq03==1  & countstratumdwagekind>30
    replace msalary=medstrmsalary if msalary==. & s4bq01==2       & countstratummsalary>30
    replace othbeni=medstrothbeni if othbeni==. & s4bq01==2       & countstratumothbeni>30
	
	
	noi di as error "Replacing missing values by urban/rural median values per indudstry"	
	replace avgdwage=meduravgdwage if avgdwage==. & s4bq01==1     & countareaavgdwage>30
    replace dwagekind=medurdwagekind if dwagekind==. & s4bq03==1  & countareadwagekind>30
    replace msalary=medurmsalary if msalary==. & s4bq01==2        & countareamsalary>30
    replace othbeni=medurothbeni if othbeni==. & s4bq01==2        & countareaothbeni>30
	
    
	noi di as error "Replacing missing values  by country median values  per industry"	
	replace avgdwage=medcntavgdwage if avgdwage==. & s4bq01==1 
    replace dwagekind=medcntdwagekind if dwagekind==. & s4bq03==1
    replace msalary=medcntmsalary if msalary==. & s4bq01==2
    replace othbeni=medcntothbeni if othbeni==. & s4bq01==2
*/	

mvencode _all,mv(0) override
gen wage_inc_cash=avgdwage*s4aq02*s4aq03 if s4bq01==1 
gen wage_inc_kind=dwagekind*s4aq02*s4aq03 if s4bq03==1 
replace wage_inc_cash=msalary*12 if s4bq01==2
replace wage_inc_kind=othbeni if s4bq01==2 
egen wage_inc=rsum(wage_inc_cash wage_inc_kind)

collapse (sum) wage_inc_cash=wage_inc_cash wage_inc_kind=wage_inc_kind wage_inc=wage_inc (max)div zila ruc,by(hhold)

table div,c(sum wage_inc_cash sum wage_inc_kind sum wage_inc) row f(%12.0f)
sort  hhold

save wage_income_imputed,replace



/*****************************************************************************************************
*                                                                                                    *
                                         BUSINESS INCOME
*                                                                                                    *
*****************************************************************************************************/

use "$input\HH_SEC_05_Q1Q2Q3Q4",clear
drop if s5q00==.

*one mistake was indetified in the questionnaire of household 2013017, we correct this number
replace s5q13=4992000 if hhold==2013017

gen gr_buss_inc=s5q13
egen buss_expenses=rsum(s5q14 - s5q19)
gen net_buss_inc=s5q13-buss_expenses

replace net_buss_inc=net_buss_inc* (s5q07/100) if net_buss_inc>0 & net_buss_inc~=. & ( s5q07>0 & s5q07~=.)
collapse (sum) gr_buss_inc=gr_buss_inc buss_expenses=buss_expenses net_buss_inc=net_buss_inc  s5q20=s5q20 ,by(hhold)
sort  hhold

save business_income,replace

/*****************************************************************************************************
*                                                                                                    *
                                       AGRICULTURE INCOME
*                                                                                                    *
*****************************************************************************************************/

    use "$input\HH_SEC_7B_Q1Q2Q3Q4",clear
    drop if s7bq02~=1		
		
		
	*Rural variable	 
	gen rural=(ruc==1)

/*1) We found outliers in the unit values (s7bq04b) that were affecting the gini. We apply the same methodology we used in
consumption to fix these outliers */

    rename (s7bq00 s7bq04a) (item quantity)
	duplicates report hhold item
	
    *There is one negative value, we replace it for missing
    replace s7bq04b=. if s7bq04b==-19
	
	
	gen p_1 = s7bq04b
	la var p_1 "Initial unit value"

	gen p=p_1 
	
	
	/*When quantity>0 and the unit value is zero we replace these values for missing and at the end 
	we use the medians to impute those prices, and compute the total value */
	replace p=. if (quantity>0 & quantity~=.) & p==0
	
	
	*Previous option
	*replace p=. if p==999
	
		
	*Create Ln of p
	quietly gen lnp = ln(p) 
	
	
	* 1) Identify and replace outliers as missings
	
	qui levelsof item, local (crop) 	
	foreach f of local crop {
	qui   sum p [aw = hhwgt] if item==`f', detail	

      * When the variance of p exists and is different from zero we detect and delete outliers
	     if r(Var) != 0 & r(Var) < . {
		
	     qui levelsof stratum16, local(strat)
         foreach s of local strat {
            qui   sum p [aw = hhwgt] if p > 0 & p <. & stratum16 == `s' & item==`f'
            local antp = r(N)
			qui sum lnp [aw= hhwgt] if stratum16 == `s' & item==`f', detail
			local ameanp = r(mean)
			local asdp   = r(sd)			
      
		    replace  p =. if (abs((lnp - `ameanp') / `asdp') > 3.5 & ~mi(lnp)) & stratum16 == `s' & item==`f'
		 	qui count if p > 0 & ~mi(p) & stratum16 == `s' & item==`f'
		 	local postp = r(N)
			
		   }
	     }
       }
	   
	  */
     
	gen outlier=(p==.)
	
	noi di as error "Number of outliers"
	count if p==.	
	
	*Proportion of outliers
	tab outlier


	*2) Count number of observations without outliers
    bysort stratum16  item: egen countstratum= count(p)
	bysort rural      item: egen countarea  = count(p)	
	
	

	*3) Calculate medians 
	*A-calculate median by stratum	
		 
	  qui levelsof stratum16, local(strat)
	  qui levelsof item, local(crop)
 	  qui gen medianstratum = . 
	  foreach s of local strat {
	           foreach f of local crop {
		qui su p [aw = hhwgt] if stratum == `s' & item==`f' & p!=0, detail
		qui replace medianstratum = r(p50) if stratum == `s' & item==`f' & medianstratum == .
        }
	  }		
		
		
	
	 *E-calculate median by urban/rural		 
	  qui levelsof rural, local(strat)
	  qui levelsof item, local(crop)
 	  qui gen medianarea = . 
	  foreach s of local strat {
	           foreach f of local crop {
		qui su p [aw = hhwgt] if rural == `s' & item==`f' & p!=0, detail
		qui replace medianarea = r(p50) if rural == `s' & item==`f' & medianarea == .
        }
	  }

	  
	  *F- Calculate median by country
	  qui levelsof item, local(crop)
	  qui gen mediancountry =.
	  foreach f of local crop {
	  qui su p [aw = hhwgt] if item==`f' & p!=0, detail
      qui replace mediancountry = r(p50) 
	  }
	  
	  
   	 	
	  /*
     *3) We impute the MEDIAN values at different levels. We start from the lowest or 
	 closest level (stratum) to the highest level (National):
	 
	 
	 A- STRATUM: 
	 
	 B- URBAN/RURAL: 
	 
	 C- NATIONAL: 	 */	
	
   	noi di as error "Replacing outliers by stratum median price per item"	
	replace p=medianstratum if p==. & countstratum>30
	
	noi di as error "Replacing outliers by area median price per item"	
	replace p=medianarea if p==. & countarea>30
	
	noi di as error "Replacing outliers by country median price per item"	
	replace p=mediancountry if p==. 
	
	
* For crop income we use the 2010 definition that adds (value consumed and sold)
* For the missings cases we use total value
gen 	crop_inc=(s7bq05+s7bq06)*p
replace crop_inc=(quantity*p) if crop_inc==.

bys hhold: egen total=sum(crop_inc)

collapse (sum) crop_inc=crop_inc,by(hhold)
sort  hhold
save crop_income,replace


use "$input\HH_SEC_7C1_Q1Q2Q3Q4",clear
gen live_inc1=s7c1q04b if s7c1q00~=210
collapse (sum) live_inc1=live_inc1,by(hhold)
sort  hhold
save live_income1,replace

use "$input\HH_SEC_7C2_Q1Q2Q3Q4",clear
mvencode _all,mv(0) override
gen live_inc2=(s7c2q07b + s7c2q08b) if s7c2q00~=220
collapse (sum) live_inc2=live_inc2,by(hhold)
sort hhold
save live_income2,replace
 
use "$input\HH_SEC_7C3_Q1Q2Q3Q4",clear
mvencode _all,mv(0) override
gen fish_inc=(s7c3q11b+s7c3q12b) if s7c3q00~=230
collapse (sum) fish_inc=fish_inc,by(hhold)
sort  hhold
save fish_income,replace

use "$input\HH_SEC_7C4_Q1Q2Q3Q4",clear
mvencode _all,mv(0) override
gen forest_inc=(s7c4q15+s7c4q16) if s7c4q00~=240
collapse (sum) forest_inc=forest_inc,by(hhold)
sort hhold
save forest_income,replace

use "$input\HH_SEC_7E_Q1Q2Q3Q4",clear
gen agri_asset_inc=s7eq04 if s7eq00~=420
collapse (sum) agri_asset_inc=agri_asset_inc,by(hhold)
sort hhold
save agri_asset_income,replace


/*****************************************************************************************************
*                                                                                                    *
                                           OTHER INCOME
*                                                                                                    *
*****************************************************************************************************/

use "$input\HH_SEC_8B_Q1Q2Q3Q4",clear

** Other property income : rent from land, rent from property,profit & dividends, interest from bank & other sources
egen prop_inc=rsum(s8bq01 s8bq02 s8bq04 s8bq12)

** Transfers : Remittances
egen remittance_inc=rsum(s8bq08 s8bq09)

** Social Income : Insurances, lottery , charity in cash/kind
egen social_inc=rsum(s8bq03a s8bq03b s8bq03c s8bq05 s8bq06 s8bq07)

** Other non-labor income : gratuity, separation payment,retirement,other cash or in-kind
egen othnonwage_inc=rsum(s8bq11 s8bq13) 

collapse (sum)  prop_inc=prop_inc remittance_inc=remittance_inc social_inc=social_inc othnonwage_inc=othnonwage_inc,by(hhold)
sort hhold
save oth_income,replace


/*****************************************************************************************************
*                                                                                                    *
                                            REMITTANCES
*                                                                                                    *
*****************************************************************************************************/

use "$input\HH_SEC_8C_Q1Q2Q3Q4",clear
drop if s8cq00==. | s8cq00==0
keep psu hhold div zila wgt post_factor ruc s8cq00 s8cq06 s8cq14 s8cq17
rename s8cq00 personid
rename s8cq14 remit_cash
rename s8cq17 remit_kind
gen urbrural=1 if ruc==1
replace urbrural=2 if urbrural==.
egen tot_remit_abr=rsum(remit_cash remit_kind) if s8cq06==2 
egen tot_remit_dom=rsum(remit_cash remit_kind) if s8cq06==1 
replace tot_remit_abr=tot_remit_abr/2
replace tot_remit_dom=tot_remit_dom/2
egen tot_remit=rsum(tot_remit_abr tot_remit_dom)
collapse (sum)  tot_remit= tot_remit tot_remit_abr=tot_remit_abr tot_remit_dom=tot_remit_dom (max) urbrural,by(hhold)
sort hhold
gen dremit8c=tot_remit>0 & tot_remit~=.
save temp3,replace


use "$input\HH_SEC_8B_Q1Q2Q3Q4",clear
keep  hhold s8bq08 s8bq09 s8bq10
egen remit_8b=rsum(s8bq08 s8bq09)
gen dremit8b=remit_8b>0 & remit_8b~=.
sort hhold
merge hhold using temp3
tab _m
drop if _m==2
drop _m

gen remit=(dremit8b==1| dremit8c==1)
count if remit==1 & (tot_remit==. | tot_remit==0)

replace tot_remit=remit_8b if remit==1 & (tot_remit==. | tot_remit==0)
sort hhold
save remittances,replace



/*****************************************************************************************************
*                                                                                                    *
                                         SOCIAL SAFETY NETS
*                                                                                                    *
*****************************************************************************************************/

use "$input\HH_SEC_1C_Q1Q2Q3Q4",clear
*mvencode _all,mv(0) override
keep if s1cq01==1

**check whether any person participating in programs but not getting moneytary benifits either in cash or in kind **  
count if (s1cq10a==. | s1cq10a==0) & (s1cq101d==. | s1cq101d==0) & (s1cq102d==. | s1cq102d==0) 
*mvencode _all,mv(0) override

** receipt from the last payment **
gen snet_cash_last=s1cq05a
egen snet_kind_last=rsum(s1cq071d s1cq072d) if s1cq06==1

** last 12 months receipt **
gen snet_cash=s1cq10a if s1cq01==1 
replace snet_cash=0 if s1cq01==1 & (s1cq02==2 | s1cq02==4)

egen snet_kind=rsum(s1cq101d  s1cq102d)
collapse (sum)  snet_cash=snet_cash snet_kind=snet_kind snet_cash_last=snet_cash_last snet_kind_last=snet_kind_last,by(hhold)
egen snet_total=rsum(snet_cash snet_kind)
egen snet_total_last=rsum(snet_cash_last snet_kind_last)
** check for missing receipts **
replace snet_total=snet_total_last if (snet_total==. | snet_total==0) & (snet_total_last~=. | snet_total_last~=0)
sort hhold
save safetynet_income,replace



/*****************************************************************************************************
*                                                                                                    *
                                             STIPEND 
*                                                                                                    *
*****************************************************************************************************/

use "$input\HH_SEC_2B_Q1Q2Q3Q4",clear
gen stipend_inc=s2bq06
collapse (sum)  stipend_inc=stipend_inc,by(hhold)
sort hhold
save stipend_income,replace



/*****************************************************************************************************
*                                                                                                    *
                                         IMPUTED RENT 
*                                                                                                    *
*****************************************************************************************************/


use "$input\HH_SEC_6A_Q1Q2Q3Q4",clear
keep hhold s6aq23
sort hhold
save temp4,replace


use "$output/expenditure_2016",clear
keep hhold imprent 
mvencode _all,mv(0) override
replace imprent=imprent*12


sort hhold
merge hhold using temp4
tab _m
keep if _m==3
drop _m

*We do not do the following replacement to follow what it was done in 2010
*replace imprent=pr_rent if (rent==. | rent==0) & (imprent==. | imprent==0) & (s6aq23==1 | s6aq23==3)
collapse (sum) imprent=imprent  (max) s6aq23,by(hhold)
sort hhold
save imputed_income,replace


/*****************************************************************************************************
*                                                                                                    *
                                       MERGE ALL FILES
*                                                                                                    *
*****************************************************************************************************/

use wage_income_imputed, clear
merge 1:1 hhold using business_income
tab _m
drop _m
sort  hhold
merge  1:1 hhold using crop_income
tab _m
drop _m
sort  hhold
merge 1:1 hhold using live_income1
tab _m
drop _m
sort  hhold
merge  1:1 hhold using live_income2
tab _m
drop _m
sort  hhold
merge  1:1 hhold using fish_income
tab _m
drop _m
sort  hhold
merge  1:1 hhold using forest_income
tab _m
drop _m
sort  hhold
merge  1:1 hhold using agri_asset_income
tab _m
drop _m
sort  hhold
merge 1:1 hhold using oth_income
tab _m
drop _m
sort  hhold
merge 1:1 hhold using remittances
tab _m
drop _m
sort  hhold

merge 1:1 hhold using safetynet_income
tab _m
drop _m
sort hhold
merge 1:1 hhold using stipend_income
tab _m
drop _m
sort  hhold
merge 1:1 hhold using imputed_income
tab _m
drop if _m==2
drop _m
sort hhold

cap drop _m
mvencode _all,mv(0) override
cap drop tot_income
gen tot_income=wage_inc+net_buss_inc+crop_inc+live_inc1+live_inc2+fish_inc+forest_inc+agri_asset_inc+prop_inc ///
+ social_inc + tot_remit+othnonwage_inc+snet_total+stipend_inc+imprent


**Create monthly income
gen hhincome=tot_income/12


*Convert all components to monthly 
glo var wage_inc net_buss_inc crop_inc live_inc1 live_inc2 fish_inc forest_inc agri_asset_inc prop_inc tot_remit social_inc othnonwage_inc snet_total stipend_inc imprent

foreach var in $var {
replace `var'= `var'/12
}

*Create shares of each source of income on total household income
foreach var in $var {
gen sh`var'= (`var'/hhincome)*100 if hhincome>=0
}

sort hhold

*Replace negative values with missing
replace hhincome=. if hhincome<0
save household_income2016,replace


**Drop temporary files
erase "HH_SEC_4A.dta"
erase "HH_SEC_4B.dta"
erase "wage_income_imputed.dta"
erase "business_income.dta"
erase "crop_income.dta"
erase "live_income1.dta"
erase "live_income2.dta"
erase "fish_income.dta"
erase "forest_income.dta"
erase "agri_asset_income.dta"
erase "oth_income.dta"
erase "temp3.dta"
erase "remittances.dta"
erase "safetynet_income.dta"
erase "stipend_income.dta"
erase "temp4.dta"
erase "imputed_income.dta"


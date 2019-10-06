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
** Modified	        12/15/2017                                                                                                 
******************************************************************************************************
*****************************************************************************************************/
/* This do file identifies outliers in unit values and correct these numbers in non-food expenditure */
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
                              SECTION 9D1: ANNUAL NON-FOOD EXPENDITURE							
*                                                                                                    *
*****************************************************************************************************/
  
  * Section 9, Part D (items 311 - 362)
	use "$input/HH_SEC_9D1_Q1Q2Q3Q4", clear
	
	rename (s9d1q00 s9d1q01 s9d1q02) (item quantity value)
	drop if  (quantity==. | quantity==0) & (value==. | value==0)
	
	*13 repeated observations		
	duplicates report hhid item
	duplicates drop hhid item, force
	drop if mod(item,10)==0
	
		
	*Rural variable	 
	gen rural=(ruc==1)


	*357 observations where households reported quantities but total value is missing or zero
	*br if (quantity>0 & quantity~=.) & (value==. | value==0)
	
	gen p_1 = (value/quantity)
	la var p_1 "Initial unit value"

	gen p=p_1 
	
	/*When quantity>0 and total value is zero, the unit value is zero. We replace these values for missing and at the end 
	we use the medians to impute those prices, and compute the total value */
	
	replace p=. if (quantity>0 & quantity~=.) & (value==. | value==0)

	
	*Create Ln of p
	quietly gen lnp = ln(p) 
	
	
	* 1) Identify and replace outliers as missings
	
	qui levelsof item, local (nfood) 	
	foreach f of local nfood {
	qui   sum p [aw = hhwgt] if item==`f', detail	

      * When the variance of p exists and is different from zero we detect and delete outliers
	     if r(Var) != 0 & r(Var) < . {
		
	     qui levelsof  stratum16, local(strat)
         foreach s of local strat {
            qui   sum p [aw = hhwgt] if p > 0 & p <. &  stratum16 == `s' & item==`f'
            local antp = r(N)
			qui sum lnp [aw= hhwgt] if  stratum16 == `s' & item==`f', detail
			local ameanp = r(mean)
			local asdp   = r(sd)			
      
		    replace  p =. if (abs((lnp - `ameanp') / `asdp') > 2.5 & ~mi(lnp)) &  stratum16 == `s' & item==`f'
		 	qui count if p > 0 & ~mi(p) &  stratum16 == `s' & item==`f'
		 	local postp = r(N)
			
		   }
	     }
       }
     
	gen outlier=(p==.)
	
	noi di as error "Number of outliers"
	count if p==.	
	
		
     *A-calculate median by stratum
	 qui levelsof stratum16, local(strat)
	 qui levelsof item, local(nfood)
 	 qui gen medianstrat = . 
	 foreach s of local strat {
	           foreach f of local nfood {
		qui su p [aw = hhwgt] if stratum16 == `s' & item==`f', detail
		qui replace medianstrat = r(p50) if stratum16 == `s' & item==`f' & medianstrat == .
        }
	  }
			
	
	*3) Correct outliers
	
	/*	 A- STRATUM: Replace outlier with stratum median unit value	 */	
	noi di as error "Replacing outliers by stratum median price per item"	
	replace p=medianstrat if p==. 
	
   *Impute the total value if quantity>0 and value is zero or missing 
   replace value=quantity*p if (quantity>0 & quantity~=.) & (value==. | value==0)
   
   save "$temporary/HH_SEC_9D1_Q1Q2Q3Q4adj", replace


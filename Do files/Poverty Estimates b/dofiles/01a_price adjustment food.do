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
/* This do file identifies outliers in unit values and correct these numbers in daily consumption and 
weekly consumption */
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
                                       DAILY CONSUMPTION							
*                                                                                                    *
*****************************************************************************************************/


	use "$input/HH_SEC_9A2_Q1Q2Q3Q4", clear
	drop if  (s9a2q02==. | s9a2q02==0) & (s9a2q04==. | s9a2q04==0)
	rename (s9a2q01 s9a2q02 s9a2q04) (item quantity value)
	
	duplicates report hhold day item
	duplicates tag hhold day item, gen(tag)
	duplicates drop hhold day item, force
	sort hhold item day
	
	*Rural variable	 
	gen rural=(ruc==1)
	
	*There are 5 quantities with negative sign, we change the sign to positive
	sum quantity, de
	
	replace quantity=1    if hhold==231054 & day==3  & item==192  
	replace quantity=2    if hhold==1619030 & day==9 & item==192  
    replace quantity=1500 if hhold==1654086 & day==1 & item==12
    replace quantity=10   if hhold==1710061 & day==13 & item==204
    replace quantity=1500 if hhold==2125053 & day==6 & item==13
	
	gen p_1 = (value/quantity)
	la var p_1 "Initial unit value"

	gen p=p_1 
	
	/*When quantity>0 and the unit value is zero we replace these values for missing and at the end 
	we use the medians to impute those prices, and compute the total value */
	
	replace p=. if (quantity>0 & quantity~=.) & (value==. | value==0)
	
	
	*Create Ln of p
	quietly gen lnp = ln(p) 
	
	
	* 1) Identify and replace outliers as missings
	
	qui levelsof item, local (food) 	
	foreach f of local food {
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
      
		    replace  p =. if (abs((lnp - `ameanp') / `asdp') > 2.5 & ~mi(lnp)) & stratum16 == `s' & item==`f'
		 	qui count if p > 0 & ~mi(p) & stratum16 == `s' & item==`f'
		 	local postp = r(N)
			
		   }
	     }
       }
     
	gen outlier=(p==.)
	
	noi di as error "Number of outliers"
	count if p==.	
	
		
	*2) Count number of observations without outliers
	bysort hhold      item: egen counthhold= count(p)
	bysort psu        item: egen countpsu=  count(p)
	bysort zila       item: egen countzila= count(p)
    bysort stratum16  item: egen countstratum= count(p)
	bysort rural      item: egen countarea  = count(p)

		
	*3) Calculate medians 
	
	*A- Calculate median by household and item
	bysort hhold      item: egen medianhhold=   median(p)
	
	
	*B- Calculate median by PSU and item
	bysort psu        item: egen medianpsu=     median(p)
	
	
	*C-calculate median by zila	and item
	 qui levelsof zila, local(strat)
	 qui levelsof item, local(food)
 	  qui gen medianzila = . 
	  foreach z of local strat {
	           foreach f of local food {
		qui su p [aw = hhwgt] if zila == `z' & item==`f', detail
		qui replace medianzila = r(p50) if zila == `z' & item==`f' & medianzila == .
        }
	    }
	
     *D-calculate median by stratum	
	 qui levelsof stratum16, local(strat)
	 qui levelsof item, local(food)
 	  qui gen medianstratum = . 
	  foreach s of local strat {
	           foreach f of local food {
		qui su p [aw = hhwgt] if stratum == `s' & item==`f', detail
		qui replace medianstratum = r(p50) if stratum == `s' & item==`f' & medianstratum == .
        }
	  }
		
	
	 *E-calculate median by urban/rural		 
	 qui levelsof rural, local(strat)
	 qui levelsof item, local(food)
 	  qui gen medianarea = . 
	  foreach s of local strat {
	           foreach f of local food {
		qui su p [aw = hhwgt] if rural == `s' & item==`f', detail
		qui replace medianarea = r(p50) if rural == `s' & item==`f' & medianarea == .
        }
	  }

	  *F- Calculate median by country
	  qui su p [aw = hhwgt] if p!=0, detail
      gen mediancountry = r(p50) 

	
	*4) Correct outliers
	
		/*
     We impute the MEDIAN values at different levels. We start from the lowest or 
	 closest level (household) to the highest level (stratum):
	 
	 A- HOUSEHOLD: maximum number of observations = 14. We ask for more than 9 observations per household and item 
	 
	 B- PSU: We ask for more than 9 observations per PSU and item.
				 
	 C- ZILA: We ask for more than 9 observations per zila and item.
	 
	 D- STRATUM: We ask for more than 9 observations per stratum and item.
	 
	 E- URBAN/RURAL: We ask for more than 9 observations per area and item.
	 
	 F- NATIONAL: Replace outlier with national unit value	 */	
	
	
	noi di as error "Replacing outliers by household median price per item"	
	replace p=medianhhold if p==. & counthhold>9

	noi di as error "Replacing outliers by psu median price per item"	
	replace p=medianpsu  if p==. & countpsu>9
	
	noi di as error "Replacing outliers by zila median price per item"	
	replace p=medianzila if p==. & countzila>9
	
   	noi di as error "Replacing outliers by stratum median price per item"	
	replace p=medianstratum if p==. & countstratum>9
	
	noi di as error "Replacing outliers by area median price per item"	
	replace p=medianarea if p==. & countarea>9
	
	noi di as error "Replacing outliers by country median price per item"	
	replace p=mediancountry if p==. 
	
   *Impute the total value if quantity>0 and value is zero or missing 
   replace value=quantity*p if (quantity>0 & quantity~=.) & (value==. | value==0)
	
   save "$temporary/HH_SEC_9A2_Q1Q2Q3Q4adj", replace
   

   
   
    /*****************************************************************************************************
    *                                                                                                    *
                                       WEEKLY CONSUMPTION							
    *                                                                                                    *
    *****************************************************************************************************/
   
    use "$input/HH_SEC_9B2_Q1Q2Q3Q4", clear
	drop if  (s9b2q02==. | s9b2q02==0) & (s9bbq04==. | s9bbq04==0)

	rename (s9b2q01 s9b2q02 s9bbq04) (item quantity value)

    duplicates report hhold week item
    duplicates drop hhold week item, force
	
	*Rural variable	 
	gen rural=(ruc==1)

		
	*There are 3 quantities with negative sign, we change the sign to positive
	sum quantity, de
	
	replace quantity=75     if hhold==1695126 & week==1  & item==211
	replace quantity=125    if hhold==1710018 & week==2  & item==214 
    replace quantity=50     if hhold==1710061 & week==2  & item==215
	

    gen p_1 = (value/quantity)
	la var p_1 "Initial unit value"
	
	gen p=p_1 
	
	/*When quantity>0 and total value is zero, the unit value is zero. We replace these values for missing and at the end 
	we use the medians to impute those prices, and compute the total value */
	
	replace p=. if (quantity>0 & quantity~=.) & (value==. | value==0)
	
	
	*Create Ln of p
	quietly gen lnp = ln(p) 
	
	
	* 1) Identify and delete outliers
	
	qui levelsof item, local (food) 	
	foreach f of local food {
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
      
		    replace  p =. if (abs((lnp - `ameanp') / `asdp') > 2.5 & ~mi(lnp)) & stratum16 == `s' & item==`f'
		 	qui count if p > 0 & ~mi(p) & stratum16 == `s' & item==`f'
		 	local postp = r(N)
			
		   }
	     }
       }
     
	 
	gen outlier=(p==.)
	
	noi di as error "Number of outliers"
	count if p==.	
	
		
	*2) Count number of observations without outliers
	bysort hhold      item: egen counthhold= count(p)
	bysort psu        item: egen countpsu=  count(p)
	bysort zila       item: egen countzila= count(p)
    bysort stratum16  item: egen countstratum= count(p)
	bysort rural      item: egen countarea  = count(p)

		
	*2) Calculate medians 
	
	*A- Calculate median by household and item
	bysort hhold      item: egen medianhhold=   median(p)
	
	
	*B- Calculate median by PSU and item
	bysort psu        item: egen medianpsu=     median(p)
	
	
	*C-calculate median by zila	and item
	 qui levelsof zila, local(strat)
	 qui levelsof item, local(food)
 	  qui gen medianzila = . 
	  foreach z of local strat {
	           foreach f of local food {
		qui su p [aw = hhwgt] if zila == `z' & item==`f', detail
		qui replace medianzila = r(p50) if zila == `z' & item==`f' & medianzila == .
        }
	    }
	
     *D-calculate median by stratum	
	 qui levelsof stratum16, local(strat)
	 qui levelsof item, local(food)
 	  qui gen medianstratum = . 
	  foreach s of local strat {
	           foreach f of local food {
		qui su p [aw = hhwgt] if stratum == `s' & item==`f', detail
		qui replace medianstratum = r(p50) if stratum == `s' & item==`f' & medianstratum == .
        }
	  }
	  
	 *E-calculate median by urban/rural		 
	 qui levelsof rural, local(strat)
	 qui levelsof item, local(food)
 	  qui gen medianarea = . 
	  foreach s of local strat {
	           foreach f of local food {
		qui su p [aw = hhwgt] if rural == `s' & item==`f', detail
		qui replace medianarea = r(p50) if rural == `s' & item==`f' & medianarea == .
        }
	  }

	  *F- Calculate median by country
	  qui su p [aw = hhwgt], detail
      gen mediancountry = r(p50) 
	  
   
   	*Number of outliers per household and item
	bysort hhold    item: egen countoutl= count(p) if p==.
    tab countoutl	  
   
   
   	*3) Correct outliers
	
		/*
     We impute the MEDIAN values at different levels. We start from the lowest or 
	 closest level (household) to the highest level (stratum):
	 
	 A- HOUSEHOLD: maximum number of observations = 14. We ask for more than 9 observations per household and item 
	 
	 B- PSU: We ask for more than 9 observations per PSU and item.
				 
	 C- ZILA: We ask for more than 9 observations per zila and item.
	 
	 D- STRATUM: We ask for more than 9 observations per stratum and item.
	 
	 E- URBAN/RURAL: We ask for more than 9 observations per area and item.
	 
	 F- NATIONAL: Replace outlier with national unit value	 */	
	 	
	
	
	noi di as error "Replacing outliers by household median price per item"	
	replace p=medianhhold if p==. &  counthhold>1 & countoutl!=2

	noi di as error "Replacing outliers by psu media price per item"	
	replace p=medianpsu  if p==. & countpsu>9
	
	noi di as error "Replacing outliers by zila median price per item"	
	replace p=medianzila if p==. & countzila>9
	
   	noi di as error "Replacing outliers by stratum median price per item"	
	replace p=medianstratum if p==. & countstratum>9
	
	noi di as error "Replacing outliers by area median price per item"	
	replace p=medianarea if p==. & countarea>9
	
	noi di as error "Replacing outliers by country median price per item"	
	replace p=mediancountry if p==. 
	
	
   *Impute the total value if quantity>0 and value is zero or missing 
   replace value=quantity*p if (quantity>0 & quantity~=.) & (value==. | value==0)

   save "$temporary/HH_SEC_9B2_Q1Q2Q3Q4adj", replace

   

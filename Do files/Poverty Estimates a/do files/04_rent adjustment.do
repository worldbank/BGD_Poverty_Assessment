/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                                BANGLADESH CONSUMPTION AGGREGATES 2016                           **
**                                                                                                  **
** COUNTRY			BANGLADESH
** COUNTRY ISO CODE	BGD
** YEAR				2016
** SURVEY NAME		HOUSEHOLD INCOME AND EXPENDITURE SURVEY 		
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS
** Modified	        12/19/2017                                                                                                 
******************************************************************************************************
*****************************************************************************************************/
/*This do file adjusts consumption for those households who did not report rents nor imputed rents */
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
                                          RENT ADJUSTMENT
*                                                                                                    *
*****************************************************************************************************/

	*Rent and imputed rent variables from Section 9, Part D
	use "$input/HH_SEC_9D2_Q1Q2Q3Q4", clear
	sort hhid

	rename (s9d2q00 s9d2q01) (item value)	
	keep if item==391 | item==392
	drop occ 
	reshape wide value, i(hhid) j(item)

	rename (value391 value392) (rent imprent)
	keep psu hhid hhid rent imprent
	save "$temporary/rent",replace


	*Dwelling characteristics
	use "$input/HH_SEC_6A_Q1Q2Q3Q4", clear	

	gen lnroom=log(s6aq02)
	gen dining= s6aq03
	replace dining=0 if dining==2

	gen kitchen=  s6aq04
	replace kitchen=0 if kitchen==2

	gen brickwall=0
	replace brickwall=1 if s6aq07==5
	replace brickwall=. if s6aq07==.

	gen tapwater=s6aq12
	replace tapwater=0 if  tapwater~=1 &  tapwater~=.

	gen electricity= s6aq17
	replace electricity=0 if  electricity==2 | s6aq17==0

	gen telephone= s6aq19
	replace telephone=0 if telephone==2

	gen ownership=s6aq23

	gen lndwsize=log(s6aq09)

	gen rental=.
	replace rental=1 if s6aq23==2
	replace rental=0 if s6aq23~=2 &  s6aq23~=.

		
	*Rural/urban variable
	g 		urbrural=.
	replace urbrural=1 if ruc==1
	replace urbrural=2 if (ruc==2 | ruc==3)	
	
	keep psu hhid hhid lnroom - rental ownership hhwgt ruc urbrural term qtr stratum16
	save "$temporary/rent2",replace


	*Merging all databases, food and non-food expenditure, rents and dwelling characteristics
	use "$temporary/hhexp_hies2016", clear

	*Merge household food and Non-food expenditure with dwelling characteristics
	merge 1:1 hhid using "$temporary/rent2"
	tab _m
	rename _merge merge1

	*Merge with rent and imputed rent
	merge 1:1 hhid using "$temporary/rent"
	tab _m
	drop _m

	*one household has expenditure equal to zero. We changed that value for missing.
	replace hhexp=. if hhexp==0
	gen dummy1=(hhexp==.)
	gen dummy2=0
	replace dummy2=1 if lnroom==. & dining==. & kitchen==. & brickwall==. & tapwater==. & ///
	electricity==. & telephone==. & lndwsize==. & rental==.

	la var dummy1 "Households who did not report expenditure"
	la var dummy2 "Households who did not report dwelling characteristics"
	drop merge1

	*replacing rent and imputed rent equal to zero for missing
	replace rent=. if rent==0
	replace imprent=. if imprent==0
	

	*Use dwelling ownership information to clean rent and imputed rent variables
	replace imprent=rent if (rent>0 & rent~=.) & ownership~=2 & (imprent==. | imprent==0)
	replace rent=imprent if (imprent>0 & imprent~=.) & ownership==2 & (rent==. | rent==0)

	replace rent=. 	  if (rent>0 & rent~=.) & ownership~=2
	replace imprent=. if (imprent>0 & imprent~=.) & ownership==2
		 
	gen dum1=(rent>0 & rent~=.)
	gen dum2=(imprent>0 & imprent~=.)
	gen lnrent=log(rent)
	gen lnimprent=log(imprent)

	tab stratum16, gen(st)

	* Distribution of rent by stratum - use only rent
	reg lnrent st1-st15  lnroom dining kitchen brickwall tapwater electricity telephone lndwsize [aw=hhwgt]

	* Comparison among predicted values, actual rents and imputed rents 
	predict hat
	gen pr_rent=exp(hat)
	sum rent pr_rent lnrent hat [aw=hhwgt] if dum1==1
	sum imprent pr_rent [aw=hhwgt] if dum2==1
	gen diff1=rent-pr_rent
	gen diff2=imprent-pr_rent
	sum diff1 diff2 [aw=hhwgt]

	kdensity lnrent [aw=hhwgt], gen(x1 lnrent_h)
	label var lnrent_h "density: log(rent)"
	kdensity hat if lnrent~=. [aw=hhwgt], gen(x2 lnrent_h2)
	label var lnrent_h2 "density: predicted log(rent)"
	twoway (line lnrent_h x1) (line lnrent_h2 x2)

	kdensity lnimprent [aw=hhwgt], gen(x3 lnimprent_h)
	label var lnimprent_h "density: log(imprent)"
	kdensity hat if lnimprent~=. [aw=hhwgt], gen(x4 lnimprent_h2)
	label var lnimprent_h2 "density: predicted log(imprent)"
	twoway (line lnimprent_h x3) (line lnimprent_h2 x4)

	* Adjustment for consumption expenditures for households who did not report rents nor imputed rents 
	* Rent and imputed rents are already included in hhexp variable
	rename hhexp consexp
	gen consexp2=consexp
	replace consexp2=consexp+pr_rent/12 if (rent==. | rent==0) & (imprent==. | imprent==0)
	gen nfexp2=nfexp
	replace nfexp2=nfexp+pr_rent/12 if (rent==. | rent==0) & (imprent==. | imprent==0)
	* Monthly expenses for rents 
	gen 	hsvalhh=rent/12 
	replace hsvalhh=imprent/12 if hsvalhh==.
	replace hsvalhh=pr_rent/12 if hsvalhh==.

	replace rent= rent/12
	replace imprent= imprent/12
	replace pr_rent=pr_rent/12

	*keep  hhid stratum wgt2 rent imprent pr_rent hsvalhh fexp nfexp consexp consexp2 nfexp2
	*order hhid stratum wgt2 rent imprent pr_rent hsvalhh fexp nfexp consexp consexp2 nfexp2

	
    list hhid if rent==. & imprent==. & pr_rent==.
	
	la var hhid "Household code"
	la var urbrural " 1 Rural, 2 Urban"
	la var rent "Monthly Rent"
	la var imprent "Monthly imputed rent"
	la var pr_rent "Monthly Predicted rent for households who did not report rents nor imputed rents"
	label var hsvalhh "Monthly rents (rent, imprent, or pr_rent) for household" 
	la var nfexp "Monthly initial Non-food expenditure"
	lab var nfexp2 "Monthly non-food expenditure including predicted rents"
	la var consexp "Monthly initial consumption expenditure"
	lab var consexp2 "Monthly expenditure including predicted rents for hhlds who didn't report rents nor imprent"
	
	
   *Drop extra households in some PSU's 
   	drop if (psu==534 & hhid==114) | (psu==753 & hhid==78) | (psu==780 & hhid==36) |(psu==1254 & hhid==3) ///
    |(psu==1262 & hhid==52)  | (psu==1710 & hhid==97) |(psu==2120 & hhid==70)


	save "$output/expenditure_2016", replace
	erase "$temporary/rent.dta"


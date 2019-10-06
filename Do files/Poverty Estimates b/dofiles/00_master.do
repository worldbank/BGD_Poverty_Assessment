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
** Modified	        05/21/2019                                                                                                 
******************************************************************************************************
*****************************************************************************************************/
/*Run all the do files */
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
                                              ROUTE								
*                                                                                                    *
*****************************************************************************************************/


*Path
glo path         "..."


*Input
glo input2010    "$path\Do files\Data\Auxilliary data"
glo input_raw    "$path\Do files\Data\2016\Raw data"
glo input        "$path\Do files\Data\2016\Raw data\Raw data for b"

glo output       "$path\Do files\Poverty Estimates b\output"
glo temporary    "$path\Do files\Poverty Estimates b\output\temp"
cd               "$output"


*do files
glo do           "$path\Do files\Poverty Estimates b\do files"




/*****************************************************************************************************
*                                                                                                    *
                                          RUN DO FILES								
*                                                                                                    *
*****************************************************************************************************/

do "$do/01_create new input datasets.do"
do "$do/01a_price adjustment food.do"
do "$do/01b_price adjustment non-food.do"
do "$do/02_health and education expenditure.do"
do "$do/03_household expenditure.do"
do "$do/04_rent adjustment.do"
do "$do/05a_budget shares annual.do"
do "$do/05b_budget shares quarters.do"
do "$do/06_Household Income.do"
do "$do/07_poverty database.do"
do "$do/08_poverty tables.do"
do "$do/9_poverty with intertemporal adjustment.do"
do "$do/10_How to compute poverty.do"


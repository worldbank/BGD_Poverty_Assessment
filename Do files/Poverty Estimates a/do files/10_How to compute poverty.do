/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                              BANGLADESH CONSUMPTION AGGREGATES 2016                              **
**                                                                                                  **
** COUNTRY	Bangladesh
** COUNTRY ISO CODE	BGD
** YEAR	2016
** SURVEY NAME	HOUSEHOLD INCOME AND EXPENDITURE SURVEY 2016
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS
** Modified	      05_20_2019 
**                                                                                                  **
*****************************************************************************************************/

/*This dofile shows how to replicate the poverty estimates for Bangaldesh */

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
                                        SUMMARY STATISTICS
*                                                                                                    *
*****************************************************************************************************/	  

use "$output//poverty_indicators2016", clear


*Household consumption and income (Household Indicators, use household weights)
tabstat consexp2 hhincome [aw=hhwgt], statistics(mean p25 p50  p75)  


*Per capita expenditure and per capita income (Per capita indicators, use population weights)
tabstat pcexp pcincome [aw=popwgt], statistics(mean p25 p50  p75)  


*Real Per capita expenditure and per capita income
tabstat rpcexp rpcincome [aw=popwgt], statistics(mean p25 p50  p75)  

	  
   
/*****************************************************************************************************
*                                                                                                    *
                                           POVERTY RATES
*                                                                                                    *
*****************************************************************************************************/


*Quarterly poverty rates, standard erros and confidence intervals. You should use stratum16 variable
svyset psu [pweight=popwgt], strata(stratum16) 
svy: mean upperpoorquarters, over(quarter)
svy: mean lowerpoorquarters, over(quarter)

	
*Annual poverty rates, standard erros and confidence intervals. You should use stratum (stratum132) variable
svyset psu [pweight=popwgt], strata(stratum) 
svy: mean upperpoor
svy: mean lowerpoor

*Urban rural annual poverty rates
svy: mean upperpoor, over(urbrural)
svy: mean lowerpoor, over(urbrural)

*Division annual poverty rates
svy: mean upperpoor, over(division_code)
svy: mean lowerpoor, over(division_code)

*District annual poverty rates
svy: mean upperpoor, over(zila_code)
svy: mean lowerpoor, over(zila_code)


/*****************************************************************************************************
*                                                                                                    *
                                            GINI
*                                                                                                    *
*****************************************************************************************************/

*Install fastgini command

*Gini of real Per capita consumption 
fastgini rpcexp [w=popwgt] 

*Gini of real Per capita Income 
fastgini rpcincome [w=popwgt] 



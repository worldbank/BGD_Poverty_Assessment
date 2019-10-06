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

/*This dofile estimates the poverty rates applying intertemporal adjustment */

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
                                           TEMPORAL ADJUSTMENTS 
*                                                                                                    *
*****************************************************************************************************/

use "$output/poverty_indicators2016_detailed", clear


*Express all real consumptions in 2016 Q1 prices using the inflation of the poverty lines from quarter to quarter


* 1) Create the same upper and lower q1 poverty lines for all quarters
gen zuq1_=zu16quarters if quarter==1
egen zuq1=mean(zuq1_), by (stratum16)

gen zlq1_=zl16quarters if quarter==1
egen zlq1=mean(zlq1_), by (stratum16)

* 2) Calculate the inflation using the upper poverty lines from each quarter
gen timedefu=zu16quarters/zuq1
table stratum quarter, c(m timedefu)

* 3) Bring all consumptions to q1 prices
g pcexpq1=pcexp/timedefu
table stratum quarter, c(m pcexp m pcexpq1)

* 4) Create the real per capita expenditure in q1 prices
g rpcexpq1=rpcexp/timedefu
table stratum quarter, c(m rpcexp m rpcexpq1)

* 5) Calculate the average real consumption expenditure expressed in quarter 1 prices for selected percentiles

table quarter [aw=popwgt], c(p10 rpcexpq1 p25 rpcexpq1 p50 rpcexpq1 p75 rpcexpq1 p90 rpcexpq1)
table term [aw=popwgt], c(p10 rpcexpq1 p25 rpcexpq1 p50 rpcexpq1 p75 rpcexpq1 p90 rpcexpq1)

   

/*****************************************************************************************************
*                                                                                                    *
                                          POVERTY INDICATORS 
*                                                                                                    *
*****************************************************************************************************/

gen upperpoorq1=pcexpq1<zuq1 if pcexp!=.
gen lowerpoorq1=pcexpq1<zlq1 if pcexp!=.


*Selected standard errors
svyset psu [pweight=popwgt], strata(stratum) 
svy: mean upperpoorq1
svy: mean lowerpoorq1


/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                                        BANGLADESH HIES 2016                         **
**                                                                                                   **
** COUNTRY			BANGLADESH
** COUNTRY ISO CODE	BGD
** YEAR				2016
** SURVEY NAME		HOUSEHOLD INCOME AND EXPENDITURE SURVEY 		
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS
** MODIFIED BY	    Joaquin Endara
** Modified         05/20/2019                      *****************************************************************************************************
*****************************************************************************************************/
/*Create all the databases changing the urban and rural classification */
/*****************************************************************************************************
*                                                                                                    *
                                       INITIAL COMMANDS
*                                                                                                    *
*****************************************************************************************************/


** INITIAL COMMANDS
	clear
    set more off
    set max_memory ., perm
	

/*==================================================
1: Fix the Urban Rural missclasification using PSU's
==================================================*/

use "$hies_raw/HH_SEC_A_Q1Q2Q3Q4",clear

gen ruc_new=ruc
*reclassify 259 HH from rural to urban 
#delimit
replace ruc_new=2 if inlist(psu
,222
,343
,641
,642
,705
,706
,928
,929
,1239
,1253
,1717
,1781
,1789
)
;
#d cr

compare ruc_new ruc

gen stratum16_new=stratum16

*Reclassify 40 HH from Stratum Chittagong rural to Chittagong Urban
replace stratum16_new=4 if inlist(psu,222,343)

*reclassify  120 HH from Dhaka Rural to Urban stratum 
replace stratum16_new=7 if inlist(psu,641,642,705,706,928,929)

*reclassify  40 HH from Khulna Rural to Urban stratum
replace stratum16_new=10 if inlist(psu,1239,1253)

*reclassify  60 HH from Rajshahi Rural to Urban stratum
replace stratum16_new=13 if inlist(psu,1717,1781,1789)

compare stratum16_new stratum16

keep hhold ruc_new stratum16_new psu 

lab var stratum16_new "Stratum 16 b"
lab var ruc_new "Rural Urban b"


#d ;
la de stratum16 
1	"Barisal Rural"
2	"Barisal Urban"
3	"Chittagong Rural"
4	"Chittagong Urban"
5	"Chittagong CC"
6	"Dhaka Rural"
7	"Dhaka Urban"
8	"Dhaka CC"
9	"Khulna Rural"
10	"Khulna Urban"
11	"Khulna CC"
12	"Rajshahi Rural"
13	"Rajshahi Urban"
14	"Rajshahi CC"
15	"Sylhet Rural"
16	"Sylhet Urban"
,modify 
;

la de ruc
1	"Rural"
2	"Urban"
3   "City Corporation"
;
#d cr


*rename variable 
rename (stratum16_new  ruc_new) (stratum16 ruc)

*label values
la val stratum16 stratum16
la val ruc ruc

rename (stratum16_new ruc_new) (stratum16 ruc)
save "$input/stratum16_b", replace


/*****************************************************************************************************
*                                                                                                    *
                                            GLOBALS								
*                                                                                                    *
*****************************************************************************************************/


	#delimit;
		glo FILES
			HH_SEC_1A  		
			HH_SEC_1B     
			HH_SEC_1C     
			HH_SEC_1R     
			HH_SEC_2A     
			HH_SEC_2B     
			HH_SEC_3A     
			HH_SEC_4A     
			HH_SEC_4B 	
			HH_SEC_05   			
			HH_SEC_6A 			
			HH_SEC_6B  			
			HH_SEC_7A 			
			HH_SEC_7B 			
			HH_SEC_7C1    
			HH_SEC_7C2    
			HH_SEC_7C3    
			HH_SEC_7C4    
			HH_SEC_7D    
			HH_SEC_7E    		
			HH_SEC_8A     
			HH_SEC_8B 
			HH_SEC_8C  
			HH_SEC_8D1  			
			HH_SEC_8D2
			HH_SEC_9A1   
			HH_SEC_9A2
			HH_SEC_9B1  
			HH_SEC_9B2  
			HH_SEC_9C 
			HH_SEC_9D1
			HH_SEC_9D2
			HH_SEC_9DC
			HH_SEC_9E   
			HH_SEC_9EC   			
			HH_SEC_A			
			; 
    #delimit cr
   

/*****************************************************************************************************
*                                                                                                    *
                                       APPEND ALL SECTIONS								
*                                                                                                    *
*****************************************************************************************************/
 
foreach file of global FILES{
use "$input_raw\\`file'_Q1Q2Q3Q4", clear
drop stratum16 ruc
merge m:1 hhold using "$input/stratum16_b"
tab _m
keep if _m==3
drop _m
save "$input\\`file'_Q1Q2Q3Q4",replace
}



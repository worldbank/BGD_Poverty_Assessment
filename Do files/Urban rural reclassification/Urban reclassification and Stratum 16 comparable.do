/*==================================================
project:       HIES 2016 STRATUM 16 Comparable across time
Author:        Joaquin Endara 
E-email:       jendaracevallos@worldbank.org
url:           
Dependencies:  GPVDR
----------------------------------------------------
Creation Date:    23 Jul 2019 
Modification Date:   
Do-file version:    01
References:   This do files generates comparable areas across time, reasigning HH in the HIES 2016 to transform the CC into SMA. the the dofile replicates this task using the PSU's       
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
version 15.1

drop _all

glo path  "..."

glo hies_raw   = "$path\Do files\Data\2016\Raw data"


/*==================================================
1: Fix the Urban Rural missclasification using PSU's
==================================================*/

use "$hies_raw\COVER",clear

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

keep hhid ruc_new stratum16_new psu 

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


/*==================================================
      2: Generate straum 16 comparable 
	  across time reclassifying PSU
==================================================*/

*stratum comparable from stratum 16 
gen stratum16_comparable=stratum16

*gen ruc comparable
gen ruc_comparable=ruc

*from Chittagong Urban to Chittagon CC (now becoming SMA) 20 HH
replace stratum16_comparable=5 if inlist(psu,343)
replace ruc_comparable=3 if inlist(psu,343)

*from Khulna Urban to Khulna CC (now becoming SMA) 40 HH
replace stratum16_comparable=11 if inlist(psu,1239,1253)
replace ruc_comparable=3 if inlist(psu,1239,1253)

*from Dhaka Urban to Dhaka CC (now becoming SMA) 120 HH
#delimit
replace stratum16_comparable=8 if inlist(psu
,641 
,642 
,705 
,706 
,928 
,929
)
;
replace ruc_comparable=3 if inlist(psu
,641 
,642 
,705 
,706 
,928 
,929
)
;
#d cr			


*Var lables
#d ;
la de stratum16_comparable 
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
,modify 
;

la de ruc_comparable
1	"Rural"
2	"Urban"
3   "SMA"
;
#d cr



la val stratum16_comparable stratum16_comparable
la val ruc_comparable ruc_comparable

lab var stratum16_comparable "Stratum 16 Comparable acros time b"
lab var ruc_comparable "1 Rural 2 Urban 3 SMA Comparable acros time b"

exit 

/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.for details in the methodological note in volume 2 of the 2016 Poverty Assessment 
2.
3.


Version Control: 1.0


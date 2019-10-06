/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                                 HARMONIZATION 2000, 2005, 2010, 2016                             **
**                                                                                                  **
** COUNTRY			Bangladesh
** COUNTRY ISO CODE	BGD
** YEAR				2016
** SURVEY NAME		HOUSEHOLD INCOME AND EXPENDITURE SURVEY 2016
** SURVEY AGENCY	BANGLADESH BUREAU OF STATISTICS
** 
** Modified			07/12/2018 \
**                                                                                                  **
*****************************************************************************************************/
/*This dofile harmonizes 4 waves (2000, 2005, 2010, 2016) of Bangladesh Household Income and Expenditure
Survey (HIES). 

Variables are defined as  s#_q#_yy_t
s# = Section number
q# = Question number
yy = year, 00 for 2000, 05 for 2005, 10 for 2010, 16 for 2016
t = Type of information: Raw=r or Constructed=c */

/*****************************************************************************************************
*                                                                                                    *
                                         INITIAL COMMANDS
*                                                                                                 * 
*****************************************************************************************************/ 

** INITIAL COMMANDS
   set more off, perm
   
    
/*****************************************************************************************************
*                                                                                                    *
                         *  ASSEMBLE WEIGHTS AND GEOGRAPHIC INFORMATION 
*                                                                                                    *
*****************************************************************************************************/

loc files="individual employment household"

foreach file of loc files {
use           `file'2000, clear
append using  `file'2005
append using  `file'2010
append using  `file'2016

dis in red "`file'"
label var year "Year of survey"

gen psu= psu_00 if year==2000
replace psu= psu_05 if year==2005
replace psu= psu_10 if year==2010
replace psu= psu_16 if year==2016
label var psu "Primary sampling unit"
note psu: psu is not comparable across years 

gen long hhid= hhid_00 if year==2000
replace  hhid= hhid_05 if year==2005
replace  hhid= hhid_10 if year==2010
replace  hhid= hhid_16 if year==2016
label var hhid "Household id"
note hhid: Household id is not comparable across years

gen     hhwgt= hhwgt_00 if year==2000
replace hhwgt= hhwgt_05 if year==2005
replace hhwgt= hhwgt_10 if year==2010
replace hhwgt= hhwgt_16 if year==2016
la var  hhwgt "Household Weight"

gen     popwgt= popwgt_00 if year==2000
replace popwgt= popwgt_05 if year==2005
replace popwgt= popwgt_10 if year==2010
replace popwgt= popwgt_16 if year==2016
la var  popwgt "Population Weight"

gen stratum16= stratum_00    if   year==2000 
replace stratum16=stratum_05 if   year==2005
replace stratum16=stratum_10 if   year==2010
replace stratum16=stratum16_16 if year==2016

label drop stratum16
la var stratum16 "Stratum"
la de  stratum16 1 "Barisal Rural" 2 "Barisal Municipality" 3 "Chittagong Rural" 4 "Chittagong Municipality" ///
5 "Chittagong SMA" 6 "Dhaka Rural" 7 "Dhaka Municipality" 8 "Dhaka SMA" 9 "Khulna Rural" 10 "Khulna Municipality" ///
11 "Khulna SMA" 12 "Rajshahi Rural" 13 "Rajshahi Municipality" 14 "Rajshahi SMA" 15 "Sylhet Rural" 16 "Sylhet Municipality"
la val stratum16 stratum16

gen location=.
replace location=1 if stratum16==1 | stratum16==3 | stratum16==6 | stratum16==9 | stratum16==12 | stratum16==15
replace location=2 if stratum16==2 | stratum16==4 | stratum16==7 | stratum16==10 | stratum16==13 | stratum16==16
replace location=3 if stratum16==5 | stratum16==8 | stratum16==11| stratum16==14
la var  location "Rural/Municipality/SMA"
la de   location 1"Rural" 2"Municipality" 3"SMA"
la val  location location

la drop urbrural
gen urbrural=.
replace  urbrural=1 if location==1
replace  urbrural=2 if inlist(location,2,3)
la var   urbrural "1 Rural/2 Urban"
la de    urbrural 1"Rural" 2 "Urban"
la val   urbrural urbrural

*generate rural dummy
gen rural=0
replace rural=1 if urbrural==1
la var   rural "1 if Rural Area"
la de    rural 1 "Rural" 0 "Urban"
la val   rural rural


*Create 7 divisions

/*Mymensingh Division was created in 2015 from districts previously comprising the northern part of Dhaka Division.
We combine Mymensingh with Dhaka in this database */
gen      division= division_00 if year==2000
replace  division= division_05 if year==2005
replace  division= division_10 if year==2010
replace  division= div_16 if year==2016
replace  division=30 if division==45 & year==2016
label var division "7 divisions"
label de division 10 "Barisal" 20 "Chittagong" 30 "Dhaka" 40 "Khulna" 50 "Rajshahi" 55 "Rangpur" 60 "Sylhet"
la val division division

*Districts
gen district    = district_00 if year==2000
replace district= district_05 if year==2005
replace district= district_10 if year==2010
replace district= zl_16 if year==2016
label var district "District/Zila"

la drop district
la de district 4  "BARGUNA"
la de district 6  "BARISAL",add
la de district 9  "BHOLA",add
la de district 42 "JHALOKATI",add
la de district 78 "PATUAKHALI",add
la de district 79 "PIROJPUR",add
la de district 3  "BANDARBAN",add
la de district 12 "BRAHMANBARIA",add
la de district 13 "CHANDPUR",add
la de district 15 "CHITTAGONG",add
la de district 19 "COMILLA",add
la de district 22 "COX'S BAZAR",add
la de district 30 "FENI",add
la de district 46 "KHAGRACHHARI",add
la de district 51 "LAKSHMIPUR",add
la de district 75 "NOAKHALI",add
la de district 84 "RANGAMATI",add
la de district 26 "DHAKA",add
la de district 29 "FARIDPUR",add
la de district 33 "GAZIPUR",add
la de district 35 "GOPALGANJ",add
la de district 39 "JAMALPUR",add
la de district 48 "KISHOREGANJ",add
la de district 54 "MADARIPUR",add
la de district 56 "MANIKGANJ",add
la de district 59 "MUNSHIGANJ",add
la de district 61 "MYMENSINGH",add
la de district 67 "NARAYANGANJ",add
la de district 68 "NARSINGDI",add
la de district 72 "NETRAKONA",add
la de district 82 "RAJBARI",add
la de district 86 "SHARIATPUR",add
la de district 89 "SHERPUR",add
la de district 93 "TANGAIL",add
la de district 1  "BAGERHAT",add
la de district 18 "CHUADANGA",add
la de district 41 "JESSORE",add
la de district 44 "JHENAIDAH",add
la de district 47 "KHULNA",add
la de district 50 "KUSHTIA",add
la de district 55 "MAGURA",add
la de district 57 "MEHERPUR",add
la de district 65 "NARAIL",add
la de district 87 "SATKHIRA",add
la de district 10 "BOGRA",add
la de district 70 "CHAPAI NABABGANJ",add
la de district 38 "JOYPURHAT",add
la de district 64 "NAOGAON",add
la de district 69 "NATORE",add
la de district 76 "PABNA",add
la de district 81 "RAJSHAHI",add
la de district 88 "SIRAJGANJ",add
la de district 27 "DINAJPUR",add
la de district 32 "GAIBANDHA",add
la de district 49 "KURIGRAM",add
la de district 52 "LALMONIRHAT",add
la de district 73 "NILPHAMARI",add
la de district 77 "PANCHAGARH",add
la de district 85 "RANGPUR",add
la de district 94 "THAKURGAON",add
la de district 36 "HABIGANJ",add
la de district 58 "MAULVIBAZAR",add
la de district 90 "SUNAMGANJ",add
la de district 91 "SYLHET",add
la val district district

gen district_code=district
label var district_code "District/Zila code"

gen thana_= string(id_03_code_16,"%02.0f")
tostring zl_16, replace
gen thana_16= zl_16 + thana_
replace thana_16="." if thana_16==".."
destring thana_16, replace
drop thana_

gen     upazila= thana_00 if year==2000
replace upazila= thana_05 if year==2005
replace upazila= thana_10 if year==2010
replace upazila= thana_16 if year==2016
label var upazila "Upazila/Thana"

la de upazila 409 "AMTALI"
la de upazila 419 "BAMNA", add
la de upazila 428 "BARGUNA SADAR", add
la de upazila 447 "BETAGI", add
la de upazila 485 "PATHARGHATA", add
la de upazila 602 "AGAILJHARA", add
la de upazila 603 "BABUGANJ", add
la de upazila 607 "BAKERGANJ", add
la de upazila 610 "BANARI PARA", add
la de upazila 651 "BARISAL SADAR (KOTWALI)", add
la de upazila 632 "GAURNADI", add
la de upazila 636 "HIZLA", add
la de upazila 662 "MEHENDIGANJ", add
la de upazila 669 "MULADI", add
la de upazila 694 "WAZIRPUR", add
la de upazila 918 "BHOLA SADAR", add
la de upazila 921 "BURHANUDDIN", add
la de upazila 925 "CHAR FASSON", add
la de upazila 929 "DAULAT KHAN", add
la de upazila 954 "LALMOHAN", add
la de upazila 965 "MANPURA", add
la de upazila 991 "TAZUMUDDIN", add
la de upazila 4240"JHALOKATI SADAR", add
la de upazila 4243"KANTHALIA", add
la de upazila 4273"NALCHITY", add
la de upazila 4284"RAJAPUR", add
la de upazila 7838"BAUPHAL", add
la de upazila 7852"DASHMINA", add
la de upazila 7855"DUMKI", add
la de upazila 7857"GALACHIPA", add
la de upazila 7866"KALA PARA", add
la de upazila 7876"MIRZAGANJ", add
la de upazila 7895"PATUAKHALI SADAR", add
la de upazila 7914"BHANDARIA", add
la de upazila 7947"KAWKHALI", add
la de upazila 7958"MATHBARIA", add
la de upazila 7976"NAZIRPUR", add
la de upazila 7987"NESARABAD (SWARUPKATI)", add
la de upazila 7980"PIROJPUR SADAR", add
la de upazila 7990"ZIANAGAR", add
la de upazila 304 "ALIKADAM", add
la de upazila 314 "BANDARBAN SADAR", add
la de upazila 351 "LAMA", add
la de upazila 373 "NAIKHONGCHHARI", add
la de upazila 389 "ROWANGCHHARI", add
la de upazila 391 "RUMA", add
la de upazila 395 "THANCHI", add
la de upazila 1202"AKHAURA", add
la de upazila 1233"ASHUGANJ", add
la de upazila 1204"BANCHHARAMPUR", add
la de upazila 1207"BIJOYNAGAR", add
la de upazila 1213"BRAHMANBARIA SADAR", add
la de upazila 1263"KASBA", add
la de upazila 1285"NABINAGAR", add
la de upazila 1290"NASIRNAGAR", add
la de upazila 1294"SARAIL", add
la de upazila 1322"CHANDPUR SADAR", add
la de upazila 1345"FARIDGANJ", add
la de upazila 1347"HAIM CHAR", add
la de upazila 1349"HAJIGANJ", add
la de upazila 1358"KACHUA (CHANDPUR)", add
la de upazila 1376"MATLAB DAKSHIN", add
la de upazila 1379"MATLAB UTTAR", add
la de upazila 1395"SHAHRASTI", add
la de upazila 1504"ANOWARA", add
la de upazila 1510"BAKALIA", add
la de upazila 1508"BANSHKHALI", add
la de upazila 1506"BAYEJID BOSTAMI", add
la de upazila 1512"BOALKHALI", add
la de upazila 1518"CHANDANAISH", add
la de upazila 1519"CHANDGAON", add
la de upazila 1520"CHITTAGONG PORT", add
la de upazila 1528"DOUBLE MOORING", add
la de upazila 1533"FATIKCHHARI", add
la de upazila 1535"HALISHAHAR", add
la de upazila 1537"HATHAZARI", add
la de upazila 1543"KHULSHI", add
la de upazila 1541"KOTWALI (CHITTAGONG)", add
la de upazila 1547"LOHAGARA (CHITTAGONG)", add
la de upazila 1553"MIRSHARAI", add
la de upazila 1555"PAHARTALI", add
la de upazila 1557"PANCHLAISH", add
la de upazila 1565"PATENGA", add
la de upazila 1561"PATIYA", add
la de upazila 1570"RANGUNIA", add
la de upazila 1574"RAOZAN", add
la de upazila 1578"SANDWIP", add
la de upazila 1582"SATKANIA", add
la de upazila 1586"SITAKUNDA", add
la de upazila 1909"BARURA", add
la de upazila 1915"BRAHMAN PARA", add
la de upazila 1918"BURICHANG", add
la de upazila 1927"CHANDINA", add
la de upazila 1931"CHAUDDAGRAM", add
la de upazila 1967"COMILLA ADARSHA SADAR", add
la de upazila 1933"COMILLA SADAR DAKSHIN", add
la de upazila 1936"DAUDKANDI", add
la de upazila 1940"DEBIDWAR", add
la de upazila 1954"HOMNA", add
la de upazila 1972"LAKSAM", add
la de upazila 1974"MANOHARGANJ", add
la de upazila 1975"MEGHNA", add
la de upazila 1981"MURADNAGAR", add
la de upazila 1987"NANGALKOT", add
la de upazila 1994"TITAS", add
la de upazila 2216"CHAKARIA", add
la de upazila 2224"COX'S BAZAR SADAR", add
la de upazila 2245"KUTUBDIA", add
la de upazila 2249"MAHESHKHALI", add
la de upazila 2256"PEKUA", add
la de upazila 2266"RAMU", add
la de upazila 2290"TEKNAF", add
la de upazila 2294"UKHIA", add
la de upazila 3014"CHHAGALNAIYA", add
la de upazila 3025"DAGANBHUIYAN", add
la de upazila 3029"FENI SADAR", add
la de upazila 3041"FULGAZI", add
la de upazila 3051"PARSHURAM", add
la de upazila 3094"SONAGAZI", add
la de upazila 4643"DIGHINALA", add
la de upazila 4649"KHAGRACHHARI SADAR", add
la de upazila 4661"LAKSHMICHHARI", add
la de upazila 4665"MAHALCHHARI", add
la de upazila 4667"MANIKCHHARI", add
la de upazila 4670"MATIRANGA", add
la de upazila 4677"PANCHHARI", add
la de upazila 4680"RAMGARH", add
la de upazila 5133"KAMALNAGAR", add
la de upazila 5143"LAKSHMIPUR SADAR", add
la de upazila 5165"RAMGANJ", add
la de upazila 5173"RAMGATI", add
la de upazila 5158"ROYPUR", add
la de upazila 7507"BEGUMGANJ", add
la de upazila 7510"CHATKHIL", add
la de upazila 7521"COMPANIGANJ (NOAKHALI)", add
la de upazila 7536"HATIYA", add
la de upazila 7547"KABIRHAT", add
la de upazila 7587"NOAKHALI SADAR", add
la de upazila 7580"SENBAGH", add
la de upazila 7583"SONAIMURI", add
la de upazila 7585"SUBARNACHAR", add
la de upazila 8407"BAGHAICHHARI", add
la de upazila 8421"BARKAL", add
la de upazila 8429"BELAI CHHARI", add
la de upazila 8447"JURAI CHHARI", add
la de upazila 8436"KAPTAI", add
la de upazila 8425"KAWKHALI (BETBUNIA)", add
la de upazila 8458"LANGADU", add
la de upazila 8475"NANIARCHAR", add
la de upazila 8478"RAJASTHALI", add
la de upazila 8487"RANGAMATI SADAR", add
la de upazila 2602"ADABOR", add
la de upazila 2604"BADDA", add
la de upazila 2605"BANGSHAL", add
la de upazila 2606"BIMAN BANDAR", add
la de upazila 2608"CANTONMENT", add
la de upazila 2609"CHAK BAZAR", add
la de upazila 2610"DAKSHINKHAN", add
la de upazila 2611"DARUS SALAM", add
la de upazila 2612"DEMRA", add
la de upazila 2614"DHAMRAI", add
la de upazila 2616"DHANMONDI", add
la de upazila 2618"DOHAR", add
la de upazila 2624"GENDARIA", add
la de upazila 2626"GULSHAN", add
la de upazila 2628"HAZARIBAGH", add
la de upazila 2629"JATRABARI", add
la de upazila 2632"KADAMTALI", add
la de upazila 2630"KAFRUL", add
la de upazila 2633"KALABAGAN", add
la de upazila 2634"KAMRANGIR CHAR", add
la de upazila 2638"KERANIGANJ", add
la de upazila 2636"KHILGAON", add
la de upazila 2637"KHILKHET", add
la de upazila 2640"KOTWALI (DHAKA)", add
la de upazila 2642"LALBAGH", add
la de upazila 2648"MIRPUR (DHAKA)", add
la de upazila 2650"MOHAMMADPUR (DHAKA)", add
la de upazila 2654"MOTIJHEEL", add
la de upazila 2662"NAWABGANJ (DHAKA)", add
la de upazila 2663"NEW MARKET", add
la de upazila 2664"PALLABI", add
la de upazila 2665"PALTAN", add
la de upazila 2666"RAMNA", add
la de upazila 2667"RAMPURA", add
la de upazila 2668"SABUJBAGH", add
la de upazila 2672"SAVAR", add
la de upazila 2674"SHAH ALI", add
la de upazila 2675"SHAHBAGH", add
la de upazila 2680"SHER-E-BANGLA NAGAR", add
la de upazila 2676"SHYAMPUR", add
la de upazila 2688"SUTRAPUR", add
la de upazila 2690"TEJGAON", add
la de upazila 2692"TEJGAON IND. AREA", add
la de upazila 2693"TURAG", add
la de upazila 2696"UTTAR KHAN", add
la de upazila 2695"UTTARA", add
la de upazila 2903"ALFADANGA", add
la de upazila 2910"BHANGA", add
la de upazila 2918"BOALMARI", add
la de upazila 2921"CHAR BHADRASAN", add
la de upazila 2947"FARIDPUR SADAR", add
la de upazila 2956"MADHUKHALI", add
la de upazila 2962"NAGARKANDA", add
la de upazila 2984"SADARPUR", add
la de upazila 2990"SALTHA", add
la de upazila 3330"GAZIPUR SADAR", add
la de upazila 3332"KALIAKAIR", add
la de upazila 3334"KALIGANJ (GAZIPUR)", add
la de upazila 3336"KAPASIA", add
la de upazila 3386"SREEPUR (GAZIPUR)", add
la de upazila 3532"GOPALGANJ SADAR", add
la de upazila 3543"KASHIANI", add
la de upazila 3551"KOTALIPARA", add
la de upazila 3558"MUKSUDPUR", add
la de upazila 3591"TUNGIPARA", add
la de upazila 3907"BAKSHIGANJ", add
la de upazila 3915"DEWANGANJ", add
la de upazila 3929"ISLAMPUR", add
la de upazila 3936"JAMALPUR SADAR", add
la de upazila 3958"MADARGANJ", add
la de upazila 3961"MELANDAHA", add
la de upazila 3985"SARISHABARI UPAZILA", add
la de upazila 4802"AUSTAGRAM", add
la de upazila 4806"BAJITPUR", add
la de upazila 4811"BHAIRAB", add
la de upazila 4827"HOSSAINPUR", add
la de upazila 4833"ITNA", add
la de upazila 4842"KARIMGANJ", add
la de upazila 4845"KATIADI", add
la de upazila 4849"KISHOREGANJ SADAR", add
la de upazila 4854"KULIAR CHAR", add
la de upazila 4859"MITHAMAIN", add
la de upazila 4876"NIKLI", add
la de upazila 4879"PAKUNDIA", add
la de upazila 4892"TARAIL", add
la de upazila 5440"KALKINI", add
la de upazila 5454"MADARIPUR SADAR", add
la de upazila 5480"RAJOIR", add
la de upazila 5487"SHIB CHAR", add
la de upazila 5610"DAULATPUR (MANIKGANJ)", add
la de upazila 5622"GHIOR", add
la de upazila 5628"HARIRAMPUR", add
la de upazila 5646"MANIKGANJ SADAR", add
la de upazila 5670"SATURIA", add
la de upazila 5678"SHIBALAYA", add
la de upazila 5682"SINGAIR", add
la de upazila 5924"GAZARIA", add
la de upazila 5944"LOHAJANG", add
la de upazila 5956"MUNSHIGANJ SADAR", add
la de upazila 5974"SERAJDIKHAN", add
la de upazila 5984"SREENAGAR", add
la de upazila 5994"TONGIBARI", add
la de upazila 6113"BHALUKA", add
la de upazila 6116"DHOBAURA", add
la de upazila 6120"FULBARIA", add
la de upazila 6122"GAFFARGAON", add
la de upazila 6123"GAURIPUR", add
la de upazila 6124"HALUAGHAT", add
la de upazila 6131"ISHWARGANJ", add
la de upazila 6165"MUKTAGACHHA", add
la de upazila 6152"MYMENSINGH SADAR", add
la de upazila 6172"NANDAIL", add
la de upazila 6181"PHULPUR", add
la de upazila 6194"TRISHAL", add
la de upazila 6702"ARAIHAZAR", add
la de upazila 6706"BANDAR", add
la de upazila 6758"NARAYANGANJ SADAR", add
la de upazila 6768"RUPGANJ", add
la de upazila 6704"SONARGAON", add
la de upazila 6807"BELABO", add
la de upazila 6852"MANOHARDI", add
la de upazila 6860"NARSINGDI SADAR", add
la de upazila 6863"PALASH", add
la de upazila 6864"ROYPURA", add
la de upazila 6876"SHIBPUR", add
la de upazila 7204"ATPARA", add
la de upazila 7209"BARHATTA", add
la de upazila 7218"DURGAPUR (NETRAKONA)", add
la de upazila 7240"KALMAKANDA", add
la de upazila 7247"KENDUA", add
la de upazila 7238"KHALIAJURI", add
la de upazila 7256"MADAN", add
la de upazila 7263"MOHANGANJ", add
la de upazila 7274"NETROKONA SADAR", add
la de upazila 7283"PURBADHALA", add
la de upazila 8207"BALIAKANDI", add
la de upazila 8229"GOALANDA", add
la de upazila 8247"KALUKHALI", add
la de upazila 8273"PANGSHA", add
la de upazila 8276"RAJBARI SADAR", add
la de upazila 8614"BHEDARGANJ", add
la de upazila 8625"DAMUDYA", add
la de upazila 8636"GOSAIRHAT", add
la de upazila 8665"NARIA", add
la de upazila 8669"SHARIATPUR SADAR", add
la de upazila 8694"ZANJIRA", add
la de upazila 8937"JHENAIGATI", add
la de upazila 8967"NAKLA", add
la de upazila 8970"NALITABARI", add
la de upazila 8988"SHERPUR SADAR", add
la de upazila 8990"SREEBARDI", add
la de upazila 9309"BASAIL", add
la de upazila 9319"BHUAPUR", add
la de upazila 9323"DELDUAR", add
la de upazila 9325"DHANBARI", add
la de upazila 9328"GHATAIL", add
la de upazila 9338"GOPALPUR", add
la de upazila 9347"KALIHATI", add
la de upazila 9357"MADHUPUR", add
la de upazila 9366"MIRZAPUR", add
la de upazila 9376"NAGARPUR", add
la de upazila 9385"SAKHIPUR", add
la de upazila 9395"TANGAIL SADAR", add
la de upazila 108 "BAGERHAT SADAR", add
la de upazila 114 "CHITALMARI", add
la de upazila 134 "FAKIRHAT", add
la de upazila 138 "KACHUA (BAGERHAT)", add
la de upazila 156 "MOLLAHAT", add
la de upazila 158 "MONGLA", add
la de upazila 160 "MORRELGANJ", add
la de upazila 173 "RAMPAL", add
la de upazila 177 "SARANKHOLA", add
la de upazila 1807"ALAMDANGA", add
la de upazila 1823"CHUADANGA SADAR", add
la de upazila 1831"DAMURHUDA", add
la de upazila 1855"JIBAN NAGAR", add
la de upazila 4104"ABHAYNAGAR", add
la de upazila 4109"BAGHER PARA", add
la de upazila 4111"CHAUGACHHA", add
la de upazila 4123"JHIKARGACHHA", add
la de upazila 4138"KESHABPUR", add
la de upazila 4147"JESSORE SADAR", add
la de upazila 4161"MANIRAMPUR", add
la de upazila 4190"SHARSHA", add
la de upazila 4414"HARINAKUNDA", add
la de upazila 4419"JHENAIDAH SADAR", add
la de upazila 4433"KALIGANJ (JHENAIDAH)", add
la de upazila 4442"KOTCHANDPUR", add
la de upazila 4471"MAHESHPUR", add
la de upazila 4480"SHAILKUPA", add
la de upazila 4712"BATIAGHATA", add
la de upazila 4717"DACOPE", add
la de upazila 4721"DAULATPUR", add
la de upazila 4740"DIGHALIA", add
la de upazila 4730"DUMURIA", add
la de upazila 4745"KHALISHPUR", add
la de upazila 4748"KHAN JAHAN ALI", add
la de upazila 4751"KHULNA SADAR", add
la de upazila 4753"KOYRA", add
la de upazila 4764"PAIKGACHHA", add
la de upazila 4769"PHULTALA", add
la de upazila 4775"RUPSA", add
la de upazila 4785"SONADANGA", add
la de upazila 4794"TEROKHADA", add
la de upazila 5015"BHERAMARA", add
la de upazila 5039"DAULATPUR (KUSHTIA)", add
la de upazila 5063"KHOKSA", add
la de upazila 5071"KUMARKHALI", add
la de upazila 5079"KUSHTIA SADAR", add
la de upazila 5094"MIRPUR (KUSHTIA)", add
la de upazila 5557"MAGURA SADAR", add
la de upazila 5566"MOHAMMADPUR (MAGURA)", add
la de upazila 5585"SHALIKHA", add
la de upazila 5595"SREEPUR (MAGURA)", add
la de upazila 5747"GANGNI", add
la de upazila 5787"MEHERPUR SADAR", add
la de upazila 5760"MUJIB NAGAR", add
la de upazila 6528"KALIA", add
la de upazila 6552"LOHAGARA (NARAIL)", add
la de upazila 6576"NARAIL SADAR", add
la de upazila 8704"ASSASUNI", add
la de upazila 8725"DEBHATA", add
la de upazila 8743"KALAROA", add
la de upazila 8747"KALIGANJ (SATKHIRA)", add
la de upazila 8782"SATKHIRA SADAR", add
la de upazila 8786"SHYAMNAGAR", add
la de upazila 8790"TALA", add
la de upazila 1006"ADAMDIGHI", add
la de upazila 1020"BOGRA SADAR", add
la de upazila 1027"DHUNAT", add
la de upazila 1033"DHUPCHANCHIA", add
la de upazila 1040"GABTALI", add
la de upazila 1054"KAHALOO", add
la de upazila 1067"NANDIGRAM", add
la de upazila 1081"SARIAKANDI", add
la de upazila 1085"SHAJAHANPUR", add
la de upazila 1088"SHERPUR", add
la de upazila 1094"SHIBGANJ (BOGRA)", add
la de upazila 1095"SONATOLA", add
la de upazila 3813"AKKELPUR", add
la de upazila 3847"JOYPURHAT SADAR", add
la de upazila 3858"KALAI", add
la de upazila 3861"KHETLAL", add
la de upazila 3874"PANCHBIBI", add
la de upazila 6403"ATRAI", add
la de upazila 6406"BADALGACHHI", add
la de upazila 6428"DHAMOIRHAT", add
la de upazila 6450"MAHADEBPUR", add
la de upazila 6447"MANDA", add
la de upazila 6460"NAOGAON SADAR", add
la de upazila 6469"NIAMATPUR", add
la de upazila 6475"PATNITALA", add
la de upazila 6479"PORSHA", add
la de upazila 6485"RANINAGAR", add
la de upazila 6486"SAPAHAR", add
la de upazila 6909"BAGATIPARA", add
la de upazila 6915"BARAIGRAM", add
la de upazila 6941"GURUDASPUR", add
la de upazila 6944"LALPUR", add
la de upazila 6963"NATORE SADAR", add
la de upazila 6991"SINGRA", add
la de upazila 7018"BHOLAHAT", add
la de upazila 7037"GOMASTAPUR", add
la de upazila 7056"NACHOLE", add
la de upazila 7066"CHAPAI NABABGANJ SADAR", add
la de upazila 7088"SHIBGANJ (CHAPAI NABABGANJ)", add
la de upazila 7605"ATGHARIA", add
la de upazila 7616"BERA", add
la de upazila 7619"BHANGURA", add
la de upazila 7622"CHATMOHAR", add
la de upazila 7633"FARIDPUR", add
la de upazila 7639"ISHWARDI", add
la de upazila 7655"PABNA SADAR", add
la de upazila 7672"SANTHIA", add
la de upazila 7683"SUJANAGAR", add
la de upazila 8110"BAGHA", add
la de upazila 8112"BAGHMARA", add
la de upazila 8122"BOALIA", add
la de upazila 8125"CHARGHAT", add
la de upazila 8131"DURGAPUR (RAJSHAHI)", add
la de upazila 8134"GODAGARI", add
la de upazila 8140"MATIHAR", add
la de upazila 8153"MOHANPUR", add
la de upazila 8172"PABA", add
la de upazila 8182"PUTHIA", add
la de upazila 8185"RAJPARA", add
la de upazila 8190"SHAH MAKHDUM", add
la de upazila 8194"TANORE", add
la de upazila 8811"BELKUCHI", add
la de upazila 8827"CHAUHALI", add
la de upazila 8844"KAMARKHANDA", add
la de upazila 8850"KAZIPUR", add
la de upazila 8861"ROYGANJ", add
la de upazila 8867"SHAHJADPUR", add
la de upazila 8878"SIRAJGANJ SADAR", add
la de upazila 8889"TARASH", add
la de upazila 8894"ULLAH PARA", add
la de upazila 2717"BIRAL", add
la de upazila 2710"BIRAMPUR", add
la de upazila 2712"BIRGANJ", add
la de upazila 2721"BOCHAGANJ", add
la de upazila 2730"CHIRIRBANDAR", add
la de upazila 2764"DINAJPUR SADAR", add
la de upazila 2738"FULBARI", add
la de upazila 2743"GHORAGHAT", add
la de upazila 2747"HAKIMPUR", add
la de upazila 2756"KAHAROLE", add
la de upazila 2760"KHANSAMA", add
la de upazila 2769"NAWABGANJ (DINAJPUR)", add
la de upazila 2777"PARBATIPUR", add
la de upazila 3221"FULCHHARI", add
la de upazila 3224"GAIBANDHA SADAR", add
la de upazila 3230"GOBINDAGANJ", add
la de upazila 3267"PALASHBARI", add
la de upazila 3282"SADULLAPUR", add
la de upazila 3288"SAGHATA", add
la de upazila 3291"SUNDARGANJ", add
la de upazila 4906"BHURUNGAMARI", add
la de upazila 4908"CHAR RAJIBPUR", add
la de upazila 4909"CHILMARI", add
la de upazila 4952"KURIGRAM SADAR", add
la de upazila 4961"NAGESHWARI", add
la de upazila 4918"PHULBARI", add
la de upazila 4977"RAJARHAT", add
la de upazila 4979"RAUMARI", add
la de upazila 4994"ULIPUR", add
la de upazila 5202"ADITMARI", add
la de upazila 5233"HATIBANDHA", add
la de upazila 5239"KALIGANJ (LALMONIRHAT)", add
la de upazila 5255"LALMONIRHAT SADAR", add
la de upazila 5270"PATGRAM", add
la de upazila 7312"DIMLA", add
la de upazila 7315"DOMAR", add
la de upazila 7336"JALDHAKA", add
la de upazila 7345"KISHOREGANJ", add
la de upazila 7364"NILPHAMARI SADAR", add
la de upazila 7385"SAIDPUR", add
la de upazila 7704"ATWARI", add
la de upazila 7734"DEBIGANJ", add
la de upazila 7790"TENTULIA", add
la de upazila 8503"BADARGANJ", add
la de upazila 8527"GANGACHARA", add
la de upazila 8542"KAUNIA", add
la de upazila 8558"MITHA PUKUR", add
la de upazila 8573"PIRGACHHA", add
la de upazila 8576"PIRGANJ (RANGPUR)", add
la de upazila 8549"RANGPUR SADAR", add
la de upazila 8592"TARAGANJ", add
la de upazila 9408"BALIADANGI", add
la de upazila 9451"HARIPUR", add
la de upazila 9482"PIRGANJ (THAKURGAON)", add
la de upazila 9486"RANISANKAIL", add
la de upazila 9494"THAKURGAON SADAR", add
la de upazila 3602"AJMIRIGANJ", add
la de upazila 3605"BAHUBAL", add
la de upazila 3611"BANIACHONG", add
la de upazila 3626"CHUNARUGHAT", add
la de upazila 3644"HABIGANJ SADAR", add
la de upazila 3668"LAKHAI", add
la de upazila 3671"MADHABPUR", add
la de upazila 3677"NABIGANJ", add
la de upazila 5814"BARLEKHA", add
la de upazila 5835"JURI", add
la de upazila 5856"KAMALGANJ", add
la de upazila 5865"KULAURA", add
la de upazila 5874"MAULVIBAZAR SADAR", add
la de upazila 5880"RAJNAGAR", add
la de upazila 5883"SREEMANGAL", add
la de upazila 9018"BISHWAMBARPUR", add
la de upazila 9023"CHHATAK", add
la de upazila 9027"DAKSHIN SUNAMGANJ", add
la de upazila 9029"DERAI", add
la de upazila 9032"DHARAMPASHA", add
la de upazila 9033"DOWARABAZAR", add
la de upazila 9047"JAGANNATHPUR", add
la de upazila 9050"JAMALGANJ", add
la de upazila 9086"SULLA", add
la de upazila 9089"SUNAMGANJ SADAR", add
la de upazila 9092"TAHIRPUR", add
la de upazila 9108"BALAGANJ", add
la de upazila 9117"BEANI BAZAR", add
la de upazila 9120"BISHWANATH", add
la de upazila 9127"COMPANIGANJ (SYLHET)", add
la de upazila 9131"DAKSHIN SURMA", add
la de upazila 9135"FENCHUGANJ", add
la de upazila 9138"GOLAPGANJ", add
la de upazila 9141"GOWAINGHAT", add
la de upazila 9153"JAINTIAPUR", add
la de upazila 9159"KANAIGHAT", add
la de upazila 9162"SYLHET SADAR", add
la de upazila 9194"ZAKIGANJ", add
la de upazila 7725"BODA", add
la de upazila 7773"PANCHAGARH SADAR", add
la val upazila upazila

gen upazila_code=upazila
label var upazila_code "Upazila/Thana code"

la var quarter_16 "Quarter 2016"

save `file', replace
}  
/*
* Microcredit and migration are available for years 2010 and 2016

foreach file in microcredit migration {
use           `file'2010, clear
append using  `file'2016

label var year "Year of survey"

gen psu= psu_10 if year==2010
replace psu= psu_16 if year==2016
label var psu "Primary sampling unit"
note psu: psu is not comparable across years 

gen long hhid= hhid_10 if year==2010
replace  hhid= hhid_16 if year==2016
label var hhid "Household id"
note hhid: Household id is not comparable across years

gen hhwgt= hhwgt_10 if year==2010
replace hhwgt= hhwgt_16 if year==2016
la var  hhwgt "Household Weight"

gen popwgt= popwgt_10 if year==2010
replace popwgt= popwgt_16 if year==2016
la var  popwgt "Population Weight"

gen stratum16=stratum_10 if   year==2010
replace stratum16=stratum16_16 if year==2016

label drop stratum16
la var stratum16 "Stratum"
la de  stratum16 1 "Barisal Rural" 2 "Barisal Municipality" 3 "Chittagong Rural" 4 "Chittagong Municipality" ///
5 "Chittagong SMA" 6 "Dhaka Rural" 7 "Dhaka Municipality" 8 "Dhaka SMA" 9 "Khulna Rural" 10 "Khulna Municipality" ///
11 "Khulna SMA" 12 "Rajshahi Rural" 13 "Rajshahi Municipality" 14 "Rajshahi SMA" 15 "Sylhet Rural" 16 "Sylhet Municipality"
la val stratum16 stratum16

gen location=.
replace location=1 if stratum16==1 | stratum16==3 | stratum16==6 | stratum16==9 | stratum16==12 | stratum16==15
replace location=2 if stratum16==2 | stratum16==4 | stratum16==7 | stratum16==10 | stratum16==13 | stratum16==16
replace location=3 if stratum16==5 | stratum16==8 | stratum16==11| stratum16==14
la var  location "Rural/Municipality/SMA"
la de   location 1"Rural" 2"Municipality" 3"SMA"
la val  location location

la drop urbrural

gen urbrural=.
replace  urbrural=1 if location==1
replace  urbrural=2 if inlist(location,2,3)
la var   urbrural "1 Rural/2 Urban"
la de    urbrural 1"Rural" 2 "Urban", modify
la val   urbrural urbrural

*Create 7 divisions
/*Mymensingh Division was created in 2015 from districts previously comprising the northern part of Dhaka Division.
We combine Mymensingh with Dhaka in this database */
gen division= division_10 if year==2010
replace  division= div_16 if year==2016
replace  division=30 if division==45 & year==2016
label var division "7 divisions"
label de division 10 "Barisal" 20 "Chittagong" 30 "Dhaka" 40 "Khulna" 50 "Rajshahi" 55 "Rangpur" 60 "Sylhet"
la val division division

*Districts
gen district= district_10 if year==2010
replace district= zl_16 if year==2016
label var district "District/Zila"

la de district 4  "BARGUNA"
la de district 6  "BARISAL",add
la de district 9  "BHOLA",add
la de district 42 "JHALOKATI",add
la de district 78 "PATUAKHALI",add
la de district 79 "PIROJPUR",add
la de district 3  "BANDARBAN",add
la de district 12 "BRAHMANBARIA",add
la de district 13 "CHANDPUR",add
la de district 15 "CHITTAGONG",add
la de district 19 "COMILLA",add
la de district 22 "COX'S BAZAR",add
la de district 30 "FENI",add
la de district 46 "KHAGRACHHARI",add
la de district 51 "LAKSHMIPUR",add
la de district 75 "NOAKHALI",add
la de district 84 "RANGAMATI",add
la de district 26 "DHAKA",add
la de district 29 "FARIDPUR",add
la de district 33 "GAZIPUR",add
la de district 35 "GOPALGANJ",add
la de district 39 "JAMALPUR",add
la de district 48 "KISHOREGANJ",add
la de district 54 "MADARIPUR",add
la de district 56 "MANIKGANJ",add
la de district 59 "MUNSHIGANJ",add
la de district 61 "MYMENSINGH",add
la de district 67 "NARAYANGANJ",add
la de district 68 "NARSINGDI",add
la de district 72 "NETRAKONA",add
la de district 82 "RAJBARI",add
la de district 86 "SHARIATPUR",add
la de district 89 "SHERPUR",add
la de district 93 "TANGAIL",add
la de district 1  "BAGERHAT",add
la de district 18 "CHUADANGA",add
la de district 41 "JESSORE",add
la de district 44 "JHENAIDAH",add
la de district 47 "KHULNA",add
la de district 50 "KUSHTIA",add
la de district 55 "MAGURA",add
la de district 57 "MEHERPUR",add
la de district 65 "NARAIL",add
la de district 87 "SATKHIRA",add
la de district 10 "BOGRA",add
la de district 70 "CHAPAI NABABGANJ",add
la de district 38 "JOYPURHAT",add
la de district 64 "NAOGAON",add
la de district 69 "NATORE",add
la de district 76 "PABNA",add
la de district 81 "RAJSHAHI",add
la de district 88 "SIRAJGANJ",add
la de district 27 "DINAJPUR",add
la de district 32 "GAIBANDHA",add
la de district 49 "KURIGRAM",add
la de district 52 "LALMONIRHAT",add
la de district 73 "NILPHAMARI",add
la de district 77 "PANCHAGARH",add
la de district 85 "RANGPUR",add
la de district 94 "THAKURGAON",add
la de district 36 "HABIGANJ",add
la de district 58 "MAULVIBAZAR",add
la de district 90 "SUNAMGANJ",add
la de district 91 "SYLHET",add
la val district district

gen district_code=district
label var district_code "District/Zila code"

gen thana_= string(id_03_code_16,"%02.0f")
tostring zl_16, replace
gen thana_16= zl_16 + thana_
replace thana_16="." if thana_16==".."
destring thana_16, replace
drop thana_

gen upazila= thana_10 if year==2010
replace upazila= thana_16 if year==2016
label var upazila "Upazila/Thana"

la de upazila 409 "AMTALI"
la de upazila 419 "BAMNA", add
la de upazila 428 "BARGUNA SADAR", add
la de upazila 447 "BETAGI", add
la de upazila 485 "PATHARGHATA", add
la de upazila 602 "AGAILJHARA", add
la de upazila 603 "BABUGANJ", add
la de upazila 607 "BAKERGANJ", add
la de upazila 610 "BANARI PARA", add
la de upazila 651 "BARISAL SADAR (KOTWALI)", add
la de upazila 632 "GAURNADI", add
la de upazila 636 "HIZLA", add
la de upazila 662 "MEHENDIGANJ", add
la de upazila 669 "MULADI", add
la de upazila 694 "WAZIRPUR", add
la de upazila 918 "BHOLA SADAR", add
la de upazila 921 "BURHANUDDIN", add
la de upazila 925 "CHAR FASSON", add
la de upazila 929 "DAULAT KHAN", add
la de upazila 954 "LALMOHAN", add
la de upazila 965 "MANPURA", add
la de upazila 991 "TAZUMUDDIN", add
la de upazila 4240"JHALOKATI SADAR", add
la de upazila 4243"KANTHALIA", add
la de upazila 4273"NALCHITY", add
la de upazila 4284"RAJAPUR", add
la de upazila 7838"BAUPHAL", add
la de upazila 7852"DASHMINA", add
la de upazila 7855"DUMKI", add
la de upazila 7857"GALACHIPA", add
la de upazila 7866"KALA PARA", add
la de upazila 7876"MIRZAGANJ", add
la de upazila 7895"PATUAKHALI SADAR", add
la de upazila 7914"BHANDARIA", add
la de upazila 7947"KAWKHALI", add
la de upazila 7958"MATHBARIA", add
la de upazila 7976"NAZIRPUR", add
la de upazila 7987"NESARABAD (SWARUPKATI)", add
la de upazila 7980"PIROJPUR SADAR", add
la de upazila 7990"ZIANAGAR", add
la de upazila 304 "ALIKADAM", add
la de upazila 314 "BANDARBAN SADAR", add
la de upazila 351 "LAMA", add
la de upazila 373 "NAIKHONGCHHARI", add
la de upazila 389 "ROWANGCHHARI", add
la de upazila 391 "RUMA", add
la de upazila 395 "THANCHI", add
la de upazila 1202"AKHAURA", add
la de upazila 1233"ASHUGANJ", add
la de upazila 1204"BANCHHARAMPUR", add
la de upazila 1207"BIJOYNAGAR", add
la de upazila 1213"BRAHMANBARIA SADAR", add
la de upazila 1263"KASBA", add
la de upazila 1285"NABINAGAR", add
la de upazila 1290"NASIRNAGAR", add
la de upazila 1294"SARAIL", add
la de upazila 1322"CHANDPUR SADAR", add
la de upazila 1345"FARIDGANJ", add
la de upazila 1347"HAIM CHAR", add
la de upazila 1349"HAJIGANJ", add
la de upazila 1358"KACHUA (CHANDPUR)", add
la de upazila 1376"MATLAB DAKSHIN", add
la de upazila 1379"MATLAB UTTAR", add
la de upazila 1395"SHAHRASTI", add
la de upazila 1504"ANOWARA", add
la de upazila 1510"BAKALIA", add
la de upazila 1508"BANSHKHALI", add
la de upazila 1506"BAYEJID BOSTAMI", add
la de upazila 1512"BOALKHALI", add
la de upazila 1518"CHANDANAISH", add
la de upazila 1519"CHANDGAON", add
la de upazila 1520"CHITTAGONG PORT", add
la de upazila 1528"DOUBLE MOORING", add
la de upazila 1533"FATIKCHHARI", add
la de upazila 1535"HALISHAHAR", add
la de upazila 1537"HATHAZARI", add
la de upazila 1543"KHULSHI", add
la de upazila 1541"KOTWALI (CHITTAGONG)", add
la de upazila 1547"LOHAGARA (CHITTAGONG)", add
la de upazila 1553"MIRSHARAI", add
la de upazila 1555"PAHARTALI", add
la de upazila 1557"PANCHLAISH", add
la de upazila 1565"PATENGA", add
la de upazila 1561"PATIYA", add
la de upazila 1570"RANGUNIA", add
la de upazila 1574"RAOZAN", add
la de upazila 1578"SANDWIP", add
la de upazila 1582"SATKANIA", add
la de upazila 1586"SITAKUNDA", add
la de upazila 1909"BARURA", add
la de upazila 1915"BRAHMAN PARA", add
la de upazila 1918"BURICHANG", add
la de upazila 1927"CHANDINA", add
la de upazila 1931"CHAUDDAGRAM", add
la de upazila 1967"COMILLA ADARSHA SADAR", add
la de upazila 1933"COMILLA SADAR DAKSHIN", add
la de upazila 1936"DAUDKANDI", add
la de upazila 1940"DEBIDWAR", add
la de upazila 1954"HOMNA", add
la de upazila 1972"LAKSAM", add
la de upazila 1974"MANOHARGANJ", add
la de upazila 1975"MEGHNA", add
la de upazila 1981"MURADNAGAR", add
la de upazila 1987"NANGALKOT", add
la de upazila 1994"TITAS", add
la de upazila 2216"CHAKARIA", add
la de upazila 2224"COX'S BAZAR SADAR", add
la de upazila 2245"KUTUBDIA", add
la de upazila 2249"MAHESHKHALI", add
la de upazila 2256"PEKUA", add
la de upazila 2266"RAMU", add
la de upazila 2290"TEKNAF", add
la de upazila 2294"UKHIA", add
la de upazila 3014"CHHAGALNAIYA", add
la de upazila 3025"DAGANBHUIYAN", add
la de upazila 3029"FENI SADAR", add
la de upazila 3041"FULGAZI", add
la de upazila 3051"PARSHURAM", add
la de upazila 3094"SONAGAZI", add
la de upazila 4643"DIGHINALA", add
la de upazila 4649"KHAGRACHHARI SADAR", add
la de upazila 4661"LAKSHMICHHARI", add
la de upazila 4665"MAHALCHHARI", add
la de upazila 4667"MANIKCHHARI", add
la de upazila 4670"MATIRANGA", add
la de upazila 4677"PANCHHARI", add
la de upazila 4680"RAMGARH", add
la de upazila 5133"KAMALNAGAR", add
la de upazila 5143"LAKSHMIPUR SADAR", add
la de upazila 5165"RAMGANJ", add
la de upazila 5173"RAMGATI", add
la de upazila 5158"ROYPUR", add
la de upazila 7507"BEGUMGANJ", add
la de upazila 7510"CHATKHIL", add
la de upazila 7521"COMPANIGANJ (NOAKHALI)", add
la de upazila 7536"HATIYA", add
la de upazila 7547"KABIRHAT", add
la de upazila 7587"NOAKHALI SADAR", add
la de upazila 7580"SENBAGH", add
la de upazila 7583"SONAIMURI", add
la de upazila 7585"SUBARNACHAR", add
la de upazila 8407"BAGHAICHHARI", add
la de upazila 8421"BARKAL", add
la de upazila 8429"BELAI CHHARI", add
la de upazila 8447"JURAI CHHARI", add
la de upazila 8436"KAPTAI", add
la de upazila 8425"KAWKHALI (BETBUNIA)", add
la de upazila 8458"LANGADU", add
la de upazila 8475"NANIARCHAR", add
la de upazila 8478"RAJASTHALI", add
la de upazila 8487"RANGAMATI SADAR", add
la de upazila 2602"ADABOR", add
la de upazila 2604"BADDA", add
la de upazila 2605"BANGSHAL", add
la de upazila 2606"BIMAN BANDAR", add
la de upazila 2608"CANTONMENT", add
la de upazila 2609"CHAK BAZAR", add
la de upazila 2610"DAKSHINKHAN", add
la de upazila 2611"DARUS SALAM", add
la de upazila 2612"DEMRA", add
la de upazila 2614"DHAMRAI", add
la de upazila 2616"DHANMONDI", add
la de upazila 2618"DOHAR", add
la de upazila 2624"GENDARIA", add
la de upazila 2626"GULSHAN", add
la de upazila 2628"HAZARIBAGH", add
la de upazila 2629"JATRABARI", add
la de upazila 2632"KADAMTALI", add
la de upazila 2630"KAFRUL", add
la de upazila 2633"KALABAGAN", add
la de upazila 2634"KAMRANGIR CHAR", add
la de upazila 2638"KERANIGANJ", add
la de upazila 2636"KHILGAON", add
la de upazila 2637"KHILKHET", add
la de upazila 2640"KOTWALI (DHAKA)", add
la de upazila 2642"LALBAGH", add
la de upazila 2648"MIRPUR (DHAKA)", add
la de upazila 2650"MOHAMMADPUR (DHAKA)", add
la de upazila 2654"MOTIJHEEL", add
la de upazila 2662"NAWABGANJ (DHAKA)", add
la de upazila 2663"NEW MARKET", add
la de upazila 2664"PALLABI", add
la de upazila 2665"PALTAN", add
la de upazila 2666"RAMNA", add
la de upazila 2667"RAMPURA", add
la de upazila 2668"SABUJBAGH", add
la de upazila 2672"SAVAR", add
la de upazila 2674"SHAH ALI", add
la de upazila 2675"SHAHBAGH", add
la de upazila 2680"SHER-E-BANGLA NAGAR", add
la de upazila 2676"SHYAMPUR", add
la de upazila 2688"SUTRAPUR", add
la de upazila 2690"TEJGAON", add
la de upazila 2692"TEJGAON IND. AREA", add
la de upazila 2693"TURAG", add
la de upazila 2696"UTTAR KHAN", add
la de upazila 2695"UTTARA", add
la de upazila 2903"ALFADANGA", add
la de upazila 2910"BHANGA", add
la de upazila 2918"BOALMARI", add
la de upazila 2921"CHAR BHADRASAN", add
la de upazila 2947"FARIDPUR SADAR", add
la de upazila 2956"MADHUKHALI", add
la de upazila 2962"NAGARKANDA", add
la de upazila 2984"SADARPUR", add
la de upazila 2990"SALTHA", add
la de upazila 3330"GAZIPUR SADAR", add
la de upazila 3332"KALIAKAIR", add
la de upazila 3334"KALIGANJ (GAZIPUR)", add
la de upazila 3336"KAPASIA", add
la de upazila 3386"SREEPUR (GAZIPUR)", add
la de upazila 3532"GOPALGANJ SADAR", add
la de upazila 3543"KASHIANI", add
la de upazila 3551"KOTALIPARA", add
la de upazila 3558"MUKSUDPUR", add
la de upazila 3591"TUNGIPARA", add
la de upazila 3907"BAKSHIGANJ", add
la de upazila 3915"DEWANGANJ", add
la de upazila 3929"ISLAMPUR", add
la de upazila 3936"JAMALPUR SADAR", add
la de upazila 3958"MADARGANJ", add
la de upazila 3961"MELANDAHA", add
la de upazila 3985"SARISHABARI UPAZILA", add
la de upazila 4802"AUSTAGRAM", add
la de upazila 4806"BAJITPUR", add
la de upazila 4811"BHAIRAB", add
la de upazila 4827"HOSSAINPUR", add
la de upazila 4833"ITNA", add
la de upazila 4842"KARIMGANJ", add
la de upazila 4845"KATIADI", add
la de upazila 4849"KISHOREGANJ SADAR", add
la de upazila 4854"KULIAR CHAR", add
la de upazila 4859"MITHAMAIN", add
la de upazila 4876"NIKLI", add
la de upazila 4879"PAKUNDIA", add
la de upazila 4892"TARAIL", add
la de upazila 5440"KALKINI", add
la de upazila 5454"MADARIPUR SADAR", add
la de upazila 5480"RAJOIR", add
la de upazila 5487"SHIB CHAR", add
la de upazila 5610"DAULATPUR (MANIKGANJ)", add
la de upazila 5622"GHIOR", add
la de upazila 5628"HARIRAMPUR", add
la de upazila 5646"MANIKGANJ SADAR", add
la de upazila 5670"SATURIA", add
la de upazila 5678"SHIBALAYA", add
la de upazila 5682"SINGAIR", add
la de upazila 5924"GAZARIA", add
la de upazila 5944"LOHAJANG", add
la de upazila 5956"MUNSHIGANJ SADAR", add
la de upazila 5974"SERAJDIKHAN", add
la de upazila 5984"SREENAGAR", add
la de upazila 5994"TONGIBARI", add
la de upazila 6113"BHALUKA", add
la de upazila 6116"DHOBAURA", add
la de upazila 6120"FULBARIA", add
la de upazila 6122"GAFFARGAON", add
la de upazila 6123"GAURIPUR", add
la de upazila 6124"HALUAGHAT", add
la de upazila 6131"ISHWARGANJ", add
la de upazila 6165"MUKTAGACHHA", add
la de upazila 6152"MYMENSINGH SADAR", add
la de upazila 6172"NANDAIL", add
la de upazila 6181"PHULPUR", add
la de upazila 6194"TRISHAL", add
la de upazila 6702"ARAIHAZAR", add
la de upazila 6706"BANDAR", add
la de upazila 6758"NARAYANGANJ SADAR", add
la de upazila 6768"RUPGANJ", add
la de upazila 6704"SONARGAON", add
la de upazila 6807"BELABO", add
la de upazila 6852"MANOHARDI", add
la de upazila 6860"NARSINGDI SADAR", add
la de upazila 6863"PALASH", add
la de upazila 6864"ROYPURA", add
la de upazila 6876"SHIBPUR", add
la de upazila 7204"ATPARA", add
la de upazila 7209"BARHATTA", add
la de upazila 7218"DURGAPUR (NETRAKONA)", add
la de upazila 7240"KALMAKANDA", add
la de upazila 7247"KENDUA", add
la de upazila 7238"KHALIAJURI", add
la de upazila 7256"MADAN", add
la de upazila 7263"MOHANGANJ", add
la de upazila 7274"NETROKONA SADAR", add
la de upazila 7283"PURBADHALA", add
la de upazila 8207"BALIAKANDI", add
la de upazila 8229"GOALANDA", add
la de upazila 8247"KALUKHALI", add
la de upazila 8273"PANGSHA", add
la de upazila 8276"RAJBARI SADAR", add
la de upazila 8614"BHEDARGANJ", add
la de upazila 8625"DAMUDYA", add
la de upazila 8636"GOSAIRHAT", add
la de upazila 8665"NARIA", add
la de upazila 8669"SHARIATPUR SADAR", add
la de upazila 8694"ZANJIRA", add
la de upazila 8937"JHENAIGATI", add
la de upazila 8967"NAKLA", add
la de upazila 8970"NALITABARI", add
la de upazila 8988"SHERPUR SADAR", add
la de upazila 8990"SREEBARDI", add
la de upazila 9309"BASAIL", add
la de upazila 9319"BHUAPUR", add
la de upazila 9323"DELDUAR", add
la de upazila 9325"DHANBARI", add
la de upazila 9328"GHATAIL", add
la de upazila 9338"GOPALPUR", add
la de upazila 9347"KALIHATI", add
la de upazila 9357"MADHUPUR", add
la de upazila 9366"MIRZAPUR", add
la de upazila 9376"NAGARPUR", add
la de upazila 9385"SAKHIPUR", add
la de upazila 9395"TANGAIL SADAR", add
la de upazila 108 "BAGERHAT SADAR", add
la de upazila 114 "CHITALMARI", add
la de upazila 134 "FAKIRHAT", add
la de upazila 138 "KACHUA (BAGERHAT)", add
la de upazila 156 "MOLLAHAT", add
la de upazila 158 "MONGLA", add
la de upazila 160 "MORRELGANJ", add
la de upazila 173 "RAMPAL", add
la de upazila 177 "SARANKHOLA", add
la de upazila 1807"ALAMDANGA", add
la de upazila 1823"CHUADANGA SADAR", add
la de upazila 1831"DAMURHUDA", add
la de upazila 1855"JIBAN NAGAR", add
la de upazila 4104"ABHAYNAGAR", add
la de upazila 4109"BAGHER PARA", add
la de upazila 4111"CHAUGACHHA", add
la de upazila 4123"JHIKARGACHHA", add
la de upazila 4138"KESHABPUR", add
la de upazila 4147"JESSORE SADAR", add
la de upazila 4161"MANIRAMPUR", add
la de upazila 4190"SHARSHA", add
la de upazila 4414"HARINAKUNDA", add
la de upazila 4419"JHENAIDAH SADAR", add
la de upazila 4433"KALIGANJ (JHENAIDAH)", add
la de upazila 4442"KOTCHANDPUR", add
la de upazila 4471"MAHESHPUR", add
la de upazila 4480"SHAILKUPA", add
la de upazila 4712"BATIAGHATA", add
la de upazila 4717"DACOPE", add
la de upazila 4721"DAULATPUR", add
la de upazila 4740"DIGHALIA", add
la de upazila 4730"DUMURIA", add
la de upazila 4745"KHALISHPUR", add
la de upazila 4748"KHAN JAHAN ALI", add
la de upazila 4751"KHULNA SADAR", add
la de upazila 4753"KOYRA", add
la de upazila 4764"PAIKGACHHA", add
la de upazila 4769"PHULTALA", add
la de upazila 4775"RUPSA", add
la de upazila 4785"SONADANGA", add
la de upazila 4794"TEROKHADA", add
la de upazila 5015"BHERAMARA", add
la de upazila 5039"DAULATPUR (KUSHTIA)", add
la de upazila 5063"KHOKSA", add
la de upazila 5071"KUMARKHALI", add
la de upazila 5079"KUSHTIA SADAR", add
la de upazila 5094"MIRPUR (KUSHTIA)", add
la de upazila 5557"MAGURA SADAR", add
la de upazila 5566"MOHAMMADPUR (MAGURA)", add
la de upazila 5585"SHALIKHA", add
la de upazila 5595"SREEPUR (MAGURA)", add
la de upazila 5747"GANGNI", add
la de upazila 5787"MEHERPUR SADAR", add
la de upazila 5760"MUJIB NAGAR", add
la de upazila 6528"KALIA", add
la de upazila 6552"LOHAGARA (NARAIL)", add
la de upazila 6576"NARAIL SADAR", add
la de upazila 8704"ASSASUNI", add
la de upazila 8725"DEBHATA", add
la de upazila 8743"KALAROA", add
la de upazila 8747"KALIGANJ (SATKHIRA)", add
la de upazila 8782"SATKHIRA SADAR", add
la de upazila 8786"SHYAMNAGAR", add
la de upazila 8790"TALA", add
la de upazila 1006"ADAMDIGHI", add
la de upazila 1020"BOGRA SADAR", add
la de upazila 1027"DHUNAT", add
la de upazila 1033"DHUPCHANCHIA", add
la de upazila 1040"GABTALI", add
la de upazila 1054"KAHALOO", add
la de upazila 1067"NANDIGRAM", add
la de upazila 1081"SARIAKANDI", add
la de upazila 1085"SHAJAHANPUR", add
la de upazila 1088"SHERPUR", add
la de upazila 1094"SHIBGANJ (BOGRA)", add
la de upazila 1095"SONATOLA", add
la de upazila 3813"AKKELPUR", add
la de upazila 3847"JOYPURHAT SADAR", add
la de upazila 3858"KALAI", add
la de upazila 3861"KHETLAL", add
la de upazila 3874"PANCHBIBI", add
la de upazila 6403"ATRAI", add
la de upazila 6406"BADALGACHHI", add
la de upazila 6428"DHAMOIRHAT", add
la de upazila 6450"MAHADEBPUR", add
la de upazila 6447"MANDA", add
la de upazila 6460"NAOGAON SADAR", add
la de upazila 6469"NIAMATPUR", add
la de upazila 6475"PATNITALA", add
la de upazila 6479"PORSHA", add
la de upazila 6485"RANINAGAR", add
la de upazila 6486"SAPAHAR", add
la de upazila 6909"BAGATIPARA", add
la de upazila 6915"BARAIGRAM", add
la de upazila 6941"GURUDASPUR", add
la de upazila 6944"LALPUR", add
la de upazila 6963"NATORE SADAR", add
la de upazila 6991"SINGRA", add
la de upazila 7018"BHOLAHAT", add
la de upazila 7037"GOMASTAPUR", add
la de upazila 7056"NACHOLE", add
la de upazila 7066"CHAPAI NABABGANJ SADAR", add
la de upazila 7088"SHIBGANJ (CHAPAI NABABGANJ)", add
la de upazila 7605"ATGHARIA", add
la de upazila 7616"BERA", add
la de upazila 7619"BHANGURA", add
la de upazila 7622"CHATMOHAR", add
la de upazila 7633"FARIDPUR", add
la de upazila 7639"ISHWARDI", add
la de upazila 7655"PABNA SADAR", add
la de upazila 7672"SANTHIA", add
la de upazila 7683"SUJANAGAR", add
la de upazila 8110"BAGHA", add
la de upazila 8112"BAGHMARA", add
la de upazila 8122"BOALIA", add
la de upazila 8125"CHARGHAT", add
la de upazila 8131"DURGAPUR (RAJSHAHI)", add
la de upazila 8134"GODAGARI", add
la de upazila 8140"MATIHAR", add
la de upazila 8153"MOHANPUR", add
la de upazila 8172"PABA", add
la de upazila 8182"PUTHIA", add
la de upazila 8185"RAJPARA", add
la de upazila 8190"SHAH MAKHDUM", add
la de upazila 8194"TANORE", add
la de upazila 8811"BELKUCHI", add
la de upazila 8827"CHAUHALI", add
la de upazila 8844"KAMARKHANDA", add
la de upazila 8850"KAZIPUR", add
la de upazila 8861"ROYGANJ", add
la de upazila 8867"SHAHJADPUR", add
la de upazila 8878"SIRAJGANJ SADAR", add
la de upazila 8889"TARASH", add
la de upazila 8894"ULLAH PARA", add
la de upazila 2717"BIRAL", add
la de upazila 2710"BIRAMPUR", add
la de upazila 2712"BIRGANJ", add
la de upazila 2721"BOCHAGANJ", add
la de upazila 2730"CHIRIRBANDAR", add
la de upazila 2764"DINAJPUR SADAR", add
la de upazila 2738"FULBARI", add
la de upazila 2743"GHORAGHAT", add
la de upazila 2747"HAKIMPUR", add
la de upazila 2756"KAHAROLE", add
la de upazila 2760"KHANSAMA", add
la de upazila 2769"NAWABGANJ (DINAJPUR)", add
la de upazila 2777"PARBATIPUR", add
la de upazila 3221"FULCHHARI", add
la de upazila 3224"GAIBANDHA SADAR", add
la de upazila 3230"GOBINDAGANJ", add
la de upazila 3267"PALASHBARI", add
la de upazila 3282"SADULLAPUR", add
la de upazila 3288"SAGHATA", add
la de upazila 3291"SUNDARGANJ", add
la de upazila 4906"BHURUNGAMARI", add
la de upazila 4908"CHAR RAJIBPUR", add
la de upazila 4909"CHILMARI", add
la de upazila 4952"KURIGRAM SADAR", add
la de upazila 4961"NAGESHWARI", add
la de upazila 4918"PHULBARI", add
la de upazila 4977"RAJARHAT", add
la de upazila 4979"RAUMARI", add
la de upazila 4994"ULIPUR", add
la de upazila 5202"ADITMARI", add
la de upazila 5233"HATIBANDHA", add
la de upazila 5239"KALIGANJ (LALMONIRHAT)", add
la de upazila 5255"LALMONIRHAT SADAR", add
la de upazila 5270"PATGRAM", add
la de upazila 7312"DIMLA", add
la de upazila 7315"DOMAR", add
la de upazila 7336"JALDHAKA", add
la de upazila 7345"KISHOREGANJ", add
la de upazila 7364"NILPHAMARI SADAR", add
la de upazila 7385"SAIDPUR", add
la de upazila 7704"ATWARI", add
la de upazila 7734"DEBIGANJ", add
la de upazila 7790"TENTULIA", add
la de upazila 8503"BADARGANJ", add
la de upazila 8527"GANGACHARA", add
la de upazila 8542"KAUNIA", add
la de upazila 8558"MITHA PUKUR", add
la de upazila 8573"PIRGACHHA", add
la de upazila 8576"PIRGANJ (RANGPUR)", add
la de upazila 8549"RANGPUR SADAR", add
la de upazila 8592"TARAGANJ", add
la de upazila 9408"BALIADANGI", add
la de upazila 9451"HARIPUR", add
la de upazila 9482"PIRGANJ (THAKURGAON)", add
la de upazila 9486"RANISANKAIL", add
la de upazila 9494"THAKURGAON SADAR", add
la de upazila 3602"AJMIRIGANJ", add
la de upazila 3605"BAHUBAL", add
la de upazila 3611"BANIACHONG", add
la de upazila 3626"CHUNARUGHAT", add
la de upazila 3644"HABIGANJ SADAR", add
la de upazila 3668"LAKHAI", add
la de upazila 3671"MADHABPUR", add
la de upazila 3677"NABIGANJ", add
la de upazila 5814"BARLEKHA", add
la de upazila 5835"JURI", add
la de upazila 5856"KAMALGANJ", add
la de upazila 5865"KULAURA", add
la de upazila 5874"MAULVIBAZAR SADAR", add
la de upazila 5880"RAJNAGAR", add
la de upazila 5883"SREEMANGAL", add
la de upazila 9018"BISHWAMBARPUR", add
la de upazila 9023"CHHATAK", add
la de upazila 9027"DAKSHIN SUNAMGANJ", add
la de upazila 9029"DERAI", add
la de upazila 9032"DHARAMPASHA", add
la de upazila 9033"DOWARABAZAR", add
la de upazila 9047"JAGANNATHPUR", add
la de upazila 9050"JAMALGANJ", add
la de upazila 9086"SULLA", add
la de upazila 9089"SUNAMGANJ SADAR", add
la de upazila 9092"TAHIRPUR", add
la de upazila 9108"BALAGANJ", add
la de upazila 9117"BEANI BAZAR", add
la de upazila 9120"BISHWANATH", add
la de upazila 9127"COMPANIGANJ (SYLHET)", add
la de upazila 9131"DAKSHIN SURMA", add
la de upazila 9135"FENCHUGANJ", add
la de upazila 9138"GOLAPGANJ", add
la de upazila 9141"GOWAINGHAT", add
la de upazila 9153"JAINTIAPUR", add
la de upazila 9159"KANAIGHAT", add
la de upazila 9162"SYLHET SADAR", add
la de upazila 9194"ZAKIGANJ", add
la de upazila 7725"BODA", add
la de upazila 7773"PANCHAGARH SADAR", add
la val upazila upazila

gen upazila_code=upazila
label var upazila_code "Upazila/Thana code"

la var quarter_16 "Quarter 2016"

save `file', replace
}  

*/
/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE INDIVIDUAL DATABASE
*                                                                                                    *
*****************************************************************************************************/

use individual, clear

gen     indid=indid_00 if year==2000
replace indid=indid_05 if year==2005
replace indid=indid_10 if year==2010
replace indid=indid_16 if year==2016
la var  indid "individual id"

*************************HOUSEHOLD INFORMATION ROSTER***************************




gen roster_a_2= s1a_q2_00_r if year==2000
replace roster_a_2= s1a_q2_05_r if year==2005
replace roster_a_2= s1a_q2_10_r if year==2010
replace roster_a_2= s1a_q1_16_r if year==2016
label var roster_a_2 "Sex"
la de roster_a_2 1 "Male" 2 "Female"
label values roster_a_2 roster_a_2

gen roster_a_3= s1a_q3_00_r if year==2000
replace roster_a_3= s1a_q3_05_r if year==2005
replace roster_a_3= s1a_q3_10_r if year==2010
replace roster_a_3= s1a_q2_16_r if year==2016
replace roster_a_3=. if roster_a_3==0
label var roster_a_3 "Relationship with the head of the household"
la de roster_a_3 1"Head" 2"Husband/wife" 3"Son/Daughter" 4"Spouse of Son/Daughter" 5"Grandchild"   ///
6"Father/Mother" 7"Brother/Sister" 8"Niece/Nephew" 9"Father/Mother in law"  10"Brother/Sister in law" ///
11"Other relative" 12"Servant" 13"Employee" 14"Other"
label values roster_a_3 roster_a_3

gen roster_a_4= s1a_q4_00_r if year==2000
replace roster_a_4= s1a_q4_05_r if year==2005
replace roster_a_4= s1a_q4_10_r if year==2010
replace roster_a_4= s1a_q3_16_r if year==2016
label var roster_a_4 "Individual age"

gen roster_a_5= s1a_q5_00_r if year==2000
replace roster_a_5= s1a_q5_05_r if year==2005
replace roster_a_5= s1a_q5_10_r if year==2010
replace roster_a_5= s1a_q4_16_r if year==2016
label var roster_a_5 "Religion"
la de roster_a_5 1 "Islam" 2 "Hinduism" 3 "Buddhism" 4 "Christianity" 5 "Other"
label values roster_a_5 roster_a_5

gen roster_a_6a= s1a_q6_00_r if year==2000
replace roster_a_6a= s1a_q6_05_r if year==2005
replace roster_a_6a= s1a_q6_10_r if year==2010
replace roster_a_6a= s1a_q5_16_r if year==2016
replace roster_a_6a=. if inlist(roster_a_6a,0,8)
label var roster_a_6a "Marital status"
la de roster_a_6a 1 "Currently Married" 2 "Never Married" 3 "Widowed" 4 "Divorced" 5"separated"
label values roster_a_6a roster_a_6a

gen roster_a_6b=s1a_q6_16_r if year==2016
la var roster_a_6b "Age at 1st marriage"
note roster_a_6b:Question only available for year 2016

/*question 7:earner. In 2005 is an individual id, and in 2010, 2016 is a yes/no question.
 In this harmonization becomes a yes/no question. There is not information for year 2000.*/
gen roster_a_7= .
replace roster_a_7=1 if s1a_q7_05_r!=. & year==2005
replace roster_a_7=2 if s1a_q7_05_r==. & year==2005
replace roster_a_7=s1a_q7_10_r if year==2010
replace roster_a_7=s1a_q7_16_r if  year==2016
replace roster_a_7=. if roster_a_7==0
label var roster_a_7 "Earner Yes/no"
la de roster_a_7 1 "Yes" 2 "No"
label values roster_a_7 roster_a_7
note roster_a_7: question 7:earner. In 2005 is an individual id, and in 2010, 2016 is  ///
a yes/no question. In this harmonization becomes a yes/no question

gen roster_a_8= s1a_q7_00_r if year==2000
replace roster_a_8= s1a_q8_05_r if year==2005
replace roster_a_8= s1a_q8_10_r if year==2010
label var roster_a_8 "Spouse id"
note roster_a_8: Question not available for 2016

gen roster_a_9= s1a_q8_00_r if year==2000
replace roster_a_9= s1a_q9_05_r if year==2005
replace roster_a_9=. if s1a_q9_05_r==69 & year==2005
replace roster_a_9= s1a_q9_10_r if year==2010
label var roster_a_9 "Father id"
note roster_a_9: Question not available for 2016

gen roster_a_10= s1a_q9_00_r if year==2000
replace roster_a_10= s1a_q10_05_r if year==2005
replace roster_a_10=. if s1a_q10_05_r==93 & year==2005
replace roster_a_10= s1a_q10_10_r if year==2010
replace roster_a_10=. if s1a_q10_10_r==0 & year==2010
label var roster_a_10 "Mother id"
note roster_a_10: Question not available for 2016

gen roster_a_11= s1a_q11_10_r if year==2010
replace roster_a_11= s1a_q8_16_r if year==2016
replace roster_a_11=. if inlist(roster_a_11,0,5)
label var roster_a_11 "Lived abroad more than 6 months during last 5 years?"
la de roster_a_11 1"Yes" 2 "No"
label values roster_a_11 roster_a_11

gen roster_a_12= s1a_q12_10_r if year==2010
replace roster_a_12=. if s1a_q12_10_r==0 & year==2010
replace roster_a_12=s1a_q9_16_r if year==2016
replace roster_a_12=. if roster_a_12==0
label var roster_a_12 "Why did return?"
la de roster_a_12 1"Lose job" 2"Due to illness" 3"End of employment contract" 4"Disagreement with authorities"  ///
5"Homesick" 6"Due to Economic Recession" 7"Other"
label values roster_a_12 roster_a_12

gen roster_a_13=s1a_q10_16_r if year==2016
la var roster_a_13 "Whether (name) has a mobile?"
la de roster_a_13 1 "Yes" 2"No"
la val roster_a_13 roster_a_13

gen roster_a_14=s1a_q11_16_r if year==2016
la var roster_a_14  "Main use of the mobile"
la de roster_a_14 1"Communicating", add
la de roster_a_14 2 "Getting information related to work", add
la de roster_a_14 3 "Transferring money", add
la de roster_a_14 4 "Accessing the internet", add
la val roster_a_14 roster_a_14

gen roster_a_15= s1a_q12_16_r if year==2016
la var roster_a_15 "Does (name) have difficulty for seeing, even if he/she is wearing glasses?"
la de roster_a_15 1 "No Difficulty", add
la de roster_a_15 2 "Yes, Some Difficulty", add
la de roster_a_15 3 "Yes, Severe Difficulty", add
la de roster_a_15 4 "Yes, Can't see", add
la val roster_a_15 roster_a_15

gen roster_a_16=s1a_q13_16_r if year==2016
replace roster_a_16=. if roster_a_16==5
la var roster_a_16 "Does (name) have difficulty hearing, even if he/she is wearing a hearing aid?"
la de roster_a_16 1 "No Difficulty", add
la de roster_a_16 2 "Yes, Some Difficulty", add
la de roster_a_16 3 "Yes, Severe Difficulty", add
la de roster_a_16 4 "Yes, Can't hear", add
la val roster_a_16 roster_a_16

gen roster_a_17=s1a_q14_16_r if year==2016
la var roster_a_17 "Does (name) have difficulty for walking or climbing or any other physical movement?"
la de roster_a_17 1 "No Difficulty", add
la de roster_a_17 2 "Yes, Some Difficulty", add
la de roster_a_17 3 "Yes, Severe Difficulty", add
la de roster_a_17 4 "Yes, Can't walk", add
la val roster_a_17 roster_a_17

gen roster_a_18=s1a_q15_16_r if year==2016
la var roster_a_18 "Does (name) have difficulty remembering or concentrating?"
la de roster_a_18 1 "No Difficulty", add
la de roster_a_18 2 "Yes, Some Difficulty", add
la de roster_a_18 3 "Yes, Severe Difficulty", add
la de roster_a_18 4 "Yes, Can't remember", add
la val roster_a_18 roster_a_18

gen roster_a_19=s1a_q16_16_r if year==2016
la var roster_a_19 "Does (name) have difficulty with self care?"
la de roster_a_19 1 "No Difficulty", add
la de roster_a_19 2 "Yes, Some Difficulty", add
la de roster_a_19 3 "Yes, Severe Difficulty", add
la de roster_a_19 4 "Yes, Can't selfcare", add
la val roster_a_19 roster_a_19

gen roster_a_20=s1a_q17_16_r if year==2016
la var roster_a_20 "Does (name) have difficulty communicating?"
la de roster_a_20 1 "No Difficulty", add
la de roster_a_20 2 "Yes, Some Difficulty", add
la de roster_a_20 3 "Yes, Severe Difficulty", add
la de roster_a_20 4 "Yes, Can't communicate at all", add
la val roster_a_20 roster_a_20

gen roster_b_1= s1b_q1_00_r if year==2000
replace roster_b_1= s1b_q1_05_r if year==2005
replace roster_b_1= s1b_q1_10_r if year==2010
replace roster_b_1=s1b_q1_16_r if year==2016
replace roster_b_1=. if roster_b_1==0
label var roster_b_1 "Did work for livelihood during last 7 days?"
la de roster_b_1 1 "Yes" 2 "No"
label values roster_b_1 roster_b_1

gen roster_b_2= s1b_q2_00_r if year==2000
replace roster_b_2= s1b_q2_05_r if year==2005
replace roster_b_2= s1b_q2_10_r if year==2010
replace roster_b_2=s1b_q2_16_r if year==2016
replace roster_b_2=. if inlist(roster_b_2,0,5)
label var roster_b_2 "Were you avaible for work during last 7 days?"
la de lroster_b_2 1 "Yes" 2 "No"
label values roster_b_2 lroster_b_2

gen roster_b_3= s1b_q3_00_r if year==2000
replace roster_b_3= s1b_q3_05_r if year==2005
replace roster_b_3= s1b_q3_10_r if year==2010
replace roster_b_3=s1b_q3_16_r if year==2016
replace roster_b_3=. if roster_b_3==0
label var roster_b_3 "Did you look for work during last 7 days?"
la de roster_b_3 1 "Yes" 2 "No"
label values roster_b_3 roster_b_3

*Option 10:On leave/looking for job/business only appears in 2010 and 2016
gen roster_b_4= s1b_q4_00_r if year==2000
replace roster_b_4=11 if s1b_q4_00_r==10 & year==2000
replace roster_b_4= s1b_q4_05_r if year==2005
replace roster_b_4=11 if s1b_q4_05_r==10 & year==2005
replace roster_b_4= s1b_q4_10_r if year==2010
replace roster_b_4=s1b_q4_16_r if year==2016
replace roster_b_4=. if inlist(roster_b_4,0,14,25)
label var roster_b_4 "Reason for not looking for work"
la de roster_b_4 01"Engaged in domestic work" 02"Housewife" 03"Student" 04"Too old/ retired" 05"Too young" ///
06 "Temporarily sick" 07"Disabled" 08"Waiting to start new job" 09"No work available" 10"On leave/looking for job/business" 11"Other"
label values roster_b_4 roster_b_4
note roster_b_4: Option 10:On leave/looking for job/business only appears in 2010 and 2016

************************************EDUCATION***********************************

*Question only avaiable for years 2010, 2016
gen educ_a_1=resid2a_10 
replace educ_a_1=s2a_qa_16_r if year==2016
replace educ_a_1=. if educ_a_1==0
label var educ_a_1 "Respondent identification code section Education Part A"
note educ_a_1:Question only available for years 2010, 2016

gen educ_a_2=s3a_q1_00_r if year==2000
replace educ_a_2= s3a_q1_05_r if year==2005
replace educ_a_2= s2a_q3_10_r if year==2010
replace educ_a_2= s2a_q1_16_r if year==2016
replace educ_a_2=. if educ_a_2==0
label var educ_a_2 "Can you read a letter?"
la de educ_a_2 1 "Yes" 2 "No"
label val educ_a_2 educ_a_2

gen educ_a_3=s3a_q2_00_r if year==2000
replace educ_a_3= s3a_q2_05_r if year==2005
replace educ_a_3= s2a_q4_10_r if year==2010
replace educ_a_3= s2a_q2_16_r if year==2016
replace educ_a_3=. if inlist(educ_a_3,0,4,7)
label var educ_a_3 "Can you write a letter?"
la de educ_a_3 1 "Yes" 2 "No"
la val educ_a_3 educ_a_3

*Question only available for year 2016
gen educ_a_4=s2a_q3_16_r if year==2016
replace educ_a_4=. if inlist(s2a_q3_16_r,0,3,4,7)
la var educ_a_4 "Have you ever attended education?"
la de educ_a_4  1 "Yes" 2 "No"
la val educ_a_4 educ_a_4
note educ_a_4: Question only available for year 2016

*Some options in this question are different in year 2000, information for 2000 is not used

*2005 (option other in in 16 instead of 19)
gen educ_a_5= s3a_q3_05_r if year==2005
replace educ_a_5=19 if s3a_q3_05_r==16& year==2005
*2000 (they separate in years in high school or college, so we consolidate them) 
replace educ_a_5=s3a_q4_00_r if s3a_q4_00_r<=10 & s3a_q4_00_r!=. & year==2000
replace educ_a_5=10 if s3a_q4_00_r==11 & year==2000
replace educ_a_5=11 if inrange(s3a_q4_00_r,12,14) & year==2000
replace educ_a_5=12 if s3a_q4_00_r==15 & year==2000
replace educ_a_5=13 if inlist(s3a_q4_00_r,16,17) & year==2000
*2010 one observation had 50 
replace educ_a_5= s2a_q5_10_r if year==2010
replace educ_a_5=. if s2a_q5_10_r==50 & year==2010
*2016 chance the coding of the levels of eduction. starting at 12 see questionnaire for details

forval i=0/11 {
replace educ_a_5=`i' if  s2a_q4_16_r==`i' & year==2016
}
replace educ_a_5=12 if  s2a_q4_16_r==15 & year==2016
replace educ_a_5=13 if  s2a_q4_16_r==18 & year==2016
replace educ_a_5=14 if  s2a_q4_16_r==16 & year==2016
replace educ_a_5=15 if  s2a_q4_16_r==17 & year==2016
replace educ_a_5=16 if  s2a_q4_16_r==12 & year==2016
replace educ_a_5=17 if  s2a_q4_16_r==14 & year==2016
replace educ_a_5=18 if  s2a_q4_16_r==13 & year==2016
replace educ_a_5=19 if  s2a_q4_16_r==19 & year==2016
*correction if you never attended school (just for 2016)
replace educ_a_5=0  if  educ_a_4==2
*correction if you learn how to write and write outside the Formal schooling frame (just for 2000)
replace educ_a_5=0 if  inrange(s3a_q3_00_r,2,5)
*correction if you do not know how to read or write
replace educ_a_5=0  if  educ_a_3==2 | educ_a_2==2
label var educ_a_5 "Highest class completed"
la de educ_a_5 0"No class passed" 1"Class 1" 2"Class 2" 3"Class 3" 4"Class 4" 5"Class 5" 6"Class 6" ///
7"Class 7" 8"Class 8" 9"Class 9" 10"SSC/equivalent" 11"HSC/equivalent" 12"Graduate/equivalent" 13"Post graduate/equivalent" ///
14"Medical" 15"Engineering"16"Vocational" 17"Technical Education" 18"Nursing" 19"Other"
label values educ_a_5 educ_a_5
note educ_a_5: Some options in this question are different in year 2000

*********************new variable 


* Years of education (We assume the minimum number of years of each category)
*12 years if high school, 14 for nursing  vocational and technical education
*16 for graduate equivalent medical and engineering
*17 for Post graduate 
gen years_educ=0 if  educ_a_5==0 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=1 if  educ_a_5==1 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=2 if  educ_a_5==2 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=3 if  educ_a_5==3 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=4 if  educ_a_5==4 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=5 if  educ_a_5==5 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=6 if  educ_a_5==6 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=7 if  educ_a_5==7 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=8 if  educ_a_5==8 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=9 if  educ_a_5==9 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=10 if  educ_a_5==10 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=12 if  educ_a_5==11 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=14 if  inrange(educ_a_5,16,18) & roster_a_4>=18 & roster_a_4!=.
replace years_educ=16 if  inrange(educ_a_5,14,15) & roster_a_4>=18 & roster_a_4!=.
replace years_educ=16 if  educ_a_5==12 & roster_a_4>=18 & roster_a_4!=.
replace years_educ=17 if  educ_a_5==13 & roster_a_4>=18 & roster_a_4!=.
la var years_educ "Years of education, population aged 18+"
note years_educ: 12 years for high school, 14 for nursing, vocational and technical education 16 for graduate equivalent medical and engineering 17 for Post graduate 


************************************************************

/*For year 2000 there are only three options: Formal school, Taught by family, Govt. literacy course 
NGO literacy course and Other  */
gen educ_a_6=s3a_q3_00_r if year==2000
replace educ_a_6=5 if s3a_q3_00_r==2& year==2000
replace educ_a_6=6 if s3a_q3_00_r==3& year==2000
replace educ_a_6=8 if s3a_q3_00_r==4& year==2000
replace educ_a_6= s3a_q4_05_r if year==2005
replace educ_a_6=. if s3a_q4_05_r==0 & year==2005
replace educ_a_6= s2a_q6_10_r if year==2010
replace educ_a_6=. if s2a_q6_10_r==0 & year==2010
forval i=1/4 {
replace educ_a_6=`i' if  s2a_q5_16_r==`i'
}
replace educ_a_6=6 if  s2a_q5_16_r==5
replace educ_a_6=7 if  s2a_q5_16_r==6
replace educ_a_6=8 if  s2a_q5_16_r==7
replace educ_a_6=. if  s2a_q5_16_r==0 & year==2016
label var educ_a_6 "where attended/attending?"
la de educ_a_6 1"Formal School" 2"Formal College" 3"Formal University" 4"Madrasha" 5"Taught by family" ///
6"Govt. informal literacy programme" 7"NGO literacy course" 8"Other"
label values educ_a_6 educ_a_6
note educ_a_6:For year 2000 there are only five options: Formal school, Taught by family, Govt. literacy course, ///
NGO literacy course and Other 

/*Some options in this question are different in year 2000, information for 2000 is not used*/
gen educ_a_7= s3a_q5_05_r if year==2005
replace educ_a_7=. if s3a_q5_05_r==0 & year==2005
replace educ_a_7=s2a_q7_10_r if year==2010
replace educ_a_7=. if s2a_q7_10_r==0 & year==2010
replace educ_a_7=s2a_q6_16_r if year==2016
replace educ_a_7=. if s2a_q6_16_r==0 & year==2016
label var educ_a_7 "What type of school attended/attending?"
la de educ_a_7 1"Government" 2"Private(Govt. grants)" 3"Private (Not govt. grants)" 4"NGO run institution"  ///
5"Madrasa (Govt. affiliated)" 6"Madrasa (Kowmi)"
label values educ_a_7 educ_a_7
note educ_a_7:Some options in this question are different in year 2000, information for 2000 is not used

gen educ_b1_1=s3b_q1_00_r if year==2000
replace educ_b1_1= s3b1_q1_05_r if year==2005
replace educ_b1_1= s2b_q1_10_r if year==2010
replace educ_b1_1= s2b_q1_16_r if year==2016
replace educ_b1_1=. if inlist(educ_b1_1,0,4,5,6,7,9)
label var educ_b1_1 "Are you currently attending education institution?"
la de educ_b1_1 1 "Yes" 2 "No"
label values educ_b1_1 educ_b1_1

*Some options in this question are different in year 2000, information for 2000 is not used
gen educ_b1_2=s3b1_q2_05_r if year==2005
replace educ_b1_2=19 if s3b1_q2_05_r==16 & year==2005
replace educ_b1_2= s2b_q2_10_r if year==2010
forval i=0/11 {
replace educ_b1_2=`i' if  s2b_q3_16_r==`i'
}
replace educ_b1_2=12 if  s2b_q3_16_r==15
replace educ_b1_2=13 if  s2b_q3_16_r==18
replace educ_b1_2=14 if  s2b_q3_16_r==16
replace educ_b1_2=15 if  s2b_q3_16_r==17
replace educ_b1_2=16 if  s2b_q3_16_r==12
replace educ_b1_2=17 if  s2b_q3_16_r==14
replace educ_b1_2=18 if  s2b_q3_16_r==13
replace educ_b1_2=19 if  s2b_q3_16_r==19
la var educ_b1_2 "What class are you currently attending?"
la de educ_b1_2 0"No class passed/pre-schooling" 1"Class 1" 2"Class 2" 3"Class 3" 4"Class 4" 5"Class 5" 6"Class 6" ///
7"Class 7" 8"Class 8" 9"Class 9" 10"SSC/equivalent" 11"HSC/equivalent" 12"Graduate/equivalent" 13"Post graduate/equivalent" ///
14"Medical" 15"Engineering"16"Vocational" 17"Technical Education" 18"Nursing" 19"Other"
label values educ_b1_2 educ_b1_2
note educ_b1_2:Some options in this question are different in year 2000, information for 2000 is not used

*Questions 3 to 7 only available in 2010
gen educ_b1_3=s2b_q3_10_r if year==2010
replace educ_b1_3=. if s2b_q3_10_r==0 & year==2010
label var educ_b1_3 "Are you receiving stipend for primary?"
la de educ_b1_3 1 "Yes" 2 "No"
label values educ_b1_3 educ_b1_3
note educ_b1_3: Question only available for year 2010

gen educ_b1_4=s2b_q4_10_r if year==2010
replace educ_b1_4=. if s2b_q4_10_r==0 & s2b_q3_10_r!=2 & year==2010
label var educ_b1_4 "how much did you receive in the past 12 months?"
note educ_b1_4: Question only available for year 2010

gen educ_b1_5=s2b_q5_10_r if year==2010
replace educ_b1_5=. if s2b_q5_10_r==0 & year==2010
label var educ_b1_5 "Are you receiving stipend for secondary?"
la de educ_b1_5 1 "Yes" 2 "No"
label values educ_b1_5 educ_b1_5
note educ_b1_5: Question only available for year 2010

gen educ_b1_6=s2b_q6_10_r if year==2010
replace educ_b1_6=. if s2b_q6_10_r==0 & s2b_q5_10_r!=2 & year==2010
label var educ_b1_6 "how much did you receive in the past 12 months? (Secondary)"
note educ_b1_6: Question only available for year 2010

gen educ_b1_7=s2b_q7_10_r if year==2010
replace educ_b1_7=. if s2b_q7_10_r==0 & year==2010
label var educ_b1_7 "do you benefit from the tuition waiver? (Secondary)"
la de educ_b1_7 1"Yes" 2 "No"
label values educ_b1_7 educ_b1_7
note educ_b1_7: Question only available for year 2010

gen educ_b2_8a= s3b_q8a_00_r if  year==2000
replace educ_b2_8a=s3b2_q8a_05_r if year==2005
replace educ_b2_8a=s2b_q8_10_r   if year==2010
replace educ_b2_8a=s2b_q8a_16_r  if year==2016
label var educ_b2_8a "Amount spent on admission fee"

gen educ_b2_8b= s3b_q8b_00_r if year==2000
replace educ_b2_8b=s3b2_q8b_05_r if year==2005
replace educ_b2_8b=s2b_q_1_10_r if year==2010
replace educ_b2_8b=s2b_q8b_16_r if year==2016
label var educ_b2_8b "Amount spent on annual session fee"

gen educ_b2_8c= s3b_q8c_00_r if year==2000
replace educ_b2_8c=s3b2_q8c_05_r if year==2005
replace educ_b2_8c=s2b_q_2_10_r if year==2010
replace educ_b2_8c=s2b_q8d_16_r if year==2016
label var educ_b2_8c "Amount spent on registration fee"

gen educ_b2_8d= s3b_q8d_00_r if year==2000
replace educ_b2_8d=s3b2_q8d_05_r if year==2005
replace educ_b2_8d=s2b_q_3_10_r if year==2010
replace educ_b2_8d=s2b_q8e_16_r if year==2016
label var educ_b2_8d "Amount spent on examination fee"

gen educ_b2_8e= s3b_q8e_00_r if year==2000
replace educ_b2_8e=s3b2_q8e_05_r if year==2005
replace educ_b2_8e=s2b_q_4_10_r if year==2010
replace educ_b2_8e=s2b_q8f_16_r if year==2016
label var educ_b2_8e "Amount spent on tuituion fee"

gen educ_b2_8f= s3b_q8f_00_r if year==2000
replace educ_b2_8f=s3b2_q8f_05_r if year==2005
replace educ_b2_8f=s2b_q_5_10_r if year==2010
replace educ_b2_8f=s2b_q8g_16_r if year==2016
label var educ_b2_8f "Amount spent on text books, note books"

gen educ_b2_8g= s3b_q8g_00_r if year==2000
replace educ_b2_8g=s3b2_q8g_05_r if year==2005
replace educ_b2_8g=s2b_q_6_10_r if year==2010
replace educ_b2_8g=s2b_q8h_16_r if year==2016
label var educ_b2_8g "Amount spent on exercise books, stationary"

gen educ_b2_8h= s3b_q8h_00_r if year==2000
replace educ_b2_8h=s3b2_q8h_05_r if year==2005
replace educ_b2_8h=s2b_q_7_10_r if year==2010
replace educ_b2_8h=s2b_q8i_16_r if year==2016
label var educ_b2_8h "Amount spent on uniform dress, footwear"

gen educ_b2_8i= s3b_q8i_00_r if year==2000
replace educ_b2_8i=s3b2_q8i_05_r if year==2005
replace educ_b2_8i=s2b_q_8_10_r if year==2010
replace educ_b2_8i=s2b_q8j_16_r if year==2016
label var educ_b2_8i "Amount spent on private tutoring"

gen educ_b2_8j= s3b_q8j_00_r if year==2000
replace educ_b2_8j=s3b2_q8j_05_r if year==2005
replace educ_b2_8j=s2b_q_9_10_r if year==2010
replace educ_b2_8j=s2b_q8l_16_r if year==2016
label var educ_b2_8j "Amount spent on hostel (incl food)"

gen educ_b2_8k= s3b_q8k_00_r if year==2000
replace educ_b2_8k=s3b2_q8k_05_r if year==2005
replace educ_b2_8k=s2b__10_10_r if year==2010
replace educ_b2_8k=s2b_q8m_16_r if year==2016
label var educ_b2_8k "Amount spent on transport"

gen educ_b2_8l= s3b_q8l_00_r if year==2000
replace educ_b2_8l=s3b2_q8l_05_r if year==2005
replace educ_b2_8l=s2b__11_10_r if year==2010
replace educ_b2_8l=s2b_q8n_16_r if year==2016
label var educ_b2_8l "Amount spent on tiffin"

gen educ_b2_8m= s2b__12_10_r if year==2010
replace educ_b2_8m=s2b_q8o_16_r if year==2016
label var educ_b2_8m "Amount spent on internet/e-mail"

gen educ_b2_8n= s3b_q8m_00_r if year==2000
replace educ_b2_8n=s3b2_q8m_05_r if year==2005
replace educ_b2_8n=s2b__13_10_r if year==2010
replace educ_b2_8n=s2b_q8c_16_r if year==2016
label var educ_b2_8n "Amount spent on schooling donation"

gen educ_b2_8o= s3b_q8n_00_r if year==2000
replace educ_b2_8o=s3b2_q8n_05_r if year==2005
replace educ_b2_8o=s2b__14_10_r if year==2010
replace educ_b2_8o=s2b_q8p_16_r if year==2016
label var educ_b2_8o "Amount spent on schooling other"

gen educ_b2_8p=s2b_q8k_16_r if year==2016
label var educ_b2_8p "Amount spent on Coaching fees"
note educ_b2_8p: Only available for 2016

gen educ_b2_8q= s3b_q8o_00_r if year==2000
replace educ_b2_8q=s3b2_q8o_05_r if year==2005
replace educ_b2_8q=s2b__15_10_r if year==2010
replace educ_b2_8q=s2b_q8q_16_r if year==2016
label var educ_b2_8q "Amount spent on schooling total"

*Question 9 and 10 available in 2000
gen educ_b1_9 = s3b_q3_00_r if year==2000
label var educ_b1_9 "Days absent from school over the past 30 days"
note educ_b1_9: Question only available for year 2000

gen educ_b1_10 = s3b_q4_00_r if year==2000
replace educ_b1_10=. if s3b_q4_00_r==0 & year==2000
label var educ_b1_10 "Main reason for your longest absence from school"
la de leduc_b1_10 1"No absence" 2"Sick" 3"Household work" 4"Farm work" 5"Family business" ///
6"Other work" 7"Bad weather" 8"Other reasons"
la val educ_b1_10 leduc_b1_10
note educ_b1_10: Question only available for year 2000

/*Question 11 and 12 available in 2005*/
gen educ_b1_11 = s3b1_q3_05_r if year==2005
replace educ_b1_11=. if s3b1_q3_05_r==0 & year==2005
label var educ_b1_11 "Are you receiving stipend for primary? Only female students"
la de leduc_b1_11 1"Yes" 2"No"
la val educ_b1_11 leduc_b1_11
note educ_b1_11: Question only available for year 2005

gen educ_b1_12 = s3b1_q4_05_r if year==2005
label var educ_b1_12 "how much did you receive? Only primary female students"
note educ_b1_12: Question only available for year 2005

/*Question 13 to 15 available in 2000 and 2005*/
gen educ_b1_13 = s3b_q5_00_r if year==2000
replace educ_b1_13= s3b1_q5_05_r if year==2005
replace educ_b1_13=. if s3b1_q5_05_r==0 & year==2005
label var educ_b1_13 "Are you receiving stipend for secondary? Only female students"
la de leduc_b1_13 1"Yes" 2"No"
la val educ_b1_13 leduc_b1_13
note educ_b1_13: Question only available for years 2000 and 2005
 
gen educ_b1_14 = s3b_q6_00_r if year==2000
replace educ_b1_14= s3b1_q6_05_r if year==2005
label var educ_b1_14 "how much did you receive? Only secondary female students"
note educ_b1_14: Question only available for years 2000 and 2005
 
gen educ_b1_15 = s3b_q7_00_r if year==2000
replace educ_b1_15= s3b1_q7_05_r if year==2005
replace educ_b1_15=. if s3b1_q7_05_r==0 & year==2005
label var educ_b1_15 "do you benefit from the tuition waiver? Only secondary female students"
la de educ_b1_15 1 "Yes" 2 "No"
label values educ_b1_15 educ_b1_15
note educ_b1_15: Question only available for years 2000 and 2005
 
*Questions 16 to 21 only available for 2016
gen educ_b1_16=s2a_q3_16_r if year==2016
replace educ_b1_16=. if inlist(educ_b1_16,0,3,4,7)
label var educ_b1_16 "Have you ever attended education?"
la de educ_b1_16 1 "Yes" 2 "No"
label values educ_b1_16 educ_b1_16
note educ_b1_16: Question only available for year 2016
 
gen educ_b1_17=s2a_q7_16_r if year==2016
replace educ_b1_17=. if inlist(educ_b1_17,0,3)
label var educ_b1_17 "Was the last studies abroad (outside Bangladesh)?"
la de educ_b1_17 1 "Yes" 2 "No"
label values educ_b1_17 educ_b1_17
note educ_b1_17: Question only available for year 2016

gen educ_b1_18=s2b_q4_16_r if year==2016
replace educ_b1_18=. if inlist(educ_b1_18,5,7)
label var educ_b1_18 "Are you receiving any stipend for education?"
la de educ_b1_18 1 "Yes" 2 "No"
label values educ_b1_18 educ_b1_18
note educ_b1_18: Question only available for year 2016

gen educ_b1_19=s2b_q5_16_r if year==2016
replace educ_b1_19=. if educ_b1_19==0
label var educ_b1_19 "Which one?"
la de educ_b1_19 1"PEC" 2"JSC" 3"SSC" 4"HSC" 5"Graduate/equivalent"  ///
6"Post graduate/ equivalent"  7"Other (Specify)"
label values educ_b1_19 educ_b1_19
note educ_b1_19: Question only available for year 2016

gen educ_b1_20=s2b_q6_16_r if year==2016
label var educ_b1_20 "How much did you receive in total in the past 12 months?"
note educ_b1_20: Question only available for year 2016

gen educ_b1_21=s2b_q7_16_r if year==2016
replace educ_b1_21=. if inlist(educ_b1_21,0,4,5)
label var educ_b1_21 "Do you benefit from the tuition waiver?"
la de educ_b1_21 1 "Yes" 2 "No"
label values educ_b1_21 educ_b1_21
note educ_b1_21: Question only available for year 2016

***************************************HEALTH***********************************

gen health_a1_1=  s4a_q1_00_r if year==2000
replace health_a1_1= s4a1_q1_05_r if year==2005
replace health_a1_1= s3a_q1_10_r  if year==2010
replace health_a1_1=s3a_q1_16_r if year==2016
replace health_a1_1=. if inlist(health_a1_1,0,7)
label var health_a1_1 "have suffered chronic illness in the last 12 months?"
la de health_a1_1 1 "Yes" 2 "No"
label values health_a1_1 health_a1_1
 
/*(1)Options cancer, leprosy, paralysis, histeria and epilepsy not available for year 2000.
(2)Option histeria only available in 2005.
(3)Option epilepsy only available in 2010.*/
gen health_a1_2a=  s4a_q2_00_r if year==2000
replace health_a1_2a=16 if s4a_q2_00_r==11 & year==2000
replace health_a1_2a=. if (s4a_q2_00_r==0 | s4a_q2_00_r==20 | s4a_q2_00_r==40 | s4a_q2_00_r==60 | s4a_q2_00_r==70  ///
| s4a_q2_00_r==80 | s4a_q2_00_r==90) & year==2000
replace health_a1_2a= s4a1_q2_05_r if year==2005
replace health_a1_2a=16 if s4a1_q2_05_r==15 & year==2005
replace health_a1_2a=15 if s4a1_q2_05_r==14 & year==2005 
replace health_a1_2a=. if s4a1_q2_05_r==0 & year==2005 
replace health_a1_2a= s3a_q2_10_r  if year==2010 
replace health_a1_2a=16 if s3a_q2_10_r==15 & year==2010 
replace health_a1_2a=. if s3a_q2_10_r==0 & year==2010 
forval i=1/11 {
replace health_a1_2a=`i' if  s3a_q2a_16_r==`i'
}
replace health_a1_2a=17 if s3a_q2a_16_r==12
replace health_a1_2a=18 if s3a_q2a_16_r==13
replace health_a1_2a=19 if s3a_q2a_16_r==14
replace health_a1_2a=13 if s3a_q2a_16_r==15
replace health_a1_2a=20 if s3a_q2a_16_r==16
replace health_a1_2a=21 if s3a_q2a_16_r==17
replace health_a1_2a=16 if s3a_q2a_16_r==18
label var health_a1_2a "what chronic illness? 1" 
la de lhealth_a1_2a 1"Chronic Fever" 2"Injuries/Disability" 3"Chronic Heart Disease" 4"Asthma/Breathing trouble"  /// 
5"Diarrhoea/Chronic Dysentery" 6"Gastric/ulcer" 7"Blood pressure" 8"Arthritis/Rheumatism" 9"Eczema/Skin problems" 10"Diabetes"     ///
11"Cancer"  12"Leprosy" 13"Paralysis" 14"Epilepsy" 15"Histeria" 16"Other" 17"kidney Diseases" 18"Liver Diseases" 19"Mental Health" ///
20"Ear/ENT problem" 21"Eye problem"
label values health_a1_2a lhealth_a1_2a
note health_a1_2a:Options cancer, leprosy, paralysis, histeria and epilepsy not available for year 2000.
note health_a1_2a:Options histeria only available in 2005. 
note health_a1_2a:Options epilepsy only available in 2010.
note health_a1_2a:Options kidney Diseases, Liver Diseases, Mental Health, Ear/ENT problem, Eye problem only available in 2016.

*Question 2b, only available for years 2010 and 2016
gen health_a1_2b= s3a_q_1_10_r if year==2010
replace health_a1_2b=. if (s3a_q_1_10_r==0 |s3a_q_1_10_r==25|s3a_q_1_10_r==16) & year==2010
forval i=1/11 {
replace health_a1_2b=`i' if  s3a_q2b_16_r==`i'
}
replace health_a1_2b=16 if s3a_q2b_16_r==12
replace health_a1_2b=17 if s3a_q2b_16_r==13
replace health_a1_2b=18 if s3a_q2b_16_r==14
replace health_a1_2b=13 if s3a_q2b_16_r==15
replace health_a1_2b=19 if s3a_q2b_16_r==16
replace health_a1_2b=20 if s3a_q2b_16_r==17
replace health_a1_2b=15 if s3a_q2b_16_r==18
label var health_a1_2b "what chronic illness? 2"
la de health_a1_2b 1"Chronic Fever" 2"Injuries/Disability" 3"Chronic Heart Disease" 4"Asthma/Breathing trouble"  /// 
5"Chronic Dysentery" 6"Gastric/ulcer" 7"Blood pressure" 8"Arthritis/Rheumatism" 9"Eczema" 10"Diabetes"     /// 
11"Cancer"  12"Leprosy" 13"Paralysis" 14"Epilepsy" 15"Other" 16"kidney Diseases" 17"Liver Diseases" 18"Mental Health" ///
19"Ear/ENT problem" 20"Eye problem"
label values health_a1_2b health_a1_2b

*Questions 3a and 3b not available for year 2016 
gen health_a1_3a=   s4a_q3a_00_r if year==2000
replace health_a1_3a=  s4a1_q3a_05_r if year==2005
replace health_a1_3a=  s3a_q3_10_r  if year==2010
label var health_a1_3a "for how long had illness? (years)" 
 
gen health_a1_3b= s4a_q3b_00_r if year==2000
replace health_a1_3b= s4a1_q3b_05_r if year==2005
replace health_a1_3b= s3a_q_2_10_r if year==2010
replace health_a1_3b=. if health_a1_3b>12
label var health_a1_3b "for how long had illness? (Months)"

gen health_a1_4= s4a_q4_00_r if year==2000
replace health_a1_4=. if s4a_q4_00_r==0 & year==2000
replace health_a1_4= s4a1_q4_05_r if year==2005
replace health_a1_4=. if s4a1_q4_05_r==0 & year==2005 
replace health_a1_4= s3a_q4_10_r if year==2010
replace health_a1_4=. if (s3a_q4_10_r==0 | s3a_q4_10_r==4) & year==2010
replace health_a1_4=s3a_q3_16_r if year==2016
replace health_a1_4=. if s3a_q3_16_r==7
replace health_a1_4=. if s3a_q3_16_r==0
label var health_a1_4 "have suffered illness in last 30 days?"
la de health_a1_4 1 "Yes" 2 "No"
label values health_a1_4 health_a1_4

/*(1)Option Palpitation in 2000 is assumed to be the same as heart disease in 2005 and 2010.
(2)Options Typhoid, Tuberculosis, Malaria, Jaundice, Female diseases, Pregnancy related, Cancer,
Leprosy, Paralysis, Epilepsy, Scabies, Kidney Diseases, Gall stone Diseases, and Histeria not available in 2000.
(3)Option histeria only available in 2005.
(4)Option gall stone Diseases only available in 2010
(5)Options pregnancy related, epilepsy, scabies, kidney Diseases only available in 2010, 2016.
(6)Options Mental health, Liver Diseases, Ear/ENT problem, Eye problem only available in 2016. */
gen health_a1_5a= s4a_q5a_00_r if year==2000
replace health_a1_5a=4 if s4a_q5a_00_r==3 & year==2000
replace health_a1_5a=5 if s4a_q5a_00_r==4 & year==2000
replace health_a1_5a=6 if s4a_q5a_00_r==5 & year==2000
replace health_a1_5a=7 if s4a_q5a_00_r==6 & year==2000
replace health_a1_5a=8 if s4a_q5a_00_r==7 & year==2000
replace health_a1_5a=9 if s4a_q5a_00_r==8 & year==2000
replace health_a1_5a=10 if s4a_q5a_00_r==9 & year==2000
replace health_a1_5a=26 if s4a_q5a_00_r==11 & year==2000
replace health_a1_5a=. if (s4a_q5a_00_r==0 |s4a_q5a_00_r==20 | s4a_q5a_00_r==30) & year==2000
replace health_a1_5a= s4a1_q5a_05_r if year==2005
replace health_a1_5a=18 if s4a1_q5a_05_r==17 & year==2005
replace health_a1_5a=19 if s4a1_q5a_05_r==18 & year==2005
replace health_a1_5a=20 if s4a1_q5a_05_r==19 & year==2005
replace health_a1_5a=25 if s4a1_q5a_05_r==20 & year==2005
replace health_a1_5a=26 if s4a1_q5a_05_r==21 & year==2005
replace health_a1_5a=. if s4a1_q5a_05_r==0 & year==2005
replace health_a1_5a= s3a_q5_10_r if year==2010
replace health_a1_5a=26 if s3a_q5_10_r==25 & year==2010
replace health_a1_5a=. if s3a_q5_10_r==0 & year==2010
forval i=1/18 {
replace health_a1_5a=`i' if  s3a_q4a_16_r==`i'
}
replace health_a1_5a=27 if  s3a_q4a_16_r==19
forval i=20/23 {
replace health_a1_5a=`i' if  s3a_q4a_16_r==`i'
}
replace health_a1_5a=28 if  s3a_q4a_16_r==24
replace health_a1_5a=29 if  s3a_q4a_16_r==25
replace health_a1_5a=30 if  s3a_q4a_16_r==26
replace health_a1_5a=26 if  s3a_q4a_16_r==27
label var health_a1_5a "what type of illness? 1"
la de health_a1_5a 1"Diarrhoea" 2"Fever" 3"Dysentery" 4"Pain" 5"Injury" 6"Blood pressure" 7"Heart disease" ///
8"Breathing trouble" 9"Weakness" 10"Dizziness" 11"Pneumonia" 12"Typhoid" 13"Tuberculosis" 14"Malaria"   ///
15"Jaundice" 16"Female diseases" 17"Pregnancy related" 18"Cancer"  19"Leprosy" 20"Paralysis"  ///
21"Epilepsy" 22"Scabies" 23"Kidney Diseases" 24"Gall stone Diseases" 25"Histeria" 26"Other" 27"Mental health" ///
28 "Liver Diseases" 29"Ear/ENT problem" 30"Eye problem"
label values health_a1_5a health_a1_5a
note health_a1_5a:Option Palpitation in 2000 is assumed to be the same as heart disease in 2005 and 2010.
note health_a1_5a:Options Typhoid, Tuberculosis, Malaria, Jaundice, Female diseases, Pregnancy related, Cancer, ///
Leprosy, Paralysis, Epilepsy, Scabies, Kidney Diseases, Gall stone Diseases, and Histeria not available in 2000.
note health_a1_5a:Option histeria only available in 2005.
note health_a1_5a:Option gall stone Diseases only available in 2010.
note health_a1_5a:Options pregnancy related, epilepsy, scabies, kidney Diseases only available in 2010, 2016.
note health_a1_5a:Options Mental health, Liver Diseases, Ear/ENT problem, Eye problem only available in 2016.

/*(1)Option Palpitation in 2000 is assumed to be the same as heart disease in 2005 and 2010.
(2)Options Typhoid, Tuberculosis, Malaria, Jaundice, Female diseases, Pregnancy related, Cancer,
Leprosy, Paralysis, Epilepsy, Scabies, Kidney Diseases, Gall stone Diseases, and Histeria not available in 2000.
(3)Option histeria only available in 2005.
(4)Option gall stone Diseases only available in 2010
(5)Options pregnancy related, epilepsy, scabies, kidney Diseases only available in 2010, 2016.
(6)Options Mental health, Liver Diseases, Ear/ENT problem, Eye problem only available in 2016. */
gen health_a1_5b= s4a_q5b_00_r if year==2000
replace health_a1_5b=4 if s4a_q5b_00_r==3 & year==2000
replace health_a1_5b=5 if s4a_q5b_00_r==4 & year==2000
replace health_a1_5b=6 if s4a_q5b_00_r==5 & year==2000
replace health_a1_5b=7 if s4a_q5b_00_r==6 & year==2000
replace health_a1_5b=8 if s4a_q5b_00_r==7 & year==2000
replace health_a1_5b=9 if s4a_q5b_00_r==8 & year==2000
replace health_a1_5b=10 if s4a_q5b_00_r==9 & year==2000
replace health_a1_5b=26 if s4a_q5b_00_r==10 & year==2000
replace health_a1_5b=. if s4a_q5b_00_r==70 & year==2000
replace health_a1_5b= s4a1_q5b_05_r if year==2005
replace health_a1_5b=18 if s4a1_q5b_05_r==17 & year==2005
replace health_a1_5b=19 if s4a1_q5b_05_r==18 & year==2005
replace health_a1_5b=20 if s4a1_q5b_05_r==19 & year==2005
replace health_a1_5b=25 if s4a1_q5b_05_r==20 & year==2005
replace health_a1_5b=26 if s4a1_q5b_05_r==21 & year==2005
replace health_a1_5b=. if s4a1_q5b_05_r==0 & year==2005
replace health_a1_5b= s3a_q_3_10_r if year==2010
replace health_a1_5b=26 if s3a_q_3_10_r==25 & year==2010
replace health_a1_5b=. if s3a_q_3_10_r==0 & year==2010
forval i=1/18 {
replace health_a1_5b=`i' if  s3a_q4b_16_r==`i'
}
replace health_a1_5b=27 if  s3a_q4b_16_r==19
forval i=20/23 {
replace health_a1_5b=`i' if  s3a_q4b_16_r==`i'
}
replace health_a1_5b=28 if  s3a_q4b_16_r==24
replace health_a1_5b=29 if  s3a_q4b_16_r==25
replace health_a1_5b=30 if  s3a_q4b_16_r==26
replace health_a1_5b=26 if  s3a_q4b_16_r==27
label var health_a1_5b "What type of illness? 2"
la de health_a1_5b 1"Diarrhoea" 2"Fever" 3"Dysentery" 4"Pain" 5"Injury" 6"Blood pressure" 7"Heart disease" ///
8"Breathing trouble" 9"Weakness" 10"Dizziness" 11"Pneumonia" 12"Typhoid" 13"Tuberculosis" 14"Malaria"   ///
15"Jaundice" 16"Female diseases" 17"Pregnancy related" 18"Cancer" 19"Leprosy" 20"Paralysis"  ///
21"Epilepsy" 22"Scabies" 23"Kidney Diseases" 24"Gall stone Diseases" 25"Histeria" 26"Other" 27"Mental health" ///
28 "Liver Diseases" 29"Ear/ENT problem" 30"Eye problem"
label values health_a1_5b health_a1_5b
note health_a1_5b:Option Palpitation in 2000 is assumed to be the same as heart disease in 2005 and 2010.
note health_a1_5b:Options Typhoid, Tuberculosis, Malaria, Jaundice, Female diseases, Pregnancy related, Cancer, ///
Leprosy, Paralysis, Epilepsy, Scabies, Kidney Diseases, Gall stone Diseases, and Histeria not available in 2000. 
note health_a1_5b:Option histeria only available in 2005.
note health_a1_5b:Option gall stone Diseases only available in 2010.
note health_a1_5b:Options pregnancy related, epilepsy, scabies, kidney Diseases only available in 2010, 2016.
note health_a1_5b:Options Mental health, Liver Diseases, Ear/ENT problem, Eye problem only available in 2016.
 
/*(1)Option Palpitation in 2000 is assumed to be the same as heart disease in 2005 and 2010. 
(2)Options Typhoid, Tuberculosis, Malaria, Jaundice, Female diseases, Pregnancy related, Cancer,
Leprosy, Paralysis, Epilepsy, Scabies, Kidney Diseases, Gall stone Diseases, and Histeria not available in 2000.
(3)Option histeria only available in 2005.
(4)Option gall stone Diseases only available in 2010
(5)Options pregnancy related, epilepsy, scabies, kidney Diseases only available in 2010, 2016.
(6)Options Mental health, Liver Diseases, Ear/ENT problem, Eye problem only available in 2016. */
gen health_a1_5c= s4a_q5c_00_r if year==2000
replace health_a1_5c=4 if s4a_q5c_00_r==3 & year==2000
replace health_a1_5c=5 if s4a_q5c_00_r==4 & year==2000
replace health_a1_5c=6 if s4a_q5c_00_r==5 & year==2000 
replace health_a1_5c=7 if s4a_q5c_00_r==6 & year==2000 
replace health_a1_5c=8 if s4a_q5c_00_r==7 & year==2000 
replace health_a1_5c=9 if s4a_q5c_00_r==8 & year==2000 
replace health_a1_5c=10 if s4a_q5c_00_r==9 & year==2000 
replace health_a1_5c=26 if s4a_q5c_00_r==10 & year==2000 
replace health_a1_5c= s4a1_q5c_05_r if year==2005
replace health_a1_5c=18 if s4a1_q5c_05_r==17 & year==2005
replace health_a1_5c=19 if s4a1_q5c_05_r==18 & year==2005
replace health_a1_5c=20 if s4a1_q5c_05_r==19 & year==2005
replace health_a1_5c=25 if s4a1_q5c_05_r==20 & year==2005
replace health_a1_5c=26 if s4a1_q5c_05_r==21 & year==2005
replace health_a1_5c=. if s4a1_q5c_05_r==0 & year==2005
replace health_a1_5c= s3a_q_4_10_r if year==2010
replace health_a1_5c=26 if s3a_q_4_10_r==25 & year==2010
replace health_a1_5c=. if s3a_q_4_10_r==0 & year==2010
forval i=1/18 {
replace health_a1_5c=`i' if  s3a_q4c_16_r==`i' & year==2016
}
replace health_a1_5c=27 if  s3a_q4c_16_r==19 & year==2016
forval i=20/23 {
replace health_a1_5c=`i' if  s3a_q4c_16_r==`i'
}
replace health_a1_5c=28 if  s3a_q4c_16_r==24
replace health_a1_5c=29 if  s3a_q4c_16_r==25
replace health_a1_5c=30 if  s3a_q4c_16_r==26
replace health_a1_5c=26 if  s3a_q4c_16_r==27
label var health_a1_5c "What type of illness? 3"
la de lhealth_a1_5c 1"Diarrhoea" 2"Fever" 3"Dysentery" 4"Pain" 5"Injury" 6"Blood pressure" 7"Heart disease" ///
8"Breathing trouble" 9"Weakness" 10"Dizziness" 11"Pneumonia" 12"Typhoid" 13"Tuberculosis" 14"Malaria"   ///
15"Jaundice" 16"Female diseases" 17"Pregnancy related" 18"Cancer" 19"Leprosy" 20"Paralysis"  ///
21"Epilepsy" 22"Scabies" 23"Kidney Diseases" 24"Gall stone Diseases" 25"Histeria" 26"Other" 27"Mental health" ///
28"Liver diseases" 29"Ear/ENT problems" 30"Eye problem"
label values health_a1_5c lhealth_a1_5c
note health_a1_5c:Option Palpitation in 2000 is assumed to be the same as heart disease in 2005 and 2010.
note health_a1_5c:Options Typhoid, Tuberculosis, Malaria, Jaundice, Female diseases, Pregnancy related, Cancer, ///
Leprosy, Paralysis, Epilepsy, Scabies, Kidney Diseases, Gall stone Diseases, and Histeria not available in 2000.
note health_a1_5c:Option histeria only available in 2005.
note health_a1_5c:Options pregnancy related, epilepsy, scabies, kidney Diseases, and gall stone Diseases only available in 2010.

gen health_a1_6=   s4a_q6_00_r if year==2000
replace health_a1_6= s4a1_q6_05_r if year==2005
replace health_a1_6= s3a_q6_10_r if year==2010
replace health_a1_6=s3a_q5_16_r if year==2016
replace health_a1_6=. if inlist(health_a1_6,0,7,8)
label var health_a1_6 " Have sought medical treatment?" 
la de lhealth_a1_6 1 "Yes" 2 "No" 
label values health_a1_6 lhealth_a1_6

*Option "Quality of healthcare is not good" only available for year 2010
gen health_a1_7= s4a_q7_00_r if year==2000
replace health_a1_7=2 if s4a_q7_00_r==1 & year==2000
replace health_a1_7=3 if s4a_q7_00_r==2 & year==2000
replace health_a1_7=4 if s4a_q7_00_r==3 & year==2000
replace health_a1_7=5 if s4a_q7_00_r==4 & year==2000
replace health_a1_7=6 if s4a_q7_00_r==5 & year==2000
replace health_a1_7=7 if s4a_q7_00_r==6 & year==2000
replace health_a1_7=11 if s4a_q7_00_r==10 & year==2000
replace health_a1_7=12 if s4a_q7_00_r==11 & year==2000
replace health_a1_7= s4a1_q7_05_r if year==2005
replace health_a1_7=2 if s4a1_q7_05_r==1 & year==2005
replace health_a1_7=3 if s4a1_q7_05_r==2 & year==2005
replace health_a1_7=4 if s4a1_q7_05_r==3 & year==2005
replace health_a1_7=5 if s4a1_q7_05_r==4 & year==2005
replace health_a1_7=6 if s4a1_q7_05_r==5 & year==2005
replace health_a1_7=7 if s4a1_q7_05_r==6 & year==2005
replace health_a1_7=8 if s4a1_q7_05_r==7 & year==2005
replace health_a1_7=9 if s4a1_q7_05_r==8 & year==2005
replace health_a1_7=11 if s4a1_q7_05_r==9 & year==2005
replace health_a1_7=10 if s4a1_q7_05_r==12 & year==2005
replace health_a1_7= s3a_q7_10_r if year==2010
replace health_a1_7=. if s3a_q7_10_r==0 & year==2010
forval i=2/5 {
replace health_a1_7=`i' if s3a_q6_16_r==`i'-1
}
replace health_a1_7=8 if s3a_q6_16_r==5
replace health_a1_7=13 if s3a_q6_16_r==6
replace health_a1_7=11 if s3a_q6_16_r==7
replace health_a1_7=12 if s3a_q6_16_r==8
label var health_a1_7 "Why not receive any treatment?"
la de health_a1_7 1"Quality of healthcare is not good" 2"Problem was not serious" 3"Treatment cost is too much"  ///
4"Distance is too long" 5"Afraid of discovering serious illness" 6"Afraid to take action"  ///
7"Nobody at home to pay any attention/take care of me" 8"There was none to accompany" 9"It is a hassle to go outside"  ///
10"Not able to make own decision about healthcare" 11"Didn't know where to go" 12"Other" ///
13 "Decision maker does not think I should seek treatment"
label values health_a1_7 health_a1_7
note health_a1_7:Option "Quality of healthcare is not good" only available for year 2010
note health_a1_7:Option "It is a hassle to go outside" and "Not able to make own decision about healthcare" not available for year 2016
note health_a1_7:Option "Decision maker does not think I should seek treatment" only available for year 2016

*This question has all the options different in 2016, we create a different variable for this year.
gen health_a2_8a1= s4a_q8a_00_r if year==2000
replace health_a2_8a1=13 if s4a_q8a_00_r==11 & year==2000
replace health_a2_8a1= s4a2_q8a_05_r if year==2005
replace health_a2_8a1= s3a_q8_10_r if year==2010
replace health_a2_8a1=. if s3a_q8_10_r==0 & year==2010
labe var health_a2_8a "Who was consulted for this illness/injury? (1st) 2000, 2005, 2010"
la de health_a2_8a1 1"Govt. Health Worker"2"NGO Health Worker" 3"Homeopath" 4"Ayurved/Kabiraji/Hekim" ///
5"Other Traditional/Spiritual/Faith Healer"6"Govt. Doctor(Govt. Facility)" 7"Govt. Doctor(Private Facility)" ///
8"Doctor from NG0 Facility" 9"Doctor from Private Facility" 10"Salesman of a Pharmacy/Dispensary" 11"Family treatment" ///
12"Self treatment" 13"Other"
label values health_a2_8a1 health_a2_8a1

gen health_a2_8a2=s3a_q7a_16_r
replace health_a2_8a2=. if health_a2_8a2==0
labe var health_a2_8a2 "Who was consulted for this illness/injury? (1st) 2016"
la de health_a2_8a2  1 "Govt. Health Worker", add
la de health_a2_8a2  2 "Govt. Satellite Clinic/EPI Outreach Center", add
la de health_a2_8a2  3 "Community Clinic", add
la de health_a2_8a2  4 "Union Health & Family Welfare Centrer/Union Sub Center", add
la de health_a2_8a2  5 "Upazila Health Complex", add
la de health_a2_8a2  6 "Maternal & Child Welfare Center (MCWC)", add
la de health_a2_8a2  7 "Govt. District/Sadar/General Hospital", add
la de health_a2_8a2  8 "Govt. Medical College/Specialized Hospital", add
la de health_a2_8a2  9 "Other Govt. Specify", add
la de health_a2_8a2  10 "NGO Health Worker/Satellite Clinic", add
la de health_a2_8a2  11 "NGO Clinic/Hospitals", add
la de health_a2_8a2  12 "Govt. Medical College/Specialized Hospital", add
la de health_a2_8a2  13 "Private Clinic/Hospitals", add
la de health_a2_8a2  14 "Private Medical College/Specialized Hospital", add
la de health_a2_8a2  15 "Qualified Doctor's Chamber", add
la de health_a2_8a2  16 "Non-qualified Doctor's Chamber", add
la de health_a2_8a2  17 "Pharmacy/Dispensary", add
la de health_a2_8a2  18 "Homeopath", add
la de health_a2_8a2  19 "Ayurbed/Kabiraj/Hekim", add
la de health_a2_8a2  20 "Other Traditional/Spiritual", add
la de health_a2_8a2  21 "Family/Self Treatment", add
la de health_a2_8a2  22 "Other (Specify)", add
la val health_a2_8a2 health_a2_8a2

gen health_a2_8b1= s4a_q8b_00_r if year==2000
replace health_a2_8b1=13 if s4a_q8b_00_r==11 & year==2000
replace health_a2_8b1= s4a2_q8b_05_r if year==2005
replace health_a2_8b1= s3a_q_5_10_r if year==2010
replace health_a2_8b1=. if s3a_q_5_10_r==0 & year==2010
lab var health_a2_8b1 "Who was consulted for this illness/injury? (2nd) 2000, 2005, 2010"
la de health_a2_8b1 1"Govt. Health Worker"2"NGO Health Worker" 3"Homeopath" 4"Ayurved/Kabiraji/Hekim" ///
5"Other Traditional/Spiritual/Faith Healer"6"Govt. Doctor(Govt. Facility)" 7"Govt. Doctor(Private Facility)" ///
8"Doctor from NG0 Facility" 9"Doctor from Private Facility" 10"Salesman of a Pharmacy/Dispensary" 11"Family treatment" ///
12"Self treatment" 13"Other"
label values health_a2_8b1 health_a2_8b1

gen health_a2_8b2=s3a_q7b_16_r
replace health_a2_8b2=. if inlist(health_a2_8b2,0,27)
labe var health_a2_8b2 "Who was consulted for this illness/injury? (2nd) 2016"
la de health_a2_8b2  1 "Govt. Health Worker", add  
la de health_a2_8b2  2 "Govt. Satellite Clinic/EPI Outreach Center", add
la de health_a2_8b2  3 "Community Clinic", add
la de health_a2_8b2  4 "Union Health & Family Welfare Centrer/Union Sub Center", add
la de health_a2_8b2  5 "Upazila Health Complex", add
la de health_a2_8b2  6 "Maternal & Child Welfare Center (MCWC)", add
la de health_a2_8b2  7 "Govt. District/Sadar/General Hospital", add
la de health_a2_8b2  8 "Govt. Medical College/Specialized Hospital", add
la de health_a2_8b2  9 "Other Govt. Specify", add
la de health_a2_8b2  10 "NGO Health Worker/Satellite Clinic", add
la de health_a2_8b2  11 "NGO Clinic/Hospitals", add
la de health_a2_8b2  12 "Govt. Medical College/Specialized Hospital", add
la de health_a2_8b2  13 "Private Clinic/Hospitals", add
la de health_a2_8b2  14 "Private Medical College/Specialized Hospital", add
la de health_a2_8b2  15 "Qualified Doctor's Chamber", add
la de health_a2_8b2  16 "Non-qualified Doctor's Chamber", add
la de health_a2_8b2  17 "Pharmacy/Dispensary", add
la de health_a2_8b2  18 "Homeopath", add
la de health_a2_8b2  19 "Ayurbed/Kabiraj/Hekim", add
la de health_a2_8b2  20 "Other Traditional/Spiritual", add
la de health_a2_8b2  21 "Family/Self Treatment", add
la de health_a2_8b2  22 "Other (Specify)", add
la val health_a2_8b2 health_a2_8b2

gen health_a2_8b3=s3a_q7c_16_r if year==2016
la var health_a2_8b3 "Was the consulted provider urban or rural?"
la de health_a2_8b3 1"Rural" 2"Urban"
la val health_a2_8b3 health_a2_8b3

gen health_a2_9= s4a_q9_00_r if year==2000
replace health_a2_9= s4a2_q9_05_r if year==2005
replace health_a2_9= s3a_q9_10_r if year==2010
replace health_a2_9=s3a_q8_16_r if year==2016
labe var health_a2_9 "After how many days began consultation?"

*Options "not available" and "Could not afford" only available for years 2010 and 2016
gen health_a2_10= s4a_q10_00_r if year==2000
replace health_a2_10=9 if s4a_q10_00_r==7 & year==2000
replace health_a2_10= s4a2_q10_05_r if year==2005
replace health_a2_10=9 if s4a2_q10_05_r==7 & year==2005
replace health_a2_10= s3a_q10_10_r if year==2010
replace health_a2_10=s3a_q10_16_r if year==2016
replace health_a2_10=. if health_a2_10==0
labe var health_a2_10 "From where got medicines?"
la de health_a2_10 1"Govt. health centre"2"NGO health facility"3"Private health facility" 4"Other facility"  ///
5"Pharmacy/dispensary" 6"Other shop" 7"Not available" 8"Could not afford" 9"Other"
label values health_a2_10 health_a2_10
note health_a2_10:Options "not available" and "Could not afford" only available for years 2010 and 2016

gen health_a2_11= s4a_q11_00_r if year==2000
replace health_a2_11= s4a2_q11_05_r if year==2005
replace health_a2_11= s3a_q11_10_r if year==2010
replace health_a2_11=. if (s3a_q11_10_r==0 | s3a_q11_10_r==7 | s3a_q11_10_r==8) & year==2010
labe var health_a2_11 "did you pay for the medicines?"
la de lhealth_a2_11 1"Yes, totally" 2"Yes, partially" 3"No"
label values health_a2_11 lhealth_a2_11
note health_a2_11: Question not available for 2016

gen health_a2_12= s4a_q12_00_r if year==2000
replace health_a2_12=8 if s4a_q12_00_r==7 & year==2000
replace health_a2_12=9 if s4a_q12_00_r==8 & year==2000
replace health_a2_12=10 if s4a_q12_00_r==9 & year==2000
replace health_a2_12=11 if s4a_q12_00_r==10 & year==2000
replace health_a2_12=13 if s4a_q12_00_r==11 & year==2000
replace health_a2_12= s4a2_q12_05_r if year==2005
replace health_a2_12=13 if s4a2_q12_05_r==12 & year==2005
replace health_a2_12= s3a_q12_10_r if year==2010
replace health_a2_12=s3a_q11_16_r if year==2016
replace health_a2_12=. if health_a2_12==0
label var health_a2_12 "How did you travel to the provider?"
la de lhealth_a2_12 1"Private car" 2"Taxi" 3"Bus" 4"Auto rickshaw" 5"Rickshaw" 6"Rickshaw van" 7"Bullock cart" 8"Country boat" ///
9"Engine boat" 10"Ambulance" 11"Walking" 12"Calling doctor at home" 13"Other"
label values health_a2_12 lhealth_a2_12

gen health_a2_13a= s4a_q13a_00_r if year==2000
replace health_a2_13a= s4a2_q13a_05_r if year==2005
replace health_a2_13a= s3a_q13_10_r if year==2010
replace health_a2_13a=s3a_q12a_16_r if year==2016
label var health_a2_13a "How much time it took to reach the service provider?(hour)"

gen health_a2_13b= s4a_q13b_00_r if year==2000
replace health_a2_13b= s4a2_q13b_05_r if year==2005
replace health_a2_13b=  s3a_q_6_10_r if year==2010
replace health_a2_13b=s3a_q12b_16_r if year==2016
label var health_a2_13b "How much time it took to reach the service provider?(minutes)"

gen health_a2_14a= s4a_q14a_00_r if year==2000
replace health_a2_14a= s4a2_q14a_05_r if year==2005
replace health_a2_14a= s3a_q14_10_r if year==2010
replace health_a2_14a=s3a_q13a_16_r if year==2016
label var health_a2_14a "How long did you have to wait at provider to be examined??(hour)"

gen health_a2_14b= s4a_q14b_00_r if year==2000
replace health_a2_14b= s4a2_q14b_05_r if year==2005
replace health_a2_14b= s3a_q_7_10_r  if year==2010
replace health_a2_14b= s3a_q13b_16_r if year==2016
label var health_a2_14b "How long did you have to wait at provider to be examined?(minutes)"

gen health_a3_15= s4a_q15_00_r if year==2000
replace health_a3_15= s4a3_q15_05_r if year==2005
replace health_a3_15=  s3a_q15_10_r if year==2010
replace health_a3_15=s3a_q9_16_r if year==2016
replace health_a3_15=. if inlist(health_a3_15,0,20)
label var health_a3_15 "why you chose this provider?"
la de lhealth_a3_15 1"Nearby" 2"Acceptable cost" 3"Availability of doctor" 4"Availability of female doctor" 5"Availability of equipment" ///
6"Quality of treatment" 7"Referred by other provider" 8"Referred by relatives/friends" 9"Reputation" 10 "Other"
la values health_a3_15 lhealth_a3_15

gen health_a3_16= s4a_q16_00_r if year==2000
replace health_a3_16= s4a3_q16_05_r if year==2005
replace health_a3_16=  s3a_q16_10_r if year==2010
replace health_a3_16=. if  (s3a_q16_10_r==0 | s3a_q16_10_r==6) & year==2010
la var health_a3_16 "Did provider spend enough time with you?"
la de lhealth_a3_16 1"Yes" 2"No" 3"Don't know" 
la values health_a3_16 lhealth_a3_16
note health_a3_16: Question not available for 2016

gen health_a3_17a= s4a_q17a_00_r if year==2000
replace health_a3_17a= s4a3_q17a_05_r if year==2005
replace health_a3_17a=  s3a_q17_10_r if year==2010
replace health_a3_17a= s3a_q14a_16_r if year==2016
la var health_a3_17a "How much did you spent during the past 30 days on consultation/visit?"

gen health_a3_17b= s4a_q17b_00_r if year==2000
replace health_a3_17b= s4a3_q17b_05_r if year==2005
replace health_a3_17b=  s3a_q_8_10_r if year==2010
la var health_a3_17b "How much did you spent during the past 30 days on hospital/clinic?"
note health_a3_17b: Question not available for 2016

gen health_a3_17c= s4a_q17c_00_r if year==2000
replace health_a3_17c= s4a3_q17c_05_r if year==2005
replace health_a3_17c=  s3a_q_9_10_r if year==2010
replace health_a3_17c= s3a_q14b_16_r if year==2016
la var health_a3_17c "How much did you spent during the past 30 days on medicines?"

gen health_a3_17d= s4a_q17d_00_r if year==2000
replace health_a3_17d= s4a3_q17d_05_r if year==2005
replace health_a3_17d= s3a__10_10_r if year==2010 
replace health_a3_17d= s3a_q14c_16_r if year==2016
la var health_a3_17d "How much did you spent during the past 30 days on test/investigation?"

gen health_a3_17e= s4a_q17e_00_r if year==2000
replace health_a3_17e= s4a3_q17e_05_r if year==2005
replace health_a3_17e=  s3a__11_10_r if year==2010
replace health_a3_17e= s3a_q14d_16_r if year==2016
la var health_a3_17e "How much did you spent during the past 30 days on transport?"

gen health_a3_17f= s4a_q17f_00_r if year==2000
replace health_a3_17f= s4a3_q17f_05_r if year==2005
replace health_a3_17f=  s3a__12_10_r if year==2010
la var health_a3_17f "How much did you spent during the past 30 days on tips?"
note health_a3_17f: Question not available for 2016

gen health_a3_17g= s4a_q17g_00_r if year==2000
replace health_a3_17g= s4a3_q17g_05_r if year==2005
replace health_a3_17g=  s3a__13_10_r if year==2010
la var health_a3_17g "How much did you spent during the past 30 days on other services?"
note health_a3_17g: Question not available for 2016

gen health_a3_17h= s4a3_q17h_05_r if year==2005
replace health_a3_17h= s3a__14_10_r   if year==2010
la var health_a3_17h "How much did you spent during the past 30 days on maternity cost: Clinic?"
note health_a3_17h: Question not available for 2000, 2016

gen health_a3_17i= s4a3_q17i_05_r if year==2005
replace health_a3_17i=  s3a__15_10_r if year==2010
la var health_a3_17i "How much did you spent during the past 30 days on maternity cost: Midwife?"
note health_a3_17i: Question not available for 2000, 2016

gen health_a3_17j= s4a3_q17j_05_r if year==2005
replace health_a3_17j=  s3a__16_10_r if year==2010
la var health_a3_17j "How much did you spent during the past 30 days on maternity cost: Others?"
note health_a3_17j: Question not available for 2000, 2016

gen health_a3_17k= s4a_q17h_00_r if year==2000
replace health_a3_17k= s4a3_q17k_05_r if year==2005
replace health_a3_17k=  s3a__17_10_r if year==2010
replace health_a3_17k= s3a_q14e_16_r if year==2016
la var health_a3_17k "How much did you spent during the past 30 days: total cost?"

gen health_a3_17l=s3a_q15a_16_r if year==2016
la var  health_a3_17l "How much did you spent during the past 30 days on immunization?"
note health_a3_17l: Question only available for 2016

gen health_a3_17m=s3a_q15b_16_r if year==2016
la var  health_a3_17m "How much did you spent during the past 30 days on contraceptives?"
note health_a3_17m: Question only available for 2016

gen health_a3_17n=s3a_q15c_16_r if year==2016
la var  health_a3_17n "How much did you spent during the past 30 days on ORS?"
note health_a3_17n: Question only available for 2016

gen health_a3_17o=s3a_q15d_16_r if year==2016
la var  health_a3_17o "How much did you spent during the past 30 days on routine medicines for chronic illness?"
note health_a3_17o: Question only available for 2016

gen health_a3_17p=s3a_q15e_16_r if year==2016
la var  health_a3_17p "How much did you spent during the past 30 days on routine medical check up?"
note health_a3_17p: Question only available for 2016

*Option "Assistance from friends & relatives" not available for year 2000
gen health_a3_18a= s4a_q18a_00_r if year==2000
replace health_a3_18a=11 if s4a_q18a_00_r==10 & year==2000
replace health_a3_18a= s4a3_q18a_05_r if year==2005
replace health_a3_18a=  s3a_q18_10_r if year==2010
replace health_a3_18a= s3a_q21a_16_r if year==2016
replace health_a3_18a=. if health_a3_18a==0
la var health_a3_18a "How financed treatment? 1"
la de lhealth_a3_18a 1"Regular income" 2"Household saving" 3"Sold personal belonging" 4"Sold Livestock" ///
5"Sold Agricultural product/Tree" 6"Sold permanent assets" 7"Mortgage of Assets/Land" 8"Borrowed from Friends/Relatives/Office" ///
9"Borrowed from Money Lender" 10"Assistance from friends & relatives" 11"Other"
la values health_a3_18a lhealth_a3_18a
note health_a3_18a:Option "Assistance from friends & relatives" not available for year 2000

*Option "Assistance from friends & relatives" not available for year 2000
gen health_a3_18b= s4a_q18b_00_r if year==2000
replace health_a3_18b=11 if s4a_q18b_00_r==10 & year==2000
replace health_a3_18b= s4a3_q18b_05_r if year==2005
replace health_a3_18b=  s3a__18_10_r if year==2010
replace health_a3_18b= s3a_q21b_16_r if year==2016
replace health_a3_18b=. if health_a3_18b==0
la var health_a3_18b " How financed treatment? 2"
la de lhealth_a3_18b 1"Regular income" 2"Household saving" 3"Sold personal belonging" 4"Sold Livestock" ///
5"Sold Agricultural product/Tree" 6"Sold permanent assets" 7"Mortgage of Assets/Land" 8"Borrowed from Friends/Relatives/Office" ///
9"Borrowed from Money Lender" 10"Assistance from friends & relatives" 11"Other"
la values health_a3_18b lhealth_a3_18b
note health_a3_18b:Option "Assistance from friends & relatives" not available for year 2000

*Option "Assistance from friends & relatives" not available for year 2000
gen health_a3_18c= s4a_q18c_00_r if year==2000
replace health_a3_18c=11 if s4a_q18c_00_r==10 & year==2000
replace health_a3_18c= s4a3_q18c_05_r if year==2005
replace health_a3_18c=  s3a__19_10_r if year==2010
replace health_a3_18c= s3a_q21c_16_r if year==2016
replace health_a3_18c=. if inlist(health_a3_18c,0,50,95)
la var health_a3_18c " how financed treatment? 3"
la de lhealth_a3_18c 1"Regular income" 2"Household saving" 3"Sold personal belonging" 4"Sold Livestock" ///
5"Sold Agricultural product/Tree" 6"Sold permanent assets" 7"Mortgage of Assets/Land" 8"Borrowed from Friends/Relatives/Office" ///
9"Borrowed from Money Lender" 10"Assistance from friends & relatives" 11"Other"
la values health_a3_18c lhealth_a3_18c
note health_a3_18c:Option "Assistance from friends & relatives" not available for year 2000 

*Questions health_a3_19 to health_a3_23 only available for year 2016
gen health_a3_19=s3a_q16_16_r if year==2016
replace health_a3_19=. if health_a3_19==0
la var health_a3_19 " Where you admitted to hospital and stayed overnight during the last 12 months?"
la de health_a3_19 1 "Yes" 2 "No" 3 "Don't know"
la val health_a3_19 health_a3_19
note health_a3_19: Question only available for year 2016

gen health_a3_20=s3a_q17_16_r if year==2016
la var health_a3_20 "If yes in health_a3_20: for how many nights did you stay at the hospital?"
note health_a3_20: Question only available for year 2016

gen health_a3_21=s3a_q18_16_r if year==2016
replace health_a3_21=. if inlist(health_a3_21,0,29)
la var health_a3_21 "Reasons (symptom/disease/condition) for hospitalization"
la de health_a3_21 1 "Diarrhoea/Dysentry", add
la de health_a3_21 2 "Fever", add
la de health_a3_21 3 "Pain", add
la de health_a3_21 4 "Injury/Accident", add
la de health_a3_21 5 "Blood pressure", add
la de health_a3_21 6 "Heart disease", add 
la de health_a3_21 7 "Respiratory Diseases/ Asthma/Bronchitis", add
la de health_a3_21 8 "Weakness/Dizziness", add
la de health_a3_21 9 "Pneumonia", add
la de health_a3_21 10 "Tuberculosis", add
la de health_a3_21 11 "Malaria", add
la de health_a3_21 12 "Jaundice", add
la de health_a3_21 13 "Female diseases", add
la de health_a3_21 14 "Pregnancy related", add
la de health_a3_21 15 "Cancer", add
la de health_a3_21 16 "Mental health", add
la de health_a3_21 17 "Paralysis", add
la de health_a3_21 18 "Skin diseases", add
la de health_a3_21 19 "Kidney diseases", add
la de health_a3_21 20 "Liver diseases", add
la de health_a3_21 21 "Ear/ENT problem", add
la de health_a3_21 22 "Eye problem", add
la de health_a3_21 23 "Other", add
la val health_a3_21 health_a3_21
note health_a3_21: Question only available for year 2016

gen health_a3_22=s3a_q319_16_r if year==2016
replace health_a3_22=. if inlist(health_a3_22,0,17)
la var health_a3_22 "Which hospital you were admitted in?"
la de health_a3_22 1  "Govt. Upazila Health Complex", add
la de health_a3_22 2  "Govt. Maternal & Child Welfare Center (MCWC)", add
la de health_a3_22 3  "Gov district/Sadar/General hospital", add
la de health_a3_22 4  "Govt medical college hospital", add
la de health_a3_22 5  "Govt specialized hospital", add
la de health_a3_22 6  "Other Govt hospital (specify)", add
la de health_a3_22 7  "NGO general hospital", add
la de health_a3_22 8  "NGO Medical college hospital", add
la de health_a3_22 9  "NGO specialized hospital", add
la de health_a3_22 10 "Private general hospital/clinic", add
la de health_a3_22 11 "Private medical college hospital", add
la de health_a3_22 12 "Private specialized hospital", add
la de health_a3_22 13 "Other private hospital", add
la val health_a3_22 health_a3_22
note health_a3_22: Question only available for year 2016

gen health_a3_23a= s3a_q20a_16_r if year==2016
la var health_a3_23a "How much did you spent during the past 12 months on operational cost?"
note health_a3_23a: Question only available for year 2016

gen health_a3_23b= s3a_q20b_16_r if year==2016
la var  health_a3_23b "How much did you spent during the past 12 months on consultation/Doctor fees?"
note health_a3_23b: Question only available for year 2016

gen health_a3_23c= s3a_q20c_16_r if year==2016
la var  health_a3_23c "How much did you spent during the past 12 months on bed/cabin charges?"
note health_a3_23c: Question only available for year 2016

gen health_a3_23d= s3a_q20d_16_r if year==2016
la var  health_a3_23d "How much did you spent during the past 12 months on cost of medicines?"
note health_a3_23d: Question only available for year 2016

gen health_a3_23e= s3a_q20e_16_r if year==2016
la var  health_a3_23e "How much did you spent during the past 12 months on cost of investigations?"
note health_a3_23e: Question only available for year 2016

gen health_a3_23f= s3a_q20f_16_r if year==2016
la var  health_a3_23f "How much did you spent during the past 12 months on transport cost?"
note health_a3_23f: Question only available for year 2016

gen health_a3_23g= s3a_q20g_16_r if year==2016
la var  health_a3_23g "How much did you spent during the past 12 months on informal tips?"
note health_a3_23g: Question only available for year 2016

gen health_a3_23h= s3a_q20h_16_r if year==2016
la var  health_a3_23h "How much did you spent during the past 12 months on other formal charges?"
note health_a3_23h: Question only available for year 2016

gen health_a3_23ia=s3a_q20ia_16_r if year==2016
la var  health_a3_23ia "How much did you spent during the past 12 months on maternity cost: Clinic?"
note health_a3_23ia: Question only available for year 2016

gen health_a3_23ib=s3a_q20ib_16_r if year==2016
la var  health_a3_23ib "How much did you spent during the past 12 months on maternity cost: Midwife?"
note health_a3_23ib: Question only available for year 2016

gen health_a3_23ic=s3a_q20ic_16_r if year==2016
la var  health_a3_23ic "How much did you spent during the past 12 months on maternity cost: Others?"
note health_a3_23ic: Question only available for year 2016

gen health_a3_23j=s3a_q20j_16_r if year==2016
la var  health_a3_23j "How much did you spent during the past 12 months on maternity cost: total inpatient Cost?"
note health_a3_23j: Question only available for year 2016

*Next questions are not available for year 2016
gen health_b_1a= s4b_q1a_00_r if year==2000
replace health_b_1a=. if s4b_q1a_00_r==0 & year==2000
replace health_b_1a= s4b_q1a_05_r if year==2005
replace health_b_1a=. if (s4b_q1a_05_r==17 | s4b_q1a_05_r==0) & year==2005
replace health_b_1a= s3b_q1_10_r if year==2010
replace health_b_1a=. if (s3b_q1_10_r==63 | s3b_q1_10_r==0) & year==2010
la var  health_b_1a "when the child was born? (month)"
note health_b_1a: Question not available for year 2016

*Year format is different in each HIES. health_b_1b only shows information for 2010 
gen health_b_1b= s3b_q_1_10_r if year==2010
replace health_b_1b=. if (s3b_q_1_10_r==2908 | s3b_q_1_10_r==0) & year==2010
la var health_b_1b "when the child was born? (year)"
note health_b_1b: Year format is different in each HIES. health_b_1b only shows information for 2010
note health_b_1b: Question not available for year 2016

gen health_b_2= s4b_q2_00_r if year==2000
replace health_b_2= s4b_q2_05_r if year==2005
replace health_b_2= s3b_q2_10_r if year==2010
la var health_b_2 "Present age of child? (in months)"
note health_b_2: Question not available for year 2016

gen health_b_3= s4b_q3_00_r if year==2000
replace health_b_3= s4b_q3_05_r if year==2005
replace health_b_3= s3b_q3_10_r if year==2010
replace health_b_3=. if s3b_q3_10_r==0 & year==2010
la var health_b_3 "has he/she ever been immunized?"
la de lhealth_b_3 1"Yes" 2"No" 3"Don't know"
la val health_b_3 lhealth_b_3
note health_b_3: Question not available for year 2016

gen health_b_4= s4b_q4_00_r if year==2000
replace health_b_4= s4b_q4_05_r if year==2005
replace health_b_4= s3b_q4_10_r if year==2010
replace health_b_4=. if s3b_q4_10_r==0 & year==2010
la var health_b_4 "Do you have immunization card?"
la de lhealth_b_4 1"Yes, card available" 2"No, or card not available"
la values health_b_4 lhealth_b_4
note health_b_4: Question not available for year 2016

gen health_b_5a= s4b_q5a_00_r if year==2000
replace health_b_5a=. if s4b_q5a_00_r==0 & year==2000
replace health_b_5a= s4b_q5a_05_r if year==2005
replace health_b_5a= s3b_q5_10_r if year==2010
replace health_b_5a=. if s3b_q5_10_r==0 & year==2010
la var health_b_5a "BCG immunization"
la de lhealth_b_5a 1"Yes" 2"No"3"Don't know"
la val health_b_5a lhealth_b_5a
note health_b_5a: Question not available for year 2016

gen health_b_5b= s4b_q5b_00_r if year==2000
replace health_b_5b=. if s4b_q5b_00_r==0 & year==2000
replace health_b_5b= s4b_q5b_05_r if year==2005
replace health_b_5b= s3b_q_2_10_r if year==2010
replace health_b_5b=. if s3b_q_2_10_r==0 & year==2010
la var health_b_5b "DPT1 immunization"
la de lhealth_b_5b 1"Yes" 2"No"3"Don't know"
la val health_b_5b lhealth_b_5b
note health_b_5b: Question not available for year 2016

gen health_b_5c= s4b_q5c_00_r if year==2000
replace health_b_5c=. if s4b_q5c_00_r==0 & year==2000
replace health_b_5c= s4b_q5c_05_r if year==2005
replace health_b_5c= s3b_q_3_10_r if year==2010
replace health_b_5c=. if s3b_q_3_10_r==0 & year==2010
la var health_b_5c "DPT2 immunization"
la de lhealth_b_5c 1"Yes" 2"No" 3"Don't know"
la val health_b_5c lhealth_b_5c
note health_b_5c: Question not available for year 2016

gen health_b_5d= s4b_q5d_00_r if year==2000
replace health_b_5d=. if s4b_q5d_00_r==0 & year==2000
replace health_b_5d= s4b_q5d_05_r if year==2005
replace health_b_5d=. if s4b_q5d_05_r==0 & year==2005
replace health_b_5d= s3b_q_4_10_r if year==2010
replace health_b_5d=. if s3b_q_4_10_r==0 & year==2010
la var health_b_5d "DPT3 immunization" 
la de lhealth_b_5d 1"Yes" 2"No"3"Don't know"
la val health_b_5d lhealth_b_5d
note health_b_5d: Question not available for year 2016

gen health_b_5e= s4b_q5e_00_r if year==2000
replace health_b_5e=. if s4b_q5e_00_r==0 & year==2000
replace health_b_5e= s4b_q5e_05_r if year==2005
replace health_b_5e= s3b_q_5_10_r if year==2010
replace health_b_5e=. if s3b_q_5_10_r==0 & year==2010
la var health_b_5e "Polio1 immunization"
la de lhealth_b_5e 1"Yes" 2"No" 3"Don't know"
la val health_b_5e lhealth_b_5e
note health_b_5e: Question not available for year 2016

gen health_b_5f= s4b_q5f_00_r if year==2000
replace health_b_5f=. if s4b_q5f_00_r==0 & year==2000
replace health_b_5f= s4b_q5f_05_r if year==2005
replace health_b_5f= s3b_q_6_10_r if year==2010
replace health_b_5f=. if s3b_q_6_10_r==0 & year==2010
la var health_b_5f "Polio2 immunization"
la de lhealth_b_5f 1"Yes" 2"No"3"Don't know"
la val health_b_5f lhealth_b_5f
note health_b_5f: Question not available for year 2016

gen health_b_5g= s4b_q5g_00_r if year==2000
replace health_b_5g=. if s4b_q5g_00_r==0 & year==2000
replace health_b_5g= s4b_q5g_05_r if year==2005
replace health_b_5g=. if s4b_q5g_05_r==0 & year==2005
replace health_b_5g= s3b_q_7_10_r if year==2010
replace health_b_5g=. if s3b_q_7_10_r==0 & year==2010
la var health_b_5g "Polio3 immunization"
la de lhealth_b_5g 1"Yes" 2"No"3"Don't know"
la val health_b_5g lhealth_b_5g
note health_b_5g: Question not available for year 2016

gen health_b_5h= s4b_q5h_00_r if year==2000
replace health_b_5h=. if s4b_q5h_00_r==0 & year==2000
replace health_b_5h= s4b_q5h_05_r if year==2005
replace health_b_5h=. if s4b_q5h_05_r==0 & year==2005
replace health_b_5h= s3b_q_8_10_r if year==2010
replace health_b_5h=. if s3b_q_8_10_r==0 & year==2010
la var health_b_5h "Measles immunization"
la de lhealth_b_5h 1"Yes" 2"No"3"Don't know"
la val health_b_5h lhealth_b_5h
note health_b_5h: Question not available for year 2016

*Question about "Hepatitis immunization" only available for year 2010
gen health_b_5i=s3b_q_9_10_r if year==2010 
replace health_b_5i=. if (s3b_q_9_10_r==0 | s3b_q_9_10_r==4) & year==2010
la var health_b_5i "Hepatitis immunization"
la de lhealth_b_5i 1"Yes" 2"No"
la val health_b_5i lhealth_b_5i
note health_b_5i:Question about "Hepatitis immunization" only available for year 2010 

gen health_b_6= s4b_q7_00_r if year==2000
replace health_b_6=2 if s4b_q7_00_r==3 & year==2000
replace health_b_6=3 if s4b_q7_00_r==4 & year==2000
replace health_b_6=4 if s4b_q7_00_r==5 & year==2000
replace health_b_6=5 if s4b_q7_00_r==6 & year==2000
replace health_b_6=6 if s4b_q7_00_r==7 & year==2000
replace health_b_6=7 if s4b_q7_00_r==8 & year==2000
replace health_b_6=8 if s4b_q7_00_r==9 & year==2000
replace health_b_6=9 if s4b_q7_00_r==10 & year==2000
replace health_b_6=. if s4b_q7_00_r==0 & year==2000
replace health_b_6= s4b_q7_05_r if year==2005
replace health_b_6= s3b_q6_10_r if year==2010
replace health_b_6=. if s3b_q6_10_r==0 & year==2010
la var health_b_6 "where was most recent immunization?"
la de lhealth_b_6 1"Satellite Clinic" 2"Union health & Family welfare center" 3"Thana health complex"  ///
4"divisionhospital" 5"NGO health center" 6"Private clinic/Hospital/Doctor" 07"Other" ///
8"Govt. health worker" 9"NGO health worker"
la values health_b_6 lhealth_b_6
note health_b_6: Question not available for year 2016

gen health_b_7= s4b_q8_00_r if year==2000
replace health_b_7=. if s4b_q8_00_r==0 & year==2000
replace health_b_7= s4b_q8_05_r if year==2005
replace health_b_7=. if s4b_q8_05_r==0 & year==2005
replace health_b_7= s3b_q7_10_r if year==2010
replace health_b_7=. if (s3b_q7_10_r==0 | s3b_q7_10_r==30) & year==2010
la var health_b_7  "who influenced you to immunize?"
la de lhealth_b_7 1"Self" 2"Friends/Relatives" 3"EPI programme staff" 4"Govt. health worker" 5"NGO health worker" /// 
06"Private practitioner" 7"Radio" 8"Television" 9"Union sub-center" 10"Thana health complex" 11"Hospital"
la values health_b_7 lhealth_b_7
note health_b_7: Question not available for year 2016

*Question only available for year 2010
gen health_b_8= s3b_q8_10_r if year==2010
replace health_b_8=. if s3b_q8_10_r==0 & year==2010 
label var health_b_8 "received vitamin-A capsules in last 12 months?"
la de lhealth_b_8 1"Yes" 2"No"
la values health_b_8 lhealth_b_8
note health_b_8:Question only available for year 2010

*Question only available for years 2000 and 2005
gen health_b_9= s4b_q6_00_r if year==2000
replace health_b_9=s4b_q6_05_r if year==2005
la var health_b_9 "Doses of vaccine received"
note health_b_9:Question only available for years 2000 and 2005 

gen health_c_1= s4c_q1_00_r if year==2000
replace health_c_1= s4c_q1_05_r if year==2005
replace health_c_1= s3c_q1_10_r if year==2010
replace health_c_1=. if (s3c_q1_10_r==0 | s3c_q1_10_r==5) & year==2010
la var health_c_1 "have you ever given birth?"
la de lhealth_c_1 1"Yes" 2"No"
la values health_c_1 lhealth_c_1
note health_c_1: Question not available for year 2016

*Year format is different in each HIES. health_c_2 only shows information for 2010 
gen health_c_2= s3c_q2_10_r if year==2010
replace health_c_2=. if health_c_2==1080 | health_c_2==1195 | health_c_2==2099 | health_c_2==9988
replace health_c_2=. if s3c_q2_10_r==0 & year==2010
la var health_c_2 "In which year did you give birth to your last child?"
note health_c_2: Year format is different in each HIES. health_c_2 only shows information for 2010
note health_c_2: Question not available for year 2016

gen health_c_3= s4c_q3_00_r if year==2000
replace health_c_3= s4c_q3_05_r if year==2005
replace health_c_3= s3c_q3_10_r if year==2010
replace health_c_3=. if (s3c_q3_10_r==0 | s3c_q3_10_r==3 | s3c_q3_10_r==6 | s3c_q3_10_r==7) & year==2010
la var health_c_3 "did you attend prenatal consultations?"
la de lhealth_c_3 1"Yes" 2"No"
la values health_c_3 lhealth_c_3
note health_c_3: Question not available for year 2016

gen health_c_4= s4c_q4_00_r if year==2000
replace health_c_4=2 if s4c_q4_00_r==3 & year==2000
replace health_c_4=3 if s4c_q4_00_r==4 & year==2000
replace health_c_4=4 if s4c_q4_00_r==5 & year==2000
replace health_c_4=5 if s4c_q4_00_r==6 & year==2000
replace health_c_4=6 if s4c_q4_00_r==7 & year==2000
replace health_c_4=7 if s4c_q4_00_r==8 & year==2000
replace health_c_4=8 if s4c_q4_00_r==9 & year==2000
replace health_c_4= s4c_q4_05_r if year==2005
replace health_c_4=. if s4c_q4_05_r==0 & year==2005
replace health_c_4= s3c_q4_10_r if year==2010
replace health_c_4=. if s3c_q4_10_r==0 & year==2010
la var health_c_4 "Where did you first receive this care?"
la de lhealth_c_4 1"Satellite Clinic" 2"Union  health & Family welfare center" 3"Thana health complex" ///
4"divisionhospital" 5"NGO health center" 6"Med. College hospital" 7"Private clinic/Hospital/Doctor" ///
8"Other"
la values health_c_4 lhealth_c_4
note health_c_4: Question not available for year 2016

gen health_c_5= s4c_q5_00_r if year==2000
replace health_c_5= s4c_q5_05_r if year==2005
replace health_c_5= s3c_q5_10_r if year==2010
replace health_c_5=. if s3c_q5_10_r==0 & year==2010
la var health_c_5 "At which month of pregnancy did you go for your first visit?"
note health_c_5: Question not available for year 2016

*For year 2000 question health_c_6 becomes a yes/no question to harmonize with 2010
gen health_c_6= s4c_q6_00_r if year==2000
replace health_c_6=. if s4c_q6_00_r==0 & year==2000
replace health_c_6=1 if (s4c_q6_00_r==3 | s4c_q6_00_r==4 | s4c_q6_00_r==5)  & year==2000
replace health_c_6= s4c_q6_05_r if year==2005
replace health_c_6=. if s4c_q6_05_r==0 & year==2005
replace health_c_6= s3c_q6_10_r if year==2010
replace health_c_6=. if (s3c_q6_10_r==0 | s3c_q6_10_r==4 | s3c_q6_10_r==5 | s3c_q6_10_r==6 ///
| s3c_q6_10_r==7 | s3c_q6_10_r==8) & year==2010
la var health_c_6 "Did you receive a tetanus vaccine?" 
la de lhealth_c_6 1"Yes" 2"No"
la val health_c_6 lhealth_c_6
note health_c_6: For year 2000 question health_c_6 becomes a yes/no question to harmonize with 2010
note health_c_6: Question not available for year 2016

/* Options Midwife(trained) and Midwife(untrained) are combined in years 2005 and 2010
to harmonize with year 2000 */
gen health_c_7= s4c_q7_00_r if year==2000
replace health_c_7=5 if s4c_q7_00_r==4 & year==2000
replace health_c_7=6 if s4c_q7_00_r==5 & year==2000
replace health_c_7=7 if s4c_q7_00_r==6 & year==2000
replace health_c_7= s4c_q7_05_r if year==2005
replace health_c_7=3 if s4c_q7_05_r==4 & year==2005
replace health_c_7= s3c_q7_10_r if year==2010
replace health_c_7=3 if s3c_q7_10_r==4 & year==2010
replace health_c_7=. if s3c_q7_10_r==0 & year==2010
la var health_c_7 "Who assisted with this birth?"
la de lhealth_c_7 1"At home member/relative" 2"Neighbor" 3"Midwife(trained or untrained)" /// 
5"Nurse" 6"Doctor" 7"Other"
la values health_c_7 lhealth_c_7
note health_c_7:Options Midwife(trained) and Midwife(untrained) are combined in years 2005 and 2010 ///
to harmonize with year 2000
note health_c_7: Question not available for year 2016

gen health_c_8= s4c_q8_00_r if year==2000
replace health_c_8=3 if s4c_q8_00_r==4 & year==2000
replace health_c_8=4 if s4c_q8_00_r==5 & year==2000
replace health_c_8=5 if s4c_q8_00_r==6 & year==2000
replace health_c_8=6 if s4c_q8_00_r==7 & year==2000
replace health_c_8=7 if s4c_q8_00_r==8 & year==2000
replace health_c_8=8 if s4c_q8_00_r==9 & year==2000
replace health_c_8=9 if s4c_q8_00_r==10 & year==2000
replace health_c_8= s4c_q8_05_r if year==2005
replace health_c_8= s3c_q8_10_r if year==2010
replace health_c_8=. if s3c_q8_10_r==0 & year==2010
la var health_c_8 "Where did you give birth?"
la de lhealth_c_8 1"At Home" 2"Satellite Clinic" 3"Union  health & Family welfare center" 4"Thana health complex" ///
5"divisionhospital" 6"NGO health center" 7"Med. College hospital" 8"Private clinic/Hospital/Doctor" ///
9"Other"
la values health_c_8 lhealth_c_8
note health_c_8: Question not available for year 2016

gen health_c_9= s4c_q9_00_r if year==2000
replace health_c_9= s4c_q9_05_r if year==2005
replace health_c_9= s3c_q9_10_r if year==2010
replace health_c_9=. if s3c_q9_10_r==0 & year==2010
la var health_c_9 "Did you visit post-natal checkup?"
la de lhealth_c_9 1"Yes" 2"No"
la values health_c_9 lhealth_c_9
note health_c_9: Question not available for year 2016

gen health_c_10= s4c_q10_00_r if year==2000
replace health_c_10=3 if s4c_q10_00_r==4 & year==2000
replace health_c_10=4 if s4c_q10_00_r==5 & year==2000
replace health_c_10=5 if s4c_q10_00_r==6 & year==2000
replace health_c_10=6 if s4c_q10_00_r==7 & year==2000
replace health_c_10=7 if s4c_q10_00_r==8 & year==2000
replace health_c_10=8 if s4c_q10_00_r==9 & year==2000
replace health_c_10=9 if s4c_q10_00_r==10 & year==2000
replace health_c_10= s4c_q10_05_r if year==2005
replace health_c_10=. if s4c_q10_05_r==0 & year==2005
replace health_c_10= s3c_q10_10_r if year==2010
replace health_c_10=. if s3c_q10_10_r==0 & year==2010
la var health_c_10 "Where did you go for checkup?"
la de lhealth_c_10 1"At Home" 2"Satellite Clinic" 3"Union  health & Family welfare center" 4"Thana health complex" ///
5"divisionhospital" 6"NGO health center" 7"Med. College hospital" 8"Private clinic/Hospital/Doctor" ///
9"Other"
la values health_c_10 lhealth_c_10
note health_c_10: Question not available for year 2016

*SUBSECTION HEALTH: DISABILITY, ONLY APPEARS IN 2010 
gen health_d_2 = s3d_q2_10_r if year==2010
replace health_d_2=. if s3d_q2_10_r==0 & year==2010
la var health_d_2 "Difficulty seeing?"
la de lhealth_d_2 1"No Difficulty" 2"Yes, Some Difficulty" 3"Yes, Severe Difficulty" 4"Yes, Can't see"
la values health_d_2 lhealth_d_2
note health_d_2: Question only available for year 2010

gen health_d_3 = s3d_q3_10_r if year==2010
la var health_d_3 "How old was when difficulty began?"
note health_d_3: Question only available for year 2010

gen health_d_4 = s3d_q4_10_r if year==2010
replace health_d_4=. if s3d_q4_10_r==0 & year==2010
la var health_d_4 "What was the cause?"
la de lhealth_d_4 1"From birth" 2"Accident" 3"Illness" 4"Old Age" 5"Malpractice" 6"Other"
la values health_d_4 lhealth_d_4
note health_d_4: Question only available for year 2010

gen health_d_5 = s3d_q5_10_r if year==2010
replace health_d_5=. if s3d_q5_10_r==0 & year==2010
la var health_d_5 "Difficulty hearing?"
la de lhealth_d_5 1"No Difficulty" 2"Yes, Some Difficulty" 3"Yes, Severe Difficulty" 4"Yes, Can't hear"
la values health_d_5 lhealth_d_5
note health_d_5: Question only available for year 2010

gen health_d_6 = s3d_q6_10_r if year==2010
la var health_d_6 "How old was when it began?"
note health_d_6: Question only available for year 2010

gen health_d_7 = s3d_q7_10_r if year==2010
replace health_d_7=. if s3d_q7_10_r==0 & year==2010
la var health_d_7 "What was the cause?"
la de lhealth_d_7 1"From birth" 2"Accident" 3"Illness" 4"Old Age" 5"Malpractice" 6"Other"
la values health_d_7 lhealth_d_7
note health_d_7: Question only available for year 2010

gen health_d_8 = s3d_q8_10_r if year==2010
replace health_d_8=. if s3d_q8_10_r==0 & year==2010 
la var health_d_8 "Difficulty walking?"
la de lhealth_d_8 1"No Difficulty" 2"Yes, Some Difficulty" 3"Yes, Severe Difficulty" 4"Yes, Can't walk"
la values health_d_8 lhealth_d_8
note health_d_8: Question only available for year 2010

gen health_d_9 = s3d_q9_10_r if year==2010
la var health_d_9 "how old was when it began?"
note health_d_9: Question only available for year 2010

gen health_d_10 = s3d_q10_10_r if year==2010
replace health_d_10=. if s3d_q10_10_r==0 & year==2010
la var health_d_10 "What was the cause?"
la de lhealth_d_10 1"From birth" 2"Accident" 3"Illness" 4"Old Age" 5"Malpractice" 6"Other"
la values health_d_10 lhealth_d_10
note health_d_10: Question only available for year 2010

gen health_d_11 = s3d_q11_10_r if year==2010
replace health_d_11=. if s3d_q11_10_r==0 & year==2010
la var health_d_11 "Difficulty remembering?"
la de lhealth_d_11 1"No Difficulty" 2"Yes, Some Difficulty" 3"Yes, Severe Difficulty" 4"Yes, Can't remember"
la values health_d_11 lhealth_d_11
note health_d_11: Question only available for year 2010

gen health_d_12 = s3d_q12_10_r if year==2010
la var health_d_12 "how old was when it began?"
note health_d_12: Question only available for year 2010

gen health_d_13 = s3d_q13_10_r if year==2010
replace health_d_13=. if s3d_q13_10_r==0 & year==2010
la var health_d_13 "What was the cause?"
la de lhealth_d_13 1"From birth" 2"Accident" 3"Illness" 4"Old Age" 5"Malpractice" 6"Other"
la values health_d_13 lhealth_d_13
note health_d_13: Question only available for year 2010

gen health_d_14 = s3d_q14_10_r if year==2010
replace health_d_14=. if s3d_q14_10_r==0 & year==2010 
la var health_d_14 "Difficulty remembering?"
la de lhealth_d_14 1"No Difficulty" 2"Yes, Some Difficulty" 3"Yes, Severe Difficulty" 4"Yes, Can't selfcare"
la values health_d_14 lhealth_d_14
note health_d_14: Question only available for year 2010

gen health_d_15 = s3d_q15_10_r if year==2010
la var health_d_15 "how old was when it began?"
note health_d_15: Question only available for year 2010

gen health_d_16 = s3d_q16_10_r if year==2010
replace health_d_16=. if s3d_q16_10_r==0 & year==2010
la var health_d_16 "What was the cause?"
la de lhealth_d_16 1"From birth" 2"Accident" 3"Illness" 4"Old Age" 5"Malpractice" 6"Other"
la values health_d_16 lhealth_d_16
note health_d_16: Question only available for year 2010

gen health_d_17 = s3d_q17_10_r if year==2010
replace health_d_17=. if s3d_q17_10_r==0 & year==2010
la var health_d_17 "Difficulty in communicating?"
la de lhealth_d_17 1"No Difficulty" 2"Yes, Some Difficulty" 3"Yes, Severe Difficulty" 4"Yes, Can't communicate at all"
la values health_d_17 lhealth_d_17
note health_d_17: Question only available for year 2010

gen health_d_18 = s3d_q18_10_r if year==2010
la var health_d_18 "how old was when it began?"
note health_d_18: Question only available for year 2010

gen health_d_19 = s3d_q19_10_r if year==2010
replace health_d_19=. if s3d_q19_10_r==0 & year==2010
la var health_d_19 "What was the cause?"
la de lhealth_d_19 1"From birth" 2"Accident" 3"Illness" 4"Old Age" 5"Malpractice" 6"Other"
la values health_d_19 lhealth_d_19
note health_d_19: Question only available for year 2010

gen health_d_20a = s3d_q20_10_r if year==2010
replace health_d_20a=. if s3d_q20_10_r==0 &year==2010 
la var health_d_20a "Difficulty reduced work at home?"
la de lhealth_d_20a 1"Yes" 2"No"
la values health_d_20a lhealth_d_20a
note health_d_20a: Question only available for year 2010

gen health_d_20b = s3d_q_1_10_r if year==2010
replace health_d_20b=. if s3d_q_1_10_r==0 & year==2010
la var health_d_20b "Difficulty reduced work at school?"
la de lhealth_d_20b 1"Yes" 2"No"
la values health_d_20b lhealth_d_20b
note health_d_20b: Question only available for year 2010

gen health_d_20c = s3d_q_2_10_r if year==2010
replace health_d_20c=. if s3d_q_2_10_r==0 &year==2010
la var health_d_20c "Difficulty reduced work at work?"
la de lhealth_d_20c 1"Yes" 2"No"
la values health_d_20c lhealth_d_20c
note health_d_20c: Question only available for year 2010

gen health_d_21 = s3d_q21_10_r if year==2010
replace health_d_21=. if s3d_q21_10_r==0 & year==2010
la var health_d_21 "What measures taken to improve?"
la de lhealth_d_21 1"None" 2"Surgical operation" 3"Medication" 4"Assistive devices" 5"Special education" ///
6"Skills training (vocational)" 7"Activity of Daily Living" 8"Counseling" 9"Spiritual/traditional healer" ///
10"Other" 
la values health_d_21 lhealth_d_21
note health_d_21: Question only available for year 2010


/*Drop some observations in 2005 that were only available in this module, but they do not
have poverty or geographical information*/
drop if year==.

compress
saveold "$output/final00_16_individual.dta", replace version(13) 


/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE EMPLOYMENT DATABASE
*                                                                                                    *                                                                                                    *
*****************************************************************************************************/

use employment, clear

gen     indid=indid_00 if year==2000
replace indid=indid_05 if year==2005
replace indid=indid_10 if year==2010
replace indid=indid_16 if year==2016
la var  indid "individual id"

gen activity=     activity_00 if year==2000
replace activity= activity_05 if year==2005
replace activity= activity_10 if year==2010
replace activity= activity_16 if year==2016
la var activity "Activity serial"

gen labor_a_1a= s5a_q1a_00_r if year==2000
replace labor_a_1a= s5a_q1a_05_r if year==2005
replace labor_a_1a= s4a_q1_10_r if year==2010
replace labor_a_1a= s4a_q1a_16_r if year==2016
la var labor_a_1a "What activities did you do? description"

gen labor_a_1b= s5a_q1b_00_r if year==2000
replace labor_a_1b= s5a_q1b_05_r if year==2005
replace labor_a_1b= s4a_q_1_10_r if year==2010
replace labor_a_1b= s4a_q1b_16_r if year==2016
la var labor_a_1b "What activities did you do? occupation code"

gen labor_a_1c= s5a_q1c_00_r if year==2000
replace labor_a_1c= s5a_q1c_05_r if year==2005
replace labor_a_1c= s4a_q_2_10_r if year==2010
replace labor_a_1c= s4a_q1c_16_r if year==2016
replace labor_a_1c=. if inlist(labor_a_1c,0,4,6,8,38,39,42,43,44,46,47,49,54,57,76,83,85,98)
la var labor_a_1c "What activities did you do? industry code"

gen labor_a_2= s5a_q2_00_r if year==2000
replace labor_a_2= s5a_q2_05_r if year==2005
replace labor_a_2= s4a_q2_10_r if year==2010
replace labor_a_2= s4a_q2_16_r if year==2016
replace labor_a_2=. if labor_a_2>12
la var labor_a_2 "How many months did you do this activity in the last 12 months?"

gen labor_a_3= s5a_q3_00_r if year==2000
replace labor_a_3= s5a_q3_05_r if year==2005
replace labor_a_3= s4a_q3_10_r if year==2010
replace labor_a_3=. if inlist(s4a_q3_10_r,36, 39, 50) & year==2010
replace labor_a_3= s4a_q3_16_r if year==2016
la var labor_a_3 "How many days per month did you do this activity?"

gen labor_a_4= s5a_q4_00_r if year==2000
replace labor_a_4= s5a_q4_05_r if year==2005
replace labor_a_4= s4a_q4_10_r if year==2010
replace labor_a_4= s4a_q4_16_r if year==2016
replace labor_a_4=. if labor_a_4>24
la var labor_a_4 "How many hours per day did you do this activity?"

gen labor_a_5a= s5a_q5b_00_r if year==2000
replace labor_a_5a= s5a_q5a_05_r if year==2005
replace labor_a_5a= s4a_q5_10_r if year==2010
replace labor_a_5a= s4a_q5a_16_r if year==2016
replace labor_a_5a=. if inlist(labor_a_5a,0,6,7,9)
la var labor_a_5a "Where did you do this activity? Rural/Urban"
la de  labor_a_5a 1"Rural" 2"Urban"
la values  labor_a_5a  labor_a_5a

gen labor_a_5b= s5a_q5a_00_r if year==2000
replace labor_a_5b= s5a_q5b_05_r if year==2005
replace labor_a_5b=  s4a_q_3_10_r if year==2010
replace labor_a_5b= s4a_q5b_16_r if year==2016
replace labor_a_5b=82 if labor_a_5b==34
la var labor_a_5b "Where did you do this activity? district code"
la val labor_a_5b  district

*Question 6 in year 2000 is not comparable with years 2005, 2010 and 2016
gen labor_a_6= s5a_q6_05_r if year==2005
replace labor_a_6= s4a_q6_10_r if year==2010
replace labor_a_6= s4a_q6_16_r if year==2016
replace labor_a_6=. if inlist(labor_a_6,0,3)
la var labor_a_6 "What kind of activities you engaged in?"
la de  labor_a_6 1"Agriculture" 2"Non Agriculture"
la values  labor_a_6  labor_a_6
note labor_a_6: This question for year 2000 is not comparable with years 2005, 2010 and 2016

gen labor_a_7= s5a_q7_05_r if year==2005
replace labor_a_7=. if s5a_q7_05_r==0 & year==2005 
replace labor_a_7= s4a_q7_10_r if year==2010
replace labor_a_7=. if s4a_q7_10_r==0 & year==2010
replace labor_a_7= s4a_q7_16_r if year==2016
replace labor_a_7=. if inlist(labor_a_7,0,7) & year==2016
la var labor_a_7 " what was your employment status? agricultural Sector"
la de   labor_a_7  1"Day labourer" 2"Self employed" 3"Employer" 4"Employee" 
la values  labor_a_7  labor_a_7

gen labor_a_8= s5a_q8_05_r if year==2005
replace labor_a_8= s4a_q8_10_r if year==2010
replace labor_a_8=. if s4a_q8_10_r==0 & year==2010
replace labor_a_8= s4a_q8_16_r if year==2016
replace labor_a_8=. if inlist(labor_a_8,0,5)
la var labor_a_8 " what was your employment status? Non agriculture Sector"
la de  labor_a_8  1"Day labourer" 2"Self employed" 3"Employer" 4"Employee" 
la values  labor_a_8 labor_a_8    
 
gen labor_b_1= s5b_q1_00_r if year==2000
replace labor_b_1= s5b_q1_05_r if year==2005
replace labor_b_1= s4b_q1_10_r if year==2010
replace labor_b_1=. if s4b_q1_10_r==0 & year==2010
replace labor_b_1= s4b_q1_16_r if year==2016
replace labor_b_1=. if s4b_q1_16_r==0 & year==2016
la var labor_b_1 "were you paid on a daily basis?"
la de  labor_b_1 1"Yes" 2"No"
la val labor_b_1 labor_b_1

/*Question 'What was the daily wage in cash in the past 12 months? Average wage' 
in years 2005 and 2010 was assumed to be the same to 'wage' in question 2 for year 2000*/   
gen labor_b_2a= s5b_q2a_05_r if year==2005
replace labor_b_2a= s4b_q2_10_r if year==2010
replace labor_b_2a= s4b_q2a_16_r if year==2016
la var labor_b_2a "Highest daily wage in cash?"
note labor_b_2a:Question "What was the daily wage in cash in the past 12 months? Average wage" in years 2005 ///
and 2010 was assumed to be the same to "wage" in question 2 for year 2000 

gen labor_b_2b= s5b_q2b_05_r if year==2005
replace labor_b_2b= s4b_q_1_10_r if year==2010
replace labor_b_2b= s4b_q2b_16_r if year==2016
la var labor_b_2b "Lowest daily wage in cash?"

gen labor_b_2c= s5b_q2_00_r if year==2000
replace labor_b_2c= s5b_q2a_05_r if year==2005
replace labor_b_2c= s4b_q_2_10_r if year==2010
replace labor_b_2c= s4b_q2c_16_r if year==2016
la var labor_b_2c "Average daily wage in cash?"

gen labor_b_3= s5b_q3_00_r if year==2000
replace labor_b_3=. if s5b_q3_00_r==0 & year==2000
replace labor_b_3= s5b_q3_05_r if year==2005
replace labor_b_3=. if s5b_q3_05_r==0 & year==2005
replace labor_b_3= s4b_q3_10_r if year==2010
replace labor_b_3=. if s4b_q3_10_r==0 & year==2010
replace labor_b_3= s4b_q3_16_r if year==2016
replace labor_b_3=. if s4b_q3_16_r==0& year==2016
la var labor_b_3 " Did you receive payments in-kind?"
la de  labor_b_3 1"Yes" 2"No"
la val labor_b_3  labor_b_3

gen labor_b_4= s5b_q4_00_r if year==2000
replace labor_b_4=. if s5b_q4_00_r==0 & year==2000
replace labor_b_4= s5b_q4_05_r if year==2005
replace labor_b_4=. if s5b_q4_05_r==0 & year==2005
replace labor_b_4= s4b_q4_10_r if year==2010
replace labor_b_4=. if s4b_q4_10_r==0 & year==2010
replace labor_b_4= s4b_q4_16_r if year==2016
replace labor_b_4=. if s4b_q4_16_r==0 & year==2016
la var labor_b_4 "What type of item received in payment?"
la de  labor_b_4 1"Paddy" 2"Rice" 3"Wheat" 4"Meal" 5"Other"
la val labor_b_4 labor_b_4

gen labor_b_5a= s5b_q5_00_r if year==2000
replace labor_b_5a= s5b_q5a_05_r if year==2005
replace labor_b_5a= s4b_q5_10_r if year==2010
replace labor_b_5a= s4b_q5a_16_r if year==2016
la var labor_b_5a "How much you received per day? Kg"

*Price not available for year 2000         
gen labor_b_5b= s5b_q5b_05_r if year==2005
replace labor_b_5b= s4b_q_3_10_r if year==2010
replace labor_b_5b= s4b_q5b_16_r if year==2016
la var labor_b_5b "How much you received per day? Price (Taka)"
note labor_b_5b:Price not available for year 2000

*Total value not available for year 2000 
gen labor_b_5c=  (s5b_q5a_05_r*s5b_q5b_05_r) if year==2005
replace labor_b_5c= (s4b_q5_10_r*s4b_q_3_10_r) if year==2010
replace labor_b_5c=(s4b_q5a_16_r*s4b_q5b_16_r) if year==2016
la var labor_b_5c "How much you received per day? Total (Taka)"
note labor_b_5c:Total value not available for year 2000 

*Option household not available for year 2000
gen labor_b_6= s5b_q7_00_r if year==2000
replace labor_b_6=9 if s5b_q7_00_r==8 & year==2000 
replace labor_b_6= s5b_q6_05_r if year==2005
replace labor_b_6=. if s5b_q6_05_r==0 & year==2005
replace labor_b_6= s4b_q6_10_r if year==2010
replace labor_b_6=. if s4b_q6_10_r==0 & year==2010
replace labor_b_6= s4b_q6_16_r if year==2016
replace labor_b_6=. if s4b_q6_16_r==0 & year==2016
la var labor_b_6 "What type of org. you work for?"
la de  labor_b_6 1"Govt. organization" 2"Autonomous body" 3"Private office" ///
4"Public mill/ factory" 5"Private mill/ factory" 6"Local govt" 7"NGO" 8"Household" 9"Other"
la val labor_b_6 labor_b_6
note labor_b_6:Option household not available for year 2000 

gen labor_b_7= s5b_q9_00_r if year==2000
replace labor_b_7= s5b_q7_05_r if year==2005
replace labor_b_7= s4b_q7_10_r if year==2010
replace labor_b_7= s4b_q7_16_r if year==2016
la var labor_b_7 "Gross remuneration per month"

gen labor_b_8= s5b_q8_00_r if year==2000
replace labor_b_8= s5b_q8_05_r if year==2005
replace labor_b_8= s4b_q8_10_r if year==2010
replace labor_b_8= s4b_q8_16_r if year==2016
la var labor_b_8 " Net cash/remuneration take-home monthly?"

gen labor_b_9= s5b_q10_00_r if year==2000
replace labor_b_9= s5b_q9_05_r if year==2005
replace labor_b_9= s4b_q9_10_r if year==2010
replace labor_b_9= s4b_q9_16_r if year==2016
la var labor_b_9 "Other benefits you received in last 12 months?"

/* Question did you do this activity under a public work programme? 
only appears in 2000*/
gen labor_b_10= s5b_q6_00_r if year==2000
replace labor_b_10=. if s5b_q6_00_r==0 & year==2000
la var labor_b_10 "Did you do this activity under a public work programme?"
la de llabor_b_10 1"Yes" 2"No" 3"Don't know"
la val labor_b_10 llabor_b_10
note labor_b_10: Question only available for year 2000

compress
saveold "$output/final00_16_employment.dta", replace version(13)  




/*****************************************************************************************************
*                                                                                                    *
                                     * ASSEMBLE HOUSEHOLD DATABASE
*                                                                                                    *
*****************************************************************************************************/

use household, clear

************************************************HOUSING ************************************************

gen housing_a_1=  s6a_q01_10_r if year==2010
replace housing_a_1=s6a_q1_16_r if year==2016
replace housing_a_1=. if housing_a_1==0
la var housing_a_1 "id code of the respondent"
note housing_a_1: Question only available for 2010 and 2016

gen housing_a_2= s2_q1_00_r if year==2000
replace housing_a_2= s2_q1_05_r if year==2005
replace housing_a_2= s6a_q02_10_r if year==2010
replace housing_a_2=s6a_q2_16_r if year==2016
replace housing_a_2=. if inlist(housing_a_2,0,-2)
la var housing_a_2 "How many rooms does your household occupy?"

*This question is not available for year 2000
gen housing_a_3= s2_q2_05_r if year==2005
replace housing_a_3= s6a_q03_10_r if year==2010
replace housing_a_3= s6a_q3_16_r if year==2016
replace housing_a_3=. if inlist(housing_a_3,0,3)
la var housing_a_3 "Does Your dwelling posses a separate dining room?"
la de  housing_a_3 1"Yes" 2"No"
la val housing_a_3 housing_a_3
note housing_a_3:This question is not available for year 2000 

gen housing_a_4a= s2_q2_00_r if year==2000
replace housing_a_4a= s2_q3_05_r if year==2005
replace housing_a_4a= s6a_q04_10_r if year==2010
replace housing_a_4a= s6a_q4_16_r if year==2016
replace housing_a_4a=. if inlist(housing_a_4a,0,3,7)
la var housing_a_4a "Does Your dwelling posses a separate Kitchen?"
la de  housing_a_4a 1"Yes" 2"No"
la val housing_a_4a housing_a_4a

gen housing_a_4b=s6a_q5_16_r if year==2016
replace housing_a_4b=. if s6a_q5_16_r==3 & year==2016
la var housing_a_4b "If yes in housing_a_4a, the dwelling shares this facility with no hh members"
la de  housing_a_4b 1"Yes" 2"No"
la val housing_a_4b housing_a_4b
note housing_a_4b: Question only available for year 2016

gen housing_a_4c=s6a_q6_16_r if year==2016
la var housing_a_4c "What type of stove do you have?"
la de housing_a_4c 1 "Electric",add
la de housing_a_4c 2 "Gas", add
la de housing_a_4c 3 "Own built traditional mud stoves", add
la de housing_a_4c 4 "Improved stove (mud stove purchased/received from NGO)", add
la de housing_a_4c 5 "Concrete stove purchased /received from NGO", add
la de housing_a_4c 6 "Pre-fabricated steel stoves (non-electric & non-gas)", add
la de housing_a_4c 7 "None", add
la val housing_a_4c housing_a_4c
note housing_a_4c: Question only available for year 2016

gen housing_a_5a= s2_q3_00_r if year==2000
replace housing_a_5a= s2_q4_05_r if year==2005
replace housing_a_5a= s6a_q05_10_r if year==2010
la var housing_a_5a "Material of the walls 2000, 2005, 2010"
la de housing_a_5a 1"Brick/cement" 2"C.I. Sheet/wood" 3"Mud brick" 4"Hemp/hay/bamboo" 5"Other"
la val housing_a_5a housing_a_5a

gen housing_a_5b=s6a_q7_16_r if year==2016
replace housing_a_5b=. if housing_a_5b==7
la var housing_a_5b "Material of the walls 2016"
la de housing_a_5b 1 "Straw/Bamboo/ Polythene/Plastic/ Canvas", add
la de housing_a_5b 2 "Mud/Unburnt brick", add
la de housing_a_5b 3 "Tin (CI sheet)", add
la de housing_a_5b 4 "Wood", add
la de housing_a_5b 5 "Brick/Cement", add
la de housing_a_5b 6 "Other (specify)", add
la val housing_a_5b housing_a_5b

gen housing_a_6a= s2_q4_00_r if year==2000
replace housing_a_6a= s2_q5_05_r if year==2005
replace housing_a_6a= s6a_q06_10_r if year==2010
la var housing_a_6a "Material of the roof 2000, 2005, 2010"
la de  housing_a_6 1"Brick/cement"2"C.I. Sheet/wood" 3"Tile/wood" 4"Hemp/hay/bamboo" 5"Other"
la val housing_a_6  housing_a_6

gen housing_a_6b=s6a_q8_16_r if year==2016
replace housing_a_6b=. if inlist(s6a_q8_16_r, 6, 9)
la var housing_a_6b "Material of the roof 2016"
la de housing_a_6b 1 "Straw/Bamboo/Polythene/Plastic/Canvas", add
la de housing_a_6b 2 "Tin (CI sheet)", add
la de housing_a_6b 3 "Tally", add
la de housing_a_6b 4 "Brick/Cement", add
la de housing_a_6b 5 "Other (specify)", add
la val housing_a_6b housing_a_6b

gen housing_a_7= s6a_q07_10_r if year==2010
replace housing_a_7=s6a_q9_16_r if year==2016
la var housing_a_7 "Total usable space (Sq.feet)"
note housing_a_7:Question only available fo years 2010, 2016

*Option "open field" only available for years 2000 and 2005. Option "other" only available in 2010 
gen housing_a_8a= s2_q5_00_r if year==2000
replace housing_a_8a= s2_q6_05_r if year==2005
replace housing_a_8a= s6a_q08_10_r if year==2010
replace housing_a_8a=7 if s6a_q08_10_r==6 & year==2010
replace housing_a_8a= s6a_q10_16_r if year==2016
la var housing_a_8a "Latrine type"
la de  housing_a_8a 1"Sanitary" 2"Pacca latrine (water seal)" 3"Pacca latrine(pit)"4"Kacha latrine (perm)" ///
5"Kacha latrine (temp)" 6"Open field" 7"Other"
la val housing_a_8a housing_a_8a
note housing_a_8a:Option "open field" only available for years 2000 and 2005. Option "other" only available in 2010 

gen housing_a_8b=s6a_q11_16_r if year==2016
replace housing_a_8b=. if inlist(s6a_q11_16_r,3,4,5,6)
la var housing_a_8b "The household shares this toilet facility with other households"
la de housing_a_8b 1 "Yes" 2 "No"
la val housing_a_8b housing_a_8b

gen housing_a_9= s2_q6_00_r if year==2000
replace housing_a_9= s2_q7_05_r if year==2005
replace housing_a_9= s6a_q09_10_r if year==2010
replace housing_a_9= s6a_q12_16_r if year==2016
la var housing_a_9 "Main source of drinking water"
la de  housing_a_9 1"Supply water" 2"Tubewell" 3"Pond/river" 4"Well" 5"Waterfall/string" 6"Other"
la val housing_a_9 housing_a_9

gen housing_a_10= s2_q8_05_r if year==2005
replace housing_a_10= s6a_q10_10_r if year==2010
replace housing_a_10=. if s6a_q10_10_r==0 & year==2010
replace housing_a_10= s6a_q13_16_r if year==2016
replace housing_a_10=. if s6a_q13_16_r==3 & year==2016
la var housing_a_10 "Tubwell tested for arsenic"
la de  housing_a_10 1"Yes" 2"No"
la val housing_a_10 housing_a_10

gen housing_a_11= s2_q9_05_r if year==2005
replace housing_a_11=. if s2_q9_05_r==0 & year==2005 
replace housing_a_11= s6a_q11_10_r if year==2010
replace housing_a_11=. if s6a_q11_10_r==0 & year==2010
replace housing_a_11= s6a_q14_16_r if year==2016
la var housing_a_11 "If yes arsenic found?"
la de  housing_a_11 1"Yes" 2"No"
la val housing_a_11 housing_a_11

gen housing_a_12= s2_q10_05_r if year==2005
replace housing_a_12=. if s2_q10_05_r==0 & year==2005 
replace housing_a_12= s6a_q12_10_r if year==2010
replace housing_a_12=. if s6a_q12_10_r==0 & year==2010
replace housing_a_12= s6a_q12_16_r if year==2016
la var housing_a_12 "If yes alternative source of drinking water?"
la de  housing_a_12 1"Supply water" 2"Tubewell" 3"Pond/river" 4"Well" 5"Waterfall/string" 6"Other"
la val housing_a_12 housing_a_12

gen housing_a_13= s2_q7_00_r if year==2000
replace housing_a_13= s2_q11_05_r if year==2005
replace housing_a_13= s6a_q13_10_r if year==2010
replace housing_a_13=s6a_q16_16_r if year==2016
la var housing_a_13 "Main source of water for other use"
la de  housing_a_13 1"Supply water" 2"Tubewell" 3"Pond/river" 4"Well" 5"Waterfall/string" 6"Other"
la val housing_a_13 housing_a_13

gen housing_a_14= s2_q8_00_r if year==2000
replace housing_a_14= s2_q12_05_r if year==2005
replace housing_a_14= s6a_q14_10_r if year==2010
replace housing_a_14=. if s6a_q14_10_r==0 & year==2010
replace housing_a_14= s6a_q17_16_r if year==2016
replace housing_a_14=. if s6a_q17_16_r==3 & year==2016 
la var  housing_a_14 " Electricity connection"
la de   housing_a_14 1"Yes" 2"No"
la val  housing_a_14 housing_a_14

*Question only available for years 2010, 2016
gen housing_a_15= s6a_q15_10_r if year==2010
replace housing_a_15= s6a_q18_16_r if year==2016
replace housing_a_15=. if inlist(housing_a_15,0,30,32)
la var housing_a_15 "How many hours do you have electicity?"
note housing_a_15:Question only available for years 2010, 2016

gen housing_a_16= s2_q14_05_r if year==2005
replace housing_a_16= s6a_q16_10_r if year==2010
replace housing_a_16=. if s6a_q16_10_r==0 & year==2010
la var housing_a_16 "Does the household own mobile phone?"
la de  housing_a_16 1"Yes" 2"No"
la val housing_a_16 housing_a_16
note housing_a_16: Question not available in this section for year 2016

gen housing_a_17= s2_q13_05_r if year==2005
replace housing_a_17= s6a_q17_10_r if year==2010
replace housing_a_17= s6a_q19_16_r if year==2016
replace housing_a_17=. if inlist(housing_a_17,0,3)
la var housing_a_17 "Does the household have telephone connection?"
la de  housing_a_17 1"Yes" 2"No"
la val housing_a_17  housing_a_17

*Question not available for year 2000
gen housing_a_18= s2_q15_05_r if year==2005
replace housing_a_18= s6a_q18_10_r if year==2010
replace housing_a_18= s6a_q20_16_r if year==2016
replace housing_a_18=. if housing_a_18==0
la var housing_a_18 "Does your household own a computer?"
la de  housing_a_18 1"Yes" 2"No"
la val housing_a_18  housing_a_18
note housing_a_18:Question not available for year 2000

/*(1)Question not available for year 2000.
(2)In 2005 the question only asked about e-mail facility*/
gen housing_a_19= s2_q16_05_r if year==2005
replace housing_a_19= s6a_q19_10_r if year==2010
replace housing_a_19= s6a_q21_16_r if year==2016
replace housing_a_19=. if housing_a_19==0
la var housing_a_19 "Access to internet/e-mail facilities"
la de  housing_a_19 1"Yes" 2"No"
la val housing_a_19 housing_a_18
note housing_a_19: Question not available for year 2000
note housing_a_19: In 2005 the question only asked about e-mail facility 

*Question only available for years 2010, 2016
gen housing_a_20= s6a_q20_10_r if year==2010
replace housing_a_20=. if s6a_q20_10_r==0 & year==2010
replace housing_a_20= s6a_q22_16_r if year==2016
la var housing_a_20 "How does your household members access the internet?"
la de housing_a_20 1"Mobile phone" 2"Home computer" 3"Cybercafe" ///
4"Community information Center" 5"Other"
la val housing_a_20 housing_a_20
note housing_a_20:Question only available for years 2010, 2016

*Option Government residence not available for year 2000
gen housing_a_21a= s2_q11_00_r if year==2000
replace housing_a_21a= 6 if s2_q11_00_r==5 & year==2000
replace housing_a_21a= s2_q18_05_r if year==2005
replace housing_a_21a= s6a_q21_10_r if year==2010
la var housing_a_21a "Present occupancy status 2000, 2005, 2010"
la de  housing_a_21a 1"Owner" 2"Renter"3"Squatter" 4"Provided free by relatives/employer" ///
5"Government residence" 6"Other"
la val housing_a_21a housing_a_21a
note housing_a_21:Option "Government residence" not available for year 2000 

gen housing_a_21b= s6a_q23_16_r if year==2016
replace housing_a_21b=. if housing_a_21b==5
la var housing_a_21b "Present occupancy status 2016" 
la de housing_a_21b 1 "Own" 2 "Rented" 3 "Rent-free"
la val housing_a_21b housing_a_21b

gen housing_a_22= s2_q12_00_r if year==2000 
replace housing_a_22= s2_q19_05_r if year==2005
replace housing_a_22= s6a_q22_10_r if year==2010
replace housing_a_22= s6a_q24_16_r if year==2016
la var housing_a_22 "Dwelling value"

gen housing_a_23= s2_q10_00_r if year==2000
replace housing_a_23= s2_q17_05_r if year==2005
la var housing_a_23 "Dwelling size"
note housing_a_23:Question only available for years 2000 and 2005

gen housing_a_24= s2_q9_00_r if year==2000
replace housing_a_24=1 if s2_q13_05_r==1 | s2_q14_05_r==1 & year==2005
replace housing_a_24=2 if s2_q13_05_r==2 & s2_q14_05_r==2 & year==2005
replace housing_a_24=1 if s6a_q16_10_r==1 | s6a_q17_10_r==1 & year==2010
replace housing_a_24=2 if s6a_q16_10_r==2 & s6a_q17_10_r==2 & year==2010
la var housing_a_24 "Does the household have any telephone or mobile phone?"
la de lhousing_a_24 1"Yes" 2"No"
la val housing_a_24 lhousing_a_24
note housing_a_24: Mobile phone information is not available in this section for year 2016

gen housing_a_25= s6a_q25_16_r if year==2016
la var housing_a_25 "is this a slum household?"
la de housing_a_25 1 "Yes" 2"No"
la val housing_a_25 housing_a_25

************************OTHER ASSETS AND INCOME*********************************

gen oincome_a_1a = s8a_q1_00_r if year==2000
replace oincome_a_1a= s8a_q1_05_r if year==2005
replace oincome_a_1a= s8a_q01_10_r if year==2010
replace oincome_a_1a=. if s8a_q01_10_r==0 & year==2010
replace oincome_a_1a=   s8a_q1a_16_r if year==2016
replace oincome_a_1a=. if s8a_q1a_16_r==0 & year==2016
la var oincome_a_1a "Any land or property which your household owns but doesn't operate?"
la de  oincome_a_1a 1"Yes" 2"No"
la val oincome_a_1a oincome_a_1a

*Question only available for years 2010, 2016
*Variable in 2010 is converted to acres (1 decimal=1/100 acre)
gen oincome_a_1b=(s8a_q_1_10_r/100) if year==2010
replace oincome_a_1b= s8a_q1b_16_r if year==2016
la var oincome_a_1b "Amount of unused land? acres"
note oincome_a_1b: Question only available for years 2010, 2016

gen oincome_a_2 = s8a_q2_00_r if year==2000
replace oincome_a_2= s8a_q2_05_r if year==2005
replace oincome_a_2= s8a_q02_10_r if year==2010
replace oincome_a_2= s8a_q2_16_r if year==2016
la var oincome_a_2 "Present price of your own land"

gen oincome_a_3 = s8a_q3_00_r if year==2000
replace oincome_a_3= s8a_q3_05_r if year==2005
replace oincome_a_3=. if s8a_q3_05_r==0 & year==2005
replace oincome_a_3= s8a_q03_10_r if year==2010
replace oincome_a_3=. if s8a_q03_10_r==0 & year==2010
replace oincome_a_3= s8a_q3_16_r if year==2016
replace oincome_a_3=. if s8a_q3_16_r==0 & year==2016
la var oincome_a_3 "Did your household purchase any land or property in last 12 months?"
la de  oincome_a_3 1"Yes" 2"No"
la val oincome_a_3 oincome_a_3

gen oincome_a_4 = s8a_q4_00_r if year==2000
replace oincome_a_4= s8a_q4_05_r if year==2005
replace oincome_a_4= s8a_q04_10_r if year==2010
replace oincome_a_4= s8a_q4_16_r if year==2016
la var oincome_a_4 "Cost of purchasing this land or property"

*Questions from 5 to 12 are not comparable with questions in year 2000
gen oincome_a_5 = s8a_q5_05_r if year==2005
replace oincome_a_5= s8a_q05_10_r if year==2010
replace oincome_a_5=. if s8a_q05_10_r==0 & year==2010
replace oincome_a_5= s8a_q5_16_r if year==2016
replace oincome_a_5=. if s8a_q5_16_r==0 & year==2016
la var oincome_a_5 "Did your household purchase any house or flat?"
la de  oincome_a_5 1"Yes" 2"No"
la val oincome_a_5 oincome_a_5

gen oincome_a_6 = s8a_q6_05_r if year==2005
replace oincome_a_6= s8a_q06_10_r if year==2010
replace oincome_a_6= s8a_q6_16_r if year==2016
la var oincome_a_6 "Cost of purchasing this house or flat"

gen oincome_a_7 = s8a_q7_00_r if year==2000
replace oincome_a_7 = s8a_q7_05_r if year==2005
replace oincome_a_7= s8a_q07_10_r if year==2010
replace oincome_a_7=. if s8a_q07_10_r==0 & year==2010
replace oincome_a_7= s8a_q7_16_r if year==2016
replace oincome_a_7=. if inlist(s8a_q7_16_r,0,5) & year==2016
la var oincome_a_7 "Does your household own any other assets?"
la de loincome_a_7 1"Yes" 2"No"
la val oincome_a_7 loincome_a_7

gen oincome_a_8 = s8a_q8_00_r if year==2000
replace oincome_a_8 = s8a_q8_05_r if year==2005
replace oincome_a_8= s8a_q08_10_r if year==2010
replace oincome_a_8= s8a_q8_16_r if year==2016
la var oincome_a_8 "What is the total value of these assets?"

gen oincome_a_9 = s8a_q9_05_r if year==2005
replace oincome_a_9= s8a_q09_10_r if year==2010
replace oincome_a_9= s8a_q9_16_r if year==2016
replace oincome_a_9=. if oincome_a_9==0
la var oincome_a_9 "Did your household purchase any assets other than land?"
la de loincome_a_9 1"Yes" 2"No"
la val oincome_a_9 loincome_a_9

gen oincome_a_10 = s8a_q10_05_r if year==2005
replace oincome_a_10= s8a_q10_10_r if year==2010
replace oincome_a_10= s8a_q10_16_r if year==2016
la var oincome_a_10 "How much did your household spend on purchasing these assets?"

gen oincome_a_11 = s8a_q11_05_r if year==2005
replace oincome_a_11= s8a_q11_10_r if year==2010
replace oincome_a_11=. if s8a_q11_10_r==0 & year==2010
replace oincome_a_11= s8a_q11_16_r if year==2016
replace oincome_a_11=. if s8a_q11_16_r==0 & year==2016
la var oincome_a_11 "Did your household sell any assets?"
la de loincome_a_11 1"Yes" 2"No"
la val oincome_a_11 loincome_a_11

gen oincome_a_12 = s8a_q12_05_r if year==2005
replace oincome_a_12= s8a_q12_10_r if year==2010
replace oincome_a_12= s8a_q12_16_r if year==2016
la var oincome_a_12 "How much did your household get from selling these assets?"

gen oincome_b_1 = s8b_q1_00_r if year==2000
replace oincome_b_1 = s8b_q1_05_r if year==2005
replace oincome_b_1= s8b_q01_10_r if year==2010
replace oincome_b_1= s8b_q1_16_r if year==2016
la var oincome_b_1 "Income from rent of land"

gen oincome_b_2 = s8b_q2_00_r if year==2000
replace oincome_b_2 = s8b_q2_05_r if year==2005
replace oincome_b_2= s8b_q02_10_r if year==2010
replace oincome_b_2= s8b_q2_16_r if year==2016
la var oincome_b_2 "Income from rent of other property"

gen oincome_b_3a = s8b_q3a_05_r if year==2005
replace oincome_b_3a= s8b_q03_10_r if year==2010
replace oincome_b_3a= s8b_q3a_16_r if year==2016
la var oincome_b_3a "Income from Life insurance"

gen oincome_b_3b = s8b_q3b_05_r if year==2005
replace oincome_b_3b= s8b_q_1_10_r if year==2010
replace oincome_b_3b= s8b_q3b_16_r if year==2016
la var oincome_b_3b "Income from Health insurance"

gen oincome_b_3c = s8b_q3b_05_r if year==2005
replace oincome_b_3c= s8b_q_2_10_r if year==2010
replace oincome_b_3c= s8b_q3c_16_r if year==2016
la var oincome_b_3c "Income from General insurance"

gen oincome_b_4 = s8b_q4_00_r if year==2000
replace oincome_b_4 = s8b_q4_05_r if year==2005
replace oincome_b_4= s8b_q04_10_r if year==2010
replace oincome_b_4= s8b_q4_16_r if year==2016
la var oincome_b_4 "Profit and dividend received"

gen oincome_b_5 = s8b_q5_00_r if year==2000
replace oincome_b_5 = s8b_q5_05_r if year==2005
replace oincome_b_5= s8b_q05_10_r if year==2010
replace oincome_b_5= s8b_q5_16_r if year==2016
la var oincome_b_5 "Lottery or similary income in cash or in-kind"

gen oincome_b_6 = s8b_q6_00_r if year==2000
replace oincome_b_6 = s8b_q6_05_r if year==2005
replace oincome_b_6= s8b_q06_10_r if year==2010
replace oincome_b_6= s8b_q6_16_r if year==2016
la var oincome_b_6 "Gift, Charity or other received? In cash"

gen oincome_b_7 = s8b_q7_00_r if year==2000
replace oincome_b_7 = s8b_q7_05_r if year==2005
replace oincome_b_7= s8b_q07_10_r if year==2010
replace oincome_b_7= s8b_q7_16_r if year==2016
la var oincome_b_7 "Gift, Charity or other received? In Kind"

gen oincome_b_8 = s8b_q8_00_r if year==2000
replace oincome_b_8 = s8b_q8_05_r if year==2005
replace oincome_b_8= s8b_q08_10_r if year==2010
replace oincome_b_8= s8b_q8_16_r if year==2016
la var oincome_b_8 "Remittances received from within the country"

gen oincome_b_9 = s8b_q9_00_r if year==2000
replace oincome_b_9 = s8b_q9_05_r if year==2005
replace oincome_b_9= s8b_q09_10_r if year==2010
replace oincome_b_9= s8b_q9_16_r if year==2016
la var oincome_b_9 "Remittances received from outside the country"

*Question only available for years 2010, 2016
gen oincome_b_10 = s8b_q10_10_r if year==2010
replace oincome_b_10=. if s8b_q10_10_r==0 & year==2010
replace oincome_b_10= s8b_q10_16_r if year==2016
replace oincome_b_10=. if s8b_q10_16_r==0 & year==2016
la var oincome_b_10 "where did you invest/spend the received money?"
la de  oincome_b_10 1"Construction"  2"Business" 3"Education" 4"Marriage"  ///
5"Consumption" 6"Treatment" 7"Other"
la val oincome_b_10 oincome_b_10
note oincome_b_10: Question only available for years 2010, 2016

gen oincome_b_11 = s8b_q10_00_r if year==2000
replace oincome_b_11 = s8b_q10_05_r if year==2005
replace oincome_b_11= s8b_q11_10_r if year==2010
replace oincome_b_11= s8b_q11_16_r if year==2016
la var oincome_b_11 "Pension, Gratuity, other benefit received"

gen oincome_b_12 = s8b_q11_00_r if year==2000
replace oincome_b_12 = s8b_q11_05_r if year==2005
replace oincome_b_12= s8b_q12_10_r if year==2010
replace oincome_b_12= s8b_q12_16_r if year==2016
la var oincome_b_12 "Interest received during the past 12 months"

gen oincome_b_13= s8b_q11_00_r if year==2000
replace oincome_b_13= s8b_q11_05_r if year==2005
replace oincome_b_13= s8b_q13_10_r if year==2010
replace oincome_b_13= s8b_q13_16_r if year==2016
la var oincome_b_13 "Other cash or in-kind received during the past 12 months"

*Questions "oincome_b_14" only available for year 2000
gen oincome_b_14a= s8b_q13dw_00_r if year==2000
la var oincome_b_14a "Wheat received from the programme VGD in the last 12 months (Kg)"
note oincome_b_14a: Question only available for year 2000

gen oincome_b_14b= s8b_q13dr_00_r if year==2000
la var oincome_b_14b "Rice received from the programme VGD in the last 12 months (Kg)"
note oincome_b_14b: Question only available for year 2000

gen oincome_b_14c= s8b_q13fw_00_r if year==2000
la var oincome_b_14c "Wheat received from the programme VGF in the last 12 months (Kg)"
note oincome_b_14c: Question only available for year 2000

gen oincome_b_14d= s8b_q13fr_00_r if year==2000
la var oincome_b_14d "Rice received from the programme VGF in the last 12 months (Kg)"
note oincome_b_14d: Question only available for year 2000

gen oincome_b_14e= s8b_q13gw_00_r if year==2000
la var oincome_b_14e "Wheat received from the programme GR in the last 12 months (Kg)"
note oincome_b_14e: Question only available for year 2000

gen oincome_b_14f= s8b_q13gr_00_r if year==2000
la var oincome_b_14f "Rice received from the programme GR in the last 12 months (Kg)"
note oincome_b_14f: Question only available for year 2000

gen oincome_b_14g= s8b_q13ew_00_r if year==2000
la var oincome_b_14g "Wheat received from the programme FFE in the last 12 months (Kg)"
note oincome_b_14g: Question only available for year 2000

gen oincome_b_14h= s8b_q13er_00_r if year==2000
la var oincome_b_14h "Rice received from the programme FFE in the last 12 months (Kg)"
note oincome_b_14h: Question only available for year 2000

*SUBSECTION OTHER ASSETS AND INCOME:MIGRATION AND REMITTANCE, ONLY AVAILABLE IN 2010 and 2016
gen migr_1=s8c_q01_10_r if year==2010
replace migr_1=. if s8c_q01_10_r==0 & year==2010
replace migr_1=s8c_q1_16_r if year==2016
replace migr_1=. if inlist(migr_1, 0)
la var migr_1 "Has any member of household migrated during the last 5 years?"
la de lmigr_1 1"Yes" 2"No"
la val migr_1 lmigr_1
note migr_1: Question only available for years 2010, 2016

gen migr_2=s8c_q02_10_r if year==2010
replace migr_2=s8c_q2_16_r if year==2016
replace migr_2=. if migr_2==0
la var migr_2 "Household received remittances from outside?"
la de lmigr_2 1"Yes" 2"No"
la val migr_2 lmigr_2
note migr_2: Question only available for years 2010, 2016


*SUBSECTION OTHER ASSETS AND INCOME: MICRO CREDIT, ONLY AVAILABLE IN 2010, 2016
gen oincome_d_1=s8d_q01_10_r if year==2010
replace oincome_d_1=. if s8d_q01_10_r==0 & year==2010
replace oincome_d_1= s8d1_q1_16_r if year==2016
la var oincome_d_1 "Any member opened bank account?"
la de loincome_d_1 1"Yes" 2"No"
la val oincome_d_1 loincome_d_1
note oincome_d_1: Question only available for years 2010, 2016

gen oincome_d_2=s8d_q02_10_r if year==2010
replace oincome_d_2= s8d1_q2_16_r if year==2016
replace oincome_d_2=. if inlist(oincome_d_2,0,3)
la var oincome_d_2 "Any member deposited money in the credit or microfinance institution"
la de loincome_d_2 1"Yes" 2"No"
la val oincome_d_2 loincome_d_2
note oincome_d_2: Question only available for years 2010, 2016

gen oincome_d_3=s8d_q03_10_r if year==2010
replace oincome_d_3=. if s8d_q03_10_r==0 & year==2010
replace oincome_d_3= s8d1_q3_16_r if year==2016
la var oincome_d_3 "Any member deposited in informal depositor organisation?"
la de loincome_d_3 1"Yes" 2"No"
la val oincome_d_3 loincome_d_3
note oincome_d_3: Question only available for years 2010, 2016

gen oincome_d_4=s8d_q04_10_r if year==2010
replace oincome_d_4= s8d1_q4_16_r if year==2016
replace oincome_d_4=. if oincome_d_4==0
la var oincome_d_4 "Any member borrowed money from a family member, friend, or other source in the last 12 months"
la de loincome_d_4 1"Yes" 2"No"
la val oincome_d_4 loincome_d_4
note oincome_d_4: Question only available for years 2010, 2016


************************AGRICULTURE:LANDHOLDING*********************************
*NOTE: Negative values of acres converted to positive
 
*Variables in 2010 are converted to acres (1 decimal=1/100 acre)
gen agri_a_1= s7a_q1_00_r if year==2000
replace agri_a_1= s7_q1_05_r if year==2005
replace agri_a_1=(s7a_q01_10_r/100) if year==2010
replace agri_a_1= s7a_q1_16_r if year==2016
*fix negatives
replace agri_a_1=-agri_a_1 if agri_a_1<0
*replace missing with 0
replace agri_a_1=0 if agri_a_1==.
la var agri_a_1 "Cultivable land owned (acres)"
note agri_a_1: Missing values replaced with zero (just for 2000 the proportion of missing was hi)


*Question not available for year 2000
gen agri_a_2= s7_q21_05_r if year==2005
replace agri_a_2=(s7a_q02_10_r/100) if year==2010
replace agri_a_2= s7a_q2_16_r if year==2016
replace agri_a_2=-agri_a_2 if agri_a_2<0
la var agri_a_2 "Total dwelling-house/Homested land owned (acres)"
note agri_a_2:Question not available for year 2000

*Question only available for years 2010, 2016
gen agri_a_3= (s7a_q03_10_r /100) if year==2010
replace agri_a_3= s7a_q3_16_r if year==2016
replace agri_a_3=-agri_a_3 if agri_a_3<0
la var agri_a_3 "Total Non-cultivated Land (acres)"
note agri_a_3:Question only available for years 2010, 2016

gen agri_a_4= s7a_q2_00_r if year==2000
replace agri_a_4= s7_q3_05_r if year==2005
replace agri_a_4=(s7a_q04_10_r/100) if year==2010
replace agri_a_4= s7a_q4_16_r if year==2016
replace agri_a_4=-agri_a_4 if agri_a_4<0
la var agri_a_4 "Agricultural land rented/ share-cropped/ mortgaged in (acres)"

gen agri_a_5= s7a_q3_00_r if year==2000
replace agri_a_5= s7_q4_05_r if year==2005
replace agri_a_5=(s7a_q05_10_r/100) if year==2010
replace agri_a_5= s7a_q5_16_r if year==2016
replace agri_a_5=-agri_a_5 if agri_a_5<0
la var agri_a_5 "Agricultural land rented/ share-cropped/ mortgaged out (acres)"

*Question only available for years 2010, 2016
gen agri_a_6= (s7a_q06_10_r /100) if year==2010
replace agri_a_6= s7a_q6_16_r if year==2016
replace agri_a_6=-agri_a_6 if agri_a_6<0
la var agri_a_6 "Total operating land (acres)"
note agri_a_6:Question only available for years 2010, 2016

*Question only available for years 2000 and 2005
gen agri_a_7= s7a_q4_00_r if year==2000
replace agri_a_7= s7_q6_05_r if year==2005
replace agri_a_7=. if s7_q6_05_r==0 & year==2005
la var agri_a_7 "What is the quality of your land?"
la de lagri_a_7  1"Better than average" 2"Average" 3"Poorer than average" 4"Much poorer than average"
la val agri_a_7 lagri_a_7
note agri_a_7: Question only available for years 2000 and 2005

*Next question is only available for year 2010, for 2016 is in a different section
gen agri_b_1 = s7b_q01_10_r if year==2010
replace agri_b_1=. if s7b_q01_10_r==0 & year==2010
la var agri_b_1 "Did any household member cultivate any crop in the last 12 months?"
la de lagri_b_1 1"Yes" 2"No"
la val agri_b_1 lagri_b_1
note agri_b_1: Question only available for year 2010 

*Next questions are only available for years 2010 and 2016
gen agri_c_1 = s7c_q01_10_r if year==2010
replace agri_c_1=s7c1_q1_16_r if year==2016
replace agri_c_1=. if agri_c_1==0
la var agri_c_1 "Did any household member raise any livestock or poultry birds in the last 12 months?"
la de lagri_c_1 1"Yes" 2"No"
la val agri_c_1 lagri_c_1
note agri_c_1: Question only available for years 2010, 2016

gen agri_c_9 = s7c_q09_10_r if year==2010
replace agri_c_9=. if s7c_q09_10_r==0 & year==2010
replace agri_c_9= s7c3_q9_16_r if year==2016
la var agri_c_9 "Did any household member engage in any fishing in the last 12 months?"
la de lagri_c_9 1"Yes" 2"No"
la val agri_c_9 lagri_c_9
note agri_c_9: Question only available for year 2010

gen agri_c_13 = s7c_q13_10_r if year==2010
replace agri_c_13=. if s7c_q13_10_r==0 & year==2010
replace agri_c_13= s7c4_q13_16_r if year==2016
replace agri_c_13=. if inlist(agri_c_13,0)
la var agri_c_13 "Did any household member engage in any farm forestry in the last 12 months?"
la de lagri_c_13 1"Yes" 2"No"
la val agri_c_13 lagri_c_13
note agri_c_13: Question only available for years 2010, 2016

compress
saveold "$output/final00_16_household.dta", replace version(13) 


*****Erase temporary files
loc files="individual enterprise employment household agriculture food1 food2 food3 monthlynfood annualnfood durable"

foreach file of loc files {
foreach num of numlist 2000 2005 2010 2016 {
cap erase "`file'`num'.dta"
}
}

loc files="individual enterprise employment household agriculture food1 food2 food3 monthlynfood annualnfood durable"

foreach file of loc files {
cap erase "`file'`num'.dta"
}

foreach file in microcredit migration {
foreach num of numlist 2010 2016 {
cap erase "`file'`num'.dta"
}
}

foreach file in microcredit migration {
cap erase "`file'.dta"
}

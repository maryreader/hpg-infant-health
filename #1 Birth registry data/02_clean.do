********************************************************************************
****************** ONS02: Clean birth registry data ****************************
********************************************************************************

clear all
set more off 
capture log close 

**** Clean geographical index of income deprivation data ***********************
import delim "$raw/ONSPD_MAY_2020_UK.csv"

gen str8 postcode = subinstr(pcd," ","",.) 

keep postcode lsoa01 lsoa11 ctry rgn 

save "$clean/postcode_to_geog_2020_cumulative", replace 

/* LSOA to deprivation: England and Wales */
import delim "$raw/income_deprivation.csv", clear

rename lsoacode2011 lsoa11

keep lsoa11 income* idaci* 

save "$clean/lsoa_to_deprivation", replace 

**** Combine admin birth registry data, 2006-2014 ******************************
use "$raw/births2006", clear
append using "$raw/births2007"
append using "$raw/births2008"
append using "$raw/births2009"
append using "$raw/births2010"
append using "$raw/births2011"
append using "$raw/births2012"
append using "$raw/births2013"
append using "$raw/births2014"

replace vmlid=VMLID if missing(vmlid)
drop VMLID

rename *, lower 

sort dob
order dob birthwgt agebm gestatn sbind multbth multtype pcdrm prevch prevchl prchsind prevchs

label var agebf "Age of father at birth"
label var agebm "Age of mother at birth"
label var birthwgt "Birth weight"
label var dob "Date of birth of child"
label var empsecf "Employment status of father"
label var empsecm "Employment status of mother"
label var multbth "Multiple birth"
label var multtype "Multiple birth type" 
label var pcdrm "Postcode of residence of mother" 
label var prchsind "Previous stillbirth indicator" 
label var prevchs "Previous stillbirths" 
label var sbind "Stillbirth" 
label var seccatf "NSSEC operation category of father"
label var seccatm "NSSEC operation category of mother"
label var secclrf "NSSEC analytical category of father"
label var secclrm "NSSEC analytical category of mother"
label var sex "Sex of child"
label var soc2kf "Occupation of father"
label var soc2km "Occupation of mother" 
label var gestatn "Gestation for stillbirths"
label var i10p001 "Cause of death information Original 1"
label var cr10001 "Row number 1 for original cause of death mention"
label var bthimar "Marital status/Registration type"
label var agebmind "Age of mother at birth indicator" 
label var agebfind "Age of father at birth indicator" 
label var dommind "Month of marriage imputation indicator"
label var esttypeb "Establishment type when birth occurred" 
label var nhsind "NHS Establishment indicator" 
label var prevch "Previous births" 
label var prevchl "Previous live births" 
label var mattab "Maternity selection indicator" 
label var cr10001 "Row number 1 for original cause of death mention" 
label var ctrypobf "Country of birth of father" 
label var ctrypobm "Country of birth of mother" 
label var deathlab "Death in labour indicator for stillbirths" 
label var dobf "Date of birth of father"
label var dobm "Date of bith of mother" 
label var domyind "Year of marriage imputation indicator" 
label var dor "Date of registration"  
label var durmar "Duration of marriage" 
label var fic10ind "Final cause of death indicator" 
label var cestrss "Communal establishment code" 
label var agemf "Age of father at marriage"
label var agemm "Age of mother at marriage" 
label var prchlind "Previous live birth indicator" 
label var pind "Second female parent indicator" 
label var docon "Date of conception" 
label var ctryrm "Country of usual residence of mother" 
label var domym "Date of marriage year and month" 
label var pcdpob "Postcode of place of birth" 
label var postmort "Postmortem indicator" 
label var bwigs10 "Wigglesworth code" 
label var tbthtm "Total births to mother" 
label var multmar "Multiple marriage indicator" 

rename gestatn geststill

**** Clean variables of interest ***********************************************

/* Create postcode variable */ 
* Postcode of mother's residence
gen str8 postcode = subinstr(pcdrm," ","",.) 
* If missing, replace with postcode of place of birth
replace postcode = subinstr(pcdpob," ","",.) if postcode==""

/* Check missingness */ 
count if postcode==""

/* Merge with LSOA and geographical data */
merge m:1 postcode using "$clean/postcode_to_geog_2020_cumulative", keep(match master)

/* Label England and Wales */
gen country="England" if ctry=="E92000001"
replace country="Wales" if ctry=="W92000004"
replace country="Scotland" if ctry=="S92000003"
replace country="Northern Ireland" if ctry=="N92000002"
label var country "Country of mother's residence"

/* Merge with combined England & Wales deprivation data from 2015-16 */
merge m:1 lsoa11 using "$clean/lsoa_to_deprivation", keep(match master) gen(merge_imd)
tab merge_imd country // check unmatched are NI/Scot 
rename incomedomainscore incscore 
label var incscore "Index of income deprivation"

/* Baby's date of birth */ 
destring dob, gen(DOB)
gen str4 dxyr=substr(dob,1,4)
gen str2 dxmo=substr(dob,5,6)
gen str2 dxda=substr(dob,7,8)
destring dx*, replace
gen Date_of_Birth=mdy(dxmo,dxda,dxyr)
format Date_of_Birth %d
drop dob 
rename Date_of_Birth dob
label var dob "Date of birth"
sort DOB

/* Create a centred date of birth variable around treatment cut-off */
gen centred_dob=dob-17993

/* Centred week of birth */ 
gen centred_wob=wofd(centred_dob)

/* Mother's date of birth */
gen str8 mdob = subinstr(dobm,"/","",.) 
gen str2 dmda=substr(mdob,1,2)
gen str2 dmmo=substr(mdob,3,4)
gen str4 dmyr=substr(mdob,5,8)
destring dm*, replace force
gen dom = mdy(dmmo,dmda,dmyr)
format dom %d
drop mdob dobm
rename dom mdob
label var mdob "Mother's date of birth"

gen age = dob-mdob
replace age = age/365
label var age "Maternal age (years)"

/* Father's date of birth */ 
gen str8 fdob=subinstr(dobf,"/","",.)
gen str2 dfda=substr(fdob,1,2)
gen str2 dfmo=substr(fdob,3,4)
gen str4 dfyr=substr(fdob,5,8)
destring df*, replace force 
gen dof=mdy(dfmo,dfda,dfyr)
format dof %d
drop fdob dobf
rename dof fdob
label var fdob "Father's date of birth"

/* Teenage pregnancy dummy */
gen teen = (age<20) if age!=.
label var teen "Teenage mother"

/* Advanced maternal age dummy */
gen old = (age>=35) if age!=.
label var old "Advanced maternal age (>=35 years)"

/* Sex of the baby */
destring sex, replace
codebook sex, t(100)
gen female=(sex==2) if sex!=.
label var female "Female baby"

/* Stillbirth status */ 
destring sbind, replace
tab sbind, mi 
recode sbind (.=0)

/* Multiple  birth status */
destring multbth, replace
tab multbth
recode multbth (.=0)

/* Type of birth registration */ 
codebook bthimar, t(100)
label define reg 1 "Within marriage/civil partnership" ///
2 "Outside marriage/civil partnership, sole registration" ///
3 "Outside marriage/civil partnership, joint registration, parents same address" ///
4 "Outside marriage/civil partnership, joint registration, parents different address"

/* Single parent dummy - based on sole registration and/or different address */ 
destring bthimar, replace
gen lone=(inlist(bthimar,2,4))
label var lone "Single parent"

/* NHS hospital flag */ 
codebook nhsind, t(100)
destring nhsind, replace
gen nhs_estab = 0 
replace nhs_estab=1 if nhsind==1
label var nhs_estab "Born in a NHS hospital"

/* Socio-economic status/NS-SEC occupation: coded for a random 10% sample */ 
/* coding:
11 Large employers and higher managerial occupations
12 Higher professional occupations
20 Lower managerial and professional occupations
30 Intermediate occupations
40 Small employers and own-account workers
50 Lower supervisory and technical occupations-----
60 Semi-routine occupations
70 Routine occupations
80 Never worked and long-term unemployed
90 Full-time students
91 Occupations not stated or inadequately described
92 Not classifiable for other reasons*/ 

/* Father's occupation */ 
destring secclrf, replace
recode secclrf (22=.) (39=.) (91=.) (92=.)
/* Mother's NS-SEC */
destring secclrm, replace
recode secclrm (91=.) (92=.)

/* Create combined SES */
gen combined_sc = min(secclrf, secclrm)
label var combined_sc "Combined socio-economic status (NS-SEC)"

/* Create NS-SEC 5-8 dummy variable */
gen lower_sc = 1 if inlist(combined_sc,50,60,70,80)
replace lower_sc = 0 if inlist(combined_sc,11,12,20,30,40)  
label var lower_sc "Lower socio-economic status (SES)"

/* Health in Pregnancy Grant ITT variable: all DOBs between 6 April 2009
and 16 April 2011 inclusive */ 
gen hpg_dob=(DOB>=20090406&DOB<=20110416) if DOB!=.
label var hpg_dob "Eligible for HPG"

gen hpg_wob=(centred_wob>=0 & centred_wob<=105) if centred_wob!=. 
label var hpg_wob "Eligible for HPG"

/* Create parametric versions of DOB */
gen interact_dob=(hpg_dob*centred_dob)
gen centred_dob2=(centred_dob^2)
gen quad_interact_dob=(interact_dob*centred_dob)
gen centred_dob3=(centred_dob2*centred_dob)
gen cube_interact_dob=(quad_interact_dob*centred_dob)

/* Day of the week FE */ 
gen dow = dow(mdy(dxmo,dxda,dxyr)) 
label var dow "Day of the week"
label define days 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" ///
4 "Thursday" 5 "Friday" 6 "Saturday"
label values dow days 
codebook dow, t(100)

gen sunday = (dow==0) 
gen monday = (dow==1)
gen tuesday = (dow==2)
gen wednesday = (dow==3)
gen thursday = (dow==4)
gen friday = (dow==5)
gen saturday = (dow==6)

**** Sample restrictions *******************************************************

/* Identify and drop duplicates */
duplicates tag, gen(dupe)
duplicates drop

/* Drop observations with late registrations and dobs in 2005*/
drop if DOB<20060101

/*Drop missing obs for birth weight and DOB */
drop if birthwgt >=.
drop if dob >=.

/* Drop stillbirths */
drop if sbind==1

/* Restrict to births from 6 April 2006-2014 */
keep if DOB>=20060406&DOB<20140406

**** Clean birth weight data ***************************************************
sum birthwgt, d

/* Create a cleaned birth weight variable */ 
replace birthwgt=. if birthwgt==0 
replace birthwgt=. if birthwgt>=9000
sum birthwgt, d 
sum birthwgt if birthwgt<1400, d
sum birthwgt if birthwgt>4610, d
replace birthwgt=. if birthwgt<265 | birthwgt>5650
label var birthwgt "Birth weight (grams)"

/* LBW and ELBW dummies */ 
gen lowbw=(birthwgt<2500) if birthwgt!=. 
label var lowbw "Low birth weight"

gen elbw=(birthwgt<1500) if birthwgt!=. 
label var elbw "Extremely low birth weight"

**** Create quantiles **********************************************************
/* Maternal age */ 
* Quartiles 
xtile mquart = age if age!=., nq(4)
label var mquart "Maternal age quartile"
bysort mquart: sum age 
label define mquart 1 "25 and under" 2 "25-29 years" 3 "29-34 years" 4 "34 and over" 
label values mquart mquart 

* Deciles 
xtile mdecile = age if age!=., nq(10)
label var mdecile "Maternal age decile"
bysort mdecile: sum age 
label define mdecile 1 "21 and under" 2 "21-24 years" 3 "24-26 years" 4 "26-28 years" 5 "28-29 years" 6 "29-31 years" 7 "31-33 years" 8 "33-35 years" 9 "35-37 years" 10 "37 and over"
label values mdecile mdecile 

/* Index of income deprivation */ 
* Below/above median
xtile ihalf = incscore if incscore!=., nq(2)
label var ihalf "Income deprivation above/below median"
bysort ihalf: sum incscore 
label define ihalf 1 "Below-median deprivation" 2 "Above-median deprivation"
label values ihalf ihalf
* Quartiles 
xtile iquart = incscore if incscore!=., nq(4)
label var iquart "Income deprivation quartile"
bysort iquart: sum incscore 
label define iquart 1 "5% deprived" 2 "10% deprived" 3 "17% deprived" 4 "30% deprived" 
label values iquart iquart
* Deciles 
xtile idecile = incscore if incscore!=., nq(10)
label var idecile "Income deprivation decile"
bysort idecile: sum incscore 
label define idecile 1 "3% deprived" 2 "5% deprived" 3 "7% deprived" 4 "9% deprived" 5 "11% deprived" 6 "14% deprived" 7 "17% deprived" 8 "21% deprived" 9 "27% deprived" 10 "36% deprived"
label values idecile idecile

/* Interaction between maternal age and deprivation */ 
gen mquart_ihalf = 1 if mquart==1 & ihalf==1
replace mquart_ihalf = 2 if mquart==1 & ihalf==2
replace mquart_ihalf = 3 if mquart==2 & ihalf==1
replace mquart_ihalf = 4 if mquart==2 & ihalf==2 
bysort ihalf: sum incscore 
label define mquart_ihalf 1 "24 and under, less deprived area" 2 "24 and under, more deprived area" 3 "34 and over, less deprived area" 4 "34 and over, more deprived area" 
label values mquart_ihalf mquart_ihalf

**** Save datasets *************************************************************

keep *dob* DOB *dob* *wob* birthwgt lowbw* elbw* multbth sbind ///
age incscore *mquart* mdecile iquart idecile ihalf female dow ///
sunday monday tuesday wednesday thursday friday saturday *interact* *hpg* ///
lower_sc combined_sc nhs_estab *lone* teen old country 

save "$clean/births_0614", replace 
********************************************************************************
********************* NHS02: Clean NHS hospital data ***************************
********************************************************************************
clear all
set more off 
capture log close 

foreach year in 0607 0708 0809 0910 1011 1112 1213 1314 1415 {
	use "$clean/hes_`year'", clear
		
	gen fyear = `year' 

	sort week_of_birth_06042009_var1

	rename binary_treatment hpg_nhs

	label var study_id "Unique baby ID"
	label var week_of_birth_06042009_var1 "Actual week of birth relative to 6 April 2009 (weeks)"
	label var hpg_nhs "Date of birth from 6 April 2009 to 16 April 2011 inclusive" 
	label var fyear "Financial year"
	label var anagest "Gestational age at first antenatal assessment"
	label var anasdate "First antenatal assessment date"
	label var ethnos "Ethnicity"
	label var lsoa11 "LSOA (2011)"
	label var lsoa01 "LSOA (2001)"
	label var matage "Maternal age (years)"
	label var neocare "Neonatal level of care"
	label var delonset "Delivery onset method"
	label var numbaby "Number of babies delivered (including stillbirths)"
	label var postdur "Postnatal stay (days)"
	label var well_baby_ind "Well baby (normal neonatal care)"

	**** Clean variables of interest ***************************************

	/* Week of birth relative to 6 April 2009 */
	codebook week_of_birth_06042009_var1, t(100)
		
	rename week_of_birth_06042009_var1 wob 
		
	/* Stillbirth status */
	codebook birstat*, t(100)
		
	label define birstat 1 "Live birth" 2 "Stillbirth: ante-partum" ///
	3 "Stillbirth: post-partum" 4 "Stillbirth: indeterminate" ///
	9 "Not known" 
		
	label values birstat* birstat 
		
	capture confirm variable birstat 
		
	if !_rc { 
		gen sbind = 1 if inlist(birstat,2,3,4)
		replace sbind = 0 if inlist(birstat,1)
	}
	else {
		gen sbind = 1 if inlist(birstat_1,2,3,4)
		replace sbind = 0 if inlist(birstat_1,1)

		forval i=2/9 {
			replace sbind = 1 if inlist(birstat_`i',2,3,4) 
			replace sbind = 0 if inlist(birstat_`i',1)
		}
	}
	label var sbind "Stillbirth"

	/* Birthweight */ 
	codebook birweit*, t(100)
		
	capture confirm variable birweit 
		
	if !_rc {
		gen birthwgt = birweit 
	}
	else {
		gen birthwgt = birweit_1 
		forval i=2/9 {
			replace birthwgt = birweit_`i' if birthwgt==.
		}
	}
	label var birthwgt "Birth weight (grams)" 
		
	replace birthwgt=. if birthwgt>=7000 // NB 7000=7000 or more; 9999=not known

	/* Neonatal level of care */ 
	codebook neocare, t(100)
	label define neo 0 "Normal" 1 "Special" 2 "Level 2 intensive care" ///
	3 "Level 1 intensive care" 8 "NA" 9 "Not known" 
	label values neocare neo
	gen icu = 1 if inlist(neocare,1,2,3)
	replace icu = 0 if inlist(neocare,0)
	label var icu "Special or intensive neonatal care"

	/* Multiple birth status */
	codebook numbaby, t(100)
	tostring numbaby, replace
	replace numbaby = "" if inlist(numbaby, "9", "X") // recode '9' and 'X' to missing
	destring numbaby, replace

	gen multbth=(numbaby>1) if numbaby!=.
	label var multbth "Multiple birth"

	/* Sex of baby */ 
	capture confirm numeric variable sexbaby
	if !_rc {
		gen female=1 if inlist(sexbaby,2) & sexbaby!=.
		replace female=0 if inlist(sexbaby,1) & sexbaby!=. 
	}
	else {
		capture confirm string variable sexbaby
		if !_rc {
			gen female=1 if inlist(sexbaby,"2","F") & sexbaby!=""
			replace female=0 if inlist(sexbaby,"1","M") & sexbaby!=""
		}
		else {
			gen female=.
		}
	}
	label var female "Female baby"
	
	/* Maternal age */ 
	codebook matage, t(100)
	sum matage
		
	/* Ethnicity */
	codebook ethnos, t(100)
	encode ethnos, gen(ethnicity)
	codebook ethnicity, t(100)
	label define eth 1 "British (White)" 2 "Irish (White)" ///
	3 "Any other white background" 4 "White and Black Caribbean (Mixed)" ///
	5 "White and Black African (Mixed)" 6 "White and Asian (Mixed)" ///
	7 "Any other mixed background" 8 "Indian (Asian or Asian British)" ///
	9 "Pakistani (Asian or Asian British)" 10 "Bangladeshi (Asian or Asian British)" ///
	11 "Any other black background" 12 "Caribbean (Black or Black British)" ///
	13 "African(Black or Black British)" 14 "Any other black background" ///
	15 "Chinese (other ethnic group)" 16 "Any other ethnic group" ///
	17 "Missing" 
	label drop ethnicity
	label values ethnicity eth
	codebook ethnicity, t(100)
	recode ethnicity (18=.) (17=.) // missing codes

	gen white = inlist(ethnicity,1) if ethnicity!=.
	label var white "White British"

	gen south_asian = inlist(ethnicity,8,9,10) if ethnicity!=.
	label var south_asian "Indian, Pakistani or Bangladeshi" 

	gen bame = inlist(ethnicity,4,5,6,7,8,9,10,11,12,13,14,15,16) if ethnicity!=.
	label var bame "Black, Asian or Minority Ethnic (BAME)"

	/* Gestational age */ 
	codebook gestat* 
	
	capture confirm variable gestat 
	if !_rc {
		gen gestage = gestat
		}
	else {
		gen gestage = gestat_1 
		forval i=2/9 {
			replace gestage=gestat_`i' if gestage==.
		}
	}
	recode gestage (99=.)
	replace gestage=. if gestage>45
	replace gestage=. if gestage<22 // following Herbert et al (2017)
	sum gestage
	label var gestage "Gestational age at birth (weeks)"
	
	/* Expected week of delivery */ 
	gen ewd=wob+(40-gestage) if wob!=. & gestage!=. 
	label var ewd "Expected week of birth relative to 6 April 2009 (weeks)"
	
	/* Date of first antenatal assessment */ 
	codebook anasdate, t(100)
	gen antedate=date(anasdate, "YMD")
	recode antedate (-58073=.) // drop implausible dates
	label var antedate "Date of first antenatal appt (date fmt)"
	format antedate %td
	local cutoff 17993 
	gen centred_antedate=antedate-`cutoff'
	label var centred_antedate "Date of antenatal appt (relative to 6 April 2009)"
	gen centred_anteweek=wofd(centred_antedate)
	label var centred_anteweek "Week of antenatal appt (relative to 6 April 2009)"
	gen antedate_diff=wob-centred_anteweek if wob!=. & centred_anteweek!=.
	label var antedate_diff "Diff betw WOB and week of first antenatal appt" 
	
	* Drop impossible antedates 
	foreach v in centred_antedate centred_anteweek antedate_diff {
		replace `v'=. if antedate_diff>45 
		replace `v'=. if antedate_diff<0
	}

	* Code as missing if gestation at antenatal check is greater than gestation at birth  
	replace anagest=. if anagest>gestage & anagest!=. & gestage!=. 
	
	* Replace with antedate calculation if anagest is missing
	replace anagest=gestage-antedate_diff if anagest==. & gestage!=.
	
	* Code negatives to missing
	replace anagest=. if anagest<0 
	
	gen anagest_diff = gestage-anagest if gestage!=. & anagest!=. 
	label var anagest_diff "Diff between gestational age at birth and first antenatal appt"
		
	tab anagest_diff antedate_diff, mi // should be very similar 
	
	gen weekstogo = 40-anagest 
	label var weekstogo "Number of weeks of expected gestation after ante-natal appt"
	
	* Use antenatal data to fill in due dates if gestage is missing 
	replace ewd=centred_anteweek+weekstogo if gestage==.
	
	/* Replace EWD with WOB if missing */ 
	replace ewd=wob if ewd==.
	label var ewd "Expected week of birth relative to 6 April 2009 (weeks)"
		
	/* Antenatal appointment before 25 weeks */
	gen anagest_pre25 = (anagest<25) if anagest!=. 
	label var anagest_pre25 "First antenatal assessment before 25 weeks"
	
	/* Anagest dummies by trimester */ 
	gen anagest_first = (anagest<=13) if anagest!=. 
	label var anagest_first "First antenatal assessment during first trimester"
	bysort anagest_first: sum anagest 
	
	gen anagest_second = (anagest<=26 & anagest>13) if anagest!=. 
	label var anagest_second "First antenatal assessment during second trimester"
	bysort anagest_second: sum anagest 

	gen anagest_third = (anagest<=40 & anagest>26) if anagest!=. 
	label var anagest_third "First antenatal assessment during third trimester"
	bysort anagest_third: sum anagest 
	
	/* Delivery onset method */ 
	codebook delonset, t(100)
	label define delivery 1 "Spontaneous" ///
	2 "Caesarean section after onset of labour, decision made before labour" ///
	3 "Surgical induction by amniotomy" 4 "Medical induction" ///
	5 "Combination of surgical and medical induction" 8 "NA" ///
	9 "Not known" 
	label values delonset delivery 
	recode delonset (8/9=.)
	
	/* Postnatal stay in hospital */ 
	codebook postdur, t(100)
	sum postdur
	replace postdur=. if postdur>270 // it's meant to go up to 270 days 

	/* Well baby flag */ 
	codebook well_baby_ind, t(100)
	encode well_baby_ind, gen(well_baby)
	codebook well_baby
	recode well_baby (2=1) (1=0)
	label drop well_baby
	label var well_baby "Normal neonatal level of care"
	
	* Flag implausible gestational ages & birth weight combinations using
	* Herbert, Wijlaars, Zylbersztejn, Cromwell and Hardelid (2017) method
	{
	/* The code below implements Herbert, Wijlaars, Zylbersztejn, Cromwell and Hardelid (2017)'s
	method to clean gestational age and birthweight data using HES. The code flags
	observations in which the recorded birth weight falls outside +/-4 standard 
	deviations (SD) of mean birth weight for each gestational age. 
	To obtain birth weight centiles, they used LMSgrowth, a Microsoft Excel 
	add-in with growth references for children in the UK, 
	developed by Pan and Cole
	(available from: https://www.healthforallchildren.com/shop-base/shop/software/lmsgrowth/) */

	gen implaus=0
	********************* Boys
	replace implaus=1 if female==0 & gestage==22 & birthwgt <=266 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==23 & birthwgt <=309 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==24 & birthwgt <=352 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==25 & birthwgt <=396 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==26 & birthwgt <=440 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==27 & birthwgt <=486 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==28 & birthwgt <=536 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==29 & birthwgt <=593 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==30 & birthwgt <=659 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==31 & birthwgt <=741 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==32 & birthwgt <=843 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==33 & birthwgt <=968 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==34 & birthwgt <=1115 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==35 & birthwgt <=1283 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==36 & birthwgt <=1470 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==37 & birthwgt <=1699 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==38 & birthwgt <=1857 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==39 & birthwgt <=2014 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==40 & birthwgt <=2170 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==41 & birthwgt <=2329 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==42 & birthwgt <=2492 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==43 & birthwgt <=2492 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==44 & birthwgt <=2492 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==45 & birthwgt <=2492 & birthwgt !=.

	replace implaus=1 if female==0 & gestage==22 & birthwgt >=745 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==23 & birthwgt >=899 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==24 & birthwgt >=1053 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==25 & birthwgt >=1215 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==26 & birthwgt >=1388 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==27 & birthwgt >=1569 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==28 & birthwgt >=1766 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==29 & birthwgt >=1980 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==30 & birthwgt >=2214 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==31 & birthwgt >=2481 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==32 & birthwgt >=2780 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==33 & birthwgt >=3103 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==34 & birthwgt >=3435 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==35 & birthwgt >=3760 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==36 & birthwgt >=4066 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==37 & birthwgt >=4193 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==38 & birthwgt >=4498 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==39 & birthwgt >=4792 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==40 & birthwgt >=5078 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==41 & birthwgt >=5366 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==42 & birthwgt >=5655 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==43 & birthwgt >=5655 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==44 & birthwgt >=5655 & birthwgt !=.
	replace implaus=1 if female==0 & gestage==45 & birthwgt >=5655 & birthwgt !=.

	***************** Girls
	replace implaus=1 if female==1 & gestage==22 & birthwgt <=190 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==23 & birthwgt <=230 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==24 & birthwgt <=270 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==25 & birthwgt <=312 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==26 & birthwgt <=354 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==27 & birthwgt <=399 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==28 & birthwgt <=448 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==29 & birthwgt <=506 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==30 & birthwgt <=580 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==31 & birthwgt <=672 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==32 & birthwgt <=785 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==33 & birthwgt <=920 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==34 & birthwgt <=1074 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==35 & birthwgt <=1247 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==36 & birthwgt <=1438 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==37 & birthwgt <=1662 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==38 & birthwgt <=1820 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==39 & birthwgt <=1976 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==40 & birthwgt <=2128 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==41 & birthwgt <=2280 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==42 & birthwgt <=2431 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==43 & birthwgt <=2431 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==44 & birthwgt <=2431 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==45 & birthwgt <=2431 & birthwgt !=.

	replace implaus=1 if female==1 & gestage==22 & birthwgt >=674 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==23 & birthwgt >=831 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==24 & birthwgt >=988 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==25 & birthwgt >=1153 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==26 & birthwgt >=1327 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==27 & birthwgt >=1511 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==28 & birthwgt >=1705 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==29 & birthwgt >=1912 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==30 & birthwgt >=2145 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==31 & birthwgt >=2410 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==32 & birthwgt >=2700 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==33 & birthwgt >=3007 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==34 & birthwgt >=3321 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==35 & birthwgt >=3633 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==36 & birthwgt >=3929 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==37 & birthwgt >=4040 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==38 & birthwgt >=4329 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==39 & birthwgt >=4605 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==40 & birthwgt >=4866 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==41 & birthwgt >=5120 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==42 & birthwgt >=5370 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==43 & birthwgt >=5370 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==44 & birthwgt >=5370 & birthwgt !=.
	replace implaus=1 if female==1 & gestage==45 & birthwgt >=5370 & birthwgt !=.

	************ missing
	replace implaus=1 if female==. & gestage==22 & birthwgt <=266 & birthwgt !=.
	replace implaus=1 if female==. & gestage==23 & birthwgt <=309 & birthwgt !=.
	replace implaus=1 if female==. & gestage==24 & birthwgt <=352 & birthwgt !=.
	replace implaus=1 if female==. & gestage==25 & birthwgt <=396 & birthwgt !=.
	replace implaus=1 if female==. & gestage==26 & birthwgt <=440 & birthwgt !=.
	replace implaus=1 if female==. & gestage==27 & birthwgt <=486 & birthwgt !=.
	replace implaus=1 if female==. & gestage==28 & birthwgt <=536 & birthwgt !=.
	replace implaus=1 if female==. & gestage==29 & birthwgt <=593 & birthwgt !=.
	replace implaus=1 if female==. & gestage==30 & birthwgt <=659 & birthwgt !=.
	replace implaus=1 if female==. & gestage==31 & birthwgt <=741 & birthwgt !=.
	replace implaus=1 if female==. & gestage==32 & birthwgt <=843 & birthwgt !=.
	replace implaus=1 if female==. & gestage==33 & birthwgt <=968 & birthwgt !=.
	replace implaus=1 if female==. & gestage==34 & birthwgt <=1115 & birthwgt !=.
	replace implaus=1 if female==. & gestage==35 & birthwgt <=1283 & birthwgt !=.
	replace implaus=1 if female==. & gestage==36 & birthwgt <=1470 & birthwgt !=.
	replace implaus=1 if female==. & gestage==37 & birthwgt <=1699 & birthwgt !=.
	replace implaus=1 if female==. & gestage==38 & birthwgt <=1857 & birthwgt !=.
	replace implaus=1 if female==. & gestage==39 & birthwgt <=2014 & birthwgt !=.
	replace implaus=1 if female==. & gestage==40 & birthwgt <=2170 & birthwgt !=.
	replace implaus=1 if female==. & gestage==41 & birthwgt <=2329 & birthwgt !=.
	replace implaus=1 if female==. & gestage==42 & birthwgt <=2492 & birthwgt !=.
	replace implaus=1 if female==. & gestage==43 & birthwgt <=2492 & birthwgt !=.
	replace implaus=1 if female==. & gestage==44 & birthwgt <=2492 & birthwgt !=.
	replace implaus=1 if female==. & gestage==45 & birthwgt <=2492 & birthwgt !=.

	replace implaus=1 if female==. & gestage==22 & birthwgt >=674 & birthwgt !=.
	replace implaus=1 if female==. & gestage==23 & birthwgt >=831 & birthwgt !=.
	replace implaus=1 if female==. & gestage==24 & birthwgt >=988 & birthwgt !=.
	replace implaus=1 if female==. & gestage==25 & birthwgt >=1153 & birthwgt !=.
	replace implaus=1 if female==. & gestage==26 & birthwgt >=1327 & birthwgt !=.
	replace implaus=1 if female==. & gestage==27 & birthwgt >=1511 & birthwgt !=.
	replace implaus=1 if female==. & gestage==28 & birthwgt >=1705 & birthwgt !=.
	replace implaus=1 if female==. & gestage==29 & birthwgt >=1912 & birthwgt !=.
	replace implaus=1 if female==. & gestage==30 & birthwgt >=2145 & birthwgt !=.
	replace implaus=1 if female==. & gestage==31 & birthwgt >=2410 & birthwgt !=.
	replace implaus=1 if female==. & gestage==32 & birthwgt >=2700 & birthwgt !=.
	replace implaus=1 if female==. & gestage==33 & birthwgt >=3007 & birthwgt !=.
	replace implaus=1 if female==. & gestage==34 & birthwgt >=3321 & birthwgt !=.
	replace implaus=1 if female==. & gestage==35 & birthwgt >=3633 & birthwgt !=.
	replace implaus=1 if female==. & gestage==36 & birthwgt >=3929 & birthwgt !=.
	replace implaus=1 if female==. & gestage==37 & birthwgt >=4040 & birthwgt !=.
	replace implaus=1 if female==. & gestage==38 & birthwgt >=4329 & birthwgt !=.
	replace implaus=1 if female==. & gestage==39 & birthwgt >=4605 & birthwgt !=.
	replace implaus=1 if female==. & gestage==40 & birthwgt >=4866 & birthwgt !=.
	replace implaus=1 if female==. & gestage==41 & birthwgt >=5120 & birthwgt !=.
	replace implaus=1 if female==. & gestage==42 & birthwgt >=5370 & birthwgt !=.
	replace implaus=1 if female==. & gestage==43 & birthwgt >=5370 & birthwgt !=.
	replace implaus=1 if female==. & gestage==44 & birthwgt >=5370 & birthwgt !=.
	replace implaus=1 if female==. & gestage==45 & birthwgt >=5370 & birthwgt !=.
	}
	
	/* Clean gestational age */ 
	replace gestage = . if implaus==1 
	label var gestage "Gestational age at birth (weeks)"
	
	/* Prematurity dummy */
	gen premature = (gestage<37) if gestage!=.  
	label var premature "Premature birth"
		
	/* Health in Pregnancy Grant ITT variables: all dates of birth between
	6 April 2009 and 16 April 2011 inclusive */ 
	gen hpg_ewd=(ewd>=0 & ewd<=105) if ewd!=.
	label var hpg_ewd "Eligible for HPG"
	
	gen hpg_wob=(wob>=0 & wob<=105) if wob!=.
	label var hpg_wob "Eligible for HPG"
	
	* NHS-Digital-created dummy for DOB between 6 April 2009 and 16 April 2011 inclusive 
	codebook hpg_nhs, t(100) 
	destring hpg_nhs, replace force 

	gen hpg_match = 0 if hpg_nhs!=. 
	replace hpg_match = 1 if hpg_wob==hpg_nhs 
	label var hpg_match "NHS HPG variable matches my one based on WOB" 

	/* Create parametric versions of EWD and WOB */
	foreach v in ewd wob {
		gen interact_`v'=(hpg_`v'*`v')
		gen `v'2=(`v'^2)
		gen `v'3=(`v'^3)
	}
	
	/* Country of residence - from LSOA code prefix */ 
	gen country_code_11 = substr(lsoa11,1,1) 
	gen country_code_01 = substr(lsoa01,1,1) 
	gen england = (country_code_01=="E") if lsoa01!="" 
	replace england = (country_code_11=="E") if lsoa11!=""
	
	keep study_id *wob* *week_of_birth* anagest* fyear birstat* sbind multbth ///
	birthwgt* *gestage* ethnicity matage neocare numbaby  ///
	postdur well_baby antedate *hpg* *interact* *ewd* icu white bame south_asian ///
	premature* lsoa* delonset female antedate centred_antedate centred_anteweek *diff* england

	compress
	
	save "$clean/clean_hes_`year'", replace
}

**** Combine and restrict sample ***********************************************

use "$clean/clean_hes_0607", clear

foreach year in 0708 0809 0910 1011 1112 1213 1314 1415 {
	append using "$clean/clean_hes_`year'"
}

sort ewd 

order study_id wob birthwgt gestage sbind antedate matage ethnicity delonset postdur icu well_baby fyear

gen birth=1

* Drop missing week of birth
drop if wob==.
	
* Drop stillbirths
drop if sbind==1 
	
/* Drop duplicate babies across years */
sort study_id wob birthwgt gestage sbind antedate matage ethnicity delonset postdur icu well_baby fyear
duplicates report study_id 
duplicates tag, gen(duplicates_tag)

duplicates drop study_id, force
		
********************************************************************************
* Clean birth weight data *
********************************************************************************
		
/* Clean birthweight in line with birth registry birthweight data cut-offs */ 
replace birthwgt=. if birthwgt<265 | birthwgt>5650
label var birthwgt "Birth weight (grams)"

/* Low and extremely low birthweight dummies */ 
gen lowbw=(birthwgt<2500) if birthwgt!=.
label var lowbw "Low birth weight"

gen elbw=(birthwgt<1500) if birthwgt!=.
label var elbw "Extremely low birth weight"

* Create gestage and anagest dummies (for fixed effects) 
foreach v in gestage anagest {
	local ytitle `: var label `v''
	sum `v'
	return list
	forval i=`r(min)'/`r(max)' {
		gen `v'_`i' = (`v'==`i') if `v'!=.
		label var `v'_`i' "`ytitle' is `i' weeks"
	} 
}

********************************************************************************
* Save datasets *
********************************************************************************
foreach year in 0607 0708 0809 0910 1011 1112 1213 1314 1415 {

	erase "$clean/clean_hes_`year'.dta"
}
	
foreach t in ewd wob {
		
	preserve 
 
	* April 2006 to April 2015
	keep if `t'>=-156 & `t'<312
		
	save "$clean/`t'_clean_hes_0615", replace
	
	* April 2006 to April 2014
	keep if `t'>=-156 & `t'<260
		
	save "$clean/`t'_clean_hes_0614", replace
	
	restore
	

}

********************************************************************************
***************** ONS03: Main tables with birth registry data ******************
********************************************************************************

clear all
set more off 
capture log close 

#delimit ; 

**** Tab. 1: Summary statistics from birth registry data, 2006-2014 ***********;
{ ; 
use "$clean/births_0614", clear ;

capture confirm file "$outputs" ; 
if _rc!=0{ ; 
	shell mkdir "$outputs" ; 
} ; 

* Open table ; 
cap file close fh ; 
file open fh using "$outputs/table_1.tex", write replace ; 

* Create table structure ; 
file write fh
" & \multicolumn{1}{c}{} & \multicolumn{1}{c}{} & \multicolumn{1}{c}{} & \multicolumn{1}{c}{} & \multicolumn{1}{c}{} \\" _n
" & N & Mean & SD & Prop. complete \\" _n
"\addlinespace \hline \addlinespace" _n ; 

* Fill in table ; 

foreach v in birthwgt lowbw elbw multbth female age teen incscore nhs_estab lower_sc { ; 
	sum `v' ; 
	local mean = string(`r(mean)', "%10.3f") ; 
	local obs = string(`r(N)', "%10.0fc") ; 
	local sd = string(`r(sd)', "%10.3f") ; 
	count if `v'!=. ; 
	local nomi = `r(N)' ; 
	describe, short ; 
	local total = `r(N)' ; 
	local nomiprop = `nomi'/`total' ; 
	local strnomiprop = string(`nomiprop', "%10.2fc") ; 

file write fh "`:var label `v'' & `obs' & `mean' & `sd' & `strnomiprop' \\" _n ; 

} ; 

* Close file ; 
	
file close fh ; 
} ; 
**** Tab. 2: Effects of the Health in Pregnancy Grant on birth weight *********;
{ ;
cap file close fh ; 
file open fh using "$outputs/table_2.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" & \multicolumn{4}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} \\" _n 
"\midrule" _n ; 
#delimit ; 

foreach v in birthwgt lowbw elbw { ; 
	
	* Non-parametric CER-optimal ; 
	local j=1 ; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) bwselect(cerrd) all ; 
	global `v'h`j' = e(h_l) ; 
	global `v'b`j' = e(b_l) ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	local maxtreat_`v' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Non-parametric MSE-optimal ; 
	local j=2 ; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) bwselect(mserd) all ; 
	global `v'h`j' = e(h_l) ; 
	global `v'b`j' = e(b_l) ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	local mintreat_`v' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Non-parametric CER-optimal with uniform kernel ; 
	local j=3 ; 
	rdrobust `v' centred_dob, p(1) kernel(uniform) bwselect(cerrd) all ; 
	global `v'h`j' = e(h_l) ; 
	global `v'b`j' = e(b_l) ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Non-parametric CER-optimal with controls ; 
	local j=4 ; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) bwselect(cerrd) all covs(age multbth incscore female) ; 
	global `v'h`j' = e(h_l) ; 
	global `v'b`j' = e(b_l) ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	sum `v' if hpg_dob==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_dob==0 ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1'& `rd2'`stars2'& `rd3'`stars3'& `rd4'`stars4' & `ymean' \\"  _n ; 
	file write fh "& (`rdse1')& (`rdse2')& (`rdse3')& (`rdse4') \\" _n ; 
	file write fh "Bandwidth (days) & `h1' & `h2' & `h3' & `h4' \\" _n ; 
	file write fh "N & `n1'& `n2'& `n3'& `n4' & `ycount' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ; 
} ; 
file write fh "CER-optimal & X & & X & X  \\" _n ; 
file write fh "MSE-optimal & & X  \\" _n ; 
file write fh "Controls & & & & X  \\" _n ; 
file write fh "Kernel & Triangular & Triangular & Uniform & Triangular " _n ; 
file close fh ; 

di $birthwgth1 ; 
di $lowbwh1 ; 
di $elbwh1 ; 
di $birthwgth2 ; 
di $lowbwh2 ; 
di $elbwh2 ; 

* Back-of-envelope calculations to check consistency of results ***************; 
log using "$outputs/back_of_envelope.log", replace ; 

global max_effect = `maxtreat_birthwgt' ; 
global min_effect = `mintreat_birthwgt' ; 

preserve ; 
* Keep control group only ; 
keep if hpg_dob==0 ; 

foreach v in lowbw elbw { ; 
    
	if "`v'"=="lowbw" { ; 
	    global threshold = 2500 ; 
	} ; 
		if "`v'"=="elbw" { ; 
	    global threshold = 1500 ; 
	} ; 
	
	di "`: var label `v''" ; 

	count if `v'==1 ; 
	global num = r(N) ; 
	di "Number of babies under threshold is $num" ; 

	mean `v' ; 
	global prop = e(b)[1,1] ; 
	di "Proportion of babies under threshold is $prop" ; 

	global lower_max = $threshold-$max_effect ;  
	global lower_min = $threshold-$min_effect ;  

	* Maximum effect ;  
	count if birthwgt>=$lower_max & `v'==1 ; 
	global target_max = r(N) ; 
	di "Number of babies within window is $target_max" ; 
	global percent_max = $target_max/$num ; 
	di "... which is $percent_max as a proportion of the number of babies under threshold" ; 
	local expected_max_effect =  $percent_max*$prop*100 ; 
	di `expected_max_effect' ; 
	di "Max expected effect is `expected_max_effect'" ; 
	local max `: di %4.2f `expected_max_effect'' ; 

	* Minimum effect ; 
	count if birthwgt>=$lower_min & `v'==1 ; 
	global target_min = r(N) ; 
	di "Number of babies within window is $target_min" ; 
	global percent_min = $target_min/$num ; 
	di "... which is $percent_min as a proportion of the number of babies under threshold" ; 
	local expected_min_effect = $percent_min*$prop*100 ; 
	di "Min expected effect is `expected_min_effect'" ; 
	local min `: di %4.2f `expected_min_effect'' ; 

	di "Expected effect is between `min'-`max' pp" ; 
} ; 
restore ; 
} ; 
**** Tab. 4: Placebo cut-off tests ********************************************;
{ ; 
cap file close fh ; 
file open fh using "$outputs/table_4.tex", write replace ; 
* Create table skeleton ; 
file write fh 
" & \multicolumn{5}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)}\\" _n 
"\midrule" _n ; 

foreach p in 2007 2008 2010 2012 { ; 

	if "`p'"=="2007" { ; 
	local cutoff = "17262" ;
	local dob = "DOB>=20070406&DOB<=20090416" ; 
	local hpg_condition = "if hpg_dob==0" ; 
	} ; 
	if "`p'"=="2008" { ; 
	local cutoff = "17628" ;
	local dob = "DOB>=20080406&DOB<=20100416" ;
	local hpg_condition = "if hpg_dob==0" ; 
	} ; 
	if "`p'"=="2010" { ; 
	local cutoff = "18358" ;
	local dob = "DOB>=20100406&DOB<=20120416" ;
	local hpg_condition = "if hpg_dob==1" ; 
	} ; 
	if "`p'"=="2012" { ; 
	local cutoff = "19089" ;
	local dob = "DOB>=20120406&DOB<=20140416" ;
	local hpg_condition = "if hpg_dob==0" ; 
	} ; 

	use "$clean/births_0614", clear ;
	drop centred_dob ;  
	gen centred_dob=dob-`cutoff' ; 
	
	* Non-parametric CER-optimal ; 
	local j=1 ; 
	rdrobust birthwgt centred_dob `hpg_condition', p(1) kernel(triangular) h($birthwgth1) b($birthwgtb1) all ; 
	global cerrd = e(h_l) ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Non-parametric MSE-optimal ; 
	local j=2 ; 
	rdrobust birthwgt centred_dob `hpg_condition', p(1) kernel(triangular) h($birthwgth2) b($birthwgtb2) all ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Non-parametric CER-optimal with uniform kernel ; 
	local j=3 ; 
	rdrobust birthwgt centred_dob `hpg_condition', p(1) kernel(uniform) h($birthwgth3) b($birthwgtb3) all ; 
	global cerrd = e(h_l) ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Non-parametric CER-optimal with controls ; 
	local j=4 ; 
	rdrobust birthwgt centred_dob `hpg_condition', p(1) kernel(triangular) h($birthwgth4) b($birthwgtb4) all covs(age multbth incscore female) ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Non-parametric CER-optimal *for this cut-off* ; 
	local j=5 ; 
	rdrobust birthwgt centred_dob `hpg_condition', p(1) kernel(triangular) bwselect(cerrd) all ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,3]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[3,1]' ; 
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 

	sum birthwgt `hpg_condition' & centred_dob<0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count `hpg_condition' & centred_dob<0 ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "April `p' & `rd1'`stars1'& `rd2'`stars2'& `rd3'`stars3' & `rd4'`stars4' & `rd5'`stars5'& `ymean' \\"  _n ; 
	file write fh "& (`rdse1')& (`rdse2')& (`rdse3')& (`rdse4') & (`rdse5')\\" _n ; 
	file write fh "Bandwidth (days)& `h1' & `h2' & `h3' & `h4' & `h5'  \\" _n ; 
	file write fh "N & `n1'& `n2' & `n3' & `n4' & `n5' & `ycount' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ; 
} ; 
file write fh "CER-optimal & & & & & X  \\" _n ; 
file write fh "Controls & & & & X \\" _n ; 
file write fh "Kernel & Triangular & Triangular & Uniform & Triangular & Triangular " _n ; 
file close fh ; 
} ;

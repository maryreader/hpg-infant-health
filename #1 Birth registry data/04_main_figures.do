********************************************************************************
************** ONS04: Main figures with birth registry data ********************
********************************************************************************

clear all
set more off 
capture log close 

#delimit ; 

**** Fig. 1: Effect of the Health in Pregnancy Grant on birth weight **********;
{ ;

capture confirm file "$outputs/figures" ; 
if _rc!=0{ ; 
	shell mkdir "$outputs/figures" ; 
} ; 

local scale = "3290(35)3360" ;
local xscale = "-63(21)63" ; 
	
use "$clean/births_0614", clear ;

rdrobust birthwgt centred_dob, p(1) kernel(triangular) bwselect(cerrd) all ; 
local h = floor(e(h_l)) ; 
matrix b = e(b) ; 
global rd `: di %4.3f b[1,3]' ; 
mata st_matrix("se",sqrt(diagonal(st_matrix("e(V)")))) ; 
global rdse `: di %4.3f se[3,1]' ; 
global p = e(pv_rb) ;
if $p < 0.01 {; global stars = "***"; };
if $p < 0.05 & $p>=0.01 {; global stars = "**"; };
if $p < 0.1 & $p>=0.05 {; global stars = "*"; };
if $p > 0.1 {; global stars = ""; } ; 
di $p ; 
global outcome `:var label birthwgt' ; 
	
keep if centred_dob>=-`h' & centred_dob<=`h' ;
		
reg birthwgt centred_dob if centred_dob<0 ;
predict yhat if centred_dob<0 ;

reg birthwgt centred_dob if centred_dob>=0 ;
predict yhat2 if centred_dob>=0 ;

gen bin = floor(centred_dob/7) ;

* Collapse by bin ;
collapse (mean) birthwgt yhat yhat2, by(bin) ;

* Scale units to mean day of bin ;
gen centred_dob = bin*7  ;
replace centred_dob = centred_dob+3.5 ;
		
#delimit ; 

twoway scatter birthwgt centred_dob if centred_dob<0, mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
|| scatter birthwgt centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
|| line yhat centred_dob if centred_dob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
|| line yhat2 centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
xline(0) 
 xtitle("Actual date of birth relative to 6 April 2009 (days)") ytitle("$outcome") 
graphregion(color(white)) xlabel(`xscale') ylabel(`scale')
legend(off)
caption("RD $rd$stars ($rdse)", ring(0) position(4))
;

graph export "$outputs/figures/figure_1.pdf", replace ;
} ; 
**** Fig. 3: Birth weight effects by maternal age quartile ********************;
{ ;

foreach v in birthwgt lowbw elbw { ; 

	forval i=1/4 { ; 
	
	use "$clean/births_0614", clear ;
	
	keep if mquart==`i' ; 
	
	local age: label mquart `i' ; 

	rdrobust `v' centred_dob, p(1) kernel(triangular) h($`v'h1) b($`v'b1) all ;
	local h = e(h_l) ;
	matrix b = e(b) ; 
	global rd `: di %4.3f b[1,3]' ; 
	mata st_matrix("se",sqrt(diagonal(st_matrix("e(V)")))) ; 
	global rdse `: di %4.3f se[3,1]' ; 
	global p = e(pv_rb) ;
	if $p < 0.01 {; global stars = "***"; };
	if $p < 0.05 & $p>=0.01 {; global stars = "**"; };
	if $p < 0.1 & $p>=0.05 {; global stars = "*"; };
	if $p > 0.1 {; global stars = ""; } ; 
	di $p ; 
	global outcome `:var label `v'' ;

	sysdir set PLUS "$ado/parmest" ; 
	parmest, saving("$temp/mquart`i'_`v'.dta", replace) level(95) ; 
		
	} ; 

} ; 

* Coefficient graph ; 
use "$clean/births_0614", clear ;
    
local name `:var label mquart' ; 
	
foreach v in birthwgt lowbw elbw { ; 

	if "`v'"=="birthwgt" { ; 
		local scale = "-40(20)40" ; 
	} ; 
	if "`v'"=="lowbw" { ; 
		local scale = "-0.016(0.008)0.016" ; 
	} ; 
	if "`v'"=="elbw" { ; 
		local scale = "-0.006(0.003)0.003" ; 
	} ; 
	
use "$clean/births_0614", clear ;
	
local ytitle `:var label `v'' ; 
	
use "$temp/mquart1_`v'", clear ; 
append using "$temp/mquart2_`v'" ; 
append using "$temp/mquart3_`v'" ; 
append using "$temp/mquart4_`v'" ; 

keep if parm=="Robust" ; 

gen quartile=_n ; 

twoway scatter estimate quartile, mcolor(black) msymbol(smcircle) ||
rcap max95 min95 quartile, lcolor(gs5)
graphregion(color(white))
xtitle("`name'") 
ytitle("Effect")
title("`ytitle'", color(black))
yline(0, lcolor(cranberry) lwidth(thin))
xlabel(1(1)4)
ylabel(`scale')
legend(off); 

graph save "$outputs/figures/`v'_mquart_coeff.gph", replace ;

} ;

* Combine graphs across variables ; 
graph combine "$outputs/figures/birthwgt_mquart_coeff.gph"
"$outputs/figures/lowbw_mquart_coeff.gph"
"$outputs/figures/elbw_mquart_coeff.gph",
graphregion(color(white))  ; 

graph export "$outputs/figures/figure_3.pdf", replace ; 

erase "$outputs/figures/birthwgt_mquart_coeff.gph" ; 
erase "$outputs/figures/lowbw_mquart_coeff.gph" ; 
erase "$outputs/figures/elbw_mquart_coeff.gph" ; 
} ;
**** Fig. 4: Placebo cut-off tests ********************************************;
{ ;
local scale = "3290(35)3360" ;
local xscale = "-63(21)63" ; 
			
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
	
	rdrobust birthwgt centred_dob `hpg_condition', p(1) kernel(triangular) h($birthwgth1) b($birthwgtb1) all ; 
	local h = floor(e(h_l)) ; 
	matrix b = e(b) ; 
	global rd `: di %4.3f b[1,3]' ; 
	mata st_matrix("se",sqrt(diagonal(st_matrix("e(V)")))) ; 
	global rdse `: di %4.3f se[3,1]' ; 
	global p = e(pv_rb) ;
	if $p < 0.01 {; global stars = "***"; };
	if $p < 0.05 & $p>=0.01 {; global stars = "**"; };
	if $p < 0.1 & $p>=0.05 {; global stars = "*"; };
	if $p > 0.1 {; global stars = ""; } ; 
	di $p ; 
	global outcome `:var label birthwgt' ; 
	
	keep if centred_dob>=-`h' & centred_dob<=`h' ; 
			
	reg birthwgt centred_dob if centred_dob<0 ; 
	predict yhat if centred_dob<0 ; 
	
	reg birthwgt centred_dob if centred_dob>=0 ; 
	predict yhat2 if centred_dob>=0 ;
	
	gen bin = floor(centred_dob/7) ;
	
	* Collapse by bin ;
	collapse (mean) birthwgt yhat yhat2, by(bin) ;

	* Scale units to mean day of bin ;
	gen centred_dob = bin*7  ;
	replace centred_dob = centred_dob+3.5 ;
			
	#delimit ; 
	
	twoway scatter birthwgt centred_dob if centred_dob<0, mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| scatter birthwgt centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	|| line yhat centred_dob if centred_dob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| line yhat2 centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	xline(0) 
	title("`p'", color(black)) xtitle("Actual date of birth relative to 6 April `p' (days)") ytitle("$outcome") 
	graphregion(color(white)) xlabel(`xscale') ylabel(`scale')
	legend(off)
	caption("RD $rd$stars ($rdse)", ring(0) position(4))
	;
	
	graph save "$outputs/figures/`p'_birthwgt.gph", replace ;

} ; 

graph combine "$outputs/figures/2007_birthwgt.gph" 
"$outputs/figures/2008_birthwgt.gph"
"$outputs/figures/2010_birthwgt.gph"
"$outputs/figures/2012_birthwgt.gph", graphregion(color(white)) ; 
graph export "$outputs/figures/figure_4.pdf", replace ;

erase "$outputs/figures/2007_birthwgt.gph" ; 
erase "$outputs/figures/2008_birthwgt.gph" ; 
erase "$outputs/figures/2010_birthwgt.gph" ; 
erase "$outputs/figures/2012_birthwgt.gph" ; 
} ;





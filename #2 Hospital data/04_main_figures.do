********************************************************************************
****************** NHS04: Main figures with NHS hospital data ******************
********************************************************************************
clear all
set more off 
capture log close 

#delimit ; 

capture confirm file "$outputs/figures" ; 
if _rc!=0{ ; 
	shell mkdir "$outputs/figures" ; 
} ; 

**** Fig. 2: Effect on prematurity (<37 weeks) ********************************;
{ ; 
local scale = "0.05(0.02)0.09" ;
local xscale = "-15(5)15" ; 
	
use "$clean/wob_clean_hes_0614", clear ;

local bandwidth "prematureh1wob" ; 
local bias_bandwidth "prematureb1wob" ; 
rdrobust premature wob, p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all ;
local h = floor(e(h_l)) ; 
matrix b = e(b) ;
global rd `: di %4.3f  b[1,3]' ;
mata st_matrix("se",sqrt(diagonal(st_matrix("e(V)")))) ;
matrix list se ;
global rdse `: di %4.3f  se[3,1]' ;
global treat `:var label wob' ;
global outcome `:var label premature' ;
global p = e(pv_rb) ;
di $p ;
if $p < 0.01 {; global stars = "***"; };
if $p < 0.05 & $p >= 0.01 {; global stars = "**"; };
if $p < 0.1 & $p >= 0.05 {; global stars = "*"; };
if $p > 0.1 {; global stars = ""; };
di $p ;

keep if wob>=-`h' & wob<=`h' ;

reg premature wob if wob<0 ; 
predict yhat if wob<0 ; 

reg premature wob if wob>=0 ; 
predict yhat2 if wob>=0 ; 
	
preserve ;
collapse premature yhat yhat2, by(wob) ;

twoway scatter premature wob if wob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| scatter premature wob if wob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	|| line yhat wob if wob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| line yhat2 wob if wob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	xline(0) 
	xtitle("$treat") ytitle("$outcome") xlabel(`xscale') ylabel(`scale')
	graphregion(color(white)) 
	legend(off)
	caption("RD $rd$stars ($rdse)", ring(0) position(4))
	;

restore ;

graph export "$outputs/figures/figure_2.pdf", replace ; 

} ; 


	

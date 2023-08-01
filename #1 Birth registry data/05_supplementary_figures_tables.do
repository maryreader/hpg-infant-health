********************************************************************************
******* ONS05: Supplementary tables and figures with birth registry data *******
********************************************************************************

clear all
set more off 
capture log close 

#delimit ; 

use "$clean/births_0614", clear ; 

**** Figure S1: Histogram of birth weight *************************************;
{ ;
histogram birthwgt, 
frequency
color(emidblue) lcolor(gs5) lwidth(vthin) bin(54)
xtitle("Birth weight (grams)", size(small)) ytitle("Density", size(small))
xlabel (500(1000)6500, labsize(small))
ylabel(,labsize(small))
graphregion(color(white)) ; 

graph export "$outputs/figures/figure_s2.pdf", replace ; 
} ; 
**** Figure S2: McCrary manipulation test: actual date of birth ***************;
{ ; 
preserve ; 

gen birth=1 ; 

collapse (count) birth, by(centred_dob) ; 

save "$outputs/centred_dob_counts", replace ; 

# delimit ; 
local ytitle "Date of birth relative to 6 April 2009" ; 
local range "-365 365" ; 
local scale "-365(365)365" ; 
local title "Actual date of birth" ; 

expand birth ; 

capture drop temp_* ; 
qui rddensity centred_`t', plot plot_range(`range') hist_range(`range') genvars(temp) ;
global rd `: di %4.2f e(T_q)' ; 
global rdp `: di %4.2f e(pv_q)' ; 

local ci_plot_region_l = `"(rarea temp_cil temp_cir temp_grid if temp_group == 0, sort lcolor(white%0) color(red%30))"' ; 
local ci_plot_region_r = `"(rarea temp_cil temp_cir temp_grid if temp_group == 1, sort lcolor(white%0) color(blue%30))"' ; 

local es_plot_line_l = `"(line temp_f temp_grid if temp_group == 0, sort lcolor(red) lwidth("medthin") lpattern(solid))"' ; 
local es_plot_line_r = `"(line temp_f temp_grid if temp_group == 1, sort lcolor(blue) lwidth("medthin") lpattern(solid))"' ;

qui su temp_hist_width if temp_hist_group == 0 ;
local hist_width_l = r(mean) ;

qui su temp_hist_width if temp_hist_group == 1 ;
local hist_width_r = r(mean) ;

local plot_histogram_l = `"(bar temp_hist_height temp_hist_center if temp_hist_group == 0, barwidth(`hist_width_l') color(red%20))"' ;
local plot_histogram_r = `"(bar temp_hist_height temp_hist_center if temp_hist_group == 1, barwidth(`hist_width_r') color(blue%20))"' ;

local graph_opt = `"xline(0, lcolor(black) lwidth(medthin) lpattern(solid)) legend(off) xlabel(`scale') xtitle(`ytitle') ytitle("Density") caption("RD $rd (p-value: $rdp)", ring(0) position(1)) graphregion(color(white)) title(`title', size(medium) color(black) position(12)) ylabel(#3)"' ; 

twoway `plot_histogram_l' 
`plot_histogram_r' 
`ci_plot_region_l' 
`ci_plot_line_l' 
`ci_plot_ebar_l' 
`ci_plot_region_r' 
`ci_plot_line_r' 
`ci_plot_ebar_r' 
`es_plot_line_l' 
`es_plot_point_l' 
`es_plot_line_r' 
`es_plot_point_r' 
, `graph_opt' ;

graph export "$outputs/figure_s3.pdf", replace ;
restore ; 
} ;
**** Tab. S2: Summary statistics by treatment and control *********************;
{ ;
* Open table ; 
cap file close fh ; 
file open fh using "$outputs/table_s2.tex", write replace ; 

* Create table structure ; 
file write fh 
" & \multicolumn{3}{c}{Control group} & \multicolumn{3}{c}{Treatment group} \\" _n 
" & N & Mean & SD & N & Mean & SD \\" _n 
"\addlinespace \hline \addlinespace \\" _n ; 

* Fill in table ; 
gen s0 = (hpg_dob==0) ; 
gen s1 = (hpg_dob==1) ; 

foreach v in birthwgt lowbw elbw multbth female age teen incscore nhs_estab lower_sc { ; 

	forval s=0/1 { ;
	sum `v' if s`s'==1 ; 
	local mean`s' = string(`r(mean)', "%10.3f") ; 
	local obs`s' = string(`r(N)', "%10.0fc") ; 
	local sd`s' = string(`r(sd)', "%10.3f") ; 

	} ; 

file write fh "`:var label `v'' & `obs0' & `mean0' & `sd0' & `obs1' & `mean1' & `sd1'  \\" _n ; 
} ; 

* Close file ; 
	
file close fh ;  
} ;
**** Tab S4: Full covariate balance test results ******************************;
{ ;
cap file close fh ; 
file open fh using "$outputs/table_s4.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" & \multicolumn{4}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)}\\" _n 
"\midrule" _n ; 

foreach v in multbth female age incscore teen nhs_estab lower_sc { ; 

if "`v'"=="multbth" { ;
	local controls "age incscore female" ; } ; 
if "`v'"=="female" { ;
	local controls "age multbth incscore" ; } ; 
if "`v'"=="age" { ;
	local controls "multbth incscore female" ; } ; 	
if "`v'"=="incscore" { ;
	local controls "age multbth female" ; } ; 	
else { ; 
	local controls "age multbth incscore female" ; } ; 
	
	* Non-parametric CER-optimal ; 
	local j=1 ;
	rdrobust `v' centred_dob, p(1) kernel(triangular) h($birthwgth1) b($birthwgtb1) all ; 
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
	rdrobust `v' centred_dob, p(1) kernel(triangular) h($birthwgth2) b($birthwgtb2) all ; 
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
	rdrobust `v' centred_dob, p(1) kernel(uniform) h($birthwgth3) b($birthwgtb3)  all ; 
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
	
	* Non-parametric CER-optimal *for this covariate* with triangular kernel ; 
	local j=4 ; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
file write fh "CER-optimal & & & & X  \\" _n ; 
file write fh "Kernel & Triangular & Triangular & Uniform & Triangular " _n ; 
file close fh ; 
} ;
**** Fig. S5: Covariate balance tests *****************************************;
{ ;
foreach v in multbth age female incscore { ; 

	local xscale = "-63(21)63" ; 

	if "`v'"=="multbth" { ; 
		local scale = "0.028(0.005)0.038" ; 
		local controls "age incscore female" ;
	} ; 
	if "`v'"=="female" { ; 
		local scale = "0.475(0.01)0.495" ; 
		local controls "age multbth incscore" ;
	} ; 
	if "`v'"=="age" { ; 
		local scale = "29.2(0.2)29.8" ; 
		local controls "multbth incscore female" ;
	} ; 
	if "`v'"=="incscore" { ; 
		local scale = "0.148(0.0025)0.153" ; 
		local controls "age multbth female" ;
	} ; 

	use "$clean/births_0614", clear ;

	rdrobust `v' centred_dob, p(1) kernel(triangular) h($birthwgth1) b($birthwgtb1) all ; 
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
	global outcome `:var label `v'' ; 
	
	keep if centred_dob>=-`h' & centred_dob<=`h' ; 
			
	reg `v' centred_dob if centred_dob<0 ; 
	predict yhat if centred_dob<0 ; 
	
	reg `v' centred_dob if centred_dob>=0 ; 
	predict yhat2 if centred_dob>=0 ;
	
	gen bin = floor(centred_dob/7) ;
	
	* Collapse by bin ;
	collapse (mean) `v' yhat yhat2, by(bin) ;

	* Scale units to mean day of bin ;
	gen centred_dob = bin*7  ;
	replace centred_dob = centred_dob+3.5 ;
			
	#delimit ; 
	
	twoway scatter `v' centred_dob if centred_dob<0, mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| scatter `v' centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	|| line yhat centred_dob if centred_dob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| line yhat2 centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	xline(0) 
	title("$outcome", color(black)) xtitle("Actual date of birth relative to 6 April 2009 (days)") ytitle("$outcome") 
	graphregion(color(white)) xlabel(`xscale') ylabel(`scale')
	legend(off)
	caption("RD $rd$stars ($rdse)", ring(0) position(4))
	;

	graph save "$outputs/figures/`v'.gph", replace ;

};

graph combine "$outputs/figures/multbth.gph"
"$outputs/figures/female.gph"
"$outputs/figures/age.gph"
"$outputs/figures/incscore.gph", graphregion(color(white)) ; 
graph export "$outputs/figures/figure_s5.pdf", replace ;

erase "$outputs/figures/multbth.gph" ; 
erase "$outputs/figures/female.gph" ; 
erase "$outputs/figures/age.gph" ; 
erase "$outputs/figures/incscore.gph" ; 
} ; 
**** Tab. S5: RD estimates with different bandwidths **************************;
{ ;
use "$clean/births_0614", clear ;

cap file close fh ; 
file open fh using "$outputs/table_s5.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" & \multicolumn{4}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} \\" _n 
"\midrule" _n ; 

foreach v in birthwgt lowbw elbw { ; 
	
	* Linear, CER optimal ; 
	local j=1; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
	local h`j' = `: di %4.3f $cerrd' ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Linear, MSE optimal ; 
	local j=2 ; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) bwselect(mserd) all ; 
	global mserd = e(h_l) ; 
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
	local h`j' = `: di %4.3f $mserd' ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Linear, 2*CER ; 
	local j=3 ; 
	local h=$cerrd*2 ; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) h(`h') all ; 
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
	local h`j' = `: di %4.3f `h'' ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	
	* Linear, 2*MSE ; 
	local j=4 ; 
	local h=$mserd*2 ; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) h(`h') all ; 
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
	local h`j' = `: di %4.3f `h'' ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
		
	sum `v' if hpg_dob==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_dob==0 ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1'& `rd2'`stars2'& `rd3'`stars3'& `rd4'`stars4'& `ymean' \\"  _n ; 
	file write fh "& (`rdse1')& (`rdse2')& (`rdse3')& (`rdse4') \\" _n ; 
	file write fh "Bandwidth (days) & `h1' & `h2' & `h3' & `h4'   \\" _n ; 
	file write fh "N & `n1'& `n2'& `n3'& `n4' & `ycount' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ; 
} ; 

file write fh "Size of bandwidth & CER & MSE & 2*CER & 2*MSE  \\" _n ; 
file write fh "Kernel & Triangular & Triangular & Triangular & Triangular " _n ; 

file close fh ; 
} ;
**** Tab. S6: Linear parametric RD estimates by bandwidth *********************;
{ ;
cap file close fh ; 
file open fh using "$outputs/table_s6.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" & \multicolumn{5}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\" _n 
"\midrule" _n ; 

foreach v in birthwgt lowbw elbw { ; 

	use "$clean/births_0614", clear ;

	* Linear, 168 days ; 
	local j=1 ; 
	regress `v' hpg_dob centred_dob if centred_dob>=-168 & centred_dob<=168, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local n`j'=string(`e(N)', "%10.0fc") ; 
	fitstat ; 
	local fit`j' = r(aic) ; 
	local aic`j' = string(`fit`j'', "%4.3f") ;
	di `aic`j'' ; 
		
	* Linear, 140 days ; 
	local j=2 ; 
	regress `v' hpg_dob centred_dob if centred_dob>=-140 & centred_dob<=140, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local n`j'=string(`e(N)', "%10.0fc") ; 
	fitstat ; 
	local fit`j' = r(aic) ; 
	local aic`j' = string(`fit`j'', "%4.3f") ;
	di `aic`j'' ; 

	* Linear, 112 days ; 
	local j=3 ; 
	regress `v' hpg_dob centred_dob if centred_dob>=-112 & centred_dob<=112, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local n`j'=string(`e(N)', "%10.0fc") ; 
	fitstat ; 
	local fit`j' = r(aic) ; 
	local aic`j' = string(`fit`j'', "%4.3f") ;
	di `aic`j'' ; 
	
	* Linear, 84 days ; 
	local j=4 ; 
	regress `v' hpg_dob centred_dob if centred_dob>=-84 & centred_dob<=84, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local n`j'=string(`e(N)', "%10.0fc") ; 
	fitstat ; 
	local fit`j' = r(aic) ; 
	local aic`j' = string(`fit`j'', "%4.3f") ;
	di `aic`j'' ; 
	
	* Linear, 56 days ; 
	local j=5 ; 
	regress `v' hpg_dob centred_dob if centred_dob>=-56 & centred_dob<=56, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	local n`j'=string(`e(N)', "%10.0fc") ; 
	fitstat ; 
	local fit`j' = r(aic) ; 
	local aic`j' = string(`fit`j'', "%4.3f") ;
	di `aic`j'' ; 
	
	sum `v' if hpg_dob==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_dob==0 ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1'& `rd2'`stars2'& `rd3'`stars3'& `rd4'`stars4'& `rd5'`stars5' & `ymean' \\"  _n ; 
	file write fh "& (`rdse1')& (`rdse2')& (`rdse3')& (`rdse4')& (`rdse5') \\" _n ; 
	file write fh "AIC & `aic1'& `aic2'& `aic3'& `aic4'& `aic5' \\" _n ; 

} ; 

file write fh "N & `n1'& `n2'& `n3'& `n4'& `n5' & `ycount' \\" _n ; 
file write fh "\addlinespace \hline \addlinespace" _n ; 
file write fh "Bandwidth (days) & 168 & 140 & 112 & 84 & 56 \\" _n ; 
file write fh "Linear trend & X & X & X & X & X & " _n ; 

file close fh ; 
} ;
**** Tab. S7: Additional parametric RD estimates ******************************; 
{ ;
use "$clean/births_0614", clear ;

count if birthwgt!=. ; 

local n = string(`r(N)', "%10.0fc") ; 

cap file close fh ; 
file open fh using "$outputs/table_s7.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" & \multicolumn{6}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} & \multicolumn{1}{c}{(7)} \\" _n 
"\midrule" _n ; 

foreach v in birthwgt lowbw elbw { ; 

	* Linear ; 
	local j=1 ; 
	regress `v' hpg_dob centred_dob if centred_dob>=-112 & centred_dob<=112, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	
	* Linear with day-of-the-week FE and controls ; 
	local j=2 ; 
	regress `v' hpg_dob centred_dob i.dow age multbth incscore female if centred_dob>=-112 & centred_dob<=112, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	
	* Quadratic ; 
	local j=3 ; 
	regress `v' hpg_dob centred_dob centred_dob2 if centred_dob>=-112 & centred_dob<=112, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
		
	* Quadratic with day-of-the-week FE and controls ; 
	local j=4 ; 
	regress `v' hpg_dob centred_dob centred_dob2 i.dow age multbth incscore female if centred_dob>=-112 & centred_dob<=112, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	
	* Cubic ; 
	local j=5 ; 
	regress `v' hpg_dob centred_dob centred_dob2 centred_dob3 if centred_dob>=-112 & centred_dob<=112, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
		
	* Cubic with day-of-the-week FE and controls ; 
	local j=6 ; 
	regress `v' hpg_dob centred_dob centred_dob2 centred_dob3 i.dow age multbth incscore female if centred_dob>=-112 & centred_dob<=112, robust ; 
	matrix b`j' = e(b) ; 
	local rd`j' `: di %4.3f b`j'[1,1]' ; 
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ; 
	local rdse`j' `: di %4.3f se`j'[1,1]' ; 
	local p`j' = 2*ttail(e(df_r),abs(`rd`j''/`rdse`j'')) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j''>=0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j''>=0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; } ; 
	di `p`j'' ; 
	
	sum `v' if hpg_dob==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_dob==0 ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1'& `rd2'`stars2'& `rd3'`stars3' & `rd4'`stars4' & `rd5'`stars5' & `rd6'`stars6' & `ymean' \\"  _n ; 
	file write fh "& (`rdse1')& (`rdse2')& (`rdse3') & (`rdse4') & (`rdse5')  & (`rdse6') \\" _n ; 
} ; 

file write fh "N & `n' & `n' & `n' & `n' & `n' & `n' & `ycount' \\" _n ; 
file write fh "\addlinespace \hline \addlinespace" _n ; 
file write fh "Linear trend & X & X \\" _n ; 
file write fh "Quadratic trend & & & X & X \\" _n ; 
file write fh "Cubic trend & & & & & X & X \\" _n ; 
file write fh "Day of the week FE & & X & & X & & X \\" _n ; 
file write fh "Controls & & X & & X & & X & " _n ; 

file close fh ; 
} ;
**** Fig. S6: Quantile regression *********************************************; 
{ ;
#delimit ; 

use "$clean/births_0614", clear ; 

* The original seed for the graph got lost - hence the very slight difference in CIs ; 
set seed 6042009 ; 

* Window with 2 years either side of cut-off (2 years control, 2 years treatment) ; 
keep if DOB>=20070406 & DOB<20110406 ; 

local ytitle `:var label birthwgt' ; 

sqreg birthwgt hpg_dob centred_dob interact, quantiles(0.05 0.15 0.25 0.35 0.45 0.55 0.65 0.75 0.85 0.95) ; 

sysdir set PLUS "$ado/parmest" ; 
parmest, saving("$temp/bw_sqreg.dta", replace) level(95) ; 

preserve  ; 
use "$temp/bw_sqreg", clear ; 

encode eq, gen(quantile) ; 

keep if parm=="hpg_dob" ;

twoway scatter estimate quantile, mcolor(black) msymbol(smcircle) ||
rcap max95 min95 quantile, lcolor(gs5)
graphregion(color(white))
ytitle("Effect (grams)")
xtitle("Birth weight quantile")
yline(0, lcolor(cranberry) lwidth(thin))
xlabel(1(1)10, valuelabel)
ylabel(-10(10)30)
legend(off); 

graph export "$outputs/figures/figure_s6.pdf", replace ; 

restore ; 
} ;
**** Fig. S7: Effect on low birth weight (<2500g) *****************************;
{ ;
local scale = "0.06(0.005)0.085" ; 
local xscale = "-105(105)105" ;	

use "$clean/births_0614", clear ;
rdrobust lowbw centred_dob, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
global outcome `:var label lowbw' ; 
	
keep if centred_dob>=-`h' & centred_dob<=`h' ;
		
reg lowbw centred_dob if centred_dob<0 ;
predict yhat if centred_dob<0 ;

reg lowbw centred_dob if centred_dob>=0 ;
predict yhat2 if centred_dob>=0 ;

gen bin = floor(centred_dob/7) ;

* Collapse by bin ;
collapse (mean) lowbw yhat yhat2, by(bin) ;

* Scale units to mean day of bin ;
gen centred_dob = bin*7  ;
replace centred_dob = centred_dob+3.5 ;
		
#delimit ; 

twoway scatter lowbw centred_dob if centred_dob<0, mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
|| scatter lowbw centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
|| line yhat centred_dob if centred_dob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
|| line yhat2 centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
xline(0) 
 xtitle("Actual date of birth relative to 6 April 2009 (days)") ytitle("$outcome") 
graphregion(color(white)) xlabel(`xscale') ylabel(`scale')
legend(off)
caption("RD $rd$stars ($rdse)", ring(0) position(4))
;

graph export "$outputs/figures/figure_s7.pdf", replace ;
} ;
**** Fig. S8: Effects on extremely low birth weight (<1500g) ******************; 
{ ;
local scale = "0.006(0.002)0.016" ; 
local xscale = "-147(147)147" ;

use "$clean/births_0614", clear ;
rdrobust elbw centred_dob, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
global outcome `:var label elbw' ; 
	
keep if centred_dob>=-`h' & centred_dob<=`h' ;
		
reg elbw centred_dob if centred_dob<0 ;
predict yhat if centred_dob<0 ;

reg elbw centred_dob if centred_dob>=0 ;
predict yhat2 if centred_dob>=0 ;

gen bin = floor(centred_dob/7) ;

* Collapse by bin ;
collapse (mean) elbw yhat yhat2, by(bin) ;

* Scale units to mean day of bin ;
gen centred_dob = bin*7  ;
replace centred_dob = centred_dob+3.5 ;
		
#delimit ; 

twoway scatter elbw centred_dob if centred_dob<0, mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
|| scatter elbw centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
|| line yhat centred_dob if centred_dob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
|| line yhat2 centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
xline(0) 
 xtitle("Actual date of birth relative to 6 April 2009 (days)") ytitle("$outcome") 
graphregion(color(white)) xlabel(`xscale') ylabel(`scale')
legend(off)
caption("RD $rd$stars ($rdse)", ring(0) position(4))
;

graph export "$outputs/figures/figure_s8.pdf", replace ;
} ;
**** Fig. S9: Heterogeneity by maternal age decile ****************************;
{ ;
foreach v in birthwgt lowbw elbw { ; 

	forval i=1/10 { ; 
	
	use "$clean/births_0614", clear ;
		
	keep if mdecile==`i' ; 
	
	local age: label mdecile `i' ; 
	
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
	
	sysdir set PLUS "${ado}parmest" ;
	parmest, saving("$temp/mdecile`i'_`v'", replace) level(95) ; 

} ; 

} ; 

* Coefficient graph ; 

use "$clean/births_0614", clear ;

local name `:var label mdecile' ; 

foreach v in birthwgt lowbw elbw { ; 

	if "`v'"=="birthwgt" { ; 
		local scale = "-50(25)50" ; 
	} ; 
	if "`v'"=="lowbw" { ; 
		local scale = "-0.02(0.01)0.02" ; 
	} ; 
	if "`v'"=="elbw" { ; 
		local scale = "-0.01(0.005)0.005" ; 
	} ; 
	
	use "$clean/births_0614", clear ;

	local ytitle `:var label `v'' ; 
		
	use "$temp/mdecile1_`v'", clear ; 
	append using "$temp/mdecile2_`v'" ; 
	append using "$temp/mdecile3_`v'" ; 
	append using "$temp/mdecile4_`v'" ; 
	append using "$temp/mdecile5_`v'" ; 
	append using "$temp/mdecile6_`v'" ;
	append using "$temp/mdecile7_`v'" ; 
	append using "$temp/mdecile8_`v'" ; 
	append using "$temp/mdecile9_`v'" ; 
	append using "$temp/mdecile10_`v'" ; 

	keep if parm=="Robust" ; 

	gen decile=_n ; 

	twoway scatter estimate decile, mcolor(black) msymbol(smcircle) ||
	rcap max95 min95 decile, lcolor(gs5)
	graphregion(color(white))
	xtitle("`name'") 
	ytitle("Effect")
	title("`ytitle'", color(black))
	yline(0, lcolor(cranberry) lwidth(thin))
	xlabel(1(1)10)
	ylabel(`scale')
	legend(off); 

	graph save "$outputs/figures/`v'_mdecile_coeff.gph", replace ;

} ;

* Combine graphs across variables ; 
graph combine "$outputs/figures/birthwgt_mdecile_coeff.gph"
"$outputs/figures/lowbw_mdecile_coeff.gph"
"$outputs/figures/elbw_mdecile_coeff.gph",
graphregion(color(white))  ; 

graph export "$outputs/figures/figure_s9.pdf", replace ; 

erase "$outputs/figures/birthwgt_mdecile_coeff.gph" ; 
erase "$outputs/figures/lowbw_mdecile_coeff.gph" ; 
erase "$outputs/figures/elbw_mdecile_coeff.gph" ; 
} ;
**** Tab. S11: Heterogeneity by maternal age and deprivation ******************;
{ ;
cap file close fh ; 
file open fh using "$outputs/table_s11.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" & \multicolumn{4}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{Quartile 1} & \multicolumn{1}{c}{Quartile 2} & \multicolumn{1}{c}{Quartile 3} & \multicolumn{1}{c}{Quartile 4} & \multicolumn{1}{c}{} \\" _n 
"\midrule" _n ; 

foreach v in birthwgt lowbw elbw { ; 

	forval i=1/4 { ; 
	local j=`i' ; 
	use "$clean/births_0614", clear ;
		
	keep if mquart_ihalf==`i' ;
	
	rdrobust `v' centred_dob, p(1) kernel(triangular) h($`v'h1) b($`v'b1) all ; 
	local h = e(h_l) ;
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
	local h`j' = `: di %4.3f `h'' ; 
	local n`j' = string(e(N_h_l) + e(N_h_r), "%10.0fc") ; 
	} ; 

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

file close fh ;
} ;
**** Tab. S12: Births RD estimates with week of birth as running variable *****;
{ ;
cap file close fh ; 
file open fh using "$outputs/table_s12.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" & \multicolumn{4}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\" _n 
"\midrule" _n ; 

foreach v in birthwgt lowbw elbw { ; 
	
	* Non-parametric CER-optimal ; 
	local j=1 ; 
	rdrobust `v' centred_wob, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
	rdrobust `v' centred_wob, p(1) kernel(triangular) bwselect(mserd) all ; 
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
	rdrobust `v' centred_wob, p(1) kernel(uniform) bwselect(cerrd) all ; 
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
	rdrobust `v' centred_wob, p(1) kernel(triangular) bwselect(cerrd) all covs(age multbth incscore female) ; 
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

	sum `v' if hpg_wob==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_wob==0 ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1'& `rd2'`stars2'& `rd3'`stars3'& `rd4'`stars4'& `ymean' \\"  _n ; 
	file write fh "& (`rdse1')& (`rdse2')& (`rdse3')& (`rdse4') \\" _n ; 
	file write fh "Bandwidth (weeks) & `h1' & `h2' & `h3' & `h4'   \\" _n ; 
	file write fh "N & `n1'& `n2'& `n3'& `n4' & `ycount' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ; 
} ; 
file write fh "CER-optimal & X & & X & X  \\" _n ; 
file write fh "MSE-optimal & & X  \\" _n ; 
file write fh "Controls & & & & X  \\" _n ; 
file write fh "Kernel & Triangular & Triangular & Uniform & Triangular " _n ; 
file close fh ; 
} ;
**** Tab. S15: o o o Donut RD test o o o o o o o o o o o o o o o o o o o o o o ; 
{ ;
cap file close fh ; 
file open fh using "$outputs/table_s15.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" & \multicolumn{6}{c}{Regression discontinuity} & \multicolumn{1}{c}{Control mean} \\" _n 
" & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} & \multicolumn{1}{c}{(7)}\\" _n 
"\midrule" _n ; 

foreach v in birthwgt lowbw elbw { ; 

	use "$clean/births_0614", clear ;

	* No donut ; 
	local j=1 ; 
	rdrobust `v' centred_dob, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
	
	* Donut radius 1 ;
	local j=2 ; 
	rdrobust `v' centred_dob if abs(centred_dob)>=1, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
	
	* Donut radius 2 ;
	local j=3 ; 
	rdrobust `v' centred_dob if abs(centred_dob)>=2, p(1) kernel(triangular) bwselect(cerrd) all ; 
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

	* Donut radius 3 ;
	local j=4 ; 
	rdrobust `v' centred_dob if abs(centred_dob)>=3, p(1) kernel(triangular) bwselect(cerrd) all ; 
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

	* Donut radius 7 ;
	local j=5 ; 
	rdrobust `v' centred_dob if abs(centred_dob)>=7, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
	
	* Donut radius 21 ;
	local j=6 ; 
	rdrobust `v' centred_dob if abs(centred_dob)>=21, p(1) kernel(triangular) bwselect(cerrd) all ; 
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
	
	file write fh "`:var label `v'' & `rd1'`stars1'& `rd2'`stars2'& `rd3'`stars3'& `rd4'`stars4'& `rd5'`stars5' & `rd6'`stars6' & `ymean' \\"  _n ; 
	file write fh "& (`rdse1')& (`rdse2')& (`rdse3')& (`rdse4')& (`rdse5') & (`rdse6') \\" _n ; 
	file write fh "Bandwidth (days) & `h1' & `h2' & `h3' & `h4' & `h5' & `h6' \\" _n ; 
	file write fh "N & `n1'& `n2'& `n3'& `n4'& `n5' & `n6' & `ycount' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ; 
} ; 

file write fh "CER-optimal & X & X & X & X & X & X \\" _n ; 
file write fh "Donut-hole radius (days) & 0 & 1 & 2 & 3 & 7 & 21 & " _n ; 

file close fh ; 
} ;
**** Fig. S14: Placebo cut-off test: low birth weight (<2500g) ****************; 
{ ;
local scale = "0.06(0.005)0.085" ; 
local xscale = "-105(105)105" ; 
			
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
	
	rdrobust lowbw centred_dob `hpg_condition', p(1) kernel(triangular) h($lowbwh1) b($lowbwb1) all ; 
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
	global outcome `:var label lowbw' ; 
	
	keep if centred_dob>=-`h' & centred_dob<=`h' ; 
			
	reg lowbw centred_dob if centred_dob<0 ; 
	predict yhat if centred_dob<0 ; 
	
	reg lowbw centred_dob if centred_dob>=0 ; 
	predict yhat2 if centred_dob>=0 ;
	
	gen bin = floor(centred_dob/7) ;
	
	* Collapse by bin ;
	collapse (mean) lowbw yhat yhat2, by(bin) ;

	* Scale units to mean day of bin ;
	gen centred_dob = bin*7  ;
	replace centred_dob = centred_dob+3.5 ;
			
	#delimit ; 
	
	twoway scatter lowbw centred_dob if centred_dob<0, mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| scatter lowbw centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	|| line yhat centred_dob if centred_dob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| line yhat2 centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	xline(0) 
	title("`p'", color(black)) xtitle("Actual date of birth relative to 6 April `p' (days)") ytitle("$outcome") 
	graphregion(color(white)) xlabel(`xscale') ylabel(`scale')
	legend(off)
	caption("RD $rd$stars ($rdse)", ring(0) position(4))
	;
	
	graph save "$outputs/figures/`p'_lowbw.gph", replace ;

} ; 

graph combine "$outputs/figures/2007_lowbw.gph" 
"$outputs/figures/2008_lowbw.gph"
"$outputs/figures/2010_lowbw.gph"
"$outputs/figures/2012_lowbw.gph", graphregion(color(white)) ; 
graph export "$outputs/figures/figure_s14.pdf", replace ;

erase "$outputs/figures/2007_lowbw.gph" ; 
erase "$outputs/figures/2008_lowbw.gph" ; 
erase "$outputs/figures/2010_lowbw.gph" ; 
erase "$outputs/figures/2012_lowbw.gph" ;
} ;
**** Fig. S15: Placebo cut-off test: extremely low birth weight (<1500g) ******;
{ ;

local scale = "0.006(0.002)0.016" ; 
local xscale = "-147(147)147" ; 
		
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
	
	rdrobust elbw centred_dob `hpg_condition', p(1) kernel(triangular) h($elbwh1) b($elbwb1) all ; 
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
	global outcome `:var label elbw' ; 
	
	keep if centred_dob>=-`h' & centred_dob<=`h' ; 
			
	reg elbw centred_dob if centred_dob<0 ; 
	predict yhat if centred_dob<0 ; 
	
	reg elbw centred_dob if centred_dob>=0 ; 
	predict yhat2 if centred_dob>=0 ;
	
	gen bin = floor(centred_dob/7) ;
	
	* Collapse by bin ;
	collapse (mean) elbw yhat yhat2, by(bin) ;

	* Scale units to mean day of bin ;
	gen centred_dob = bin*7  ;
	replace centred_dob = centred_dob+3.5 ;
			
	#delimit ; 
	
	twoway scatter elbw centred_dob if centred_dob<0, mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| scatter elbw centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	|| line yhat centred_dob if centred_dob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| line yhat2 centred_dob if centred_dob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	xline(0) 
	title("`p'", color(black)) xtitle("Actual date of birth relative to 6 April `p' (days)") ytitle("$outcome") 
	graphregion(color(white)) xlabel(`xscale') ylabel(`scale')
	legend(off)
	caption("RD $rd$stars ($rdse)", ring(0) position(4))
	;
	
	graph save "$outputs/figures/`p'_elbw.gph", replace ;

} ; 

graph combine "$outputs/figures/2007_elbw.gph" 
"$outputs/figures/2008_elbw.gph"
"$outputs/figures/2010_elbw.gph"
"$outputs/figures/2012_elbw.gph", graphregion(color(white)) ; 
graph export "$outputs/figures/figure_s15.pdf", replace ;

erase "$outputs/figures/2007_elbw.gph" ; 
erase "$outputs/figures/2008_elbw.gph" ; 
erase "$outputs/figures/2010_elbw.gph" ; 
erase "$outputs/figures/2012_elbw.gph" ;
} ;
**** Fig. S17: Smoking at time of delivery by quarter of birth, 2007-2015 *****;
{ ;
import excel "$data/smoking_quarterly", firstrow clear ; 

encode quarter, gen(quart) ; 

label var smoking_percent "Prop. of women known to be smoking at time of delivery" ; 

twoway line smoking_percent quart, lcolor(navy) 
graphregion(color(white)) xlabel(3(7)30,valuelabel labsize(small)) 
ylabel(,labsize(small)) 
xline(10, lcolor(cranberry) lstyle(solid)) 
xline(19, lcolor(cranberry) lstyle(solid)) 
ytitle(, size(small)) xtitle("Quarter of delivery", size(small)) ; 

graph export "$outputs/figure_s17.pdf", replace ; 
} ;



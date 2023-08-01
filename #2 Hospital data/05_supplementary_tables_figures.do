********************************************************************************
******** B05: Supplementary tables and figures with NHS hospital data **********
********************************************************************************
clear all
set more off 
capture log close 

#delimit ; 

**** Tab. S1: Summary statistics **********************************************; 
{ ; 
local outcomes "birthwgt lowbw elbw gestage premature postdur multbth anagest anagest_first anagest_second anagest_third anagest_pre25 matage white south_asian bame" ; 

use "$clean/wob_clean_hes_0615", clear ;

* Open table ;
cap file close fh ; 

file open fh using "$outputs/table_s1.tex", write replace ; 

* Create table structure ; 
file write fh
" & \multicolumn{1}{c}{}  & \multicolumn{1}{c}{} & \multicolumn{1}{c}{} & \multicolumn{1}{c}{} &\multicolumn{1}{c}{} \\" _n 
" & N & Mean & SD & Prop. complete \\" _n 
"\addlinespace \hline \addlinespace" _n ; 

* Fill in table ; 

foreach v in `outcomes' { ; 
	sum `v' ; 
	local mean = string(`r(mean)', "%10.3f") ; 
	local obs = string(`r(N)', "%10.0fc") ; 
	local sd = string(`r(sd)', "%10.3f") ; 
	count if `v'!=. ; 
	local nomi = `r(N)' ; 
	describe, short ; 
	local total =`r(N)' ; 
	local nomiprop = `nomi'/`total' ; 
	local strnomiprop = string(`nomiprop', "%10.2fc") ; 

file write fh "`:var label `v'' & `obs' & `mean' & `sd' & `strnomiprop' \\" _n ; 

} ; 

* Close file ; 
	
file close fh ; 
} ; 
**** Fig. S4: McCrary manipulation test: actual and expected week of birth ****;
{ ;
foreach t in ewd wob { ; 
	
	use "$clean/`t'_clean_hes_0614", clear ; 

	if "`t'"=="wob" { ; 
		local ytitle "Actual week of birth" ; 
		local title_detailed "Actual week of birth relative to 6 April 2009 (weeks)" ; 
	} ;
	else { ;
		local ytitle "Expected week of birth" ;
		local title_detailed "Expected week of birth relative to 6 April 2009 (weeks)" ;
	} ; 

preserve ; 

capture drop temp_* ; 
qui rddensity `t', plot plot_range(-52 52) hist_range(-52 52) genvars(temp) ; 
global rd `: di %4.2f e(T_q)' ; 
global rdp `: di %4.2f  e(pv_q)' ; 

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

local graph_opt = `"xline(0, lcolor(black) lwidth(medthin) lpattern(solid)) legend(off) xlabel(-52(26)52) xtitle("`title_detailed'") ytitle("Density") caption("RD $rd (p-value: $rdp)", ring(0) position(1)) graphregion(color(white)) title("`ytitle'", color(black))"' ; 

twoway 	`plot_histogram_l' 	 
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
	`es_plot_point_r',					
	`graph_opt' ; 
				
graph save "$outputs/figures/`t'_rddensity.gph", replace ; 
restore ; 
} ; 

graph combine "$outputs/figures/wob_rddensity.gph"
"$outputs/figures/ewd_rddensity.gph", col(1) graphregion(color(white)) ; 
graph export "$outputs/figures/figure_s4.pdf", replace ; 

erase "$outputs/figures/wob_rddensity.gph" ; 
erase "$outputs/figures/ewd_rddensity.gph" ; 
} ; 

**** Tab. S3: Summary statistics by treatment and control group ***************;
{ ; 

use "$clean/wob_clean_hes_0615", clear ; 

local outcomes "birthwgt lowbw elbw gestage premature postdur multbth anagest anagest_first anagest_second anagest_third anagest_pre25 matage white south_asian bame" ; 

* Open table ; 
cap file close fh ; 
file open fh using "$outputs/table_s3.tex", write replace ; 

* Create table structure ; 
file write fh
"&\multicolumn{3}{c}{Control group} &\multicolumn{3}{c}{Treatment group}   \\" _n 
" & N & Mean & SD & N & Mean & SD \\" _n 
"\addlinespace \hline \addlinespace \\" _n ; 

* Fill in table ; 
gen s0 = (hpg_wob==0) ; 
gen s1 = (hpg_wob==1) ; 

foreach v in `outcomes' { ; 

	forval s=0/1 { ; 
	sum `v' if s`s'==1; 
	local mean`s' = string(`r(mean)', "%10.3f") ; 
	local obs`s' = string(`r(N)', "%10.0fc") ; 
	local sd`s' = string(`r(sd)', "%10.3f") ; 

} ; 

file write fh "`:var label `v'' & `obs0' & `mean0' & `sd0' & `obs1' & `mean1' & `sd1' \\" _n ; 

} ; 

* Close file ; 
	
file close fh ; 
} ; 

**** Tab. S8: Intrauterine growth model with gestation fixed effects **********;
{ ; 

use "$clean/wob_clean_hes_0614", clear ;
	
cap file close fh ; 
file open fh using "$outputs/table_s8.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" &\multicolumn{2}{c}{Regression discontinuity} &\multicolumn{1}{c}{Control mean} \\" _n
" &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)} &\multicolumn{1}{c}{(3)} \\" _n
"\midrule" _n ;

foreach v in birthwgt lowbw elbw { ;
	
	* Non-parametric linear - no FE ;
	local j=1 ; 
	rdrobust `v' wob, p(1) kernel(triangular) bwselect(cerrd) all ; 
	global `v'h`j' = e(h_l) ; 
	global `v'b`j' = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric linear - with gestage FE ;
	local j=2 ; 
	rdrobust `v' wob, p(1) kernel(triangular) covs(gestage_23 gestage_24 gestage_25 gestage_26 gestage_27 gestage_28 gestage_29 gestage_30 gestage_31 gestage_32 gestage_33 gestage_34 gestage_35 gestage_36 gestage_37 gestage_38 gestage_39 gestage_40 gestage_41 gestage_42 gestage_43 gestage_44 gestage_45) h($`v'h1) b($`v'b1) all ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
		
	sum `v' if hpg_wob==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_wob==0 ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1' & `rd2'`stars2' & `ymean' \\" _n ;
	file write fh "& (`rdse1') & (`rdse2') \\" _n ;
	file write fh "Bandwidth (weeks) & `h1' & `h2' \\" _n ; 
	file write fh "N & `n1' & `n2' & `ycount' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ;
} ; 
	file write fh "CER-optimal & X & X \\" _n ; 
	file write fh "Gestation FE & & X & " _n ; 

file close fh ;
} ; 

**** Tab. S9: Placebo cut-off test: gestational age at 1st antenatal **********;
{ ; 
cap file close fh ; 
file open fh using "$outputs/table_s9.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" &\multicolumn{5}{c}{Regression discontinuity} &\multicolumn{1}{c}{Control mean} \\" _n
" &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)} &\multicolumn{1}{c}{(3)} &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)} &\multicolumn{1}{c}{(6)} \\" _n
"\midrule" _n ;
			
foreach p in 2007 2008 2010 2012 { ; 

if "`p'"=="2007" { ; 
local wobchange = "wob+104" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 
if "`p'"=="2008" { ; 
local wobchange = "wob+52" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 
if "`p'"=="2010" { ; 
local wobchange = "wob-52" ; 
local hpg_condition = "if hpg_wob==1" ; 
} ; 
if "`p'"=="2012" { ; 
local wobchange = "wob-156" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 

use "$clean/wob_clean_hes_0614", clear ;

di "`wobchange'" ; 
di "`hpg_condition'" ; 
replace wob = `wobchange' ; 

* Non-parametric CER-optimal ;
local j=1 ; 
local bandwidth "anagesth`j'wob" ; 
local bias_bandwidth "anagestb`j'wob" ; 
rdrobust anagest wob `hpg_condition', p(1) h($`bandwidth') b($`bias_bandwidth') all ; 
global cerrd = e(h_l) ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric MSE-optimal ;
local j=2 ; 
local bandwidth "anagesth`j'wob" ; 
local bias_bandwidth "anagestb`j'wob" ; 
rdrobust anagest wob `hpg_condition', p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal - with uniform kernel ;
local j=3 ; 
local bandwidth "anagesth`j'wob" ; 
local bias_bandwidth "anagestb`j'wob" ; 
rdrobust anagest wob `hpg_condition', p(1) kernel(uniform) h($`bandwidth') b($`bias_bandwidth') all ; 
global cerrd = e(h_l) ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal - with controls ;
local j=4 ; 
local bandwidth "anagesth`j'wob" ; 
local bias_bandwidth "anagestb`j'wob" ; 
rdrobust anagest wob `hpg_condition', p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all covs(matage multbth white); 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal *for this cut-off ;
local j=5 ; 
local bandwidth "anagesth`j'wob" ; 
local bias_bandwidth "anagestb`j'wob" ; 
rdrobust anagest wob `hpg_condition', p(1) kernel(triangular) bwselect(cerrd) all ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
			
sum anagest `hpg_condition' & wob<0 ; 
local ymean=string(`r(mean)', "%4.3f") ; 
count `hpg_condition' & wob<0 & anagest!=. ; 
local ycount=string(`r(N)', "%10.0fc") ; 

file write fh "April `p' & `rd1'`stars1' & `rd2'`stars2' & `rd3'`stars3' & `rd4'`stars4' & `rd5'`stars5'& `ymean' \\" _n ;
file write fh "& (`rdse1') & (`rdse2') & (`rdse3') & (`rdse4') & (`rdse5') \\" _n ;
file write fh " Bandwidth (weeks) & `h1' & `h2' & `h3' & `h4' & `h5' \\" _n ; 
file write fh " N & `n1' & `n2' & `n3' & `n4' & `n5' & `ycount' \\" _n ; 
file write fh "\addlinespace \hline \addlinespace" _n ;
} ; 
file write fh "CER-optimal & & & & & X \\" _n ; 
file write fh "Controls & & & & X \\" _n ; 
file write fh "Kernel & Triangular & Triangular & Uniform & Triangular & Triangular " _n ; 
file close fh ;
} ; 

**** Tab. S10: Effects on timing of antenatal engagement **********************;
{ ; 
use "$clean/wob_clean_hes_0614", clear ;

cap file close fh ; 
file open fh using "$outputs/table_s10.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" &\multicolumn{4}{c}{Regression discontinuity} &\multicolumn{1}{c}{Control mean} \\" _n
" &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)} &\multicolumn{1}{c}{(3)} &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)} \\" _n
"\midrule" _n ;

foreach v in anagest anagest_first anagest_second anagest_third anagest_pre25 { ;
	
	* Non-parametric CER-optimal ;
	local j=1 ; 
	rdrobust `v' wob, p(1) kernel(triangular) bwselect(cerrd) all ; 
	global `v'h`j'wob = e(h_l) ; 
	global `v'b`j'wob = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric MSE-optimal ;
	local j=2 ; 
	rdrobust `v' wob, p(1) kernel(triangular) bwselect(mserd) all ; 
	global `v'h`j'wob = e(h_l) ; 
	global `v'b`j'wob = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric CER-optimal - with uniform kernel ;
	local j=3 ; 
	rdrobust `v' wob, p(1) kernel(uniform) bwselect(cerrd) all ; 
	global `v'h`j'wob = e(h_l) ; 
	global `v'b`j'wob = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric CER-optimal - with controls ;
	local j=4 ; 
	rdrobust `v' wob, p(1) kernel(triangular) bwselect(cerrd) all covs(matage multbth white); 
	global `v'h`j'wob = e(h_l) ; 
	global `v'b`j'wob = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
				
	sum `v' if hpg_wob==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_wob==0 & `v'!=. ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1' & `rd2'`stars2' & `rd3'`stars3' & `rd4'`stars4' & `ymean' \\" _n ;
	file write fh "& (`rdse1') & (`rdse2') & (`rdse3') & (`rdse4') \\" _n ;
	file write fh "Bandwidth (weeks) & `h1' & `h2' & `h3' & `h4' \\" _n ; 
	file write fh "N & `n1' & `n2' & `n3' & `n4' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ;
} ; 
	file write fh "CER-optimal & X & & X & X \\" _n ; 
	file write fh "MSE-optimal & & X \\" _n ; 
	file write fh "Controls & & & & X \\" _n ; 
	file write fh "Kernel & Triangular & Triangular & Uniform & Triangular " _n ; 

file close fh ;
} ; 

**** Tab. S13: RD estimates with expected WOB as the running variable *********; 
{ ; 
use "$clean/ewd_clean_hes_0614", clear ;
	
cap file close fh ; 
file open fh using "$outputs/table_s13.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" &\multicolumn{4}{c}{Regression discontinuity} &\multicolumn{1}{c}{Control mean} \\" _n
" &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)} &\multicolumn{1}{c}{(3)} &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)} \\" _n
"\midrule" _n ;

foreach v in birthwgt lowbw elbw gestage premature anagest { ;
	
	* Non-parametric CER-optimal ;
	local j=1 ; 
	rdrobust `v' ewd, p(1) kernel(triangular) bwselect(cerrd) all ; 
	global `v'h`j'ewd = e(h_l) ; 
	global `v'b`j'ewd = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric MSE-optimal ;
	local j=2 ; 
	rdrobust `v' ewd, p(1) kernel(triangular) bwselect(mserd) all ; 
	global `v'h`j'ewd = e(h_l) ; 
	global `v'b`j'ewd = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric CER-optimal - with uniform kernel ;
	local j=3 ; 
	rdrobust `v' ewd, p(1) kernel(uniform) bwselect(cerrd) all ; 
	global `v'h`j'ewd = e(h_l) ; 
	global `v'b`j'ewd = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric CER-optimal - with controls ;
	local j=4 ; 
	rdrobust `v' ewd, p(1) kernel(triangular) bwselect(cerrd) all covs(matage multbth white); 
	global `v'h`j'ewd = e(h_l) ; 
	global `v'b`j'ewd = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
				
	sum `v' if hpg_ewd==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_ewd==0 & `v'!=. ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1' & `rd2'`stars2' & `rd3'`stars3' & `rd4'`stars4' & `ymean' \\" _n ;
	file write fh "& (`rdse1') & (`rdse2') & (`rdse3') & (`rdse4') \\" _n ;
	file write fh "Bandwidth (weeks) & `h1' & `h2' & `h3' & `h4' \\" _n ; 
	file write fh "N & `n1' & `n2' & `n3' & `n4' & `ycount' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ;
} ; 
	file write fh "CER-optimal & X & & X & X \\" _n ; 
	file write fh "MSE-optimal & & X \\" _n ; 
	file write fh "Controls & & & & X \\" _n ; 
	file write fh "Kernel & Triangular & Triangular & Uniform & Triangular " _n ; 

file close fh ;

di $birthwgth1_ewd ; 
} ; 

**** Tab. S14: Full RD estimates with actual WOB as the running variable ******; 
{ ;
use "$clean/wob_clean_hes_0614", clear ;
	
cap file close fh ; 
file open fh using "$outputs/table_s14.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" &\multicolumn{4}{c}{Regression discontinuity} &\multicolumn{1}{c}{Control mean} \\" _n
" &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)} &\multicolumn{1}{c}{(3)} &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)} \\" _n
"\midrule" _n ;

foreach v in birthwgt lowbw elbw gestage premature anagest { ;
	
	* Non-parametric CER-optimal ;
	local j=1 ; 
	rdrobust `v' wob, p(1) kernel(triangular) bwselect(cerrd) all ; 
	global `v'h`j'wob = e(h_l) ; 
	global `v'b`j'wob = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric MSE-optimal ;
	local j=2 ; 
	rdrobust `v' wob, p(1) kernel(triangular) bwselect(mserd) all ; 
	global `v'h`j'wob = e(h_l) ; 
	global `v'b`j'wob = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric CER-optimal - with uniform kernel ;
	local j=3 ; 
	rdrobust `v' wob, p(1) kernel(uniform) bwselect(cerrd) all ; 
	global `v'h`j'wob = e(h_l) ; 
	global `v'b`j'wob = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
	
	* Non-parametric CER-optimal - with controls ;
	local j=4 ; 
	rdrobust `v' wob, p(1) kernel(triangular) bwselect(cerrd) all covs(matage multbth white); 
	global `v'h`j'wob = e(h_l) ; 
	global `v'b`j'wob = e(b_l) ; 
	matrix b`j' = e(b) ;
	local rd`j' `: di %4.3f  b`j'[1,3]' ;
	mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
	local rdse`j' `: di %4.3f  se`j'[3,1]' ;
	local p`j' = e(pv_rb) ;
	if `p`j'' < 0.01 {; local stars`j' = "***"; };
	if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
	if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
	if `p`j'' > 0.1 {; local stars`j' = ""; };
	di `p`j'' ;
	local h`j' = string(e(h_l), "%10.2f") ; 
	local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
				
	sum `v' if hpg_wob==0 ; 
	local ymean=string(`r(mean)', "%4.3f") ; 
	count if hpg_wob==0 & `v'!=. ; 
	local ycount=string(`r(N)', "%10.0fc") ; 
	
	file write fh "`:var label `v'' & `rd1'`stars1' & `rd2'`stars2' & `rd3'`stars3' & `rd4'`stars4' & `ymean' \\" _n ;
	file write fh "& (`rdse1') & (`rdse2') & (`rdse3') & (`rdse4') \\" _n ;
	file write fh "Bandwidth (weeks) & `h1' & `h2' & `h3' & `h4' \\" _n ; 
	file write fh "N & `n1' & `n2' & `n3' & `n4' & `ycount' \\" _n ; 
	file write fh "\addlinespace \hline \addlinespace" _n ;
} ; 
	file write fh "CER-optimal & X & & X & X \\" _n ; 
	file write fh "MSE-optimal & & X \\" _n ; 
	file write fh "Controls & & & & X \\" _n ; 
	file write fh "Kernel & Triangular & Triangular & Uniform & Triangular " _n ; 

file close fh ;

di $birthwgth1_wob ; 
} ; 

**** Fig. S10-S13: Results with actual vs expected WOB as the running variable ; 
{ ; 
local outcomes "birthwgt lowbw elbw premature" ; 

foreach v in `outcomes' { ;
	
	if "`v'"=="birthwgt" { ;
	local scale = "3245(40)3365" ; 
	local xscale = "-9(3)9" ; 
	} ; 
	if "`v'"=="lowbw" { ;
	local scale = "0.05(0.01)0.1" ; 
	local xscale = "-12(6)12" ; 
	} ; 
	if "`v'"=="elbw" { ;
	local scale = "0.006(0.012)0.03" ; 
	local xscale = "-15(5)15" ; 
	} ; 
	if "`v'"=="premature" { ; 
	local scale = "0.05(0.02)0.09" ;
	local xscale = "-17(17)17" ; 
	} ; 
	
	foreach t in ewd wob { ;
	
	if "`t'"=="wob" { ; 
		local title "Actual week of birth" ; 
	} ; 
	else { ; 
		local title "Expected week of birth" ; 
	} ;

	use "$clean/`t'_clean_hes_0614", clear ;
	
	local bandwidth "`v'h1ewd" ; 
	local bias_bandwidth "`v'b1ewd" ; 
	rdrobust `v' `t', p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all ;
	local h = floor(e(h_l)) ; 
	matrix b = e(b) ;
	global rd `: di %4.3f  b[1,3]' ;
	mata st_matrix("se",sqrt(diagonal(st_matrix("e(V)")))) ;
	matrix list se ;
	global rdse `: di %4.3f  se[3,1]' ;
	global treat `:var label `t'' ;
	global outcome `:var label `v'' ;
	global p = e(pv_rb) ;
	di $p ;
	if $p < 0.01 {; global stars = "***"; };
	if $p < 0.05 & $p >= 0.01 {; global stars = "**"; };
	if $p < 0.1 & $p >= 0.05 {; global stars = "*"; };
	if $p > 0.1 {; global stars = ""; };
	di $p ;

	keep if `t'>=-`h' & `t'<=`h' ;
	
	reg `v' `t' if `t'<0 ; 
	predict yhat if `t'<0 ; 
	
	reg `v' `t' if `t'>=0 ; 
	predict yhat2 if `t'>=0 ; 
		
	preserve ;
	collapse `v' yhat yhat2, by(`t') ;
	
	br ; 
	
	twoway scatter `v' `t' if `t'<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
		|| scatter `v' `t' if `t'>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
		|| line yhat `t' if `t'<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
		|| line yhat2 `t' if `t'>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
		xline(0) 
		xtitle("$treat") ytitle("$outcome") xlabel(`xscale') ylabel(`scale')
		graphregion(color(white)) 
		title("`title'", color(black))
		legend(off)
		caption("RD $rd$stars ($rdse)", ring(0) position(4))
		;

	restore ;
	
	graph save "$outputs/figures/`v'_`t'.gph", replace ; 
} ;
} ;

graph combine "$outputs/figures/birthwgt_wob.gph" 
"$outputs/figures/birthwgt_ewd.gph",
graphregion(color(white)) ;
graph export "$outputs/figures/figure_s10.pdf", replace ; 

graph combine "$outputs/figures/lowbw_wob.gph" 
"$outputs/figures/lowbw_ewd.gph",
graphregion(color(white)) ;
graph export "$outputs/figures/figure_s11.pdf", replace ; 

graph combine "$outputs/figures/elbw_wob.gph" 
"$outputs/figures/elbw_ewd.gph",
graphregion(color(white)) ;
graph export "$outputs/figures/figure_s12.pdf", replace ; 

graph combine "$outputs/figures/premature_wob.gph" 
"$outputs/figures/premature_ewd.gph",
graphregion(color(white)) ;
graph export "$outputs/figures/figure_s13.pdf", replace ; 

foreach v in birthwgt lowbw elbw premature { ; 
	erase "$outputs/figures/`v'_wob.gph" ;
	erase "$outputs/figures/`v'_ewd.gph" ;
} ;  
} ; 

**** Tab. S16: Placebo cut-off tests with expected WOB as the running variable ; 
{ ; 
cap file close fh ; 
file open fh using "$outputs/table_s16.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" &\multicolumn{5}{c}{Regression discontinuity} &\multicolumn{1}{c}{Control mean} \\" _n
" &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)} &\multicolumn{1}{c}{(3)} &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)} &\multicolumn{1}{c}{(6)} \\" _n
"\midrule" _n ;
			
foreach p in 2007 2008 2010 2012 { ; 

if "`p'"=="2007" { ; 
local wobchange = "ewd+104" ; 
local hpg_condition = "if hpg_ewd==0" ; 
} ; 
if "`p'"=="2008" { ; 
local wobchange = "ewd+52" ; 
local hpg_condition = "if hpg_ewd==0" ; 
} ; 
if "`p'"=="2010" { ; 
local wobchange = "ewd-52" ; 
local hpg_condition = "if hpg_ewd==1" ; 
} ; 
if "`p'"=="2012" { ; 
local wobchange = "ewd-156" ; 
local hpg_condition = "if hpg_ewd==0" ; 
} ; 

use "$clean/ewd_clean_hes_0614", clear ;

di "`wobchange'" ; 
di "`hpg_condition'" ; 
replace ewd = `wobchange' ; 

* Non-parametric CER-optimal ;
local j=1 ; 
local bandwidth "birthwgth`j'ewd" ; 
local bias_bandwidth "birthwgtb`j'ewd" ; 
rdrobust birthwgt ewd `hpg_condition', p(1) h($`bandwidth') b($`bias_bandwidth') all ; 
global cerrd = e(h_l) ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric MSE-optimal ;
local j=2 ; 
local bandwidth "birthwgth`j'ewd" ; 
local bias_bandwidth "birthwgtb`j'ewd" ; 
rdrobust birthwgt ewd `hpg_condition', p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal - with uniform kernel ;
local j=3 ; 
local bandwidth "birthwgth`j'ewd" ; 
local bias_bandwidth "birthwgtb`j'ewd" ; 
rdrobust birthwgt ewd `hpg_condition', p(1) kernel(uniform) h($`bandwidth') b($`bias_bandwidth') all ; 
global cerrd = e(h_l) ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal - with controls ;
local j=4 ; 
local bandwidth "birthwgth`j'ewd" ; 
local bias_bandwidth "birthwgtb`j'ewd" ; 
rdrobust birthwgt ewd `hpg_condition', p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all covs(matage multbth white); 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal *for this cut-off ;
local j=5 ; 
local bandwidth "birthwgth`j'ewd" ; 
local bias_bandwidth "birthwgtb`j'ewd" ; 
rdrobust birthwgt ewd `hpg_condition', p(1) kernel(triangular) bwselect(cerrd) all ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
			
sum birthwgt `hpg_condition' & ewd<0 ; 
local ymean=string(`r(mean)', "%4.3f") ; 
count `hpg_condition' & ewd<0 & birthwgt!=. ; 
local ycount=string(`r(N)', "%10.0fc") ; 

file write fh "April `p' & `rd1'`stars1' & `rd2'`stars2' & `rd3'`stars3' & `rd4'`stars4' & `rd5'`stars5'& `ymean' \\" _n ;
file write fh "& (`rdse1') & (`rdse2') & (`rdse3') & (`rdse4') & (`rdse5') \\" _n ;
file write fh " Bandwidth (weeks) & `h1' & `h2' & `h3' & `h4' & `h5' \\" _n ; 
file write fh " N & `n1' & `n2' & `n3' & `n4' & `n5' & `ycount' \\" _n ; 
file write fh "\addlinespace \hline \addlinespace" _n ;
} ; 
file write fh "CER-optimal & & & & & X \\" _n ; 
file write fh "Controls & & & & X \\" _n ; 
file write fh "Kernel & Triangular & Triangular & Uniform & Triangular & Triangular " _n ; 
file close fh ;
} ; 

**** Tab. S17: Placebo cut-off test: prematurity ******************************;
{ ; 
cap file close fh ; 
file open fh using "$outputs/table_s17.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" &\multicolumn{5}{c}{Regression discontinuity} &\multicolumn{1}{c}{Control mean} \\" _n
" &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)} &\multicolumn{1}{c}{(3)} &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)} &\multicolumn{1}{c}{(6)} \\" _n
"\midrule" _n ;
			
foreach p in 2007 2008 2010 2012 { ; 

if "`p'"=="2007" { ; 
local wobchange = "wob+104" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 
if "`p'"=="2008" { ; 
local wobchange = "wob+52" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 
if "`p'"=="2010" { ; 
local wobchange = "wob-52" ; 
local hpg_condition = "if hpg_wob==1" ; 
} ; 
if "`p'"=="2012" { ; 
local wobchange = "wob-156" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 

use "$clean/wob_clean_hes_0614", clear ;

di "`wobchange'" ; 
di "`hpg_condition'" ; 
replace wob = `wobchange' ; 

* Non-parametric CER-optimal ;
local j=1 ; 
local bandwidth "prematureh`j'wob" ; 
local bias_bandwidth "prematureb`j'wob" ; 
rdrobust premature wob `hpg_condition', p(1) h($`bandwidth') b($`bias_bandwidth') all ; 
global cerrd = e(h_l) ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric MSE-optimal ;
local j=2 ; 
local bandwidth "prematureh`j'wob" ; 
local bias_bandwidth "prematureb`j'wob" ; 
rdrobust premature wob `hpg_condition', p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal - with uniform kernel ;
local j=3 ; 
local bandwidth "prematureh`j'wob" ; 
local bias_bandwidth "prematureb`j'wob" ; 
rdrobust premature wob `hpg_condition', p(1) kernel(uniform) h($`bandwidth') b($`bias_bandwidth') all ; 
global cerrd = e(h_l) ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal - with controls ;
local j=4 ; 
local bandwidth "prematureh`j'wob" ; 
local bias_bandwidth "prematureb`j'wob" ; 
rdrobust premature wob `hpg_condition', p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all covs(matage multbth white); 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;

* Non-parametric CER-optimal *for this cut-off ;
local j=5 ; 
local bandwidth "prematureh`j'wob" ; 
local bias_bandwidth "prematureb`j'wob" ; 
rdrobust premature wob `hpg_condition', p(1) kernel(triangular) bwselect(cerrd) all ; 
matrix b`j' = e(b) ;
local rd`j' `: di %4.3f  b`j'[1,3]' ;
mata st_matrix("se`j'",sqrt(diagonal(st_matrix("e(V)")))) ;
local rdse`j' `: di %4.3f  se`j'[3,1]' ;
local p`j' = e(pv_rb) ;
if `p`j'' < 0.01 {; local stars`j' = "***"; };
if `p`j'' < 0.05 & `p`j'' >= 0.01 {; local stars`j' = "**"; };
if `p`j'' < 0.1 & `p`j'' >= 0.05 {; local stars`j' = "*"; };
if `p`j'' > 0.1 {; local stars`j' = ""; };
di `p`j'' ;
local h`j' = string(e(h_l), "%10.2f") ; 
local n`j'=string(e(N_h_l) + e(N_h_r),"%10.0fc")  ;
			
sum premature `hpg_condition' & wob<0 ; 
local ymean=string(`r(mean)', "%4.3f") ; 
count `hpg_condition' & wob<0 & premature!=. ; 
local ycount=string(`r(N)', "%10.0fc") ; 

file write fh "April `p' & `rd1'`stars1' & `rd2'`stars2' & `rd3'`stars3' & `rd4'`stars4' & `rd5'`stars5'& `ymean' \\" _n ;
file write fh "& (`rdse1') & (`rdse2') & (`rdse3') & (`rdse4') & (`rdse5') \\" _n ;
file write fh " Bandwidth (weeks) & `h1' & `h2' & `h3' & `h4' & `h5' \\" _n ; 
file write fh " N & `n1' & `n2' & `n3' & `n4' & `n5' & `ycount' \\" _n ; 
file write fh "\addlinespace \hline \addlinespace" _n ;
} ; 
file write fh "CER-optimal & & & & & X \\" _n ; 
file write fh "Controls & & & & X \\" _n ; 
file write fh "Kernel & Triangular & Triangular & Uniform & Triangular & Triangular " _n ; 
file close fh ;
} ; 

**** Fig. S16: Placebo cut-off test: prematurity ******************************;
{ ; 
local scale = "0.05(0.02)0.09" ;
local xscale = "-15(5)15" ; 
	
foreach p in 2007 2008 2010 2012 { ; 

if "`p'"=="2007" { ; 
local wobchange = "wob+104" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 
if "`p'"=="2008" { ; 
local wobchange = "wob+52" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 
if "`p'"=="2010" { ; 
local wobchange = "wob-52" ; 
local hpg_condition = "if hpg_wob==1" ; 
} ; 
if "`p'"=="2012" { ; 
local wobchange = "wob-156" ; 
local hpg_condition = "if hpg_wob==0" ; 
} ; 
	
use "$clean/wob_clean_hes_0614", clear ;

* Re-centre to placebo cut-off ;
replace wob = `wobchange' ;

local bandwidth "prematureh1wob" ; 
local bias_bandwidth "prematureb1wob" ; 
rdrobust premature wob `hpg_condition', p(1) kernel(triangular) h($`bandwidth') b($`bias_bandwidth') all ; 
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

br ; 

twoway scatter premature wob if wob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| scatter premature wob if wob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	|| line yhat wob if wob<0 , mcolor(gs5) msymbol(smcircle_hollow) lcolor(gs5)
	|| line yhat2 wob if wob>=0 , mcolor(gs5) msymbol(smcircle) lcolor(gs5)
	xline(0) 
	xtitle("$treat", size(small)) ytitle("$outcome", size(small))
	xlabel(`xscale', labsize(small)) 
	ylabel(`scale', labsize(small))
	title("`p'", color(black))
	graphregion(color(white)) 
	legend(off)
	caption("RD $rd$stars ($rdse)", ring(0) position(4))
	;

restore ;

graph save "$outputs/figures/`p'_premature_wob.gph", replace ;
	
} ; 
graph combine
"$outputs/figures/2007_premature_wob.gph"
"$outputs/figures/2008_premature_wob.gph"
"$outputs/figures/2010_premature_wob.gph"
"$outputs/figures/2012_premature_wob.gph", graphregion(color(white))
; 

graph export "$outputs/figures/figure_s16.pdf", replace ;

erase "$outputs/figures/2007_premature_wob.gph" ; 
erase "$outputs/figures/2008_premature_wob.gph" ; 
erase "$outputs/figures/2010_premature_wob.gph" ; 
erase "$outputs/figures/2012_premature_wob.gph" ; 
} ; 


********************************************************************************
****************** NHS03: Main tables with NHS hospital data *******************
********************************************************************************
clear all
set more off 
capture log close 

#delimit ; 

capture confirm file "$outputs" ; 
if _rc!=0{ ; 
	shell mkdir "$outputs" ; 
} ; 

**** Tab. 3: Effect of the Health in Pregnancy Grant on gestational length, prematurity and antenatal engagement *************************************;
{ ;
	
use "$clean/wob_clean_hes_0614", clear ;
	
cap file close fh ; 
file open fh using "$outputs/table_3.tex", write replace ; 

* Create table skeleton ; 
file write fh 
" &\multicolumn{4}{c}{Regression discontinuity} &\multicolumn{1}{c}{Control mean} \\" _n
" &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)} &\multicolumn{1}{c}{(3)} &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)} \\" _n
"\midrule" _n ;

foreach v in gestage premature anagest { ;
	
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




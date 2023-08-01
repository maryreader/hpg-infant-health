********************************************************************************
******** PUB00: Supplementary tables and figures with published data ***********
********************************************************************************

clear all
set more off 
capture log close 

* Stata 17.0

global data "INSERT DATA PATH HERE"
global outputs "INSERT OUTPUT PATH HERE"

#delimit ; 

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

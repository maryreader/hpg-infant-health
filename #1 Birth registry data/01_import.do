********************************************************************************
******************** ONS01: Import birth registry data *************************
********************************************************************************
clear all
set more off 
capture log close 

forval y=2006/2014{
	import spss "$raw/births`y'.sav", clear 
	save "$raw/births`y'.dta", replace
}

********************************************************************************
************* Master Do File #2: Run All NHS Hospital Code (HES) ***************
********************************************************************************
clear all
set more off 
capture log close

* Stata 17.0 
* rdrobust version 9.0.5 
* rddensity version 2.3 

global project "INSERT PROJECT PATH HERE"
global raw "INSERT RAW DATA PATH HERE"

global dofiles "$project/do_files/hpg/github"
global import "$project/import/version_a/github"
global clean "/$project/processed/version_a/hpg/github"
global outputs "$project/outputs/version_a/github"

do "$dofiles/01_import.do" 
do "$dofiles/02_clean.do"
do "$dofiles/03_main_tables.do" 
do "$dofiles/04_main_figures.do" 
do "$dofiles/05_supplementary_tables_figures.do" 

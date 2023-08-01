********************************************************************************
*************** Master do file #1: Birth registry data (ONS) *******************
********************************************************************************

clear all
set more off
capture log close 

* Stata MP 16.1 
* rdrobust version 7.3.0
* parmest version 11.0
* rddensity version 2.3 

cd "P:/Working/" 

global raw "P:/Working/raw"
global clean "P:/Working/processed"
global do "P:/Working/dofiles/hpg/github"
global outputs "P:/Working/outputs/hpg/github"
global ado "R:/SOFTWARE/Stata/Stata ado/"
global temp "P:/Working/temp"

sysdir set PLUS "$ado/parmest" 
sysdir set PLUS "$ado/parmby" 
sysdir set PLUS "$ado/parmcip" 
sysdir set PLUS "$ado/rdrobust" 

do "$do/01_import.do"  
do "$do/02_clean.do" 
do "$do/03_main_tables.do"
do "$do/04_main_figures.do"
do "$do/05_supplementary_figures_tables.do" 

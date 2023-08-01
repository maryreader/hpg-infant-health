********************************************************************************
******************** HES01: Import NHS hospital data ***************************
********************************************************************************

import delim using "$raw/NIC309029_HES_APC_A_201499.txt", clear delimiters("|")
describe, short 
save "$clean/hes_1415", replace 

import delim using "$raw/NIC309029_HES_APC_A_201399.txt", clear delimiters("|")
describe, short 
save "$clean/hes_1314", replace 

import delim using "$raw/NIC309029_HES_APC_A_201299.txt", clear delimiters("|")
describe, short 
save "$clean/hes_1213", replace 

import delim using "$raw/NIC309029_HES_APC_A_201199.txt", clear delimiters("|")
describe, short 
save "$clean/hes_1112", replace 

import delim using "$raw/NIC309029_HES_APC_A_201099.txt", clear delimiters("|")
describe, short 
save "$clean/hes_1011", replace 

import delim using "$raw/NIC309029_HES_APC_A_200999.txt", clear delimiters("|")
describe, short 
save "$clean/hes_0910", replace 

import delim using "$raw/NIC309029_HES_APC_A_200899.txt", clear delimiters("|")
describe, short 
save "$clean/hes_0809", replace 

import delim using "$raw/NIC309029_HES_APC_A_200799.txt", clear delimiters("|")
describe, short 
save "$clean/hes_0708", replace 

import delim using "$raw/NIC309029_HES_APC_A_200699.txt", clear delimiters("|")
describe, short 
save "$clean/hes_0607", replace 



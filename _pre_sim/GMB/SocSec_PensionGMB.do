


/*
	Project:            GamSim 2020
	Author:             Madi Mangan
	Program Name:       03. SocialSecurityContributions.do

Modification Date:  November 2024
Comments:  				Estimated wage Income for those who report that are in this social security system. 
						It is an employer contribution to social security, but we assume that the incidence
						goes to employee.         
===========================================================================*/


********************************************************************************
*/



*******************************************************************************
* Social Security Contributions
*******************************************************************************


if $devmode ==0 {
use `02_income_tax_GMB_final', clear
}
if $devmode ==1 {
use "$presim/02_income_tax_GMB_final.dta", clear 

}

gen inclab = li	

// Generate social security forms not available in The Gambia and set the outcome to zero. 
		foreach var in csh_css csp_fnr csp_ipr csh_ipm {
			cap gen `var'=0
		}

		replace csp_ipr = inclab*$NPS_Rate
		
		label var csh_css  "Contrib. Health - CSS (labor risk & family)"
		label var csp_fnr  "Contrib. Pensions - FNR (not included in PDI)"
		label var csp_ipr  "Contrib. Pensions - IPRES (not included in PDI)"
		label var csh_ipm  "Contrib. Health salaried workers"
		
// need the dataset at household level. so we collapse		
collapse (sum) csh_css csp_fnr csp_ipr csh_ipm hhweight (mean) hhsize , by(hhid)

// save the final dataset 
		if $devmode== 1 {
			save "$tempsim/social_security_contribs.dta", replace
		}

		tempfile social_security_contribs
		save `social_security_contribs'		
		
		
		
		
		/*
// Household Labour income pension income from IHS 2020. 
use "$data_sn/Stata/PART B Section 4A-Household income.dta", clear 

		keep if inlist(s4aq1, 13)
		keep s4aq2 s4aq3 s4aq1 quarter area district lga hid
		gen hhincome_pn =  s4aq3
		lab var hhincome_pn "Household labour income"
		collapse (sum) hhincome, by(hid area district lga)
		ren (hid lga) (hhid region)

// add consumption data 
	merge 1:1 hhid using "$presim/01_menages2.dta", nogen keepusing(hhweight zref pcc) keep(match)		
		
	tempfile income
	save `income', replace  


// Indentify individuals who pays social security. 
use "$data_sn/Stata/PART A Section 1_2_3_4_6-Individual level.dta", clear 	

		gen entitled_pension_1 = .
			replace entitled_pension_1 = 1 if (ilo_lfs ==1 | ilo_lfs==2) & (s4q13 == 1) & (s4q16==1)
			replace entitled_pension_1 = 0 if entitled_pension_1 ==.
			
*/	

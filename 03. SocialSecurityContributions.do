
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

		replace csh_ipm = inclab*$NPS_Rate
		
		label var csh_css  "Contrib. Health - CSS (labor risk & family)"
		label var csp_fnr  "Contrib. Pensions - FNR (not included in PDI)"
		label var csp_ipr  "Contrib. Pensions - IPRES (not included in PDI)"
		label var csh_ipm  "Contrib. Health salaried workers"
		
// need the dataset at household level. so we collapse		
collapse (sum) csh_css csp_fnr csp_ipr csh_ipm hhweight , by(hhid)

// save the final dataset 
		if $devmode== 1 {
			save "$tempsim/social_security_contribs.dta", replace
		}

		tempfile social_security_contribs
		save `social_security_contribs'		
		
		
		


/*===========================================================================
Project:            GamSim 2024 Presim
Author:             Madi mangan
Program Name:       06_fertilizer.do
---------------------------------------------------------------------------
Creation:           July, 2024
Modification Date:  July 2024
Comments:           This is intended to produce the presim file to run ferrtilizer subsidies for the Gambia. 
===========================================================================*/



/**********************************************************************************
*            			1. Preparing data 
**********************************************************************************/ 
 
/*------------------------------------------------
* Loading data
------------------------------------------------*/

*----- Data on fertilizer use from Africultural holding data. 



use "$data_sn/PART B Section 3A-Agriculture holding.dta", clear 

		gen fert_use = s3aq15 ==1
		gen gov_fert = s3aq17 == 3

		ren hid hhid 
		gen use_fert = 0
		replace use_fert = 1 if fert_use ==1 & gov_fert ==1
		
		collapse (max) use_fert gov_fert fert_use, by(hhid)
tempfile fert
save `fert', replace 

/*------------------------------------------------
* Fertilizer data 
------------------------------------------------*/

use "$presim/05_purchases_hhid_codpr.dta", clear
cap ren hhid hid
		merge m:1 hid using "$data_sn/GMB_IHS2020_E_hhsize.dta" , nogen keepusing(wta_hh_c nfdelec lga district) assert(matched)
		ren (wta_hh_c lga nfdelec hid) (hhweight region depan1 hhid)
		merge m:1 hhid using `fert', keep(matched) nogen


		replace depan = depan1 if codpr == 343
		gen codpr_fert = codpr == 343 // fertilizer product code

		drop hsize 
		keep if codpr_fert == 1 
		drop if hhweight == . 

		*----- HH Coverage
		gen hh_fert = depan > 0                         // Option 1: 
		replace hh_fert = 1 if use_fert ==1 & depan ==0 // Option 2: 
		
		gen hh_fert_1 = depan > 0 // Option 1: HH uses fertilizer
		gen hh_fert_2 = use_fert ==1 // Option 2: 
		
		
/*
*  Define the quantity use
*/		gen price = 1100
		gen qty_bag = depan/ price if codpr ==343
		ren qty_bag consumption_fertilizer
		
		keep hhid codpr consumption_fertilizer  hh_fert* codpr_fert depan
		
save "$presim/08_subsidies_fertilizer.dta", replace

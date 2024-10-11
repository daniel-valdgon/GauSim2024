

/*===========================================================================
Project:            GamSim 2024 Presim
Author:             Madi mangan
Program Name:       06_fuels.do
---------------------------------------------------------------------------
Creation:           July, 2024
Modification Date:  July 2024
Comments:           This is adopted from the Senegal tool. 
===========================================================================*/

/*--------------------------------------------------------------------------*/
noi dis "1. Backing out consumption from fuels spending "
/*--------------------------------------------------------------------------*/

use "$presim/05_purchases_hhid_codpr.dta", clear

*I need subbsidized prices from survey year. This works because I ran 01. Pullglobals in the PreSim Master
foreach globy in sp_petrol sp_diesel sp_Kerosene {
	global `globy'_SY ${`globy'}
	dis "`globy': " ${`globy'}
}


gen q_petrol     = depan/${sp_petrol_SY}  if inlist(codpr, 754) //
gen q_diesel = depan/${sp_diesel_SY} if inlist(codpr, 276)     		 // 
gen q_Kerosene   = depan/${sp_Kerosene_SY}   if inlist(codpr, 44) 			 // 



// generate fake variables with zeros to replicate senegal dataset.
foreach y in q_fuel q_pet_lamp q_butane {
	cap gen `y' = 0
}

collapse (sum) q_fuel q_pet_lamp q_butane q_petrol q_diesel q_Kerosene, by(hhid) 

save "$presim/06_fuels.dta", replace



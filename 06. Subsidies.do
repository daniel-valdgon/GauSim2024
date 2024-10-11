/********************************************************************************
********************************************************************************
* Program: Subsidies
* Date: March 2024
* Version: 1.0

Modified: Generalize the electricity subsidies to include fixed cost 
			
*--------------------------------------------------------------------------------

************************************************************************************/
noi dis as result " 1. Subvention directe à l'Électricité                          "
************************************************************************************

noi use "$presim/08_subsidies_elect.dta", clear 

keep hhid consumption_electricite type_client prepaid_woyofal

*Define tranches for subsidies consumption_electricite is bimonthly so intervals should also be bimonthly 

forval i=1/7{
	gen tranche`i'_tool=. //(AGV) The user can use up to 7 tranches in the tool, but certainly most of them will not be used
}
 
foreach payment in 0 1 {  	
		
	if "`payment'"=="1" local tpay "W"			// Prepaid (Woyofal)
	else if "`payment'"=="0" local tpay "P"		// Postpaid

	foreach pui in DPP DMP DGP{
		if ("`pui'"=="DPP") local client=1
		if ("`pui'"=="DMP") local client=2
		if ("`pui'"=="DGP") local client=3
		if strlen(`"$tholdsElec`tpay'`pui'"')>0{ //This should skip those cases where the combination puissance*payment does not exist (basically WDGP)
			local i=0
			global MaxT0_`tpay'`pui' 0 //This "tranche 0" is helpful for the next loops
			foreach tranch in ${tholdsElec`tpay'`pui'}{
				local j = `i'+1
				replace tranche`j'_tool=${Max`tranch'_`tpay'`pui'}-${MaxT`i'_`tpay'`pui'} if consumption_electricite>=${Max`tranch'_`tpay'`pui'} & type_client==`client' & prepaid_woyofal==`payment'
				replace tranche`j'_tool=consumption_electricite-${MaxT`i'_`tpay'`pui'} if consumption_electricite<${Max`tranch'_`tpay'`pui'} & consumption_electricite>${MaxT`i'_`tpay'`pui'} & type_client==`client' & prepaid_woyofal==`payment'
				local ++i
				dis "`pui' households, prepaid=`payment', tranche `i'"
			}
		}
	}
}

forval i=1/7{
	replace tranche`i'_tool=0 if tranche`i'_tool==. & prepaid_woyofal!=.	
}

gen tranche_elec_max = .
forval i=1/7{
	local l = 8-`i'
	replace tranche_elec_max = `l' if tranche`l'_tool!=0 & tranche`l'_tool !=. & tranche_elec_max==.
	gen subsidy`i'=.
}

if $incBlockTar == 1 {
	foreach payment in  0 1 {	
		if "`payment'"=="1" local tpay "W"			// Prepaid (Woyofal)
		else if "`payment'"=="0" local tpay "P"		// Postpaid
		foreach pui in DPP DMP DGP{
			if ("`pui'"=="DPP") local client=1
			if ("`pui'"=="DMP") local client=2
			if ("`pui'"=="DGP") local client=3
			local condition_exists = strlen(`"${tholdsElec`tpay'`pui'}"')
			if `condition_exists'>0{ //This should skip those cases where the combination puissance*payment does not exist (basically WDGP)
				local i=1
				foreach tranch in ${tholdsElec`tpay'`pui'}{
					replace subsidy`i'=${Subvention`tranch'_`tpay'`pui'}*tranche`i'_tool if type_client==`client' & prepaid_woyofal==`payment'
					*noi dis "`pui' housholds, prepaid=`payment', tranche `i'"
					local ++i
				}
			}
		}
	}
}
if $incBlockTar == 0 {
	foreach payment in  0 1 {	
		if "`payment'"=="1" local tpay "W"			// Prepaid (Woyofal)
		else if "`payment'"=="0" local tpay "P"		// Postpaid
		foreach pui in DPP DMP DGP{
			if ("`pui'"=="DPP") local client=1
			if ("`pui'"=="DMP") local client=2
			if ("`pui'"=="DGP") local client=3
			local condition_exists = strlen(`"${tholdsElec`tpay'`pui'}"')
			if `condition_exists'>0{ //This should skip those cases where the combination puissance*payment does not exist (basically WDGP)
				levelsof tranche_elec_max if type_client==`client' & prepaid_woyofal==`payment', local(tranches)
				foreach tranch of local tranches {
					dis ${SubventionT`tranch'_`tpay'`pui'}
					replace subsidy1=${SubventionT`tranch'_`tpay'`pui'}*consumption_electricite  if type_client==`client' & prepaid_woyofal==`payment' & tranche_elec_max==`tranch'
				}
			}
		}
	}
}

egen subsidy_elec_direct=rowtotal(subsidy*)


*Tranches are bimonthly therefore subsidy is bimonthly. Here we convert to annual values everything 
foreach v of varlist subsidy* {
	replace `v'=6*`v'
}


forval i=1/7{
	sum tranche`i'_tool
	if `r(mean)'==0{
		drop tranche`i'_tool
	}
	sum subsidy`i'
	if `r(N)'==0{
		drop subsidy`i'
	}
}

tempfile Elec_subsidies_direct_hhid
save `Elec_subsidies_direct_hhid'

************************************************************************************/
noi dis as result " 2. Subvention indirecte à l'Électricité                        "
************************************************************************************

use "$presim/IO_Matrix_elec.dta", clear 

*Shock
gen shock=$subsidy_shock_elec if elec_sec==1
replace shock=0  if shock==.

*Indirect effects 
des sect_*, varlist 
local list "`r(varlist)'"
	
costpush `list', fixed(fixed) priceshock(shock) genptot(elec_tot_shock) genpind(elec_ind_shock) fix
	
keep sector elec_ind_shock elec_tot_shock
	
tempfile io_ind_elec
save `io_ind_elec', replace


/**********************************************************************************/
noi dis as result " 3. Direct effect of fuel subsidies                           "
/**********************************************************************************/

use "$presim/06_fuels.dta", clear

*Compute subsidy receive for each tranche of consumption 

rename q_fuel q_fuel_hh 

foreach pdto in petrol diesel Kerosene {
	gen sub_`pdto'	= .
	replace sub_`pdto'= (${mp_`pdto'}-${sp_`pdto'})*q_`pdto' 		
}



egen subsidy_fuel_direct=rowtotal(sub_petrol sub_diesel sub_Kerosene)  

if $devmode== 1 {
    save "$tempsim/fuel_dir_sub_hhid.dta", replace
}
tempfile fuel_dir_sub_hhid
save `fuel_dir_sub_hhid'



************************************************************************************
noi dis as result " 4. Indirect effects of Fuel subsidies                         "
************************************************************************************
	
// load IO
use "$presim/IO_matrix.dta", clear // this does not seems the appropriate naming in teh senegal tool. Check with Andres

*use "$presim/IO_percentage.dta", clear 
cap ren sector Secteur

gen shock = 0
replace shock = $sr_petrol 	if Secteur==7  // Gasoline
replace shock = $sr_Kerosene 			if Secteur==8  // Kerosene
replace shock = $sr_diesel 	if Secteur==10 // Diesel and others

	
// Fixed 
gen fixed=1 if inlist(Secteur,7,8,9,10,14,15,25,26,27) // health, education, electricity , oil 
replace fixed=0 if fixed==.
	
	
if $devmode== 1 {
    save "$tempsim/IO_Matrix_check.dta", replace
}

des sect_*, varlist 
local list "`r(varlist)'"

// Cost push 
costpush `list', fixed(fixed) price(shock) genptot(fuel_tot_shock) genpind(fuel_ind_shock) fix

if $devmode== 1 {
    save "$tempsim/fuel_ind_sim_Secteur.dta", replace
}
tempfile fuel_ind_sim_Secteur
save `fuel_ind_sim_Secteur', replace 


*-------- Welfare 
// Adding indirect effect to database and expanding direct effect per product (codpr)

use "$presim/05_netteddown_expenses_SY.dta", clear 
cap ren sector Secteur
merge m:1 Secteur using `fuel_ind_sim_Secteur', /* assert(matched using) */ keep(1 3) nogen  // this is a need to correct the IO_percentage file to the new IO matrix, this requires some more time.  

merge m:1 hhid using `fuel_dir_sub_hhid' , assert(matched using) keep(match) nogen   

gen subsidy_fuel_indirect=achats_net*fuel_ind_shock

rename subsidy_fuel_direct subsidy_fuel_direct_hhidlevel
gen subsidy_fuel_direct = 0
replace subsidy_fuel_direct = sub_petrol*pourcentage*pondera_informal   if codpr==754
replace subsidy_fuel_direct = sub_diesel*pourcentage*pondera_informal if codpr==276
replace subsidy_fuel_direct = sub_Kerosene*pourcentage*pondera_informal  if codpr==44


drop shock fixed fuel_ind_shock fuel_tot_shock q_* sub_*
compress
tempfile fuel_verylong
save `fuel_verylong', replace 

egen subvention_fuel=rowtotal(subsidy_fuel_indirect subsidy_fuel_direct)

collapse (sum) subsidy_fuel_indirect subsidy_fuel_direct subvention_fuel (mean) subsidy_fuel_direct_hhidlevel, by(hhid)

drop subsidy_fuel_direct_hhidlevel

if $devmode== 1 {
    save "$tempsim/Fuel_subsidies.dta", replace
}
tempfile Fuel_subsidies
save `Fuel_subsidies', replace



/***********************************************************************************
*TESTS
***********************************************************************************/

*-------- Welfare 
// Adding indirect effect to database and expanding direct effect per product (codpr)
*use "$presim/05_netteddown_expenses_SY.dta", clear 
use `fuel_verylong', clear
cap ren Secteur sector

merge m:1 hhid codpr using "$presim/08_subsidies_elect.dta", nogen keepusing(codpr_elec) keep(master match)

merge m:1 hhid using `Elec_subsidies_direct_hhid', nogen assert(using matched) keep(matched)
*merge m:1 hhid using `Water_subsidies_direct_hhid', nogen assert(using matched) keep(matched)

merge m:1 sector using `io_ind_elec', nogen assert(using matched) keep(matched)
*merge m:1 sector using `io_ind_eau', nogen assert(using matched) keep(matched)

*merge m:1 hhid codpr using `fuel_verylong', nogen assert(using matched) keep(matched)

if $devmode== 1 {
    save "$presim/Subsidies_check_correct_netdown.dta", replace
}

use "$presim/Subsidies_check_correct_netdown.dta", clear

*1. Removing direct subsidies
replace subsidy_elec_direct = 0 if codpr_elec!=1
replace subsidy_elec_direct = subsidy_elec_direct*pourcentage*pondera_informal

*replace subsidy_eau_direct = 0 if codpr!=332
*replace subsidy_eau_direct = subsidy_eau_direct*pourcentage*pondera_informal

*gen achats_sans_subs_dir = achats_net - subsidy_fuel_direct - subsidy_elec_direct - subsidy_eau_direct
gen achats_sans_subs_dir = achats_net - subsidy_elec_direct - subsidy_fuel_direct


if $asserts_ref2018 == 1{
	gen dif1 = achats_net_subind-achats_sans_subs_dir
	tab codpr if abs(dif1)>0.00001
	assert abs(dif1)<0.00001
}

*2. Removing indirect subsidies

gen subsidy_elec_indirect = achats_net * elec_ind_shock 
*gen subsidy_eau_indirect  = achats_net * eau_ind_shock

*gen achats_sans_subs = achats_sans_subs_dir - subsidy_fuel_indirect - subsidy_elec_indirect - subsidy_eau_indirect

gen achats_sans_subs = achats_sans_subs_dir - subsidy_elec_indirect - subsidy_fuel_indirect


if $asserts_ref2018 == 1{
	gen dif2 = achats_net_excise-achats_sans_subs
	tab codpr if abs(dif2)>0.00001
	assert abs(dif2)<0.00001
}

*We are interested in the detailed long version, to continue the confirmation process with excises and VAT

if $devmode== 1 {
    save "$tempsim/Subsidies_verylong.dta", replace
}
tempfile Subsidies_verylong
save `Subsidies_verylong'


* Create variables in cero
foreach var in subsidy_eau_direct subsidy_eau_indirect subsidy_agric {
	gen `var'=0
}

*Finally, we are only interested in the per-household amounts, so we will collapse the database:
collapse (sum) subsidy_fuel_direct subsidy_fuel_indirect subsidy_elec_direct subsidy_elec_indirect subsidy_eau_direct subsidy_eau_indirect subsidy_agric, by(hhid) 

*merge 1:1 hhid using `Agricultural_subsidies', nogen keepusing(subsidy_agric) 

if $devmode== 1 {
    save "$tempsim/Subsidies.dta", replace
}
tempfile Subsidies
save `Subsidies'




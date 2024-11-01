

/*==============================================================================
 The Gambia Custom Duties
 Author: Madi Mangan
 Date: OCtober 2024
 Version: 1.0

 Notes: 
	* this is a simulation dofile for custom duties in the Gambia. it is run after the presimulation (only for the first time)
	

*========================================================================================*/



use "$presim/05_purchases_hhid_codpr.dta", clear
		merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)
		collapse (sum) depan [iw=hhweight], by(codpr) 
		
		
		
/*==================================================================
-------------------------------------------------------------------*
			1. Computing direct effects of Custom Duties
-------------------------------------------------------------------*
===================================================================*/
noi dis as result " 1. direct effect of Custom duties"		


		clear
		gen codpr=.
		gen custom=.
		local i=1
		foreach prod of global products {
			set obs `i'
			qui replace codpr	 = `prod' in `i'
			qui replace custom      = ${customrate_`prod'} if codpr==`prod' in `i'
			local i=`i'+1
		}
		tempfile CUSTOMrates
		save `CUSTOMrates'
		

		if $devmode== 1 {
	*use "$presim/05_purchases_hhid_codpr.dta", clear
    use "$tempsim/Subsidies_verylong.dta", clear
}
else{
	use `Subsidies_verylong', clear
}

global depan achats_sans_subs
		
/*		
		if $devmode== 1 {
			use "$tempsim/Excises_verylong.dta", clear
		}
		else{
			use `Excises_verylong', clear
		}
*/		
merge m:1 codpr using `CUSTOMrates', nogen keep(1 3) 


* Informality simulation assumption
noi dis as result "Simulation with the assumption that informality decrease in $informal_reduc_rate %"

		egen aux = max(informal_purchase * achats_sans_subs * $informal_reduc_rate), by(hhid codpr)
		gen aux_f = (1 - informal_purchase) * (achats_sans_subs + aux) 
		gen aux_i = informal_purchase * (achats_sans_subs - aux)

		bysort hhid codpr: egen x_bef=total(achats_sans_subs)
		ereplace achats_sans_subs = rowtotal(aux_f aux_i)
		bysort hhid codpr: egen x_aft=total(achats_sans_subs)

		drop aux aux_f aux_i x_bef x_aft 

		gen Custom = achats_sans_subs * custom * (1-informal_purchase)
		
		*replace Custom = achats_sans_subs * custom

		
*We are interested in the detailed long version, to continue the confirmation process with Exises

		if $devmode== 1 {
			save "$tempsim/Custom_verylong.dta", replace
		}
		tempfile Custom_verylong
		save `Custom_verylong'		
		
*Finally, we are only interested in the per-household amounts, so we will collapse the database:	
		collapse (sum) Custom, by(hhid)
** Save final dataset 

		if $devmode== 1 {
			save "${tempsim}/custom_duties.dta", replace
		}

		tempfile Custom_duties
		save `Custom_duties'	

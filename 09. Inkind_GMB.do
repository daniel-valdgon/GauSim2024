
/*==============================================================================*\
 West Africa
 Editted by: Madi Mangan
 Start Date: June 2024
 Update Date: June 2024
 Version: 1.0
\*==============================================================================*/


/********** Education *******/


use "$presim/07_educ.dta", clear


		gen am_pre_school_pub = ${Edu_montantPrescolaire}  if ben_pre_school==1   & pub_school==1
		gen am_primary_pub    = ${Edu_montantPrimaire}     if ben_primary==1      & pub_school==1
		gen am_secondary_pub  = ${Edu_montantSecondaire}   if ben_secondary==1    & pub_school==1
		gen am_tertiary_pub   = ${Edu_montantSuperieur}    if ben_tertiary==1     & pub_school==1
		 
		collapse (sum)  am_pre_school_pub am_primary_pub am_secondary_pub am_tertiary_pub, by(hhid)
		egen education_inKind=rowtotal(am_pre_school_pub am_primary_pub am_secondary_pub am_tertiary_pub)

tempfile Transfers_InKind_Education
save `Transfers_InKind_Education'

/********** Health *******/

use "$presim/07_health.dta", clear 
 
sum publichealth [iw=hhweight]
local sante_beneficiare `r(sum)' // dis "`healthcare_benefeciaries'"

gen depense_person=$Montant_Assurance_maladie/`sante_beneficiare' 
gen am_sante=depense_person if publichealth==1

dis "$Montant_Assurance_maladie"
sum depense_person, d

collapse (sum) am_sante, by(hhid)
egen Sante_inKind=rowtotal(am_sante)
merge 1:1 hhid using `Transfers_InKind_Education', nogen


if $devmode== 1 {
    save "$tempsim/Transfers_InKind.dta", replace
}

tempfile Transfers_InKind
save `Transfers_InKind'


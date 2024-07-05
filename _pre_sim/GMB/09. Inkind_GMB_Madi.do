/*
Author     : Madi Mangan
Start date : June 2024
Last Update: June 2024 

Objective  : Presimulation for in-kind Transfer for the purpose of fiscal microsimulation to study the incidence of Direct transfer
           **I compile and adopt the key characteristics of the household necessary for assignment of social programmes 
*/



use "$data_sn/Health for all the Hhold Members.dta", clear 
merge m:1 hid using "$data_sn/GMB_IHS2020_E_hhsize.dta", gen(merged7) keepusing(wta_hh_c) update
ren (wta_hh_c hid)  (hhweight hhid)

*s2aq10. // what type of facility
*s2aq10a // What type of facility did [NAME] visit?


gen     hcare_level  = 1 if (s2aq10 ==  2 | s2aq10 ==  3 | s2aq10 == 4 | s2aq10 == 9)
replace hcare_level = 2 if s2aq10 ==1


gen consult_prim= hcare_level==1
gen consult_sec=  hcare_level==2


gen hospita=1 if s2aq10 ==1

		gen     freq=0
		bys id: egen consult_sec_hh=total(consult_sec)
		bys id: egen hospita_hh=total(hospita)
		bys id: egen consult_prim_hh=total(consult_prim)


gen publichealth=1 if s2aq10a == 1 // access to public health in general

keep hhid hhweight hcare_level consult_prim consult_sec hospita consult_sec_hh hospita_hh consult_prim_hh publichealth 

save "$presim/07_health.dta", replace


/*==============================================================================*\
 Senegal Standardization
 Authors: Gabriel
 Start Date: February 2024
 Update Date: February 2024
 
\*==============================================================================*/
   
	*******************************************************************
	***** GLOBAL PATHS ************************************************
	
	//Users (change this according to your own folder location)	
if "`c(username)'"=="wb621266" {
	global pathdata     "C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
	global path     	"C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
	global thedo     	"${path}/02_scripts"
	global country 		"SEN"
}

	global data_sn 		"${path}/01_data/1_raw/${country}"    
	global presim_SEN   "C:\Users\wb621266\OneDrive - WBG\Senegal_tool\Senegal_tool\01. Data\2_pre_sim"
	global presim       "${path}/01_data/2_pre_sim/${country}"

 
 
	* Senegal data with informality as a dummy
 	use "$presim_SEN/05_netteddown_expenses_SY.dta", clear
			
	gunique codpr hhid informal_purchase Secteur
	
	gduplicates tag codpr hhid informal_purchase, gen(dup)
	egen tag = tag(codpr hhid informal_purchase)
	
	tab dup tag
	tab dup pourcentage
	
	drop dup tag
	
	ren Secteur sector
	
	gsort hhid codpr informal_purchase sector
	
	*gen depan = achats_net_VAT // different  MRT

	
	*keep hhid codpr sector pourcentage informal_purchase depan achats*
	
	save "$presim/05_netteddown_expenses_SY.dta", replace
	
	
	
	
	
	


/*==============================================================================*\
 GAMSIM - Presentation do-file 
 To do: Create presentation figures and tables on In-kind Transfers
 Authors: Madi Mangan 
 Start Date: June 2024
 Update Date: June 2024
 
\*==============================================================================*/

// defile paths and directories

global path     	"/Users/manganm/Documents/GitHub/Gamsim_2024"
		global country 		"GMB"
		global presim       "${path}/01_data/2_pre_sim/${country}"
		global data_out    	"${path}/01_data/4_sim_output"
		global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_${country}_2.xlsx" 
		
		* New Params
		global xls_out    	"${path}/03_Tool/Figures_InKind_${country}.xlsx" 
		global sheetname "GMB_2020_Inkind_ref"
		global nsim 1	
		
		
		
/// ---___---____------___---____--- Marginal contributions  of Excises ---___---__---___// 

*Figure of marginal contributions
 import excel "$xls_sn", sheet(allGMB_2020_Inkind_ref) firstrow clear 
 
 ** effects on poverty - Poverty Prevalence
 // total
sum value if concat=="ymp_pc_fgt0_zref_ymp_."
assert r(N)==1
local pre = r(mean)
sum value if concat=="ymp_inc_inktransf_total_fgt0_zref_ymp_."
assert r(N)==1
local post = r(mean)
local effect_1 = round(100*(`post'-`pre'),0.0001)

// education
sum value if concat=="ymp_inc_education_inKind_fgt0_zref_ymp_."
assert r(N)==1
local post = r(mean)
local effect_2 = round(100*(`post'-`pre'),0.0001)

// Health
sum value if concat=="ymp_inc_Sante_inKind_fgt0_zref_ymp_."
assert r(N)==1
local post = r(mean)
local effect_3 = round(100*(`post'-`pre'),0.0001)

 ** effect on inequality - GINI
 // total
sum value if concat=="ymp_pc_gini__ymp_."
assert r(N)==1
local pre = r(mean)
sum value if concat=="ymp_inc_inktransf_total_gini__ymp_."
assert r(N)==1
local post = r(mean)
local effect_4 = round(100*(`post'-`pre'),0.0001)

// education 

sum value if concat=="ymp_inc_education_inKind_gini__ymp_."
assert r(N)==1
local post = r(mean)
local effect_5 = round(100*(`post'-`pre'),0.0001)

// Health
sum value if concat=="ymp_inc_Sante_inKind_gini__ymp_."
assert r(N)==1
local post = r(mean)
local effect_6 = round(100*(`post'-`pre'),0.0001)

clear 
set obs 6
gen mar =.
forval n=1/6{
	replace mar = `effect_`n'' in `n'
}
* export to excel 
global cell = "A1"
export excel using "$xls_out", sheet("fig_1", modify) first(variable) cell($cell ) keepcellfmt



/// ---------------------------------------------------------------// 
** Absolute and relative incidence of Excises by deciles 

import excel "$xls_sn", sheet(allGMB_2020_Inkind_ref) firstrow clear 

preserve
keep if measure=="benefits" 
gen keep = 0
foreach var in education_inKind Sante_inKind inktransf_total {
	replace keep = 1 if variable == "`var'_pc"
}	
keep if keep ==1 

replace variable=variable+"_ymp" if deciles_pc!=.
replace variable=variable+"_yd" if deciles_pc==.

egen decile=rowtotal(yd_deciles_pc deciles_pc)

keep decile variable value
rename value v_

reshape wide v_, i(decile) j(variable) string
drop if decile ==0
keep decile *_yd

foreach var in v_education_inKind_pc_yd v_Sante_inKind_pc_yd v_inktransf_total_pc_yd {
	egen ab_`var' = sum(`var')
	gen in_`var' = `var'*100/ab_`var'
}


ren (in_v_education_inKind_pc_yd in_v_Sante_inKind_pc_yd in_v_inktransf_total_pc_yd) (Education Health Total)

*ren in_v_excise_taxes_pc_yd Absolute_inc 
keep decile Education Health Total
*keep decile  Absolute_inc  

global cell = "A1"
export excel using "$xls_out", sheet("fig_2", modify) first(variable) cell($cell ) keepcellfmt
restore


*** relative 

keep if measure=="netcash" 
gen keep = 0
foreach var in education_inKind Sante_inKind inktransf_total {
	replace keep = 1 if variable == "`var'_pc"
}	
keep if keep ==1 

replace variable=variable+"_ymp" if deciles_pc!=.
replace variable=variable+"_yd" if deciles_pc==.

egen decile=rowtotal(yd_deciles_pc deciles_pc)


keep decile variable value
replace value = value*(-100)
rename value v_

reshape wide v_, i(decile) j(variable) string
drop if decile ==0
keep decile *_yd

ren (v_education_inKind_pc_yd v_Sante_inKind_pc_yd v_inktransf_total_pc_yd) (Education Health Total)
*ren v_excise_taxes_pc_yd Relative

global cell = "A1"
export excel using "$xls_out", sheet("fig_3", modify) first(variable) cell($cell ) keepcellfmt




// Expenditure on In-kind transfers
	
	* Gen macro for results organization

	global letters "a b c d e f g h i j k l"
	
	gen nsim = length("${sheetname}") - length(subinstr("${sheetname}", " ", "", .)) + 1
	qui sum nsim
	global nsim "`r(mean)'"
	drop nsim
	
	
	* Import and save simulation results
	forvalues i=1/$nsim {	
		
		global var : word `i' of $sheetname
		
		import excel "$xls_sn", sheet("all${var}") firstrow clear
		
		global label : word `i' of $letters
		
		gen sim = `i'
		gen sim_s = "${var}"
		
		tempfile Sim`i'
		save `Sim`i''	
	}


	* Append simulation results
	use `Sim1', clear

	forvalues i = 2/$nsim {
		append using `Sim`i''
	}

	
	save "$data_out/AllSim.dta", replace

		
	use "$data_out/AllSim.dta", clear

	* Names
	global variable "excise_taxes_pc"
	global quintil "1 2 3 4 5"

	replace variable = "a_" + variable if variable == "excise_taxes_pc"

	* Filters
	keep if inlist(variable, "a_excise_taxes_pc")
	keep if measure == "benefits"

	* 1. Grouping by quintil
	recode deciles_pc (1=1) (2=1) (3=2) (4=2) (5=3) (6=3) (7=4) (8=4) (9=5) (10=5), generate(quintil)

	collapse (sum) value, by(sim variable quintil)

	drop if quintil == 0

	replace value = value/1000000000

	* Generate matrix
	global count ""
	global rownames ""
	mat R = J(1,5,.)

	forvalues i=1/$nsim {	
		
		global count "$count A`i' \"
		
		local sim : word `i' of $sheetname
		global rownames "$rownames `sim'_$variable"
		
		tab variable quintil [iw = value] if sim == `i', matcell(A`i')
		
		sum value if sim == `i' & variable == "c_excise_taxes_pc"		
		if (r(max) == 0) mat A`i' = A`i' \ R
	}	

	global count = substr("$count", 1, length("$count")-1)
	
	mat A = $count
	mat colnames A = $quintil 
	*mat rownames A = $rownames

	matlist A

	* Print 
	putexcel set "${xls_out}", sheet("fig_4") modify
	putexcel A1 = ("Revenue") A2 = matrix(A), names

	shell ! "$xls_out"

		
		
		
	* 2. Comparison reforms on principal indicators
	use "$data_out/AllSim.dta", clear

	keep concat yd_deciles_pc measure value _population variable deciles_pc all reference sim*

	labmask sim, values(sim_s)

	global variable "ymp_pc yn_pc yd_pc yc_pc yf_pc"
	global reference "zref line_1 line_2 line_3"
	global measure "fgt0 fgt1 fgt2 gini theil"

	gen income = ""
	
	forvalues i = 1/5 {
		local l : word `i' of $letters
		local v : word `i' of $variable
		replace income = "`l'_" + variable if variable == "`v'"
		di "`l' - `v'"
	}
	

	* Filter indicators of interest
	gen test = .
	foreach i in $variable {
		foreach j in $measure {
			replace test = 1 if (variable == "`i'" &  measure == "`j'") 
		}
	}
	tab test

	keep if test == 1

	
	* Generate matrix
	global count ""
	global rownames ""
	forvalues i=1/$nsim {	
		
		global count "$count B0`i', A`i' \"
		
		local sim : word `i' of $sheetname
		global rownames "$rownames `sim'_$variable"
		
		tab income measure [iw = value] if sim == `i' & reference == "", matcell(A`i')
		tab income measure [iw = value] if sim == `i' & reference == "zref", matcell(B0`i')
		
	}	
		
	global count = substr("$count", 1, length("$count")-1)
		
	mat A = $count
	mat colnames A = $measure 
	mat rownames A = $rownames
	
	matlist A
	 
	putexcel set "${xls_out}", sheet("fig_5") modify
	putexcel A1 = ("Principal indicators - Simulations") A2 = matrix(A), names
			
		
	**** --------------------------------------- END --------------------- ---- ***	

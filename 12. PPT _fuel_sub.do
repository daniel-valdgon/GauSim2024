



global country 		"GMB"
	global path     	"/Users/manganm/Documents/GitHub/Gamsim_2024"
	global thedo     	"/Users/manganm/Documents/GitHub/vat_tool"
	global data_sn 		"${path}/01_data/1_raw/${country}"    
	global presim       "${path}/01_data/2_pre_sim/${country}"
	global tempsim      "${path}/01_data/3_temp_sim"
	global data_out    	"${path}/01_data/4_sim_output"
	global theado       "$thedo/ado"
	global xls_out    	"${path}/03_Tool/Figures_Fuel_Sub_GMB.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_GMB_2.xlsx" 
	
	global sheetname "Ref_2020"
	global nsim 1
	
	
	
	********************************************************************
	** 4. Scenario Compariston​  									  **
	********************************************************************

	*ssc install labmask
	
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

	/* Labels
	label var zref "Seuil de pauvreté national"
	label var line_1 "Seuil de pauvreté international 2.15 USD (2017 PPP)"
	label var line_2 "Seuil de pauvreté international 3.65 USD (2017 PPP)"
	label var line_3 "Seuil de pauvreté international 6.85 USD (2017 PPP)"
		
	label var ymp_pc "Revenu de marché plus pensions"
	label var yn_pc "Revenu net de marché"
	label var yd_pc "Revenu disponible"
	label var yc_pc "Revenu consommable"	
	*/

	*label values measure ""
	*label define measure measure	

	*export excel "$xls_out", sheet("all") first(variables) sheetreplace
	save "$data_out/AllSim.dta", replace

	 
	* Generate output - Compare Scenarios to print excel
	* 1. Comparison reforms on principal indicators
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
		
		*tab income measure [iw = value] if sim == `i' & reference == "line_1", matcell(B1`i')
		*tab income measure [iw = value] if sim == `i' & reference == "line_2", matcell(B2`i')
		*tab income measure [iw = value] if sim == `i' & reference == "line_3", matcell(B3`i')
	}	
		
	global count = substr("$count", 1, length("$count")-1)
		
	mat A = $count
	mat colnames A = $measure 
	mat rownames A = $rownames
	
	matlist A
	 
	putexcel set "${xls_out}", sheet("Fig_1") modify
	putexcel A1 = ("Indicadores principales - Simulaciones") A2 = matrix(A), names
	
	
	
	
	
	
	
	* 2. Total revenue by quintil
	use "$data_out/AllSim.dta", clear

	* Names
	global variable "subsidy_fuel_pc subsidy_fuel_direct_pc subsidy_fuel_indirect_pc"
	global quintil "1 2 3 4 5"

	replace variable = "a_" + variable if variable == "subsidy_fuel_pc"
	replace variable = "b_" + variable if variable == "subsidy_fuel_direct_pc"
	replace variable = "c_" + variable if variable == "subsidy_fuel_indirect_pc"

	* Filters
	keep if inlist(variable, "a_subsidy_fuel_pc", "b_subsidy_fuel_direct_pc", "c_subsidy_fuel_indirect_pc")
	keep if measure == "benefits"

	* Grouping by quintil
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
		
		sum value if sim == `i' & variable == "c_subsidy_fuel_indirect_pc"		
		if (r(max) == 0) mat A`i' = A`i' \ R
	}	

	global count = substr("$count", 1, length("$count")-1)
	
	mat A = $count
	mat colnames A = $quintil 
	mat rownames A = $rownames

	matlist A

	* Print 
	putexcel set "${xls_out}", sheet("Fig_2") modify
	putexcel A1 = ("Revenue") A2 = matrix(A), names

	shell ! "$xls_out"
	
	
	
	
	/// ---------------------------------------------------------------// 
** Absolute and relative incidence of VAT by deciles 

import excel "$xls_sn", sheet(allRef_2020) firstrow clear 

preserve
keep if measure=="benefits" 
gen keep = 0
foreach var in subsidy_fuel_direct subsidy_fuel_indirect subsidy_fuel {
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

foreach var in v_subsidy_fuel_direct_pc_yd v_subsidy_fuel_indirect_pc_yd{
	egen ab_`var' = sum(`var')
	gen in_`var' = `var'*100/ab_`var'
}

ren in_v_subsidy_fuel_direct_pc_yd direct_absolute_inc 
ren in_v_subsidy_fuel_indirect_pc_yd indirect_absolute_inc
*ren [in_v_TVA_direct_pc_yd in_v_TVA_indirect_pc_yd] [direct_absolute_inc indirect_absolute_inc]
keep decile  direct_absolute_inc indirect_absolute_inc 

global cell = "A2"
export excel using "$xls_out", sheet("Fig_3", modify) first(variable) cell($cell ) keepcellfmt

restore

*** relative 

keep if measure=="netcash" 
gen keep = 0
foreach var in subsidy_fuel_direct subsidy_fuel_indirect subsidy_fuel {
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

global cell = "A2"
export excel using "$xls_out", sheet("Fig_4", modify) first(variable) cell($cell ) keepcellfmt



/// ---___---____------___---____--- Marginal contributions  of VAT---___---__---___// 
		 
		 *Figure of marginal contributions
		 import excel "$xls_sn", sheet(allRef_2020) firstrow clear 
		 
		*Effect of VAT on ymp inequality
		// total
		sum value if concat=="ymp_pc_gini__ymp_."
		assert r(N)==1
		local pre = r(mean)
		sum value if concat=="ymp_inc_subsidy_fuel_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_1 = round(100*(`post'-`pre'),0.0001)

		// direct 
		sum value if concat=="ymp_inc_subsidy_fuel_direct_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_2 = round(100*(`post'-`pre'),0.0001) 


		// indirect 
		sum value if concat=="ymp_inc_subsidy_fuel_indirect_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_3 = round(100*(`post'-`pre'),0.0001) 

		 *Effect of VAT on ymp poverty
		 
		 // total
		sum value if concat=="ymp_pc_fgt0_zref_ymp_."
		assert r(N)==1
		local pre = r(mean)
		sum value if concat=="ymp_inc_subsidy_fuel_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_4 = round(100*(`post'-`pre'),0.0001)

		// direct 
		sum value if concat=="ymp_inc_subsidy_fuel_direct_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_5 = round(100*(`post'-`pre'),0.0001)  

		// indirect 
		sum value if concat=="ymp_inc_subsidy_fuel_indirect_fgt0_zref_ymp_."
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
		 global cell = "A2"
		 export excel using "$xls_out", sheet("Fig_5", modify) first(variable) cell($cell ) keepcellfmt
 




/*==============================================================================*\
 GAMSIM - Non-technical Presentation do-file 
 To do: Create presentation figures and tables on all policies covered by the presentation
 Authors: Madi Mangan 
 Start Date: August 2024
 Update Date: August 22, 2024
 
\*==============================================================================*/

// defile paths and directories

global path     	"/Users/manganm/Documents/GitHub/Gamsim_2024"
		global country 		"GMB"
		global presim       "${path}/01_data/2_pre_sim/${country}"
		global data_out    	"${path}/01_data/4_sim_output"
		global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_${country}_2.xlsx" 
		
		* New Params
		global xls_out    	"${path}/03_Tool/non_technical_pre_08_2024.xlsx" 
		global sheetname "Ref_2020_GMB VAT_NoExempt_GMB_2020 INF_DES10_GMB_2020 VAT_foodexempt_GMB Ref_Exc_2020_GMB Sin_Exc_2020_GMB Dir_trans_PMT_expand Revenu_recycling_GMB GMB_2020_Inkind_ref GMB_2020_Sub_ref"
		global nsim 10	
		

		
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
	 
	putexcel set "${xls_out}", sheet("fig_1") modify
	putexcel A1 = ("Principal indicators - Simulations") A2 = matrix(A), names		
	
	
	// Marginal contributions. 
	
 
  /// ---___---____------___---____--- Marginal contributions  of VAT---___---__---___// 
 
 *Figure of marginal contributions
 
 import excel "$xls_sn", sheet(allVAT_foodexempt_GMB) firstrow clear // sim 4
 *import excel "$xls_sn", sheet(allRef_2020_GMB) firstrow clear 
 *import excel "$xls_sn", sheet(allVAT_NoExempt_GMB_2020) firstrow clear
 
			 
			 
			*Effect of VAT on ymp inequality
			// total
			sum value if concat=="ymp_pc_gini__ymp_."
			assert r(N)==1
			local pre = r(mean)
			sum value if concat=="ymp_inc_Tax_TVA_gini__ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_1 = round(100*(`post'-`pre'),0.0001)

			// direct 
			sum value if concat=="ymp_inc_TVA_direct_gini__ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_2 = round(100*(`post'-`pre'),0.0001) 


			// indirect 
			sum value if concat=="ymp_inc_TVA_indirect_gini__ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_3 = round(100*(`post'-`pre'),0.0001) 

			 *Effect of VAT on ymp poverty
			 
			 // total
			sum value if concat=="ymp_pc_fgt0_zref_ymp_."
			assert r(N)==1
			local pre = r(mean)
			sum value if concat=="ymp_inc_Tax_TVA_fgt0_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_4 = round(100*(`post'-`pre'),0.0001)

			// direct 
			sum value if concat=="ymp_inc_TVA_direct_fgt0_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_5 = round(100*(`post'-`pre'),0.0001)  

			// indirect 
			sum value if concat=="ymp_inc_TVA_indirect_fgt0_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_6 = round(100*(`post'-`pre'),0.0001) 

			// poverty gap
			// total
			sum value if concat=="ymp_pc_fgt1_zref_ymp_."
			assert r(N)==1
			local pre = r(mean)
			sum value if concat=="ymp_inc_Tax_TVA_fgt1_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_7 = round(100*(`post'-`pre'),0.0001)

			// direct 
			sum value if concat=="ymp_inc_TVA_direct_fgt1_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_8 = round(100*(`post'-`pre'),0.0001)  

			// indirect 
			sum value if concat=="ymp_inc_TVA_indirect_fgt1_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_9 = round(100*(`post'-`pre'),0.0001) 
			 
			 
			 clear 
			 set obs 9
			gen mar =.
			forval n=1/9{
				replace mar = `effect_`n'' in `n'
			}
			 * export to excel 
			 global cell = "D2"
			 export excel using "$xls_out", sheet("fig_2", modify) first(variable) cell($cell ) keepcellfmt	
			 
			 
			 
	/// ---___---____------___---____--- Marginal contributions  of Excises ---___---__---___// 

*Figure of marginal contributions
 import excel "$xls_sn", sheet(allRef_Exc_2020_GMB) firstrow clear 
 
 *import excel "$xls_sn", sheet(allSin_Exc_2020_GMB) firstrow clear 
 
 
			 ** effects on poverty - Poverty Prevalence
			 // total
			sum value if concat=="ymp_pc_fgt0_zref_ymp_."
			assert r(N)==1
			local pre = r(mean)
			sum value if concat=="ymp_inc_excise_taxes_fgt0_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_1 = round(100*(`post'-`pre'),0.0001)
			 
			 ** effect on inequality - GINI
			 // total
			sum value if concat=="ymp_pc_gini__ymp_."
			assert r(N)==1
			local pre = r(mean)
			sum value if concat=="ymp_inc_excise_taxes_gini__ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_2 = round(100*(`post'-`pre'),0.0001)

			// poverty gap
			sum value if concat=="ymp_pc_fgt0_zref_ymp_."
			assert r(N)==1
			local pre = r(mean)
			sum value if concat=="ymp_inc_excise_taxes_fgt1_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_3 = round((`post'-`pre'),0.0001)

			clear 
			set obs 3
			gen mar =.
			forval n=1/3{
				replace mar = `effect_`n'' in `n'
			}
			* export to excel 
			global cell = "B16"
			*export excel using "$xls_out", sheet("fig_1", modify) first(variable) cell($cell ) keepcellfmt
			
			export excel using "$xls_out", sheet("fig_2", modify) first(variable) cell($cell ) keepcellfmt
	
	
/// ---___---____------___---____--- Marginal contributions  of Direct transfer ---___---__---___---___---__---___ ---___---__---___// 	

 *import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear 
		*import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear
		import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear
		import excel "$xls_sn", sheet(allRevenu_recycling_GMB) firstrow clear
		
		import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear

*Excises_Recycled Dir_trans_PMT_expand
// Marginal contributions

** effects on poverty - Poverty Prevalence
preserve
 // total
		sum value if concat=="ymp_pc_fgt0_zref_ymp_."
		assert r(N)==1
		local pre = r(mean)
		sum value if concat=="ymp_inc_dirtransf_total_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_1 = round(100*(`post'-`pre'),0.0001)
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_2 = round(100*(`post'-`pre'),0.0001)
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_3 = round(100*(`post'-`pre'),0.0001) 
 // Scholarships for students in higher education
		sum value if concat=="ymp_inc_am_bourse_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_4 = round(100*(`post'-`pre'),0.0001) 
 
 ** effect on inequality - GINI
 // total
		sum value if concat=="ymp_pc_gini__ymp_."
		assert r(N)==1
		local pre = r(mean)
		sum value if concat=="ymp_inc_dirtransf_total_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_5 = round(100*(`post'-`pre'),0.0001)

 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_6 = round(100*(`post'-`pre'),0.0001)  
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_7 = round(100*(`post'-`pre'),0.0001) 
 
 // Scholarships for students in higher education
        sum value if concat=="ymp_inc_am_bourse_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_8 = round(100*(`post'-`pre'),0.0001) 
		
		
 ** effect on Poverty Gap
 // total
		sum value if concat=="ymp_pc_fgt1_zref_ymp_."
		assert r(N)==1
		local pre = r(mean)
		sum value if concat=="ymp_inc_dirtransf_total_fgt1_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_9 = round(100*(`post'-`pre'),0.0001)
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_fgt1_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_10 = round(100*(`post'-`pre'),0.0001)
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_fgt1_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_11 = round(100*(`post'-`pre'),0.0001) 
 
   
 
 // Scholarships for students in higher education
		sum value if concat=="ymp_inc_am_bourse_fgt1_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_12 = round(100*(`post'-`pre'),0.0001) 
 
 
 // Create a matrix with the locals created	
		clear 
		set obs 12
		gen mar =.
		forval n=1/12{
			replace mar = `effect_`n'' in `n'
		}
		
	global cell = "N3"
export excel using "$xls_out", sheet("Marginal", modify) first(variable) cell($cell ) keepcellfmt
	
	* export to excel 
		global cell = "C26"
		export excel using "$xls_out", sheet("fig_2", modify) first(variable) cell($cell) keepcellfmt
		
restore
		
		
		
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

			// poverty gap
			 // total
			sum value if concat=="ymp_pc_fgt1_zref_ymp_."
			assert r(N)==1
			local pre = r(mean)
			sum value if concat=="ymp_inc_inktransf_total_fgt1_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_7 = round(100*(`post'-`pre'),0.0001)

			// education
			sum value if concat=="ymp_inc_education_inKind_fgt1_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_8 = round(100*(`post'-`pre'),0.0001)

			// Health
			sum value if concat=="ymp_inc_Sante_inKind_fgt1_zref_ymp_."
			assert r(N)==1
			local post = r(mean)
			local effect_9 = round(100*(`post'-`pre'),0.0001)

			clear 
			set obs 9
			gen mar =.
			forval n=1/9{
				replace mar = `effect_`n'' in `n'
			}
			* export to excel 
			global cell = "B42"
			export excel using "$xls_out", sheet("fig_2", modify) first(variable) cell($cell ) keepcellfmt



************************************************************************************************************************************************************************
************************************************************************************************************************************************************************

*****************************************************************************// Revenue by Scenari **********************************************************************


// VAT

* 2. Total revenue by quintil
	use "$data_out/AllSim.dta", clear

	* Names
	global variable "Tax_TVA_pc TVA_direct_pc TVA_indirect_pc"
	global quintil "1 2 3 4 5"

	replace variable = "a_" + variable if variable == "Tax_TVA_pc"
	replace variable = "b_" + variable if variable == "TVA_direct_pc"
	replace variable = "c_" + variable if variable == "TVA_indirect_pc"

	* Filters
	keep if inlist(variable, "a_Tax_TVA_pc", "b_TVA_direct_pc", "c_TVA_indirect_pc")
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
		
		sum value if sim == `i' & variable == "c_TVA_indirect_pc"		
		if (r(max) == 0) mat A`i' = A`i' \ R
	}	

	global count = substr("$count", 1, length("$count")-1)
	
	mat A = $count
	mat colnames A = $quintil 
	mat rownames A = $rownames

	matlist A

	* Print 
	putexcel set "${xls_out}", sheet("fig_3") modify
	putexcel B4 = ("Revenue") B5 = matrix(A), names

	shell ! "$xls_out"

	
// excises


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
	mat rownames A = $rownames

	matlist A

	* Print 
	putexcel set "${xls_out}", sheet("fig_3") modify
	putexcel B39 = ("Revenue") B40 = matrix(A), names

	shell ! "$xls_out"

	
	
	
// Direct Transfers

   use "$data_out/AllSim.dta", clear

	* Names
	global variable "dirtransf_total_pc"
	global quintil "1 2 3 4 5"

	replace variable = "a_" + variable if variable == "dirtransf_total_pc"

	* Filters
	keep if inlist(variable, "a_dirtransf_total_pc")
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
		
		sum value if sim == `i' & variable == "c_dirtransf_total_pc"		
		if (r(max) == 0) mat A`i' = A`i' \ R
	}	

	global count = substr("$count", 1, length("$count")-1)
	
	mat A = $count
	mat colnames A = $quintil 
	*mat rownames A = $rownames

	matlist A

	* Print 
	putexcel set "${xls_out}", sheet("fig_3") modify
	putexcel B49 = ("Revenue") B50 = matrix(A), names

	shell ! "$xls_out"
	
			
// Inkind transfers

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

	
	
	
	
// Electricity subsidies





/// ---------------------------------------------------------------// 
** Absolute and relative incidence of VAT by deciles 

			import excel "$xls_sn", sheet(allRef_2020_GMB) firstrow clear 

			preserve
			keep if measure=="benefits" 
			gen keep = 0
			foreach var in TVA_direct TVA_indirect TVA {
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

			foreach var in v_TVA_direct_pc_yd v_TVA_indirect_pc_yd{
				egen ab_`var' = sum(`var')
				gen in_`var' = `var'*100/ab_`var'
			}

			ren in_v_TVA_direct_pc_yd direct_absolute_inc 
			ren in_v_TVA_indirect_pc_yd indirect_absolute_inc
			*ren [in_v_TVA_direct_pc_yd in_v_TVA_indirect_pc_yd] [direct_absolute_inc indirect_absolute_inc]
			keep decile  direct_absolute_inc indirect_absolute_inc 

			global cell = "B4"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt

			restore

			*** relative 

			keep if measure=="netcash" 
			gen keep = 0
			foreach var in TVA_direct TVA_indirect TVA {
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

			global cell = "F4"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt	


/// ---------------------------------------------------------------// 
** Absolute and relative incidence of Excises by deciles 

import excel "$xls_sn", sheet(allRef_Exc_2020_GMB) firstrow clear 

			preserve
			keep if measure=="benefits" 
			gen keep = 0
			foreach var in excise_taxes {
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

			foreach var in v_excise_taxes_pc_yd {
				egen ab_`var' = sum(`var')
				gen in_`var' = `var'*100/ab_`var'
			}

			ren in_v_excise_taxes_pc_yd Absolute_inc 
			keep decile  Absolute_inc  

			global cell = "B21"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt
			restore


			*** relative 

			keep if measure=="netcash" 
			gen keep = 0
			foreach var in excise_taxes {
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
			ren v_excise_taxes_pc_yd Relative

			global cell = "F21"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt

			
// Direct Transfers 
import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear
// Absolute incidence

preserve
		keep if measure=="benefits" 
		gen keep = 0
		foreach var in am_Cantine am_BNSF am_bourse dirtransf_total {
			replace keep = 1 if variable == "`var'_pc"
		}	
		keep if keep ==1 

		replace variable=variable+"_ymp" if deciles_pc!=.
		replace variable=variable+"_yd" if deciles_pc==.
		*gen decile = yd_deciles_pc

		egen decile=rowtotal(yd_deciles_pc deciles_pc)

		keep decile variable value
		rename value v_

		reshape wide v_, i(decile) j(variable) string
		drop if decile ==0
		keep decile *_yd
		egen ab_v_dirtransf_total_pc_yd1 = sum(v_dirtransf_total_pc_yd)
		

		foreach var in v_am_Cantine_pc_yd v_am_BNSF_pc_yd v_am_bourse_pc_yd  v_dirtransf_total_pc_yd  {
			egen ab_`var' = sum(`var')
			*gen in_`var' = `var'*100/ab_`var'
			gen in_`var' = `var'*100/ab_v_dirtransf_total_pc_yd1
			*gen in_`var' = `var'*100/sum(v_dirtransf_total_pc_yd)
		}

		ren (in_v_am_Cantine_pc_yd in_v_am_BNSF_pc_yd in_v_am_bourse_pc_yd in_v_dirtransf_total_pc_yd) (Abs_Cantine Abs_BNSF Abs_Scholar Abs_total)
		*ren in_v_dirtransf_total_pc_yd Absolute_inc 
		keep Abs_*  decile

		global cell = "B40"
		export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell) keepcellfmt
restore

// Relative incidence
preserve 
			keep if measure=="netcash" 
			gen keep = 0
			foreach var in am_Cantine am_BNSF am_bourse dirtransf_total {
				replace keep = 1 if variable == "`var'_pc"
			}	
			keep if keep ==1 

			replace variable=variable+"_ymp" if deciles_pc!=.
			replace variable=variable+"_yd" if deciles_pc==.

			egen decile=rowtotal(yd_deciles_pc deciles_pc)


			keep decile variable value
			replace value = value*(100)
			rename value v_

			reshape wide v_, i(decile) j(variable) string
			drop if decile ==0
			keep *_yd
			ren (v_am_Cantine_pc_yd v_am_BNSF_pc_yd v_am_bourse_pc_yd v_dirtransf_total_pc_yd) (Rel_Cantine Rel_BNSF Rel_Scholar Rel_total)
			*ren v_dirtransf_total_pc_yd Relative

			global cell = "I40"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt

restore			
		 
		 
		 
/// ---------------------------------------------------------------// 
** Absolute and relative incidence of In-kind transfers by deciles 

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

			global cell = "B59"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt
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

			global cell = "F59"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt
			
			
			
			
			
			
			
			
// Comparing gains in relative incidence. 
  ** extract following absolute incidence 
     * 1. full VAT 
	 * 2. No exemptions on VAT
	 * 3. Excises
	 * 4. Sin tax 
	 * 5. Transfers (Nafa Quick)
	 * 6. Revenue recycling. 
	 
	 
	 
// VAT Full
import excel "$xls_sn", sheet(allRef_2020_GMB) firstrow clear 
*import excel "$xls_sn", sheet(allVAT_NoExempt_GMB_2020) firstrow clear 

			preserve
			keep if measure=="benefits" 
			gen keep = 0
			foreach var in TVA_direct TVA_indirect TVA {
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

			foreach var in v_TVA_direct_pc_yd v_TVA_indirect_pc_yd{
				egen ab_`var' = sum(`var')
				gen in_`var' = `var'*100/ab_`var'
			}

			ren in_v_TVA_direct_pc_yd direct_absolute_inc 
			ren in_v_TVA_indirect_pc_yd indirect_absolute_inc
			*ren [in_v_TVA_direct_pc_yd in_v_TVA_indirect_pc_yd] [direct_absolute_inc indirect_absolute_inc]
			keep decile  direct_absolute_inc indirect_absolute_inc 
			egen abs = rowtotal(direct_absolute_inc indirect_absolute_inc)
			replace abs = abs/2
			keep abs

			global cell = "B99"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt

			restore				
				
// Excises 				
import excel "$xls_sn", sheet(allRef_Exc_2020_GMB) firstrow clear 
import excel "$xls_sn", sheet(allSin_Exc_2020_GMB) firstrow clear 

			preserve
			keep if measure=="benefits" 
			gen keep = 0
			foreach var in excise_taxes {
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

			foreach var in v_excise_taxes_pc_yd {
				egen ab_`var' = sum(`var')
				gen in_`var' = `var'*100/ab_`var'
			}
			ren in_v_excise_taxes_pc_yd Abs 
			keep  Abs  

			global cell = "G99"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt
			restore				
				
 				
// Direct Transfers 
import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear
import excel "$xls_sn", sheet(allRevenu_recycling_GMB) firstrow clear

preserve
		keep if measure=="benefits" 
		gen keep = 0
		foreach var in am_Cantine am_BNSF am_bourse dirtransf_total {
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
		keep decile *_ymp
		*egen ab_v_dirtransf_total_pc_yd1 = sum(v_dirtransf_total_pc_yd)
		
/*
		foreach var in v_am_Cantine_pc_yd v_am_BNSF_pc_yd v_am_bourse_pc_yd  v_dirtransf_total_pc_yd  {
			egen ab_`var' = sum(`var')
			gen in_`var' = `var'*100/ab_`var'
		}

		ren (in_v_am_Cantine_pc_yd in_v_am_BNSF_pc_yd in_v_am_bourse_pc_yd in_v_dirtransf_total_pc_yd) (Abs_Cantine Abs_BNSF Abs_Scholar Abs)
		*/
		foreach var in v_am_BNSF_pc_ymp {
			egen ab_`var' = sum(`var')
			gen in_`var' = `var'*100/ab_`var'
		}

		ren (in_v_am_BNSF_pc_ymp) (Abs)
		
		
		*egen abs = rowtotal(Abs_Cantine Abs_BNSF Abs_Scholar)
		*replace Abs = abs/3
		keep Abs

		global cell = "K99"
		export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell) keepcellfmt
restore





// Relative 

// VAT 
import excel "$xls_sn", sheet(allRef_2020_GMB) firstrow clear 
import excel "$xls_sn", sheet(allVAT_NoExempt_GMB_2020) firstrow clear

keep if measure=="netcash" 
			gen keep = 0
			foreach var in TVA_direct TVA_indirect TVA {
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
			egen rel = rowtotal(v_TVA_direct_pc_yd v_TVA_indirect_pc_yd)
			replace rel = rel/2
			keep rel

			global cell = "C122"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt	

// Excises 

 
import excel "$xls_sn", sheet(allRef_Exc_2020_GMB) firstrow clear 
import excel "$xls_sn", sheet(allSin_Exc_2020_GMB) firstrow clear 

			keep if measure=="netcash" 
			gen keep = 0
			foreach var in excise_taxes {
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
			keep *_yd
			ren v_excise_taxes_pc_yd Rel

			global cell = "G122"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt

// Direct transfers

import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear
import excel "$xls_sn", sheet(allRevenu_recycling_GMB) firstrow clear

preserve 
			keep if measure=="netcash" 
			gen keep = 0
			foreach var in am_Cantine am_BNSF am_bourse dirtransf_total {
				replace keep = 1 if variable == "`var'_pc"
			}	
			keep if keep ==1 

			replace variable=variable+"_ymp" if deciles_pc!=.
			replace variable=variable+"_yd" if deciles_pc==.

			egen decile=rowtotal(yd_deciles_pc deciles_pc)


			keep decile variable value
			replace value = value*(100)
			rename value v_

			reshape wide v_, i(decile) j(variable) string
			drop if decile ==0
			keep *_yd
			ren (v_am_Cantine_pc_yd v_am_BNSF_pc_yd v_am_bourse_pc_yd v_dirtransf_total_pc_yd) (Rel_Cantine Rel_BNSF Rel_Scholar Rel)
			*ren v_dirtransf_total_pc_yd Relative
			keep Rel

			global cell = "K122"
			export excel using "$xls_out", sheet("fig_4", modify) first(variable) cell($cell ) keepcellfmt

restore			

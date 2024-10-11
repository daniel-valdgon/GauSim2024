


/*
Slides for Transfers 
To do: Create presentation
Authors: Madi Mangan 
Start Date: 03 May 2024
Update Date: 28 June 2024

*/

        // output files 
		global xls_out    	"${path}/03_Tool/trans_slides_${country}.xlsx"


        *import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear 
		import excel "$xls_sn", sheet(allDir_trans_PMT_expand) firstrow clear 


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
		
	* export to excel 
		global cell = "A2"
		export excel using "$xls_out", sheet("fig_1", modify) first(variable) cell($cell) keepcellfmt
		
		*global cell = "B2"
		export excel using "$xls_out", sheet("fig_6", modify) first(variable) cell($cell) keepcellfmt
restore




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

		global cell = "A2"
		export excel using "$xls_out", sheet("fig_2", modify) first(variable) cell($cell) keepcellfmt
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

			global cell = "A2"
			export excel using "$xls_out", sheet("fig_3", modify) first(variable) cell($cell ) keepcellfmt

restore


// Total expenses

global sheetname "Ref_2020_Baseline Dir_trans_PMT_expand Dir_trans_RND_expand Dir_trans_PMT_10 Dir_trans_RND_10 Revenu_recycling_GMB"
	global nsim 6		
		
		
		
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
	putexcel set "${xls_out}", sheet("fig_4") modify
	putexcel A2 = ("Revenue") A3 = matrix(A), names

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
	putexcel A2 = ("Principal indicators - Simulations") A3 = matrix(A), names
			
		
	**** --------------------------------------- END --------------------- ---- ***	
		

// Simulation 


// Descriptives for the Appendix

use  "$presim/07_dir_trans_PMT.dta", clear
merge 1:m hhid  using  "$presim/07_educ.dta", nogen

collapse (sum) ben_pre_school ben_primary ben_tertiary [iw=hhweight], by(ndfdecil) cw
egen ben_school_cantines = rowtotal(ben_pre_school ben_primary)

	foreach var in ben_school_cantines ben_tertiary {
		egen ab_`var' = sum(`var')
		replace `var' = `var'/ab_`var'
	}
	cap ren ndfdecil decile
	keep ben_school_cantines ben_tertiary decile
	global cell = "A2"
	export excel using "$xls_out", sheet("dis_1", modify) first(variable) cell($cell ) keepcellfmt
	
	
	
// Rondom Assignment
	
import excel "$xls_sn", sheet(allDir_trans_RND_expand) firstrow clear 


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
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_2 = round(100*(`post'-`pre'),0.0001) 
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_fgt0_zref_ymp_."
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
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_6 = round(100*(`post'-`pre'),0.0001) 
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_7 = round(100*(`post'-`pre'),0.0001)  

 // Scholarships for students in higher education
        sum value if concat=="ymp_inc_am_bourse_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_8 = round(100*(`post'-`pre'),0.0001) 
 
 // Create a matrix with the locals created	
		clear 
		set obs 8
		gen mar =.
		forval n=1/8{
			replace mar = `effect_`n'' in `n'
		}
		
	* export to excel 
		global cell = "B2"
		export excel using "$xls_out", sheet("fig_6", modify) first(variable) cell($cell) keepcellfmt
restore


	// PMT 10% of household
	import excel "$xls_sn", sheet(allDir_trans_PMT_10) firstrow clear 


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
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_2 = round(100*(`post'-`pre'),0.0001) 
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_fgt0_zref_ymp_."
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
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_6 = round(100*(`post'-`pre'),0.0001) 
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_7 = round(100*(`post'-`pre'),0.0001)  

 // Scholarships for students in higher education
        sum value if concat=="ymp_inc_am_bourse_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_8 = round(100*(`post'-`pre'),0.0001) 
 
 // Create a matrix with the locals created	
		clear 
		set obs 8
		gen mar =.
		forval n=1/8{
			replace mar = `effect_`n'' in `n'
		}
		
	* export to excel 
		global cell = "C2"
		export excel using "$xls_out", sheet("fig_6", modify) first(variable) cell($cell) keepcellfmt
restore


// Random Assignment 10% of household 
import excel "$xls_sn", sheet(allDir_trans_RND_10) firstrow clear 


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
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_2 = round(100*(`post'-`pre'),0.0001) 
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_fgt0_zref_ymp_."
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
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_6 = round(100*(`post'-`pre'),0.0001) 
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_7 = round(100*(`post'-`pre'),0.0001)  

 // Scholarships for students in higher education
        sum value if concat=="ymp_inc_am_bourse_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_8 = round(100*(`post'-`pre'),0.0001) 
 
 // Create a matrix with the locals created	
		clear 
		set obs 8
		gen mar =.
		forval n=1/8{
			replace mar = `effect_`n'' in `n'
		}
		
	* export to excel 
		global cell = "D2"
		export excel using "$xls_out", sheet("fig_6", modify) first(variable) cell($cell) keepcellfmt
restore



	
	
	
	
	
	
	
/*-------------------------------------------------------/
	6. Poverty results
/-------------------------------------------------------*/

	global variable 	"yd" // Only one
	global reference 	"zref" // Only one

	*-----  Marginal contributions
forvalues scenario = 1/$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	mat pov = J(1,`len', r(mean))'
	 
	sum value if measure == "gini" & variable == "${variable}_pc"
	mat gini = J(1,`len', r(mean))'
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	foreach var in $policy {
		replace keep = 1 if variable == "${variable}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${variable}" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${variable}_inc_`v'"
	}
	
	tab o_variable measure [iw = value] if reference == "$reference", matcell(A1)
	tab o_variable measure [iw = value] if reference == "", matcell(A2)

*-----  Kakwani	
	import excel "$xls_sn", sheet("conc${variable}_${proj_`scenario'}") firstrow clear 
	
	keep ${variable}_centile_pc ${variable}_pc $policy
	keep if ${variable}_centile_pc == 999
	
	ren * var_*
	ren var_${variable}_centile_pc ${variable}_centile_pc
	ren var_${variable}_pc ${variable}_pc
	
	reshape long var_, i(${variable}_centile_pc) j(variable, string)
	ren var_ value
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "`v'_pc"
	}

	tab o_variable [iw = ${variable}_pc], matcell(B1)
	tab o_variable [iw = value], matcell(B2)
	
	* Matrix
	mat A = pov, A1, gini, A2, B1, B2
	
	mat colnames A = gl_pov poverty gl_gini gini ${variable}_pc conc${variable}
	mat rownames A = $policy
		
	keep o_variable
	gsort o_variable

	svmat double A,  names(col)

	gen scenario = `scenario'
	order scenario, first
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
	*save "$tempsim/${pov_`scenario'}", replace

}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
	*append using "$tempsim/${pov_`scenario'}"
	
}

export excel "$xls_out", sheet(fig_8) first(variable) sheetmodify 




/*-------------------------------------------------------/
	6. Poverty difference on simulations
/-------------------------------------------------------*/

	global variable 	"yc" // Only one
	global reference 	"zref" // Only one

	*-----  Marginal contributions
forvalues scenario = 1/$numscenarios {
	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	mat pov = J(1,`len', r(mean))' 
	
	sum value if measure == "gini" & variable == "${variable}_pc"
	mat gini = J(1,`len', r(mean))'
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	foreach var in $policy {
		replace keep = 1 if variable == "${variable}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${variable}" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${variable}_inc_`v'"
	}
	
	tab o_variable measure [iw = value] if reference == "$reference", matcell(A1)
	tab o_variable measure [iw = value] if reference == "", matcell(A2)

*-----  Kakwani	

	import excel "$xls_sn", sheet("conc${variable}_${proj_`scenario'}") firstrow clear 
	
	keep ${variable}_centile_pc ${variable}_pc $policy
	keep if ${variable}_centile_pc == 999
	
	ren * var_*
	ren var_${variable}_centile_pc ${variable}_centile_pc
	ren var_${variable}_pc ${variable}_pc
	
	reshape long var_, i(${variable}_centile_pc) j(variable, string)
	ren var_ value
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "`v'_pc"
	}

	tab o_variable [iw = ${variable}_pc], matcell(B1)
	tab o_variable [iw = value], matcell(B2)
	
	mat J = J(1,1, .)
	
	* temporal fix for VAT Ind Effects
	local dim `= rowsof(B2)'	
	if ("`dim'" == "2") {
		mat B2 = B2 \ J
	}
	
	* Matrix
	mat A = pov, A1, gini, A2, B1, B2
	
	mat colnames A = gl_pov poverty gl_gini gini ${variable}_pc conc${variable}
	mat rownames A = $policy
	
	keep o_variable
	gsort o_variable

	svmat double A,  names(col)
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(fig_7) first(variable) sheetreplace 



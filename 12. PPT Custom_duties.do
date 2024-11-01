
/*

	 Authors	 : 	Madi Mangan 
	 Start Date	 : 	October 2024
	 Update Date : 	30th October, 2024
	 
	 To Do: 	 :	Extract figures for slides of Custom Duties	

*/

	global xls_out		"${path}/03_Tool/_post_sim/Figure12_Custom_duties.xlsx"

	global numscenarios	2
	global coutryscen	"GMB"	// Fill with the country of each simulation 
	global proj_1		"Ref_2020_cust_NF" 
	global proj_2		"Ref_2020_custom"
	

	global policy		"Custom"
	scalar t1 = c(current_time)


/*-------------------------------------------------------/
	1. Names
/-------------------------------------------------------*/

*----- Scenarios
		forvalues scenario = 1/$numscenarios {
			
			clear
			set obs 1
			
			gen scenario = `scenario'
			gen name = "${proj_`scenario'}"
			
			tempfile name_`scenario'
			save `name_`scenario'', replace
		}

		clear
		forvalues scenario = 1/$numscenarios {
			append using `name_`scenario''
		}

export excel "$xls_out", sheet(Scenarios) first(variable) sheetreplace cell(A1)


/*-------------------------------------------------------/
	2 Relative Incidence
/-------------------------------------------------------*/

			global income 	"ymp" // yd, ymp

		forvalues scenario = 1/$numscenarios {

			import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

			keep if measure=="netcash" 
			gen keep = 0

			global policy2 	""
			foreach var in $policy {
				replace keep = 1 if variable == "`var'_pc"
				global policy2	"$policy2 v_`var'_pc_${income}" 
			}	
			keep if keep ==1 

			replace variable=variable+"_ymp" if deciles_pc!=.
			replace variable=variable+"_yd" if deciles_pc==.

			egen decile=rowtotal(yd_deciles_pc deciles_pc)

			keep decile variable value
			*gen val2 = . 
			*replace val2 = value * (-100) if value < 0
			*replace val2 = value*(100) if value >= 0
			rename value v_

			reshape wide v_, i(decile) j(variable) string
			drop if decile ==0
			
			keep decile *_${income}
			gen scenario = `scenario'
			order scenario decile $policy2
			ren (*) (scenario decile $policy)
			
			tempfile inc_`scenario'
			save `inc_`scenario'', replace

		}


		clear
		forvalues scenario = 1/$numscenarios {
			append using `inc_`scenario''
		}

export excel "$xls_out", sheet(Incidence) first(variable) sheetmodify cell(A1)

/*-------------------------------------------------------/
	3. Absolute Incidence
/-------------------------------------------------------*/

	global income 	"ymp" // yd, ymp

forvalues scenario = 1/$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="benefits" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_${income}

	foreach var in $policy2 {
		egen ab_`var' = sum(`var')
		gen in_`var' = `var'*100/ab_`var'
	}

	keep decile in_*
	gen scenario = `scenario'
	order scenario, first
	ren (*) (scenario decile $policy)

	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace
	
}


clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Incidence) first(variable) sheetmodify cell(S1)
	
	
/*-------------------------------------------------------/
	4. Marginal Contributions
/-------------------------------------------------------*/

	global variable 	"ymp" // Only one
	global reference 	"zref" // Only one

forvalues scenario = 1/$numscenarios {
	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	global pov0 = r(mean)
	 
	sum value if measure == "fgt1" & variable == "${variable}_pc" & reference == "$reference"
	global pov1 = r(mean) 
	 
	sum value if measure == "gini" & variable == "${variable}_pc"
	global gini1 = r(mean)
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	foreach var in $policy {
		replace keep = 1 if variable == "${variable}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${variable}" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "fgt1", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${variable}_inc_`v'"
	}
	
	ren value val_
	keep o_variable measure val_
	gsort o_variable
	
	reshape wide val_, i(o_variable) j(measure, string)
	
	gen gl_fgt0 = $pov0
	gen gl_fgt1 = $pov1
	gen gl_gini = $gini1
	
	tempfile mc
	save `mc', replace

*-----  Kakwani	
	import excel "$xls_sn", sheet("conc${variable}_${proj_`scenario'}") firstrow clear 
	
	keep ${variable}_centile_pc ${variable}_pc $policy
	keep if ${variable}_centile_pc == 999
	
	ren * var_*
	ren var_${variable}_centile_pc income_centile_pc
	ren var_${variable}_pc income_pc
	
	reshape long var_, i(income_centile_pc) j(variable, string)
	ren var_ value_
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "`v'_pc"
	}

	keep o_variable income_pc value_
	ren value value_k

	merge 1:1 o_variable using `mc', nogen
	
	gen scenario = `scenario'
	
	ren * cat_*
	ren (cat_scenario cat_o_variable) (scenario variable)
	
	reshape long cat_ , i(scenario variable) j(cat, string)
	
	gen var = substr(variable, 3, length(variable))
	drop variable
	
	reshape wide cat_ , i(scenario cat) j(var, string)

	ren * (scenario indic $policy)
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Marginal) first(variable) sheetreplace 


/*-------------------------------------------------------/
	5. Poverty and Inequality - Compare Scenarios
/-------------------------------------------------------*/

	global variable 	"yc" // Only one
	global reference 	"zref" // Only one
	
forvalues scenario = 1/$numscenarios {
	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	global pov0 = r(mean)

	sum value if measure == "fgt1" & variable == "${variable}_pc" & reference == "$reference"
	global pov1 = r(mean)
	
	sum value if measure == "gini" & variable == "${variable}_pc"
	global gini1 = r(mean)
	
	
	clear
	set obs 1 
	
	gen gl_fgt0 = $pov0
	gen gl_fgt1 = $pov1
	gen gl_gini = $gini1
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
	
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Poverty) first(variable) sheetmodify 

/*-------------------------------------------------------/
	6. Coverage
/-------------------------------------------------------*/

	global variable 	"ymp" // yd... Only one
	
forvalues scenario = 1/$numscenarios {
	
	local scenario = 1
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	keep if measure=="coverage" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 
	
	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	
	keep decile *_${income}
	gen scenario = `scenario'
	order scenario decile $policy2
	ren (*) (scenario decile $policy)
	
	tempfile cov_`scenario'
	save `cov_`scenario'', replace
	
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `cov_`scenario''
}

export excel "$xls_out", sheet(Coverage) first(variable) sheetmodify 



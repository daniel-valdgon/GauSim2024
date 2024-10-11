
/*
	 GAMSIM_2024 - Pre-simulation do-file 
	 Authors	 : 	Madi Mangan 
	 Start Date	 : 	September 2024
	 Update Date : 	Sept 05, 2024
	 To do	     : 	Compute labour income  from PIT data
					
*/

* Define the program to back out income from PIT
cap program drop backout_income
program define backout_income
    version 16.0
    
    * 1. Define tax brackets and rates as matrices based on the table from your document
    matrix define tax_brackets = (0, 24000 \ 24001, 34000 \ 34001, 44000 \ 44001, 54000 \ 54001, 64000 \ 64001, .)
    matrix define tax_rates = (0.0 \ 0.05 \ 0.10 \ 0.15 \ 0.20 \ 0.25)

    * 2. Create a new variable to hold income calculation
    gen income = .
    
    * 3. Loop through each taxpayer in the dataset
    forvalues i = 1 / `=_N' {
        local tax_paid = PIT[`i']

        * Loop through the brackets to find the correct one
        forvalues j = 1 / 6 {
            local lower_bracket = tax_brackets[`j', 1]
            local upper_bracket = tax_brackets[`j', 2]
            local tax_rate = tax_rates[`j', 1]
            
            * Check if the tax paid falls within the tax bracket range
            if tax_paid > lower_bracket & (tax_paid <= upper_bracket | upper_bracket == .) {
                * Back out income for this taxpayer
                local income = tax_paid / `tax_rate'
                replace income = `income' in `i'
                continue, break
            }
        }
    }
end

* Load your dataset 
		import excel "$data_sn/tax_data.xlsx", sheet("PIT") firstrow clear
		ren y_2020 PIT
		drop if PIT ==. 
*** run the program
backout_income

* Review the calculated income values
list PIT income

** PROYECT: Mauritania CEQ
** TO DO: Data cleansing of purchases, presim
** EDITED BY: Gabriel Lombo and Daniel Valderrama
** LAST MODIFICATION: 18 January 2024


*ssc install gtools
*ssc install ereplace
*net install gr0034.pkg


*** Variables Standardization
** Names

/* Just once
* Excel file
global xls_var 			"${tool}/policy_inputs/${country}/_other/Dictionary_${country}.xlsx" 

* Test 1 - RawData
global data 		"${data_sn}" // Data path
global all_data 	"pivot2019 EPCV2019_income menage_pauvrete_2019 informality_Bachas_mean" // Data names
global sheet 		"rawData" // Sheet name
global n 			4 // Data number

* First step
*global stage 		"stage1" 
*var_standardization

* Hand: rename variables

* Second step - allocating
global stage 		"stage2" 
var_standardization


capture macro drop xls_var data all_data sheet n stage
*/

** Scope
* Bachas Informality - Recode coicop
use "$data_sn/s_informality_Bachas_mean.dta", clear

gen coicop = .
replace coicop = 1 if product_name == "Food and non-alcoholic beverages"
replace coicop = 2 if product_name == "Alcoholic beverages, tobacco and narcotics"
replace coicop = 3 if product_name == "Clothing and footwear"
replace coicop = 4 if product_name == "Housing, water, electricity, gas and other fuels"
replace coicop = 5 if product_name == "Furnishings, household equipment and routine household maintenance"
replace coicop = 6 if product_name == "Health"
replace coicop = 7 if product_name == "Transport"
replace coicop = 8 if product_name == "Communication"
replace coicop = 9 if product_name == "Recreation and culture"
replace coicop = 10 if product_name == "Education"
replace coicop = 11 if product_name == "Restaurants and hotels"
replace coicop = 12 if product_name == "Miscellaneous goods and services"

labmask coicop, values(product_name)

tempfile Bachas_mean
save `Bachas_mean', replace


*** Final presim Data
* Household Data
use "$data_sn/s_EPCV2019_income.dta" , clear

collapse (sum) dtot = pcc, by(hhid hhweight hhsize)

merge 1:1 hhid using "$data_sn/s_menage_pauvrete_2019.dta", keep(matched) nogen

gen pcc = dtot/hhsize

* By Household @gabriel use quantiles or _ebin using stable option 
*xtile decile_expenditure = pcc [aw=hhweight*hhsize], n(10) // Use consumption

gen pondih = hhweight*hhsize
_ebin pcc [aw=pondih], nq(10) gen(decile_expenditure)

drop pondih



* To check and agree
*gen all = 1
*tab all [iw=hhweight*hhsize]
*replace hhweight = round(hhweight)
*tab all [fw=hhweight*hhsize] // as in simdo 08, rounding changes on 500 people


/**** Create poverty lines

* MRT: i2017 - 1.05, i2018 - 0.65, i2019 - 0.98. ccpi_a
* MRT: i2017 - 3.0799999,	i2018 - 4.2035796. fcpi_a
* MRT: i2017 - 2.269, i2018 - 3.07. hcpi_a
* MRT Inflation according to WorldBank Data Dashboard. 2017 - 2.3, 2018 - 3.1
* Country specific...

local ppp17 = 12.4452560424805
local inf17 = 2.3
local inf18 = 3.1
local inf19 = 2.3
cap drop line_1 line_2 line_3
gen line_1=2.15*365*`ppp17'*`inf17'*`inf18'*`inf19'
gen line_2=3.65*365*`ppp17'*`inf17'*`inf18'*`inf19'
gen line_3=6.85*365*`ppp17'*`inf17'*`inf18'*`inf19'

foreach var in /*line_1 line_2 line_3*/ yd_pc yc_pc  {
	gen test=1 if `var'<=zref
	recode test .= 0
	noi tab test [iw=hhweight*hhsize]
	drop test
}
*/

save "$presim/01_menages.dta", replace



* Purchases Data
use "$data_sn/s_pivot2019.dta" , clear

drop hhweight hhsize

* Merge data 
merge m:1 hhid using "$presim/01_menages.dta", nogen keepusing(decile_expenditure hhweight hhsize) keep(3) //Get decile
merge m:1 decile_expenditure coicop using `Bachas_mean', nogen keepusing(informal_purchase) keep(1 3) // Get informality

* Exclude auto-consumption, donation and transfers
tab source
drop if inlist(source, 1, 3)

gunique hhid codpr

* HH and product level
collapse (sum) depan [aw=hhweight], by(hhid hhsize codpr coicop informal_purchase decile_expenditure)

* We need to compute the purchases before taxes!!!!!!!!!!!!!
*gen depan_for = depan* (1-informal_purchase)/(1+TVA)
*gen depan_inf = depan* informal_purchase

*egen depan2=rowtotal(depan_for depan_inf)  // actually the computation is even more complex because shuold include also the indirect effects  


save "$presim/05_purchases_hhid_codpr.dta", replace










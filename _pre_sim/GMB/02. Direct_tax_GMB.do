
/*=============================================================================

	Project:		Direct Taxes - Presim
	Author:			Madi Mangan
	Creation Date:	07 August 2024
	Modified:		07 August 2024
	
	Note: This do-file creates the pre-simulation dataset for direct taxes
	
==============================================================================*/

use "$presim/02_income_tax_GMB_final.dta", clear
merge m:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize ndecil)
gen uno = 1
	
* Working-age population
	*gen female = (sex==2)
	gen wa_pop = inrange(age,15,64)
	gen nwa_pop = inrange(age,0,14)
	gen n2wa_pop = inrange(age,65,96)
	
** Tax income
* Principal activity
	gen employee_1 = .
	replace employee_1 = 1 if inrange(s4q2, 1, 4) | (s4q3 ==1)
	replace employee_1 = 0 if inrange(s4q2, 5, 7) 

	*gen tax_ind_1 = employee_1 == 1 & s4q13==1 & s4q16==1  // employed, have a contract and entitleed to social security contribution. 
	gen tax_ind_1 = pay_pit == 1  // employed, have a contract and entitleed to social security contribution. 
	replace tax_ind_1 = 0 if tax_ind_1 ==0


	
	// Descriptives about Workes. 
	ta employee_1 [fw=int(hhweight)] if age >=15
	ta s4q16 [fw=int(hhweight)] 							// pays social security contribution
	ta s4q13 [fw=int(hhweight)] 							// Have an emploment contract
	ta pay_pit [fw=int(hhweight)]

** Defining the tax base	
	
	*gen tax_base_1 = E20A2*E15 if tax_ind_1 == 1
	replace hl_income = li
	gen tax_base_1 = hl_income if tax_ind_1 == 1


*PIT parameters (over yearly gross income)
		global PIT_thres_1=0
		global PIT_thres_2=24000
		global PIT_thres_3=34000
		global PIT_thres_4=44000
		global PIT_thres_5=54000
		global PIT_thres_6=64000
		global PIT_rate_1=0		
		global PIT_rate_2=0.05	
		global PIT_rate_3=0.10	
		global PIT_rate_4=0.15	
		global PIT_rate_5=0.20	
		global PIT_rate_6=0.25		

/*		
		forvalues v in $PIT_rate_1 $PIT_rate_2 $PIT_rate_3 $PIT_rate_4 $PIT_rate_5 $PIT_rate_6 {
			replace `v' = `v' + 0.05
		}
*/
gen tranche = 0
		replace tranche = 1 if inrange(tax_base, 24001, 34000) 
		replace tranche = 2 if inrange(tax_base, 34001, 44000) 
		replace tranche = 3 if inrange(tax_base, 44001, 54000) 
		replace tranche = 4 if inrange(tax_base, 54001, 64000)
		replace tranche = 5 if inrange(tax_base, 64001, .)		
		
*Convert Earnings from Net to Gross
dirtax tax_base_1, netinput rates(0 5 10 15 20 25) tholds(0 24000 34000 44000 54000 64000) gen(tot_gross_earn_yr)
sum  tot_gross_earn_yr [fw=int(hhweight)] if tax_base_1!=.

*Distribution of Taxpayers, by Income Bracket
gen PIT_schedule_ind=.
	replace PIT_schedule=0 if tot_gross_earn_yr>=$PIT_thres_1 & tot_gross_earn_yr<=$PIT_thres_2
	replace PIT_schedule=0.05 if tot_gross_earn_yr>$PIT_thres_2 & tot_gross_earn_yr<=$PIT_thres_3
	replace PIT_schedule=0.10 if tot_gross_earn_yr>$PIT_thres_3 & tot_gross_earn_yr<=$PIT_thres_4
	replace PIT_schedule=0.15 if tot_gross_earn_yr>$PIT_thres_4 & tot_gross_earn_yr<=$PIT_thres_5
	replace PIT_schedule=0.20 if tot_gross_earn_yr>$PIT_thres_5 & tot_gross_earn_yr<=$PIT_thres_6
	replace PIT_schedule=0.30 if tot_gross_earn_yr>$PIT_thres_6
	
ta PIT_schedule_ind [fw=int(hhweight)] if tax_base_1!=. //
disp 66519 - 9406    // 57,113  individuals with positive PIT liability


**Calculate PIT Liabilities
gen PIT_yr=0
			replace PIT_yr=0 if tot_gross_earn_yr>$PIT_thres_1 & tot_gross_earn_yr<=$PIT_thres_2
			replace PIT_yr=$PIT_rate_1*($PIT_thres_2-$PIT_thres_1)+ $PIT_rate_2*($PIT_thres_3-$PIT_thres_2) if tot_gross_earn_yr>$PIT_thres_2 & tot_gross_earn_yr<=$PIT_thres_3
			replace PIT_yr=$PIT_rate_1*($PIT_thres_2-$PIT_thres_1)+ $PIT_rate_2*($PIT_thres_3-$PIT_thres_2)+$PIT_rate_3*($PIT_thres_4-$PIT_thres_3) if tot_gross_earn_yr>$PIT_thres_3 & tot_gross_earn_yr<=$PIT_thres_4
			replace PIT_yr=$PIT_rate_1*($PIT_thres_2-$PIT_thres_1)+ $PIT_rate_2*($PIT_thres_3-$PIT_thres_2)+$PIT_rate_3*($PIT_thres_4-$PIT_thres_3) +$PIT_rate_4*($PIT_thres_5-$PIT_thres_4) if tot_gross_earn_yr>$PIT_thres_4 & tot_gross_earn_yr<=$PIT_thres_5
			replace PIT_yr=$PIT_rate_1*($PIT_thres_2-$PIT_thres_1)+ $PIT_rate_2*($PIT_thres_3-$PIT_thres_2)+$PIT_rate_3*($PIT_thres_4-$PIT_thres_3) +$PIT_rate_4*($PIT_thres_5-$PIT_thres_4) +$PIT_rate_5*($PIT_thres_6-$PIT_thres_5) if tot_gross_earn_yr>$PIT_thres_5 & tot_gross_earn_yr<=$PIT_thres_6
			replace PIT_yr=$PIT_rate_1*($PIT_thres_2-$PIT_thres_1)+ $PIT_rate_2*($PIT_thres_3-$PIT_thres_2)+$PIT_rate_3*($PIT_thres_4-$PIT_thres_3) +$PIT_rate_4*($PIT_thres_5-$PIT_thres_4) +$PIT_rate_5*($PIT_thres_6-$PIT_thres_5) + $PIT_rate_6*($PIT_thres_6-$PIT_thres_5) if tot_gross_earn_yr>$PIT_thres_6
label var PIT_yr "Individual PIT (simulated), yearly"


ren (PIT_yr) (income_tax)
replace income_tax = 0 if tax_ind_1==0
*** ---------------------------------------/// ------------------------- *** ***
*** ---------------------------------------/// ------------------------- *** ***
*** ---------------------------------------/// ------------------------- *** ***

** Enterprise tax 

		foreach var in allowance tax_ind2 tax_ind3 regime income_tax2 income_tax3 tax_base2 tax_base3 {
			cap gen `var' = 0
		}
		keep hhid tax_ind* tax_base* income_tax* allowance tranche regime hhweight hhsize ndecil PIT_schedule_ind

save "$presim/02_Income_tax_input.dta", replace

qwe


/*


* Tax
	local tax0 = 0.00
	local tax1 = 0.05
	local tax2 = 0.10
	local tax3 = 0.15
	local tax4 = 0.20
	local tax5 = 0.25

	gen tranche = 0
	replace tranche = 1 if inrange(tax_base, 24001, 34000) 
	replace tranche = 2 if inrange(tax_base, 34001, 44000) 
	replace tranche = 3 if inrange(tax_base, 44001, 54000) 
	replace tranche = 4 if inrange(tax_base, 54001, 64000)
	replace tranche = 5 if inrange(tax_base, 64001, .)

	gen income_tax = 0
	replace income_tax = tax_base * `tax0' if tranche == 0
	replace income_tax = tax_base * `tax1' - 24000  if tranche == 1
	replace income_tax = tax_base * `tax2' - 34000 if tranche == 2
	replace income_tax = tax_base * `tax3' - 44000 if tranche == 3
	replace income_tax = tax_base * `tax4' - 54000 if tranche == 4
	replace income_tax = tax_base * `tax5' - 64000 if tranche == 5

	replace income_tax = 0 if income_tax < 0	

**---------- Tax entreprises
* Principal activity
	gen emp2 = inrange(E10, 7, 8) & E13C == 1
	gen tax_ind2 = emp2 == 1 & E20A2>0 & E20A2!=. & E20A1 == 1
	gen tax_base2 = E20A2*E15 if tax_ind2 == 1

	


	gen regime = 0
	replace regime = 1 if E11 == 10 & tax_ind2 == 1
	replace regime = 2 if inrange(E11, 5, 9) & tax_ind2 == 1

* Tax
	local tax1 = 0.03
	local tax2 = 0.3

	gen income_tax2 = 0
	replace income_tax2 = tax_base2 * `tax1' if regime == 1
	replace income_tax2 = tax_base2 * `tax2' if regime == 2

	tabstat tax_ind2 tax_base2 income_tax2 [aw = hhweight], s(sum) by(regime)


**---------- Tax property
	gen tax_ind3 = F1 == 1 & G0 == 1

	gen tax_base3 = 12751.6 if tax_ind2 == 1

	local tax1 = 0.1

	gen income_tax3 = 0
	replace income_tax3 = tax_base3 * `tax1' if tax_ind2 == 1


	tabstat tax_ind3 tax_base3 income_tax3 [aw = hhweight], s(sum) by(regime)
*/



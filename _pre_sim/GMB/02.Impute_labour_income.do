

/*
	 GAMSIM_2024 - Pre-simulation do-file 
	 Authors	 : 	Madi Mangan 
	 Start Date	 : 	August 2024
	 Update Date : 	August 29, 2024
	 To do	     : 	Compute household labour income 
					impute labour income using both household labour income and imputation using LFS 2018
*/



// Household Labour income from IHS 2020. 
use "$data_sn/Stata/PART B Section 4A-Household income.dta", clear 

		keep if inlist(s4aq1, 9, 10,11)
		keep s4aq2 s4aq1 quarter area district lga hid
		
		gen hhincome = . 
			forvalues v = 9(1)11 {
				replace hhincome = s4aq2 if s4aq1 == `v'
			}
		lab var hhincome "Household labour income"
		replace hhincome = hhincome*12
		  
		collapse (sum) hhincome, by(hid area district lga)
		ren (hid lga) (hhid region)

// add consumption data 
	merge 1:1 hhid using "$presim/01_menages2.dta", nogen keepusing(hhweight zref pcc) keep(match)		
		
	tempfile income
	save `income', replace  

	
/* -------------------------------------------------------------------------- */
/*      B. Income from Non Labor Sources                                      */
/* -------------------------------------------------------------------------- */

/* ---- 1. Remittances received --------------------------------------------- */	
	
use "$data_sn/Stata/PART B Section 4A-Household income.dta", clear 	
	
	
// Create house individual characteristics which are both common and necessary to define their labour income. 
use "$data_sn/Stata/PART A Section 1_2_3_4_6-Individual level.dta", clear
	  
*Age of interest ()
	tab s1q5_years
	drop if s1q5_years<15
	ren s1q5_years age

gen area_res=.
	    replace area_res=1 if area==1				// Urban 
		replace area_res=2 if area==2				// Rural
		        lab def area_res_lab 1 "1 - Urban" 2 "2 - Rural"
		        lab val area_res area_res_lab
		        lab var area_res "Residence area"			
				
gen sex=.
	    replace sex=1 if s1q3==1				// Male
		replace sex=2 if s1q3==2				// Female
		        label define label_Sex 1 "1 - Male" 2 "2 - Female"
		        label values sex label_Sex
		        lab var sex "Sex"				
		
*---------------------------------------------------------------------------
* 					ISCED 11                                               *
*---------------------------------------------------------------------------
				
    * Detailed				
    gen ilo_edu_isced11=.
		replace ilo_edu_isced11=1 if s3aq2==2			// No schooling
		replace ilo_edu_isced11=2 if s3aq6==0			// Early childhood education
		replace ilo_edu_isced11=3 if s3aq6==1	  		// Primary education
		replace ilo_edu_isced11=4 if s3aq6==2			// Lower secondary education
		replace ilo_edu_isced11=5 if s3aq6==3		    // Upper secondary education
		replace ilo_edu_isced11=6 if s3aq6==4			// Vocational certificate 
		replace ilo_edu_isced11=7 if s3aq6==5			// Dimploma
		replace ilo_edu_isced11=8 if s3aq6==6			// Higher 
		
			    label def isced_11_lab 1 "X - No schooling" 2 "0 - Early childhood education" 3 "1 - Primary education" 4 "2 - Lower secondary education" ///
				                       5 "3 - Upper secondary education" 6 "4 - Vocational certificate " 7 "5 - Dimploma" 8 "6 - Higher" 
			    label val ilo_edu_isced11 isced_11_lab
			    lab var ilo_edu_isced11 "Educational attainment (ISCED 11)"
				
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*			           Marital status ('ilo_mrts') 	                           *
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------

	* Detailed
	gen ilo_mrts_details=.
	    replace ilo_mrts_details=1 if s1q10==1					// Single
		replace ilo_mrts_details=2 if s1q10==2					// Married
		replace ilo_mrts_details=3 if s1q10==3					// Union / cohabiting
		replace ilo_mrts_details=4 if s1q10 ==6						// Widowed
		replace ilo_mrts_details=5 if s1q10==4					// Divorced / separated
		
		        label define label_mrts_details 1 "1 - Single" 2 "2 - Married" 3 "3 - Union / cohabiting" ///
				                                4 "4 - Widowed" 5 "5 - Divorced / separated" 
		        label values ilo_mrts_details label_mrts_details
		        lab var ilo_mrts_details "Marital status"
				
	* Aggregate
	gen ilo_mrts_aggregate=.
	    replace ilo_mrts_aggregate=1 if inlist(ilo_mrts_details,1,4,5)          // Single / Widowed / Divorced / Separated
		replace ilo_mrts_aggregate=2 if inlist(ilo_mrts_details,2,3)            // Married / Union / Cohabiting
	
		        label define label_mrts_aggregate 1 "1 - Single / Widowed / Divorced / Separated" 2 "2 - Married / Union / Cohabiting"
		        label values ilo_mrts_aggregate label_mrts_aggregate
		        lab var ilo_mrts_aggregate "Marital status (Aggregate levels)"											

* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*			Disability status ('ilo_dsb_details')                              *
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------

    * Detailed
	gen ilo_dsb_details=.
	    replace ilo_dsb_details=1 if (s2cq3==1 & s2cq4==1 & s2cq5==1 & s2cq6==1 & s2cq7==1 & s2cq8==1)	// No, no difficulty
		replace ilo_dsb_details=2 if (s2cq3==2 | s2cq4==2 | s2cq5==2 | s2cq6==2 | s2cq7==2 | s2cq8==2)	// Yes, some difficulty
		replace ilo_dsb_details=3 if (s2cq3==3 | s2cq4==3 | s2cq5==3 | s2cq6==3 | s2cq7==3 | s2cq8==3)	// Yes, a lot of difficulty
		replace ilo_dsb_details=4 if (s2cq3==4 | s2cq4==4 | s2cq5==4 | s2cq6==4 | s2cq7==4 | s2cq8==4)	// Cannot do it at all
		replace ilo_dsb_details=1 if ilo_dsb_details==.
				label def dsb_det_lab 1 "1 - No, no difficulty" 2 "2 - Yes, some difficulty" 3 "3 - Yes, a lot of difficulty" 4 "4 - Cannot do it at all"
				label val ilo_dsb_details dsb_det_lab
				label var ilo_dsb_details "Disability status (Details)"

    * Aggregate  	
	gen ilo_dsb_aggregate=.
	    replace ilo_dsb_aggregate=1 if inlist(ilo_dsb_details,1,2)				// Persons without disability
		replace ilo_dsb_aggregate=2 if inlist(ilo_dsb_details,3,4)				// Persons with disability
				label def dsb_lab 1 "1 - Persons without disability" 2 "2 - Persons with disability" 
				label val ilo_dsb_aggregate dsb_lab
				label var ilo_dsb_aggregate "Disability status (Aggregate)"	
				
// Other labour Market variables 
* sector of employment
ren (s4q11 hid) (sector hhid)
* ilo_lfs : Labour Force Status

gen pay_pit = .
      replace pay_pit = 1 if (ilo_lfs ==1 | ilo_lfs==2) & (s4q13 == 1) & (s4q16==1)
	  replace pay_pit = 0 if pay_pit ==.
	          label def pay_pit 1 "Pays PIT" 0 "Does not pay PIT"
			  label val pay_pit pay_pit
			  label var pay_pit "Worker pays PIT"

merge m:1 hhid using `income', keep(match) nogen  
	  
// how many people within the household pay PIT 
   gen work = . 
	   replace work = 1 if pay_pit ==1
	   replace work = 0 if work ==. 
	   replace work =1 if (s4q3 ==1 & work !=1)
   egen hhwork = sum(work), by(hhid)
		label var hhwork "Number of working household member with contract and pay social security"

// labour income from household labour income 
   gen hl_income = hhincome/hhwork
   replace hl_income = 0 if work ==0
		label var hl_income "Individual labour income based on household labour income"
	
// a. Generate the missing variables
		gen female = sex ==2
		gen rural = area ==2
		gen agesq = age^2
		gen sector_1 = sector ==	1
		gen sector_2 = sector ==	3
		gen sector_3 = sector >=	4 & sector !=. 

		gen empstat_1 = 			(s4q12 >=1 & s4q12<=4 )
		gen empstat_2 = ilo_lfs ==1
gen wave_1 =1
gen empstat_3 = 0	


gen entitled_pension_1 = .
			replace entitled_pension_1 = 1 if (ilo_lfs ==1 | ilo_lfs==2) & (s4q13 == 1) & (s4q16==1)
			replace entitled_pension_1 = 0 if entitled_pension_1 ==.
	
//  b. label Xs

		lab var female "Share of female worker"
		lab var age "Mean age of workers"
		lab var agesq "Mean age squared of workers"
		lab var ilo_edu_isced11 "Highest level of educational attainment"
		*lab var educy "Average years of education of workers"
		lab var sector_1 "Share of workers in Agriculture"
		lab var sector_2 "Share of workers in Manufacture"
		lab var sector_3 "Share of workers in Services"
		lab var empstat_1 "Share of self-employee/own boss"
		lab var empstat_2 "Share of salaried workers"
		lab var empstat_3 "Share of other workers"
		lab var rural "Live in rural areas"
		lab var wave_1 "Interviewed during first wave"
	
gen totincome  = hhincome

		gen manager = s4q10 ==1
		ren s4q10 occupation
		gen manager_service = manager*sector_3
		gen female_manager = manager*female
		gen formal = pay_pit==1
		gen formal_female = formal*female
		gen edu_high = ilo_edu_isced11 >=8
		gen manager_eduhigh = manager*edu_high

	save "$presim/02_income_tax_GMB.dta", replace 	
	
	
	// Descriptives 
	tabstat work if ilo_lfs ==1 | ilo_lfs == 2, by(area)
	tabstat work if ilo_lfs ==1 | ilo_lfs == 2, by(sector)
	
/* -------------------------------------------------------------------------- */
/*      A. Mincer model estimation for average household worker               */
/* -------------------------------------------------------------------------- */

global xls_out		"${path}/03_Tool/Figure12_Direct_Taxes.xlsx"

global Xind female age agesq ilo_edu_isced11 sector_* empstat_* manager manager_service formal formal_female female_manager edu_high manager_eduhigh
global Xhh rural region 
global Xs $Xind $Xhh

//  a. average over individual data
collapse (mean) $Xind hl_income hhwork zref pcc [pw = hhweight], by(hhid rural region hhweight)
	
//  b. log labor income per worker
gen double lnLx=ln(hl_income/hhwork)	
	

/* ---- 2. Mincer equation -------------------------------------------------- */
		gen wgt = hhweight
		sum $Xs
		sum lnLx wgt hhwork

//  a. regression
		eststo Mincer : regress lnLx $Xs [pw=wgt*hhwork]	
		ereturn list
		* Print 
		putexcel set "${xls_out}", sheet("Mincer") modify
		putexcel A2 = `e(r2)'
		predict res if e(sample) , res
		gen eresid = exp(res) 
		sum eresid [aw=wgt*hhwork]
		local duan = r(mean)

	//  b. estimation plot
qui coefplot Mincer, keep(hoursf female age agesq educy sector_1 sector_2 sector_3 empstat_1 empstat_2 empstat_3 rural manager manager_service formal) xline(0) title("Mincer regression results") byopts(xrescale) graphregion(col(white)) bgcol(white) eqlabels("labor incomes based", asequations)
graph export "${path}/03_Tool/Mincer_$iso3.png", replace
putexcel F4 = image("${path}/03_Tool/Mincer_$iso3.png")

	
/* -------------------------------------------------------------------------- */
/*      B. Apply estimated coefficients to individual level data              */
/* -------------------------------------------------------------------------- */

/* ---- 1. Predict individual labor income ---------------------------------- */	
	
	
	use "$presim/02_income_tax_GMB.dta", clear 
	
//  b. impute missing values of Xs
		sum $Xind

//  c. merge in hh level variables
*		merge m:1 idh using `li', keepusing($Xhh) assert(match using) keep(match)

//  d. predict individual level labor income
		estimates restore Mincer
		predict double li    // predict individual labor income for each individual based on their characteristics and the coefficients from the average worker regression
		replace li = exp(li)*`duan' // Duan's smearing estimator, see https://people.stat.sc.edu/hoyen/STAT704/Notes/Smearing.pdf
		sum li
	
save "$presim/02_income_tax_GMB_final.dta", replace 
	
if $devmode ==0 {
save `02_income_tax_GMB_final', clear
}
if $devmode ==1 {
save "$presim/02_income_tax_GMB_final.dta", replace 

}


qwe	
/* -------------------------------------------------------------------------- */
/*      C. All Household Variables                                            */
/* -------------------------------------------------------------------------- */

use "$presim/01_menages2.dta", clear 




	
	
	
* ------------------------------------------------------------------------------ -----------------------
* ------------------------------------------------------------------------------ -----------------------
*			Estimate a mincer equation, to elicitsharing ratio of income                               *
* ------------------------------------------------------------------------------ -----------------------
* ------------------------------------------------------------------------------ -----------------------	
	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	qwe
							
// Labour force data 2018 
use "$data_sn/Stata/LFS 2018 Anonymized.dta", clear 

// create the variables of interest. 

*ren (hl6 hl4 hh7 hh8) (age sex residence region)


*Age of interest ()
	tab hl6
	drop if hl6<15
	ren hl6 age


gen area_res=.
	    replace area_res=1 if hh7==1				// Urban 
		replace area_res=2 if hh7==2				// Rural
		        lab def area_res_lab 1 "1 - Urban" 2 "2 - Rural"
		        lab val area_res area_res_lab
		        lab var area_res "Residence area"
				
				
gen sex=.
	    replace sex=1 if hl4==1				// Male
		replace sex=2 if hl4==2				// Female
		        label define label_Sex 1 "1 - Male" 2 "2 - Female"
		        label values sex label_Sex
		        lab var sex "Sex"				
				
	*---------------------------------------------------------------------------
	* ISCED 11
	*---------------------------------------------------------------------------
				
    * Detailed				
    gen ilo_edu_isced11=.
		replace ilo_edu_isced11=1 if ed4==2					// No schooling
		replace ilo_edu_isced11=2 if ed8_level==0			// Early childhood education
		replace ilo_edu_isced11=3 if ed8_level==1	  		// Primary education
		replace ilo_edu_isced11=4 if ed8_level==2			// Lower secondary education
		replace ilo_edu_isced11=5 if ed8_level==3		    // Upper secondary education
		replace ilo_edu_isced11=6 if ed8_level==4			// Vocational certificate 
		replace ilo_edu_isced11=7 if ed8_level==5			// Dimploma
		replace ilo_edu_isced11=8 if ed8_level==6			// Higher 
		
			    label def isced_11_lab 1 "X - No schooling" 2 "0 - Early childhood education" 3 "1 - Primary education" 4 "2 - Lower secondary education" ///
				                       5 "3 - Upper secondary education" 6 "4 - Vocational certificate " 7 "5 - Dimploma" 8 "6 - Higher" 
			    label val ilo_edu_isced11 isced_11_lab
			    lab var ilo_edu_isced11 "Educational attainment (ISCED 11)"

				
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*			           Marital status ('ilo_mrts') 	                           *
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------

	* Detailed
	gen ilo_mrts_details=.
	    replace ilo_mrts_details=1 if hl8==2					// Single
		replace ilo_mrts_details=2 if hl8==1					// Married
		replace ilo_mrts_details=3 if hl8==3					// Union / cohabiting
		* replace ilo_mrts_details=4 if 						// Widowed
		replace ilo_mrts_details=5 if hl8==4					// Divorced / separated
		
		        label define label_mrts_details 1 "1 - Single" 2 "2 - Married" 3 "3 - Union / cohabiting" ///
				                                4 "4 - Widowed" 5 "5 - Divorced / separated" 
		        label values ilo_mrts_details label_mrts_details
		        lab var ilo_mrts_details "Marital status"
				
	* Aggregate
	gen ilo_mrts_aggregate=.
	    replace ilo_mrts_aggregate=1 if inlist(ilo_mrts_details,1,4,5)          // Single / Widowed / Divorced / Separated
		replace ilo_mrts_aggregate=2 if inlist(ilo_mrts_details,2,3)            // Married / Union / Cohabiting
	
		        label define label_mrts_aggregate 1 "1 - Single / Widowed / Divorced / Separated" 2 "2 - Married / Union / Cohabiting"
		        label values ilo_mrts_aggregate label_mrts_aggregate
		        lab var ilo_mrts_aggregate "Marital status (Aggregate levels)"				
			
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*			Disability status ('ilo_dsb_details')                              *
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------

    * Detailed
	gen ilo_dsb_details=.
	    replace ilo_dsb_details=1 if (fn3==1 & fn4==1 & fn5==1 & fn6==1 & fn7==1 & fn8==1)	// No, no difficulty
		replace ilo_dsb_details=2 if (fn3==2 | fn4==2 | fn5==2 | fn6==2 | fn7==2 | fn8==2)	// Yes, some difficulty
		replace ilo_dsb_details=3 if (fn3==3 | fn4==3 | fn5==3 | fn6==3 | fn7==3 | fn8==3)	// Yes, a lot of difficulty
		replace ilo_dsb_details=4 if (fn3==4 | fn4==4 | fn5==4 | fn6==4 | fn7==4 | fn8==4)	// Cannot do it at all
		replace ilo_dsb_details=1 if ilo_dsb_details==.
				label def dsb_det_lab 1 "1 - No, no difficulty" 2 "2 - Yes, some difficulty" 3 "3 - Yes, a lot of difficulty" 4 "4 - Cannot do it at all"
				label val ilo_dsb_details dsb_det_lab
				label var ilo_dsb_details "Disability status (Details)"

    * Aggregate  	
	gen ilo_dsb_aggregate=.
	    replace ilo_dsb_aggregate=1 if inlist(ilo_dsb_details,1,2)				// Persons without disability
		replace ilo_dsb_aggregate=2 if inlist(ilo_dsb_details,3,4)				// Persons with disability
				label def dsb_lab 1 "1 - Persons without disability" 2 "2 - Persons with disability" 
				label val ilo_dsb_aggregate dsb_lab
				label var ilo_dsb_aggregate "Disability status (Aggregate)"				
				
				
// define employment
   gen employed = . 
       replace employed = 1 if inlist(em5, ,)
	   
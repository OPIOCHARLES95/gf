# GTM HIV Data
Files in  the GTM HIV Folder
======


## Basic Organization
This folder has GTM HIV anaylsis. It has a mixture of anaylsis from SIGSA, SIGPRO and Condom Analysis

### HIV Testing File Prep
1. **prep_hiv_data_SIGSA_patientlvl_testing.R**
	- Cleans the Patient-Level SIGSA data
2. **prep_hiv_testing_combine_SIGSA_SIGPRO.R**
	- Combines SIGSA and SIGPRO data for testing
	- uses output from prep_hiv_data_SIGSA_patientlvl_testing.R
3. **prep_hiv_data_SIGSA_program_data.R** -- **DO NOT USE**
	- Cleans the Facility-Level SIGSA data
 	- We decided to proceed with patient-level data since facility-level is a subset of patient 
4. **prep_hiv_data_SIGSA.R** -- **DO NOT USE**
	- Orginal code for generating maps for SIGSA data, old code

### HIV Testing Visualization Code
1. **map_hiv_testing_combined.R**
	- creates figures and maps for combined SIGSA-SIGPRO testing 
	- uses output from prep_hiv_testing_combine_SIGSA_SIGPRO.R
2. **map_hiv_data_SIGSA_program_data.R** -- **DO NOT USE**
	- creates figures and maps for facility-level SIGSA data, old code
3. **map_hiv_data_SIGSA.R** -- **DO NOT USE**
	- creates figures and maps for patient-level SIGSA data, old code



### HIV Treatment Prep
1. **prep_hiv_data_SIGSA_program_data _Treatment.R**
	- Cleans the Facility-Level SIGSA Treatment data, monthly reports
2. **map_hiv_data_SIGSA_program_data _Treatment.R**
	- creates figures and maps for SIGSA treament
	- these variable names are VERY long


### Condom Analysis & Supply Chain -- done by Irena and Guillermo
1. **Guatemala-hiv-exploratory.R**
2. **master_gtm_prep.R**
3. **prep_condom_data.R**


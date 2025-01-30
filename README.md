
<!-- README.md is generated from README.Rmd. Please edit that file -->

# TestGeneratorWorkshop

<!-- badges: start -->
<!-- badges: end -->

## Setting Up the Test Environment

Before running the tests, ensure that you have installed the necessary
packages. You can install them using the following command:

    install.packages(c("dplyr", "CDMConnector", "omopgenerics", "testthat", "PatientProfiles", "here"))

## Running the Tests with `testthat`

The following code executes three separate tests:

- **Checking cohort counts**
- **Characterization**
- **Running the study**

## Creating a Test Database Using Excel

- This project includes a sample population dataset,
  `icu_sample_population`, located in the `tests/testthat` folder. It
  contains:

  - 5 patients with ICU visits
  - 7 patients with COVID-19
  - 5 patients with mechanical ventilation

  Explore the dataset and modify the tables to create your own test
  cases.

- The `TestGenerator` package provides a blank CDM, allowing you to
  input your own patient data from scratch.

- You can also create a test database for one of your ongoing studies.

- If needed, you can collaborate with a data scientist, or we can assist
  in processing the patients and running the tests for you.

``` r
cdmVersion <- "5.3"

TestGenerator::generateTestTables(
  tableNames = c("person", "drug_exposure", "condition_occurrence"),
  cdmVersion = cdmVersion,
  outputFolder = here::here("tests", "testthat"),
  filename = paste0("test_cdm_", cdmVersion)
)
```

## Reading the Test Data

After generating the test patients, a data scientist can use the Excel
file to create the test CDM.

``` r
filePath <- testthat::test_path("icu_sample_population.xlsx")
TestGenerator::readPatients.xl(
  filePath = filePath,
  testName = "icu_sample_population",
  cdmVersion = "5.3"
)
#> ✔ Unit Test Definition Created Successfully: 'icu_sample_population'
```

## Creating the CDM Database in Memory

Now, we can select a dataset to create our CDM reference.

``` r
cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population")
#> Note: method with signature 'DBIConnection#Id' chosen for function 'dbExistsTable',
#>  target signature 'duckdb_connection#Id'.
#>  "duckdb_connection#ANY" would also be valid
#> ! cdm name not specified and could not be inferred from the cdm source table
#> ✔ Patients pushed to blank CDM successfully
```

## Exploring the Data as a Standard CDM Reference

The CDM reference contains all tables following standard conventions.

``` r
cdm
#> 
#> ── # OMOP CDM reference (duckdb) of An OMOP CDM database ───────────────────────
#> • omop tables: person, observation_period, visit_occurrence, visit_detail,
#> condition_occurrence, drug_exposure, procedure_occurrence, device_exposure,
#> measurement, observation, death, note, note_nlp, specimen, fact_relationship,
#> location, care_site, provider, payer_plan_period, cost, drug_era, dose_era,
#> condition_era, metadata, cdm_source, concept, vocabulary, domain,
#> concept_class, concept_relationship, relationship, concept_synonym,
#> concept_ancestor, source_to_concept_map, drug_strength, cohort_definition,
#> attribute_definition
#> • cohort tables: -
#> • achilles tables: -
#> • other tables: -

cdm$person
#> # Source:   table<main.person> [?? x 18]
#> # Database: DuckDB v1.1.3 [cbarboza@Windows 10 x64:R 4.4.1/C:\Users\cbarboza\AppData\Local\Temp\RtmpoD3XkA\file5dc81f8378e8.duckdb]
#>   person_id gender_concept_id year_of_birth month_of_birth day_of_birth
#>       <int>             <int>         <int>          <int>        <int>
#> 1         1              8532          1980             NA           NA
#> 2         2              8507          1990             NA           NA
#> 3         3              8532          2000             NA           NA
#> 4         4              8507          1980             NA           NA
#> 5         5              8532          1990             NA           NA
#> 6         6              8507          2000             NA           NA
#> 7         7              8532          1980             NA           NA
#> 8         8              8507          1990             NA           NA
#> # ℹ 13 more variables: birth_datetime <dttm>, race_concept_id <int>,
#> #   ethnicity_concept_id <int>, location_id <int>, provider_id <int>,
#> #   care_site_id <int>, person_source_value <chr>, gender_source_value <chr>,
#> #   gender_source_concept_id <int>, race_source_value <chr>,
#> #   race_source_concept_id <int>, ethnicity_source_value <chr>,
#> #   ethnicity_source_concept_id <int>
```

## Creating Cohorts and Running Tests in the `testthat` Environment

The following steps are performed:

- Checking cohort counts
- Testing the characterization function
- Running the study

``` r
library(dplyr)
library(CDMConnector)
library(omopgenerics)
library(testthat)
library(PatientProfiles)
library(here)
source(here::here("R/icu.R"))

test_that("Check cohort counts for COVID, ICU visits, and ventilation", {
  cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population")
  
  # Generate cohorts
  cohorts <- here::here("cohorts", "population")
  icu_cohort_sets <- CDMConnector::readCohortSet(cohorts)
  cdm <- CDMConnector::generate_cohort_set(cdm, icu_cohort_sets, name = "icu_population_cohorts")
  cdm[["icu_population_cohorts"]] %>% omopgenerics::settings()
  
  # Check counts
  cohort_counts <- omopgenerics::cohortCount(cdm$icu_population_cohorts)
  
  expect_equal(cohort_counts[1, ] %>% pull(number_records), 5)
  expect_equal(cohort_counts[2, ] %>% pull(number_records), 7)
  expect_equal(cohort_counts[3, ] %>% pull(number_records), 5)
})

test_that("Characterization", {
  cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population")
  cohorts <- here::here("cohorts", "population")
  
  icu_cohort <- CDMConnector::readCohortSet(cohorts) %>%
    dplyr::filter(cohort_name == "p2_c1_014_icu_visit_dv_v2")
  cdm <- CDMConnector::generate_cohort_set(cdm, icu_cohort, name = "icu")
  
  covid_cohort <- CDMConnector::readCohortSet(cohorts) %>%
    dplyr::filter(cohort_name == "p2_c1_014_covid19_v2")
  cdm <- CDMConnector::generate_cohort_set(cdm, covid_cohort, name = "covid")
  
  ventilation_cohort <- CDMConnector::readCohortSet(cohorts) %>%
    dplyr::filter(cohort_name == "p2_c1_014_mechanical_ventilation_dv_v2")
  cdm <- CDMConnector::generate_cohort_set(cdm, ventilation_cohort, name = "ventilation")
  
  summaryCharacterization <- characterizeICU(
    cdm = cdm,
    icuCohort = "icu",
    covidCohort = "covid",
    ventilationCohort = "ventilation"
  )
  
  expect_s3_class(summaryCharacterization, c("summarised_result", "omop_result"))
  expect_equal(
    summaryCharacterization %>% 
      filter(variable_name == "covid_m14_to_0", estimate_name == "count") %>% 
      pull(estimate_value), "4"
  )
  expect_equal(
    summaryCharacterization %>% 
      filter(variable_name == "ventilation_m7_to_0", estimate_name == "count") %>% 
      pull(estimate_value), "3"
  )
})

test_that("Run Study", {
  cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population")
  outputDir <- paste0(tempdir(), "/results")
  dir.create(outputDir)
  
  runStudy(cdm, outputDir = outputDir)
  
  files_created <- list.files(outputDir)
  expect_true("icu_summary.csv" %in% files_created)
  
  unlink(outputDir, recursive = TRUE)
})
```

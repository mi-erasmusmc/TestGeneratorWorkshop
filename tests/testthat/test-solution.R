library(dplyr)
library(CDMConnector)
library(omopgenerics)
library(testthat)
library(PatientProfiles)
source("R/icu.R")

test_that("Check cohort counts for covid, icu visits and ventilation", {
  # Load Patients

  # cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population_remifentanil")
  # cdm <- TestGenerator::patientsCDM(testName = "mimicIVsubset")
  cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population")
  
  # Generate cohorts
  cohorts <- here::here("cohorts", "population")
  icu_cohort_sets <- CDMConnector::readCohortSet(cohorts)
  cdm <- CDMConnector::generate_cohort_set(cdm, icu_cohort_sets, name = "icu_population_cohorts")
  cdm[["icu_population_cohorts"]] %>% omopgenerics::settings()
  
  # Check counts
  
  cohort_counts <- omopgenerics::cohortCount(cdm$icu_population_cohorts)
  
  # 1. Covid
  covid <- cohort_counts[1, ] %>% pull(number_records)
  expect_equal(covid, 5)

  # 2. ICU Visit
  icu_visit <- cohort_counts[2, ] %>% pull(number_records)
  expect_equal(icu_visit, 7)
  
  # 3. Mechanical ventilation
  ventilation <- cohort_counts[3, ] %>% pull(number_records)
  expect_equal(ventilation, 5)
  
})

test_that("Characterise", {
  
  # cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population_remifentanil")
  cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population")
  
  # Generate cohorts
  cohorts <- here::here("cohorts", "population")

  # ICU Cohort 
  
  icu_cohort <- CDMConnector::readCohortSet(cohorts) %>%
    dplyr::filter(cohort_name == "p2_c1_014_icu_visit_dv_v2")
  cdm <- CDMConnector::generate_cohort_set(cdm, icu_cohort, name = "icu")
  
  # Covid Cohort
  
  covid_cohort <- CDMConnector::readCohortSet(cohorts) %>%
    dplyr::filter(cohort_name == "p2_c1_014_covid19_v2")
  cdm <- CDMConnector::generate_cohort_set(cdm, covid_cohort, name = "covid")
  
  # Ventilation Cohort 
  
  ventilation_cohort <- CDMConnector::readCohortSet(cohorts) %>%
    dplyr::filter(cohort_name == "p2_c1_014_mechanical_ventilation_dv_v2")
  cdm <- CDMConnector::generate_cohort_set(cdm, ventilation_cohort, name = "ventilation")
  
  # Characterization
  
  summaryCharacterization <- characterizeICU(cdm = cdm,
                                             icuCohort = "icu",
                                             covidCohort = "covid",
                                             ventilationCohort = "ventilation")
  
  expect_s3_class(summaryCharacterization, c("summarised_result", "omop_result"))
  countCovid <- summaryCharacterization %>% filter(variable_name == "covid_m14_to_0",
                                                   estimate_name == "count") %>% pull(estimate_value)
  expect_equal(countCovid, "4")
  countVentilation <- summaryCharacterization %>% filter(variable_name == "ventilation_m7_to_0",
                                                         estimate_name == "count") %>% pull(estimate_value)
  expect_equal(countVentilation, "3")
  
  # # Visualization
  # icu_visit <- cdm[["icu"]] %>% dplyr::collect()
  # covid <- cdm[["covid"]] %>% dplyr::collect()
  # ventilation <- cdm[["ventilation"]] %>% dplyr::collect()
  # 
  # TestGenerator::graphCohort(subject_id = 8, list("covid" = covid,
  #                                                 "ventilation" = ventilation,
  #                                                 "icu_visit" = icu_visit))

})

test_that("Run Study", {
  
  # cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population_remifentanil")
  cdm <- TestGenerator::patientsCDM(testName = "icu_sample_population")
  outputDir <- paste0(tempdir(), "/results")
  dir.create(outputDir)
  
  # Run study
  runStudy(cdm, outputDir = outputDir)
  
  files_created <- list.files(outputDir)
  expect_true("icu_summary.csv" %in% files_created)

  unlink(outputDir, recursive = TRUE)
  
})

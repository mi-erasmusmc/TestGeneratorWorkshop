#' Characterize Covid
#' Characterization of ICU patients with Covid
#'
#' @param cdm A CDM reference object
#' @param icuCohort Population CDM cohort
#' @param covidCohort Covid cohort
#' @param ventilationCohort Ventilation cohort
#' @param drug_name Drug name in character
#' @param strata In character
#' @param dbname In character
#'
#' @return A summarisedResult from PatientProfiles
characterizeICU <- function(cdm,
                            icuCohort,
                            covidCohort,
                            ventilationCohort) {

  summaryCharacterization <- cdm[[icuCohort]] %>%
    PatientProfiles::addDemographics() %>%
    PatientProfiles::addCohortIntersectFlag(indexDate = "cohort_start_date",
                                            censorDate = "cohort_end_date",
                                            targetCohortTable = covidCohort,
                                            targetStartDate = "cohort_start_date",
                                            targetEndDate = "cohort_start_date",
                                            window = list(c(-14, 0)),
                                            nameStyle = "covid_{window_name}") %>%
    PatientProfiles::addCohortIntersectFlag(indexDate = "cohort_start_date",
                                            censorDate = "cohort_end_date",
                                            targetCohortTable = ventilationCohort,
                                            targetStartDate = "cohort_start_date",
                                            targetEndDate = "cohort_start_date",
                                            window = list(c(-7, 0)),
                                            nameStyle = "ventilation_{window_name}") %>%
    PatientProfiles::summariseResult()
  return(summaryCharacterization)
}

runStudy <- function(cdm,
                     outputDir = NULL) {
  
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
  
  summarisedResult <- characterizeICU(cdm = cdm,
                                      icuCohort = "icu",
                                      covidCohort = "covid",
                                      ventilationCohort = "ventilation")
  
  file_location <- paste0(outputDir, "/icu_summary.csv")
  
  omopgenerics::exportSummarisedResult(summarisedResult,
                                       fileName = file_location)
  
}
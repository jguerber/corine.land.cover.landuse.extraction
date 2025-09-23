#' Automatically select the dataset to use
#'
#' `get_clc_year` returns the year of an available data from the given sampling
#' year. The selected year is the highest strictly inferior available year. If
#' 2012 and 2018 are the available years, 2012 will be selected for date
#' between 2013 and 2018, 2018 will be selected for the rest. If no available
#' year is smaller than the sampling year, the smallest available year is
#' selected.
#'
#' @param year Integer. Sampling year.
#' @param available_years Vector of available years.
#' Is automatically calculated with [set_corine_land_cover_path()].
#'
#' @returns Integer. Selected year.
#' @keywords internal
#'
#' @examples
#' get_clc_year(2002, available_years = c(2012, 2018))
#' get_clc_year(2013, available_years = c(2012, 2018))
#' get_clc_year(2022, available_years = c(2012, 2018))
get_clc_year <- function(year, available_years = getOption("available_years")) {
  past_years <- available_years[available_years < year]
  if (length(past_years) > 0) {
    return(max(past_years))
  } else {
    return(min(available_years))
  }
}

#' Check if the given year is available
#'
#' `check_clc_year` returns an error is the given year is not available.
#' Available years must have be calculated with the function
#' [set_corine_land_cover_path()].
#'
#' @param input_clc_year Integer.
#'
#' @returns Nothing if the year is available. An error otherwise.
#' @keywords internal
#'
#' @examples
#' check_clc_year(2006)
#' check_clc_year(2012)
check_clc_year <- function(input_clc_year) {
  if (!(is.numeric(input_clc_year) &
        length(input_clc_year) == 1 &
        (input_clc_year %in% getOption("available_years")))) {
    stop("Invalid input for 'input_clc_year'")
  }
}

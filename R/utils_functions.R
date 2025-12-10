#' Aggregate composition data according to CORINE Land Cover levels
#'
#' `aggregate_to_level_i` transforms a data frame where the composition data
#' is given at the third level of resolution to the second or first level.
#'
#' @param level_3_df Data frame of compositions, where the composition
#' variables are named with three digits. Compatible with the output of
#' `get_full_compositions`.
#' @param i 1 or 2. Defines the output level of aggregation.
#'
#' @returns Data frame similar to `level_3_df`. The composition columns are
#' replaced with data aggregated at the desired output level.
#' @export
#'
#' @examples
#' # CORINE data sets must be loaded first
#' clc_path <- system.file(
#'   "extdata", package = "corine.land.cover.landuse.extraction"
#' )
#' set_corine_land_cover_path(clc_path)
#' # Extract with auto selection
#' level_3_compositions <- get_full_compositions(
#'   example_points_df, buffer_radius_m = 1, input_clc_year = "auto"
#' )
#' # Combine compositions
#' level_2_compositions <- aggregate_to_level_i(level_3_compositions, 2)
#' level_1_compositions <- aggregate_to_level_i(level_3_compositions, 1)
#' level_3_compositions ; level_2_compositions ; level_1_compositions
aggregate_to_level_i <- function(level_3_df, i) {
  level_3_names <- grep("\\d{3}", names(level_3_df), value = TRUE)
  level_i_names <- stringr::str_replace(
    level_3_names, sprintf("(?<=\\d{%d})\\d{%d}", i, 3-i), "")

  level_i_df <- unique(level_i_names) %>%
    sapply(function(clc_code) {
      corresponding_cols <- level_3_names[level_i_names == clc_code]
      level_3_df %>%
        dplyr::select(dplyr::all_of(corresponding_cols)) %>%
        rowSums()
    }) %>%
    as.data.frame() %>%
    dplyr::bind_cols(
      dplyr::select(level_3_df, -dplyr::all_of(level_3_names)), .)
  return(level_i_df)
}

#' Faster version of st::st_intercetion
#' 
#' https://github.com/r-spatial/sf/issues/801#issuecomment-1279636073
#' 
#' @author Gordon McDonald
st_intersection_faster <- function(x,y,...){

  # subset with st_intersects
  y_subset <-
    st_intersects(x, y) %>%
    unlist() %>%
    unique() %>%
    sort() %>%
    {y[.,]}

  st_intersection(x, y_subset,...)
}
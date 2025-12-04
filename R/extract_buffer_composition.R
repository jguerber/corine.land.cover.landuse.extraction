#' Extract the land cover composition
#'
#' `extract_compositions` returns the composition of the land cover in the area
#' around the points given in a data frame.
#'
#' This function performs the following steps:
#' * Transform points: points data frame is transformed to a sf object and
#' converted to the CORINE data set coordinate system
#' * Compute buffer compositions: for each point, a round buffer of the given
#' radius is intersected with the dataset land cover categories
#' * Combine by point_id, land cover type and get buffer area ratio: for each
#' category in the buffer, the area is computed and then converted to a
#' proportion of the area of the buffer.
#'
#' @param points_df Data frame containing all the locations of the points from
#' which to extract the surrounding composition. Coordinates need to be given in
#' two columns names `longitude` and `latitude`. Each row must have a unique
#' identifier set in the `point_id` column.
#' @param map Sf object containing the polygons describing the territory land
#' cover.
#' @param buffer_radius_m Radius length in meters of the circular buffer
#' centered on the coordinates of the points from which to extract the land
#' cover composition.
#' @param points_crs Identifier of the coordinate reference system (CRS)
#' associated with the coordinates of the input points. Default is EPSG:4326.
#'
#' @returns Data frame containing the relative compositions of the buffers
#' centered around the input points. Each land cover is associated with columns
#' whose values range from 0 (category absent from the buffer zone) to 1 (the
#' buffer is entirely composed of this category).
#' @export
#'
#' @examples
#' map_folder <- system.file(
#'   "extdata", "2012",
#'   package = "corine.land.cover.landuse.extraction"
#' )
#' map <- read_clc_map_shapefile(map_folder)
#' buffer_radius_m <- 1
#' extract_compositions(
#'   example_points_df,
#'   map,
#'   buffer_radius_m
#' )
extract_compositions <- function(points_df, map, buffer_radius_m,
                                 points_crs = 4326) {
  ## Transform points
  points_sf <- points_df %>%
    sf::st_as_sf(coords = c("longitude", "latitude"),
                 crs = sf::st_crs(points_crs), agr = "constant") %>%
    sf::st_transform(crs = sf::st_crs(map))

  ## Compute buffer compositions
  buffers <- sf::st_buffer(points_sf, buffer_radius_m)
  compositions <- sf::st_intersection(map, buffers) %>%
    dplyr::mutate(area = sf::st_area(.)) %>%
    dplyr::rename_with(~ "code", dplyr::matches("^code", ignore.case = TRUE))

  ## Combine by point_id and land cover type
  code_clc_list <- unique(compositions$code)
  compositions_df <- sf::st_drop_geometry(points_sf)
  for (code_clc in code_clc_list) {
    sum_area <- compositions %>%
      dplyr::filter(code == code_clc) %>%
      dplyr::group_by(point_id) %>%
      dplyr::summarise(!!code_clc := as.numeric(sum(area))) %>%
      sf::st_drop_geometry()
    compositions_df <- compositions_df %>%
      dplyr::left_join(sum_area, by = "point_id")
  }

  ## Compute area ratio
  compositions_df <- compositions_df %>%
    dplyr::mutate(
      dplyr::across(dplyr::where(is.numeric), ~ replace(., is.na(.), 0)))
  compositions_df$buffer_area <- rowSums(compositions_df[code_clc_list])
  compositions_df[code_clc_list] <- compositions_df[code_clc_list] /
    compositions_df$buffer_area

  return(compositions_df)
}

#' Extract the land cover composition for a given year
#'
#' Internal function. For a given year, `get_year_compositions` filters the data
#' points, loads the corresponding CORINE Land Cover dataset and runs the
#' [extract_compositions()] function.
#'
#' This function performs the following steps:
#' * Filter: points data frame is filter to keep the locations where to extract
#' buffer compositions
#' * Load: the corresponding CORINE Land Cover dataset is loaded inot memory
#' * Extract: extraction is made between the points and the loaded dateset.
#'
#' @param points_df Data frame containing all the locations of the points from
#' which to extract the surrounding composition. Coordinates need to be given in
#' two columns names `longitude` and `latitude`. This function implies that the
#' coordinates are in the EPSG:4326 reference system. Each row must have a
#' unique identifier set in the `point_id` column. The year of the CORINE Land
#' Cover dataset to use must be given in the `clc_year` column.
#' @param input_year Numeric identifying the dataset to use. It is used to
#' filter `points_df`.
#' @param buffer_radius_m Radius length in meters of the circular buffer
#' centered on the coordinates of the points from which to extract the land
#' cover composition.
#' @param points_crs Identifier of the coordinate reference system (CRS)
#' associated with the coordinates of the input points. Default is EPSG:4326.
#'
#' @returns An [extract_compositions()] output. Data frame containing the
#' relative compositions of the buffers centered around the input points. Each
#' land cover is associated with columns whose values range from 0 (category
#' absent from the buffer zone) to 1 (the buffer is entirely composed of this
#' category).
#' @keywords internal
#'
#' @examples
#' buffer_radius_m <- 1
#' get_year_compositions(example_points_df, 2012, buffer_radius_m)
get_year_compositions <- function(points_df, input_year,
                                  buffer_radius_m, points_crs = 4326) {
  filtered_df <- points_df %>%
    dplyr::filter(clc_year == input_year)
  map <- sf::st_make_valid(read_clc_map(input_year))
  compositions_df <- extract_compositions(filtered_df, map,
                                          buffer_radius_m, points_crs)
  return(compositions_df)
}

#' Extract the land cover composition for the complete point data frame
#'
#' Main function. For a given buffer radius, `get_full_compositions` splits
#' the points data according to the CORINE Land Cover dataset to use and process
#' to extract the composition of the land cover in the area around the points.
#'
#' This function performs the following steps:
#' * Compute year to use: if the year corresponding to the dataset is not
#' given, it is automatically calculated from the sampling year
#' * Extract for each dataset: extraction is performed for each data set
#' * Combine data frame: year composition data frames are combined.
#'
#' @param points_df Data frame containing all the locations of the points from
#' which to extract the surrounding composition. Coordinates need to be given in
#' two columns names `longitude` and `latitude`. This function implies that the
#' coordinates are in the EPSG:4326 reference system. Each row must have a
#' unique identifier set in the `point_id` column. If the CORINE Land Cover
#' dataset selection is set to 'auto', a `year` column must be provided.
#' @param buffer_radius_m Radius length in meters of the circular buffer
#' centered on the coordinates of the points from which to extract the land
#' cover composition.
#' @param input_clc_year String 'auto' or integer. Default 'auto'. 'auto'
#' selects the closest previous dataset available for each point, according to
#' the `year` value. If 2012 and 2018 are the available years, 2012 will be
#' selected for date between 2013 and 2018, 2018 will be selected for the rest.
#' `input_clc_year` can also be an available year from which to process all data
#' points.
#' @param points_crs Identifier of the coordinate reference system (CRS)
#' associated with the coordinates of the input points. Default is EPSG:4326.
#'
#' @returns An [extract_compositions()] output. Data frame containing the
#' relative compositions of the buffers centered around the input points. Each
#' land cover is associated with columns whose values range from 0 (category
#' absent from the buffer zone) to 1 (the buffer is entirely composed of this
#' category).
#' @export
#'
#' @examples
#' # CORINE data sets must be loaded first
#' clc_path <- system.file(
#'   "extdata", package = "corine.land.cover.landuse.extraction"
#' )
#' set_corine_land_cover_path(clc_path)
#' buffer_radius_m <- 1
#' # Extract with auto selection
#' get_full_compositions(
#'   example_points_df, buffer_radius_m, input_clc_year = "auto"
#' )
#' # Extract for a given year
#' get_full_compositions(
#'   example_points_df, buffer_radius_m, input_clc_year = 2012
#' )
get_full_compositions <- function(points_df, buffer_radius_m,
                                  input_clc_year = "auto",
                                  points_crs = 4326) {
  if (input_clc_year == "auto") {
    points_df$clc_year <- sapply(points_df$year, get_clc_year)
  } else {
    check_clc_year(input_clc_year)
    points_df$clc_year <- input_clc_year
  }
  points_df <- points_df %>%
    dplyr::select(point_id, longitude, latitude, clc_year)
  year_list <- unique(points_df$clc_year)
  compositions_by_year <- lapply(
    year_list, get_year_compositions,
    points_df = points_df, buffer_radius_m = buffer_radius_m,
    points_crs = points_crs
  )
  full_compositions_df <- compositions_by_year %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(
      dplyr::across(dplyr::where(is.numeric), ~ replace(., is.na(.), 0))) %>%
    dplyr::select(
      -tidyselect::matches("\\d+"),
      sort(names(.)[tidyselect::matches("\\d+")]))
  return(full_compositions_df)
}

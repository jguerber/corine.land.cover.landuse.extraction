#' Initialize the dataset path
#'
#' `set_corine_land_cover_path` allows the package to access the CORINE Land
#' Cover datasets.
#'
#' @param path String. Path to the folder containing the subfolders. Each
#' subfolder must contain the CORINE Land Cover dataset in geopackage or
#' shapefile format. The subfolder names must the years of the datasets.
#'
#' @export
#'
#' @examples
#' clc_path <- system.file(
#'   "extdata", package = "corine.land.cover.landuse.extraction"
#' )
#' set_corine_land_cover_path(clc_path)
set_corine_land_cover_path <- function(path) {
  options(clc_path = normalizePath(path))
  year_dirs <- list.dirs(path, recursive = FALSE, full.names = FALSE)
  options(available_years = as.numeric(year_dirs))
}

#' Get the dataset format.
#'
#' `get_data_format` gives the file format (geopackage of shapefile) of the
#' CORINE Land Cover dataset.
#'
#' @param data_folder String. Path of the CORINE Land Cover dataset subfolder.
#'
#' @returns String: 'shapefile' or 'geopackage'.
#' @keywords internal
#'
#' @examples
#' folder_2012 <- system.file(
#'   "extdata", "2012",
#'   package = "corine.land.cover.landuse.extraction"
#' )
#' get_data_format(folder_2012)
#'
#' folder_2018 <- system.file(
#'   "extdata", "2018",
#'   package = "corine.land.cover.landuse.extraction"
#' )
#' get_data_format(folder_2018)
get_data_format <- function(data_folder) {
  gpkg_files <- list.files(data_folder, recursive = TRUE, pattern = ".*\\.gpkg")
  if (length(gpkg_files) == 0) {
    return("shapefile")
  } else {
    return("geopackage")
  }
}

#' Open a shapefile dataset
#'
#' `read_clc_map_shapefile` loads a shapefile dataset.
#'
#' @param data_folder String. Path of the CORINE Land Cover dataset subfolder.
#'
#' @returns Sf object.
#' @export
#'
#' @examples
#' folder_2012 <- system.file(
#'   "extdata", "2012",
#'   package = "corine.land.cover.landuse.extraction"
#' )
#' read_clc_map_shapefile(folder_2012)
read_clc_map_shapefile <- function(data_folder) {
  shp_file <- list.files(
    path = data_folder, full.names = TRUE,
    recursive = TRUE, pattern = "CLC\\d{2}_.*\\.shp"
  )
  map <- sf::st_read(shp_file, agr = "constant", quiet = TRUE)
  return(map)
}

#' Open a geopackage dataset
#'
#' `read_clc_map_gpkg` loads a geopackage dataset.
#'
#' @param data_folder String. Path of the CORINE Land Cover dataset subfolder.
#'
#' @returns Sf object.
#' @export
#'
#' @examples
#' folder_2018 <- system.file(
#'   "extdata", "2018",
#'   package = "corine.land.cover.landuse.extraction"
#' )
#' read_clc_map_shapefile(folder_2018)
read_clc_map_gpkg <- function(data_folder) {
  gpkg_file <- list.files(
    path = data_folder, full.names = TRUE,
    recursive = TRUE, pattern = ".*\\.gpkg"
  )
  map <- sf::st_read(gpkg_file, agr = "constant", quiet = TRUE)
  return(map)
}

#' Open a CORINE Land Cover dataset.
#'
#' `read_clc_map` loads a CORINE Land Cover dataset after having identified its
#' data type format.
#'
#' @param year String or integer. Year giving the subfolder to open.
#' @param clc_path String. Path of the folder containing all the CORINE Land
#' Cover dataset subfolders.
#'
#' @returns Sf object.
#' @keywords internal
#'
#' @examples
#' clc_path <- system.file(
#'   "extdata", package = "corine.land.cover.landuse.extraction"
#' )
#' set_corine_land_cover_path(clc_path)
#' read_clc_map(2012)
#' read_clc_map(2018)
read_clc_map <- function(year, clc_path = getOption("clc_path")) {
  year_folder <- file.path(clc_path, year)
  if (get_data_format(year_folder) == "shapefile") {
    return(read_clc_map_shapefile(year_folder))
  } else {
    return(read_clc_map_gpkg(year_folder))
  }
}

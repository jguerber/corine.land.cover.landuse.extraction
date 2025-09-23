# Installation
```
install.packages("devtools") # si nécessaire
devtools::install_github("jean-cohen/corine.land.cover.landuse.extraction")
library(corine.land.cover.landuse.extraction)
```
# Données
Pour le sol français métropolitain, les données peuvent être téléchargées depuis les liens suivants :
- 1990 : https://www.donnees.statistiques.developpement-durable.gouv.fr/donneesCLC/CLC/millesime/CLC90_FR_RGF_SHP.zip
- 2000 : https://www.donnees.statistiques.developpement-durable.gouv.fr/donneesCLC/CLC/millesime/CLC00_FR_RGF_SHP.zip
- 2006 : https://www.donnees.statistiques.developpement-durable.gouv.fr/donneesCLC/CLC/millesime/CLC06_FR_RGF_SHP.zip
- 2012 : https://www.donnees.statistiques.developpement-durable.gouv.fr/donneesCLC/CLC/millesime/CLC12_FR_RGF_SHP.zip
- 2018 : https://www.data.gouv.fr/api/1/datasets/r/196a6f96-f558-4dec-9bdc-1359d32dc5d1

Pour que le package soit entièrement opérationnel, tous les millésimes d'intérêt doivent être téléchargés et décompressés dans des sous dossiers dont les noms correspondent aux années.
```
corine_land_cover_data/
  2000/
  2006/
  2012/
  2018/
```
Les données peuvent être lues si elles sont au format shapefile (.shp) ou geopackage (.gpkg).

# Utilisation
## Points dont la composition des alentours est à extraire
Les points à extraire doivent sous la forme de data frame contenant les colonnes suivantes :
- `point_id` : clé primaire de la table
- `longitude` : longitude du point
- `latitude` : latitude du point
- `year` : année correspondant au point (optionnel, nécessaire pour le calcul automatique du millésime à utiliser)

Par défaut, les coordonnées sont considérées dans le référentiel WGS 84/EPSG:4326, tout autre référentiel peut être précisé avec l'argument `points_crs`.

## Extraction selon l'année de l'échantillonnage des points
Ce paquet R est conçu pour adapter le millésime d'extraction en fonction d'une variable année.
Il faut d'abord donné le chemin d'accès au dossier contenant toute les bases de données avec la fonction `set_corine_land_cover_path`.
La fonction `get_full_compositions` permet d'extraire les compositions d'un buffer de rayon donné autour de chacun des points.

```
set_corine_land_cover_path(CORINE_LAND_COVER_PATH)
buffer_radius_m <- 250
compositions_df <- get_full_compositions(points_df, buffer_radius_m, input_clc_year = "auto")
```
Il est possible de forcer les données à utiliser en précisant l'année du millésime dans l'argument `input_clc_year`.

## Extraction manuelle
L'extraction peut être faite manuellement en chargeant les données CORINE Land Cover avec les fonctions `read_clc_map_shapefile` ou `read_clc_map_gpkg`, puis en utilsant `extract_compositions`.
Les cas d'utilisation de ces fonctions sont disponibles dans la documentation.

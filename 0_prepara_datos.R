##################################################
## author  =  Alexander Quevedo 
## copyright =  Copyright 2021, Gobierno de Jalisco
## credits = Alexander Quevedo
##  license = "MIT"
## version = 0.0.1
## maintainer = Alexander Quevedo
## email = alexander.quevedo@jalisco.gob.mx
## status = Development
##################################################

library(rgee)
library(tidyverse)
library(sf)
library(raster)

# Lines 19 and 20 refer to the bin folder inside an anaconda environment
# name gee where the geemap package has been installed
# EARTHENGINE_PYTHON and RETICULATE_PYTHON are two environmental variables
# You can create the anaconda environment with conda create --name gee python=3.8 geemap -c conda-forge
# This will create an anaconda environment named gee

Sys.setenv(EARTHENGINE_PYTHON='/home/rnanclares/anaconda3/envs/gee/bin')
Sys.setenv(RETICULATE_PYTHON='/home/rnanclares/anaconda3/envs/gee/bin')

# After installation you have to 
# ee_install()
# ee_clean_pyenv()
ee_check()
## It is necessary just once


# Initialize Earth Engine!
ee_Initialize()

ee_roi <- st_read("data/limite_combinado_lulc.gpkg") %>%
  st_geometry() %>%
  sf_as_ee()

collection_fires <- ee$ImageCollection("ESA/CCI/FireCCI/5_1")$
                       select("BurnDate")

ic_drive_files_1 <- ee_imagecollection_to_local(
  ic = collection_fires,
  region = ee_roi,
  scale = 250,
  dsn = file.path("data/incendios_historicos", "FireCCI_")
)


##################################################
## authors  =  Alexander Quevedo, Raul Nanclares 
## copyright =  Copyright 2021, Gobierno de Jalisco
## credits = Alexander Quevedo, Raul Nanclares
##  license = "MIT"
## version = 0.0.1
## maintainer = Raul Nanclares da Veiga
## email = raul.nanclares@jalisco.gob.mx
## status = Development
##################################################

library(rgee)
library(tidyverse)
library(sf)
library(raster)

# Here we have two options:
# 1) CREATE ANACONDA ENVIRONMENT 
# Lines 19 and 20 refer to the bin folder inside an anaconda environment
# named gee where the geemap package has been installed
# You can create the anaconda environment with 
## conda create --name gee python=3.8 geemap earthengine-api numpy  -c conda-forge
# This will create an anaconda environment named gee

# EARTHENGINE_PYTHON and RETICULATE_PYTHON are two environmental variables
Sys.setenv(EARTHENGINE_PYTHON='/home/rnanclares/anaconda3/envs/gee/bin')
Sys.setenv(RETICULATE_PYTHON='/home/rnanclares/anaconda3/envs/gee/bin')

# 2) Use the R gee package to create a Python env (using pyenv)
# After installation you have to 
# ee_install()
# ee_clean_pyenv() ### Remove rgee system variables from .Renviron
# Use in case you want to start the installation from scratch

ee_check() # This command checks if the environment fills all the requirements, you can use is in 1) and 2)
## It is necessary just once


# Initialize Earth Engine! (You need to register first to get your Google Earth Engine Account)
ee_Initialize()

# ROI: Region of Interest
ee_roi <- st_read("limits/limite_combinado_lulc.gpkg") %>%
  st_geometry() %>%
  sf_as_ee() # This line transforms the limit to something understandable by Google Earth Engine

# Define the collection we will be using to get the burnt/burned area
collection_fires <- ee$ImageCollection("ESA/CCI/FireCCI/5_1")$
                       select("BurnDate")

ic_drive_files_1 <- ee_imagecollection_to_local(
  ic = collection_fires,
  region = ee_roi,
  scale = 250,
  dsn = file.path("data/incendios_historicos", "FireCCI_")
)


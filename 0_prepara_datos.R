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

Sys.setenv(EARTHENGINE_PYTHON='/home/alequech/anaconda3/envs/gee/bin')
Sys.setenv(RETICULATE_PYTHON='/home/alequech/anaconda3/envs/gee/bin')

#setwd("~/Documents/iA_LULC")
#/home/alequech/.virtualenvs/rgee/bin/python 
# ee_install()
# ee_clean_pyenv()
ee_check()
## It is necessary just once


# Initialize Earth Engine!
ee_Initialize()

ee_roi <- st_read("data/limite_frankenstein_utm.shp") %>%
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


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
library(lubridate)
library(raster)
library(stars)
library(terra)
library(rgee)
library(sf)
library(tidyverse)
library(magrittr)
source("funciones.R")

Sys.setenv(EARTHENGINE_PYTHON='/home/alequech/anaconda3/envs/gee/bin')
Sys.setenv(RETICULATE_PYTHON='/home/alequech/anaconda3/envs/gee/bin')

#setwd("~/Documents/iA_LULC")
#/home/alequech/.virtualenvs/rgee/bin/python 
# ee_install()
# ee_clean_pyenv()
ee_check()
## It is necessary just once


# Initialize Earth Engine!
ee_Initialize("alexander.jalisco")


periodo <- seq(as.Date("2010/02/01"), as.Date("2019/12/01"), "month")  


###  Terreno 

DEM <- ee$Image("USGS/SRTMGL1_003")
Slope_T <- ee$Terrain$slope(DEM)


n_list <- list()
for(i in 1:length(periodo)){
  
  nlayer <-  periodo[i] %>% as.character()
  
  roi <-
    st_read("muestra/poligonos_muestra.gpkg", layer = nlayer) %>%  sf_as_ee()
  
  fecha_init_m <- periodo[i] %m-% months(1) 
  
  fecha_fin_m <- (periodo[i] - 1)  %>% as.character()
  
  fecha_init_m %<>% as.character()
  
  print(paste0("mes incendio: ",nlayer))
  print(paste0("muestreo: ", fecha_init_m," ", fecha_fin_m))
  
  
  ### NDVI modis NDVI, Evapotranspiracion y tempratura 
  
  modis_ndvi <- ee$ImageCollection("MODIS/006/MOD13Q1")
  ### NDVI
  ndvi_composite <- modis_ndvi$
    filter(ee$Filter$date(fecha_init_m,fecha_fin_m))$
    map(mod13q1_clean)$
    mean()
  
  ##Evapotranspiracion 
  modis_evapo <- ee$ImageCollection("MODIS/006/MOD16A2")$
    select(c("PET","ET"))$
    filter(ee$Filter$date(fecha_init_m,fecha_fin_m))$
    mean()
  
  ## Temperatura  
  modis_temp <- ee$ImageCollection("MODIS/006/MOD11A1")$
    select("LST_Day_1km")$
    filter(ee$Filter$date(fecha_init_m,fecha_fin_m))$
    mean()
  
  
  ### SMOS
  smos <- ee$ImageCollection("NASA_USDA/HSL/soil_moisture")$
    filter(ee$Filter$date(fecha_init_m,fecha_fin_m))$
    select(c("ssm","susm"))$
    mean()  
  
  
  ###  Precipitacion
  precipitacion <- ee$ImageCollection("UCSB-CHG/CHIRPS/PENTAD")$
    filter(ee$Filter$date(fecha_init_m,fecha_fin_m))$
    sum()
  

  #####  stack GEE 
  
  stack_gee <- ndvi_composite$addBands(modis_evapo)
  stack_gee <- stack_gee$addBands(modis_temp)
  stack_gee <- stack_gee$addBands(smos)
  stack_gee <- stack_gee$addBands(precipitacion)
  stack_gee <- stack_gee$addBands(DEM)
  stack_gee <- stack_gee$addBands(Slope_T)
  
  
  datos <- ee_extract(
    x = stack_gee,
    y = roi,
    scale = 250,
    fun = ee$Reducer$mean(),
    sf = TRUE
  )
  
  rm(stack_gee)
  
  n_list[[nlayer]]  <- datos
  
}

sapply(names(n_list),
       function (x)
         st_write(n_list[[x]], "muestra/poligonos_muestra_datos.gpkg", x, append = TRUE))



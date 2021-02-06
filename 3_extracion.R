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
library(rgee)
library(sf)
library(tidyverse)
library(magrittr)

Sys.setenv(EARTHENGINE_PYTHON='/home/alequech/anaconda3/envs/gee/bin')
Sys.setenv(RETICULATE_PYTHON='/home/alequech/anaconda3/envs/gee/bin')


muestras <- "muestra/poligonos_muestra.gpkg"
nlayers <- st_layers(muestras)[10]

roi <- st_read(muestras, layer ="2010-02-01") %>%  sf_as_ee()

as.Date(nlayers$name)  %m+% months(1) 
#setwd("~/Documents/iA_LULC")
#/home/alequech/.virtualenvs/rgee/bin/python 
# ee_install()
# ee_clean_pyenv()
ee_check()
## It is necessary just once


# Initialize Earth Engine!
##ee_Initialize("alexander.jalisco")

fecha_ini <- as.Date("2010-01-01")

fecha_init_m <- fecha_ini # %>% as.character()

fecha_fin_m <- (fecha_init_m %m+% months(1) - 1)  %>% as.character()

fecha_init_m %<>% as.character()

### NDVI modis NDVI, Evapotranspiracion y tempratura 

modis_ndvi <- ee$ImageCollection("MODIS/006/MOD13Q1")
### NDVI
ndvi_composite <- modis_ndvi$
  filter(ee$Filter$date(fecha_init_m,fecha_fin_m))$
  filter(ee$Filter$calendarRange(1, field = "month"))$
  map(mod1q1_clean)$
  mean()

##Evapotranspiracion 
modis_evapo <- ee$ImageCollection("MODIS/NTSG/MOD16A2/105")$
  select(c("PET","ET"))$
  filter(ee$Filter$date(fecha_init_m,fecha_fin_m))$
  filter(ee$Filter$calendarRange(1, field = "month"))$
  mean()

## Temperatura  
modis_temp <- ee$ImageCollection("MODIS/006/MOD11A1")$
  select("LST_Day_1km")$
  filter(ee$Filter$date(fecha_init_m,fecha_fin_m))$
  filter(ee$Filter$calendarRange(1, field = "month"))$
  mean()

### SMOS
smos <- ee$ImageCollection("NASA_USDA/HSL/soil_moisture")$
        filter(ee$Filter$date('2010-01-01', '2019-12-31'))$
        select(c("ssm","susm"))$
        mean()  


## Precipitacion


ee_utils_create_json

datos <- ee_utils_create_json(list(ndvi_composite,smos))
datos <- datos$addBands(smos)


ee_nc_rain <- ee_extract(
  x = smos,
  y = roi,
  scale = 250,
  fun = ee$Reducer$mean(),
  sf = TRUE
)


# library(remotes)
# install_github("r-spatial/rgee")

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
  dsn = file.path("data/", "FireCCI_")
)



img_02_result <- collection_fires %>% ee$utils$future$value()

fires_img <- ee$Image("ESA/CCI/FireCCI/5_1/2019_05_01")

ee_print(collection_fires)

img_02 <- ee_as_raster(
  image = fires_img,
  region = ee_roi,
  via = "drive"
)

a1 <-  terra::rast(img_02)

a1[a1 == 0] <- NA




collection <- ee$ImageCollection("COPERNICUS/S2_SR")$
  filterDate("2019-01-01", "2020-12-31")$
  filterBounds(ee_roi)$
  select("B[4-8]")





y = ee$Geometry$Point(20.667, -103.509)

#count <- collection$size()$getInfo()
#sceneList <- collection$aggregate_array("system:index")$getInfo()

#scene <- ee$Image(collection$get(10))

ee_TS<- ee_extract(
  x = collection$toBands()$divide(10000),
  y = ee_roi ,
  scale = 30,
  fun = ee$Reducer$mean(),
  sf = FALSE
)

pivot_longer(ee_TS, cols = everything(), values_to = "Reflectancia") %>%
  mutate(fecha = str_sub(name,2, 9) %>% anytime::anydate(), banda = str_sub(name,-2, -1)) %>%
  ggplot(.,aes(x=fecha, y = Reflectancia, colour = banda, group = banda)) + 
  geom_line()+
  scale_x_date(date_breaks = 'months', date_labels = '%b-%Y')

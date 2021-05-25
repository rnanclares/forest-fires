library(raster)
library(tidyverse)
library(caret)


mes_eval <- 5 # mes para el caul se calculara el riesgo

model_rf <- readRDS("modelo_rf.rds")

mes_datos <- mes_eval - 1
meses <-c("enero","febrero","marzo","abril", "mayo", "junio", "julio", "agosto")
mes <- meses[mes_datos]
elevation <- raster(paste0("data/inferencia/",mes,"/dem.tif")) 
#slope <-  raster("data/inferencia/slope.tif") 
evapotranspiracion <- stack(paste0("data/inferencia/",mes,"/evapotranspiracion.tif"))
temperature <- raster(paste0("data/inferencia/",mes,"/temperatura.tif"))
precipitacion <- raster(paste0("data/inferencia/",mes,"/precipitacion.tif"))
ndvi <- raster(paste0("data/inferencia/",mes,"/NDVI.tif"))
humedad <- stack(paste0("data/inferencia/",mes,"/smos.tif"))
dist_km_prev <- raster(paste0("data/distancia_incendios/","/distancia_2019.tif"))%>% resample(ndvi)

stack_p <- stack(elevation, evapotranspiracion, temperature, precipitacion, ndvi, humedad, dist_km_prev)

mascara_forestal <- raster("data/mascara_forestal_250.tif")
mascara_forestal[mascara_forestal!=1] <- NA
mascara_forestal <- resample(mascara_forestal,stack_p)

#names(stack_p) <- c('elevation','slope','PET' ,'ET' ,'Day_1km','precipitation','NDVI' , 'ssm','susm', 'dist_km_prev')

names(stack_p) <- c('elevation','PET' ,'ET' ,'Day_1km','precipitation','NDVI' , 'ssm','susm', 'dist_km_prev')

stack_p <-  stack_p %>% crop(mascara_forestal) %>% raster::mask(mascara_forestal)

riesgo_incendios_rf <- raster::predict(stack_p,model_rf, progress = "text",  type='prob', index=1:2)

writeRaster(riesgo_incendios_rf[[2]], paste0("riesgo_",meses[mes_eval],"_2021.tif"),overwrite=TRUE)

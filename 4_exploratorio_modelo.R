##################################################
## author  =  Alexander Quevedo 
## copyright =  Copyright 2021, Gobierno de Jalisco
## credits = Alexander Quevedo
## license = "MIT"
## version = 0.0.1
## maintainer = Alexander Quevedo
## email = alexander.quevedo@jalisco.gob.mx
## status = Development
##################################################
library(sf)
library(raster)
library(rgee)
library(ggplot2)
library(GGally)
library(Hmisc)
library(caret)
library(CAST)
library(tidyverse)
library(lubridate)
library(magrittr)
library(doParallel)
library(xgboost)
library(fasterize)
library(viridis)
library(gridExtra)

#Sys.setenv(EARTHENGINE_PYTHON='/home/alequech/anaconda3/envs/gee/bin')
#Sys.setenv(RETICULATE_PYTHON='/home/alequech/anaconda3/envs/gee/bin')
#ee_Initialize("alexander.jalisco",drive = TRUE)

datos <- st_read("muestra/poligonos_muestra_datos.gpkg", layer = "poligonos_muestra_datos") %>% 
        st_drop_geometry()

datos  <- datos %>% select(-slope)

limite <- st_read("data/limite_combinado_lulc.gpkg")

datos$incendio <- as.factor(datos$incendio)


my_colors <- c("0" = "#00b159","1" = "#d11141")

ggpairs(datos, aes(colour = incendio),
        columns = 3:10,
        upper = list(continuous = wrap("points", alpha = 0.3)),
        diag = list(discrete="barDiag", continuous = wrap("densityDiag", alpha=0.5 )),
        lower = list(continuous = wrap("smooth", alpha = 0.3, size=0.1)),
        legend = c(1,1))+
        scale_color_manual(values = my_colors)+
        scale_fill_manual(values = my_colors)


predictors <- names(datos)[3:10]

datos.c <- datos %>% drop_na()  

down_sample <- downSample(x = datos.c[, -ncol(datos.c)],
                         y = datos.c$incendio)


trainIndex <- createDataPartition(datos.c$incendio, p = .8, 
                                  list = FALSE, 
                                  times = 1)


incendios_Train <- datos.c[ trainIndex,]
incendios_Test  <- datos.c[-trainIndex,]

#### Random Forest 
cl <- makePSOCKcluster(4)
registerDoParallel(cl)
model_rf <- train(incendios_Train[,predictors],
                  incendios_Train$incendio,
               method="rf",
               ntree=300,
               importance=TRUE,
               trControl = trainControl(method="cv"))
stopCluster(cl)

plot(varImp(model_rf,scale = F),col="black")
plot(model_rf)
plot(model_rf$finalModel)


saveRDS(model_rf, "./modelo_rf.rds")


fires_pro <- predict(model_rf, incendios_Test, type="prob")
fires_cla <- predict(model_rf, incendios_Test)

incendios_Test$prob_incendio <- fires_pro$'1'
incendios_Test$predict_incendio <- fires_cla  

confusionMatrix(reference = incendios_Test$incendio, data =  incendios_Test$predict_incendio)

#### Logic 
cl <- makePSOCKcluster(3)
registerDoParallel(cl)
logit.incendios <- train(x= incendios_Train[,predictors] , 
                         y= incendios_Train$incendio, 
                  method = 'glmnet',
                  family = 'binomial' )
stopCluster(cl)

# incendios_Train2 <- down_sample[ trainIndex,]
# incendios_Test2  <- down_sample[-trainIndex,]
# 
# incendios_Train2$precipitation <- NULL 
# incendios_Test2$precipitation <- NULL 
# 
# predictors2 <- names(incendios_Train2)[3:11]
# 
# cl <- makePSOCKcluster(4)
# registerDoParallel(cl)
# model_rf2 <- train(incendios_Train2[,predictors2],
#                    incendios_Train2$incendio,
#                   method="rf",
#                   ntree=1000,
#                   importance=TRUE,
#                   trControl = trainControl(method="cv"))
# stopCluster(cl)

#plot(model_rf2$finalModel)
#plot(model_rf2)
#plot(varImp(model_rf2,scale = F),col="black")
mes_eval <- 5
mes_datos <- mes_eval - 1
meses <-c("enero","febrero","marzo","abril", "mayo", "junio", "julio")
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



riesgo_incendios_lg <- raster::predict(stack_p,logit.incendios, progress = "text",  type='prob', index=1:2)


incendios_2020 <-
        st_read("data/incendios_2020/MERGE_JAL_2020_630.gpkg") %>%
        st_make_valid() %>%
        filter(mes == mes_eval) %>% 
        fasterize(mascara_forestal)

incendios_2020[is.na(incendios_2020) & mascara_forestal == 1] <- 0 

#incendios_2020[incendios_2020 == 0] <- 2 

#riesgo_incendios <- round(riesgo_incendios * 1000,0)

library(TOC)
#mascara_forestal0 <-  mascara_forestal 
#mascara_forestal0[is.na(mascara_forestal)] <- 0



df_eval <-stack(riesgo_incendios_rf,incendios_2020, na.rm= TRUE) %>% 
        as.data.frame(na.rm = TRUE)

names(df_eval) <- c("probNO","probSI","incendios_2020")
write_csv(df_eval, "resultados/df_eval.csv")

Tocd <- TOC(df_eval$probSI, df_eval$incendios_2020,nthres = 20, progress=TRUE)
rocd <- ROC(df_eval$probSI, df_eval$incendios_2020,nthres = 20, progress=TRUE)

plot(Tocd)
plot(rocd)

writeRaster()


# library(CAST)
# AOA <- aoa(stack_p, model_rf)
# attributes(AOA)$aoa_stats
# 
# grid.arrange(
#         spplot(
#                 incendios_2020,
#                 main = "Incendios Junio 2020",
#                 col.regions = c("grey", "red")
#         ),
#         spplot(AOA$DI, col.regions = viridis(100), main = "DI"),
#         spplot(
#                 riesgo_incendios,
#                 col.regions = viridis(100),
#                 main = "Riesgo con AOA"
#         ) + spplot(AOA$AOA, col.regions = c("grey", "transparent")),
#         ncol = 3
# )
# 
# 
# min(incendios_2020)
# #http://www.sthda.com/english/articles/35-statistical-machine-learning-essentials/139-gradient-boosting-essentials-in-r-using-xgboost/
# cl <- makePSOCKcluster(2)
# registerDoParallel(cl)
# model_xgbT <- train(
#         incendios_Train[, predictors],
#         incendios_Train$incendio,
#         method = "xgbTree",
#         trControl = trainControl("cv", number = 10)
# )
# stopCluster(cl)

varImp(model_xgbT)
plot(varImp(model_xgbT,scale = F),col="black")
plot(model_xgbT)

riesgo  <- raster::predict(stack_p,model_xgbT, progress = "text",  type='prob', index=1:2)
plot(riesgo_incendios_rf[[2]])

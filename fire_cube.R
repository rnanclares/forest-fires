#library(terra)
library(stars)
library(starsExtra)
library(zoo)
library(lubridate)
library(dplyr)

raster_incendios <-
  list.files(pattern = "FireCCI_.*.tif$",
             include.dirs = TRUE,
             recursive = TRUE)[1:25]

rasterio = list(
  nXOff = 6,
  nYOff = 6,
  nXSize = 100,
  nYSize = 100,
  bands = c(1, 3, 4)
)

z <- seq(as.Date("2001/01/01"), as.Date("2019/12/01"), "month") 
z <- z[1:25]

s_incendios <-
  read_stars(raster_incendios, along = list(time = z), proxy = FALSE)

forest <- read_stars("data/mascara_forestal_250.tif")

names(forest) <- "mask_forest"

names(s_incendios) <- "FireCCI"

s_incendios$FireCCI[is.na(forest$mask_forest)]  <- NA
#s_incendios$FireCCI[s_incendios$FireCCI == 0]  <- NA
s_incendios$FireCCI[s_incendios$FireCCI > 0]  <- 1


by_t = "1 years"

year_fires <- aggregate(s_incendios, by = by_t, FUN = sum)
year_fires$FireCCI[year_fires$FireCCI == 0] <- NA

#plot(year_fires)
#drop(year_fires, drop = 1)

filter(s_incendios, time ==  as.Date("2001-06-01")) -> a
mapview(a) | mapview(forest)

filter(s_incendios, time ==  as.Date("2001-01-01")) -> a

ext = st_as_sfc(st_bbox(r))

date_y <- st_get_dimension_values(year_fires, "time")[1:2]

vector_fy <- list()

for (i in 1:length(date_y)) {
  print(date_y[i])
  nlist  <- paste0("anio_", year(date_y[i]))
  
  vector_fy[[nlist]] <- 
    year_fires %>%
    filter(time == date_y[i]) %>%
    st_as_sf() %>%
    st_union(by_feature = FALSE) %>%
    st_cast("POLYGON") %>%
    st_as_sf() %>%
    mutate(area = st_area(.))
}

t_muestras <- lapply(vector_fy, function(x)
              st_drop_geometry(x) %>%  
              summarise(., m_area = mean(area), total = sum(area), muestra_mensual = round((sum(area)/12) * 1/mean(area))))


ubuernet <- forest


ubuernet[]


# Create points
pnt = st_sample(st_buffer(ext, 10), 1000)
pnt = st_as_sf(pnt)


###st_as_sf(r, merge = TRUE)
#media del area quedama - > quemada +- standa desvition
#sample poligonos sobre el area

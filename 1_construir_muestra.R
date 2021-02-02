#library(terra)
library(stars)
library(starsExtra)
library(zoo)
library(lubridate)
library(dplyr)
library(purrr)


raster_incendios <-
  list.files(pattern = "FireCCI_.*.tif$",
             include.dirs = TRUE,
             recursive = TRUE)#[1:24]

rasterio = list(
  nXOff = 6,
  nYOff = 6,
  nXSize = 100,
  nYSize = 100,
  bands = c(1, 3, 4)
)

z <- seq(as.Date("2001/01/01"), as.Date("2019/12/01"), "month")
#z <- z[1:24]

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

date_y <- st_get_dimension_values(year_fires, "time")

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
    summarise(
      .,
      m_area = mean(area),
      total = sum(area),
      muestra_mensual = round((sum(area) / 12) * 1 / mean(area)),
      radio = sqrt(mean(area) / pi)
    ))

t_muestras <-
  do.call(rbind, t_muestras) %>% tibble::rownames_to_column()

n_list <- list()

for (i in 1:length(date_y)) {
  print(date_y[i])
  area_fire <-  filter(year_fires, time == date_y[i])
  unburned <- forest
  unburned[area_fire > 0] <- NA
  forest_v <- st_as_sf(unburned)
  n <- t_muestras$muestra_mensual[i]
  radio <- t_muestras[i, ]$radio
  year_f <- year(date_y[i])
  for (j  in 1:12) {
    print(j)
    
    sample_point <-
      st_sample(forest_v, size = as.vector(n)) %>%
      st_buffer(dist = radio) %>% 
      st_as_sf() %>%
      mutate(incendio = 0)
    
    id_list <-
      paste0(year_f, "/", j, "/01") %>% as.Date() %>% as.character()
    n_list[[id_list]] <- sample_point
  }
  
}


s_incendios$FireCCI[s_incendios$FireCCI == 0]  <- NA

for (fm in 1:length(n_list)) {
  fire_month <- s_incendios %>% slice(time, fm)
  fire_dummy <-
    map(fire_month, function(x)
      min(x, na.rm = TRUE))[[1]]
  if (fire_dummy  != 1) {
    next
  } else{
    fire_month %>%
      st_as_sf() %>%
      st_union(by_feature = FALSE) %>%
      st_cast("POLYGON") %>%
      st_as_sf() %>% 
      mutate(incendio = 1) -> b 
      n_list[[names(n_list)[fm]]] <- rbind(b, n_list[[names(n_list)[fm]]]) 
  }
}

dir.create("muestra")
sapply(names(n_list), 
       function (x) st_write(n_list[[x]], "muestra/poligonos_muestra.gpkg", x, append = TRUE))


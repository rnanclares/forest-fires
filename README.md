# Wildfire Risk/Danger model 

Build a model to estimate the probability of wildfires occuring, using remote sensed data (data from satellite sensors).

### Training data

Historical wildfire record - (FireCCI51: MODIS Fire_cci Burned Area Pixel product, version 5.1)

### Environmental Variables 
#### Previous month
* CHIRPS Daily: Climate Hazards Group InfraRed Precipitation With Station Data (Version 2.0 Final)  - [via Google Earth Engine](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY)
  * Reduced to monthly sum per pixel (Monthly accumulated precipitation).
  * Recommendation: Explore alternatives, the product usually takes 20 days to process but lately is taking more than a month, so it will be late to produce a risk map with the precipitation from the previous month.
* Potencial Evapotranspiration - [MOD16A2 Product](https://developers.google.com/earth-engine/datasets/catalog/MODIS_NTSG_MOD16A2_105)
  * Monthly average per pixel 
  * Spatial resolution (Ground sampling distance): 1 km
* Evapotranspiration - [MOD16A2 Product](https://developers.google.com/earth-engine/datasets/catalog/MODIS_NTSG_MOD16A2_105)
  * Monthly
  * Spatial resolution (Ground sampling distance): 1 km
* Temperature MODIS - [MOD11A1 Product](https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MOD11A1)
  * Monthly average
  * Spatial resolution (Ground sampling distance): 1 km
* NDVI MODIS - [MOD13Q1 Product (NDVI Anomalies calculated from this product can be used as a proxy to drought)](https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MOD13Q1).
  * Monthly average
  * Spatial resolution (Ground sampling distance): 250 m
* Soil Moisture - [NASA USDA HSL](https://developers.google.com/earth-engine/datasets/catalog/NASA_USDA_HSL_soil_moisture)
  * Deprecated - replaced by Enhanced SMAP 
  * Monthly average
  * Spatial resolution (Ground sampling distance) 0.25 º ~ 25 km (Enhanced SMAP ~ 10 km)


#### Previous year (constant throughout the year) 

* Distance to previous fires (Km) - calculated from FireCCI51: MODIS Fire_cci Burned Area Pixel Product, Version 5.1 . We used Dinamica Ego to calculate this variable using the following model. In our opinion, it should be replaced by a script to avoid needing to use another software.


## Training data preparation

Data obtained from scripts 0 to 4 can be found here gs://geo-2021/digeo/Incendios/datos_scripts.zip (please download and don't modify the folder structure)

* `0_prepara_datos.R` -  downloads the product [FireCCI51](https://developers.google.com/earth-engine/datasets/catalog/ESA_CCI_FireCCI_5_1) from Google Earth Engine (GEE).

*  `1_construir_muestra.R`  Using the FIRECCI51 product creates a sample of burned and not burned pixels 

*  `2_distancia_incendios_anios_previos.egoml` - calculates distance to previous fires, using [DinamicaEgo](https://csr.ufmg.br/dinamica/dinamica-5/)

*  `3_extracion.R` - extract data from the environmental variables (TODO: Check if it really does)

* `4_exploratorio_modelo.R` - Creates a model using Random Forests

### Inference 

* To do the inference you have to download the explicative variables of the previous month using the Jupyter Notebook - `5_Datos_para_inferencia.ipynb`, it's recommend running using Google Colab. These data is exported to the `incendios_2021` folder in Google Drive, these layers need to be downloaded and copied to the `data/correspondingmonth` folder.    

```python 
### Calculates variables for April, which will we used to the inference for the month of May  
iniDate = '2021-04-01'
endDate = '2021-04-30'
```

* `6_inferencia.R` -  to conduct the inference simply define the month for which the risk estimation will be calculated

```r
mes_eval <- 5 # Month number
```


### Note

In the last month (May 2021) precipitation (CHIRPS) and soil moisture (SMOS) are delayed in its ingestion into GEE so we instead used an average value obtained using GEE.

```js
var geometry = ee.Geometry.Rectangle([-105.70671, 18.91105, -101.45436, 22.75942])
var m = 5  //##
var chirps = ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
  .select('precipitation')
  .filter(ee.Filter.calendarRange(m, m, 'month'))
  .mean()

var smos = ee.ImageCollection('NASA_USDA/HSL/soil_moisture')
.select('ssm', 'susm')
.filter(ee.Filter.calendarRange(m, m, 'month'))
.mean()


Export.image.toDrive({
  image: chirps,
  description: 'precipitacion',
  scale: 250,
  crs: 'EPSG:32613',
  folder: 'incendios_2021' , 
  region: geometry
});


Export.image.toDrive({
  image: smos,
  description: 'smos',
  scale: 250,
  crs: 'EPSG:32613',
  folder: 'incendios_2021' , 
  region: geometry
});
```
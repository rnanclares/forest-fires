# Modelo de riesgo de incendios forestales 

Construir un modelo para estimar la proabilidad de incendios forestales,  usando datos derivados de imágenes de satelite.

## Variables

Incendios históricos - (FireCCI51: MODIS Fire_cci Burned Area Pixel product, version 5.1) 

### Ambientales 
* Temperatura (MODIS)
* Indices de vegetación (MODIS)
* Humedad (SMOS)
* Precipitación


### Antropicas 

* Distancia a incendios previos 

## Preparar datos de entrenamiento y modelo 

Los datos resultantes de los scripts 0 a 4  se encuentra en gs://geo-2021/digeo/Incendios/datos_scripts.zip por favor descargue y conserve la estrutura de carpetas


* `0_prepara_datos.R` -  se encarga de descargar el prodcuto [FireCCI51](https://developers.google.com/earth-engine/datasets/catalog/ESA_CCI_FireCCI_5_1) 
Los datos resultantes de los Scripts 0 a 4 se encuentran en gs://geo-2021/digeo/Incendios/datos_scripts.zip 

* `0_prepara_datos.R` -  se encarga de descargar el prodcuto [FireCCI51](https://developers.google.com/earth-engine/datasets/catalog/ESA_CCI_FireCCI_5_1) 

*  `1_construir_muestra.R`  Usando el producto FIRECCI51 se crea una muestra, de pixeles quemados y no quemados 

*  `2_distancia_incendios_anios_previos.egoml` - calcula la Distancia  a los incendios previos, se ejecuta usando [DinamicaEgo](https://csr.ufmg.br/dinamica/dinamica-5/)

*  `3_extracion.R` -  Se encarga de extraer las muestras de las Variables mencionadas

* `4_exploratorio_modelo.R` - Crea un modelo usando un RF  

### Inferencias 

* Para realizar la inferencia se deben descargar las variables explicativas del mes previo usando el Jupyter Notebook - `5_Datos_para_inferencia.ipynb`, se recomienda correrlo usando google colab. Estos datos se exportaran dentro de la carpeta `incendios_2021`, estas deben de descargarse y copiarse en la carteta `data/mescorrespondiente`.    

```python 
### Calcula las variables para abril, las cuales seran empleadas para el calculo del mes de mayo  
iniDate = '2021-04-01'
endDate = '2021-04-30'
```

* El scrip 6 
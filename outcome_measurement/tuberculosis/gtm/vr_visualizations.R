
# ----------------------------------------------
# Irena Chen 
# 6/20/2018
# Start visualizations of the VR data 
## RUN THIS ON THE CLUSTER SINCE SOME FILES ARE VERY BIG ####
## Also: the raster code is included, but I didn't use that data for creating visualizations so it is commented out 
# ----------------------------------------------
###### Set up R / install packages  ###### 
# ----------------------------------------------

rm(list=ls())
library(raster)
library(rgeos)
library(data.table)
library(ggplot2)
library(maptools)
library(ggrepel)

# ----------------------------------------------
##set set up the directories to read/export files: 
# ----------------------------------------------
j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j') # have to declare the J Drive differently on the cluster 
# raster_dir = paste0(j, '/Project/Evaluation/GF/covariates/gtm/')
muni_dir <- paste0(j, '/WORK/11_geospatial/05_survey shapefile library/Shapefile directory/')
dept_dir <- paste0(j, '/Project/Evaluation/GF/mapping/gtm/')
vr_dir <-  paste0(j, '/Project/Evaluation/GF/outcome_measurement/gtm/prepped_data/')
export_dir <- paste0(j, '/Project/Evaluation/GF/outcome_measurement/gtm/visualizations/')
merge_dir <- paste0(j, "/WORK/11_geospatial/11_vr/vr_data_inputs/muni_merges/GTM/")

## ----------------------------------------------
## read files 
# ----------------------------------------------
# popData = raster(paste0(raster_dir, "/worldpop/Guatemala 100m Population/GTM_pph_v2b_2015.tif"))
vrData <- data.table(fread(paste0(vr_dir, "redistribution_20180716.csv")))
shapeData = shapefile(paste0(muni_dir, "vr_gaul_gtm.shp"))
mergeData <- data.table(fread(paste0(merge_dir, "GTM_muni_merges_2009_2016.csv")))
deptData <- shapefile(paste0(dept_dir, "GTM_adm1.shp"))
# ----------------------------------------------
## set up shape data 
# ----------------------------------------------

##municipality level data: 
coordinates = data.table(fortify(shapeData, region='GAUL_CODE'))
names = data.table(shapeData@data)
coord_and_names = merge(coordinates, names, by.x='id', by.y='GAUL_CODE', allow.cartesian=TRUE)


## load the department level shape data 
names = data.table(deptData@data)
dept_coords <- data.table(fortify(deptData, region='ID_1'))
dept_names <- data.table(deptData@data)
dept_dataset = merge(dept_coords, dept_names, by.x = 'id', by.y='ID_1', allow.cartesian=TRUE)


# ----------------------------------------------
### optional: this sets up a list of dept names and coordinates so you can plot them as labels 
# ----------------------------------------------
gtm_region_centroids <- data.frame(long = coordinates(deptData)[, 1],lat = coordinates(deptData)[, 2])
gtm_region_centroids[, 'ID_1'] <- deptData@data[,'ID_1'] 
gtm_region_centroids[, 'NAME_1'] <-deptData@data[,'NAME_1']
gtm_region_centroids$NAME_1[18] <- "Totonicap�n"
gtm_region_centroids$NAME_1[22] <- "Solol�"
gtm_region_centroids$NAME_1[21] <- "Suchitep�quez"
gtm_region_centroids$NAME_1[3] <- "Sacatep�quez"
gtm_region_centroids$NAME_1[1] <- "Quich�"
gtm_region_centroids$NAME_1[7] <- "Pet�n"


# ----------------------------------------------
## subset TB deaths from the overall VR data 
# ----------------------------------------------
##
tb_death_ids <- c(97,
                  98,
                  99,
                  100,
                  101,
                  102,
                  103,
                  104,
                  105,
                  106,
                  107,
                  108,
                  109,
                  110,
                  111,
                  112,
                  113,
                  114,
                  115,
                  116,
                  117,
                  118,
                  119,
                  120,
                  121,
                  122,
                  123,
                  124,
                  125,
                  126,
                  127,
                  128,
                  129,
                  130,
                  131,
                  132,
                  133,
                  134,
                  135,
                  136,
                  137,
                  138,
                  139,
                  140,
                  141,
                  142,
                  143,
                  144,
                  145,
                  146,
                  147,
                  148,
                  149,
                  150,
                  151,
                  152,
                  153,
                  154,
                  155,
                  156,
                  157,
                  158,
                  159,
                  160,
                  161,
                  162,
                  163,
                  164,
                  165,
                  166,
                  167,
                  168,
                  169,
                  170,
                  171,
                  172,
                  173,
                  174,
                  175,
                  176,
                  177,
                  178,
                  1339,
                  1340,
                  1341,
                  1342,
                  1343,
                  1344,
                  13990,
                  14223,
                  18433,
                  24801,
                  104471,
                  895)


# get the codes from the "cause_ids" csv 
tb_death_codes <- c(297,
                    954,
                    934,
                    946, ##MDR-TB
                    947,
                    948,# HIV/TB
                    949, #HIV/TB - MDR w/out extensive drug resistance
                    950 #HIV/TB - extensively drug-resistant TB
)
vrTb <- vrData[cause_id%in%tb_death_codes]


setnames(vrTb, "deaths", "tb_deaths")


# ----------------------------------------------
## GUATEMALA MAPPING 
# ----------------------------------------------

# right now, we don't care about the other variables (just year and location )
byVars = names(vrTb)[names(vrTb)%in%c('year_id', 'location_id')]
tb_map_dataset= vrTb[, list(tb_deaths=sum(na.omit(tb_deaths))), by=byVars]

## total deaths 
byVars = names(vrData)[names(vrData)%in%c('year_id', 'location_id')]
annualVr= vrData[, list(deaths=sum(na.omit(deaths))), by=byVars]

##merge the two datasets back together 
tb_map_dataset <- merge(tb_map_dataset, annualVr, by=c("location_id", "year_id"))

##calculate TB mortality over total mortality
tb_map_dataset[,tb_rate:=tb_deaths/deaths]
##order by year and location so that the yearly graphs print in order 
tb_map_dataset <-tb_map_dataset[with(tb_map_dataset, order(year_id, location_id)), ]

# ----------------------------------------------
## line graph over time 
# ----------------------------------------------
lineGraph <- tb_map_dataset[with(tb_map_dataset,order(year_id)),]
lineGraph <- lineGraph [, list(tb_deaths=sum(na.omit(tb_deaths))
                               ,deaths=sum(na.omit(deaths))), by=c("year_id")]

lineGraph[,tb_rate:=tb_deaths/deaths]



ggplot(lineGraph, aes(x = year_id, y= tb_deaths)) + 
  geom_line(size=0.75) +
  scale_color_manual(values="#551A8B") +
  scale_y_continuous(limits=c(100, 550)) +
  ggtitle("TB Mortality over Time (National Level)") +
  labs(x = "Year", y = "Number of Deaths (Estimate)") +
  theme_bw()

##plot the TB death rate (TB deaths/total deaths)
ggplot(lineGraph, aes(x = year_id, y= tb_rate)) + 
  geom_line(size=0.75) +
  scale_color_manual(values="#551A8B") +
  ggtitle("TB Mortality over Time (National Level)") +
  labs(x = "Year", y = "TB Deaths/Total Deaths") +
  theme_bw()


# ----------------------------------------------
## connect the VR dataset to the shapefile dataset  
# ----------------------------------------------

mergeData$adm2_gbd_id <- as.integer(mergeData$adm2_gbd_id)
coord_and_names$id <- as.integer(coord_and_names$id)

##merge the dataset w/ muni names and ids to the shape file 
# we need to do this join because there is nothing to join the the VR data to the shape file right now 
merge_coords <- merge(mergeData, coord_and_names, by.x="uid", by.y="id", allow.cartesian=TRUE)
#rename adm2_gbd_id to "location_id" -> we will use this to join the VR data and the shape file  
setnames(merge_coords, "adm2_gbd_id", "location_id")

##### I don't even think we needed this but including it in case we ever want to use population ### 
# aggRaster <- extract(popData, vectorData)
# aggRaster = data.table(do.call('rbind',lapply(aggRaster, sum, na.rm=TRUE)))
# aggRaster[, GAUL_CODE:=vectorData@data[,'GAUL_CODE']]


# ----------------------------------------------
## municipality level graphs by year 
# ----------------------------------------------
gtm_plots <- list()
i=1
for(k in unique(tb_map_dataset$year_id)){
  shapedata <- copy(merge_coords)
  graphData <- tb_map_dataset[year_id==k]
  shapedata$year_id <- k
  graphdata <- merge(graphData, shapedata, by=c("year_id", "location_id"),
                     all.y=TRUE, allow.cartesian=TRUE) ##all.y so that shape data doesn't get dropped
  plot <- (ggplot() + geom_polygon(data=graphdata, aes(x=long, y=lat, group=group, fill=tb_rate)) + 
             coord_equal() + ##so the two shapefiles have the same proportions 
             geom_path() +
             geom_map(map=dept_dataset, data=dept_dataset,
                      aes(map_id=id,group=group), size=1, color="#ece5f9", alpha=0) +  
             geom_polygon(data=dept_dataset, aes(x=long, y=lat, group=group), color="#4e0589", alpha=0) + #colors in the outline of each department
             scale_fill_gradient2(low='#9aeaea', mid='#216fff', high='#0606aa',
                                  na.value = "grey70",space = "Lab", midpoint = 0.03, ## play around with this to get the gradient 
                                  # that you want, depending on data values 
                                  breaks=c(0, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07), limits=c(0, 0.07)) + 
             theme_void() +  
             geom_label_repel(data = gtm_region_centroids, aes(label = NAME_1, x = long, y = lat, group = NAME_1), 
                              size = 3, fontface = 'bold', color = 'black',
                              box.padding = 0.35, point.padding = 0.3,
                              segment.color = 'grey50', nudge_x = 0.2, nudge_y = 0.3) + 
             labs(title=paste0(k, " Guatemala TB Mortality by Municipality"), fill='TB Deaths/Total Deaths \n'))
  gtm_plots[[i]] <- plot
  i=i+1
}

##export graphs as PDF 
pdf(paste0(export_dir, "tb_mortality_by_muni.pdf"), height=6, width=9)
invisible(lapply(gtm_plots, print))
dev.off()












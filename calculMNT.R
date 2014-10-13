###################################################################
#Ce script charge des MNT les joint puis calcul les pentes et l'exposition

#library(XLConnect)
library(rgdal)
library(raster)
library(maptools)
rm(list=ls())

#Dédinition du SCR de référence
Lambert93 <- "+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#On trouve les définitions de ce type sur internet, c'est une définition normée.

#Importation du MNT
MNT1 <- raster("p1.tif")   #mettre le chemin vers les MNTs
MNT2 <- raster("p2.tif")
#ajouter autant de MNT que souhaité (MNT3, MNT4 ...)
MNT <- merge(MNT1, MNT2)                   #fusionne les MNT si besoin ajouter MNT3, MNT4 ... cette étape prend du temps
projection(MNT) <- Lambert93                 #Projette les MNT en lambert 93
plot(MNT1)
#Sauvegarde du MNT
writeRaster(MNT, filename="MNT.asc", overwrite=T)
#Charge MNT
#affichage du MNT
#plot(MNT)

#Calcul de la pente et de l'exposition, ici encore ça prend quelques minutes
#SlopeAspect <- terrain(MNT, opt=c('slope', 'aspect'), unit='degrees')
#Transformation en RasterBrick (Raster multi-couche cf remarque)
#GeoData <- brick(MNT, SlopeAspect)
#names(GeoData) <- c("Altitude", "Pente", "Exposition")

#effacer tout
rm(list=ls())

##Remarque 
#---------
#Dans R un raster peut être mulricouche (comme dans beaucoup de logiciel de SIG comme GRASS). 
#Cela signifie que sur un même pixel vous disposez de plusieurs infos : 
#ici l'altitude, la pente et l'exposition.
#Dans R on appelle ces rasters des RasterBrick

#############################################################################
#seconde partie permet de calculer à partir du MNT :
# - les contour des bassins versants
# - les talweg
#Nous utilisons ici GRASS dans R
#Il faut avoir installé GRASS sur l'ordinateur
library(spgrass6)
#Dédinition du SCR de référence
Lambert93 <- "+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#Chemin vers l'application GRASS
#si vous êtes sous windows se sera du type "C:\\Program Files\\GRASS 6.4"
initGRASS(gisBase ='/Applications/GRASS-6.4.app/Contents/MacOS',
          home=getwd(), gisDbase="GRASS_temp",
          location="Durance", mapset="PERMANENT",
          override = TRUE)
execGRASS("g.proj", flags="c", proj4 = Lambert93)

execGRASS("r.in.gdal", flags=c("o","overwrite"),
          parameters = list(input="MNT.asc",
              output="DEM"))
execGRASS("g.region", flags="a", parameters=list(rast="DEM",
                                     align="DEM") )

#Redécoupage du raster si nécessaire et calcul des pentes et exposition
#et redéfinition de la région
# execGRASS("r.resamp.rst", input = "DEM",
#             ew_res = 14.25, ns_res = 14.25,
#             elev = "DEM_resamp", slope = "slope", aspect = "aspect")
# execGRASS("g.region", rast = "DEM_resamp")
#DEM_out <- readRAST6(c("DEM_resamp","slope", "aspect"))


#Calcul des bassins versants et des talweg
execGRASS("r.watershed", elevation = "DEM", 
          basin = "r_Bassin", stream = "r_Ecoulement", 
          threshold = 1000, #voici le seuil de surface minimale des bassins
          convergence = 5, memory = 300, flags="overwrite")

#Export dans R
Bassin.int <- readRAST6("r_Bassin",  ignore.stderr=TRUE,
                    plugin=NULL)
Bassin.rast <- raster(Bassin.int)

#Sauvegarde en raster de format tif
writeRaster(Bassin.rast, filename="Bassin.tif", overwrite=T)


##Remarque :
#-----------
#GRASS
#GRASS est un logiciel SIG extrémement complet et puissant.
#À l'origine il ne s'utilisé qu'au travers de scripts, actuellement une interface graphique a été developpé.
#La principale difficulté de GRASS réside dans la définition des SCR, projets et "région".
#Il faut retenir que GRASS utilise des fichiers aux extension qui lui sont propre, on lui indique les 
#fichiers à importer, et il gére lui même l'organisation (d'où les notion de "location" et "mapset")...
#Cela ne vous parle pas vraiment, c'est tout à fait normal il faut se mettre dedans pour comprendre.
#Mais heureusement pour vous, comme nous l'utilisons au travers de R, il n'est pas
#nécessaire de connaître tout cela.
#Il faut tout de même retenir que GRASS est un logiciel trés complet qui permet de 
#réaliser toutes les manipulation que l'on réalise sous ArcGis (voire mieux et plus
#rapidement) et tout cela gratuitement.




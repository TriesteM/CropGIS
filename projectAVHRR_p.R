
# Basic Steps-------------------------------------------------------------

## 1) Import CDL layers
## 2) Extract spatial point locations of each crop type from CDL layers
## 3) Import AVHRR layers
## 4) Crop AVHRR layers to match the respective CDL state layer extent
## 5) Reproject AVHRR layers to match CDL layer spatial projections
## 6) Extract the AVHRR values at CDL crop locations

# Setup-------------------------------------------------------------------

#Pause Dropbox sync, or exit the app

#check to make sure you have the necessary packages and if not,
#install and load them: 
if (!require("pacman")) install.packages("pacman")
pacman::p_load(raster,rgdal,data.table,
               lubridate,foreach,doParallel,
               doSNOW,cdlTools)

#make sure your working directory is: 
# ./Cropyield5 Team Folder/Crop_GIS/CDL_raster

#to check what's been downloaded, extracted
source('checkAVHRRdownloadsExtracts.R')
#if you're using this to determine a new download,
#consider the dates in 'Check' a (narrow) range to get you started
View(check)

#raster functions will generate huge temp files,
#we'll need control over save folders to do long jobs
rasterOptions()$tmpdir
newRasterTemp=paste(getwd(),'rasterTemp',
                    format(Sys.time(),'%B_%d_%Y'),sep='/')
dir.create(newRasterTemp,showWarnings=F)
rasterOptions(tmpdir=newRasterTemp)
#set the temp folder 

#I wrote some functions:
source('projectAVHRRfunctions.R') 
# file.show('projectAVHRRfunctions.R')

#Objects to define for this script:
year=2011 #set whatever year you're planning on extracting
month='September' #set whatever month AVHRR you're getting
avhdir='../AVHRR/' #if you're using my Dropbox setup this shouldn't change
cropxyfolder=paste0('./CDLcropXY/',year)

dir.create(cropxyfolder,showWarnings=F,recursive=T)

#AVHRR images are currently organized by './Year/month'
#there will be millions of these images in our future, so I got 
#started writing some scripts that can process their filenames
rm(list = setdiff(ls(), lsf.str()))
source('whatdidIdownload.R')  
# if there are stray avhrr folders 
#and you don't want to decode their noaa names
args('whatdidIdownload')  # year, avhdir, copyto = F <--function will copy these
# whatdidIdownload(DirToAVHRR,copyto=T)
whatdidIdownload(avhdir,year,copyto=F)
debug(whatdidIdownload)

# 1) Import CDL layers-----------------------------------------------------

cdl_states=c('WA','OR','KS',
             'CO','OK','IA',
             'MN','NE','MO',
             'ND','SD','IL',
             'TX')

# CDLfolders() -->function to get and check the CDL folder names; 
folders=unlist(lapply(cdl_states,function(e) CDLfolders(e)))
folders

#getCDL()-->function to go through each local folder,
#pull out the CDL layers we want
CDLdata=lapply(folders,function(e) getCDL(e,year))
names(CDLdata)=cdl_states
rm(folders)
assign(paste('IA',year,'df',sep=''),
       CDLdata[['IA']]@data@attributes[[1]],
       envir=globalenv())
#just the attributes of the Iowa CDL raster--contains counts
#of different crop cells.  Good for validation later.


# 2) Extract crop cell locations from CDL layers---------------------------

#only need to do this once per year
list.files(cropxyfolder) #you're good to go unless this is empty

#we will be managing the temp folder size, 
#otherwise it can get to about 200gB during the 
#CDL layer processing
newRasterTemp
#check this if your hard disc gets mysteriously stuffed

#x,y locations to extract at values:
# 1 is corn
# 5 is soybeans
# 24 is winter wheat

#Functions:
source('CropXYcoordsFromCDL.R')
View(cropXYfromCDL)  # takes 1 raster, extracts xy at 1 value
args(cropXYfromCDL2disc)  
# takes CDLdata list, works through all at all crops
# then writes each to disc, deletes temp files

#we're extracting only at classes that don't represent
#rotational agriculture, or whatever
data.frame(winterWheat,updateNamesCDL(winterWheat))
data.frame(soybeans,updateNamesCDL(soybeans))
data.frame(corn,updateNamesCDL(corn))
#the single-crop fields are where the CDL is most accurate
cropclasses=data.frame(cropclasses=c(1,5,24),
                       crops=c('Corn','Soy','Wheat'),
                       stringsAsFactors=FALSE)

cropXYfromCDL2disc(CDLdata,cropclasses,cropxyfolder,newRasterTemp)

list.files(cropxyfolder)


# 3) Import AVHRR layers--------------------------------------------------

#getAVHRR() imports the correct images for your year/month and 
#prints the start date and the end date of image data gathered
#(we're downloading both the 7-day and the 14-day composites)
getAVHRR

#make sure the AVHRR images are untarred!
#the raster() function called by getAVHRR() is picky about that

source('bulkUntarAVHRR.R')
bulkUntarAVHRR(avhdir,year,month)

AVHRRdata=getAVHRR(avhdir,year,month)

#getAVHRR() looks in the appropriate year/month directory for 
# _tif folders, goes into them and imports .tifs as raster objects
#it then stacks the .tifs together as a rasterbrick
class(AVHRRdata)
class(AVHRRdata[[1]])
inMemory(AVHRRdata)
#rasterbricks are generally not fully loaded to R memory
#its main data will be in newRasterTemp, so don't delete 
#that until you've produced the UTM cropped versions

names(AVHRRdata) #this just accesses the tifs layers' names
#2 composite lengths, 5 bands each

#information about the AVHRR data is coded into its name:
# "n19_us15_230243"
#n19 is the noaa satellite no.
#us is 'merica
#15 is the year
#230 is the start (ordinal) date of image data acquisition
#243 is the end date
lapply(names(AVHRRdata),function(e) picturetime(e,year))
#picturetime() grabs the "n19_us15_230243"-type layer name embedded in
#raster attribute data and converts to start and end date
unname(sapply(names(AVHRRdata), 
              function(e) picturetime2compLength(e,year)))
#picturetime2comLength() takes those dates and converts to length of 
#data acquisition--we're keeping track of this in future processing


# 4) Crop AVHRR layers to match CDL state layer extents--------------------

# 4.1) Import and extract state boundary layers for clip-------------------

#State boundary layers to crop the AVHRR to manageable sizes:
#taken from 'ftp://ftp2.census.gov/geo/tiger/' specific years
#these are the same boundary files used by NASS to clip their CDL

dsn1=paste('../TIGER/','tl_',year,'_us_state',sep='')
USag=readOGR(dsn=dsn1,layer=basename(dsn1))
USagdf=USag@data
USag@data$STUSPS
USag@data$statename=as.character(USag@data$STUSPS) 
#because I hate working with factors
cornholes=USag[USag@data$STUSPS %in% cdl_states,]  # don't need whole US

#split up the states into one spPolygonsDF per state
cornholesdf=USag@data[USag@data$STUSPS %in% cdl_states,]
cornholesL=vector('list',length(cornholes))

for(j in 1:length(cornholes)){
    cornholesL[[j]]=cornholes[j,]
    names(cornholesL)[[j]]=cornholes@data$statename[j] }

names(cornholesL)
names(CDLdata)
#get them in the same order
cornholesL=cornholesL[names(CDLdata)]
names(cornholesL)
#get the state boundaries into AVHRR projection
AVHRRproj=CRS(proj4string(AVHRRdata))
cornholesLEA=lapply(cornholesL,function(e) spTransform(e,AVHRRproj))
rm(USag)

# 4.1a) (Optional) AVHRR plots---------------------------------------------
#plotAVHRR()-->a function to plot AVHRR because the code to plot 
#AVHRR properly is annoying:
plotAVHRR(AVHRRdata[[1]][[1]],add=F)
sapply(cornholesLEA,function(x) plot(x,add=T,border='white',lwd=2))

# multiple bands can be plotted together, their different wavelengths
# can identify various structures when applied in various combos...
#like the NDVI is derived as:
# (NIR-VIS)/(NIR+VIS) which is
# (ch2-ch1)/(ch2+ch1) in AVHRR data sets
ndviCalc=function(x) {
    ndvi=(x[[2]]-x[[1]])/(x[[2]]+x[[1]])
    return(ndvi) }
ndvi=calc(x=AVHRRdata[[1]],fun=ndviCalc)
plot(ndvi)
#ndvi ranges from -1 to 1, with bare ground usually at
# <0.2; values at ~0.8+ are the highest density of green leaves

#incidentally, using layers of relationships/transformations
#of these bands, like the ndvi, as further values to extract 
#could be a good thing for the classification algorithm
#you know, a model that takes into account the interactions of 
#the independent variables--there's a lot of literature
#on how various combos of satellite sensosr output/wavelengths
#are tightly associated with specific landscape elements
rm(ndvi,ndviCalc)

# 4.2) Crop AVHRR layers---------------------------------------------------

#each band (1 through 5, x2) needs to be cropped 13 times 

AVHRRcrops=lapply(cornholesLEA,function(e) crop(AVHRRdata,extent(e)))
#takes about 15 seconds
names(AVHRRcrops) #13 states
sapply(AVHRRcrops,names) #10 bands (5 each composite langth) per state


# 5) Reproject AVHRR layers to match CDL layer spatial projections---------

AVHRRutm=AVHRRcrops
#if you want to run in parallel just beginCluster()
#projectRaster() has built-in threading but 
#on my machine it's not worth the loading time

# beginCluster()
for(j in 1:length(AVHRRcrops)) {
    AVHRRutm[[j]]=projectRaster(from=AVHRRcrops[[j]],
                                crs=CRS(proj4string(CDLdata[[j]])),
                                res=1000)
}
# endCluster()
# gc()
#~30 seconds

saveRDS(AVHRRutm,paste('AVHRRutm',year,month,'.RDS',sep=''))
sapply(AVHRRutm,inMemory) #so weird!

# 5.1a) (Optional) AVHRRutm crop plots-------------------------------------

#we'll reproject the boundaries to check it all still lines up:
CDLprojs=sapply(CDLdata,function(e) CRS(proj4string(e)))
cornholesUTM=lapply(1:length(cornholesL),
                    function(e) spTransform(cornholesL[[e]],
                                            CDLprojs[[e]]))
names(cornholesUTM)=names(cornholesL)
plot(cornholesUTM[[1]],border='red',lwd=2) #sets plot area
plotAVHRR(AVHRRutm[[1]][[1]][[1]],add=T)
plot(cornholesUTM[[1]],add=T,border='red',lwd=2) 
plot(CDLdata[[1]],add=T)
plot(cornholesUTM[[1]],add=T,border='white',lwd=2) #check the vector

# 5.1b) (Optional) Test plot CDLXY on AVHRRutm-----------------------------

#This is how we grab the AVHRR values:
ORWheat=read.csv(paste(cropxyfolder,'ORWheat.csv',sep='/'))
cornholesORutm=cornholesUTM[['OR']]
AVHRRORutm=AVHRRutm[['OR']]

plot(cornholesORutm,border='red',lwd=2)
plotAVHRR(AVHRRORutm[[1]],add=T)
plot(cornholesORutm,add=T,border='red',lwd=2) 
points(ORWheat[sample(1:nrow(ORWheat),80000),],
       pch=16,cex=0.3,
       col=colortable(CDLdata[[1]])[25])

#if you want to check against the original CDL raster layer 
#(original has all crops; CDLcropXY is spatial points of specific crops)
plot(cornholesORutm,border='red',lwd=2)
plot(CDLdata[['OR']],add=T)
points(ORWheat[sample(1:nrow(ORWheat),20000),],
       pch=16,cex=0.0002,
       col=colortable(CDLdata[[1]])[25])

# 6) Extract AVHRR values at CDL crop locations------------------------

#if you haven't paused Dropbox yet, you really should now

#all we need is AVHRRutm,cropxyfolder,year,month
#everything else can be removed

keep=c('AVHRRutm','cropxyfolder','year','month')
rm(list=ls()[!(ls() %in% keep)])
gc()
croptypes=c('Wheat','Soy','Corn')
cropxyfolderOut=cropxyfolder  # i.e., "./CDLcropXY/2010" nofinal slash

# cropxyfolderOut is the default output directory--change this if you have a
#hard disc that won't take too kindly to all the writing--you might be 
#able to speed this up and make your computer happier by writing results
#files to a different disc...they'll still be organized by subdirectories 
# /14dayAVHRRout/ and /7dayblahblah...


#extract the x day composite values at the x,y locations of crop:
#--pull in the crop x,y coords for croptype
#--process the coordinates in ncuts number of chunks
#--extract values of AVHRR at those coordinates, beam to disc
#--move AVHRRutm file out of the way when we're done with it

# a function to do all that:
source('AVHRRvalueFromCropXYcoords.R')
View(AVHRRvalueFromCropXYcoords)
args(AVHRRvalueFromCropXYcoords)
#AVHRRutm, cropxyfolder/Out, year, and month are already defined

# croptype: can be 'Wheat', 'Soy', or 'Corn'

# ncuts: how many chunks of crop coords to throw at the 
#AVHRR image at any one time for value extraction; increasing this 
#number will decrease the computational load of the value extraction 
#the smaller you can make ncuts, the faster this goes
#unless it's too small, then R memory will grind up
#but if it's too big, your hard disc resources thingies will stutter and
#die (data are getting written to your drive with every cut)
#...I've made some changes to this code since my email, and the
#new "sweet spot" on my machine (which has an SSD, which will have a
#big effect on this process) is around ncuts=10.  YMMV.

# buffMB: buffer size (MB) per write thread--can be 1 to 1024
#default is 8, which is the default set in the fwrite() function

#nThread: number of threads to use during write
?fwrite 
?getDTthreads #for more info

#AVHRR value vectors will be in:
paste(cropxyfolderOut,'14dayAVHRRout',year,month,sep='/')
paste(cropxyfolderOut,'7dayAVHRRout',year,month,sep='/')


# 6.1) Extracting AVHRR values in one R session----------------------------

#AVHRR values at 5 bands x 2 composite lengths
#will be extracted at crop coordinate points 
#the loop will process one croptype at a time

#this might be your best bet if your disc doesn't like all 
#the output shenanigans

for(i in croptypes) {
    AVHRRvalueFromCropXYcoords(croptype=i,ncuts=10,
                               buffMB=10,nThread=8,
                               AVHRRutm,cropxyfolder,
                               cropxyfolderOut,year,month)
}

# 6.2) Extracting AVHRR values in multiple R sessions----------------------

#AVHRRvalueFromCropXYcoords() doesn't use explicitly parallel processing
#but multithreading is internal to our final write function--
#the bottleneck with this process is the size of the data,
#not the complexity of the functions applied to it.  
#The AVHRR value extraction steps are parallel in that we're taking
#values from ten layers at each point-location query

#You can manually run this in parallel by opening multiple instances of R
#and running the function for different parameters on different sessions
#use multiple Rgui, not Rstudio

#just make sure you set to proper wd and define/paste
year= 2014
cropxyfolder=paste('./CDLcropXY/',year,sep='')
month=  'July'
source('AVHRRvalueFromCropXYcoords.R') 
#this will import relevant AVHRRutm when sourced (if it's not already
#in your global environment), but you can also do
# AVHRRutm=readRDS(paste('AVHRRutm',year,month,'.RDS',sep=''))

#extract AVHRR values for one crop type per job:
AVHRRvalueFromCropXYcoords(croptype='Soy',ncuts=10,buffMB=10,
                           nThread=10,AVHRRutm,cropxyfolder,
                           cropxyfolderOut,year,month)

AVHRRvalueFromCropXYcoords(croptype='Corn',ncuts=30,buffMB=16,
                           nThread=10,AVHRRutm,cropxyfolder,
                           cropxyfolderOut,year,month)

AVHRRvalueFromCropXYcoords(croptype='Wheat',ncuts=10,buffMB=10,
                           nThread=10,AVHRRutm,cropxyfolder,
                           cropxyfolderOut,year,month)



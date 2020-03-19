#simple functions for CDL and AVHRR processing:

if (!require("pacman")) install.packages("pacman")
pacman::p_load(raster,rgdal,data.table,lubridate,foreach,doParallel)

CDLfolders=function(cdl_state) {
    folder=paste('../',cdl_state,
                 '/land_use_land_cover/NASS_',
                 cdl_state,sep='')
    return(folder)
}

getCDL=function(folder,year) {
    CDL=raster(paste(folder,
                     list.files(folder,
                                pattern=paste('*',year,
                                              '.*.tif$',sep='')),
                     sep='/'))
    print(year)
    return(CDL) 
}

picturetime=function(noaacode,year) {
    integers=strsplit(unlist(strsplit(noaacode,'_'))[3], '')[[1]]
    startday=paste(integers[1:3],collapse='')
    endday=paste(integers[4:6],collapse='')
    start=as.Date(paste(year,startday,sep=''),
                  format='%Y%j')
    end=as.Date(paste(year,endday,sep=''),
                format='%Y%j')
    return(c(start,end)) 
}

picturetime2compLength=function(noaacode,year) {
    pdates=picturetime(noaacode,year)
    complength=as.double(difftime(pdates[2],pdates[1]))
    composite=ifelse(complength>8,14,7)
    compositeLength=paste(composite,'_day_composite',sep='')
    return(compositeLength)
}

#imports the 5 .tif channel/layers in an avhrr folder,
#holds them in list
get1avhrrComp=function(monthdir,tifdir) {
    
    rasterdir=paste(monthdir,tifdir,'/',sep='')
    print(rasterdir)
    bands=paste('_ch',1:5,'.tif',sep='')
    rasterfiles=lapply(bands,
                       function(e) list.files(rasterdir,
                                              pattern=e))
    rasterL=lapply(rasterfiles,
                   function(e) raster(paste(rasterdir,'/',e,sep='')))
    
    rasterLstack=stack(rasterL)
    print(do.call(rbind,rasterfiles))
    return(rasterLstack)
}

getAVHRR=function(avhdir,year,month) {
    
    #where are they
    monthdir=paste(avhdir,year,'/',month,'/',sep='')
    #in case there are loose tarred versions hanging around
    oops=list.files(monthdir,pattern='_tif.tar')
    x=list.files(monthdir,pattern='_tif')
    #where are they
    tifdirs=x[!(x %in% oops)]
    
    rasterLstack=stack(sapply(tifdirs,
                              function(e) get1avhrrComp(monthdir,
                                                        tifdir=e)))
    
    rasterLbrick=brick(rasterLstack)
    return(rasterLbrick)
}

#the opposite of plotRGB(), basically
plotAVHRR=function(AVHRR,add) {
    plot(AVHRR,add=add,axes=F,legend=F,box=F,
         col=gray.colors(100,start=0,end=1,gamma=1.3)) 
}

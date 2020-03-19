
# throws x,y points at AVHRR rasterbricks and returns the values found
# saves very large vectors to disc

# set up-------------------------------------------------------------------

if (!require("pacman")) install.packages("pacman")
pacman::p_load(raster,rgdal,data.table,lubridate)

if (!exists('AVHRRutm') & exists('year',inherits=F) & exists('month',inherits=F)) {
    AVHRRutm=readRDS(paste('AVHRRutm',year,month,'.RDS',sep=''))
    print(paste('importing', paste('AVHRRutm',year,month,'.RDS',sep='')))
    assign('AVHRRutm',AVHRRutm,envir=globalenv()) }

# functions----------------------------------------------------------------

picturetime=function(noaacode,year){
    integers=strsplit(unlist(strsplit(noaacode,'_'))[3], '')[[1]]
    startday=paste(integers[1:3],collapse='')
    endday=paste(integers[4:6],collapse='')
    start=as.Date(paste(year,startday,sep=''),
                  format='%Y%j')
    end=as.Date(paste(year,endday,sep=''),
                format='%Y%j')
    return(c(start,end)) 
}

picturetime2compLength=function(noaacode,year){
    pdates=picturetime(noaacode,year)
    complength=as.double(difftime(pdates[2],pdates[1]))
    composite=ifelse(complength>8,14,7)
    compositeLength=paste(composite,'_day_composite',sep='')
    return(compositeLength)
}

AVHRRvalueFromCropXYcoords=function(croptype,ncuts,
                                    buffMB=8,nThread=getDTthreads(),
                                    AVHRRutm=AVHRRutm,
                                    cropxyfolder=cropxyfolder,
                                    cropxyfolderOut=cropxyfolderOut,
                                    year=year,month=month) {
    
    #  The name codes in the image layers will determine 
    #  where their output is saved
    AVHRRnamecodes=data.frame(names=names(AVHRRutm[[1]]),
                              composite=unname(sapply(
                                  names(AVHRRutm[[1]]),
                                  function(e) picturetime2compLength(
                                      e,year))),
                              stringsAsFactors=F)
    
    compositenames=AVHRRnamecodes['composite']
    compabbrv=ifelse(compositenames=='7_day_composite',
                     '7day','14day')
    compXdayOut=ifelse(compositenames=='7_day_composite',
                       paste(unlist(strsplit(cropxyfolderOut,
                                             split=paste0('/',year))),
                             '/7dayAVHRRout/',
                             year,'/',month,sep=''),
                       paste(unlist(strsplit(cropxyfolderOut,
                                             split=paste0('/',year))),
                             '/14dayAVHRRout/',
                             year,'/',month,sep='')  
    )
    sapply(unique(compXdayOut),
           function(e) dir.create(e,showWarnings=F,
                                  recursive=T))
    for(i in unique(compXdayOut)){
        if(length(list.files(i,pattern=paste(croptype)))>0)  
            stop(paste("There are output files of this crop type in ", 
                       i,
                       ". Don't append to them!",
                       sep=''))
    }
    #  CDL data setup:
    cropfiles=list.files(cropxyfolder,ignore.case=T,
                         pattern=paste('*',
                                       croptype,
                                       sep=''))
    filenames=paste(cropxyfolder,
                    cropfiles,sep='/')
    states=sapply(1:length(cropfiles),
                  function(x) strsplit(cropfiles,
                                       croptype)[[x]][1])
    stateslocs=cbind(states=states,
                     cropfiles=cropfiles,
                     filenames=filenames)
    cropXYfiles=stateslocs[,'filenames']
    statenames=stateslocs[,'states']
    ncuts=ncuts
    buffMB=buffMB
    nThread=nThread
    
    print('Locating crop points:'); print(cropXYfiles)
    
    #  import cropXY for one crop/state at a time
    for(j in 1:length(cropXYfiles)){
        croplocs=fread(cropXYfiles[j],data.table=FALSE)
        state=statenames[j]
        
        if(nrow(croplocs)>ncuts){
            cutsi=cut(1:nrow(croplocs),
                      breaks=ncuts,
                      labels=F)
        } else {
            cutsi=cut(1:nrow(croplocs),
                      breaks=nrow(croplocs),
                      labels=F)
        }
        print(paste('state',j,'of',length(cropXYfiles)))
        
        for(k in 1:length(unique(cutsi))){
            #####this block could potentially be parallel
            AVHRR.cropCells=cellFromXY(AVHRRutm[[state]],
                                       croplocs[cutsi==k,])
            # extracted=AVHRRutm[[state]][AVHRR.cropCells]
            extracted=extract(AVHRRutm[[state]],AVHRR.cropCells)
            ######
            savefile=paste(compXdayOut,'/',
                           croptype,'_',
                           year,'_',month,'_',
                           paste('Ch_',1:5,sep=''),'_',
                           compabbrv,
                           '.csv',sep='')
            
            sapply(seq_along(colnames(extracted)),
                   function(e) fwrite(data.frame(extracted[,e]),
                                      savefile[e],
                                      append=T,
                                      buffMB=buffMB,nThread=nThread,
                                      col.names=F))
            
            print( paste('state',j,'of',length(cropXYfiles),'cut',
                         k,'of',length(unique(cutsi))) )
        }
    }
    if(length(list.files(unique(compXdayOut)))==30) {
        
        dump='./AVHRRutm_finishedExtracts/toobig'
        dir.create(dump,showWarnings=F,recursive=T)
        
        if(file.exists(paste0('./AVHRRutm',year,
                              month,'.RDS'))) {
            file.copy(from=paste0('./AVHRRutm',year,
                                  month,'.RDS'),
                      to=dump,overwrite=T)
            
            if(file.exists(paste0(dump,'./AVHRRutm',year,
                                  month,'.RDS')) &&
               file.exists(paste0('./AVHRRutm',year,
                                  month,'.RDS'))) {
                file.remove(paste0('./AVHRRutm',year,
                                   month,'.RDS'))
                file.create(paste0('./AVHRRutm_finishedExtracts/',
                                   'AVHRRutm',year,month,'.csv'))
                cat(paste0('   good job all done! AVHRRutm',year,
                           month,'.RDS has been moved to the utm graveyard')) 
            }
        }
    }
}



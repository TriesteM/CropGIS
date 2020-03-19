#CropXYcoordsFromCDL
#given a crop type and a CDL layer, extracts the x,y coordinates
#saves to disc by state/crop
#uses parallel computing

if (!require("pacman")) install.packages("pacman")
pacman::p_load(raster,rgdal,data.table,parallel)

#fwrite a large CDL crop loc matrix to disc
writebigMX=function(MX,cropxyfolder,statename,croptype) {
    filenames=paste(cropxyfolder,'/',
                    statename,croptype,'.csv',sep='')
    fwrite(data.frame(MX),filenames) 
}

#function cropXYfromCDL() will accept 1 CDL layer and 
#1 crop ID value, will return the x,y coordinates of crop
#in that layer (internal function clusterR processes the biggest part of this job 
#in parallel)
cropXYfromCDL=function(raster,cropclass) {
    
    y=cropclass
    cl=getCluster()
    
    parallel::clusterExport(cl,varlist=list('y'),
                            envir=environment())
    
    outR=clusterR(cl=cl,raster,calc,m=5,
                  args=list( fun=function(x) { x[x!=y] <- NA; return(x) } )
    )
    returnCluster()
    gc()
    
    yescells=Which(outR,cells=TRUE)
    cropXY=xyFromCell(outR,yescells)
    
    return(cropXY)
}

#loops through multiple crop classes and multiple rasters
#writes output to disc w/multiple threads, deletes temp files as it goes
cropXYfromCDL2disc=function(CDLdata=CDLdata,
                            cropclasses=cropclasses,
                            cropxyfolder=cropxyfolder,
                            newRasterTemp=newRasterTemp) {
    beginCluster()
    for(i in 1:nrow(cropclasses)) {
        
        print(paste(cropclasses[i,'crops']))
        
        for(j in 1:length(CDLdata)) {
            statename=names(CDLdata)[[j]]
            jTempDir=paste(newRasterTemp,statename,sep='/')
            dir.create(jTempDir,showWarnings=T,recursive=T)
            rasterOptions(tmpdir=jTempDir)
            print(paste(statename))
            
            CDLcropXY=cropXYfromCDL(raster=CDLdata[[j]],
                                    cropclass=cropclasses[i,'cropclasses'])
            
            writebigMX(MX=CDLcropXY,cropxyfolder,
                       statename,croptype=cropclasses[i,'crops'])
            
            unlink(file.path(jTempDir),recursive=T)
            gc()
        }
    }
    endCluster()
}

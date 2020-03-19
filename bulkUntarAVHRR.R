

bulkUntarAVHRR=function(avhdir,year,month){
    
    tarfiles=list.files(paste(avhdir,year,'/',month,sep=''),
                         pattern='_tif.tar',
                         full.names=F)
    
    tarfilesf=list.files(paste(avhdir,year,'/',month,sep=''),
                        pattern='_tif.tar',
                        full.names=T)
    
    exdirs=unlist(strsplit(tarfilesf,'.tar'))
    
    dir.create(paste(avhdir,year,'/',month,'/tars',sep=''),
               showWarnings=F)
    
    for(i in 1:length(tarfilesf)){
        
        untar(tarfilesf[i],
              exdir=exdirs[i])

        file.copy(from=tarfilesf[i],
                    to=paste(avhdir,year,'/',month,'/tars/',tarfiles,sep=''),
                  overwrite=T)
        
        file.remove(tarfilesf[i])
        
        print(i) }
}
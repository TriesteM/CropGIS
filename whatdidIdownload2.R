
#bulk downloading AVHRR data is slightly less inconvenient than
#single downloads--but no matter how you do it, it can be easy
#to lose track of which downloaded file is what.
#this function will print the start and end dates of acquisition 
#that are recorded in the AVHRR file names
#if copyto=T, it will also move them to the appropriate folders
#in our directory

whatdidIdownload=function(year,avhdir,copyto=F){
    
    if (!require("pacman")) install.packages("pacman")
    pacman::p_load(data.table,lubridate)
    
    #figure out what months they belong to:
    question=list.files(paste(avhdir,year,sep=''),pattern='.tif')
    
    splits=strsplit(question,'_')
    integers=sapply(splits,function(e) unlist(e))[3,]
    
    startday=substr(integers,1,nchar(integers)-3)
    endday=substr(integers,4,nchar(integers))
    
    start=format(as.Date(paste(year,startday,sep=''),
                         format='%Y%j'),'%B %d %Y')
    end=format(as.Date(paste(year,endday,sep=''),
                       format='%Y%j'),'%B %d %Y')
    
    startend=cbind(file=question,start=start,end=end)
    print(startend)
    
    #move to appropriate year folder
    if(copyto){
        
        print('copying files to correct folders')
        
        months=c('July','August','September')

        tofolder=unname(sapply(startend[,'end'],function(x) unlist(strsplit(x,' '))[[1]]))
        
        #many will need to go into the next month's folder:
        poo=as.numeric(unname(sapply(sapply(end,function(x) strsplit(x,' ')),function(e) e[2])))
        toplus1=format(as.Date(end,'%B %d %Y') %m+% months(1),'%B %d %Y')
        toplus1=unname(sapply(toplus1,function(x) unlist(strsplit(x,' '))[[1]]))
        
        #...unless their end date is on the 1st of the month:
        for(i in 1:length(poo)){
            ifelse(poo[i]==1,tofolder[i]<-tofolder[i],tofolder[i]<-toplus1[i])}
        
        #folder names to move them:
        tofile=paste(avhdir,year,'/',tofolder,'/',question,sep='')
        
        fromfile=paste(avhdir,year,'/',question,sep='')
        
        for(i in 1:length(fromfile)){
            file.rename(from=fromfile[i],to=tofile[i])
            print(i)
        }
    }
}

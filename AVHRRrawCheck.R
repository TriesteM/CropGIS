##check to see what AVHRR data have been downloaded

AVHRRrawCheck=function(){
    years=2008:2016
    months=c('July','August','September')
    lastday=1
    
    lastdays=paste(months,lastday,rep(years,each=3),sep=' ')
    lastdays=as.Date(lastdays,'%b %d %Y')
    lastdays=lastdays[order(lastdays)]
    
    cal1=data.frame(firstday14=lastdays-14,
                    firstday7=lastdays-7,
                    lastday=lastdays)
    cal1=format(cal1, '%B %d %Y')
    
    #what's been downloaded?
    avhdir='../AVHRR/' 
    AVHRRfolders=paste(avhdir,years,'/',sep='')
    AVHRRfolders=paste(rep(AVHRRfolders,each=3),months,sep='')
    well=lapply(AVHRRfolders,function(e) list.files(e))
    names(well)=AVHRRfolders
    
    well[sapply(well,function(e) identical(e,character(0)))]=NA
    poo=sapply(well,function(e) !is.na(e))
    
    cal1$downloaded=sapply(poo,function(x) x[1])
    
    return(cal1)
}
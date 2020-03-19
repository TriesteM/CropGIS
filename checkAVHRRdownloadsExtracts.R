

# Check for AVHRR file downloads/completion----------------------

source('AVHRRrawCheck.R') #inaccurate if unsynced from '../AVHRR/'
check=AVHRRrawCheck() 
#the dates returned by this function are approximate
#if you're using this to determine a new download,
#consider these dates a (narrow) range to get you started

#the AVHRR files will get moved to './AVHRRutm_finishedExtracts/',
#so if you want to check what's been completed for extractions:
print(paste('Years/months that have been extracted:'))
print(sub('.csv',
          '',
          sub('AVHRRutm',
              '',
              setdiff(list.files('./AVHRRutm_finishedExtracts/',
                                 full.names=F),
                      list.dirs('./AVHRRutm_finishedExtracts/',
                                recursive=F,full.names=F)))))

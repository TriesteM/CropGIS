

#check to see what ACHRR data files have been downloaded:
source('AVHRRrawCheck.R')
check=AVHRRrawCheck()
View(check)

#the dates returned by this function are approximate
#if you're using this to determine a new download,
#consider these dates a (narrow) range to get you started
#the EarthExplorer interface is prehistoric

#I don't want to write code right now to check Dropbox and report which years
#have been processed and extracted at crop field locations, so I'll just record here
#when I've finished a year: (a year is finished when July,August,Sept have been
#extracted at both 14- and 7-day AVHRR composites)

#Finished:  2015, 2008

#if you're downloading AVHRR in bulk, here's a function 
#that will display what you downloaded and their acquisition dates:

#(make sure these tif.tar files are in the appropriate YEAR folder--
#this function will look in that folder and tell you which month folder(s)
#to move them to (if copyto=F) or it will move them for you (copyto=T)
source('whatdidIdownload.R')
View(whatdidIdownload)

#you have to put them in the right year folder
#(i.e., you download images for 2008 to ../AVHRR/2008 and
#this function will distribute them to the appropriate month
#subfolders)

avhdir='../AVHRR/' 
# year=
whatdidIdownload(avhdir=avhdir,year=year,copyto=T)

# > whatdidIdownload(avhdir=avhdir,year=2010,copyto=F)
# file                      start            end             
# [1,] "n18_us10_166179_tif.tar" "June 15 2010"   "June 28 2010"  
# [2,] "n18_us10_173179_tif.tar" "June 22 2010"   "June 28 2010"  
# [3,] "n18_us10_194207_tif.tar" "July 13 2010"   "July 26 2010"  
# [4,] "n18_us10_201207_tif.tar" "July 20 2010"   "July 26 2010"  
# [5,] "n18_us10_229242_tif.tar" "August 17 2010" "August 30 2010"
# [6,] "n18_us10_236242_tif.tar" "August 24 2010" "August 30 2010"

#^^^note that these images all ended in the month prior to the month we're
#interested in (we want AVHRR up to but not including the 2nd of the 
#months of July, August, September)--so the way the directories
#are set up, these all go in next month's folder
#the function does have a response when we happen to land 
#on September 1, though

#once you have your AVHRR tif.tar files moved to the proper month
#folder, you can decompress them:
source('bulkUntarAVHRR.R')

#decompress one month folder:
bulkUntarAVHRR(avhdir=avhdir,year=year,month='August')

#decompress multiple month folders:
monthstountar=c('September','August')
sapply(monthstountar,function(e) bulkUntarAVHRR(avhdir=avhdir,year=year,month=e))

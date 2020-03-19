# CropGIS
Basic steps with comments and references to helper functions are found in 'projectAVHRR_p.R' file (

Basic Steps:

1) Import CDL layers from https://nassgeodata.gmu.edu/CropScape/ or https://www.nass.usda.gov/Research_and_Science/Cropland/Release/index.php.  

2) Extract spatial point locations of each crop type from CDL layers -- choose your crops of interest and identify their locations across area of interest.

3) Import AVHRR layers -- at the time this project was created, there was no convenient way to download these layers (in bulk), but there are helper functions to keep these data more easily organized and managed.  However:  https://www.usgs.gov/centers/eros/science/usgs-eros-archive-avhrr-normalized-difference-vegetation-index-ndvi-composites?qt-science_center_objects=0#qt-science_center_objects

4) Crop AVHRR layers to match the respective CDL state layer extent -- simple enough.

5) Reproject AVHRR layers to match CDL layer spatial projections.

6) Extract the AVHRR values at CDL crop locations -- success.

As mentioned in-line comments, the bottlenecks here are the steps that require(d) manual input (data downloads, mainly) as well as the raster manipulation steps, which generate large temp files and were slowed by reading/writing to disc.  I developed intermediate data management steps to address the issue, but efficiency might change depending on your local system, etc.

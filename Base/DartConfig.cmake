# Dashboard is opened for submissions for a 24 hour period starting at
# the specified NIGHLY_START_TIME. Time is specified in 24 hour format.
SET (NIGHTLY_START_TIME "02:00:00 EDT")

# Dart server to submit results (used by client)
SET (DROP_SITE "ftp.spl.harvard.edu")
SET (DROP_LOCATION "/incoming")
SET (DROP_SITE_USER "slicerdart")
SET (DROP_SITE_PASSWORD "slicerdart")
SET (TRIGGER_SITE 
       "http://${DROP_SITE}/cgi-bin/Submit-slicer-TestingResults.pl")

# Project Home Page
SET (PROJECT_URL "http://www.slicer.org/")

# Dart server configuration 
SET (ROLLUP_URL "http://${DROP_SITE}/cgi-bin/slicer-rollup-dashboard.sh")
SET (CVS_WEB_URL "http://${DROP_SITE}/cgi-bin/cvsweb.cgi/slicer/")
SET (CVS_WEB_CVSROOT "slicer2")
SET (USE_DOXYGEN "Off")
SET (DOXYGEN_URL "http://${DROP_SITE}/VTK/doc/nightly/html/" )
SET (USE_GNATS "Off")
SET (GNATS_WEB_URL "http://${DROP_SITE}/")

# copy over the testing logo
CONFIGURE_FILE(${VTK_SOURCE_DIR}/TestingLogo.gif ${VTK_BINARY_DIR}/Testing/HTML/TestingResults/Icons/Logo.gif COPYONLY)

# Continuous email delivery variables
SET (CONTINUOUS_FROM "slicerdart@bwh.harvard.edu")
SET (SMTP_MAILHOST "mail.bwh")
SET (CONTINUOUS_MONITOR_LIST "lorensen@crd.ge.com")
SET (CONTINUOUS_BASE_URL "http://public.kitware.com/VTK/Testing")


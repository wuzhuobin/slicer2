#
# Source files: DO NOT EDIT THIS FILE: edit CMakeListsLocal.txt instead.
#
#

SET (LOCAL_LIBRARY_BASENAME vtkLevelSets)

INCLUDE (${VTKLEVELSETS_SOURCE_DIR}/cxx/CMakeListsLocal.txt)

# --------------------------------------------------------------------------
# You probably do not need to modify anything below this line

#
# Create the vtkLevelSets C++ library
#
# (Doesn't work here because of a CMake bug)
# ADD_LIBRARY (vtkLevelSets ${LOCAL_MODULE_SRCS})

#
# Create the vtkLevelSets Tcl library
#

IF (VTK_WRAP_TCL AND VTKLEVELSETS_WRAP_TCL)

  VTK_WRAP_TCL (vtkLevelSetsTCL LevelSetsTCL_SRCS ${LOCAL_MODULE_SRCS})
  ADD_LIBRARY (vtkLevelSetsTCL ${LevelSetsTCL_SRCS})
  TARGET_LINK_LIBRARIES (vtkLevelSetsTCL 
                         vtkLevelSets
                         vtkIOTCL 
                         vtkGraphicsTCL 
                         vtkImagingTCL 
                         vtkFilteringTCL 
                         vtkCommonTCL
                         ${TCL_LIBRARY})
  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkLevelSetsTCL vtkHybridTCL)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkLevelSetsTCL vtkParallelTCL)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkLevelSetsTCL vtkPatentedTCL)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkLevelSetsTCL vtkRenderingTCL)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_TCL AND VTKLEVELSETS_WRAP_TCL)

#
# Create the vtkLevelSets Python library
#

IF (VTK_WRAP_PYTHON AND VTKLEVELSETS_WRAP_PYTHON)

  VTK_WRAP_PYTHON (vtkLevelSetsPython LevelSetsPython_SRCS ${LOCAL_MODULE_SRCS})

  IF (APPLE)
    ADD_LIBRARY (vtkLevelSetsPython MODULE ${LevelSetsPython_SRCS})
  ELSE (APPLE)
    ADD_LIBRARY (vtkLevelSetsPython SHARED ${LevelSetsPython_SRCS})
  ENDIF (APPLE)

  IF (WIN32)
    TARGET_LINK_LIBRARIES (vtkLevelSetsPython 
                           vtkLevelSets
                           vtkIOPython
                           vtkGraphicsPython
                           vtkImagingPython
                           vtkFilteringPython
                           vtkCommonPython
                           debug ${PYTHON_DEBUG_LIBRARY} 
                           optimized ${PYTHON_LIBRARY})
  ELSE (WIN32)
    TARGET_LINK_LIBRARIES (vtkLevelSetsPython 
                           vtkLevelSetsPython 
                           vtkIOPython
                           vtkGraphicsPython
                           vtkImagingPython
                           vtkFilteringPython
                           vtkCommonPython
                           ${PYTHON_LIBRARY})
  ENDIF (WIN32)

  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkLevelSetsPython vtkHybridPython)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkLevelSetsPython vtkParallelPython)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkLevelSetsPython vtkPatentedPython)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkLevelSetsPython vtkRenderingPython)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_PYTHON AND VTKLEVELSETS_WRAP_PYTHON)

#
# Create the vtkLevelSets Java library
#

IF (VTK_WRAP_JAVA AND VTKLEVELSETS_WRAP_JAVA)

  VTK_WRAP_JAVA (vtkLevelSetsJava LevelSetsJava_SRCS ${LOCAL_MODULE_SRCS})
  ADD_LIBRARY (vtkLevelSetsJava SHARED ${LevelSetsJava_SRCS})
  TARGET_LINK_LIBRARIES (vtkLevelSetsJava 
                         vtkLevelSets
                         vtkIOJava
                         vtkGraphicsJava
                         vtkImagingJava 
                         vtkFilteringJava
                         vtkCommonJava)
  IF (VTK_USE_HYBRID)
    TARGET_LINK_LIBRARIES (vtkLevelSetsJava vtkHybridJava)
  ENDIF (VTK_USE_HYBRID)

  IF (VTK_USE_PARALLEL)
    TARGET_LINK_LIBRARIES (vtkLevelSetsJava vtkParallelJava)
  ENDIF (VTK_USE_PARALLEL)

  IF (VTK_USE_PATENTED)
    TARGET_LINK_LIBRARIES (vtkLevelSetsJava vtkPatentedJava)
  ENDIF (VTK_USE_PATENTED)

  IF (VTK_USE_RENDERING)
    TARGET_LINK_LIBRARIES (vtkLevelSetsJava vtkRenderingJava)
  ENDIF (VTK_USE_RENDERING)

ENDIF (VTK_WRAP_JAVA AND VTKLEVELSETS_WRAP_JAVA)

#
# Link to VTK and local
#

TARGET_LINK_LIBRARIES (
  vtkLevelSets
  vtkIO
  vtkGraphics
  vtkImaging 
  vtkFiltering
  vtkCommon
)

IF (VTK_USE_HYBRID)
  TARGET_LINK_LIBRARIES (vtkLevelSets vtkHybrid)
ENDIF (VTK_USE_HYBRID)

IF (VTK_USE_PARALLEL)
  TARGET_LINK_LIBRARIES (vtkLevelSets vtkParallel)
ENDIF (VTK_USE_PARALLEL)

IF (VTK_USE_PATENTED)
  TARGET_LINK_LIBRARIES (vtkLevelSets vtkPatented)
ENDIF (VTK_USE_PATENTED)

IF (VTK_USE_RENDERING)
  TARGET_LINK_LIBRARIES (vtkLevelSets vtkRendering)
ENDIF (VTK_USE_RENDERING)

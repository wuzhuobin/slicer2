catch {load vtktcl}
source vtkImageInclude.tcl

# Image pipeline

vtkImageReader reader
reader ReleaseDataFlagOff
reader SetDataByteOrderToLittleEndian
reader SetDataExtent 0 255 0 255 1 93
reader SetFilePrefix "../../../vtkdata/fullHead/headsq"
reader SetDataMask 0x7fff

vtkMatrix4x4 m
m SetElement 0 0 -0.16214
m SetElement 0 1 0.914434
m SetElement 0 2 0.370837
m SetElement 0 3 0

m SetElement 1 0 -0.454903
m SetElement 1 1 -0.402761
m SetElement 1 2 0.794258
m SetElement 1 3 0

m SetElement 2 0 0.875656
m SetElement 2 1 -0.0399135
m SetElement 2 2 0.4812830
m SetElement 2 3 0

m SetElement 3 0 0
m SetElement 3 1 0
m SetElement 3 2 0
m SetElement 3 3 1

# RastoIjk
vtkMatrix4x4 m2
m2 SetElement 0 0 -1.06667
m2 SetElement 0 1 0
m2 SetElement 0 2 0
m2 SetElement 0 3 128

m2 SetElement 1 0 0
m2 SetElement 1 1 1.06667
m2 SetElement 1 2 0
m2 SetElement 1 3 106.987

m2 SetElement 2 0 0
m2 SetElement 2 1 0 
m2 SetElement 2 2 -0.5
m2 SetElement 2 3 29.75

m2 SetElement 3 0 0 
m2 SetElement 3 1 0 
m2 SetElement 3 2 0 
m2 SetElement 3 3 1 

vtkImageReformat ireform
ireform SetInput [reader GetOutput]
ireform SetReformatMatrix m
ireform SetWldToIjkMatrix m2
ireform InterpolateOff
ireform SetResolution 256
ireform SetFieldOfView 240

vtkImageViewer viewer
viewer SetInput [ireform GetOutput]
viewer SetZSlice 22
viewer SetColorWindow 2000
viewer SetColorLevel 1000

#make interface
source WindowLevelInterface.tcl

ireform SetPoint 20 30
puts "wld = [ireform GetWldPoint]"
puts "ijk = [ireform GetIjkPoint]"








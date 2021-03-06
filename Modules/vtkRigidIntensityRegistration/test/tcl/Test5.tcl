package require vtkRigidIntensityRegistration;# this pulls in the package

#if {[llength $argv ] != 7} {
#  puts "Tests vtkMutualInformationRegistration"
#  puts "Takes in a volume, applies a transform to it"
#  puts "and then tries to recapture that transform"
#  puts "This version flips a volume before applying the transform"
#  puts "Usage: vtk Test2.tcl ImageBase"
#  puts "           NumX NumY NumZ SpaceX SpaceY SpaceZ"
#}
#
#set DATA1    [lindex $argv 0 ]
#set NumX     [lindex $argv 1 ]
#set NumY     [lindex $argv 2 ]
#set NumZ     [lindex $argv 3 ]
#set SpaceX   [lindex $argv 4 ]
#set SpaceY   [lindex $argv 5 ]
#set SpaceZ   [lindex $argv 6 ]

proc TestMutualInformationTransform { BaseFileName Numx Numy Numz SpaceX SpaceY SpaceZ } {

    set BaseFileName2 /projects/test/xtrans-zflip/tt
    puts "$BaseFileName $Numx $Numy $Numz $SpaceX $SpaceY $SpaceZ"

    catch { __reader1          Delete   }
    catch { __sourcechangeinfo Delete   }
    catch { __sourcecast       Delete   }
    catch { __sourcenorm       Delete   }
    catch { __targetchangeinfo Delete   }
    catch { __targetcast       Delete   }
    catch { __targetnorm       Delete   }
    catch { __reslicer         Delete   }
    catch { __trans            Delete   }
    catch { __initialmat       Delete   }
    catch { __flipmat          Delete   }
    catch { __reg              Delete   }
    catch { __FinalTransform   Delete   }

    set LastX [expr $Numx - 1]
    set LastY [expr $Numy - 1]
    set LastZ [expr $Numz - 1]

  vtkImageReader __reader1
    __reader1 SetDataByteOrderToBigEndian
    __reader1 SetFilePattern "%s.%03d"
    __reader1 SetDataExtent 0 $LastX 0 $LastY 1 $Numz
    __reader1 SetDataSpacing $SpaceX $SpaceY $SpaceZ
    __reader1 SetFilePrefix $BaseFileName
    __reader1 Update

  set inputvol  [__reader1 GetOutput]
  
  ### Normalize, and Center the source
   vtkImageChangeInformation __sourcechangeinfo
     __sourcechangeinfo CenterImageOn
     __sourcechangeinfo SetInput $inputvol
  
   vtkImageCast __sourcecast
     __sourcecast SetOutputScalarTypeToFloat
     __sourcecast SetInput [__sourcechangeinfo GetOutput]
  
   vtkITKNormalizeImageFilter __sourcenorm
      __sourcenorm SetInput [__sourcecast GetOutput]
  
  ### Create the target image
  ## flip the y axis
 vtkMatrix4x4 __flipmat
    __flipmat Identity
    __flipmat SetElement 2 2 -1

  vtkTransform __trans
      __trans Concatenate __flipmat
  
  vtkImageReslice __reslicer
      __reslicer SetInput $inputvol
      __reslicer SetResliceTransform __trans
  
  ### Normalize, and Center the target

  vtkImageReader __reader2
    __reader2 SetDataByteOrderToBigEndian
    __reader2 SetFilePattern "%s.%03d"
    __reader2 SetDataExtent 0 $LastX 0 $LastY 1 $Numz
    __reader2 SetDataSpacing $SpaceX $SpaceY $SpaceZ
    __reader2 SetFilePrefix $BaseFileName2
    __reader2 Update

   vtkImageChangeInformation __targetchangeinfo
     __targetchangeinfo CenterImageOn
     __targetchangeinfo SetInput [__reslicer GetOutput]
     __targetchangeinfo SetInput [__reader2 GetOutput]
  
   vtkImageCast __targetcast
     __targetcast SetOutputScalarTypeToFloat
     __targetcast SetInput [__targetchangeinfo GetOutput]
  
   vtkITKNormalizeImageFilter __targetnorm
      __targetnorm SetInput [__targetcast GetOutput]
  
  ### An initial matrix
    vtkMatrix4x4 __initialmat
      __initialmat Identity
      __initialmat DeepCopy __flipmat
  
   vtkITKMutualInformationTransform __reg
      __reg Initialize __initialmat
      __reg SetTargetImage [__targetnorm GetOutput]
      __reg SetSourceImage [__sourcenorm GetOutput]
      __reg SetTranslateScale 320
      __reg SetSourceStandardDeviation 0.4
      __reg SetTargetStandardDeviation 0.4
      __reg SetSourceShrinkFactors 4 4 1
      __reg SetTargetShrinkFactors 4 4 1
      __reg SetNumberOfSamples 50
      __reg InitRandomSeed 8775070
  
    __reg ResetMultiResolutionSettings 
    foreach iter  "2500 2500 2500 2500 2500" {
       __reg SetNextMaxNumberOfIterations $iter
    }
    foreach rate  "1e-4 1e-5 5e-6 1e-6 5e-7" {
       __reg SetNextLearningRate  $rate
    }
  
    __reg Update

    if {[__reg GetError] > 0} {
       DevErrorWindow "Registration Algorithm returned an error!\n Are you sure the images overlap?"
        return
    }
  
    [__reg GetOutputMatrix] Print
    __trans Print

    vtkTransform __FinalTransform
      __FinalTransform SetMatrix [__reg GetOutputMatrix]
      __FinalTransform PreMultiply
      __FinalTransform Translate   [expr -$SpaceX*$LastX/2.0] \
        [expr -$SpaceY*$LastY/2.0] [expr -$SpaceZ*$LastZ/2.0]
      __FinalTransform PostMultiply 
      __FinalTransform Translate [expr $SpaceX*$LastX/2.0] \
       [expr $SpaceY*$LastY/2.0] [expr $SpaceZ*$LastZ/2.0]
      __FinalTransform Inverse
      __FinalTransform PostMultiply 
      __FinalTransform Concatenate [__trans GetMatrix]

    set Mat [__FinalTransform GetMatrix]
    set error0  [expr [$Mat GetElement 0 0] - 1]
    set error1  [expr [$Mat GetElement 1 1] - 1]
    set error2  [expr [$Mat GetElement 2 2] - 1]
    set error3  [$Mat GetElement 0 1]
    set error4  [$Mat GetElement 0 2]
    set error5  [$Mat GetElement 0 3]
    set error6  [$Mat GetElement 1 0]
    set error7  [$Mat GetElement 1 2]
    set error8  [$Mat GetElement 1 3]
    set error9  [$Mat GetElement 2 0]
    set error10 [$Mat GetElement 2 1]
    set error11 [$Mat GetElement 2 3]

    set error [expr $error0  * $error0  + $error1  * $error1 + \
                    $error2  * $error2  + $error3  * $error3 + \
                    $error4  * $error4  + $error5  * $error5 + \
                    $error6  * $error6  + $error7  * $error7 + \
                    $error8  * $error8  + $error9  * $error9 + \
                    $error10 * $error10 + $error11 * $error11 ]
    set error [expr sqrt($error)]

  if {$error > 0.05} {
      puts "Error was $error, bigger than 0.05!!"
      exit
  }

 #    __reader1          Delete  
 #    __sourcechangeinfo Delete  
 #    __sourcecast       Delete  
 #    __sourcenorm       Delete  
 #    __targetchangeinfo Delete  
 #    __targetcast       Delete  
 #    __targetnorm       Delete  
 #    __reslicer         Delete  
 #    __trans            Delete  
 #    __initialmat       Delete  
 #    __reg              Delete  
 #    __FinalTransform   Delete

    return $error
}



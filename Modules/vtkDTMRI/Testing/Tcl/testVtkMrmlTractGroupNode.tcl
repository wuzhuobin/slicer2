package require vtkDTMRI
package require vtkSlicerBase

vtkMrmlTractGroupNode node

node SetTractGroupID 1
node AddTractToGroup 2
node AddTractToGroup 3

puts [node Print]

vtkMrmlTree tree
tree AddItem node
tree Write "test.mrml"




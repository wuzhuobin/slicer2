catch "sc Delete"
vtkMRMLScene sc

catch "vs Delete"
vtkMRMLVolumeArchetypeStorageNode vs

sc RegisterNodeClass vs

sc SetURL Modules/vtkSlicerThree/Tests/undo.xml
sc Connect

set n [sc GetNthNodeByClass 0 vtkMRMLVolumeArchetypeStorageNode]
puts "Print Storage node 0"
puts "[$n Print]"

puts "GetFileArcheType = [$n GetFileArcheType]"

sc SaveStateForUndo $n
$n SetFileArcheType ff1
puts "GetFileArcheType = [$n GetFileArcheType]"

sc SaveStateForUndo $n
$n SetFileArcheType ff2
puts "GetFileArcheType = [$n GetFileArcheType]"

sc SaveStateForUndo $n
$n SetFileArcheType ff3
puts "GetFileArcheType = [$n GetFileArcheType]"

puts Undo
sc Undo
puts "GetFileArcheType = [$n GetFileArcheType]"

puts Undo
sc Undo
puts "GetFileArcheType = [$n GetFileArcheType]"

puts Undo
sc Undo
puts "GetFileArcheType = [$n GetFileArcheType]"




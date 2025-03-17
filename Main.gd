extends Node3D

var mdt=MeshDataTool.new()

@onready var TheModel=$metarig/Skeleton3D/Cube
@onready var TheMesh=$metarig/Skeleton3D/Cube.mesh
@onready var TheSkeleton=$metarig/Skeleton3D
@onready var metarig=$metarig
var TheSkin
var FpsMeter=preload("res://FPSDisplay.tscn")
#======================================================================

var RedBox=preload("res://BoxScene.tscn")
var point_mesh_list=[]

#=================
var bone_segment_vectors=[]#[segmentpt1, segmentpt2]
var Bsegment_count=0
var BonesAndSegments={}#{ boneindx: [bone_segment_vectors_indx1, bone_segment_vectors_indx2, bone_segment_vectors_indx3,.................. ] }

#=================
var Bones
var Weights
#==========================================================

#============================================================
var rd := RenderingServer.create_local_rendering_device()
var shader_file := load("res://LinearBlendSkinning.glsl")
var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
var shader := rd.shader_create_from_spirv(shader_spirv)
var pipeline := rd.compute_pipeline_create(shader)

var VertBuffer
var OutPutBuffer
var Uniform_VertSet

var BIndexBuffer
var WeightsBuffer
var Uniform_BIWSet

var Rinput
var RestsBuffer
var Binput
var BonesBuffer
var Uniform_BoneSet

var MatXMatBuffer
var MatXVecBuffer
var Uniform_MultSet
#============================================================
# Called when the node enters the scene tree for the first time.
func _ready():
	var fps=FpsMeter.instantiate()
	add_child(fps)
	
	
	Bones=TheModel.mesh.surface_get_arrays(0)[Mesh.ARRAY_BONES]
	Weights=TheModel.mesh.surface_get_arrays(0)[Mesh.ARRAY_WEIGHTS]
	var Vertices=TheModel.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	
	for i in range(Vertices.size()):
		put_vertex_recorded(Vector3(0,0,0), Color.RED)
	#==========================================================
	var Vinput:= PackedFloat32Array([])
	var BIinput:= PackedInt32Array([])
	var Winput:= PackedFloat32Array([])
	Rinput= PackedFloat32Array([])
	Binput= PackedFloat32Array([])
	var matxmat_input:=PackedFloat32Array([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16])
	var matxvec_input:=PackedFloat32Array([1,1,1,1])


	for i in range(Vertices.size()):
		Vinput.append(Vertices[i][0])
		Vinput.append(Vertices[i][1])
		Vinput.append(Vertices[i][2])
		Vinput.append(1.0)
		
		BIinput.append(Bones[i*8])
		BIinput.append(Bones[(i*8)+1])
		BIinput.append(Bones[(i*8)+2])
		BIinput.append(Bones[(i*8)+3])
		BIinput.append(Bones[(i*8)+4])
		BIinput.append(Bones[(i*8)+5])
		BIinput.append(Bones[(i*8)+6])
		BIinput.append(Bones[(i*8)+7])
		
		Winput.append(Weights[i*8])
		Winput.append(Weights[(i*8)+1])
		Winput.append(Weights[(i*8)+2])
		Winput.append(Weights[(i*8)+3])
		Winput.append(Weights[(i*8)+4])
		Winput.append(Weights[(i*8)+5])
		Winput.append(Weights[(i*8)+6])
		Winput.append(Weights[(i*8)+7])
	
	for i in range(TheSkeleton.get_bone_count()):
		insert_into_rest_transforms(i)
		insert_into_bone_transforms(i)
		
	var Vinput_bytes:= Vinput.to_byte_array()
	var BIinput_bytes:= BIinput.to_byte_array()
	var Winput_bytes:= Winput.to_byte_array()
	var Rinput_bytes= Rinput.to_byte_array()
	var Binput_bytes= Binput.to_byte_array()
	var matxmat_input_bytes:=matxmat_input.to_byte_array()
	var matxvec_input_bytes:=matxvec_input.to_byte_array()
	
	VertBuffer = rd.storage_buffer_create(Vinput_bytes.size(), Vinput_bytes)
	OutPutBuffer = rd.storage_buffer_create(Vinput_bytes.size())
	BIndexBuffer = rd.storage_buffer_create(BIinput_bytes.size(), BIinput_bytes)
	WeightsBuffer = rd.storage_buffer_create(Winput_bytes.size(), Winput_bytes)
	RestsBuffer = rd.storage_buffer_create(Rinput_bytes.size(), Rinput_bytes)
	BonesBuffer = rd.storage_buffer_create(Binput_bytes.size(), Binput_bytes)
	MatXMatBuffer = rd.storage_buffer_create(matxmat_input_bytes.size())
	MatXVecBuffer = rd.storage_buffer_create(matxvec_input_bytes.size())
	
	var Vuniform := RDUniform.new()
	Vuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	Vuniform.binding = 0 
	Vuniform.add_id(VertBuffer)
	var OPuniform := RDUniform.new()
	OPuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	OPuniform.binding = 1
	OPuniform.add_id(OutPutBuffer)
	Uniform_VertSet = rd.uniform_set_create([Vuniform, OPuniform], shader, 0)
	
	var BIuniform := RDUniform.new()
	BIuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	BIuniform.binding = 0
	BIuniform.add_id(BIndexBuffer)
	var Wuniform := RDUniform.new()
	Wuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	Wuniform.binding = 1
	Wuniform.add_id(WeightsBuffer)
	Uniform_BIWSet = rd.uniform_set_create([BIuniform, Wuniform], shader, 1)
	
	var Runiform := RDUniform.new()
	Runiform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	Runiform.binding = 0
	Runiform.add_id(RestsBuffer)
	var Buniform := RDUniform.new()
	Buniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	Buniform.binding = 1
	Buniform.add_id(BonesBuffer)
	Uniform_BoneSet = rd.uniform_set_create([Runiform, Buniform], shader, 2)
	
	var MXMuniform:= RDUniform.new()
	MXMuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	MXMuniform.binding = 0
	MXMuniform.add_id(MatXMatBuffer)
	var MXVuniform:= RDUniform.new()
	MXVuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	MXVuniform.binding = 1
	MXVuniform.add_id(MatXVecBuffer)
	Uniform_MultSet = rd.uniform_set_create([MXMuniform, MXVuniform], shader, 3)
	#==========================================================

	

	TheSkin=TheModel.skin
	mdt.create_from_surface(TheModel.mesh, 0)

	for i in range(TheSkeleton.get_bone_count()):
		Fill_Bone_Params(i)
	
	#[a, b, c, d]  
	#[e, f, g, h] * [x, y, z, 1]=[(a*x + b*y + c*z + d*1), (e*x + f*y + g*z + h*1), (i*x + j*y + k*z + l*1), (1*1 + 1*1 + 1*1 + 1*1)].xyz
	#[i, j, k, l]
	#[1, 1, 1, 1]
	
	#display_mesh_traingles()
	#====================================================================================


#========================================================================================
func _process(_delta):
	var VertCount:= PackedFloat32Array([3212,0,0,0])
	var VertCount_bytes:= VertCount.to_byte_array()
	
	Binput.clear()
	for i in range(TheSkeleton.get_bone_count()):
		insert_into_bone_transforms(i)
	var update_bytes=Binput.to_byte_array()
	rd.buffer_update(BonesBuffer, 0, update_bytes.size(), update_bytes)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_set_push_constant(compute_list, VertCount_bytes, VertCount_bytes.size())
	rd.compute_list_bind_uniform_set(compute_list, Uniform_VertSet, 0)
	rd.compute_list_bind_uniform_set(compute_list, Uniform_BIWSet, 1)
	rd.compute_list_bind_uniform_set(compute_list, Uniform_BoneSet, 2)
	rd.compute_list_bind_uniform_set(compute_list, Uniform_MultSet, 3)
	rd.compute_list_dispatch(compute_list, 51, 1, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	var output_bytes := rd.buffer_get_data(OutPutBuffer)
	var output := output_bytes.to_float32_array()
	for i in range(point_mesh_list.size()):
		point_mesh_list[i].global_position=Vector3( output[(i*4)], output[(i*4)+1], output[(i*4)+2] )

#========================================================================================

func insert_into_rest_transforms(bone_indx):
	var the_transform=TheSkeleton.get_bone_global_rest(bone_indx).inverse()
	Rinput.append(the_transform.basis.x[0])
	Rinput.append(the_transform.basis.x[1])
	Rinput.append(the_transform.basis.x[2])
	Rinput.append(0)
	Rinput.append(the_transform.basis.y[0])
	Rinput.append(the_transform.basis.y[1])
	Rinput.append(the_transform.basis.y[2])
	Rinput.append(0)
	Rinput.append(the_transform.basis.z[0])
	Rinput.append(the_transform.basis.z[1])
	Rinput.append(the_transform.basis.z[2])
	Rinput.append(0)
	Rinput.append(the_transform.origin[0])
	Rinput.append(the_transform.origin[1])
	Rinput.append(the_transform.origin[2])
	Rinput.append(1.0)

func insert_into_bone_transforms(bone_indx):
	var the_transform=TheSkeleton.get_bone_global_pose(bone_indx)
	Binput.append(the_transform.basis.x[0])
	Binput.append(the_transform.basis.x[1])
	Binput.append(the_transform.basis.x[2])
	Binput.append(0)
	Binput.append(the_transform.basis.y[0])
	Binput.append(the_transform.basis.y[1])
	Binput.append(the_transform.basis.y[2])
	Binput.append(0)
	Binput.append(the_transform.basis.z[0])
	Binput.append(the_transform.basis.z[1])
	Binput.append(the_transform.basis.z[2])
	Binput.append(0)
	Binput.append(the_transform.origin[0])
	Binput.append(the_transform.origin[1])
	Binput.append(the_transform.origin[2])
	Binput.append(1.0)
	
func get_skinned_pt(vertex, vertex_indx):
	var bones=Bones.slice(vertex_indx*8, (vertex_indx*8)+8)
	var weights=Weights.slice(vertex_indx*8, (vertex_indx*8)+8)

	var t1=Create_transform(bones[0], (weights[0]))
	var t2=Create_transform(bones[1], (weights[1]))
	var t3=Create_transform(bones[2], (weights[2]))
	var t4=Create_transform(bones[3], (weights[3]))
	var t5=Create_transform(bones[4], (weights[4]))
	var t6=Create_transform(bones[5], (weights[5]))
	var t7=Create_transform(bones[6], (weights[6]))
	var t8=Create_transform(bones[7], (weights[7]))
		
	var final_transform=add_transforms8(t1, t2, t3, t4, t5, t6, t7, t8)
	var final_pos=final_transform*vertex
	
	return final_pos


func create_empty_triangle(vert1, vert2, vert3):
	put_segments(vert1, vert2, Color.RED, Color.BLUE, 0.005, 0.01)
	put_segments(vert2, vert3, Color.RED, Color.BLUE, 0.005, 0.01)
	put_segments(vert3, vert1, Color.RED, Color.BLUE, 0.005, 0.01)

func create_triangles(vert1, vert2, vert3, colour):
	
	var mesh=MeshInstance3D.new()
	var ArrMesh=ArrayMesh.new()
	add_child(mesh)
	
	var surftool=SurfaceTool.new()
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surftool.add_vertex(vert1)
	surftool.add_vertex(vert2)
	surftool.add_vertex(vert3)
	surftool.add_vertex(vert1)
	surftool.add_vertex(vert3)
	surftool.add_vertex(vert2)
	surftool.generate_normals()
	ArrMesh=surftool.commit()
	mesh.mesh=ArrMesh
	
	var mat=StandardMaterial3D.new()
	mat.albedo_color=colour
	mesh.mesh.surface_set_material(0,mat)

 #============================
 #| Vector4( x, y, z, w )    |
 #| Quaternion( x, y, z, w ) |
 #============================

func Create_transform(bone_indx, weight):
	var Bone_transform=TheSkeleton.get_bone_global_pose(bone_indx)
	var Bone_rest_transform=TheSkeleton.get_bone_global_rest(bone_indx).inverse()
	return Bone_transform*Bone_rest_transform*weight

func add_transforms8(t1, t2, t3, t4, t5, t6, t7, t8):
	var xbasis=t1.basis.x+t2.basis.x+t3.basis.x+t4.basis.x+t5.basis.x+t6.basis.x+t7.basis.x+t8.basis.x
	var ybasis=t1.basis.y+t2.basis.y+t3.basis.y+t4.basis.y+t5.basis.y+t6.basis.y+t7.basis.y+t8.basis.y
	var zbasis=t1.basis.z+t2.basis.z+t3.basis.z+t4.basis.z+t5.basis.z+t6.basis.z+t7.basis.z+t8.basis.z
	var Origin=t1.origin+t2.origin+t3.origin+t4.origin+t5.origin+t6.origin+t7.origin+t8.origin
	
	return Transform3D(xbasis, ybasis, zbasis, Origin)

func _unhandled_input(_event):
	if Input.is_action_pressed("See_Bones"):#Shift+B
		for i in point_mesh_list:
			i.queue_free()
		point_mesh_list.clear()


func put_vertex(pos, colour, vertscale):
	var point=MeshInstance3D.new()
	var point_mesh=BoxMesh.new()
	point.mesh=point_mesh
	var mat=StandardMaterial3D.new()
	mat.albedo_color=colour
	point.mesh.surface_set_material(0,mat)
	metarig.add_child(point)
	point.scale=Vector3(vertscale,vertscale,vertscale)
	point.global_position=pos
	return point

func put_vertex_recorded(pos, colour):
	var point=MeshInstance3D.new()
	var point_mesh=BoxMesh.new()
	point.mesh=point_mesh
	var mat=StandardMaterial3D.new()
	mat.albedo_color=colour
	point.mesh.surface_set_material(0,mat)
	add_child(point)
	point_mesh_list.append(point)
	point.scale=Vector3(0.02,0.02,0.02)
	point.global_position=pos
	return point

func put_vertex_global(pos, colour):
	var point=MeshInstance3D.new()
	var point_mesh=BoxMesh.new()
	point.mesh=point_mesh
	var mat=StandardMaterial3D.new()
	mat.albedo_color=colour
	point.mesh.surface_set_material(0,mat)
	add_child(point)
	point.scale=Vector3(0.05,0.05,0.05)
	point.global_position=pos
	return point

func put_segments(pt1, pt2, vertexcolour, edgecolour, edgesize, vertsize):
	var bone_start=put_vertex(pt1, vertexcolour, vertsize)
	var bone_end=put_vertex(pt2, vertexcolour, vertsize)

	var Bone_Mesh=RedBox.instantiate()
	add_child(Bone_Mesh)
	var mat=StandardMaterial3D.new()
	mat.albedo_color=edgecolour
	Bone_Mesh.get_child(0).mesh.surface_set_material(0,mat)
			
	var direct=bone_start.global_position.direction_to(bone_end.global_position)
	var dist=bone_start.global_position.distance_to(bone_end.global_position)
			
	Bone_Mesh.global_position=bone_start.global_position+(direct*(dist/2))
	Bone_Mesh.look_at(bone_end.global_position)
	Bone_Mesh.set_scale(Vector3(edgesize, edgesize,(bone_start.global_position.distance_to(bone_end.global_position)) ))

func Fill_Bone_Params(bone_indx):
	var bone_children=TheSkeleton.get_bone_children(bone_indx)
	var bone_line_segment=[]
	if bone_children.size()>0:
		for children in bone_children:
			bone_segment_vectors.append([metarig.to_global(TheSkeleton.get_bone_global_pose(bone_indx).origin), metarig.to_global(TheSkeleton.get_bone_global_pose(children).origin)])
			bone_line_segment.append(Bsegment_count)
			Bsegment_count+=1
		BonesAndSegments[bone_indx]=bone_line_segment
		

func display_mesh_traingles():
	var colour_list=[Color.RED, Color.BLUE, Color.GREEN]
	var vertex_list=[]
	var colorcount=1
	var vert_dict={}
	for faces in range(mdt.get_face_count()):
		vert_dict[mdt.get_face_vertex(faces, 0)]=mdt.get_vertex(mdt.get_face_vertex(faces, 0))
		vert_dict[mdt.get_face_vertex(faces, 1)]=mdt.get_vertex(mdt.get_face_vertex(faces, 1))
		vert_dict[mdt.get_face_vertex(faces, 2)]=mdt.get_vertex(mdt.get_face_vertex(faces, 2))
		var fpt1=get_skinned_pt(mdt.get_vertex(mdt.get_face_vertex(faces, 0)), mdt.get_face_vertex(faces, 0))
		var fpt2=get_skinned_pt(mdt.get_vertex(mdt.get_face_vertex(faces, 1)), mdt.get_face_vertex(faces, 1))
		var fpt3=get_skinned_pt(mdt.get_vertex(mdt.get_face_vertex(faces, 2)), mdt.get_face_vertex(faces, 2))
		
		create_empty_triangle(fpt1, fpt2, fpt3)
		create_triangles(fpt1, fpt2, fpt3, colour_list[colorcount%3])
		colorcount+=1






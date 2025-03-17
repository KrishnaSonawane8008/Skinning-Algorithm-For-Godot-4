#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) buffer restrict readonly VertexBuffer {
    //buffer input should contain a PackedFloat32Array with sets of 4 inputs
    //in the set, the first 3 should be the x,y,z coords and the last one should be '1.0'
    vec4 data[];
}
vert_buffer;

layout(set = 0, binding = 1, std430) restrict buffer OutputBuffer {
    vec4 data[];
}
op_buffer;

layout(set = 1, binding = 0, std430) buffer restrict readonly BindexBuffer {
    //input should contain 8 bone indices per vertex, these bone indices will be used to access the
    //bone transforms from BonesBuffer and RestsBuffer 
    int data[];
}
Bindex_buffer;

layout(set = 1, binding = 1, std430) buffer restrict readonly WeightBuffer {
    //input should contain 8 bone weights per vertex, these bone weights pair(index wise) with 
    //bone transforms and rest transforms 
    float data[];
}
weight_buffer;

layout(set = 2, binding = 0, std430) buffer restrict readonly RestsBuffer {
    //for example:- for the HumanModel.blend that you were using, there must be 72 entries to this matrix in total
    //input should contain the rest transforms of bones in this maner:
    //mat4 data[ Transform3d.basis.x[0], Transform3d.basis.x[1], Transform3d.basis.x[2], 1.0, ->column1
    //           Transform3d.basis.y[0], Transform3d.basis.y[1], Transform3d.basis.y[2], 1.0, ->column2
    //           Transform3d.basis.z[0], Transform3d.basis.z[1], Transform3d.basis.z[2], 1.0, ->column3
    //           Transform3d.origin[0],  Transform3d.origin[1],  Transform3d.origin[2],  1.0, ->column4
    //           ........]
    //above is an example of just a single entry in the buffer, there should be one per bone
    mat4 data[];
}
rest_buffer;

layout(set = 2, binding = 1, std430) buffer restrict readonly BonesBuffer {
    //the input should be in the same 'format' as provided above,
    //just the entries should be of the current bone transforms 
    mat4 data[];
}
bone_buffer;

layout(set = 3, binding = 0, std430) restrict buffer MatXMatBuffer {
    mat4 data[];
}
mat_x_mat;

layout(set = 3, binding = 1, std430) restrict buffer MatXVecBuffer {
    vec4 data[];
}
mat_x_vec;

layout(push_constant, std430) uniform Params {
    float Vbuffer_size;

}
params;

// The code we want to execute in each invocation
void main() {
    uint index=gl_GlobalInvocationID.x;
    if(index>=params.Vbuffer_size){
        return;
    }

    mat4 mat_addition=((bone_buffer.data[Bindex_buffer.data[index*8]])*(rest_buffer.data[Bindex_buffer.data[index*8]]))*(weight_buffer.data[index*8]);
    mat_addition+=((bone_buffer.data[Bindex_buffer.data[index*8+1]])*(rest_buffer.data[Bindex_buffer.data[index*8+1]]))*(weight_buffer.data[index*8+1]);
    mat_addition+=((bone_buffer.data[Bindex_buffer.data[index*8+2]])*(rest_buffer.data[Bindex_buffer.data[index*8+2]]))*(weight_buffer.data[index*8+2]);
    mat_addition+=((bone_buffer.data[Bindex_buffer.data[index*8+3]])*(rest_buffer.data[Bindex_buffer.data[index*8+3]]))*(weight_buffer.data[index*8+3]);
    mat_addition+=((bone_buffer.data[Bindex_buffer.data[index*8+4]])*(rest_buffer.data[Bindex_buffer.data[index*8+4]]))*(weight_buffer.data[index*8+4]);
    mat_addition+=((bone_buffer.data[Bindex_buffer.data[index*8+5]])*(rest_buffer.data[Bindex_buffer.data[index*8+5]]))*(weight_buffer.data[index*8+5]);
    mat_addition+=((bone_buffer.data[Bindex_buffer.data[index*8+6]])*(rest_buffer.data[Bindex_buffer.data[index*8+6]]))*(weight_buffer.data[index*8+6]);
    mat_addition+=((bone_buffer.data[Bindex_buffer.data[index*8+7]])*(rest_buffer.data[Bindex_buffer.data[index*8+7]]))*(weight_buffer.data[index*8+7]);


    op_buffer.data[index]=mat_addition*vert_buffer.data[index];
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
    
}
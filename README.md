This project was made with Godot v4.2.1 stable
<br>
<h1>Introduction</h1>
<h3>What is a Skinning?</h3>
If you have seen a 3D model being animated(other than translated, rotated or scaled), then you have witnessed mesh skinning. The idea is to continuously deform the 3d model in such a way that it appears animated.
<br>
This is usually done with the help of a skeleton(virtual skeleton, the other one will get you arrested). A skeleton is bascially like a normal skeleton, it has multiple bones, each connected to some others vis joints. The Joints can be then arranged in any pose that the animator wishes. 
Before posing, the skeleton is placed inside the 3D model, then an algorithm called the skinning algorithm "maps" the model onto the skeleton. When the skeleton is posed, the corresponding mesh is also deformed to mathch the skeleton.
<br>
The game engine Godot 4 also uses skeletons to animate 3d models. Here you can see that the skeleton is highlited in yellow, inside the engine,and how it is used to deform the 3D mesh:
<br>
<br>
<video src="https://github.com/user-attachments/assets/2c185548-9543-4356-bfbf-73c9cd040a35" ></video>
<br>
As you can see in the video before posing the skeleton, the mesh was in rest pose(or as it was created in the 3d modelling software), and once the skeleton was posed the mesh was deformed with it or more specifically the vertices of the mesh(only around the rotated bone and other bones connected to it) moved with the rotated bones. This movement of vertices along with the bones of the skeleton is called mesh skinning. A skinning algorithm is just that, a program which takes in the input as the vertices of mesh in rest pose, the pose and layout of the skeleton in rest and the current pose of the skeleton to output the deformed mesh. In the video above, we can see the skinning algorithm implemented by the Godot 4 game engine at work.
<br>
<h3>How a Skinning algorithm works</h3>
Now as you know what is skinning, lets talk about a program that can implement it for us. The skinning algorithm needs the initial mesh, rest skeleton pose, new skeleton pose and vertex weight/weights to produce the deformed mesh:
<br>
<li>Initial mesh: Mesh without any deformation.</li>
<li>Rest skeleton pose: Initial skeleton pose.</li>
<li>New skeleton pose: Pose of the skeleton after it has been altered by the animator</li>
<li>Vertex weight/weights: a single or multiple(generally four) floating point numbers whoes addition equals to 1.0</li>
<br>
This formula given in <a href="https://skinning.org/direct-methods.pdf">this</a> pdf shows how the deformed vertex position is obtained given the above input according the "Linear Blend Skinning Algorithm"(a type of skinning algorithm).
<h1>The Problem</h1>
<h3>Godot 4 Doesn't provide the Deformed Vertex Positions</h3>
My problem began when i wanted to access the deformed vertex positions of a mesh in one of my Godot projects, Godot 4 provides the MeshDataTool class which gives you access to individual vertices of a mesh, but the position of the vertices obtained from MeshDataTool for a mesh(deformed by the godot 4 skinning algo) are not at the deformed position, rather at the position of rest.
<br>
This video describes my problem perfectly (Vertex positions in 3D space are represented by red cubes):
<br>
<br>
Vertex positions obtained from MeshDataTool at skeleton rest pose:
<br>
<video src="https://github.com/user-attachments/assets/7b587fdb-c9d3-410f-aaec-4c0adfa02412"></video>
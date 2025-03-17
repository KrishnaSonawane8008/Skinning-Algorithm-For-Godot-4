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
<br>
Vertex positions obtained from MeshDataTool at new pose:
<br>
<video src="https://github.com/user-attachments/assets/40e6a987-7c71-4575-97dc-36b2af2499fe"></video>
<br>
As you can see that the position obtained from the MeshDataTool after deformation is not the same as the output of the Godot skinning algo. And its not as if I haven't tried to make the MeshDataTool work, i tried setting the pose of the model before using the create_from_surface() method of the MeshDataTool, i have tried changing the bone pose from the MeshDataTool and then getting the vertex position, I have tried the SurfaceTool class to remake the entire geometry from the data( i got from the MeshDataTool) and then using the MeshDataTool to get the vertex positions, NOTHING WORKS!! plus i found a few comments saying that it was not possible to get deformed positions of vertice in the engine, so... i gave up trying the MeshDataTool way.
<br>
<h1>The Solution I Came Up With</h1>
So if Godot cannot provide me the deformed positions, then i decided to make my own deformed positions, i mean all the data needed for any skinning algo is already given to me by the MeshDataTool class, i just need to run them through the skinning algorithm formula to get the deformed positions.
<br>
<h3>But which skinning algorithm to use?</h3>
Implementing a skinning algorithm can be managed, but the problem was selecting one to implement, like there's the basic one called "Linear Blend Skinning" used by a lot of game engines, then there's one called "Approximate Nurbs Skinning", then there are those implemented by 3D modelling software such as Maya and Blender, plus there are those made custom by other people. 
<br>
The obvious question comes to mind, "Which skinning algo does Godot 4 use?". Now, I'am not lying when i say this, i was not abled to find the answer to that question, atleast not a "sure" answer. There is very less discussion about this topic in the godot community, and some people just say that its not possible. Well so i tried looking at different skinning algos and then i went through the godot engine source code(perks of opensource) to look for the code files which look similar to the formulas given in those skinning algos(i bascially searched the words skin, skeleton, bone, weight/weights, skinning,...etc through vscode). I was not able to find anything conclusive, so i just thought of trying the basic Linear Blend Skinning algo to see the accuracy of the results and then i thought of playing with the code a bit to get to better results.
<br>
<h3>Linear Blend Skinning</h3>
The requirements of linear blend skinning are mentioned above, two of those requirements are influencing bones and weights for a particular vertex. The MeshDataTool kindly provided me with those two requirements in the form of two arrays, one conatining bone indices and other containing vertex weights, the formula in the skinning algo uses 4 bones and vertex weights per vertex so i just selected elements in consecutive groups of 4 from the arrays, this was not the issue, the problem started when i implemented the Linear Blend Skinning algo in GDScript and gave it mesh data tool result as input. The output produced was, lets just say, VERY WRONG. The vertices were too far deformed  from the intended positions, i then tried a few different combinations of the formula till i lost hope again.
<br>
Now you don't understand the severity of the problem, if i cannot find a skinning algo which gives out a good result with the provided input from the MeshDataTool, i'am bascially stuck without any opening in sight except for trying a different game engine, you don't understand my mental state at that point, i just entered the game dev scene and i was one month into this project with barely any results, and I'am trying to find the solution to a problem which doesn't even exist in other engines like Unity(Unity introduced their runtime fees around this time so......probably Unreal would have been the next option), was i just wasting my time?. Then one day, when i was only one more dissapointing search result away from shifting engines i found <a href="https://www.youtube.com/watch?v=5D7oUKrjjao">this</a> video by <a href="https://www.youtube.com/@NitroxNova">Nitrox Nova</a> which gave me some idea about the vertex weights and their relation with skeleton bones.
<br>
SO, it turns out that Godt uses 8 vertex weights and bones per vertex for skeletons containing bones with more than 1 children or connected bones for a single joint instead of the afore mentioned 4. Why does Godot use 8 vertex weights and bones per vertex? GOOD QUESTION!!!
<br>
<h3>The Solution</h3>
When the issue with number of influencers per vertex was resolved, the output was a success. Linear Blend Skinning provided me with the exact deformed position of the vertices after posing the skeleton:
<br>

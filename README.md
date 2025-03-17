This project was made with Godot v4.2.1 stable
<br>
<h1>Introduction</h1>
<h3>What is a Skinning?</h3>
If you have seen a 3D model being animated(other than translated, rotated or scaled), then you have witnessed mesh skinning. The idea is to continuously deform the 3d model in such a way that it appears animated.
<br>
This is usually done with the help of a skeleton(virtual skeleton, the other one will get you arrested). A skeleton is bascially like a normal skeleton, it has multiple bones, each connected to some others vis joints. The Joints can be then arranged in any pose that the animator wishes. 
Before posing, the skeleton is placed inside the 3D model, then an algorithm called the skinning algorithm "maps" the model onto the skeleton. When the skeleton is posed, the corresponding mesh is also deformed to mathch the skeleton.
<br>
The game engine Godot 4 also uses skeletons to animate 3d models:
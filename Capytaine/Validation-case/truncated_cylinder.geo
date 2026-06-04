SetFactory("OpenCASCADE");

// -------------------- Parameters --------------------
DefineConstant[
  r         = {10.0, Name "Cylinder/Radius r (m)"},
  draft     = {10.0, Name "Cylinder/Submerged draft below z=0 (m)"},
  freeboard = {0.1,  Name "Cylinder/Freeboard above z=0 (m)"},
  lc        = {0.8,  Name "Mesh/Characteristic length lc (m)"}
];

// -------------------- Geometry definition --------------------
zTop = freeboard;     // top at +0.1 m
zBot = -draft;        // bottom at -10 m
H    = zTop - zBot;   // total height = 10.1 m

x0 = 0;
y0 = 0;

// -------------------- Single vertical cylinder --------------------
v1 = newv;
Cylinder(v1) = {x0, y0, zBot, 0, 0, H, r};

// -------------------- Mesh controls --------------------
Mesh.CharacteristicLengthMin = lc;
Mesh.CharacteristicLengthMax = lc;

// -------------------- Physical groups --------------------
Physical Volume("SingleCylinderBody") = {v1};

surfs[] = Boundary{ Volume{v1}; };
Physical Surface("SingleCylinderBody_Surfaces") = {surfs[]};
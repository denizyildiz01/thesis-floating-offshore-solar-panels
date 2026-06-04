SetFactory("OpenCASCADE");

// -------------------- Parameters --------------------
DefineConstant[
  L     = {17.7, Name "Array/Spacing L (m)"},
  r     = {1.5,  Name "Floater/Cylinder radius r (m)"},
  draft = {3.1,  Name "Floater/Submerged draft below z=0 (m)"},
  freeboard = {6.9, Name "Floater/Freeboard above z=0 (m)"},
  lc    = {0.5,  Name "Mesh/Characteristic length lc (m)"}
];

zTop = freeboard;     // top at +freeboard
zBot = -draft;        // bottom at -draft
H    = zTop - zBot;

x1 = -L/2;  x2 =  L/2;
y1 = -L/2;  y2 =  L/2;

// -------------------- 4 cylinders (as tools for union) --------------------
v1 = newv; Cylinder(v1) = {x1, y1, zBot, 0, 0, H, r};
v2 = newv; Cylinder(v2) = {x2, y1, zBot, 0, 0, H, r};
v3 = newv; Cylinder(v3) = {x2, y2, zBot, 0, 0, H, r};
v4 = newv; Cylinder(v4) = {x1, y2, zBot, 0, 0, H, r};

// -------------------- Union into ONE volume --------------------
// Result is a new volume; inputs are deleted
rigid[] = BooleanUnion{ Volume{v1, v2, v3, v4}; Delete; }{};

// -------------------- Reference “rigid body” link lines (optional) --------------------
// These lines do NOT change the solid. They’re just 1D entities you can export/tag.
p1 = newp; Point(p1) = {x1, y1, 0, lc};
p2 = newp; Point(p2) = {x2, y1, 0, lc};
p3 = newp; Point(p3) = {x2, y2, 0, lc};
p4 = newp; Point(p4) = {x1, y2, 0, lc};

l12 = newl; Line(l12) = {p1, p2};
l23 = newl; Line(l23) = {p2, p3};
l34 = newl; Line(l34) = {p3, p4};
l41 = newl; Line(l41) = {p4, p1};
l13 = newl; Line(l13) = {p1, p3};
l24 = newl; Line(l24) = {p2, p4};

// -------------------- Mesh controls --------------------
Mesh.CharacteristicLengthMin = lc;
Mesh.CharacteristicLengthMax = lc;

// -------------------- Physical groups --------------------
Physical Volume("RigidFloaterBody") = {rigid[]};

surfs[] = Boundary{ Volume{rigid[]}; };
Physical Surface("RigidFloaterBody_Surfaces") = {surfs[]};

Physical Line("RigidLinks") = {l12, l23, l34, l41, l13, l24};
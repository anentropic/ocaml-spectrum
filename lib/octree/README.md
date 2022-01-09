We want to implement the voronoi-octree search described here:  
https://link.springer.com/content/pdf/10.1007/s00138-017-0889-4.pdf

- https://en.wikipedia.org/wiki/Voronoi_diagram
- https://en.wikipedia.org/wiki/Delaunay_triangulation

> Contrary to traditional octrees, where voxels are split
> based on the number of contained data points, we split each
> voxel based on the number of intersecting Voronoi cells

A Voronoi diagram and a Delauney triangulation are duals, it looks like there are more implementations of Delauney triangulation than the former.

e.g. `ocamlgraph` lib provides https://backtracking.github.io/ocamlgraph/ocamlgraph/Graph/Delaunay/

The interface is functor-ised, we need to define a 3D version of https://backtracking.github.io/ocamlgraph/ocamlgraph/Graph/Delaunay/FloatPoints/

...making it more of a tetrahedral-isation.

The 3D Voronoi dual will have polyhedral cells of varying numbers of sides.

The algo, roughly:

- pre-compute voronoi cells of the target points
- the octree is subdivided until no leaves intersect multiple cells, i.e. each leaf cube of the octree will cover a sub-region of one voronoi cell only
- octree is used to quickly find the voronoi cell that the query point falls into... 
- centre point of th corresponding voronoi cell is the nearest neighbour

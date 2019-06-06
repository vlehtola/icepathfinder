ICEPATHFINDER
Finnish Geospatial Research Institute, Navigation department
Ville Lehtola 2017

ICEPATHFINDER is a Matlab-program that finds the shortest path for ships, given the sea ice conditions and a ship model. Topological shortest path is found with A*. A* refers to the known algorithm by that name, and accordingly the shortest path is found using a mix of Dijkstra's algorithm and a heuristic to estimate the route to the end point.

Please cite:
Lehtola V et al., Finding safe and efficient shipping routes in ice-covered waters: A framework and a model, Cold Regions Science and Technology, 2019, 10.1016/j.coldregions.2019.102795
https://www.sciencedirect.com/science/article/pii/S0165232X18304269

INPUT

The sea is spatially discretized into a 2D rectangular grid, with cells of width 1 x 1 nautical mile. Sea depth is from General Bathymetric Chart of the Oceans (GEPCO, www.gepco.net ).

Sea ice conditions are obtained from HELMI-model (HELsinki Multi category Ice model). HELMI [Haapala, 2000; Haapala et al., 2005; Mårtensson et al., 2012] includes the ice thickness distribution, i.e., ice concentrations of variable thickness categories, and mechanical redistribution of the ice due to deformations and ice strength. Beside the ability to explicitly model deformed ice, HELMI allows, furthermore, for a more detailed description of the ice strength.

Ship models include estimated speeds at different ice conditions (obtained from Aalto University Marine Technology group), and a safe depth.

The user may choose a highest acceptable stuckThreshold, which eliminates heavily iced areas from the A* optimization.

OUTPUT

The shortest path is given in Google Earth kml-file format displayable in that program. Coordinates, speeds, and times are available also in ASCII format.

LIST OF CONTRIBUTORS

Finnish Geospatial Research Institute, Navigation department

Ville Lehtola, Jakub Montewka, Robert Guinness

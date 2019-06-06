function [minX, maxX, minY, maxY]=calculateSearchArea(originX, originY, destinationX, destinationY, margin)
% CALCULATESEARCHAREA defines a search area for route finding algorithm based on coordinates of points of departure and arrival,
% adding marging to each corner. 
% [minX, maxX, minY, maxY]=calculateSearchArea(originX, originY, destinationX, destinationY)
% 
% INPUTS:
% search.origin X,Y       -  X,Y coordinates of an point of departure - origin of
%                            a route
% margin                  -  a buffer around origin and desitation points given in
%                            nautical miles
% search.destination X,Y  -  X,Y coordinates of an point of destination - the end
% 
% OUTPUTS:
% min X,Y   X,Y coordinates of a search area for an algorithm
%
% OTHER NOTES:

minX=min(originX,destinationX)-ceil(margin/4);
maxX=max(originX,destinationX)+ceil(margin/4);

minY=min(originY,destinationY)-ceil(margin/2);
maxY=max(originY,destinationY)+ceil(margin/2);

% minX=min(originX,destinationX)-ceil(margin);
% maxX=max(originX,destinationX)+ceil(margin);
% 
% minY=min(originY,destinationY)-ceil(margin);
% maxY=max(originY,destinationY)+ceil(margin);


end

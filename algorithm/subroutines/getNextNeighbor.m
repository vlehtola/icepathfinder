function neighbor = getNextNeighbor(j, currentNode)
%% Ville Lehtola 2017
% Function defining the distances&coordinates between neighboring nodes.
% Note that since the grid at 60 latitude is 0.5 x 0.25 nautical miles in
% latitude and longitude directions, this needs to be taken into account
% here. So, y-directional translations are halved and the diagonal 
% translation distance is 1.1180. This is essential only for defining the
% correct time step during the run. Regardless, optimal route solution can
% be guaranteed since the x and y are orthogonal.
% NOTE: (lat,long) ^= (y,x)
    switch j
        case 1
                neighbor.x = currentNode.x;
                neighbor.y = currentNode.y+1;
                neighbor.d = 1;
        case 2
                neighbor.x = currentNode.x;
                neighbor.y = currentNode.y-1;
                neighbor.d = 1;
        case 3
                neighbor.x = currentNode.x+1;
                neighbor.y = currentNode.y;
                neighbor.d = 0.5;
        case 4
                neighbor.x = currentNode.x-1;
                neighbor.y = currentNode.y;
                neighbor.d = 0.5;
        case 5
                neighbor.x = currentNode.x+1;
                neighbor.y = currentNode.y+1;
                neighbor.d = 1.1180; %1.4142;
        case 6
                neighbor.x = currentNode.x+1;
                neighbor.y = currentNode.y-1;                            
                neighbor.d = 1.1180; %1.4142;
        case 7
                neighbor.x = currentNode.x-1;
                neighbor.y = currentNode.y-1;   
                neighbor.d = 1.1180; %1.4142;
        case 8
                neighbor.x = currentNode.x-1;
                neighbor.y = currentNode.y+1;
                neighbor.d = 1.1180; %1.4142;             
        otherwise
            disp('Error!')
    end
end
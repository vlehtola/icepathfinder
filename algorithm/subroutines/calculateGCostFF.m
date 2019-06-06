function [gCost] = calculateGCostFF(x1,y1,x2,y2,d, inverseSpeedDynamic)    
%% Ville Lehtola 2017
% This function returns a computational GCost
% d is originally obtained from getNextNeighbor()
    iv = 0.5* ( inverseSpeedDynamic(x1,y1) + inverseSpeedDynamic(x2, y2) );    
    gCost = d*iv;       % multiply with distance d between grid cells
end
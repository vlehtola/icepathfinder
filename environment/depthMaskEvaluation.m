 function [depthMask,continentMask] = depthMaskEvaluation(env_path, in_path, safeDepth)
%DEPTHMASKEVALUATION determnines two masks one for depth the other for continents. 
% INPUT
%   depth - GEBCO 30 arc-second global grid of elevations in meters
%   obtained as an array for the Baltic and North Sea from http://www.gebco.net/data_and_products/gridded_bathymetry_data/
%   safe depth of water in meters, determined by the user

%OUTPUT
%   depthMask
%   continentMask

load(strcat(env_path, '/depth.mat'));
maskValue = -safeDepth;

[numRows, numCols] = size(depth);
depthMask = true(numRows, numCols);
% sufficient depth = 0; insufficient depth = 1
for i = 1:numCols
    [rows, cols] = find(depth(:,i)<=maskValue);
    depthMask(rows,i)=0;
end

[numRows, numCols] = size(depth);
continentMask = false(numRows, numCols);
% continent is defined as mass of land at the elevation of sea level
% and higher (=> 0m)
for i = 1:numCols
    [rows, cols] = find(depth(:,i)>=0);
    continentMask(rows,i)=1;
end

%save(['environment/maskFull' num2str(abs(maskValue))],'depthMask','continentMask');
% This line is removed so the heavy files with bathymetry are not stored
% for each and every draft of a ship.

end

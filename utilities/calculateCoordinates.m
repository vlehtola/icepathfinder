% function [longitude, latitude] = calculateCoordinates()
%     latitude = zeros(2400,1);
%     longitude = zeros(4800,1);
% 
%     for i = 1:4800
%         longitude(i) = -6 + (1/120) * (i-1);
%     end
%     longitude = repmat(longitude',2400,1);
% 
%     for j = 1:2400
%         latitude(j) = 70 - (1/120) * (j-1);
%     end
%     latitude = repmat(latitude,1,4800);
% end

 
function [longitude, latitude] = calculateCoordinates(LatN, LongW, LatRows, LongCols)
% CALCULATECOORDINATES calculates the Lat, Long grid of a given size and given resolution.
% [longitude, latitude] = calculateCoordinates(LatN, LongW, LatRows, LongCols)
% 
% INPUTS:
% LatN denotes the northernmost corner of the grid
% LongW denotes the westernmost corner of the grid
% LatRows denotes the number of rows in the grid
% LongCols denotes the number of columns in the grid
%
% OUTPUTS:
% longitude A matrix of size LatRows x LongCols specifying the longitude of
%           each grid point
% latitude  A matrix of size LatRows x LongCols specifying the latitude of
%           each grid point
%
% OTHER NOTES:
% The resolution of the grid is constant 30 arc-second (1/120), and it
% comes from GEBCO
%
    latitude = zeros(LatRows,1);
    longitude = zeros(LongCols,1);

    for i = 1:LongCols
        longitude(i) = LongW + (1/120) * (i-1);
    end
    longitude = repmat(longitude',LatRows,1);
    longitude = fliplr(longitude');

    for j = 1:LatRows
        latitude(j) = LatN - (1/120) * (j-1);
    end
    latitude = repmat(latitude,1,LongCols);
    latitude = fliplr(latitude');
end
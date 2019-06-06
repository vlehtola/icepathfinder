function integratedTimeMap(env_path, in_path, out_path)
%%  ICEPATHFINDER: find the fastest ship route given certain ice conditions
%   v1.1      1.11.2017     V.V.Lehtola              
%   Main program: integratedTimeMap: compute the time for different
%   routes.
%
%   Code handles all Baltic SW(2727,809), NE(4369,1919) of GEBCO, with HELMI-data as raw input
%   and with over 100-fold speed up compared to Guinness et al. 2014 Astar and
%   initialization. Astar: separated the topological routing problem and the sub-cell interpolation
%   problems so that the latter is done in post-optimization, and provides
%   the global minimum. Gcost calculation is separated so that only computational units are employed
%   in the loop, and a conversion to real units is done in the
%   post-computation phase. init: path end points to the source and the target are found
%   by using closest navigable depths (GEBCO). Stuck probabilities are handled 'rigorously' with
%   binomial confidence interval to increase the time spent in each grid cell.
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <https://www.gnu.org/licenses/>.
    
%% define environmental variables
if (nargin == 0)
    folder = '/work/stormwinds/icepathfinder/'; % change as needed
    env_path = fullfile(folder, 'environment');
    in_path = fullfile(folder, '.');
    out_path = fullfile(folder, 'results');
end

mkdir(out_path);
copyfile('INPUT_icepathfinder.txt', out_path);        % store the input

%% runtime setup
if (isdeployed == 0) 
    clc
    %clear all
    close all
end

tic                 % start the clock

profile off         % profiling the code
    
%% Create figure
%h = figure;

%% Initializing map grids
[search, latitude, longitude, inverseSpeed, navigationGrid, drawUpdates, CPUstartTime,speed,stuck] = init(env_path, in_path);

% debug tmp disabled by VL
%writeWeatherXML(speed, stuck, navigationGrid, iceDataTimes, latitude, longitude, strcat(out_path,'/OUTSpeedStuckData.xml'));

runMainLoop = true;
% if there is a file, debug stuff
if (false && exist('INintegratedPathAndSpeedArray.mat', 'file') == 2 )
    runMainLoop = false;
    fprintf('Found pathAndSpeedArray.mat .. skipping Astar and loading the path!\n');
    load('INintegratedPathAndSpeedArray.mat', 'pathAndSpeedArrayAB');
end

if (runMainLoop)
    %% Starting A* algorithm
    fprintf('Starting A* algorithm...')
    heuristic = false;
    [pathMatrix, pathAndSpeedArrayAB, costMatrixAB, timeCoordinateSpeedMatrix, indexOfSpeedMatrixAtWaypointAB] = Astar(search, inverseSpeed, navigationGrid, drawUpdates, CPUstartTime, env_path, in_path, heuristic);

    % swap origin and destination, and re-run
    tmpX = search.originX;
    tmpY = search.originY;
    search.originX = search.destinationX;
    search.originY = search.destinationY;
    search.destinationX = tmpX;
    search.destinationY = tmpY;

    % keep the time step indices fixed during the reverse run. For this,
    % merge a speed map that contains only one pseudo-timestep    
        
    tiInverseSpeed = zeros(size(indexOfSpeedMatrixAtWaypointAB));        % 2D initially
    for i=1:timeCoordinateSpeedMatrix                
        timeMask = indexOfSpeedMatrixAtWaypointAB;
        timeMask(timeMask~= i) = 0;
        timeMask(timeMask== i) = 1;
        % timeMask is now a binary matrix.
        timeMask = timeMask .* inverseSpeed(:,:,i);
        tiInverseSpeed = tiInverseSpeed + timeMask;         % time step values
    end
    % fill the remaining zeros with the last time step (farthest from the start)
    timeMask = -tiInverseSpeed;         % free value 1 for assignment
    timeMask(timeMask==0) = 1;
    timeMask(timeMask~=1) = 0;      % binary matrix
    timeMask = timeMask .* inverseSpeed(:,:,timeCoordinateSpeedMatrix);
    tiInverseSpeed = tiInverseSpeed + timeMask;
    
    % keep the third dimension, which cannot exist in matlab as singleton
    tiInverseSpeed = repelem(tiInverseSpeed, 1, 1, 2);
    
    [pathMatrix, pathAndSpeedArrayBA, costMatrixBA, timeCoordinateSpeedMatrix, indexOfSpeedMatrixAtWaypointBA] = Astar(search, tiInverseSpeed, navigationGrid, drawUpdates, CPUstartTime, env_path, in_path, heuristic);
    save(strcat(out_path,'/integratedCostMatrix.mat'), 'costMatrixAB', 'costMatrixBA');   % calculated costs
    save(strcat(out_path,'/integratedTimeIndexMatrix.mat'), 'indexOfSpeedMatrixAtWaypointAB', 'indexOfSpeedMatrixAtWaypointBA', 'tiInverseSpeed'); % time step indices
    save(strcat(out_path,'/integratedPathAndSpeedArray.mat'), 'pathAndSpeedArrayAB', 'pathAndSpeedArrayBA');    % use this later

end


%% sub-cell geometric optimization to overcome the limitations of 2D grid
% also reduces the number of points in a path
[ optimizedPath, stepsAndCosts] = subCellGeometricOptimization(pathAndSpeedArrayAB, latitude, longitude, navigationGrid, tiInverseSpeed);
fprintf('\n subCell optimization complete.\n');

%% compute the physical parameters for the route
[route, pathLatLon, pathLength, pathSpeed, pathTime] = physicalRoute(optimizedPath, latitude, longitude, stepsAndCosts);

timeToComputeRoute=toc/60;      % minutes

save(strcat(out_path,'/optimizedPathAndSpeedArray.mat'), 'optimizedPath', 'stepsAndCosts', 'route');

%% Saving relevant information as text files,calculating overall computation time and clearing the workspace
outputASCII(pathLatLon,pathSpeed,pathTime,pathLength, out_path);
datetime('now','InputFormat','YY-MM-DD-HH-MM-SS');

%t=datestr(now,'mmddyyyy_HHMM');
save(strcat(out_path,'/timeToComputeRoute.txt'), 'timeToComputeRoute', '-ascii');

%% Saving relevant information as kml files, for visualization purposes
kmlwriteline(strcat(out_path,'/path.kml'),pathLatLon(:,1),pathLatLon(:,2),pathSpeed);
waypointsLatLong = readtable(strcat(in_path,'/INwaypointsIB'));
waypointsLatLong=table2array(waypointsLatLong);
kmlwrite(strcat(out_path,'/IBWPs.kml'),waypointsLatLong(:,1),waypointsLatLong(:,2));

end




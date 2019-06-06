function [search, latitude, longitude, inverseSpeed, navigationGrid, drawUpdates, CPUstartTime, speed, stuck, hi, heq] = init(env_path, in_path)
%INIT This function initializes the routing algorithm
%
%%  ICEPATHFINDER: find the fastest ship route given certain ice conditions 
%   v1.1      15.2.2018     V.V.Lehtola              
%   Code handles all Baltic SW(2727,809), NE(4369,1919) using GEBCO
%   resolution. Astar: separated the topological routing problem and the sub-cell interpolation
%   problems so that the latter is done in post-optimization, and provides
%   the global minimum. Gcost calculation is separated so that only computational units are employed
%   in the loop, and a conversion to real units is done in the
%   post-computation phase. multiple objective framework support. ship-ship interactions through
%   a mean field. narrow seaways are handled rigorously.
%   init: path end points to the source and the target are found
%   by using closest navigable depths (GEBCO). Stuck probabilities are handled 'rigorously' with
%   binomial confidence interval to increase the time spent in each grid cell.

%  Code and version history for a previous VORIC-project-based implementation 
%  (authors: R. Guinness and J. Montewka) is available from
%               https://github.com/robguinness/AStar
%  ICEPATHFINDER offers also over 100-fold speed up from VORIC-Astar routine.

% DEFINITIONS: (change definitions only with great caution!
% 
% search         data structure containing information about the origin point and
%                destination point for the ship, defining the desired starting and
%                ending points between which a route should be found. Contains
%                following:
%
%                .originX       x-coordinate of the origin
%                .originY       y-coordinate of the origin
%                .destinationX  x-coordinate of the destination
%                .destinationY  y-coordinate of the destination
%
% depthMask      a binary matrix, m by n (as opposite to other matrices),  
%                where the elements in the matrix represent whether or not 
%                the depth requirements for a particular ships 
%                are met at the specified location. A value of "0" indicates
%                the requirements are met, whereas a value of "1" indicates
%                the depth requirements are not met. Rows in the matrix
%                represent y-coordinates and columns represent x-coordiantes.
%                Element (1,1) is the Northwest corner of the area
%                
%                --------------------------------------------
%                  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | n|
%                --------------------------------------------
%                |1| NW   0   0   0   0   0   0   0   0   NE|
%                |2| 0    0   0   0   0   0   0   0   1   1 |
%                |3| 0    0   0   0   0   1   1   1   1   1 |
%                |4| 0    0   0   0   0   1   1   1   1   1 |  <- land in SE
%                |m| SW   0   0   0   1   1   1   1   1   SE|     corner of region
%                 --------------------------------------------
%                 
% groundMask  a binary matrix where the elements in the matrix represent 
%                whether or not there is a continent present at the specified location
%                A value of "0" indicates no continent whereas a value of "1" indicates
%                a contient. Otherwise, the definition is the same as depthMask
%
% waypointsLatLong  a two-column matrix storing coordinates of waypoints in ice given by Icebreaker in Lat and Long.  
%
% waypoints      a two-column matrix storing coordinates of waypoints in ice given by Icebreaker in X and Y, 
%                where X corresponds to Longitude and Y corresponds to Latitude.
%
% longitude      n by m matrix containing values of longitude for a given search area. Each row corresponds to a particular longitude 
%                (there are n longitudes in search area) that crosses all latitudes (m), represented by columns. Rows can be
%                seen as meridians and coluns as parallels.              
%
% latitude       n by m matrix containing values of latitude for a given search area. Each row corresponds to a particular longitude 
%                (there are n longitudes in search area) that crosses all latitudes (m), represented by columns. Rows can be
%                seen as meridians and coluns as parallels.    
%
% speed          m by n matrix where the elements in the matrix represent speed for a particular ship, based on ship performance model developed by AALTO. 
%                Rows in the matrix represent latitude (y-coordinates) and columns represent longitude (x-coordiantes).
%                Element (1,1) is the Southwest corner of the area - N.B. the difference in orientation between speed and depthMask matrices.
%                The number of rows is 556 and the number of columns is
%                830. [m/s]
%
%                --------------------------------------------
%                  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | n|
%                --------------------------------------------
%                |1| SW   0   0   0   0   0   0   0   0   NW|
%                |2| 0    0   0   0   0   0   0   0   1   1 |
%                |3| 0    0   0   0   0   1   1   1   1   1 |
%                |4| 0    0   0   0   0   1   1   1   1   1 |  
%                |m| SE   0   0   0   1   1   1   1   1   NE| 
%                 --------------------------------------------
% inverseSpeed   a matrix containing inverse values of those stored in
%                speed matrix (1/speed). [s/m]
%
% navigationGrid      n by m matrix containing information about each and every cell in the search area. The cells are given numbers,
%                describing their status (walkable = 1; onOpenList = 2; onClosedList = 3; unwalkable = 4; found = 1; nonexistent = 2) 
%
% shipTrackLatLong
%
% shipTrackXY
%
% stuck             if the probability of a ship getting stuck in ice exceeds zero, a time penalty may apply.
%
% Margin            the value used to enlarge the search area for the algorithm. It adds a certain number of cells to all directions, based on LAT and 
%                   LONG of point of origin and point of desitnation.

% speedAalto        matrix contains speed and stuck files, both of size 556x830
% 
% metaSpeed         it contains three arrays: v_m, bst, ram.
%                   v_m - the mean speeds, in [m/s]; 
%                   bst is array of 1 or 0, 1 when ship is beset in ice. For those cases v_m has entry of 0; 
%                   ram is array of integers, the number of rams for the case.
%                   15 minute simulations with the use of ship transit model presented in 
%                   Kuuliala L., Kujala P., Suominen M., Montewka J., Estimating operability of ships in ridged ice fields, Cold Regions Science and Technology, 135, 2017, 51-61.
%                   All arrays are indexed (i,j,k), where i is heq, j is hi and k is 200 cases of one instance of hi-heq combination.
%                   8 columns corresponding to hi = 0.1:0.1:0.8; level ice
%                   thicknesses in [m]
%                   12 rows corresponding to heq = 0.05:0.05:0.6;
%                   equivalent ice thicknesses in [m]

disp('Initializing the program...')
isdeployed = 0;
CPUstartTime = tic;

%% Set-up path
if (isdeployed == 0) 
    addpath environment
    %addpath ships
    addpath utilities    
    addpath('algorithm', 'algorithm/subroutines', 'algorithm/classes');
end

%% Define data structures

% Define search structure
search = struct('originX',0,'originY',0,'destinationX',0,'destinationY',0);
HELMI=struct('originX',0,'originY',0,'destinationX',0,'destinationY',0);

%% Define constants
global IBNEEDED; IBNEEDED = 4;
global UNAVIGABLE; UNAVIGABLE = 5;
global GROUND; GROUND= 6;

%% Run-time parameters
drawAll=false;      % draw pictures or not

% if drawAll set to true, above options are all set to true
if drawAll
    figure(1)
    drawInitial = true; % don't modify
    drawUpdates = true; % don't modify
    drawResults = true; % don't modify
    hold on
    drawDebug = true;
else
    drawInitial = false; % don't modify
    drawUpdates = false; % don't modify
    drawResults = false; % don't modify
    drawDebug = false;
end

%% Load input parameters
fileID = fopen(fullfile(in_path, 'INPUT_icepathfinder.txt'), 'r');
C = textscan(fileID, '%s %f %f %f %f %f %d %d %d');
strtmp = C{1};
iceFilename = strtmp{1};
search.originLat = C{2};
search.originLong = C{3};
search.destinationLat = C{4};
search.destinationLong = C{5};
safeDepth = C{6};
timeSteps = C{7};          % 6h per step, so 8 steps means 48h.    
bathymetryOperationMode = C{8};     % GEBCO+geofence=0, GEBCO=1, AISmask=2
shipShipMaskMode = C{9};            % ice channels: on=0, off=1

%stuckInput=readtable(strcat(in_path,'/INstuckThreshold'));
%stuckThreshold=table2array(stuckInput(1,1));

% Define ice breaker waypoints
%waypointsLatLong = readtable(strcat(in_path,'/INwaypointsIB'));
%waypointsLatLong=table2array(waypointsLatLong);
waypointsLatLong=[];

% GEBCO depth matrix definition
LatN = 70;                  % the northernmost latitude of the GEBCO depth matrix
LongW = -6;                 % the weternmost longitude of the GEBCO depth matrix (negative is west)
LatRows = 2400;             % the number of rows in the GEBCO grid
LongCols = 4800;            % the number of rows in the GEBCO grid
% LAT,LONG coordinates of HELMI grid: point of origin SW(56.74N, 016.72E), point of desitnation NE(65.99,030.48)
HELMI.originLat=56.74;
HELMI.originLong=16.72;
HELMI.destinationLat=65.99;
HELMI.destinationLong=30.48;

%% Calculate geographic coordinates
fprintf('Calculating geographic coordinates (bathymetryOpMode==%d) ...', bathymetryOperationMode)
[longitude, latitude] = calculateCoordinates(LatN, LongW, LatRows, LongCols);
% x,y-coordinates of origin are calculated based on Lat, Long input
[search.originX,search.originY]=calcXY(latitude, longitude, search.originLat,search.originLong);
[search.destinationX,search.destinationY]=calcXY(latitude, longitude, search.destinationLat,search.destinationLong);
[HELMI.originX,HELMI.originY]=calcXY(latitude, longitude, HELMI.originLat,HELMI.originLong);
[HELMI.destinationX,HELMI.destinationY]=calcXY(latitude, longitude, HELMI.destinationLat,HELMI.destinationLong);

%subset of GEBCO defining the search area
% XY coordinates of HELMI grid: SW(2727,809), NE(4369,1919)
%MARGIN=251;
%[minX, maxX, minY, maxY]=calculateSearchArea(search.originX, search.originY, search.destinationX, search.destinationY,MARGIN);
MARGIN = 1;
[minX, maxX, minY, maxY]=calculateSearchArea(2727,809, 4369,1919,MARGIN);

fprintf('done.\n')

%% Load saved data
fprintf('Loading depth and speed data...')

% This function creates two masks one for depth the other for GROUND.
% Inputs are GEBCO elevation data and safe depth of water for a given ship
% defined by the user
[depthMask,groundMask] = depthMaskEvaluation(env_path, in_path, safeDepth);

% speedAalto2 is a 3D array calculated for a range of time instances
% This loads a speed grid for the area covered by HELMI model, calculated at AALTO. 
%load environment/speedAalto2                                          
% It originates in SW, and needs to be flipped to conform with the requirements - the origin needs to be in NW.

% The data has already been loaded if in deployed mode
if (isdeployed == 0) 
    iceDataPath = 'HELMI/2011/';
    % NOTE: here we create 556x415xtimeSteps matrices!
    [levelIceTh, ridgedIceTh, totalIceConc, ridgedIceConc] = loadHELMIData(iceDataPath, iceFilename, timeSteps);
end

% ice thickness for level ice (hi) and equivalent ice thickness (heq) in [m]
% levelIceTh and ridgedIceTh contain NaN values for non-modeled areas.
% Rafted ice th AND fastened ice th is within levelIceTh.
% Percolation threshold, 2d continuum model explains the constant 0.676

percolationThreshold = 0.676; % 2D continuum model for disks of radius r

totalIceConc(totalIceConc < percolationThreshold)=0;
ridgedIceConc(totalIceConc < percolationThreshold) = 0; %% note total

hi=levelIceTh.*totalIceConc;
heq=ridgedIceTh.*ridgedIceConc;

% maxIceThickness is based on the results of transit simulation, which define max ice parameters for which a ship can?t proceed, thus speed is 0.
% Tis variues from ship to ship thus need to be updated when a data for a new ship arrives
% maxIceThickness=readtable(strcat(in_path,'/INmaxIceThickness'));
% maxLevelIceThickness=table2array(maxIceThickness(1,1));
% maxEquivalentIceThickness=table2array(maxIceThickness(1,2));
maxLevelIceThickness=0.8;
maxEquivalentIceThickness=0.6;

% ice thicknesses are numerically capped so that the following matrix
% indexing works. These ice thickness caps are so large (0.6 and 0.8 ) that
% even Ia super class ship stops on such conditions.
heq(heq>maxEquivalentIceThickness)=maxEquivalentIceThickness;
hi(hi>maxLevelIceThickness)=maxLevelIceThickness;

heq_ind=heq./0.05;  
% this translates ice thickness into index that is taken as an input for interpolation function mentioned above.
hi_ind=hi./0.1;     
% the same as above. Both indices are taken to obtain the speed value and probability of getting stuck.

%% Calculate ice breaker waypoints in [X, Y]
numWaypoints = size(waypointsLatLong,1);
waypoints = zeros(numWaypoints,2);
for i=1:numWaypoints
    [X, Y] = calcXY(latitude,longitude,waypointsLatLong(i,1),waypointsLatLong(i,2));
    waypoints(i,:) = [X, Y];
end

%% the following carves ice breaker routes (DIRWAY) in the speed map
% TODO: visualization
% for i=1:numWaypoints-1
%     a = [waypoints(i,1) waypoints(i,2)]; %segment points a,b
%     b = [waypoints(i+1,1) waypoints(i+1,2)];
%     heq_ind(a) = 0; % no ice here
%     hi_ind(b) = 0;
%     ib=a;
%     stepX = sign ( b(1) - a(1) );  % +1 or -1
%     stepY = sign ( b(2) - a(2) );
%     while (ib ~= b)
%         % icebreaker moves
%         if(b(1)  - ib(1) ~= 0)
%             ib(1) = ib(1) + stepX;        
%         end
%         if(b(2)  - ib(2) ~= 0)
%             ib(2) = ib(2) + stepY;        
%         end
%         % icebreaker makes a route to the ice data map        
%         heq_ind(ib) = 0; % no ice here
%         hi_ind(ib) = 0;
%         
%     end
% end

[speed]=interpolationMetaSpeed(hi_ind,heq_ind,env_path); % the speed array is created based on hi and heq and speed-meta model
[stuck]=interpolationMetaStuck(hi_ind,heq_ind,env_path); % the probability of getting stuck array is created based on hi and heq and speed meta-model
stuck(stuck<0) = 0; % to avoid P(stuck) greater than 1 or smaller than 0, due to interpolation errors
stuck(stuck>1) = 1;

% convert the speed here from m/s to nm / hours (=knots). This is convenient since
% the grid is expressed in nautical miles.
speed = speed .* (3600 / 1852);
% --------------------------------------------

speed=flipud(speed);            % these flips could be done initially for the ice data
stuck=flipud(stuck);
% the 3rd dimension of speed matrix is obtained, to know how many time intervals is has
numberOfIntervals=size(speed);
numberOfIntervals=numberOfIntervals(3);

fprintf('done.\n')
%% Reducing the size of latitude and longitude matrices according to the already defined limits of the search area (minX-maxX, minY-maxY)

fprintf('Calculating geographic coordinates...')
longitude = longitude(minX:maxX,minY:maxY);
latitude  = latitude(minX:maxX,minY:maxY);
fprintf('done.\n')

%% Create masks and speed matrices

fprintf('Resizing matrices...')
sizeDepthMask=size(depthMask);
sizegroundMask=size(groundMask);
depthMask = depthMask((sizeDepthMask(1,1)-maxY):(sizeDepthMask(1,1)-minY),minX:maxX);
[mapRows, mapCols] = size(depthMask);
groundMask = groundMask((sizegroundMask(1,1)-maxY):(sizegroundMask(1,1)-minY),minX:maxX);
%groundMask = groundMask(minY:maxY,minX:maxX);

%TODO: the grid transformation could be done neatly in a function
%speed = helmi2gebco(speed, HELMI, minX, maxX, minY, maxY, numberOfIntervals, depthMask);
%stuck = helmi2gebco(stuck, HELMI, minX, maxX, minY, maxY, numberOfIntervals, depthMask);

% Here a HELMI grid-based speed matrix is embeded into GEBCO-based grid
% The X,Y coordinates of HELMI grid are hard-coded here (810:1921,2724:4383)
% The aim is to have speed matrix oriented so, that its originates in SW corner
% of a map, and its rows correspond to Longitude and column to Latitude
%speed2=ones(556,830,numberOfIntervals);
speed2=repelem(speed,2,2);
S=ones(2400,4800,numberOfIntervals);
sizeS=size(S);
S((sizeS(1,1)-HELMI.destinationY):(sizeS(1,1)-HELMI.originY+1),HELMI.originX:HELMI.destinationX+7,:)=speed2;
%S(810:1921,2724:4383)=speed2;
speed=S;
speed = speed((sizeS(1,1)-maxY):(sizeS(1,1)-minY),minX:maxX,:);
speed=fliplr(permute(speed,[2,1,3]));
clear S;

%% set NANs to zero in speed and inverseSpeed arrays for sea zones 
% outside the HELMI grid, addition by VL

maxSpeed = max(max(speed(:,:,1)));
% loop over time steps
for i = 1:size(speed, 3)
    tmpMat = speed(:,:,i);
    nanmask = isnan(tmpMat);
    nan2zero = nanmask .* fliplr(~depthMask');
    tmpMat(nan2zero == 1) = maxSpeed;
    tmpMat(fliplr(depthMask')) = NaN;                % not navigable depth
    speed(:,:,i) = tmpMat;
end

% Here the matrix determining the probability of ship getting best in ice is
% introduced, based on AALTO's model
%stuck2=ones(556,830,numberOfIntervals);
stuck2=repelem(stuck,2,2);
S=ones(2400,4800,numberOfIntervals);
sizeS=size(S);
S((sizeS(1,1)-HELMI.destinationY):(sizeS(1,1)-HELMI.originY+1),HELMI.originX:HELMI.destinationX+7,:)=stuck2;
stuck=S;
stuck = stuck((sizeS(1,1)-maxY):(sizeS(1,1)-minY),minX:maxX,:);
%stuck=fliplr(stuck');
stuck=fliplr(permute(stuck,[2,1,3]));

%% set NANs to zero in stuck and inverseSpeed arrays for sea zones 
% outside the HELMI grid, addition by VL

% loop over time steps
for i = 1:size(stuck, 3)
    tmpMat = stuck(:,:,i);
    nanmask = isnan(tmpMat);
    nan2zero = nanmask .* fliplr(~depthMask');
    tmpMat(nan2zero == 1) = 0;              % not stuck where not defined
    tmpMat(fliplr(depthMask')) = NaN;                % not navigable depth
    stuck(:,:,i) = tmpMat;
end

%% With a confidence of 'confidenceValue' the ship sails through some
% cell with a finite stuck chance. This equals to a certain amount
% of retries, which is used to DIVIDE the ship speed to obtain the most
% likely value (or best estimate). ++VL

confidenceValue = 0.95;
retries = log(1.0 - confidenceValue)/log( stuck );
retryCap = 10;
retries(retries < 1) = 1;               % speed cannot increase
retries(retries > retryCap) = retryCap; % cap
speedStuck = speed;
%indStuck = find(stuck> stuckThreshold);     % this causes shore problems!
indStuck = find(stuck> 0);
speedStuck(indStuck) = speed(indStuck) ./ retries(indStuck);    % divide
speed = speedStuck;
speed(speed<4) = 4; % at and below this, IB. in winter traffic analysis, where 1A super in independend mode did not have speed lower that 4 kn  (=2m/s !)
inverseSpeed = 1 ./speed;

% search.originX,Y is made into a new coordinate system, defined by minXY-maxXY to align with the size of navigationGrid
search.originX=search.originX-minX;
search.originY=search.originY-minY;
search.destinationX=search.destinationX-minX;
search.destinationY=search.destinationY-minY;

fprintf('done.\n')


%% Historical ship data

% fprintf('Loading ship tracks...')
% sh = loadShipTrack(latitude, longitude);
% fprintf('done.\n')
% 
% fprintf('Plotting ship tracks...')
% numInTrack = size(sh,1);
% trackPoints = zeros(numInTrack,2);
% prevX = 0;
% prevY = 0;
% j=1;
% for i=1:numInTrack
%     [X, Y] = calcXY(latitude,longitude,sh(i,1),sh(i,2));
%     if (X~=prevX || Y~=prevY)
%         trackPoints(j,:) = [X, Y];
%         j=j+1;
%         prevX = X;
%         prevY = Y;
%     end
% 
% end
% trackPoints = trackPoints(1:j-1,:);
% plot(trackPoints(:,1),trackPoints(:,2),'y*-');
% fprintf('done.\n')

%% debug printing

if(drawDebug)
    figure(2)    
    Data_Array = flipud(hi(:,:,1));
    imAlpha=ones(size(Data_Array));
    imAlpha(isnan(Data_Array))=0;
    imagesc(Data_Array,'AlphaData',imAlpha);
    set(gca,'color',0*[1 1 1]); 
    title('hi')
    %image(depthMask, 'Cdatamapping', 'scaled')
    %title('depthMask')
    figure(3)    
    % plot arrays so that NaNs are alpha values (=background is shown for Nans)
    Data_Array = fliplr(speed(:,:,1))'; %% note
    imAlpha=ones(size(Data_Array));
    imAlpha(isnan(Data_Array))=0;    
    tmpind = find(depthMask == 1);
    imAlpha(tmpind)=0;
    imagesc(Data_Array,'AlphaData',imAlpha);
    set(gca,'color',0*[1 1 1]); 
    title('speed in navigable depth')
    %image(speed(:,:,1), 'Cdatamapping', 'scaled')
    figure(4)    
    Data_Array = flipud(heq(:,:,1));
    imAlpha=ones(size(Data_Array));
    imAlpha(isnan(Data_Array))=0;
    imagesc(Data_Array,'AlphaData',imAlpha);
    set(gca,'color',0*[1 1 1]); 
    title('heq')
    figure(5)    
    Data_Array = fliplr(inverseSpeed(:,:,1))';
    imAlpha=ones(size(Data_Array));
    imAlpha(isnan(Data_Array))=0;
    imagesc(Data_Array,'AlphaData',imAlpha);
    set(gca,'color',0*[1 1 1]); 
    title('inverse speed')
    %imagesc(heq(:,:,1), 'Cdatamapping', 'scaled')
    %sc(isnan(heq(:,:,1)), 'bone', [1 1 1]);
    figure(1)
end

%% Define obstacles

fprintf('Assigning unnavigable nodes in navigationGrid...')

%% Create navigationGrid array
navigationGrid = fliplr(depthMask')*UNAVIGABLE + fliplr(groundMask')*(GROUND- UNAVIGABLE);

if(false)
    %% visualize Oulu searoute area grid (lat/lon)
    % Ut�: 59.77939, 21.37795
    % under Ut�: 59.72206, 20.78283
    % over Turku: 60.50945, 22.19348
    %[ll_x, ll_y] = calcXY(latitude, longitude,  59.72206, 20.78283);
    %[ur_x, ur_y] =  calcXY(latitude, longitude,  60.50945, 22.19348);
    %cropGrid = navigationGrid(ll_x:ur_x, ll_y:ur_y);
    % under Oulu: 64.93087, 25.50805
    % over Hailuoto: 65.20872, 24.43551
    [ll_x, ll_y] = calcXY(latitude, longitude, 64.93087 , 24.43551);
    [ur_x, ur_y] =  calcXY(latitude, longitude,  65.20872, 25.50805);
    cropGrid = navigationGrid(ll_x:ur_x, ll_y:ur_y);    
    h=figure();
    imagesc(fliplr(cropGrid)');
    print('cropGrid_Oulu', '-dpng');
    a=0;        % put a breakpoint here
end

% mode=0 adds geo-fencing&narrow seaway exclusion, mode=1 is plain gebco,
% mode=2 is AISmask (experimental, for plotting)
if(bathymetryOperationMode == 0)
    %% exclude narrow seaways
    navigationGrid = shoreExclusion(navigationGrid, UNAVIGABLE);       % dilate unnavigable areas

    %% Geo-fencing
    navigationGrid(490:495, 847) = UNAVIGABLE;    % Exclude Norra Kvarken route manually here
    navigationGrid(944, 330:334) = UNAVIGABLE;    % Exclude Naissaar south bypass (near Tallinn)
    navigationGrid(1000, 334:344) = UNAVIGABLE;   % Exclude Kelnase south bypass (near Tallinn)
elseif(bathymetryOperationMode == 1)
    % nothing, pure GEBCO
elseif(bathymetryOperationMode == 2)
    %% use a degree of freedom mask obtained from AIS data
    load('/work/stormwinds/icepathfinder/external_data/dof-AISmask.mat', 'AISmask');
    % extend AISmask to the same size than navigationGrid and speed map
    icMask=repelem(AISmask', 4, 2);
    %icMask = icMask(1:1645, :);
    icMask(36:1635, :) = icMask(1:1600, :);
    
    icMask = icMask(1:1645, :);
    icMask(:, 1113) = icMask(:, 1112);
    testGrid = navigationGrid;
    testGrid(icMask == 0 & navigationGrid < UNAVIGABLE) = UNAVIGABLE;
    testGrid(icMask == 1 & navigationGrid == UNAVIGABLE) = 0;
    navigationGrid = testGrid;
    
end

%% ice-channel mask (=mean field). 0:on (default), 1:off
% Ice channels are created by ice breakers and maintained by traffic
if(shipShipMaskMode == 0)    
    load('external_data/ship-ship_interaction_FGI_05022018.mat', 'system_mask');
    % extend icMask to the same size than navigationGrid and speed map
    icMask=repelem(system_mask', 4, 2);
    icMask(1624:1645, :) = icMask(1603:1624, :); % extend the matrix
    icMask(:, 1113) = icMask(:, 1112);           % extend the matrix
    
    icMask(21:1645, :) = icMask(1:1625, :);               % shift the matrix
    
    speed(icMask & speed < 8) = 8;      % 8 knots
    inverseSpeed = 1 ./speed;           % re-define inverseSpeed
end

if(drawDebug)
    figure(6)
    image(fliplr(navigationGrid)', 'Cdatamapping', 'scaled')
    title('navigationGrid')
    figure(7)
    Data_Array = flipud(stuck(:,:,1)');
    imAlpha=ones(size(Data_Array));
    imAlpha(isnan(Data_Array))=0;
    imagesc(Data_Array,'AlphaData',imAlpha);
    set(gca,'color',0*[1 1 1]); 
    %imagesc(stuck(:,:,1)', 'Cdatamapping', 'scaled')
    title('stuck')
    figure(1)
end



%% Check if the origin and destination are within navigable area
departureNavigable = navigationGrid(search.originX,search.originY);
arrivalNavigable =  navigationGrid(search.destinationX,search.destinationY);
if  departureNavigable>=4 
    fprintf('Point of departure (%i, %i)  unnavigable.\n', search.originX, search.originY)
    [search.originX, search.originY] = searchClosestNavigableDepth(search.originX, search.originY, fliplr(depthMask'));
end
if  arrivalNavigable>=4 
    fprintf('Point of arrival (%i, %i) unnavigable.\n', search.destinationX,search.destinationY)
    [search.destinationX,search.destinationY] = searchClosestNavigableDepth(search.destinationX,search.destinationY, fliplr(depthMask'));
end    


%% Debug plots on sea environment - this section may be commented out for Matlab standalone version
if drawInitial
    
    % Normalize the speed values to be between 0 and 63;
    speedNormalized = normalize(speed)*63;
    % Assign obstacles a value of 64 (highest in colormap
    speedNormalized = speedNormalized + fliplr(depthMask')*64; % ++VL
    speedNormalized(isnan(speedNormalized)) = 64;
    speedNormalized(speedNormalized > 64) = 64; % truncate to max
    % set up colormap
    colormap cool
    cmap = colormap;
    cmap(64,:) = [0 0 0];       % display value 64 as black
    colormap(cmap);
    % plot the matrix and do other setup
    image(speedNormalized(:,:,1)')
    %image(permute(speedNormalize, [2 1]))
    axis([1 mapCols 1 mapRows])
    colorbar

    % Plot origin and destination points - this section is commented for Matlab standalone version 
    fprintf('Plotting start and finish points...')
    mapWidth = size(navigationGrid, 1);
    mapHeight = size(navigationGrid, 2);
    plotPoint([search.originX, search.originY],[1 0.5 0], mapHeight, mapWidth);
    plotPoint([search.destinationX, search.destinationY], [1 0.5 0], mapHeight, mapWidth);
    scatter([search.originX], [search.originY], 10, 'r*'); % plot in two manners
    fprintf('done.\n')

    % Plot ice breaker waypoints
    fprintf('Plotting ice breaker waypoints...')
    scatter(waypoints(:,1),waypoints(:,2),'b*');
    fprintf('done.\n')

end

timeForSetup = toc;
fprintf('Time for set-up was %.2f seconds.\n',timeForSetup);

end

function [ optimizedPath, stepsAndCosts ] = subCellGeometricOptimization(pathAndSpeedArray, latitude, longitude, whichList, inverseSpeed)
%% Ville Lehtola 2017
% loop through all path points, and optimize the geometric path
% by subcell interpolation. As a result, the output path is also more
% coarse. This is good, since the final result should be expressed with a
% minimal number of Waypoints.

% needed subroutines: isNavigable(...); calculateInterpGCost(...); 

pathAndInvSpeedArray = pathAndSpeedArray;
pathAndInvSpeedArray(:,3) = 1./ pathAndSpeedArray(:,3); % want inv speeds

numberOfIntervalsPerDistanceUnit=20;
debugPlots = false;

% pathPointNumber (0=disabled); refCost ; delta cost
stepsAndCosts = zeros(size(pathAndInvSpeedArray) + [ 0 1 ]);
stepsAndCosts(:,1) = 1:size(stepsAndCosts(:,1), 1);           % ones
inverseSpeedDynamic = inverseSpeed(:,:,1);

%% Plot in a figure
if(debugPlots)
    f=figure();
    plot(pathAndInvSpeedArray(:,1),pathAndInvSpeedArray(:,2) );
    hold on
end

%% step 0: initialize costs
% one step costs between i and i+1
for i = 1:size(pathAndInvSpeedArray(:,3))-1
    x1 = pathAndInvSpeedArray(i, 1);
    y1 = pathAndInvSpeedArray(i, 2);
    x2 = pathAndInvSpeedArray(i+1, 1);
    y2 = pathAndInvSpeedArray(i+1, 2);        
    % the initial path is navigable, and does not contain NaNs
    % check if x and y need to be switched
    gridCost = calculateInterpGCost(x1,y1,x2,y2,numberOfIntervalsPerDistanceUnit, inverseSpeedDynamic, 'nearest');
    %tmpCost = 0.5* sqrt( (x2-x1)^2 + (y2-y1)^2 ) * (inverseSpeedDynamic(x1, y1) + inverseSpeedDynamic(x2, y2));

    stepsAndCosts(i, 2) = gridCost;         % time to travel
end

% removal cost/benefit (pos/neg value) for point i by tracing a direct
% route from point i-1 to i+1.
for i = 2:size(pathAndInvSpeedArray(:,3))-1
    x1 = pathAndInvSpeedArray(i-1, 1);
    y1 = pathAndInvSpeedArray(i-1, 2);
    x2 = pathAndInvSpeedArray(i+1, 1);
    y2 = pathAndInvSpeedArray(i+1, 2);        
    navigable = isNavigable(x1, y1, x2, y2, whichList );
    if(navigable)
        tmpCost = calculateInterpGCost(x1,y1,x2,y2,numberOfIntervalsPerDistanceUnit, inverseSpeedDynamic, 'nearest');
    else
        tmpCost = Inf;
    end
    
    % calculate difference. = zero if the point is already on the optimal
    % path, > 0 if removing the point should not be done, < 0 if it should.
    stepsAndCosts(i, 3) = tmpCost - stepsAndCosts(i, 2) - stepsAndCosts(i-1, 2);
end

% create pseudopoints to help deal with boundary conditions
stepsAndCosts = [stepsAndCosts(1,:) ; stepsAndCosts ; stepsAndCosts(end,:)];

fprintf('Entering post-optimization master loop.\n');
fprintf('Disabling the following points'); 
%% master loop
step=0;
while(1)
    %% step 1: arrange and remove the most expensive point (largest negative value)

    [val, idx] = min(stepsAndCosts(3:end-2, 3));               % minimum excluding 1st and last
    idx = idx + 2;                                             % with exclusion
    
    if(val >= 0)
        % optimization is complete!        
        break
    end
    
    fprintf('%i ', idx);
    stepsAndCosts(idx,:) = [];            % remove the point element

    %% step 2: update neighboring point costs, idx-1 and idx (new index)

    arr = [idx-1 idx ; idx-2 idx ; idx-1 idx+1];
    tmpCosts = zeros(size(arr,1),1);
        
    for i = 1: size(arr, 1)        
        % convert to indices a and b used by the original matrix
        a = stepsAndCosts(arr(i, 1), 1);
        b = stepsAndCosts(arr(i, 2), 1);
        x1 = pathAndInvSpeedArray(a, 1);
        y1 = pathAndInvSpeedArray(a, 2);
        x2 = pathAndInvSpeedArray(b, 1);
        y2 = pathAndInvSpeedArray(b, 2);        
        navigable = isNavigable(x1, y1, x2, y2, whichList );
        if(navigable)
            tmpCosts(i) = calculateInterpGCost(x1,y1,x2,y2,numberOfIntervalsPerDistanceUnit, inverseSpeedDynamic);
        else
            tmpCosts(i) = Inf;
        end
    end
    
    % calculate difference. = zero if the point is already on the optimal
    % path, > 0 if removing the point should not be done, < 0 if it should.

    stepsAndCosts(idx-1, 2) = tmpCosts(1);          % ei voi olla inf by def
    stepsAndCosts(idx-1, 3) = tmpCosts(2) - stepsAndCosts(idx-1, 2) - stepsAndCosts(idx-2, 2);
    stepsAndCosts(idx, 3) = tmpCosts(3) - stepsAndCosts(idx, 2) - stepsAndCosts(idx-1, 2);
        
    step = step + 1;
    % Plotting stuff
    if(debugPlots && mod(step, 20) == 0)
        optimizedPath = [];
        for i=1:size(stepsAndCosts, 1)
            optimizedPath = [optimizedPath; pathAndInvSpeedArray(stepsAndCosts(i, 1), :) ];
        end
        plot(optimizedPath(:,1),optimizedPath(:,2) );
        pause(1)
    end
end

% remove pseudopoints
stepsAndCosts(1, :) = [];
stepsAndCosts(end, :) = [];

% final result: use latitudes and longitudes to calculate the geodesic path
% and real velocity/ time used.

%stepsAndCosts(1, 2) = 0;                % reset the initial point

optimizedPath = [];
for i=1:size(stepsAndCosts, 1)
    optimizedPath = [optimizedPath; pathAndInvSpeedArray(stepsAndCosts(i, 1), :) ];
end

if(debugPlots)
    plot(optimizedPath(:,1),optimizedPath(:,2) );
    pause(1)
end

end


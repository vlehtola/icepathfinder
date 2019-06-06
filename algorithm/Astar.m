% Function to find path, gets start and finish coordinates
function [pathMatrix, pathAndSpeedArray, Gcost,timeCoordinateSpeedMatrix, indexOfSpeedMatrixAtWaypoint] = AStar(search, inverseSpeed, navigationGrid, drawUpdates, startTime, env_path, in_path, heuristic)    

    if (nargin < 8)
        heuristic = true;       %default
    end
    
    % discrete time steps, 1 to 8. inverse speed in h / nautical miles.
    % distance in unity grid steps, 0.5 nautical miles.

    timeCoordinateSpeedMatrix=1;
    inverseSpeedDynamic = inverseSpeed(:,:,timeCoordinateSpeedMatrix);
    temporalDimensionofSpeedMatrix=size(inverseSpeed,3);         % temporal dimension of the speed matrix
    updateInterval = 3000;            % used for drawing
        
    if drawUpdates
        cm = colormap;
    end

    pathAndSpeedArray = [];
            
    invMaxSpeed = min(inverseSpeed(:));
    heuristicWeightAstar = 1.0;
    % used for colorful plotting
    minFcost = heuristicWeightAstar*sqrt((search.originX - search.destinationX)^2 + (search.originY - search.destinationY)^2)* invMaxSpeed;
    
    mapWidth = size(navigationGrid, 1);
    mapHeight = size(navigationGrid, 2);

    parentX = sparse(mapWidth,mapHeight);        % 2D array stores x coord of parent for every cell
    parentY = sparse(mapWidth,mapHeight);        % 2D array stores y coord of parent for every cell
    indexOfSpeedMatrixAtWaypoint = sparse(mapWidth,mapHeight);
    indexOfSpeedMatrixAtWaypoint(search.originX, search.originY) = 1; %calculateTimeCoordinateInverseSpeedMatrix(speedMatrixStartingTime, speedMatrixStartingTime, speedMatrixUpdateInterval);
    
    Gcost = zeros(mapWidth,mapHeight);          % 2D array stores G cost of each cell
    pathLength = 0;                             % Will store pathlength                

    % Create variables
    
    %openListNew = struct('size',1,'sortedIndex',[],'nextIdValue',1,'x',[],'y');
    openListNew = OpenList(mapHeight,mapWidth);
    
    numberOfOpenListItems = 0;
    path = 0;
    
    % Variables used as constants
    walkable = 1;
    onOpenList = 2;
    onClosedList = 3;
    UNAVIGABLE = 5;
    found = 1;
    nonexistent = 2;
    
    
    fprintf('------------------------------- \n');
    fprintf('##### Astar Path Planning ##### \n');
    fprintf('------------------------------- \n\n');
    fprintf('Starting the simulation \n');
    fprintf('Using the following options: \n');
    fprintf('Start position: %d, %d \n', search.originX, search.originY);
    fprintf('Finish position: %d, %d \n', search.destinationX, search.destinationY);
    fprintf('Map size: %d \n\n\n', size(navigationGrid,1));
    fprintf('Progress:\n');
    
    % Check if start and finish coordinates are the same
    if ( (search.originX == search.destinationX) && (search.originY == search.destinationY) )
        disp('Start and finish positions are the same');
        return;
    end
    
    % Add starting position to the open list
    openListNew.add(struct('x',search.originX,'y',search.originY),Inf,0);
   
    % Counter used for printing
    i = 1;
    
    % Create an infinite loop (until goal is reached or defined unreachable
    while (1)
        
               
        % Check if there are any members in the open list
        if (openListNew.size ~= 0)
            
            %% Get next node in open list and close it
            
            % Get the values of the first item in the open list (lowest
            % Fcost) into current node
            currentNode = openListNew.getFirstAndRemove();
            
            % put the current node on the closed list
            navigationGrid(currentNode.x, currentNode.y) = onClosedList;
       
            % remove the current node from the open list
            %[openList, numberOfOpenListItems] = removeCurrentNodeFromOpenList(openList,numberOfOpenListItems);
            
            % Sort the open list
            %openList = sortopenList(openList, Fcost, numberOfOpenListItems);
            %openListNew.sort();
            
            %% Update stuff
            
            if (mod(i,3000)==0)
                % Print out current position being analysed
                curval = heuristicWeightAstar*sqrt((currentNode.x - search.destinationX)^2 + (currentNode.y - search.destinationY)^2)* invMaxSpeed;
                prog = 1 - curval / minFcost;
                fprintf('%d. Current position being analysed: %d, %d\n', i, currentNode.x, currentNode.y);
                fprintf('   Size of open list: %d    Time step[1-8]: %d\n', openListNew.size, timeCoordinateSpeedMatrix);
                fprintf('   Elapsed time: %.2f seconds. Progress %.f % \n',toc(startTime), prog);
            end
                       
            % Draw current position in blue (unless it's the start or
            % target cell.
            
            if (drawUpdates && ~((currentNode.x == search.originX) && (currentNode.y == search.originY) || (currentNode.x == search.destinationX) && (currentNode.y == search.destinationY)) )
               plotPoint([currentNode.x, currentNode.y], 'b',mapWidth,mapHeight );
            end
            
            % Update drawing
            if (drawUpdates && mod(i,updateInterval)==0)
                drawnow
            end
            
            % Increment counter
            i = i + 1;
            
            %% Check the neighbours
          
            for j=1:8   % 8 nearest
                neighbor = getNextNeighbor(j, currentNode);
                
                % Check if it is within bounds of a map
                if ( (neighbor.x > 0) && (neighbor.y > 0) && (neighbor.x <= mapWidth) && (neighbor.y <= mapHeight) )
                    % Check if not on closed list
                    if (navigationGrid(neighbor.x,neighbor.y) ~= onClosedList)
                        % Check if it is possible to navigate 
                        % to this neighbor cell
                        nnNavigable = navigationGrid(neighbor.x, neighbor.y) < UNAVIGABLE;
                        if nnNavigable
                            % If not on the open list, add it
                            if (navigationGrid(neighbor.x,neighbor.y) ~= onOpenList)

                                % Calculate current time; GCost is given in
                                % hours
                                currentTime = Gcost(currentNode.x,currentNode.y);
                                currentTimeSliceOfSpeedMatrix = floor(currentTime * 0.1667 * 0.5) + 1; % /6h and 0.5 nm per grid cell
                                % Calculate time coordinate for
                                % inverseSpeed Matrix, but only when
                                % necessary ++VL
                                if(timeCoordinateSpeedMatrix ~= currentTimeSliceOfSpeedMatrix)                                
                                    timeCoordinateSpeedMatrix = currentTimeSliceOfSpeedMatrix;
                                    if  timeCoordinateSpeedMatrix>=temporalDimensionofSpeedMatrix
                                        timeCoordinateSpeedMatrix=temporalDimensionofSpeedMatrix;
                                    else                                
                                        % Speed matrix is selected for the actual time coordinate
                                        inverseSpeedDynamic = inverseSpeed(:,:,timeCoordinateSpeedMatrix);
                                    end
                                end
                                % Calculate its G cost
                                addedGCost = calculateGCostFF(currentNode.x, currentNode.y,neighbor.x,neighbor.y, neighbor.d, inverseSpeedDynamic);
                                
                                % Update Gcost map
                                Gcost(neighbor.x,neighbor.y) = Gcost(currentNode.x,currentNode.y) + addedGCost;

                                % Get H and F costs and parent                                
                                tmpHcost = heuristicWeightAstar*sqrt((neighbor.x - search.destinationX)^2 + (neighbor.y - search.destinationY)^2)* invMaxSpeed; %Euclidean distance                                
                                tmpHcost = tmpHcost* heuristic;     % 0 or 1
                                tmpFcost = Gcost(neighbor.x,neighbor.y) + tmpHcost;
                                
                                % Add neighbor to open list
                                openListNew.add(neighbor,tmpFcost,tmpHcost);
                                % Change value of current node in navigationGrid
                                % to 'onOpenList'
                                navigationGrid(neighbor.x,neighbor.y) = onOpenList;
                                
                                parentX(neighbor.x,neighbor.y) = currentNode.x;
                                parentY(neighbor.x,neighbor.y) = currentNode.y;
                                indexOfSpeedMatrixAtWaypoint(neighbor.x, neighbor.y)=timeCoordinateSpeedMatrix;

                                % Draw current position, shade of
                                % yellow/orange indicates Fcost
                                

                                if (drawUpdates && ~((neighbor.x== search.originX) && (neighbor.y== search.originY) || (neighbor.x== search.destinationX) && (neighbor.y== search.destinationY)) )
                                    colorIndex = getColorIndex(tmpFcost, minFcost);
                                    plotPoint([neighbor.x, neighbor.y], cm(colorIndex,:), mapWidth, mapHeight);
                                end
                                
                            else % i.e. navigationGrid(neighbor.x,neighbor.y) == onOpenList
                                
                                % Calculate its G cost
                                addedGCost = calculateGCostFF(currentNode.x, currentNode.y,neighbor.x,neighbor.y, neighbor.d, inverseSpeedDynamic);
                                tempGcost = Gcost(currentNode.x,currentNode.y) + addedGCost;

                                % If this path is shorter, change Gcost, Fcost and the parent cell
                                if (tempGcost < Gcost(neighbor.x,neighbor.y))
                                    parentX(neighbor.x,neighbor.y) = currentNode.x;
                                    parentY(neighbor.x,neighbor.y) = currentNode.y;
                                    Gcost(neighbor.x,neighbor.y) = tempGcost;

                                    % Changing G cost also changes F cost, so the open list has to be updated
                                    % Change F cost
                                    openListNew.updateByCoordinates(neighbor,tempGcost);

                                end   % updating GCost 

                            end % if-else statement checking whether neighbor is on open list    

                        end % if statement checking if neighbor cell is navigable
                    end % if statement checking if neighbor is on closed list
                end % if statement checking that neighbor is on the map
            end %End of loop through the neighbors
                                
        % If open list is empty     
        else
            path = nonexistent;
            % Print out failure
            fprintf('[Astar.m] %d. Path to the target could not be found \n', i);
            fprintf("current node: %i %i \n", currentNode.x, currentNode.y);
            i = i + 1;
            break;
        end
        % If target is added to open list, path has been found
        if (navigationGrid(search.destinationX,search.destinationY) == onOpenList)
            path = found;
            % Print out success
            fprintf('%d. Path to the target found! \n', i);
            i = i + 1;
            break;
        end
        
    end
    
    % If path was found
    if (path == found)
        
        % Initialize data structures
        pathMatrix = zeros(mapHeight,mapWidth);
        pathLength = 0;
        
        % Backtrack the path using parents
        pathX = search.destinationX;
        pathY = search.destinationY;
        speedAtDestination = 1/inverseSpeed(search.destinationX, search.destinationY, indexOfSpeedMatrixAtWaypoint(search.destinationX,search.destinationY));
        % Print out backtracking
        fprintf('%d. Backtracing to find the shortest route \n', i);
        i = i + 1;
        
        % Pre-allocate pathArray to reasonable maximum size
        pathAndSpeedArray = zeros(mapWidth*mapHeight,3);
        
        % Loop until starting position is reached
        while(1)
            % Lookup parent of current cell
            tempx = parentX(pathX,pathY);
            pathY = parentY(pathX,pathY);
            pathX = tempx;
            
            % Increment the path length
            pathLength = pathLength + 1;
            
            pathMatrix(pathY,pathX) = 1;
            
            pathAndSpeedArray(pathLength,1) = pathX;
            pathAndSpeedArray(pathLength,2) = pathY;
            pathAndSpeedArray(pathLength,3) = 1/inverseSpeed(pathX,pathY, indexOfSpeedMatrixAtWaypoint(pathX,pathY));

            % Draw return path in yellow
            if (drawUpdates && ~((pathX == search.originX) && (pathY == search.originY) || (pathX == search.destinationX) && (pathY == search.destinationY)) )
                plotPoint([pathX, pathY], 'y', mapWidth, mapHeight);
            end
            
            
            % If starting position reached, break out of the loop
            if ( (pathX == search.originX) && (pathY == search.originY) )
                break;
            end
        end
        
        % Print out result
        fprintf('%d. Shortest route is shown in yellow. Total length: %d steps \n', i, pathLength);
        
    end
    
    pathAndSpeedArray = [search.destinationX search.destinationY speedAtDestination; pathAndSpeedArray(1:pathLength,:)]; 
        
end


function colorIndex = getColorIndex(fCost, minFcost)
  colorIndex = round((minFcost/fCost )*63)+1;
  colorIndex = min([ 63 colorIndex]);
end

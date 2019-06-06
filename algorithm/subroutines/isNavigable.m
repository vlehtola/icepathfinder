function [navigable, dist] = isNavigable(xDest, yDest, xOrigin, yOrigin, whichList)
    %% this function is used for path post-optimization only!
    % Ville Lehtola 2017    
    
    %% find equation for line drawn from beginning to destination
    a1 = (yDest-yOrigin) / (xDest-xOrigin); %slope
    b1 = yDest - a1*xDest; % y-intercept
    
    % slope of orthogonal line
    a2 = -1/a1;
    
    %% Get obstacles within bounding box
    
    % define bounding box
    minX = min(xDest, xOrigin);
    maxX = max(xDest, xOrigin)+1;           % +1 to avoid 1xN matrix size related errors later
    minY = min(yDest, yOrigin);
    maxY = max(yDest, yOrigin);
    % get all obstacles
    obstacleWindow = whichList(minX:maxX, minY:maxY);
    [row, col] = find(obstacleWindow >= 4);
    obstacleCoords = [row col];
    if(isempty(obstacleCoords))
        navigable = true;
        return
    end
    % the following line causes error if xDest and xOrigin are the same?
    obstacleCoords = obstacleCoords + [minX-1 minY-1];       % coord transform (error?)
%         figure();
%         hold on
%         scatter(obstacleCoords(:,1), obstacleCoords(:,2));
%         plot([xOrigin xDest], [yOrigin yDest]);
    
    % Next define a threshold (pixel) distance that an obstacle must be
    % from the path of navigation
    thresholdDistance = 0.707; % chosen to correspond roughly to sqrt(2)/2

    %% check the distance to the line for all obstacles in the bounding box
    
    for i=1:size(obstacleCoords,1)
       obstacle = obstacleCoords(i,:);
       m = obstacle(1); % x-coordinate of obstacle
       n = obstacle(2); % y-coordinate of obstacle
        
       % for a few special cases, this calculation is easier
       if (a1 == Inf || a1 == -Inf)
            dist = m-xDest;
       elseif (a1 == 0)
            dist = n-yDest;
       else
       
           % otherwise, we need to define a line passing through the obstacle
           % with slope a2 (i.e. y = a2*x + b2). Since we already know its
           % slope and a point on the line, we can solve for the y-intercept.
           b2 = n - a2*m; % y-intercept of "orthogonal line"

           % solve for point where the two lines intersect
           xIntersect = (b2-b1)/(a1-a2);
           yIntersect = (a1*b2 - a2*b1)/(a1-a2);

           % dist is Euclidean dist between (m,n) and (xIntersect,yIntersect)
           dist = sqrt((xIntersect-m)^2 + (yIntersect-n)^2);
       end
       if (dist < thresholdDistance)
           navigable = false;
           return;
       end

    end
    
    navigable = true;
end
function [route, pathLatLon, pathLength, pathSpeed, pathTime]  = physicalRoute(optimizedPath, latitude, longitude, stepsAndCosts)
% compute physical output parameters for the ship route
% INPUT: Distance is in nautical miles. Time is in hours. Speed in knots (not m/s!).
% OUTPUT: the same
% Ville Lehtola 2017
%
route = zeros(size(optimizedPath, 1)-1, 8);
cumulativeGeodeticDist = 0;
cumulativeTime = 0;

% handle the end boundary
optimizedPath = [ optimizedPath; optimizedPath(end,:) ];

for i=1:size(optimizedPath, 1)-1
    x1 = optimizedPath(i, 1);
    y1 = optimizedPath(i, 2);
    x2 = optimizedPath(i+1, 1);
    y2 = optimizedPath(i+1, 2);
    
    lat1 = latitude(1,y1);
    long1 = longitude(x1,1);
    lat2 = latitude(1,y2);
    long2 = longitude(x2,1);
    % There are about 60 nautical miles in a degree of arc length.
    % One international nautical mile equals to 1852 meters.
    geodeticDist = distance('gc', lat1, long1, lat2, long2)*60;
    cumulativeGeodeticDist = cumulativeGeodeticDist + geodeticDist;
    sumInvSpeed = stepsAndCosts(i, 2); 
    gridDist = sqrt( (x2-x1)^2 + 0.25*(y2-y1)^2 );  % 0.5 x 0.25 nm
    unitInvSpeed = sumInvSpeed / gridDist;
    time = geodeticDist * unitInvSpeed;
    cumulativeTime = cumulativeTime  + time;
    physicalSpeed = 1./unitInvSpeed;
    physicalSpeed(isnan(physicalSpeed)) = 0;        % change the NaN at last cell
    route(i,:) = [ lat1, long1, geodeticDist, cumulativeGeodeticDist, unitInvSpeed, physicalSpeed, time, cumulativeTime ];    
end
pathLatLon = route(:,1:2);
pathLength = route(:,4);
pathSpeed = route(:,6);
pathTime = route(:,8);
end


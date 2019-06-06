function [ currentTime, totalDistanceNm, totalTimeH, avgSpeedKn ] = calculateTime2( searchSpec, speedMatrix, minSpeed, startTime, timeSlices, latitude, longitude )
%CALCULATETIME Calculates the distance, time and average speed along a line
%   Iterates through the line at 1 minute time intervals and uses the speed
%   that is valid for that moment and location to estimate the next
%   distance travelled in a minute

timeStepH = 1/60; % 1 minute

% Consumed time in hours
totalTimeH = 0;
% Travelled distance in nm
totalDistanceNm = 0;

% Keep track of the clock
currentTime = startTime;

currentLat = searchSpec.originLat;
currentLon = searchSpec.originLong;

while 1
    % Current time slice
    currentSliceIndex = getTimeSliceIndex(currentTime, timeSlices);

    % Current position in matrix coordinates
    [x,y]=calcXY(latitude, longitude, currentLat,currentLon);
    
    % Current speed
    currentSpeed = speedMatrix(x, y, currentSliceIndex)*1.852; % Speed to knots
    % If required, use a minimum speed
    if (currentSpeed < minSpeed)
        currentSpeed = minSpeed;
    end
    % Distance travelled in time step
    distanceStep = timeStepH * currentSpeed; % In nm
    
    % Distance left to the end point
    distanceLeft = dist(currentLat, currentLon, searchSpec.destinationLat, searchSpec.destinationLong) / 1000 / 1.852; % To nm
    
    % Increment the spent time counter
    totalTimeH = totalTimeH + timeStepH;
    % Increment current time
    currentTime = currentTime + hours(timeStepH);

    % New position
    if distanceStep <= distanceLeft
        [currentLat, currentLon] = dest(currentLat, currentLon, searchSpec.destinationLat, searchSpec.destinationLong, distanceStep*1852);
        totalDistanceNm = totalDistanceNm + distanceStep;
    else
        %currentLat = searchSpec.destinationLat;
        %currentLon = searchSpec.destinationLong;
        totalDistanceNm = totalDistanceNm + distanceLeft;
        break;
    end
end

avgSpeedKn = totalDistanceNm / totalTimeH; % In knots

end

function index = getTimeSliceIndex(time, times)
    index = -1;
    dim = length(times);
    if (dim > 0)
        if (time <= times(1))
            index = 1;
        elseif (time >= times(dim)) 
            index = dim;
        else
            for i=1:1:dim-1
                halfpoint = times(i)+(times(i+1)-times(i))/2;
                if (time < halfpoint)
                    index = i;
                    break;
                elseif (time >= halfpoint && time <= times(i+1))
                    index = i+1;
                    break;
                end
            end
        end
    else
        fprintf('Error, dim = 0');
    end
end

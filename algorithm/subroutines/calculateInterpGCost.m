function gCost = calculateInterpGCost(x1,y1,x2,y2, numberOfIntervalsPerDistanceUnit, inverseSpeedDynamic, interpMethod)
%% Ville Lehtola 2017
% Calculate interpolated geometric cost     
% NOTE: (lat,long) ^= (y,x)

    if(nargin == 6)
        interpMethod = 'linear';
    end
    
    dist = sqrt( 0.25*(x2-x1)^2 + (y2-y1)^2 );      % 0.5 nm x 0.25 nm
    dt = 1/(numberOfIntervalsPerDistanceUnit);

    % line from (x1,y1) to (x2,y2). make sure normalizing is done properly.
    %ds=[0:1/( ceil(numberOfIntervalsPerDistanceUnit*dist) -1):1];
    ds = dt:dt:1;    
    
    cx_t = (x2-x1)*ds+x1;
    cy_t = (y2-y1)*ds+y1;

    % inverseSpeedDynamic contains NaN values that may interfere when using
    % interp2() function close to coast (which is not navigable), i.e.
    % interp2 results into a NaN if a NaN is in the neighborhood, so..
    inverseSpeedInterp = interp2(inverseSpeedDynamic,cy_t,cx_t, interpMethod);
    
    gCost = dist * dt * sum(inverseSpeedInterp);
    if(isnan(gCost))
        % recalculate
        slowestVal = max(inverseSpeedInterp);
        inverseSpeedInterp(isnan(inverseSpeedInterp)) = slowestVal;  % handle NaNs
        gCost = dist * dt * sum(inverseSpeedInterp);
        
%         % plot
%         aa=isnan(inverseSpeedDynamic);
%         figure();        
%         imagesc(aa);
%         hold on;
%         scatter(cy_t, cx_t, 'r', 'x');
%         a=0;        
    end
    
end


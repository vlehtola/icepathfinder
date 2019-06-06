function speedOut = helmi2gebco(speedIn, HELMI, minX, maxX, minY, maxY, numberOfIntervals, depthMask)
% Here a HELMI grid-based speed matrix is transformed into GEBCO-based grid
% The X,Y coordinates of HELMI grid are hard-coded here (810:1921,2724:4383)
% The aim is to have speed matrix oriented so, that its originates in SW corner
% of a map, and its rows correspond to Longitude and column to Latitude

speed2=repelem(speedIn,2,2);
S=ones(2400,4800,numberOfIntervals);
sizeS=size(S);
S((sizeS(1,1)-HELMI.destinationY):(sizeS(1,1)-HELMI.originY+1),HELMI.originX:HELMI.destinationX+7,:)=speed2;
%S(810:1921,2724:4383)=speed2;
speed=S;
speed = speed((sizeS(1,1)-maxY):(sizeS(1,1)-minY),minX:maxX,:);
speed=fliplr(permute(speed,[2,1,3]));
%clear S;

%% set NANs to zero in speed and inverseSpeed arrays for sea zones 
% outside the HELMI grid

maxSpeed = max(max(speed(:,:,1)));
for i=1:numberOfIntervals
    nanmask = isnan(speed(:,:,i));
    nan2zero = nanmask .* fliplr(~depthMask');
    nanmask(nan2zero == 1) = maxSpeed;
    speed(:,:,i) = nanmask;
end

speedOut = speed;

end


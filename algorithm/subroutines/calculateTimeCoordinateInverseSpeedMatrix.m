function [timeCoordinateSpeedMatrix] = calculateTimeCoordinateInverseSpeedMatrix(currentTime, speedMatrixStartingTime, speedMatrixUpdateInterval)
% calculateTimeCoordinateInverseSpeedMatrix 
% Summary of this function goes here
%   Detailed explanation goes here %LATER

% y=ax+b; we are after x
% x=(y-b)/a

%x=timeCoordinateSpeedMatrix;
y=currentTime;
b=speedMatrixStartingTime;
a=speedMatrixUpdateInterval;
x=(y-b)/a;
x=datenum(x)*24;
timeCoordinateSpeedMatrix=round(x)+1;

end


function [ lat, lon ] = dest(lat1, lon1, lat2, lon2, distance)
%DEST Calculates destination using Pythagoras' theorem, coordinates in degrees, distance in meters 
    rlon1 = toRadians('degrees', lon1);
    rlat1 = toRadians('degrees', lat1);
    rlon2 = toRadians('degrees', lon2);
    rlat2 = toRadians('degrees', lat2);
    R = 6371000;
    x = (rlon2-rlon1)*cos((rlat2+rlat1)/2);
    y = rlat2-rlat1;
    totalDistance = R * sqrt(x*x+y*y);
    
    ratio = distance/totalDistance;
    dx = ratio * x;
    dy = ratio * y;
    
    lat = toDegrees('radians',rlat1+dy);
    lon = toDegrees('radians',rlon1+dx/cos(rlat1));
end

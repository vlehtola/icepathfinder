function d = dist(lat1, lon1, lat2, lon2)
%DIST Distance based on Pythagoras' theorem, coordinates in degrees 
    rlon1 = toRadians('degrees', lon1);
    rlat1 = toRadians('degrees', lat1);
    rlon2 = toRadians('degrees', lon2);
    rlat2 = toRadians('degrees', lat2);
    R = 6371000;
    x = (rlon2-rlon1)*cos((rlat2+rlat1)/2);
    y = rlat2-rlat1;
    d = R * sqrt(x*x+y*y);
end

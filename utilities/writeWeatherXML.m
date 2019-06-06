function writeWeatherXML( speed, stuck, whichList, t, latitude, longitude, filename )
%WRITEWEATHERXML writes a 3D array to an XML file. The first data row contains
%the number of rows and columns in each matrix and the number of
%matrices. The row before each matrix contains the time step of the data.
%Arguments are a 3D data matrix and an array of datetimes.

scalingfactor = 1000;
nullvalue = -9999;

% open the file
fid = fopen(filename, 'w', 'n', 'UTF-8');

% write common file header
fprintf(fid, '<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid, '<Products xmlns:xdf="http:/xml.gsfc.nasa.gov/XDF/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" >\n');

% write product data
fprintf(fid, '<Grid LonMin="%f" LonMax="%f" LatMin="%f" LatMax="%f" GridXDim="%d" GridYDim="%d"/>\n', longitude(1,1), longitude(size(longitude,1),1), latitude(1,1), latitude(1,size(latitude,2)), size(longitude,1), size(latitude,2));
fprintf(fid, '<Product ProducingModel="VORIC"  Length="%d" StartAt="%s" Type="forecast">\n', size(t,2), char(t(1)));

% write each timestep of speed data
for n = 1:size(speed,3)
    fprintf(fid, '<Time   Time="%s">\n', char(t(n)));
    fprintf(fid, '<Data Parameter="ShipSpeed"  ScalingFactor="%d" NullValue= "%d" Unit="m/s">\n', scalingfactor, nullvalue);
    fprintf(fid, '<IntegerArray>\n');

    for lat = size(latitude,2):-1:1
        for lon = 1:size(longitude,1)
            if whichList(lon,lat) == 4 || whichList(lon,lat) == 5
                fprintf(fid, '%d ', nullvalue);
            else
                fprintf(fid, '%d ', round(speed(lon,lat,n)*scalingfactor));
            end
        end
        fprintf(fid, '\n');
    end
    fprintf(fid, '</IntegerArray>\n');
    fprintf(fid, '</Data>\n');
    fprintf(fid, '</Time>\n');
end

% write each timestep of probability of getting stuck data
for n = 1:size(speed,3)
    fprintf(fid, '<Time   Time="%s">\n', char(t(n)));
    fprintf(fid, '<Data Parameter="P_Stuck"  ScalingFactor="%d" NullValue= "%d" Unit="none">\n', scalingfactor, nullvalue);
    fprintf(fid, '<IntegerArray>\n');

    for lat = size(latitude,2):-1:1
        for lon = 1:size(longitude,1)
            if whichList(lon,lat) == 4 || whichList(lon,lat) == 5
                fprintf(fid, '%d ', nullvalue);
            else
                fprintf(fid, '%d ', round(stuck(lon,lat,n)*scalingfactor));
            end
        end
        fprintf(fid, '\n');
    end
    fprintf(fid, '</IntegerArray>\n');
    fprintf(fid, '</Data>\n');
    fprintf(fid, '</Time>\n');
end

% write closing XML
fprintf(fid, '</Product>\n');
fprintf(fid, '</Products>\n');

% close the file
fclose(fid);

end

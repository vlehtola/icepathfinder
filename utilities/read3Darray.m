function [ A, t ] = read3Darray( filename, separator )
%READ3DARRAY Reads a 3D array from text file. The first data row contains
%the number of rows and columns in each matrix and the number of
%matrices. The row before each matrix contains the time step of the data.
%Returns the 3D data matrix and an array of datetimes.
%
% Sample file:
% 2 2 3
% 2015-05-01T00:00:00Z
% 1 2
% 3 4
% 2015-05-01T01:00:00Z
% 5 6
% 7 8
% 2015-05-01T02:00:00Z
% 9 10
% 11 12

% open the file
fid = fopen(filename);

% read the file headers
str = fgetl(fid);
% Skip comment lines starting with something else than a number
while ischar(str) && ~isstrprop(str(1),'digit')
    str = fgetl(fid);
end

pattern = ['%d' separator '%d' separator '%d\n'];
header = sscanf(str, pattern, [1 3]);
rows = header(1);
columns = header(2);
matrices = header(3);
clear header

A = zeros(rows,columns,matrices);

% read each matrix
pattern = ['%f' separator];
for n = 1:matrices
    s = fscanf(fid, '%s', 1);
    t(n) = datetime(s,'TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXX');
    A(:,:,n) = fscanf(fid, [repmat(pattern,1,columns-1) '%f\n'], [columns, rows])';
end

% close the file
fclose(fid);

end

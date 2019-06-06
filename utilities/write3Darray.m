function write3Darray( A, t, filename, separator )
%READ3DARRAY writes a 3D array to a text file. The first data row contains
%the number of rows and columns in each matrix and the number of
%matrices. The row before each matrix contains the time step of the data.
%Arguments are a 3D data matrix and an array of datetimes.
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
fid = fopen(filename, 'w');

% write the file header
fprintf(fid, '%d%s%d%s%d\n',size(A,1), separator, size(A,2), separator, size(A,3));

% write each matrix
pattern = ['%f' separator];
for n = 1:size(A,3)
    fprintf(fid, '%s\n', char(t(n)));
    fprintf(fid,[repmat(pattern,1,size(A,2)-1) '%f\n'],A(:,:,n)');
end

% close the file
fclose(fid);

end

function outValue = plotAISdata()
%% plot the AIS data used for hybrid model speed matrix
% Ville Lehtola 2018

folder = 'D:\STORMWINDS\icepathfinder'; % change as needed
env_path = fullfile(folder, 'environment');
in_path = fullfile(folder, '.');
out_path = fullfile(folder, 'results');

tic;

[search, latitude, longitude, inverseSpeed, whichList, drawUpdates, startTime,speed,stuck, hi, heq] = init(env_path, in_path);

load('C:\Users\vle\Dropbox\workdata_ICE\AIS history data\jakub\1A_266200000.mat', 'combined');

shipX = zeros(size(combined,1), 1);
shipY = zeros(size(combined,1), 1);

maxy = size(whichList, 2);
probMask = zeros(size(whichList'));

% divide by 273 for \sigma=1 Gaussian kernel
%kernel = [1 4 7 4 1; 4 16 26 16 4; 7 26 41 26 7; 4 16 26 16 4; 1 4 7 4 1];

m=17; n=9;
sigma_m=4; sigma_n=2;
[h1 h2]=meshgrid(-(m-1)/2:(m-1)/2, -(n-1)/2:(n-1)/2);
hg= exp(-( (h1.^2)/(2*sigma_m^2) + (h2.^2)/(2*sigma_n^2) ));            %Gaussian function 
h=hg ./sum(hg(:));
 
subMatrix = hg;
kernel = hg;

radx = floor(m/2);
rady = floor(n/2);

for i=1:size(combined, 1)
    [sx, sy] = calcXY(latitude, longitude, combined(i,5), combined(i,4));    
    lat = combined(i,5);
    lon = combined(i,4);
    shipX(i)= sx;
    shipY(i)= maxy - sy; % flipud shipxy data
    
    subMatrix = probMask(maxy-sy-rady:maxy-sy+rady, sx-radx:sx+radx);
    subMatrix = subMatrix + kernel;
    probMask(maxy-sy-rady:maxy-sy+rady, sx-radx:sx+radx) = subMatrix;  % transpose
end

probMask(probMask > 50) = 50;           % cap values, e.g. ship idles in harbor

% create a separate visualization map
visMap = probMask;
visMap(visMap > 0 & visMap < 2) = 2;   % make space
tmpMap = flipud(whichList');
tmpMap(tmpMap == 5) = 1;        % ground to one
tmpMap(tmpMap > 1) = 0;         % non-ground to water

visMap = visMap + tmpMap;       % merge

h=figure(33);
imagesc(visMap);
%camroll(-90);
hold on
cm = colormap;
cm(2,:) = [1 1 1];
colormap(cm);
scatter(shipX, shipY, 10, '.', 'magenta');
a=0;

end


function outValue = plotRouteComparison()
%% Ville Lehtola 2018
% icepathfinder article plot. Hamina. closeup

folder = '/work/stormwinds/icepathfinder'; % change as needed
env_path = fullfile(folder, 'environment');
out_path = '/home/vlehtola/Dropbox/Indoor navigation/article-icepathfinder';

%route_path = fullfile(folder, 'results');
route_path = '/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/hamina_rauma-20110315/excluded_archipelago/results';

in_path = route_path;

pl_colormap_time=[
0.7500    1.0000    1.0000;
0.5961    0.9843    0.5961;
0.9597    0.9135    0.1423;
1.0000    0.5490         0;
1.0000         0         0;
1,0,0;1,0,0;1,0,0;0.5 0.5 0.5];


pl_colormap = [
% red:
1.0000         0    0;
% dark orange:
1.0000    0.5490         0;
% yellow:
0.9597    0.9135    0.1423;
% Pale green:
0.5961    0.9843    0.5961;
% Light cyan:
0.75 1 1;
];

tic;
UNAVIGABLE = 5;
GROUND = 6;

[search, latitude, longitude, inverseSpeed, navigationGrid, drawUpdates, startTime,speed,stuck, hi, heq] = init(env_path, in_path);

% load AIS data
load('/work/stormwinds/STORMWINDS/_ FGI_AIS_Stormwinds_Task_4.1/_ FGI_AIS_Stormwinds_Task_4.1/GSI_super.mat');

% load computed path
load( fullfile(route_path, 'optimizedPathAndSpeedArray.mat'), 'optimizedPath', 'route', 'stepsAndCosts');

% load subcell optimized route data to obtain the optimal travel time
load( fullfile(route_path, 'optimizedPathAndSpeedArray.mat'), 'route');

manualRoute = getPlannedRoute("Hamina", latitude, longitude);

%travels = { {'super2', 1}, {'super2', 7}, {'super11', 3}, {'super12', 3}, {'super17', 5}, {'super25', 2}, {'super29', 1} };
travels = [ [2 1]; [2 7]; [11 3]; [12 3]; [17 5]; [25 2]; [29 1] ];

travels = [ [12 3];];

% construct a time series of xy-coords that can be then plotted
for i =1:size(travels,1)
    shipInd = travels(i, 1);
    s = int2str(shipInd);
    eval(['rowIndex=voyages',s,';shipData=super',s,';'])        % prep data for that ship
    voyage = travels(i, 2);
    shipLat = shipData(rowIndex(voyage, 1): rowIndex(voyage, 2), 5); % load a certain time series
    shipLon = shipData(rowIndex(voyage, 1): rowIndex(voyage, 2), 4); % load a certain time series
    shipTime = shipData(rowIndex(voyage, 1): rowIndex(voyage, 2), 2); % load a certain time series
    shipSpeed = shipData(rowIndex(voyage, 1): rowIndex(voyage, 2), 3);
    
    len = rowIndex(voyage, 2) - rowIndex(voyage, 1);
    xy = zeros(len, 2);
    for j =1:len
        lat = shipLat(j);
        lon = shipLon(j);
        [xy(j,1), xy(j,2)] = calcXY(latitude, longitude, lat, lon);
        %tmpMap(xy(j,1), xy(j,2)) = 10;
    end
    
    %scatter(xy(:,1), xy(:,2), 10, '.', 'magenta');
end

xy = xy(floor(end/4):floor(end*0.74), :);      % cut out some data
ss = shipSpeed(floor(end/4):floor(end*0.74), :);
st = shipTime(floor(end/4):floor(end*0.74), :);

unix_epoch = datenum(1970,1,1,0,0,0);
matlab_time1 = st(1)./86400 + unix_epoch; 
matlab_time2 = st(end)./86400 + unix_epoch; 

meanSpeed = mean(ss);
medianSpeed = median(ss);
sortedss = sort(ss);
topSpeed = mean( sortedss(floor(end*9/10):end) );
timeInHours = etime(datevec(matlab_time2), datevec(matlab_time1))/60/60;
fprintf('AIS ship, time spent in hours: %f Speeds (knots): Top %f Mean %f Median %f\n', timeInHours, topSpeed, meanSpeed, medianSpeed);

h= figure(66);
clf(h, 'reset');                             % clear the figure

%% speed map
subplot(1,2,1);

Data_Array = speed(:,:,1); %% this is the data we use
imAlpha=ones(size(Data_Array));
imAlpha(isnan(Data_Array))=0;    
tmpind = find(navigationGrid >= GROUND);
imAlpha(tmpind)=0;
tmpind = find(navigationGrid == UNAVIGABLE);
imAlpha(tmpind)=1;                  % show non-navigable depths also

imagesc(Data_Array,'AlphaData',imAlpha);            % plot
hold on;
colormap(gca, pl_colormap)
set(gcf,'color','w');               % background to white
%set(gca,'color',0.8*[1 1 1]);       % alpha to grey

% colorbar settings
cb = colorbar(gca);
ylabel(cb, 'knots');
cbl = {'';'IB';'6';'7';'8';'9';'10';'11';'12';'13'};
cbt = [4 5 6 7 8 9 10 11 12 13];
cb.TickLabels = cbl;
cb.Ticks = cbt;

bw = 0.03;   % bar width
set(cb,'location','manual','position',[0.38 0.5 bw 0.4])

%plot(xy(:,2), xy(:,1), '-.b', 'LineWidth',2);
%plot(optimizedPath(:,2), optimizedPath(:,1), '-k', 'LineWidth',2);
%plot(manualRoute(:, 2), manualRoute(:,1), ':m', 'LineWidth',2);

camroll(90);
ax = gca;
set(ax, 'xAxisLocation', 'top');
xlabel('Latitude');
ylabel('Longitude');    
[ySEt, xSEt] = calcXY(latitude, longitude, 57, 17);
grid on
step = 120;
xticks(xSEt:step:2000);
yticks(ySEt:step:2000);
xticklabels(string(latitude(1,xSEt:step:end)));
yticklabels(string(longitude(ySEt:step:end,1)));

[xne, yne] = calcXY(latitude, longitude, 62, 28);
[xsw, ysw] = calcXY(latitude, longitude, 59, 18);
ylim([ xsw xne ] );
xlim([ ysw yne ] );

tc=text(xSEt+120*4.75, ySEt+60+5*120,'(a)');
tc.FontSize = 18;


%% time map
subplot(1,2,2);
load(fullfile(route_path, 'integratedCostMatrix.mat'), 'costMatrixAB', 'costMatrixBA');

travelTime = route(end-1,8);                  % travelTime in hours
fprintf('Travel time (optimized): %f (h)', travelTime );
A= full(costMatrixAB);
B=full(costMatrixBA);
mask=A;
mask(mask~=0)=1;
mask(B==0)=0;
asum=(A+B).*mask;       
% mappaa aikaan. 1 nautical mile / ( 1 m/s )
% eli kaiva referenssiaika optimoidusta pathista ja sitten
% plottaa ajan lis�ys jos poikkeat kurssilta.
%asum = asum / 1852 * 3600;    
% conffaa plottia varten
asum(asum==0)=NaN;
minVal = min(min(asum, [], 'omitnan'), [], 'omitnan');
%minVal = min(min(asum));
asum = asum ./ minVal .* travelTime;            % normalize to optimum
%% set the top X % to the max value, redefine min and max
minVal = round( min(min(asum, [], 'omitnan'), [], 'omitnan') );    
threshold = round( minVal + 10);            % max +10h delays
asum(asum > threshold) = threshold;
maxVal = threshold;

%% discretize for colorization
colorLayers = 40;
asum = asum ./ maxVal .* colorLayers;
asum = round(asum);
asum = asum ./ colorLayers .* maxVal;
asum = round(asum);    

imAlpha=ones(size(asum));
imAlpha(isnan(asum))=0;
imAlpha(navigationGrid < GROUND) = 1;
asum(isnan(asum) & navigationGrid < GROUND) = maxVal;
hold off
imagesc(asum,'AlphaData',imAlpha);            % plot    
hold on;
cmap = colormap(gca, 'jet');            % default
%cmap(minVal,:) = [0.5 0.5 0.5];
% steps in colormap == hours
stepCmap = floor( size(cmap, 1) /(maxVal- minVal) );
arvot = 1:stepCmap:size(cmap, 1);
erotus = size(arvot,2) - (maxVal - minVal);
if(erotus < 0)
    erotus = 0;
end

if(erotus >= 0 )        
    arvot = [1 arvot(3+erotus:end) 64]; 
end    
cmap = cmap(arvot, :);
cmap(end,:) = [0.5 0.5 0.5];       % display value X as grey

colormap(gca, pl_colormap_time)
%colormap(gca, cmap);
cb2=colorbar(gca);
ylabel(cb2, 'Time (h)');
%set(cb,'location','manual','position',[1.05 0.0 0.05 1])
set(cb2,'location','east');
X = [search.originX, search.destinationX];
Y = [search.originY, search.destinationY];
scatter(Y,X, 15, 'r')

hold on

plot(xy(:,2), xy(:,1), '-.b', 'LineWidth',2);
plot(optimizedPath(:,2), optimizedPath(:,1), '-k', 'LineWidth',2);
plot(manualRoute(:, 2), manualRoute(:,1), ':m', 'LineWidth',2);

camroll(90);
ax2 = gca;
set(ax2, 'xAxisLocation', 'top');
xlabel('Latitude');
ylabel('Longitude');    
[ySEt, xSEt] = calcXY(latitude, longitude, 57, 17);
grid on
step = 120;
xticks(xSEt:step:2000);
yticks(ySEt:step:2000);
xticklabels(string(latitude(1,xSEt:step:end)));
yticklabels(string(longitude(ySEt:step:end,1)));

ylim([ xsw xne ] );
xlim([ ysw yne ] );

tc=text(xSEt+120*4.75, ySEt+60+5*120,'(b)');
tc.FontSize = 18;


%% finally, print

font_rate=10/12;
f_height=3;
f_width=3;
set(gcf,'Position',[100   200   4*round(f_width*font_rate*144)   round(f_height*font_rate*144)]);
set(gca, 'FontName', 'Times')
set(gcf,'color','w');                % background to white
print(h,fullfile(out_path, 'plotRouteComparisonHaminaCloseup'),'-dpng')

end


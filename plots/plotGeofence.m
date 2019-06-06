function [outputArg1,outputArg2] = plotGeofence()
%% Ville Lehtola 2018
% icepathfinder article plot. plot bathymetry data with computational routes
% and compare computational mask with AISmask. validate narrow seaway
% exclusion.


%% define environmental variables
if (nargin == 0)
    folder = '/work/stormwinds/icepathfinder';     % change as needed
    env_path = fullfile(folder, 'environment');
    init_path = fullfile(folder, '.');          % speed data loaded from here, speed not used
end

pl_colormap = [
% Light cyan:
0.75 1 1;
% Pale green:
0.5961    0.9843    0.5961;
% yellow:
0.9597    0.9135    0.1423;
];

pl_colormap_ext = [
% Light cyan:
0.75 1 1;
% Royal blue:
0.2549    0.4118    0.8824;
% Grey:
0.7451    0.7451    0.7451;
% yellow:
0.9597    0.9135    0.1423;
];

fid = fopen(fullfile(folder, 'INPUT_icepathfinder.txt'), 'w');
fprintf(fid, 'helmigri_20110320_0600 65.577 24.328 58.241 18.219 10 8 1\n');     % note the last 1
fclose(fid);

%'Departure time [Year,Month,Day, UTC Hours,Minutes]\nDeparture coords [Lat,Long]\nArrival coords [Lat,Long]\nSafe_depth (meters)\nTime_steps (integer)\ngebco=0,geofence=1(def),AISmask=2\n');

UNAVIGABLE = 5;
GROUND = 6;

%outpath = 'C:\Users\vle\Dropbox\Indoor navigation\article-icepathfinder';
outpath = '/home/vlehtola/Dropbox/Indoor navigation/article-icepathfinder';

folderStack = {
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/hamina_rauma-20110315/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/hamina_rauma-20110315/through_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/oulu_AISpoint-20110203/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/oulu_AISpoint-20110203/through_archipelago/results'
%'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kemi_AISpoint-20110320/excluded_archipelago/results'
%'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kemi_AISpoint-20110320/through_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kotka_AISpoint-20110301/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kotka_AISpoint-20110301/through_archipelago/results'
};

%plotColors = [ 'g'; 'r'; 'g'; 'r'; 'g'; 'r' ];
plotColors = { '-k' '-r' '-.k' '-.r' '-.k' '-.r' };

koko = size(folderStack, 1);
tic;

[search, latitude, longitude, inverseSpeed, navigationGrid, drawUpdates, startTime,speed,stuck, hi, heq] = init(env_path, init_path);

h = figure(20);  
clf(h, 'reset');                             % clear the figure
hold off
% taustakuva eli pohja
pohja = navigationGrid; 
%pohja = pohja(1:2:end, 1:2:end);
pohjaAlpha=ones(size(pohja));
pohjaAlpha(pohja >= GROUND) = 0;

subplot(1,2,1);
colormap(gca, pl_colormap)
imagesc(pohja,'AlphaData',pohjaAlpha);
%imagesc(data,'AlphaData',imAlpha);

%% ice situation and ship routes
hold on
for i = 2:2:6           % plot only red routes
    route_path = folderStack{i, :};
    load( fullfile(route_path, 'optimizedPathAndSpeedArray.mat'), 'optimizedPath', 'route', 'stepsAndCosts');
    plot(optimizedPath(:,2), optimizedPath(:,1), plotColors{i}, 'LineWidth',1.3);
end

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
%yticklabels(string(longitude(ySEt:step:end,1)));

tmplabels = string(longitude(ySEt:step:end,1));
tmplabels(2:2:end) = "";        % each other label is empty for vis. purposes
yticklabels(tmplabels);

set(gcf,'color','w');                % background to white
%title('Navigable depth with computed route');
daspect([1 2 1]);
tc=text(xSEt+120*7.75, ySEt+60,'(a)');
tc.FontSize = 18;

annotation('textarrow', [0.3 0.265], [0.5 0.4], 'String', 'ÅA');
annotation('textarrow', [0.185 0.206], [0.35 0.36], 'String', 'SA');
annotation('textarrow', [0.3 0.245], [0.65 0.72], 'String', 'Kvarken');

subplot(1,2,2);

fid = fopen(fullfile(folder, 'INPUT_icepathfinder.txt'), 'w');
fprintf(fid, 'helmigri_20110320_0600 65.577 24.328 58.241 18.219 10 8 0\n');     % note the last 0
fclose(fid);

[search, latitude, longitude, inverseSpeed, navigationGrid, drawUpdates, startTime,speed,stuck, hi, heq] = init(env_path, init_path);

if(true)
   %% use a degree of freedom mask obtained from AIS data
    load('/work/stormwinds/icepathfinder/external_data/dof-AISmask.mat', 'AISmask');
    % extend AISmask to the same size than navigationGrid and speed map
    icMask=repelem(AISmask', 4, 2);
    %icMask = icMask(1:1645, :);
    icMask(36:1635, :) = icMask(1:1600, :);
    
    icMask = icMask(1:1645, :);
    icMask(:, 1113) = icMask(:, 1112);
    testGrid = navigationGrid;
    %testGrid(icMask == 0 & navigationGrid < UNAVIGABLE) = UNAVIGABLE;
    %testGrid(icMask == 1 & navigationGrid == UNAVIGABLE) = 0;
    testGrid(icMask == 0 & navigationGrid < UNAVIGABLE) = 3;    % for colors in plotting
    testGrid(icMask == 1 & navigationGrid == UNAVIGABLE) = 2;
    pohja = testGrid;
    pohjaAlpha=ones(size(pohja));
    pohjaAlpha(pohja >= GROUND) = 0;
    imagesc(pohja,'AlphaData',pohjaAlpha);
    
    %cmap = colormap
    colormap(gca, pl_colormap_ext);
end

%% ice situation and ship routes
hold on
for i = koko:-1:1                       % reverse order to get greens on top
    route_path = folderStack{i, :};
    load( fullfile(route_path, 'optimizedPathAndSpeedArray.mat'), 'optimizedPath', 'route', 'stepsAndCosts');
    plot(optimizedPath(:,2), optimizedPath(:,1), plotColors{i}, 'LineWidth',1.3);
end

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
%yticklabels(string(longitude(ySEt:step:end,1)));

tmplabels = string(longitude(ySEt:step:end,1));
tmplabels(2:2:end) = "";        % each other label is empty for vis. purposes
yticklabels(tmplabels);

set(gcf,'color','w');                % background to white
%title('Navigable depth with computed route');
daspect([1 2 1]);

tc=text(xSEt+120*7.75, ySEt+60,'(b)');
tc.FontSize = 18;

% reset the input file just in case..
fid = fopen(fullfile(folder, 'INPUT_icepathfinder.txt'), 'w');
fprintf(fid, 'helmigri_20110320_0600 65.577 24.328 58.241 18.219 10 8 0\n');     % note the last 0
fclose(fid);

%% finally, print

font_rate=10/12;
f_height=3;
f_width=3;
set(gcf,'Position',[100   200   2*round(f_width*font_rate*144)   round(f_height*font_rate*144)]);
set(gca, 'FontName', 'Times')
print(h,fullfile(outpath, 'plotGeofence'),'-dpng')

end


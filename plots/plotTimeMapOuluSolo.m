function outValue = plotSpeedMapOuluSolo()
%% Ville Lehtola 2018
% icepathfinder plot. not in article. Oulu. multiplot with speed&time maps and ship-ship mask
% effects.

folder = '/work/stormwinds/icepathfinder'; % change as needed
env_path = fullfile(folder, 'environment');
out_path = '/home/vlehtola/Dropbox/Indoor navigation/article-icepathfinder';

% first plot one and then plot the other
%route_path = '/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/oulu_balticW-20110203/excluded_archipelago/results';
route_path = '/work/stormwinds/STORMWINDS/output_routeset_timesteps_meanField/oulu_balticW-20110203/excluded_archipelago/results';
in_path = route_path;

% orange:
% 1.0000    0.6471         0
% dark orange:
% 1.0000    0.5490         0
% Pale green:
% 0.5961    0.9843    0.5961;
% Light pink:
% 1.0000    0.7137    0.7569

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

pl_colormap_time=[
0.7500    1.0000    1.0000;
0.5961    0.9843    0.5961;
0.9597    0.9135    0.1423;
1.0000    0.5490         0;
1.0000         0         0;
1,0,0;1,0,0;1,0,0;1,0,0;1,0,0;1,0,0];


UNAVIGABLE = 5;
GROUND = 6;

tic;

[search, latitude, longitude, inverseSpeed, navigationGrid, drawUpdates, startTime,speed,stuck, hi, heq] = init(env_path, in_path);

% load computed path
load( fullfile(route_path, 'optimizedPathAndSpeedArray.mat'), 'optimizedPath', 'route', 'stepsAndCosts');

h=figure(1);
clf(h, 'reset');                             % clear the figure

%subaxis(1,2,2,'SpacingVert',0.0,'SpacingHoriz',0.1);

load(fullfile(route_path, 'integratedCostMatrix.mat'), 'costMatrixAB', 'costMatrixBA');

travelTime = route(end-1,8);                  % travelTime in hours
fprintf('Travel time (optimized): %f (h)\n', travelTime );
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
cmap=pl_colormap_time(1:size(cmap,1), :);

cmap(end,:) = [0.5 0.5 0.5];       % display value X as grey
colormap(gca, cmap);
cb4=colorbar(gca);
ylabel(cb4, 'Time (h)');
%set(cb,'location','manual','position',[1.05 0.0 0.05 1])
set(cb4,'location','east');
X = [search.originX, search.destinationX];
Y = [search.originY, search.destinationY];
scatter(Y,X, 15, 'r')

hold on

%plot(xy(:,2), xy(:,1), '-.b', 'LineWidth',2);
plot(optimizedPath(:,2), optimizedPath(:,1), '-k', 'LineWidth',2);
%plot(manualRoute(:, 2), manualRoute(:,1), ':m', 'LineWidth',2);

camroll(90);
ax = gca;
set(ax, 'xAxisLocation', 'top');
xlabel('Latitude');
ylabel('Longitude');    
[ySEt, xSEt] = calcXY(latitude, longitude, 62, 19);
grid on
step = 120;
xticks(xSEt:step:2000);
yticks(ySEt:step:2000);
xticklabels(string(latitude(1,xSEt:step:end)));

%yticklabels(string(longitude(ySEt:step:end,1)));
tmplabels = string(longitude(ySEt:step:end,1));
%tmplabels(2:2:end) = "";        % each other label is empty for vis. purposes
yticklabels(tmplabels);
xlim([ xSEt xSEt+step*4]);
ylim([ ySEt ySEt+step*8]);

tc=text(xSEt+120*3.75, ySEt+60,'Time map');
tc.FontSize = 18;

%% output

font_rate=10/12;
f_height=3;
f_width=3;
set(gcf,'Position',[100   200   round(f_width*font_rate*144)   1.15*round(f_height*font_rate*144)]);
set(gcf,'color','w');                % background to white
set(gca, 'FontName', 'Times')
print(h,fullfile(out_path, 'plotTimeMapOulu'),'-dpng')


%figure(2);
%imagesc(hi(:,:,1));
%figure(3);
%imagesc(heq(:,:,1));


end
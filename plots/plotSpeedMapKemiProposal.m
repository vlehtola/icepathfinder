function outValue = plotSpeedMapOuluSolo()
%% Ville Lehtola 2018
% icepathfinder plot. for proposal. Kemi. multiplot with speed&time maps and ship-ship mask
% effects.

folder = '/work/stormwinds/icepathfinder'; % change as needed
env_path = fullfile(folder, 'environment');
out_path = '/home/vlehtola/Dropbox/Indoor navigation/article-icepathfinder';

% first plot one and then plot the other
route_path = '/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kemi_AISpoint-20110320/excluded_archipelago/results';
%route_path = '/work/stormwinds/STORMWINDS/output_routeset_timesteps_meanField/kemi_AISpoint-20110320/excluded_archipelago/results';
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
%1.0000    0.5490         0;
% yellow:
0.9597    0.9135    0.1423;
% Pale green:
%0.5961    0.9843    0.5961;
% Light cyan:
0.75 1 1;
0.75 1 1;
0.75 1 1;
0.75 1 1;
0.75 1 1;
];

UNAVIGABLE = 5;
GROUND = 6;

tic;

[search, latitude, longitude, inverseSpeed, navigationGrid, drawUpdates, startTime,speed,stuck, hi, heq] = init(env_path, in_path);

h=figure(1);
clf(h, 'reset');                             % clear the figure

%subaxis(1,2,2,'SpacingVert',0.0,'SpacingHoriz',0.1);

Data_Array = speed(:,:,1); %% this is the data we use
imAlpha=ones(size(Data_Array));
imAlpha(isnan(Data_Array))=0;    
tmpind = find(navigationGrid >= GROUND);
imAlpha(tmpind)=0;
tmpind = find(navigationGrid == UNAVIGABLE);
imAlpha(tmpind)=1;                  % show non-navigable depths also

Data_Array(tmpind) = 4;     % set too shallow cells to contain unpenetrable ice
hold off;
imagesc(Data_Array,'AlphaData',imAlpha);            % plot
hold on;
colormap(gca, pl_colormap)
set(gcf,'color','w');               % background to white
%set(gca,'color',0.8*[1 1 1]);       % alpha to grey

% % colorbar settings
% cb3 = colorbar(gca);
% ylabel(cb3, 'knots');
% cbl = {'';'IB';'6';'7';'8';'9';'10';'11';'12';'13'};
% cbt = [4 5 6 7 8 9 10 11 12 13];
% cb3.TickLabels = cbl;
% cb3.Ticks = cbt;

bw=0.015;
%set(cb3,'location','east');
%%set(cb3,'location','manual','position',[0.28 0.25 bw 0.2])

%plot(xy(:,2), xy(:,1), '--y', 'LineWidth',2);
%plot(optimizedPath(:,2), optimizedPath(:,1), 'g', 'LineWidth',2);
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

%yticklabels(string(longitude(ySEt:step:end,1)));
tmplabels = string(longitude(ySEt:step:end,1));
%tmplabels(2:2:end) = "";        % each other label is empty for vis. purposes
yticklabels(tmplabels);
%xlim([ xSEt xSEt+step*4]);
%ylim([ ySEt ySEt+step*8]);

[C,ch]=contourf(Data_Array, [5.5 7]);
%clabel(C,h);

% 3 ja 2, 4 ja 1
%annotation('textarrow', [xSEt+step*1 xSEt+step*2], [ySEt+step*4 ySEt+step*3], 'String', 'easy ice');
%annotation('textarrow', [0.735 0.7], [0.4 0.5], 'String', 'easy ice');

%title("Sea zones operable with IA super -ice-class ship");

%tc=text(xSEt+120*3.75, ySEt+60,'Date 2011-03-20 at 0600');
%tc.FontSize = 18;

%% output

font_rate=10/12;
f_height=3;
f_width=3;
set(gcf,'Position',[100   200   round(f_width*font_rate*144)   1.15*round(f_height*font_rate*144)]);
set(gcf,'color','w');                % background to white
set(gca, 'FontName', 'Times')
print(h,fullfile(out_path, 'plotSpeedMapKemiProposal'),'-dpng')


%figure(2);
%imagesc(hi(:,:,1));
%figure(3);
%imagesc(heq(:,:,1));


end
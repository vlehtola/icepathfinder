function outparam = plotCPUtime()
%% Ville Lehtola 2018
% icepathfinder article table. CPU time
% Dijkstra's algoritm scales in worst case as O(m + n log(n)), n = nodes,
% m=edges.
% See: W. Dijkstra. A note on two problems in connexion with graphs,  Numerische Mathematik,1  (1959),pp. 269-271.

nodes = 1645*1113;
edges = 1644*1112*2;
theor_x = 1:600;        % characteristic length?
n = theor_x.* theor_x;   % area
m = n*2;
C = 0.000016;
theor_y = C * (m + n.*log(n) );

outpath = '/home/vlehtola/Dropbox/Indoor navigation/article-icepathfinder';

% 1:4 time dependent, 5:8 no time dep %% TODO: include no time dep calcs
folderStack = {
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_meanField/oulu_balticW-20110203/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_meanField/hamina_rauma-20110315/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_meanField/kemi_balticW-20110320/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_meanField/kotka_gdansk-20110301/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/oulu_balticW-20110203/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/hamina_rauma-20110315/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kemi_balticW-20110320/excluded_archipelago/results'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kotka_gdansk-20110301/excluded_archipelago/results'
};


koko = size(folderStack, 1);

data = zeros(koko, 3);

for i = 1:koko
    inpath = folderStack{i, :};
    infilename = fullfile(inpath, 'timeToComputeRoute.txt');        % minutes    
    fileID = fopen(infilename, 'r');
    C = textscan(fileID, '%f');
    timeInMins = C{1};
    fclose(fileID);
    
    infilename= fullfile(inpath, 'OUTpathLength.txt');      % nautical miles
    fileID = fopen(infilename, 'r');
    C = textscan(fileID, '%s');
    traveledDistance = str2double( C{1}{end-1} );
    fclose(fileID);
    
    data(i, :) = [ timeInMins, traveledDistance, i];
    
end

%data = sort(data);

% plot CPU time as a function of route length
h = figure(56);
clf(h, 'reset');                             % clear the figure    
hold on
scatter(data(1:4,2), data(1:4,1), 100, 'x', 'black')     % time dependent
scatter(data(5:8,2), data(5:8,1), 'o', 'black')     % other

fprintf("Time (min), Traveled distance (NM)");
data(1:4,1:2)

plot(theor_x, theor_y, ':g', 'LineWidth',3);

plot([0 700], [60 60], '--r');

ylabel('t (min)');
xlabel('Route distance (NM)');
ylim([0 65]);
xlim([0 520]);
set(gcf,'color','w');                % background to white

font_rate=10/12;
f_height=3;
f_width=5;
set(gcf,'Position',[100   200   round(f_width*font_rate*144)   round(f_height*font_rate*144)]);
set(gca, 'FontName', 'Times')
print(h,fullfile(outpath, 'plotCPUtime'),'-dpng')

end


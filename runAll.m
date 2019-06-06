function outValue = runAll()
%% Run all runs. Ville Lehtola 2017

FULLRUN = true;

baseFolder = '/work/stormwinds/icepathfinder/'; % change as needed

folderStack = {
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_meanField/oulu_AISpoint-20110203/excluded_archipelago'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/oulu_AISpoint-20110203/excluded_archipelago'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/oulu_AISpoint-20110203/through_archipelago'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_meanField/kotka_AISpoint-20110301/excluded_archipelago'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kotka_AISpoint-20110301/excluded_archipelago'
'/work/stormwinds/STORMWINDS/output_routeset_timesteps_noMeanfield/kotka_AISpoint-20110301/through_archipelago'
};


for i =1:size(folderStack,1)
    folder = folderStack{i,:};
    copyfile(fullfile(folder, 'INPUT_icepathfinder.txt'), fullfile(baseFolder, 'INPUT_icepathfinder.txt'));
    env_path = fullfile(baseFolder, 'environment');
    in_path = fullfile(baseFolder, '.');
    out_path = fullfile(folder, 'results');
    route_path = fullfile(folder, 'results');

    if(FULLRUN)
        integratedTimeMap(env_path, in_path, out_path);
    else
        % plot stuff only
    end
end

end


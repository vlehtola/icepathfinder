function [outputArg1,outputArg2] = findWindChange()
%% Ville Lehtola 2018
% Pair-correlates ice maps to find when the wind has shifted radically
% Tulee etsia liiketta kohti lantta. Eli kohti gridin vasenta reunaa.
% Tama parikorrelaatiolla?

%% L2-norm
% 1-day correlation
%iceFilename = 'helmigri_20110203_0000';
% New max: 6.599839e+02 helmigri_20110225_1200 
% Unable to read file 'HELMI\2011\helmigri_20110227_0000'. No such file or directory.
% RUN from: helmigri_20110228_0000
% New max: 1.275104e+03 helmigri_20110304_1800  % liiketta ruotsiin pain
%  1.547636e+03 helmigri_20110309_0600 

% 2-day correlation
% New max: 1.221999e+03 helmigri_20110225_0000 % liiketta pohjoista kohti
% New max: 2.542641e+03 helmigri_20110308_1200 % liiketta pohjoista kohti

%% L1-norm
% 2-day
% New max: 2.972257e+03 helmigri_20110225_0000 
% New max: 5.929057e+03 helmigri_20110308_1200 

%% west-side shift. eli ruottia kohti. 2-day
% New max: 5.473423e+03 helmigri_20110327_0000 
% New max: 3.024626e+03 helmigri_20110225_0000 

% input variables

iceFilename = 'helmigri_20110225_0000';
iceDataPath = 'HELMI/2011/';
timeSteps = 8;          % 4 is 1-day, 8 is 2-days

% initialize
fmtDT='yyyyMMdd_HHmm';          % format for datetime
fmtSR='yyyymmdd_hhMM';          % format for datestr
dateStr = iceFilename(10:22);
timeStamp = datetime(dateStr, 'InputFormat',fmtDT);
loadNext = true;

prevMax = 0;

% loop
for i = 1:300                               % 300 % run till no file found
    filename = strcat('helmigri_', datestr(timeStamp,fmtSR));
    timeStamp = timeStamp + hours(6);       % advance time for next loop

    % NOTE: here we create 556x415xtimeSteps matrices!
    [levelIceTh, ridgedIceTh, totalIceConc, ridgedIceConc] = loadHELMIData(iceDataPath, filename, timeSteps);

    % pair-correlate
    ridgedIceTh(isnan(ridgedIceTh)) = 0;
    ridgedIceConc(isnan(ridgedIceConc)) = 0;
    
    val1 = ridgedIceTh(:,:,1) .*ridgedIceConc(:,:,1);
    val2 = ridgedIceTh(:,:,timeSteps).*ridgedIceConc(:,:,timeSteps);
    %diff = val1.*val1 - val2.*val2;     % L2 norm
    diff = val1 .* circshift(val2, 1);     % L1 norm w shift
    maxVal = sum(sum( abs(diff)));
    if(maxVal > prevMax)
        prevMax = maxVal;
        fprintf('\nNew max: %d %s \n', prevMax, filename);
    end
    fprintf('i:%i ', i);
end

end


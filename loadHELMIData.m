function [levelIceTh, ridgedIceTh, totalIceConc, ridgedIceConc] = loadHELMIData(iceDataPath, iceFilename, timeSteps)
%% load HELMI data
% And transfer it from 556x415 to 556x830 grid. Output levelIce, ridgedIce,
% iceConcentration.
% Ville Lehtola 2017
%
% Input from HELMI model contains 6 matrices 556x415 in size
% avg_th:        	Average thickness                   H
% rafted_conc:  Rafted ice concentration                CRa   
% rafted_th:     	Rafted ice thickness                HRa
% ridged_conc: Ridged ice concentration                 CRi    
% ridged_th:     Ridged ice thickness                   HRi 
% total_conc:    Total ice concentration                C	
% 
% The yaxis is same as for FMI ice charts, while 
% 	xaxis=16.7:(1/30):30.5;
% and ice chart grid matches the subgrid of HELMI grid  (:,10:end).

% ex. filename = helmigri_20110320_0600

fmtDT='yyyyMMdd_HHmm';          % format for datetime
fmtSR='yyyymmdd_hhMM';          % format for datestr
dateStr = iceFilename(10:22);
timeStamp = datetime(dateStr, 'InputFormat',fmtDT);
filename = iceFilename;

YDIM = 830; 

levelIceTh = zeros(556, YDIM, timeSteps);
ridgedIceTh = zeros(556, YDIM, timeSteps);
totalIceConc = zeros(556, YDIM, timeSteps);
ridgedIceConc = zeros(556, YDIM, timeSteps);

for i = 1:timeSteps
    fullFilename = fullfile(iceDataPath, filename);
    [lt, rt, tc, rc] = loadData(fullFilename);
    timeStamp = timeStamp + hours(6);       % advance time for next loop
    filename = strcat('helmigri_', datestr(timeStamp,fmtSR));
    levelIceTh(:,:,i) = lt;
    ridgedIceTh(:,:,i) = rt;
    totalIceConc(:,:,i) = tc;
    ridgedIceConc(:,:,i) = rc;
    
end
end

    
function [levelIceTh, ridgedIceTh, totalIceConc, ridgedIceConc] = loadData(fullFilename)
    
    load(fullFilename, 'avg_th', 'total_conc', 'rafted_th', 'rafted_conc', 'ridged_conc', 'ridged_th');
    % deal with NaNs: concentrations do not contain these, but thicknesses do.
    % avg_th is defined for the whole sea area, so use it to introduce zeros to
    % other matrics.

    ridged_th(isnan(ridged_th) & ~isnan(avg_th)) = 0;
    rafted_th(isnan(rafted_th) & ~isnan(avg_th)) = 0;

    % level and rafted ice together
    levelIceTh = (avg_th.*total_conc - ridged_th.*ridged_conc) ./ (total_conc - ridged_conc);
    levelIceConc = total_conc - ridged_conc;
    % ridged ice
    ridgedIceTh = ridged_th;
    ridgedIceConc = ridged_conc;

    totalIceConc = total_conc;

    % Level ice thickness is obtained as  (H*C-HRa*CRa-HRi*CRi)/(C-CRa-CRi)  
    % and its concentration is (C-CRa-CRi) 
    % 'Equivalent  thickness of deformed ice' which considers ridged and 
    % rafted types as one deformed ice class is obtained as 
    % (HRa*CRa+HRi*CRi)/(CRa+CRi) and the concentration is (CRa+CRi)
    % If one wished to include rafted ice to level ice, then 'Equivalent 
    % thickness of ridged ice' is HRi and concentration CRi, while level ice 
    % thickness is (H*C -HRi*CRi)/(C -CRi)  and its concentration is (C -CRi).


    %% reshape matrices    
    levelIceTh = repelem(levelIceTh,1,2);      % expand to 556x830 grid
    ridgedIceTh = repelem(ridgedIceTh,1,2);
    ridgedIceConc = repelem(ridgedIceConc,1,2);
    totalIceConc = repelem(totalIceConc,1,2);
    %levelIceConc = repelem(levelIceConc,1,2);
end


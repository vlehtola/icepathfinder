function [metaStuck] = interpolationMetaStuck(x,y,env_path)
%interpolationMetaSpeed(v_m,x,y) interpolates the probabiliy of stuck values from the precalculated array from ship transit model.
% 
% This array - v_m - of the mean speeds. bst is array of 1 or 0, 1 when ship is beset in ice. For those cases v_m has entry of 0. ram is array of integers, the number of rams for the case.
% 15 minute simulations.
% All arrays are indexed (i,j,k), where i is heq, j is hi and k is 200 cases of one instance of hi-heq combination.
% 
% In this function x corresponds to a column (ice thickness - hi), y to a row (equivalent ice thickness - heq).
% hi = 0.1:0.1:0.8; level ice thicknesses
% heq = 0.05:0.05:0.6; equivalent ice thicknesses

load(strcat(env_path, '/metaSpeed.mat'));
M = size(v_m,1);
N = size(v_m,2);

Stuck = mean(bst,3);

interpolatedStuck = @(x,y) interp2(1:N,1:M,Stuck,x,y,'spline',0);

% extrapolation variable (here=0) defines conditions outside the given
% regime (bst).

metaStuck=interpolatedStuck(x,y);

end
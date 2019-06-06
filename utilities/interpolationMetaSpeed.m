function [metaSpeed] = interpolationMetaSpeed(x,y,env_path)
%interpolationMetaSpeed(v_m,x,y) interpolates the speed values from the precalculated speed array from ship transit model.
% 
% This array - v_m - of the mean speeds. bst is array of 1 or 0, 1 when ship is beset in ice. For those cases v_m has entry of 0. ram is array of integers, the number of rams for the case.
% 15 minute simulations.
% All arrays are indexed (i,j,k), where i is heq, j is hi and k is 200 cases of one instance of hi-heq combination.
% 
% In this function x corresponds to a column (ice thickness - hi), y to a row (equivalent ice thickness - heq).
% x: hi = 0.1:0.1:0.8; level ice thicknesses
% y: heq = 0.05:0.05:0.6; equivalent ice thicknesses
% Note! indices x \in [0,8], y \in [0,12]

load(strcat(env_path, '/metaSpeed.mat'), 'bst', 'ram', 'v_m');
M = size(v_m,1);
N = size(v_m,2);

% Zero speed corresponds a case, where ship got stuck. However, we want
% to model the event of getting beset in ice only via the stuck probabilities, P(Stuck).
% So, we allow a small positive non-zero value for all velocities. (And to
% avoid dividing by zero in the future.)

speedMat= mean(v_m,3);
speedMat(speedMat<0.001)=0.001;    % allow a small positive non-zero value

interpolatedSpeed = @(x,y) interp2(1:N,1:M,speedMat,x,y,'spline');
metaSpeed=interpolatedSpeed(x,y);
maxSpeed = max(max(speedMat));
metaSpeed(metaSpeed > maxSpeed) = maxSpeed; % do not extrapolate the speed over the max.
end
function [X, Y] = searchClosestNavigableDepth(inputX, inputY, depthMask)
% if harbor coordinates are not within a GEPCO defined navigable depth for
% the sea floor, search for the closest GEPCO accepted depth near the
% harbor. return those coordinates X and Y.
% Ville Lehtola 2017


for searchRadius = 3:1:100
    window = [ inputX-searchRadius inputX+searchRadius inputY-searchRadius inputY+searchRadius];
    s = size(depthMask);
    window(1) = max( [ min( [window(1) s(1) ]) 1]);
    window(2) = max( [ min( [window(2) s(1) ]) 1]);
    window(3) = max( [ min( [window(3) s(2) ]) 1]);
    window(4) = max( [ min( [window(4) s(2) ]) 1]);

    trialArea = depthMask(window(1):window(2), window(3):window(4));

    navigableDepthIndex = find(trialArea==0);
    if(size(navigableDepthIndex) > 0)
        fprintf("[searchClosestNavigableDepth] Navigable depth found within %i nautical miles!\n", searchRadius);
        break
    else
        %fprintf("[searchClosestNavigableDepth] NAVIGABLE DEPTH NOT FOUND within %i nautical miles!\n", searchRadius);
    end

end

[miniX, miniY] = ind2sub(size(trialArea), navigableDepthIndex(1)); % pick the first point

rx = 0.5*(window(2)-window(1));
ry = 0.5*(window(4)-window(3));

X = inputX + miniX -rx;
Y = inputY + miniY -ry;

fprintf(" X Y %i %i \n", X, Y);

end


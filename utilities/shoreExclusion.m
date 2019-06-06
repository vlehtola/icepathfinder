function outputM = shoreExclusion(classGrid, value)
%% shoreExclusion.m function. Ville Lehtola 2017 
% morphologically dilate the non-navigable areas of classGrid using a ones(3) matrix.
% Fill the new spaces with 'value'.
% Background: shore areas are typically excluded from ship navigation. And
% when they are not, piloting is used instead of navigation.

A = classGrid;
A(A > 1) = 1;
dilationMask = ones(5); %ones(3);
M=dilateBinMatrix(A, dilationMask);

% after dilating by 2, erode by 1
dilationMask = ones(3);
invM=dilateBinMatrix(~M, dilationMask);
M = ~invM;

outputM = classGrid;
outputM(M==1 & A == 0) = value;

end


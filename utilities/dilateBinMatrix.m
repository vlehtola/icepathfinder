function outMatrix = dilateBinMatrix(inMatrix, strElem)
% Ville Lehtola 2017
% image morphology, dilation. (alternative)
% input is a binary matrix, and output is a dilated by strElem

%inMatrix = [1 2 3; 4 5 6; 7 8 10];     % test

%Structuring element
%strElem=[1 1 1; 1 1 1 ; 1 1 1 ];
m=floor(size(strElem,1)/2);
n=floor(size(strElem,2)/2);
%Pad array on all the sides
%C=padarray(inMatrix,[m n]);        % image package
sz = size(inMatrix) + [m*2 n*2];
imgPadded = zeros(sz, class(inMatrix)); 
imgPadded(m+1:end-m,n+1:end-n) = inMatrix; 
C= imgPadded;
D=false(size(inMatrix));       % logical array

for i=1:size(C,1)-(2*m)
    for j=1:size(C,2)-(2*n)
        Temp=C(i:i+(2*m),j:j+(2*n));
        D(i,j)=max(max(Temp&strElem));      % mark any overlap as 1
    end
end

%figure,imshow(D);
outMatrix = D;
end


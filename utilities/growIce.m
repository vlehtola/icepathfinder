function outMatrix = growIce(iceTh, grownArea, strElem)
% input is a value matrix, and output is dilated by strElem
%Structuring element
%strElem=[1 1 1; 1 1 1 ; 1 1 1 ];
m=floor(size(strElem,1)/2);
n=floor(size(strElem,2)/2);
%Pad array on all the sides
sz = size(grownArea) + [m*2 n*2];
grownAreaPadded = zeros(sz, class(grownArea)); 
grownAreaPadded(m+1:end-m,n+1:end-n) = grownArea; 
D=zeros(size(grownArea));        % value array

iceThPadded = zeros(sz, class(iceTh)); 
iceThPadded(m+1:end-m,n+1:end-n) = iceTh; 

for i=1:size(iceThPadded,1)-(2*m)
    for j=1:size(iceThPadded,2)-(2*n)
        tmp1=max(max(grownAreaPadded(i:i+(2*m),j:j+(2*n))));
        tmp2=iceThPadded(i:i+(2*m),j:j+(2*n));
        tmpval=max(max(tmp2.*strElem)) * tmp1;
        % make sure that the growth is only in the designated area
        D(i,j)=max(tmpval, D(i,j));      % use max value        

    end
end

%figure, imagesc(D);
outMatrix = D;

end


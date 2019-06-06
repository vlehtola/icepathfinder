%
% Normalizes matrix to be between the values 0 and 1
%
function normalizedMatrix = normalize(matrix)
    normalizedMatrix = matrix - min(matrix(:));
    normalizedMatrix = normalizedMatrix ./ max(normalizedMatrix(:));
end
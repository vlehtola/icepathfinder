function plotSpeedValues(speed)
    cm = colormap(cool(256));
    [rows,cols] = size(speed);
    maxSpeed = max(max(speed));
    speedInt = uint8((speed ./ maxSpeed) * 255);
    for i=1:rows
        for j=1:cols
            if speedInt(i,j) ~= 0
                plotPoint3([i,j],cm(speedInt(i,j),:));
            end
        end
    end
end

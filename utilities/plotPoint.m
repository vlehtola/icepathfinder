% this function may try to plot something out of boundaries
function h = plotPoint(point,color, mapHeight, mapWidth)
    x1 = point(1)-3;
    x2 = point(1)+3;
    y1 = point(2)+3;
    y2 = point(2)-3;
    
    h = patch([x1, x2, x2, x1],[y1, y1, y2, y2],color,'EdgeColor','none');
end
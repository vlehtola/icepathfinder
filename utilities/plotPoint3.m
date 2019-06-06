function h = plotPoint3(point,color)
    x1 = point(1)-1;
    x2 = point(1);
    y1 = point(2);
    y2 = point(2)-1;
    h = patch([x1, x2, x2, x1],[y1, y1, y2, y2],color,'EdgeColor','none');
end
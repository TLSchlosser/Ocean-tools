function h = circle(x,y,r,C)

th = 0:pi/50:2*pi;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
h = fill(xunit, yunit,C,'EdgeColor',C);

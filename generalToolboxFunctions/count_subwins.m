function [xw, yw] = count_subwins (minwindows)

xw = 1;
yw = 1;

while (xw * yw < minwindows)
    xw = xw + 2;
    yw = yw + 1;
end
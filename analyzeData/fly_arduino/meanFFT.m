read_arduino_tree();

figure;
for f = 1:3
    m=Collected_Data(f).meanFFT
    
    i = ((f-1) * 3) + 1
    subplot(3,3,i)
    bar(xScale,abs(m(3,:)));
    axis([0 max(xScale) 0 100]);
    
    subplot(3,3,i+1)
    bar(xScale,abs(m(5,:)));
    axis([0 max(xScale) 0 100]);
    
    subplot(3,3,i+2)
    bar(xScale,abs(m(8,:)));
    axis([0 max(xScale) 0 100]);
end
function plotData(src,event)
subplot(2,1,1);
plot(event.TimeStamps, event.Data)
axis([0,1,-15,15]);
subplot(2,1,2);
plot(event.TimeStamps, event.Data)
axis([0,1,-1,1]);
mean(event.Data)
end
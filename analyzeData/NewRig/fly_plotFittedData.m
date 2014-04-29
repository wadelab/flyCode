function status=fly_plotFittedData(contRange,data,fitParams,plotParams)
%function status=fly_plotFittedData(contRange,data,fitParams,plotParams)

contSupport=linspace(contRange(1),contRange(end),50);
outputLine=hyper_ratio(fitParams,contSupport);

h1=plot(contSupport,outputLine);
hold on;
h2=scatter(contRange,abs(data),'o');
status=[h1 h2];
hold off;


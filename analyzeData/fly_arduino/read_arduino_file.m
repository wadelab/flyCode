[f,p]=uigetfile('*.csv');
fName=fullfile(p,f);



%% read the table of contrasts
contrasts=csvread(fName, 1,0, [1,0,9,2]);



%% read the SSVEP data - 9 contrasts of 1024 data points

r=zeros(9,1024);
for i = 0:8
 iStart = 10+1024*i
 iEnd = 1033+1024*i
r(i+1,:)=csvread(fName, iStart,3, [iStart,3,iEnd,3]);
end;



%% subtract mean and do fft
figure();
for i = 0:8

r(i+1,:)=r(i+1,:)-mean(r(i+1,:));
subplot(9,1,i+1);
fData=fft(r(i+1,:));
bar(abs(fData(2:100)));
axis([0 100 0 5000]);


yTxt = strcat(num2str(contrasts(i+1,2)), '//', num2str(contrasts(i+1,3))) ;
ylabel(yTxt);

end;
% label bottom row
xlabel('Cycles per 4 s');
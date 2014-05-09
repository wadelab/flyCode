load ('c:\myspectra.mat') 


my_values_in = zeros(1,31); 
    %
    transposedvalues = transpose(sumPower);
    measurements = transposedvalues;
    my_values_out = zeros(1,256);
    
    fitType = 5 ;  %%'crtLinear'

    FitGamma(my_values_in,measurements,my_values_out,fitType)
   
i = 1;
k = 1;
while (i < nContrasts)
  j = i + 1;
while (j < nContrasts && isequal(c1(i,:), c1(j,:)))
  disp ([i, '  ' ,j]);
j = j + 1;
end;

av_CRF(k,:) = mean(CRF(i:j-1,:),1) % ; % need the ,1 to force it to work if i==j
  k = k + 1 ;
i = j ;
end


 


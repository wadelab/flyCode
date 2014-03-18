function outType=fly_parseGUIPhenotypeFields(tags)
% function outType=fly_parseGUIPhenotypeFields(tags)
% Takes a params struct with a set of fields extracted from the fly input
% gui.
% Looks for critical fields for (2) flies and constructs a string
% describing each fly's phenotype as well as an MD5 hash so that we can
% tell if they are the same or different.

criticalFields={'Fly1AgeDays','UASListFly1','GAL4Fly1','DrugFly1List','ConcFly1List','DrugAdminFly1List','OtherTypeListFly1';'Fly2AgeDays','UASListFly2','GAL4Fly2','DrugFly2List','ConcFly2List','DrugAdminFly2List','OtherTypeListFly1'};

nFieldsInGUI=length(tags);
nPhenoFields=size(criticalFields,2); % How many things contribute to the unique phenotype?
flyNameIndex=1;

% Build up a phenotype name from the components of the GUI fields: UAS,
% GAL4, age, drug etc...
% Critical fields for the first fly/channel are in row 1 of
% 'criticalFields' (indexed by flyNameIndex)
for thisFly=[1,3]
    flyName{thisFly}='D';
    for thisPhenoField=1:nPhenoFields % Loop over all the distinguishing phenotype items: the columns from criticalFields
        for thisGUIField=1:nFieldsInGUI % Look over all the fields available from the GUI (30 or so...)
            if(strcmp(tags{thisGUIField}.tag, criticalFields{flyNameIndex,thisPhenoField}))
                stringVal=char(tags{thisGUIField}.string(tags{thisGUIField}.value));
                if (strcmp(lower(stringVal),'none'))
                    stringVal='';
                end
                stringVal(~isstrprop(stringVal,'alphanum')) = ''; % Strip out non alphanumeric
                phenotypeValues{thisFly,thisPhenoField}=stringVal;
                
                flyName{thisFly}=strcat(flyName{thisFly},'_',stringVal);
            end % End if
        end % Next GUI field to check
    end % Next ptype field top search for
    flyHash{thisFly}=DataHash(flyName{thisFly}); % Generate a unique md5 hash. This is more robust than relying on string matching to a name (whitespace etc..)
    g=flyName{thisFly};
    flyName{thisFly}=g(find(~isspace(g))); % Get rid of whitespaces
    flyNameIndex=flyNameIndex+1;
end % Next fly

flyHash{2}=DataHash('Photodiode');  
flyName{2}='Photodiode'; 
outType.flyName=flyName
outType.flyHash=flyHash;
outType.phenotypeValues=phenotypeValues;
outType.criticalFields=criticalFields;


function outType=fly_parseGUIPhenotypeFields(tags)
% function outType=fly_parseGUIPhenotypeFields(tags)
% Takes a params struct with a set of fields extracted from the fly input
% gui.
% Looks for critical fields for (2) flies and constructs a string
% describing each fly's phenotype as well as an MD5 hash so that we can
% tell if they are the same or different.

criticalFields={'UASListFly1','GAL4Fly1','DrugFly1List','ConcFly1List','DrugAdminFly1List';'UASListFly2','GAL4Fly2','DrugFly2List','ConcFly2List','DrugAdminFly2List'};

nFieldsInGUI=length(tags);
nPhenoFields=size(criticalFields,2);
flyNameIndex=1;

for thisFly=[1,3]
    flyName{thisFly}=sprintf('Fly',thisFly);
    for thisPhenoField=1:nPhenoFields
        for thisGUIField=1:nFieldsInGUI
            if(strcmp(tags{thisGUIField}.tag, criticalFields{flyNameIndex,thisPhenoField}))
                stringVal=tags{thisGUIField}.string(tags{thisGUIField}.value);
                phenotypeValues{thisFly,thisPhenoField}=stringVal;
                flyName{thisFly}=strcat(flyName{thisFly},'_',stringVal);
            end % End if
        end % Next GUI field to check
    end % Next ptype field top search for
    flyHash{thisFly}=DataHash(flyName{thisFly});
    g=flyName{thisFly}{1};
    flyName{thisFly}=g(find(~isspace(g))); % Get rid of whitespaces
    flyNameIndex=flyNameIndex+1;
end % Next fly

flyHash{2}=DataHash('Photodiode');  
flyName{2}='Photodiode'; 
outType.flyName=flyName
outType.flyHash=flyHash;
outType.phenotypeValues=phenotypeValues;
outType.criticalFields=criticalFields;


function [expt,Cancelled]=fly_runFlyInputGUI()
% [expt,Cancelled]=runFlyInputGUI()
% Gets important data about the experiment
% 
%% Use a panel to get info:
experimenterList={'Naz','Rebecca','Sultan','Alex','Danielle','Chris','Sean','Jonathan'};
flyTypes={'W-normald1',...
    'test'};
flyage=[1,2,3,4]
exptSetList=[1 2 3];


clear Formats;
clear Prompt;


% *******************************************

% This is the title
Prompt=cell(7,2);
Prompt{1,1}= ['Enter experiment - level data here'];
Formats(1,1).type = 'text';
Formats(1,1).size = [-1 0];
for k = 2:10 % span the static text across the entire dialog
   Formats(1,k).type = 'none';
   Formats(1,k).limits = [0 1]; % extend from left
end

% Ask for the experimenter name
Prompt(2,:)={'Experimenter name','ExptName'};
Formats(2,1).type = 'list';
Formats(2,1).style = 'listbox';
Formats(2,1).items = experimenterList;
Formats(2,1).limits = [0 1]; % multi-select
Formats(2,1).format='integer';
Formats(2,1).size=60;

Prompt(3,:)={'Comments:','Comment'};
Formats(2,4).type = 'edit';
Formats(2,4).format = 'text';
Formats(2,4).limits = [0 4]; % default: show 20 lines
Formats(2,4).size = [180 100];

Prompt(4,:)={'Experiment set','exptSet'};
Formats(2,6).type='list';
Formats(2,6).style = 'listbox';
Formats(2,6).items = exptSetList;
Formats(2,6).format='integer';
Formats(2,6).limits = [0 1]; % multi-select
Formats(2,6).size=60;

Prompt(5,:)={'Fly type name','FlyID'};
Formats(3,1).type='list';
Formats(3,1).style ='listbox';
Formats(3,1).items = flyTypes;
Formats(3,1).format='integer';
Formats(3,1).limits = [0 1]; % multi-select
Formats(3,1).size=90;

Prompt(6,:) = {'Fly age in days', 'FlyDayAge'};
Formats(3,2).type = 'list';
Formats(3,2).style ='listbox';
Formats(3,2).items = flyage
Formats(3,2).format = 'integer';
Formats(3,2).limits = [0 255]; % Assume that flies live no longer than about 70 days max
Formats(3,2).size = 60;


Prompt(7,:) = {'Stick time (HH:MM)', 'FlyStickTime'};
Formats(3,5).type = 'edit';
Formats(3,5).format = 'date';
Formats(3,5).limits = 15; % Assume that flies live no longer than about 70 days max
Formats(3,5).size = 60;

% Set options
%%%% SETTING DIALOG OPTIONS
Options.WindowStyle = 'modal';
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ApplyButton = 'on';
Options.ButtonNames = {'Continue','Cancel'}; %<- default names, included here just for illustration

%Set default answers
DefAns.ExptName=1;
DefAns.FlyID=1;
DefAns.FlyDayAge=1;
DefAns.FlyStickTime=datestr(now,15);
DefAns.Comment='--blank--';
DefAns.exptSet=1;

size(Prompt)
size(Formats)
Title='Info for this expt';
[expt,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options)

expt.ExptName=experimenterList{expt.ExptName};
expt.FlyID=flyTypes{expt.FlyID};


%expt.experimenter='Naz';
%expt.stickDsiate='24-May-2012';
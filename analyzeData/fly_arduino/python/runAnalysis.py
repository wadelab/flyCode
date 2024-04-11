#%%
import sys
import os

# Get the directory of the current script
current_script_path = '/groups/labs/wadelab/toolbox/flyCode/analyzeData/fly_arduino/python/'
print(f'{current_script_path}')

# Add the directory to sys.path if it's not already there
if current_script_path not in sys.path:
    sys.path.append(current_script_path)
# Now you can import your module
from jots_bootstrapSSVEPs import *
"Pink1B9_14dpe"


main_directory = '/groups/labs/wadelab/data/sitran/flyArduino2'
genotypes = ['Pink1B9_14dpe', 'Pink1B9_5dpe']
bootstrapSSVEPs(main_directory, genotypes, n_bootstraps=10, plus=False, label='', save=True)



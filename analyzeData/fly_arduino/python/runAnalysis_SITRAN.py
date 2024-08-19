#%%
import sys
import os
from jots_getSVPFiles import getSVPFiles
from jots_readFile import readFile
from matplotlib import pyplot as plt
import numpy as np
# Get the directory of the current script
#current_script_path = '/groups/labs/wadelab/toolbox/flyCode/analyzeData/fly_arduino/python/' # This is machine dependent
current_script_path = '/raid/toolbox/git/flyCode/analyzeData/fly_arduino/python/' # This is machine dependent

print(f'{current_script_path}')

# Add the directory to sys.path if it's not already there
if current_script_path not in sys.path:
    sys.path.append(current_script_path)
# Now you can import your module
from jots_bootstrapSSVEPs import *
"Pink1B9_14dpe"


#main_directory = '/groups/labs/wadelab/data/sitran/flyArduino2'
main_directory = '/raid/data/SITRAN/DJ1_data_15_08_24'
genotypes = ['DJ1aDJ1b_1dpe', 'DJ1aDJ1b_7dpe','DJ1aDJ1b_21dpe','DJ1aDJ1b_28dpe']

'''
# Test reading a single file
fName='10H39M25.SVP'
fileToRead=os.path.join(main_directory, genotypes[0], fName)
print(fName)
print(fileToRead)
scd,m=readFile(fileToRead,verbose=True)

# scd is a dataframe with columns mask,probe, dataVals
# datavals is a list
# Extract all the datavals where mask==0 and probe==100 and average them , then plot the average vals
#filtered_df = df[(df['Age'] > 30) & (df['City'] == 'New York')]

highCont=(scd[(scd['mask']==0.0) & (scd['probe']==100.0)])
hig=np.array(highCont.complexData)
avHig=np.mean(hig,axis=0)
plt.plot(np.absolute(hig))


'''


bootstrapSSVEPs(main_directory, genotypes, n_bootstraps=1000, plus=False, label='', save=True)



# %%

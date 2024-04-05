import sys
from os import listdir
from jots_getSVPFiles import getSVPFiles
from jots_readFile import readFile
import numpy as np
from random import randint
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt
from copy import deepcopy
from datetime import datetime
import csv
from time import sleep
import math

def resample(this_list, length = None):
    if length == None:
        length = len(this_list)
    return [this_list[randint(0, len(this_list) -1)] for i in range(length)]

def hyperbolic(c, c50, Rmax):
    n, R0 = 2, 0
    # numpy's math functions handle edge cases more robustly and can prevent overflow errors
    return (Rmax * (np.power(c, n) / (np.power(c50, n) + np.power(c, n)))) + R0

def hyperbolicPlus(c, c50, Rmax, n, R0):
    # numpy's math functions handle edge cases more robustly and can prevent overflow errors
    return (Rmax * (np.power(c, n) / (np.power(c50, n) + np.power(c, n)))) + R0

def fittingcurve(cs, rs):
    pmin = (0, 0)
    p0 = [np.mean(cs), np.max(rs)]
    pmax = (np.inf, 2 * np.max(rs))
    params, covs = curve_fit(hyperbolic, cs, rs, p0=p0, bounds=(pmin, pmax))
    return params

def fittingcurvePlus(cs, rs):
    pmin = (0, 0, 1.5, 0)
    p0 = [np.mean(cs), np.max(rs), 2, 0]
    pmax = (np.inf, 2 * np.max(rs), 2.5, 0.0001) # these are the same bounds as os_bootstrapDatasets
    params, covs = curve_fit(hyperbolicPlus, cs, rs, p0=p0, bounds=(pmin, pmax))
    return params

def bootstrapSSVEPs(main_directory, genotypes, n_bootstraps=1000, input_freq=12, label=None, save=True, plus=False):
    # this function only bootstraps 1F1 and 2F1, but does so simultaneously
    frequencies = {"1F1": input_freq, "2F1": input_freq * 2}

    # establishing colours:
    if len(genotypes) == 4:
        colors = ['red', 'orange', 'green', 'blue']
    elif len(genotypes) == 3:
        colors = ['green', 'blue', 'red']
    elif len(genotypes) == 2:
        colors = ['blue', 'orange']
    else:
        print(f"function 'bootstrapSSVEPs' can only colour 2, 3 or 4 genotypes")
        return

    # each output file is labelled with datetime of analysis start
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    if label == None:
        label = main_directory

    # create csv files
    if save:
        if plus is True:
            savedAs = "bootstrapPlus"
        else:
            savedAs = "bootstrap"
        print(f'about to run {savedAs}...')
        sum = open(f'{timestamp}_{label.replace(" ", "-")}_{savedAs}_SUM.csv', mode='w', newline='')
        sum_writer = csv.writer(sum)
        sum_writer.writerow(["genotype", "n_files", "parameter", "harmonic", "mask", "min_value", "lower_bound", "mean", "upper_bound", "max_value"])
        raw = open(f'{timestamp}_{label.replace(" ", "-")}_{savedAs}_RAW.csv', mode='w', newline='')
        raw_writer = csv.writer(raw)

    # iterate through genotypes
    plt.figure(figsize=(11.7, 8.3), layout="constrained")
    for g, genotype in enumerate(genotypes):
        print(f'getting {genotype} data ready!')
        subdirectory = f'{main_directory}/{genotype}/'
        files = getSVPFiles(listdir(subdirectory))

        # establish probes and masks, and initialise genotype-structures
        scd, md = readFile(subdirectory + files[0], freq=list(frequencies.values())[0])

        probes, masks = list(scd["probe"].unique()), list(scd["mask"].unique())
        probes.sort()
        masks.sort()

        conds = []
        for probe in probes:
            for mask in masks:
                conds.append((probe, mask))
        conds.pop(-1) # removes (probe = 100, mask = 30)

        common_sets = {}
        for comp in frequencies.keys():
            for mask in masks:
                common_sets[(int(mask), comp)] = []
        common_conds = {}
        for cond in conds:
            common_conds[cond] = []

        c50s_for_this_genotype, Rmaxs_for_this_genotype = deepcopy(common_sets), deepcopy(common_sets)
        if plus is True:
            ns_for_this_genotype, R0s_for_this_genotype = deepcopy(common_sets), deepcopy(common_sets)
        resps_1F1, resps_2F1 = deepcopy(common_conds), deepcopy(common_conds)

        if (save == True) & (g == 0):
            raw_headings = ['genotype', 'bootstrap']
            for (mask, comp) in common_sets.keys():
                raw_headings.append(f'c50_{mask}_{comp}')
                raw_headings.append(f'Rmax_{mask}_{comp}')
                if plus is True:
                    raw_headings.append(f'n_{mask}_{comp}')
                    raw_headings.append(f'R0_{mask}_{comp}')
            raw_writer.writerow(raw_headings)

        # these are the original data restructured to be resampled later
        # these dicts are filled now
        for file in files:
            for f, freq in enumerate(frequencies.values()):
                scd, md = readFile(subdirectory+file, freq)
                this_data = scd.groupby(['probe', 'mask']).mean()["complexData"]

                for cond in conds:
                    if freq == input_freq:
                        resps_1F1[cond].append(np.abs(this_data[cond[0]][cond[1]]))
                    elif freq == input_freq * 2:
                        resps_2F1[cond].append(np.abs(this_data[cond[0]][cond[1]]))

        # bootstrapping starts here
        for b in range(n_bootstraps):

            if b % 100 == 0:
                print(f'this is bootstrap {b} out of {n_bootstraps} for {genotype}')

            c50s_for_this_bootstrap, Rmaxs_for_this_bootstrap = deepcopy(common_sets), deepcopy(common_sets)
            if plus is True:
                ns_for_this_bootstrap, R0s_for_this_bootstrap = deepcopy(common_sets), deepcopy(common_sets)
            resampled_1F1, resampled_2F1 = deepcopy(common_conds), deepcopy(common_conds)

            params = None # this is a work-around for optimizing problem...
            while params is None:
                try:
                    # resampling here
                    for cond in conds:
                        resampled_1F1[cond] = resample(resps_1F1[cond])
                        resampled_2F1[cond] = resample(resps_2F1[cond])

                    for i in range(len(files)): # make 'new dataset' of flies
                        synthetic_fly = deepcopy(common_sets)
                        for key in synthetic_fly.keys():
                            if key[0] == 0:
                                synthetic_fly[key] = np.zeros(shape=len(probes)).tolist()
                            elif key[0] == 30:
                                synthetic_fly[key] = np.zeros(shape=len(probes) - 1).tolist()

                        # restructuring happens here
                        for comp in frequencies.keys():
                            for cond in conds:
                                if comp == '1F1':
                                    synthetic_fly[(cond[1], comp)][probes.index(cond[0])] = resampled_1F1[cond][i]
                                elif comp == '2F1':
                                    synthetic_fly[(cond[1], comp)][probes.index(cond[0])] = resampled_2F1[cond][i]

                        # fitting happens here
                        for key in common_sets.keys():
                            if key[0] == 0:
                                ps = probes
                            else:
                                ps = probes[:-1]

                            if plus is True:
                                params = fittingcurvePlus(ps, synthetic_fly[key])
                            else:
                                params = fittingcurve(ps, synthetic_fly[key])

                            # params are stored
                            params = list(params)
                            c50s_for_this_bootstrap[key].append(params[0])
                            Rmaxs_for_this_bootstrap[key].append(params[1])
                            if plus is True:
                                ns_for_this_bootstrap[key].append(params[2])
                                R0s_for_this_bootstrap[key].append(params[3])

                except Exception as e:
                    # TODO: need to solve this...
                    # raise RuntimeError("Optimal parameters not found: " + res.message)
                    # RuntimeError: Optimal parameters not found: The maximum number of function evaluations is exceeded.
                    # solving by making new synthetic fly, i.e., resampling again
                    print(f'for syn fly {i} for bootstrap {b} for {genotype}:')
                    print(f'here is data from this "fly"')
                    print(synthetic_fly)
                    print(f'here are the estimated params')
                    print(params)
                    print(e)
                    print('waiting 2 secs')
                    sleep(2)
                    print('trying again by making new fly...')
                    pass

            # calculate mean at the end of this bootstrap and store for genotype
            for key in synthetic_fly.keys():
                c50s_for_this_genotype[key].append(np.mean(c50s_for_this_bootstrap[key]))
                Rmaxs_for_this_genotype[key].append(np.mean(Rmaxs_for_this_bootstrap[key]))
                if plus is True:
                    ns_for_this_genotype[key].append(np.mean(ns_for_this_bootstrap[key]))
                    R0s_for_this_genotype[key].append(np.mean(R0s_for_this_bootstrap[key]))

        if save:
            for b in range(n_bootstraps): # saving to raw file
                to_add_to_raw_file = [genotype, b]
                for (mask, comp) in common_sets.keys():
                    to_add_to_raw_file.append(c50s_for_this_genotype[(mask, comp)][b])
                    to_add_to_raw_file.append(Rmaxs_for_this_genotype[(mask, comp)][b])
                    if plus is True:
                        to_add_to_raw_file.append(ns_for_this_genotype[(mask, comp)][b])
                        to_add_to_raw_file.append(R0s_for_this_genotype[(mask, comp)][b])
                raw_writer.writerow(to_add_to_raw_file)

            # saving to summary file
            for (mask, comp) in common_sets.keys():
                sum_writer.writerow([genotype,
                                      len(files),
                                      "c50",
                                      comp,
                                      mask,
                                      np.min(c50s_for_this_genotype[(mask, comp)]),
                                      np.quantile(c50s_for_this_genotype[(mask, comp)], 0.025),
                                      np.mean(c50s_for_this_genotype[(mask, comp)]),
                                      np.quantile(c50s_for_this_genotype[(mask, comp)], 0.975),
                                      np.max(c50s_for_this_genotype[(mask, comp)])])
                sum_writer.writerow([genotype,
                                     len(files),
                                     "Rmax",
                                     comp,
                                     mask,
                                     np.min(Rmaxs_for_this_genotype[(mask, comp)]),
                                     np.quantile(Rmaxs_for_this_genotype[(mask, comp)], 0.025),
                                     np.mean(Rmaxs_for_this_genotype[(mask, comp)]),
                                     np.quantile(Rmaxs_for_this_genotype[(mask, comp)], 0.975),
                                     np.max(Rmaxs_for_this_genotype[(mask, comp)])])
                if plus is True:
                    sum_writer.writerow([genotype,
                                         len(files),
                                         "n",
                                         comp,
                                         mask,
                                         np.min(ns_for_this_genotype[(mask, comp)]),
                                         np.quantile(ns_for_this_genotype[(mask, comp)], 0.025),
                                         np.mean(ns_for_this_genotype[(mask, comp)]),
                                         np.quantile(ns_for_this_genotype[(mask, comp)], 0.975),
                                         np.max(ns_for_this_genotype[(mask, comp)])])
                    sum_writer.writerow([genotype,
                                         len(files),
                                         "R0",
                                         comp,
                                         mask,
                                         np.min(R0s_for_this_genotype[(mask, comp)]),
                                         np.quantile(R0s_for_this_genotype[(mask, comp)], 0.025),
                                         np.mean(R0s_for_this_genotype[(mask, comp)]),
                                         np.quantile(R0s_for_this_genotype[(mask, comp)], 0.975),
                                         np.max(R0s_for_this_genotype[(mask, comp)])])

        count = 1
        if plus is True:
            ncols = 4
        else:
            ncols = 2

        # aesthetics
        fs = 10 # fontsize
        ts = 5 # ticksize
        lp = 30 # labelpad

        for key in common_sets.keys():

            plt.subplot(4, ncols, count)
            plt.hist(c50s_for_this_genotype[key], bins=40, alpha=0.5, color=colors[g])
            if count <= ncols:
                plt.title('$c_{50}$', fontsize=fs)
            if count % ncols == 1:
                plt.ylabel(f'{key[1]}\nmask = {key[0]}', rotation=0, labelpad=lp, fontsize=fs)
            plt.tick_params(axis='both', labelsize=ts)
            count+=1

            plt.subplot(4, ncols, count)
            plt.hist(Rmaxs_for_this_genotype[key], bins=40, alpha=0.5, color=colors[g])
            if count <= ncols:
                plt.title('$R_{max}$', fontsize=fs)
            if count % ncols == 1:
                plt.ylabel(f'{key[1]}\nmask = {key[0]}', rotation=0, labelpad=lp, fontsize=fs)
            plt.tick_params(axis='both', labelsize=ts)
            count += 1

            if plus is True:
                plt.subplot(4, ncols, count)
                plt.hist(ns_for_this_genotype[key], bins=40, alpha=0.5, color=colors[g])
                if count <= ncols:
                    plt.title('n', fontsize=fs)
                if count % 4 == 1:
                    plt.ylabel(f'{key[1]}\nmask = {key[0]}', rotation=0, labelpad=lp, fontsize=fs)
                plt.tick_params(axis='both', labelsize=ts)
                count += 1

                plt.subplot(4, ncols, count)
                plt.hist(R0s_for_this_genotype[key], bins=40, alpha=0.5, color=colors[g], label=genotype)
                if count == ncols:
                    plt.legend(bbox_to_anchor=(1.04, 1), borderaxespad=0)
                if count <= ncols:
                    plt.title('$R_{0}$', fontsize=fs)
                if count % 4 == 1:
                    plt.ylabel(f'{key[1]}\nmask = {key[0]}', rotation=0, labelpad=lp, fontsize=fs)
                plt.tick_params(axis='both', labelsize=ts)
                count += 1

    if save:
        sum.close()
        raw.close()
        plt.savefig(f'{timestamp}_{label.replace(" ", "-")}_{savedAs}_HIS.png')

    print("bootstrapSSVEPs has finished!")

    plt.show()



if __name__ == "__main__":
    main_directory = '202403--_OS_gsk3b_epoB'
    genotypes = ['epoB_DN', 'epoB_WT', 'epoB_CA']
    bootstrapSSVEPs(main_directory, genotypes, n_bootstraps=10, plus=False, label='', save=True)















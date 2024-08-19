import pandas as pd
import numpy as np

def readFile(file, freq=12, expected=False, verbose=False):
    # expected experimental parameters are coded into a dictionary with the following keys
    # these are the experimental parameters for JOTS for NatSci project 2023/24 with ARW and IH
    if not expected:
        num_trials = 45
        num_samples = 1024
        probes = [5, 10, 30, 70, 100]
        masks = [0, 30]
        sr = 250
        si = 4
    else:
        num_trials = expected["num_trials"]
        num_samples = expected["num_samples"]
        probes = expected["probes"]
        masks = expected["masks"]
        sr = expected["sr"]
        si = expected["si"]
    time_points = [si * i for i in range(num_samples)] # calculated based on sampling interval and number of samples
    #TODO: maybe make function getExpected() which reads all files in dataset and outputs most frequent experimental parameters

    # files that can be read include txt, binary and html file formats
    try:
        if verbose:
            print(f'FLICKER: trying to open file {file} as txt file')

        metadata = {}
        """
        with open(file, mode='rt') as f:
            meta_from_file = list(f.readline().split(","))
            for i, md in enumerate(meta_from_file):
                try:
                    [key, value] = list(md.split('='))
                    metadata[key] = value
                except:
                    if verbose:
                        print(f'FLICKER: for {file}, cannot store {md}')
                    pass
        """
        if ('html' in file) or ('txt' in file) or ('SVP' in file):


            with open(file, 'r') as f:
                for line in f:
                    if verbose:
                        print(line)

                    if 'GET' in line:
                        meta_line = line.strip(" \n").split(",")
                        break
            meta_line.pop(0) # removes "/GET"
        for dp in meta_line:
            dp_split = dp.split("=")
            metadata[dp_split[0]] = dp_split[1]

        try: # open txt file and sort data by trial # TODO: continue updating here
            df = pd.read_csv(file, skiprows=1, names=['time', 'stimulus', 'response'])
            times = np.array(df['time']).reshape(num_trials, num_samples + 1)
            stimuli = np.array(df['stimulus']).reshape(num_trials, num_samples + 1)
            responses = np.array(df['response']).reshape(num_trials, num_samples + 1)
            if verbose:
                print(df)
            # the extra 3-integer line contains information about probes and masks
            # [-99, probe, mask]

        except:
            try: # open as html files
                df = pd.read_csv(file, skiprows=6, names=['time', 'stimulus', 'response'])
                times = np.array(df['time']).reshape(num_trials, num_samples + 1)
                stimuli = np.array(df['stimulus']).reshape(num_trials, num_samples + 1)
                responses = np.array(df['response']).reshape(num_trials, num_samples + 1)
                # the extra 3-integer line contains information about probes and masks
                # [-99, probe, mask]
            except:
                df = pd.read_csv(file, skiprows=12, names=['time', 'stimulus', 'response'])
                # ARW came on Monday and set up new jig and software... new file formats could do with generalising
                times = np.array(df['time']).reshape(num_trials, num_samples + 1)
                stimuli = np.array(df['stimulus']).reshape(num_trials, num_samples + 1)
                responses = np.array(df['response']).reshape(num_trials, num_samples + 1)
                # the extra 3-integer line contains information about probes and masks
                # [-99, probe, mask]

        # checking for unreasonable data / recordings - to omit
        ix_to_omit = []
        omit_info = []
        for ix, t in enumerate(times):
            if t[0] != 0:
                if verbose: print(
                    f'OMIT: recorded start time for trial {ix + 1}th is unexpected (t0 = {t[0]}) ... assuming incorrect recording and ignoring trial')
                ix_to_omit.append(ix)
                omit_info.append("t0")
                continue
            elif (t[1] - t[0]) != si:
                if verbose: print(
                    f'OMIT: recorded sampling interval for trial {ix + 1}th is unexpected(t1 - t0 = {t[1] - t[0]}) ... assuming incorrect recording and ignoring trial')
                ix_to_omit.append(ix)
                omit_info.append("si")
                continue
            elif not np.array_equal(t[:-1], time_points):
                if verbose: print(
                    f'OMIT: recorded time points for trial {ix + 1}th is unexpected... assuming incorrect recording and ignoring trial')
                ix_to_omit.append(ix)
                omit_info.append("tp")
                continue
            elif stimuli[ix][-1] not in probes:
                if verbose: print(
                    f'OMIT: recorded probe for trial {ix + 1}th is unexpected (probe = {stimuli[ix][-1]}) ... assuming incorrect recording and ignoring trial')
                ix_to_omit.append(ix)
                omit_info.append("pr")
                continue
            elif responses[ix][-1] not in masks:
                if verbose: print(
                    f'OMIT: recorded mask for trial {ix + 1}th is unexpected (mask = {responses[ix][-1]}) ... assuming incorrect recording and ignoring trial')
                ix_to_omit.append(ix)
                omit_info.append("ma")
                continue
        # times = np.delete(times, ix_to_omit, axis=0)
        # times irrelevant here on out
        stimuli = np.delete(stimuli, ix_to_omit, axis=0)
        responses = np.delete(responses, ix_to_omit, axis=0)

        filetype = 'txt'
        if verbose:
            print(f"UPDATE: successfully read {file} as txt/html file")

    except Exception as e:
        if verbose:
            print(f'ERROR: could not open file {file} as txt/html file because {e}')
            print(f'UPDATE: trying to open file {file} as binary file')
        try: # open binary file

            # get metadata first
            metadata = {}
            with open(file, mode='rb') as f:
                meta_from_file = str(f.read(200)).split("&")  # TODO: 200 here is arbitrary... maybe can work out more accurately
                for i, md in enumerate(meta_from_file):
                    try:
                        [key, value] = list(md.split('='))
                        metadata[key] = value
                    except:
                        # print(f'cannot store "{md}" in metadata')
                        pass

            data = np.fromfile(file, dtype=np.int32, count=-1)
            data = list(data)[33:]  # TODO: 33 here is arbitrary (in bytes?)
            data = np.reshape(data, (-1, 1025))
            conditions, responses, meta_from_file = [], [], [None]

            # checking for unreasonable data / recordings - to omit
            ix_to_omit = []
            omit_info = []
            for ix, d in enumerate(data):
                if ix % 2 == 0:  # these are recordings with mask contrast at end
                    cond = [None, None]
                    responses.append(list(d[:1024]))
                    cond[1] = d[-1] # mask
                    if cond[1] not in masks:
                        if verbose: print(
                            f'OMIT: recorded mask for trial {ix + 1}th is unexpected (mask = {cond[1]}) ... assuming incorrect recording and ignoring trial')
                        ix_to_omit.append(ix)
                        omit_info.append("ma")
                else:  # this is time with probe contrast at end
                    cond[0] = d[-1] # probe
                    if d[0] != 0:
                        if verbose: print(
                            f'OMIT: recorded start time for trial {ix + 1}th is unexpected (t0 = {d[0]}) ... assuming incorrect recording and ignoring trial')
                        ix_to_omit.append(ix)
                        omit_info.append("t0")
                    elif (d[1] - d[0]) != si:
                        if verbose: print(
                            f'OMIT: recorded sampling interval for trial {ix + 1}th is unexpected(t1 - t0 = {d[1] - d[0]}) ... assuming incorrect recording and ignoring trial')
                        ix_to_omit.append(ix)
                        omit_info.append("si")
                    elif not np.array_equal(d[:-1], time_points):
                        if verbose: print(
                            f'OMIT: recorded time points for trial {ix + 1}th is unexpected... assuming incorrect recording and ignoring trial')
                        ix_to_omit.append(ix)
                        omit_info.append("tp")
                    elif cond[0] not in probes:
                        if verbose: print(
                            f'OMIT: recorded probe for trial {ix + 1}th is unexpected (probe = {cond[0][-1]}) ... assuming incorrect recording and ignoring trial')
                        ix_to_omit.append(ix)
                        omit_info.append("pr")
                    conditions.append(cond)
            conditions = np.delete(conditions, ix_to_omit, axis=0)
            responses = np.delete(responses, ix_to_omit, axis=0)
            filetype = 'binary'
            if verbose:
                print(f"UPDATE: successfully read {file} as binary file")

        except Exception as e:
            if verbose:
                print(f'ERROR: could not open file {file} as binary file because {e}')
            return

    # finalise metadata
    try: # TODO: need to generalise to all gene expression targeting systems, etc.
        if filetype == 'binary':
            GAL4 = metadata["b'GET /?GAL4"]
            metadata['genotype'] = f"{GAL4}-GAL4/UAS-{metadata['UAS']}"
        elif filetype == 'txt':
            metadata['genotype'] = f'{metadata["GAL4"]}-GAL4/UAS-{metadata["UAS"]}'
        temp1 = metadata['filename'].split(" ")
        metadata['filename'] = temp1[0]
        metadata['ID'] = temp1[0].split("_")[-1]
        metadata['datetime'] = f'2023{metadata["filename"][3:5]}' \
                               f'{metadata["filename"][0:2]}' \
                               f'{metadata["filename"][6:8]}' \
                               f'{metadata["filename"][9:11]}' \
                               f'{metadata["filename"][12:14]}'  # YYYYMMDDHHMMSS
        if verbose:
            print(metadata)
    except:
        pass

    sortedComplexData = pd.DataFrame({
        "mask": [],
        "probe": [],
        "complexData": [],
    })

    for trial, data in enumerate(responses):
        data = data[:1000]  # remove last few recordings like in flyCode
        amplitudes = np.fft.fft(data) / 1000  # see ARW's code for div by 1000
        interval = 1 / sr
        frequencies = np.fft.fftfreq(n=len(data), d=interval)
        if filetype == 'txt':
            data_to_add = pd.DataFrame({
                "mask": responses[trial][-1],
                "probe": stimuli[trial][-1],
                "complexData": amplitudes[np.where(frequencies == freq)],
            })
        elif filetype == 'binary':
            data_to_add = pd.DataFrame({
                "mask": conditions[trial][1],
                "probe": conditions[trial][0],
                "complexData": amplitudes[np.where(frequencies == freq)],
            })
        sortedComplexData = pd.concat([sortedComplexData, data_to_add], axis=0, ignore_index=True)
        if verbose:
            print(sortedComplexData)
    metadata["n_trials"] = sortedComplexData.shape[0] # n rows
    if len(ix_to_omit) == 0:
        metadata["omitted"] = None
    else:
        omit_sum = []
        for i, ix in enumerate(ix_to_omit):
            omit_sum.append((ix, omit_info[i]))
        metadata["omitted"] = omit_sum
    """
    if verbose:
        print(f'filename: {metadata["filename"]}')
        print(f'ID: {metadata["ID"]}')
        print(f'genotype: {metadata["genotype"]}')
        print(f'age: {metadata["Age"]}')
        print(f'sex: {metadata["sex"]}')
        print(f'n_trials: {metadata["n_trials"]}')
        print(f'omitted: {metadata["omitted"]}')
    """

    return sortedComplexData, metadata
def getSVPFiles(directory):
    new_directory = []
    for filename in directory:
        if "SVP" in filename:
            new_directory.append(filename)
    return new_directory
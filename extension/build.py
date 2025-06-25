# Imports
import zipfile
import os
import pathlib




# BUILD SETTINGS -

# The name of the file. 
# String. Will output as NAME.aseprite-extension
NAME = "crash-selection-stacker"

# The source code directory. All files that need to be built into the .aseprite-extension go in here.
# String. By default, it uses the src folder. The path cannot be the root or output directory.
SOURCEPATH = "./zip"

# The output directory of the NAME.aseprite-extension file.
# String. By default, it outputs to the root directory.
OUTPATH = "./"

# END OF SETTINGS -




# CODE -

# Check if source path matches root or output directory
ROOTDIR = os.getcwd()
if SOURCEPATH == ROOTDIR or SOURCEPATH == OUTPATH:
  raise Exception("Source directory cannot match root or output directory")

# Check if required directories exist, and if not, create them
if not os.path.isdir(SOURCEPATH):
  os.mkdir(SOURCEPATH)
if not os.path.isdir(OUTPATH):
  os.mkdir(OUTPATH)

# Read all directories and files in the source directory, and add it to the zip
ZIPPATH = NAME + ".zip"
os.chdir(OUTPATH)
zip = zipfile.ZipFile(ZIPPATH, "w", zipfile.ZIP_DEFLATED)
os.chdir(ROOTDIR)
os.chdir(SOURCEPATH)
for (root,dirs,files) in os.walk("./",topdown=True):
  owd = os.getcwd()
  for d in dirs:
    os.chdir(root)
    p = os.path.relpath(d, owd)
    os.chdir(owd)
    zip.write(p)
  for f in files:
    os.chdir(root)
    p = os.path.relpath(f, owd)
    os.chdir(owd)
    zip.write(p)
zip.close()

# Change the file extension of the zip
os.chdir(ROOTDIR)
os.chdir(OUTPATH)
if os.path.exists(NAME + ".aseprite-extension"):
  os.remove(NAME + ".aseprite-extension")
path = pathlib.Path(ZIPPATH)
path.rename(path.with_suffix(".aseprite-extension"))
print("Build complete!")
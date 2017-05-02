#!/bin/bash

## This script will install the tools required for the STRetch pipeline.
## It will fetched each tool from the web and placed into the tools/ subdirectory.
## Paths to all installed tools can be found in the file tools.groovy at the
## end of execution of this script. These paths can be changed if a different
## version of software is required. Note that R must be installed manually
##

installdir=$PWD
refdir=$PWD/reference-data
toolspec=$PWD/pipelines/tools.groovy

mkdir -p tools/bin
cd tools

#a list of which programs need to be installed
commands="bpipe python goleft bedtools bwa samtools"

#installation method
function bpipe_install {
    wget -O bpipe-0.9.9.2.tar.gz https://github.com/ssadedin/bpipe/releases/download/0.9.9.2/bpipe-0.9.9.2.tar.gz
    tar -zxvf bpipe-0.9.9.2.tar.gz ; rm bpipe-0.9.9.2.tar.gz
    ln -s $PWD/bpipe-0.9.9.2/bin/* $PWD/bin/
}

# Installs miniconda, Python 3 + required packages, BedTools and goleft
# (and any other dependancies listed in environment.yml)
function python_install {
    wget -O miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash miniconda.sh -b -p $PWD/miniconda
    rm miniconda.sh
    $PWD/miniconda/bin/conda env create -f ../environment.yml
    ln -s $PWD/miniconda/envs/STR/bin/* $PWD/bin/
#    source activate STR
}

function bwa_install {
    wget --no-check-certificate https://github.com/lh3/bwa/releases/download/v0.7.15/bwakit-0.7.15_x64-linux.tar.bz2
    tar -jxvf bwakit-0.7.15_x64-linux.tar.bz2
    rm bwakit-0.7.15_x64-linux.tar.bz2
    ln -s $PWD/bwa.kit/* $PWD/bin/
}

function samtools_install {
    wget --no-check-certificate https://sourceforge.net/projects/samtools/files/samtools/1.3.1/samtools-1.3.1.tar.bz2
    tar -jxvf samtools-1.3.1.tar.bz2
    rm samtools-1.3.1.tar.bz2
    make prefix=$PWD install -C samtools-1.3.1/
}

function download_hg19 {
    wget --no-check-certificate -O $refdir/reference-data.zip https://ndownloader.figshare.com/articles/4658701?private_link=1a39be9282c90c4860cd
    unzip $refdir/reference-data.zip -d $refdir
    rm $refdir/reference-data.zip
}

echo "// Path to tools used by the pipeline" > $toolspec

for c in $commands ; do
    c_path=`which $PWD/bin/$c 2>/dev/null`
    if [ -z $c_path ] ; then
	echo "$c not found, fetching it"
	${c}_install
	c_path=`which $PWD/bin/$c 2>/dev/null`
    fi
    echo "$c=\"$c_path\"" >> $toolspec
done

#check that R is installed
R_path=`which R 2>/dev/null`
if [ -z $R_path ] ; then
    echo "R not found!"
    echo "Please go to http://www.r-project.org/ and follow the installation instructions."
    echo "Please also install the required R packages:"
    echo "install.packages(c('optparse','plyr','dplyr','tidyr','reshape2'))"
fi
echo "R=\"$R_path\"" >> $toolspec

if [ ! -f $refdir/*.bed ] ; then
    mkdir -p $refdir
    echo "Downloading reference data"
    download_hg19
fi
 
echo >> $toolspec
echo "// Path to reference data" >> $toolspec
echo "refdir=\"$refdir\"" >> $toolspec

#loop through commands to check they are all installed
echo "**********************************************************"
echo "Checking that all required tools were installed:"
Final_message="All commands installed successfully!"
for c in $commands ; do
    c_path=`which $PWD/bin/$c 2>/dev/null`
    if [ -z $c_path ] ; then
	echo -n "WARNING: $c could not be found!!!! "
	echo "You will need to download and install $c manually, then add its path to $toolspec"
	Final_message="WARNING: One or more command did not install successfully. See warning messages above. \
                    You will need to correct this before running STRetch."
    else
        echo "$c looks like it has been installed"
    fi
done

#check for reference data
if [ ! -f $refdir/*.bed ] ; then
    echo -n "WARNING: reference files could not be found!!!! "
    echo "You will need to download them manually, then add the path to $toolspec"
else
    echo "It looks like the reference data has been downloaded"
fi

echo "**********************************************************"
echo $Final_message
echo "Please make sure you have installed the required R packages:"
echo "install.packages(c('optparse','plyr','dplyr','tidyr','reshape2'))"

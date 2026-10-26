#!/usr/bin/env bash
#
# Copyright 2020, Christopher Bennett <christopher@bennett-tech.dev>
#
# This file is part of HISAT-genotype. It is designed to set-up HISAT-genotype after 
# downloading from github and will add all appropriate links to your path
#
# HISAT-genotype is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# HISAT-genotype is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with HISAT-genotype.  If not, see <http://www.gnu.org/licenses/>.
#

# Set working directory and argument types using getopts
HG_DIR=$(pwd)
OPTIND=1
GET_REF=NO
OMMIT_BASH=NO
OUTFILE=""
while getopts "hbrx:" opt; do
    case "$opt" in
        h) 
            echo "USAGE: setup.sh -hrb"
            echo " -h : Show this help screen"
            echo " -b : Ommit adding PATH to .bashrc or .bash_profile file (Defualt - False)"
            echo " -r : Download the base references for HISAT-genotype to default folder (Default - False)"
            echo " -x : Download base references for HISAT-genotype to folder of choice"
            exit 0
            ;;
        b)  OMMIT_BASH=YES
            ;;
        r)  GET_REF=YES
            OUTFILE=indicies
            ;;           
        x)  GET_REF=YES
            OUTFILE=$OPTARG
            ;;
    esac
done

shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

add_to_bash(){
    echo "Adding to $1 and sourcing"
    echo "export PATH=$HG_DIR:$HG_DIR/hisat2:\$PATH" >> $1
    echo "export PYTHONPATH=$HG_DIR/hisatgenotype_modules:\$PYTHONPATH" >> $1
    source $1
}

# Files to check for
BASHRC=~/.bashrc
BASH_PROFILE=~/.bash_profile
HISAT2_DIR="hisat2"

# The real HISAT2 binaries are built INSIDE the hisat2/ submodule directory
# (not in the repository root).  The 'hisat2' entry that ends up in PATH is
# only a small wrapper script; the actual engine lives in hisat2-align-s /
# hisat2-align-l.  We therefore use the presence of these built binaries as
# the indicator that HISAT2 is ready, rather than 'command -v hisat2', which
# would be satisfied by the wrapper even when the engine has not been built.
HISAT2_ALIGN_BIN="$HISAT2_DIR/hisat2-align-s"
HISAT2_BUILD_BIN="$HISAT2_DIR/hisat2-build-s"

# Exit code for `type -P` is 1 if samtools cannot be found in PATH
type -P samtools &> /dev/null
if [[ $? == 1 ]]; then
    echo "Could not find samtools in PATH"
    exit 1;
fi

## This section downloads and sets-up hisat2 submodule
echo "Setting up HISAT2"

# setup.sh must be run from a real git checkout.  A GitHub "Download ZIP"
# archive has no .git/, so 'git submodule' below would fail with an opaque
# "not a git repository" error.  Fail early with a clear message instead.
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Error: setup.sh must be run inside a git checkout of HISAT-genotype."
    echo "Clone with:  git clone --recurse-submodules <repo-url>"
    echo "(A 'Download ZIP' archive does not contain .git/ or the hisat2"
    echo " submodule, so the HISAT2 engine cannot be built from it.)"
    exit 1
fi

if test ! -f "$HISAT2_DIR/Makefile"; then
    echo "> HISAT2 submodule not present; gathering it"
    git submodule init
    git submodule update
fi

if test ! -f "$HISAT2_DIR/Makefile"; then
    echo "Error: hisat2/ is empty after 'git submodule update'."
    echo "Re-run with:  git submodule update --init --recursive"
    exit 1
fi

# Build only if the engine binaries have not already been built.  Check the
# actual binaries in hisat2/, not the wrapper in PATH.
if test ! -f "$HISAT2_ALIGN_BIN" || test ! -f "$HISAT2_BUILD_BIN"; then
    echo "> Building HISAT2 (this may take a few minutes)"
    cd "$HISAT2_DIR"
    if make -j"$(nproc 2>/dev/null || echo 2)" ; then
        cd ..
    else
        cd ..
        echo "Error: HISAT2 build failed. See the make output above."
        exit 1
    fi
else
    echo "> HISAT2 already built in $HISAT2_DIR/ (nothing to do)"
fi

# Add PATH lines to BASH
if [ "$OMMIT_BASH" == "NO" ]; then
    if test -f "$BASHRC"; then
        add_to_bash "$BASHRC"
    elif test -f "$BASH_PROFILE"; then
        add_to_bash "$BASH_PROFILE"
    else
        add_to_bash "$BASHRC"
    fi
fi

# Download all references for HISAT-genotype
if [  "$GET_REF" == "YES" ]; then
    # HISAT2 must actually be built (engine binaries present in hisat2/), not
    # merely present as a wrapper in PATH, before indexes can be built.
    if test ! -f "$HISAT2_ALIGN_BIN" || test ! -f "$HISAT2_BUILD_BIN"; then
        echo "Cannot Build Indicies without HISAT2"
        echo "Run:  bash setup.sh   (it will build the HISAT2 engine)"
        exit 1
    fi

    if [ "$OUTFILE" != "indicies" ]; then
        echo $OUTFILE > hg_ix.link
    fi

    mkdir $OUTFILE
    cd $OUTFILE

    # genotype_genome
    wget ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat-genotype/data/genotype_genome_20180128.tar.gz
    tar xvzf genotype_genome_20180128.tar.gz
    rm genotype_genome_20180128.tar.gz

    #grch38
    wget ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat2/data/grch38.tar.gz
    tar xvzf grch38.tar.gz
    rm grch38.tar.gz
    hisat2-inspect grch38/genome > genome.fa
    samtools faidx genome.fa

    #HISATgenotpye Database
    git clone https://github.com/DaehwanKimLab/hisatgenotype_db.git
    cd -
fi


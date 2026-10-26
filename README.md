# HISAT-genotype

This is the official HISAT-genotype Repository.

Please see the official website for HISATgenotype:
https://daehwankimlab.github.io/hisat-genotype/

*This directory no longer contains HISAT2. Please see the link below if you are looking for the newest HISAT2 release*
https://daehwankimlab.github.io/hisat2/

## Current Release Version
v1.3.4 - Support for the new IPD-IMGT/HLA database releases (3.65.0 and later),
          robust database builds, and general stability fixes

## Previous Releases
v1.3.3 - Added option to output all allele counts

v1.3.2 - Update to patch critical extract reads error

v1.3.1 - Update database locations and handling, and general stability fixes - BROKEN

v1.3.0 - Python 3 version

## Overview
HISAT-genotype is a next-generation genomic analysis software platform capable of assembling and genotyping human genes and genomic regions. Thie software leverages HISAT2s graph FM index and graph alignemnt algorithm to align reads to a specially constructed graph genome. An Expectation-Maximization (EM) algorithm finds the maximum likelihood estimates for each gene allele and a guided de Bruijn graph is used to construct the allele sequences.

FROM continuumio/miniconda:4.5.4

MAINTAINER Juliette Hayer <juliette.hayer@slu.se>

RUN conda install conda=4.5.11
RUN apt-get update --fix-missing && apt install -yq make gcc g++ gfortran

COPY environment.yml /
RUN conda env create -f environment.yml
ENV PATH /opt/conda/envs/RNAseq_nf/bin:$PATH

FROM ubuntu:18.04

## SET UP ENVIRONMENT
LABEL maintainer="jannetta.steyn@newcastle.ac.uk"
ENV TZ=Europe/London
ARG DEBIAN_FRONTEND=noninteractive
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

## UPDATE LINUX
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y apt-utils
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y cmake git python3 python3-pip python3-dev wget  apt-transport-https software-properties-common zip unzip libpaper-utils xdg-utils liblas3 libcairo2 libcurl4 libjpeg8 liblapack3 libpango-1.0-0 libpangocairo-1.0-0 libpng16-16 libtiff5 libtk8.6 libxt6 gfortran libblas-dev libatlas-base-dev liblapack-dev libatlas-base-dev libncurses5-dev libreadline-dev libjpeg-dev libpcre3-dev libpng-dev zlib1g-dev libbz2-dev liblzma-dev libicu-dev pkg-config 
ENV PATH $PATH:/usr/local/conda/bin

## DOWNLOAD AND INSTALL REQUIRED LINUX PACKAGES FOR MLFOW
RUN apt-get -qq update \
	&& apt-get -qq -y install gnupg curl wget bzip2 git gcc vim unixodbc-dev g++ postgresql-client r-base r-base-core r-base-dev sqlite \
	&& wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
	&& bash Miniconda3-latest-Linux-x86_64.sh -bfp /usr/local/conda \
	&& conda install -y python=3 \
	&& conda update conda \
	&& apt-get -qq -y autoremove \
	&& apt-get autoclean \
	&& rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
	&& conda clean --all --yes
RUN rm /Miniconda3-latest-Linux-x86_64.sh

## DOWNLOAD AND INSTALL PYTHON PACKAGES FOR MLFLOW
RUN python -m pip install --upgrade pip
RUN pip install mlflow[extras]==1.13.1
RUN pip install whylogs==0.4.9

## INSTALL ALL THINGS JUPYTER
RUN pip install jupyter jupyter-core notebook
# RUN apt-get jupyter jupyter-core jupyter-notebook
RUN mkdir /root/.jupyter
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension
COPY jupyter_notebook_config.py /root/.jupyter/.

## INSTALL ALL THINGS R
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
RUN apt-get update
RUN apt-get install -y r-base r-base-dev

## INSTALL ALL THINGS PYTHON
RUN pip3 install cython pivottablejs pandas numpy
RUN pip3 install matplotlib tqdm rpy2 xgboost==1.0.1 scikit-learn==0.21.1 ipywidgets==7.1
RUN python3 -m pip install tensorflow

## COPY DATA FILES
COPY spambase.csv /autoprognosis/spambase.csv
# https://www.kaggle.com/uciml/breast-cancer-wisconsin-data
COPY kaggle_breastcancer.csv /autoprognosis/kaggle_breastcancer.csv
RUN ls -la /

## COPY ALL AutoPrognosis files
RUN git clone https://github.com/ahmedmalaa/AutoPrognosis.git
RUN cd AutoPrognosis; git checkout b3e2bec0763d29de97715a95f0bc7e17a1e9a1dd
RUN mv /AutoPrognosis/alg/autoprognosis /autoprognosis/.
COPY init/ /init/
COPY util/ /util/
COPY requirements.txt /autoprognosis/.
COPY install_packages.r /autoprognosis/.
RUN cd /autoprognosis
## R STUFF FOR AUTOPROGNOSIS
RUN Rscript /autoprognosis/install_packages.r
## PYTHON STUFF FOR AUTOPROGNOSIS
RUN python3 -m pip install -r /autoprognosis/requirements.txt
COPY *.ipynb /autoprognosis/


RUN mkdir /models
COPY *.sql /models/
COPY examples/ /models
COPY start.sh /start.sh
COPY jupyter_notebook_config.py /root/.jupyter/jupyter_notebook_config.py
COPY notebooks/ /models/notebooks
ENV MLFLOW_TRACKING_URI='http://0.0.0.0:5000'
WORKDIR /models
RUN cat demo1_multiclass_create.sql | sqlite3 mlruns.db
EXPOSE 5000
EXPOSE 1230-1240
EXPOSE 8080
# CMD tail -f /dev/null
CMD ["/bin/bash", "/start.sh"]

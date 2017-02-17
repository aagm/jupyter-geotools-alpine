FROM gliderlabs/alpine:latest
MAINTAINER test Project
# Based on this project https://github.com/show0k/alpine-jupyter-docker

USER root

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Configure Miniconda
ENV MINICONDA_VER 4.2.12
ENV MINICONDA Miniconda3-$MINICONDA_VER-Linux-x86_64.sh
ENV MINICONDA_URL https://repo.continuum.io/miniconda/$MINICONDA
ENV MINICONDA_MD5_SUM d0c7c71cc5659e54ab51f2005a8d96f3


RUN apk --update add \
    wget \
    --update tini \
    gdal \
    geos \
    bash \
    git \
    curl \
    ca-certificates \
    bzip2 \
    unzip \
    sudo \
    libstdc++ \
    glib \
    libxext \
    libxrender \
    vim \
    openssl \
    py-pip  \
    py-numpy \
    python \
    --update-cache \
    --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted \
    --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted \
    && curl "https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub" -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" -o glibc.apk \
    && apk add glibc.apk \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-bin-2.23-r3.apk" -o glibc-bin.apk \
    && apk add glibc-bin.apk \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc/usr/lib \
    && rm -rf glibc*apk /var/cache/apk/*

RUN apk --update add --virtual build-dependencies \
        python-dev \
        build-base \
        gdal-dev \
        geos-dev \
        py-numpy-dev \
        --update-cache \
        --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted \
        --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted \
    && apk del build-dependencies


# Create $NB_USER user with UID=1000 and in the 'users' group
RUN adduser -s /bin/bash -u $NB_UID -D $NB_USER && \
    mkdir -p /opt/conda && \
    chown $NB_USER /opt/conda

USER $NB_USER

# Setup $NB_USER home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.local

# Install conda as $NB_USER
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    curl -L $MINICONDA_URL  -o miniconda.sh && \
    echo "$MINICONDA_MD5_SUM  miniconda.sh" | md5sum -c - && \
    /bin/bash miniconda.sh -f -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda install --yes conda==$MINICONDA_VER

# Install Jupyter Notebook and Hub
RUN conda install --quiet --yes \
    'notebook=4.3*' \
    terminado \
    ipywidgets \
    && conda clean -yt

# Install Python 3.5 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
RUN conda install --yes \
    'nomkl' \
    'numpy=1.11*' \
    'rasterio=0.36.*' \
    'fiona=1.7*' \
    'pandas=0.19*' \
    'beautifulsoup4=4.5.*' \
    'vincent=0.4.*' \
    'shapely=1.5*' \
    'cython=0.23*' \
    'ipywidgets=5.2*' \
    'numexpr=2.6*' \
    'matplotlib=1.5*' \
    'scipy=0.18*' \
    'seaborn=0.7*' \
    'gensim=0.13*' \
    'netcdf4=1.2*' \
    'scikit-learn=0.18*' \
    'scikit-image=0.12*' \
    'sympy=1.0*' \
    'patsy=0.4*' \
    'statsmodels=0.6*' \
    'cloudpickle=0.1*' \
    'dill=0.2*' \
    'numba=0.30*' \
    'bokeh=0.11*' \
    'sqlalchemy=1.0*' \
    'hdf5=1.8.17' \
    'h5py=2.6*' \
    'xlrd' \
    && conda clean -yt

# Install Python 2 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
RUN conda create -p $CONDA_DIR/envs/python2 python=2.7 \
    'nomkl' \
    'numpy=1.11*' \
    'rasterio=0.36.*' \
    'fiona=1.7*' \
    'pandas=0.19*' \
    'beautifulsoup4=4.5.*' \
    'vincent=0.4.*' \
    'shapely=1.5*' \
    'cython=0.23*' \
    'ipython=4.2*' \
    'ipywidgets=5.2*' \
    'numexpr=2.6*' \
    'matplotlib=1.5*' \
    'scipy=0.17*' \
    'seaborn=0.7*' \
    'scikit-learn=0.18*' \
    'scikit-image=0.12*' \
    'sympy=1.0*' \
    'patsy=0.4*' \
    'statsmodels=0.6*' \
    'cloudpickle=0.1*' \
    'dill=0.2*' \
    'numba=0.30*' \
    'bokeh=0.11*' \
    'hdf5=1.8.17' \
    'h5py=2.6*' \
    'sqlalchemy=1.0*' \
    'pyzmq' \
    'xlrd' \
    && conda clean -yt
USER root
COPY requirements.txt /home/$NB_USER/requirements.txt
RUN pip install -r /home/$NB_USER/requirements.txt




EXPOSE 8888

WORKDIR /home/$NB_USER/work

# Configure container startup
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start-notebook.sh /usr/local/bin/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter
RUN chmod +x /usr/local/bin/start-notebook.sh

# Install Python 2 kernel spec globally to avoid permission problems when NB_UID
# switching at runtime.
RUN $CONDA_DIR/envs/python2/bin/python \
    $CONDA_DIR/envs/python2/bin/ipython \
    kernelspec install-self

# Switch back to $NB_USER to avoid accidental container runs as root
RUN chown -R $NB_USER:users /home/$NB_USER/.local
USER $NB_USER



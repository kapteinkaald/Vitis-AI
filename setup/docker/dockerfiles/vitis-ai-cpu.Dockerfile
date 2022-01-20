FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
ENV TZ=America/Denver
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV VAI_ROOT=/opt/vitis_ai
ENV VAI_HOME=/vitis_ai_home
ARG VERSION
ENV VERSION=$VERSION
ARG DOCKER_TYPE="(CPU)"
ENV DOCKER_TYPE=$DOCKER_TYPE
ARG GIT_HASH="<blank>"
ENV GIT_HASH=$GIT_HASH
ARG DATE
ENV DATE=$DATE
ARG XRT_URL=https://www.xilinx.com/bin/public/openDownload?filename=xrt_202120.2.12.427_18.04-amd64-xrt.deb
ENV XRT_URL=$XRT_URL
ARG XRM_URL=https://www.xilinx.com/bin/public/openDownload?filename=xrm_202120.1.3.29_18.04-x86_64.deb
ENV XRM_URL=$XRM_URL
ARG PETALINUX_URL=https://www.xilinx.com/bin/public/openDownload?filename=sdk-2021.2.0.0.sh
ENV PETALINUX_URL=$PETALINUX_URL
ARG VAI_CONDA_CHANNEL="file:///scratch/conda-channel"
ENV VAI_CONDA_CHANNEL=$VAI_CONDA_CHANNEL
ARG VAI_DEB_CHANNEL=""
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


RUN chmod 1777 /tmp \
    && mkdir /scratch \
    && chmod 1777 /scratch \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        autoconf \
        automake \
        bc \
        build-essential \
        bzip2 \
        ca-certificates \
        curl \
        g++ \
        gdb \
        git \
        gnupg \
        locales \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libgtest-dev \
        libjson-c-dev \
        libjsoncpp-dev \
        libssl-dev \
        libtool \
        libunwind-dev \
        make \
        openssh-client \
        openssl \
        python3 \
        python3-dev \
        python3-minimal \
        python3-numpy \
        python3-opencv \
        python3-pip \
        python3-setuptools \
        python3-venv \
        software-properties-common \
        sudo \
        tree \
        unzip \
        vim \
        wget \
        yasm \
        zstd

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && locale-gen en_US.UTF-8 \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && dpkg-reconfigure locales

# Tools for building vitis-ai-library in the docker container
RUN apt-get install -y \
        libavcodec-dev \
        libavformat-dev \
        libeigen3-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer1.0-dev \
        libgtest-dev \
        libgtk-3-dev \
        libgtk2.0-dev \
        libhdf5-dev \
        libjpeg-dev \
        libopenexr-dev \
        libpng-dev \
        libswscale-dev \
        libtiff-dev \
        libwebp-dev \
        opencl-clhpp-headers \
        opencl-headers \
        pocl-opencl-icd \
        rpm \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get install -y \
        gcc-8 \
        g++-8 \
        gcc-9 \
        g++-9 \
    && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null \
    && apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main' \
    && apt-get update -y \
    && apt-get install -y \
        cmake=3.16.0-0kitware1 \
        cmake-data=3.16.0-0kitware1 \
        kitware-archive-keyring \
    && apt-get install -y ffmpeg \
    && cd /usr/src/gtest \
    && mkdir -p build \
    && cd build \
    && cmake .. \
    && make \
    && make install

RUN pip3 install \
        Flask \
        setuptools \
        wheel

# Install XRT
RUN wget --progress=dot:mega -O xrt.deb ${XRT_URL} \
    && ls -lhd ./xrt.deb \
    && apt-get update -y \
    && apt-get install -y ./xrt.deb \
    && rm -fr /tmp/*

# Install XRM
RUN wget --progress=dot:mega -O xrm.deb ${XRM_URL} \
    && ls -lhd ./xrm.deb \
    && apt-get install -y ./xrm.deb \
    && rm -fr /tmp/*

# glog 0.4.0
RUN cd /tmp \
    && wget --progress=dot:mega -O glog.0.4.0.tar.gz https://codeload.github.com/google/glog/tar.gz/v0.4.0 \
    && tar -xvf glog.0.4.0.tar.gz \
    && cd glog-0.4.0 \
    && ./autogen.sh \
    && mkdir build \
    && cd build \
    && cmake -DBUILD_SHARED_LIBS=ON .. \
    && make -j \
    && make install \
    && rm -fr /tmp/*

# protobuf 3.4.0
RUN cd /tmp; wget --progress=dot:mega https://codeload.github.com/google/protobuf/zip/v3.4.0 \
    && unzip v3.4.0 \
    && cd protobuf-3.4.0 \
    && ./autogen.sh \
    && ./configure \
    && make -j \
    && make install \
    && ldconfig \
    && rm -fr /tmp/*

# opencv 3.4.1
RUN add-apt-repository ppa:timsc/opencv-3.4 \
    && apt-get update \
    && apt install -y\
        libcv-dev=3.4.1-bionic1.1 \
        libcv3.4=3.4.1-bionic1.1 \
        libopencv-calib3d-dev=3.4.1-bionic1.1  \
        libopencv-calib3d3.4-dbg=3.4.1-bionic1.1 \
        libopencv-calib3d3.4=3.4.1-bionic1.1 \
        libopencv-core-dev=3.4.1-bionic1.1 \
        libopencv-core3.4=3.4.1-bionic1.1 \
        libopencv-dev=3.4.1-bionic1.1 \
        libopencv-dnn-dev=3.4.1-bionic1.1 \
        libopencv-dnn3.4-dbg=3.4.1-bionic1.1 \
        libopencv-dnn3.4=3.4.1-bionic1.1 \
        libopencv-features2d-dev=3.4.1-bionic1.1 \
        libopencv-features2d3.4-dbg=3.4.1-bionic1.1 \
        libopencv-features2d3.4=3.4.1-bionic1.1 \
        libopencv-flann-dev=3.4.1-bionic1.1 \
        libopencv-flann3.4-dbg=3.4.1-bionic1.1 \
        libopencv-flann3.4=3.4.1-bionic1.1 \
        libopencv-highgui-dev=3.4.1-bionic1.1 \
        libopencv-highgui3.4-dbg=3.4.1-bionic1.1 \
        libopencv-highgui3.4=3.4.1-bionic1.1 \
        libopencv-imgcodecs-dev=3.4.1-bionic1.1 \
        libopencv-imgcodecs3.4-dbg=3.4.1-bionic1.1 \
        libopencv-imgcodecs3.4=3.4.1-bionic1.1 \
        libopencv-imgproc-dev=3.4.1-bionic1.1 \
        libopencv-imgproc3.4-dbg=3.4.1-bionic1.1 \
        libopencv-imgproc3.4=3.4.1-bionic1.1 \
        libopencv-ml-dev=3.4.1-bionic1.1 \
        libopencv-ml3.4-dbg=3.4.1-bionic1.1 \
        libopencv-ml3.4=3.4.1-bionic1.1 \
        libopencv-objdetect-dev=3.4.1-bionic1.1 \
        libopencv-objdetect3.4-dbg=3.4.1-bionic1.1 \
        libopencv-objdetect3.4=3.4.1-bionic1.1 \
        libopencv-photo-dev=3.4.1-bionic1.1 \
        libopencv-photo3.4-dbg=3.4.1-bionic1.1 \
        libopencv-photo3.4=3.4.1-bionic1.1 \
        libopencv-shape-dev=3.4.1-bionic1.1 \
        libopencv-shape3.4-dbg=3.4.1-bionic1.1 \
        libopencv-shape3.4=3.4.1-bionic1.1 \
        libopencv-stitching-dev=3.4.1-bionic1.1 \
        libopencv-stitching3.4-dbg=3.4.1-bionic1.1 \
        libopencv-stitching3.4=3.4.1-bionic1.1 \
        libopencv-superres-dev=3.4.1-bionic1.1 \
        libopencv-superres3.4-dbg=3.4.1-bionic1.1 \
        libopencv-superres3.4=3.4.1-bionic1.1 \
        libopencv-ts-dev=3.4.1-bionic1.1 \
        libopencv-video-dev=3.4.1-bionic1.1 \
        libopencv-video3.4-dbg=3.4.1-bionic1.1 \
        libopencv-video3.4=3.4.1-bionic1.1 \
        libopencv-videoio-dev=3.4.1-bionic1.1 \
        libopencv-videoio3.4-dbg=3.4.1-bionic1.1 \
        libopencv-videoio3.4=3.4.1-bionic1.1 \
        libopencv-videostab-dev=3.4.1-bionic1.1 \
        libopencv-videostab3.4-dbg=3.4.1-bionic1.1 \
        libopencv-videostab3.4=3.4.1-bionic1.1 \
        libopencv-viz-dev=3.4.1-bionic1.1 \
        libopencv-viz3.4-dbg=3.4.1-bionic1.1 \
        libopencv-viz3.4=3.4.1-bionic1.1 \
        libopencv3.4-java=3.4.1-bionic1.1 \
        opencv-data=3.4.1-bionic1.1 \
        opencv-doc=3.4.1-bionic1.1 \
        python-opencv=3.4.1-bionic1.1 \
        python3-opencv=3.4.1-bionic1.1


# gflags 2.2.2
RUN cd /tmp; wget --progress=dot:mega https://github.com/gflags/gflags/archive/v2.2.2.tar.gz \
    && tar xvf v2.2.2.tar.gz \
    && cd gflags-2.2.2 \
    && mkdir build \
    && cd build \
    && cmake -DBUILD_SHARED_LIBS=ON .. \
    && make -j \
    && make install \
    && rm -fr /tmp/*

# pybind 2.5.0
RUN cd /tmp; git clone https://github.com/pybind/pybind11.git \
    && cd pybind11 \
    && git checkout v2.5.0 \
    && mkdir build \
    && cd build \
    && cmake -DPYBIND11_TEST=OFF .. \
    && make \
    && make install \
    && rm -fr /tmp/* \
    && chmod 777 /usr/lib/python3/dist-packages

RUN source ~/.bashrc \
    && wget --progress=dot:mega https://github.com/json-c/json-c/archive/json-c-0.15-20200726.tar.gz \
    && tar xvf json-c-0.15-20200726.tar.gz \
    && cd json-c-json-c-0.15-20200726 \
    && mkdir build \
    && cd build \
    && cmake -DBUILD_SHARED_LIBS=ON .. \
    && make -j \
    && make install \
    && rm -Rf /tmp/*

ENV GOSU_VERSION 1.12

COPY dockerfiles/bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc
RUN groupadd vitis-ai-group \
    && useradd --shell /bin/bash -c '' -m -g vitis-ai-group vitis-ai-user \
    && passwd -d vitis-ai-user \
    && usermod -aG sudo vitis-ai-user \
    && echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo 'Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/vitis_ai/conda/bin"' >> /etc/sudoers \
    && curl -sSkLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && chmod +x /usr/local/bin/gosu \
    && echo ". $VAI_ROOT/conda/etc/profile.d/conda.sh" >> ~vitis-ai-user/.bashrc \
    && echo "conda activate base" >> ~vitis-ai-user/.bashrc \
    && echo "export VERSION=${VERSION}" >> ~vitis-ai-user/.bashrc \
    && echo "export BUILD_DATE=\"${DATE}\"" >> ~vitis-ai-user/.bashrc \
    && echo "export GIT_HASH=${GIT_HASH}" >> ~vitis-ai-user/.bashrc \
    && cat ~vitis-ai-user/.bashrc >> /root/.bashrc \
    && echo $VERSION > /etc/VERSION.txt \
    && echo $DATE > /etc/BUILD_DATE.txt \
    && echo $GIT_HASH > /etc/GIT_HASH.txt \
    && echo 'export PS1="\[\e[91m\]Vitis-AI\[\e[m\] \w > "' >> ~vitis-ai-user/.bashrc \
    && mkdir -p ${VAI_ROOT} \
    && chown -R vitis-ai-user:vitis-ai-group ${VAI_ROOT} \
    && mkdir /etc/conda \
    && touch /etc/conda/condarc \
    && chmod 777 /etc/conda/condarc \
    && cat /etc/conda/condarc \
    && mkdir -p ${VAI_ROOT}/scripts \
    && chmod 775 ${VAI_ROOT}/scripts

COPY dockerfiles/host_cross_compiler_setup.sh ${VAI_ROOT}/scripts/
RUN chmod a+rx ${VAI_ROOT}/scripts/host_cross_compiler_setup.sh

COPY dockerfiles/replace_pytorch.sh ${VAI_ROOT}/scripts/
RUN chmod a+rx ${VAI_ROOT}/scripts/replace_pytorch.sh

# Set up Anaconda
USER vitis-ai-user

RUN cd /tmp \
    && wget --progress=dot:mega https://github.com/conda-forge/miniforge/releases/download/4.10.3-5/Mambaforge-4.10.3-5-Linux-x86_64.sh -O miniconda.sh \
    && /bin/bash ./miniconda.sh -b -p $VAI_ROOT/conda \
    && cat /dev/null > /etc/conda/condarc \
    && echo "channels:" >> /etc/conda/condarc \
    && echo "  - ${VAI_CONDA_CHANNEL}" >> /etc/conda/condarc \
    && echo "remote_connect_timeout_secs: 60.0">> /etc/conda/condarc \
    && rm -fr /tmp/miniconda.sh \
    && sudo ln -s $VAI_ROOT/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && . /etc/profile.d/conda.sh \
    &&  conda clean -y --force-pkgs-dirs

ADD --chown=vitis-ai-user:vitis-ai-group dockerfiles/cpu_conda/*.yml /scratch/
ADD --chown=vitis-ai-user:vitis-ai-group dockerfiles/pip_requirements.txt /scratch/

# Rebuild this layer every time
ARG CACHEBUST=1

RUN cd /scratch/ \
    && wget -O conda-channel.tar.gz --progress=dot:mega https://www.xilinx.com/bin/public/openDownload?filename=conda-channel_2.0.0.1103-02.tar.gz \
    && tar -xzvf conda-channel.tar.gz \
    && . $VAI_ROOT/conda/etc/profile.d/conda.sh \
    && mamba install -c conda-forge conda-build \
    && python3 -m pip install --upgrade pip wheel setuptools \
    && mamba env create -f /scratch/vitis-ai-pytorch.yml \
        && conda activate vitis-ai-pytorch \
        && pip install -r /scratch/pip_requirements.txt \
    && mamba env create -f /scratch/vitis-ai-caffe.yml \
        && conda activate vitis-ai-caffe \
        &&  mamba  install -y --no-update-deps  pydot pyyaml jupyter ipywidgets \
        dill progressbar2 pytest scikit-learn pandas matplotlib \
        pillow  -c conda-forge -c defaults \
        && pip install -r /scratch/pip_requirements.txt \
    && mamba env create -f /scratch/vitis-ai-tensorflow.yml \
        && conda activate vitis-ai-tensorflow \
        && pip install -r /scratch/pip_requirements.txt \
    && mamba env create -f /scratch/vitis-ai-tensorflow2.yml \
        && conda activate vitis-ai-tensorflow2 \
        &&  mamba  install --no-update-deps -y vai_q_tensorflow2  pydot pyyaml jupyter ipywidgets \
        dill progressbar2 pytest scikit-learn pandas matplotlib \
        pillow  -c conda-forge -c defaults \
        && pip install -r /scratch/pip_requirements.txt \
        && pip install  --ignore-installed tensorflow==2.6 keras==2.6 \
        && pip uninstall -y h5py \
         && pip uninstall -y h5py \
        && mamba install  -y --override-channels --force-reinstall h5py=2.10.0  -c conda-forge -c anaconda  \
    && conda clean -y --force-pkgs-dirs \
    && rm -fr ~/.cache \
    && mkdir -p $VAI_ROOT/compiler \
        && conda activate vitis-ai-caffe \
        && sudo cp -r $CONDA_PREFIX/lib/python3.6/site-packages/vaic/arch $VAI_ROOT/compiler/arch \
    && cat /dev/null > /etc/conda/condarc

USER root
# VAI-1372: Workaround to fix GCC 9 in vitis-ai-tensorflow
RUN rm -f /opt/vitis_ai/conda/envs/vitis-ai-tensorflow/etc/conda/activate.d/activate-binutils_linux-64.sh \
    && rm -f /opt/vitis_ai/conda/envs/vitis-ai-tensorflow/etc/conda/activate.d/activate-gcc_linux-64.sh \
    && rm -f /opt/vitis_ai/conda/envs/vitis-ai-tensorflow/etc/conda/activate.d/activate-gxx_linux-64.sh \
    && rm -f /opt/vitis_ai/conda/envs/vitis-ai-tensorflow/etc/conda/deactivate.d/deactivate-binutils_linux-64.sh \
    && rm -f /opt/vitis_ai/conda/envs/vitis-ai-tensorflow/etc/conda/deactivate.d/deactivate-gcc_linux-64.sh \
    && rm -f /opt/vitis_ai/conda/envs/vitis-ai-tensorflow/etc/conda/deactivate.d/deactivate-gxx_linux-64.sh

# VAI-1751: Allow all users permissions to install python packages
RUN chmod -R 777 /opt/vitis_ai/conda/envs/vitis-ai-pytorch/lib/python3.6/site-packages

# Rebuild this layer every time
ARG CACHEBUST=1
RUN cd /tmp \
    && wget -O libunilog.deb https://www.xilinx.com/bin/public/openDownload?filename=libunilog_1.4.1-r82_amd64.deb \
    && wget -O libtarget-factory.deb https://www.xilinx.com/bin/public/openDownload?filename=libtarget-factory_1.4.1-r85_amd64.deb \
    && wget -O libxir.deb https://www.xilinx.com/bin/public/openDownload?filename=libxir_1.4.1-r91_amd64.deb \
    && wget -O libvart.deb https://www.xilinx.com/bin/public/openDownload?filename=libvart_1.4.1-r130_amd64.deb \
    && wget -O libvitis_ai_library.deb https://www.xilinx.com/bin/public/openDownload?filename=libvitis_ai_library_1.4.1-r114_amd64.deb \
    && wget -O librt-engine.deb https://www.xilinx.com/bin/public/openDownload?filename=librt-engine_1.4.1-r195_amd64.deb \
    && wget -O aks.deb https://www.xilinx.com/bin/public/openDownload?filename=aks_1.4.1-r78_amd64.deb \
    && apt-get install -y --no-install-recommends /tmp/*.deb \
    && rm -rf /tmp/* \
    && ldconfig

RUN apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /scratch/*

# Set default build toolchain to GCC 9 for better performance
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-9 \
        --slave /usr/bin/gcov gcov /usr/bin/gcov-9 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
        --slave /usr/bin/gcov gcov /usr/bin/gcov-8 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 70 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-7 \
        --slave /usr/bin/gcov gcov /usr/bin/gcov-7

ADD dockerfiles/banner.sh /etc/
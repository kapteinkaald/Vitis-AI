FROM nvidia/cuda:11.0.3-cudnn8-runtime-ubuntu18.04
env DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
ENV TZ=America/Denver
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV VAI_ROOT=/opt/vitis_ai
ENV VAI_HOME=/vitis_ai_home
ARG VERSION
ENV VERSION=$VERSION
ARG DOCKER_TYPE="(GPU)"
ENV DOCKER_TYPE=$DOCKER_TYPE
ARG GIT_HASH="<blank>"
ENV GIT_HASH=$GIT_HASH
ARG DATE
ENV DATE=$DATE
ARG XRT_URL=https://www.xilinx.com/bin/public/openDownload?filename=xrt_202120.2.12.427_18.04-amd64-xrt.deb
ENV XRT_URL=$XRT_URL
ARG XRM_URL=https://www.xilinx.com/bin/public/openDownload?filename=xrm_202120.1.3.29_18.04-x86_64.deb
ENV XRM_URL=$XRM_URL
ARG PETALINUX_URL=https://www.xilinx.com/bin/public/openDownload?filename=sdk-2022.1.0.0.sh
ENV PETALINUX_URL=$PETALINUX_URL
ARG VAI_CONDA_CHANNEL="https://www.xilinx.com/bin/public/openDownload?filename=conda-channel_2.5.0.1260-01.tar.gz"
ENV VAI_CONDA_CHANNEL=$VAI_CONDA_CHANNEL
ARG VAI_DEB_CHANNEL=""
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN chmod 1777 /tmp \
    && mkdir /scratch \
    && chmod 1777 /scratch \
    && rm -fr /etc/apt/sources.list.d/cuda* \
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
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libgtest-dev \
        libjson-c-dev \
        libjsoncpp-dev \
        libssl-dev \
        libtool \
        libunwind-dev \
        locales \
        make \
        openssh-client \
        openssl \
        python3 \
        python3-dev \
        python3-minimal \
        python3-numpy \
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
RUN apt-get -y install \
        libgtest-dev \
        libeigen3-dev \
        rpm \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer1.0-dev \
        libgtk-3-dev \
        libpng-dev \
        libjpeg-dev \
        libopenexr-dev \
        libtiff-dev \
        libwebp-dev \
        libgtk2.0-dev \
        libhdf5-dev \
        opencl-clhpp-headers \
        opencl-headers \
        pocl-opencl-icd \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt install -y gcc-8 g++-8 gcc-9 g++-9 \
    && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null \
    && echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null \
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
    && apt-get update -y  \
   &&  apt-get install -y ./xrt.deb \
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

# opencv 3.4.3
RUN export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    && cd /tmp; wget --progress=dot:mega https://github.com/opencv/opencv/archive/3.4.3.tar.gz \
    && tar -xvf 3.4.3.tar.gz \
    && cd opencv-3.4.3 \
    && mkdir build \
    && cd build \
    && cmake -DBUILD_SHARED_LIBS=ON .. \
    && make -j \
    && make install \
    && ldconfig \
    && export PATH="${VAI_ROOT}/conda/bin:${VAI_ROOT}/utility:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    && rm -fr /tmp/*

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
    && echo "  - file:///scratch/conda-channel" >> /etc/conda/condarc \
    && echo "remote_connect_timeout_secs: 60.0">> /etc/conda/condarc \
    && rm -fr /tmp/miniconda.sh \
    && sudo ln -s $VAI_ROOT/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && . /etc/profile.d/conda.sh \
    &&  conda clean -y --force-pkgs-dirs

RUN cd /scratch/ \
    && wget -O conda-channel.tar.gz --progress=dot:mega https://www.xilinx.com/bin/public/openDownload?filename=conda-channel_2.0.0.1103-02.tar.gz \
    && tar -xzvf conda-channel.tar.gz \
    && . $VAI_ROOT/conda/etc/profile.d/conda.sh \
    && mamba install -c conda-forge conda-build \
    && mamba create -n vitis-ai-pytorch python=3.6 \
    && conda activate vitis-ai-pytorch \
    && mamba install pytorch=1.7.1 torchvision=0.8.2 cpuonly -c pytorch \
    && mamba install libboost=1.65 -c anaconda \
    && mamba install pytorch_nndct_cpu vaic \
    && conda clean -y --force-pkgs-dirs \
    && rm -fr ~/.cache \
    && mkdir -p $VAI_ROOT/compiler \
    && conda activate vitis-ai-pytorch \
    && sudo cp -r $CONDA_PREFIX/lib/python3.6/site-packages/vaic/arch $VAI_ROOT/compiler/arch \
    && cat /dev/null > /etc/conda/condarc

USER root
RUN chmod -R 777 /opt/vitis_ai/conda/envs/vitis-ai-pytorch/
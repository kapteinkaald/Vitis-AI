FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
ENV VAI_ROOT=/opt/vitis_ai
ENV VAI_HOME=/vitis_ai_home


RUN chmod 1777 /tmp \
    && mkdir /scratch \
    && chmod 1777 /scratch \
    && apt-get update -y > /dev/null \
    && apt-get install -y --no-install-recommends \
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
    software-properties-common \
    sudo \
    tree \
    unzip \
    vim \
    wget \
    yasm \
    zstd \
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
    > /dev/null

# gcc8 and 9
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get install -y gcc-8 g++-8 gcc-9 g++-9 > /dev/null \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-9 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-9 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-8 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 70 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-7 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-7

# cmake
RUN cd /tmp && wget -q -O cmake.sh https://github.com/Kitware/CMake/releases/download/v3.16.0/cmake-3.16.0-Linux-x86_64.sh \
    && echo y | /bin/bash ./cmake.sh --prefix=/usr/local --exclude-subdir > /dev/null \
    && cmake --version \
    && rm -fr /tmp/*

# gosu
RUN curl -sSkLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64" \
    && chmod +x /usr/local/bin/gosu

# Install XRT and XRM
RUN cd /tmp \
    && wget --progress=dot:mega -O xrt.deb https://www.xilinx.com/bin/public/openDownload?filename=xrt_202120.2.12.427_18.04-amd64-xrt.deb \
    && wget --progress=dot:mega -O xrm.deb https://www.xilinx.com/bin/public/openDownload?filename=xrm_202120.1.3.29_18.04-x86_64.deb \
    && apt-get install -y ./xrt.deb ./xrm.deb > /dev/null \
    && rm -fr /tmp/*

# vitis ai stuff
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


COPY dockerfiles/bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc
RUN groupadd vitis-ai-group \
    && useradd --shell /bin/bash -c '' -m -g vitis-ai-group vitis-ai-user \
    && passwd -d vitis-ai-user \
    && usermod -aG sudo vitis-ai-user \
    && echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo 'Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/vitis_ai/conda/bin"' >> /etc/sudoers \
    && echo ". $VAI_ROOT/conda/etc/profile.d/conda.sh" >> ~vitis-ai-user/.bashrc \
    && echo "conda activate base" >> ~vitis-ai-user/.bashrc \
    && cat ~vitis-ai-user/.bashrc >> /root/.bashrc \
    && echo 'export PS1="\[\e[91m\]Vitis-AI\[\e[m\] \w > "' >> ~vitis-ai-user/.bashrc \
    && mkdir -p ${VAI_ROOT} \
    && chown -R vitis-ai-user:vitis-ai-group ${VAI_ROOT} \
    && mkdir /etc/conda \
    && touch /etc/conda/condarc \
    && chmod 777 /etc/conda/condarc \
    && cat /etc/conda/condarc \
    && mkdir -p ${VAI_ROOT}/scripts \
    && chmod 775 ${VAI_ROOT}/scripts

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
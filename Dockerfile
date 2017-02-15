FROM ubuntu:16.04

ARG BAZEL_VERSION=0.4.2
ARG TENSORFLOW_VERSION=0.12.0

ARG PROXY_SERVER=http://proxy:8080
ARG NO_PROXY=*.local,169.254/16

ENV http_proxy $PROXY_SERVER
ENV https_proxy $PROXY_SERVER
ENV ftp_proxy $PROXY_SERVER
ENV all_proxy $PROXY_SERVER
ENV HTTP_PROXY $PROXY_SERVER
ENV HTTPS_PROXY $PROXY_SERVER
ENV FTP_PROXY $PROXY_SERVER
ENV ALL_PROXY $PROXY_SERVER
ENV no_proxy ${NO_PROXY}
ENV NO_PROXY ${NO_PROXY}

RUN apt-get update && apt-get install -y \
		bc \
		build-essential \
		cmake \
		curl \
		g++ \
		gfortran \
		git \
		libffi-dev \
		libfreetype6-dev \
		libhdf5-dev \
		libjpeg-dev \
		liblcms2-dev \
		libpng12-dev \
		libssl-dev \
		libtiff5-dev \
		libwebp-dev \
		libzmq3-dev \
		nano \
		pkg-config \
		software-properties-common \
		unzip \
		vim \
		wget \
		zlib1g-dev \
		htop \
		python3-dev \
		python3-numpy \
		python3-scipy \
		python3-h5py \
		python3-skimage \
		python3-matplotlib \
		python3-setuptools \
		python3-wheel \
		python3-pip \
		&& \
	apt-get clean && \
	apt-get autoremove


RUN \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
RUN echo "startup --batch" >>/root/.bazelrc
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/root/.bazelrc
ENV BAZELRC /root/.bazelrc
# Install the most recent bazel release.

WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE.txt && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download and build TensorFlow.

RUN git config --global http.proxy $http_proxy && \
    git config --global https.proxy $https_proxy

RUN git clone --recursive https://github.com/phvu/tensorflow.git && \
    cd tensorflow && \
    git checkout mkl
WORKDIR /tensorflow

# TODO(craigcitro): Don't install the pip package, since it makes it
# more difficult to experiment with local changes. Instead, just add
# the built directory to the path.

ENV TF_NEED_CUDA=0 \
    TF_MKL_ENABLED="true" \
    PYTHON_BIN_PATH="/usr/bin/python3" \
    USE_DEFAULT_PYTHON_LIB_PATH=1 \
    TF_NEED_MKL=1 \
    CC_OPT_FLAGS="-march=native --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.2" \
    TF_NEED_JEMALLOC=1 \
    TF_NEED_GCP=0 \
    TF_NEED_HDFS=0 \
    TF_ENABLE_XLA=0 \
    TF_NEED_OPENCL=0

RUN ./configure && \
    bazel build -c opt tensorflow/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/pip && \
    pip3 install --upgrade /tmp/pip/tensorflow-*.whl
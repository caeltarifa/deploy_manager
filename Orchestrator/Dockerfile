# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.


FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

# Configuraci�n del directorio de trabajo
WORKDIR /app

# Copiar los archivos publicados a la imagen
COPY ./app .

EXPOSE 8080 8081 2428

# Variables de entorno
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV DOTNET_gcServer=1
ENV DOTNET_gcConcurrent=0
ENV DOTNET_GCLOHCompact=1

# Configuración de variables de entorno
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV PATH="/usr/src/tensorrt/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="/app/runtimes/linux-x64/native:${LD_LIBRARY_PATH}"
ENV GST_PLUGIN_PATH="/usr/local/cuda/lib64"
ENV GST_PLUGIN_PATH="/app/runtimes/linux-x64/native:${GST_PLUGIN_PATH}"
ENV GST_PLUGIN_FEATURE_RANK="audioconvert:NONE audioresample:NONE"
ENV GST_GL_API=disable
ENV XDG_RUNTIME_DIR="/tmp"

ENV GST_VAAPI_DISABLE=1

ENV PATH="/usr/local/cuda-12.1/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda-12.1/lib64:${LD_LIBRARY_PATH}"

# Variable de entorno para desabilitar la aceleracion Intel y el acceso al display
# ENV GST_VAAPI_DISABLE=1
# ENV GST_VAAPI_ALL_DRIVERS=disable
# ENV GST_PLUGIN_FEATURE_RANK=msdk:0


# Configurar APT para ser más resiliente y agregar retraso
RUN echo "Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries && \
    echo "Acquire::http::Timeout \"120\";" > /etc/apt/apt.conf.d/99timeout


RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 \
    software-properties-common \
    gawk \
    bison \
    wget \
    unzip \
    pkg-config \
    build-essential \
    ca-certificates \
    cmake \
    git \
    apt-transport-https \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-pulseaudio \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libopencv-dev \
    libgtk2.0-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libtbb2 \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    gfortran \
    openexr \
    libatlas-base-dev \
    python3-numpy \
    libgdal-dev \
    libzstd-dev \
    liblz4-tool \
    libzvbi0 \
    libopenjp2-7 \
    libwebp-dev \
    libvpx-dev \
    librsvg2-dev \
    libswresample-dev \
    libx265-dev \
    libnuma-dev \
    libopenmpt-dev \
    libmp3lame-dev \
    libopus-dev \
    libtwolame-dev \
    libgsm1-dev \
    libtheora-dev \
    libshine-dev \
    libvorbis-dev \
    libva-dev \
    libva-drm2 \
    libva-x11-2 \
    libvdpau-dev \
    libgnutls28-dev \
    libharfbuzz-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libatk1.0-dev \
    libgdk-pixbuf2.0-dev \
    liblapack3 \
    liblapack-dev \
    libblas-dev \
    libatlas-base-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update && apt-get install -y \
    aspnetcore-runtime-8.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update


# Instalación de cuDNN 9
RUN apt-get install -y --no-install-recommends \
    cudnn-cuda-12 \
    libyaml-cpp-dev \
    tesseract-ocr \
    libcivetweb-dev \
    libgstrtspserver-1.0-0 \
    libcivetweb1 \
    libgrpc++1 \
    librdkafka1 \
    libhiredis0.14 \
    libmosquitto1 \
    datacenter-gpu-manager \
    cuda-toolkit \
    nvidia-container-toolkit \
    tensorrt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:mhier/libboost-latest \
    && apt update \
    && apt install -y libboost-filesystem-dev \
    libboost-thread-dev \
    libcufft10 \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-dev \
    cuda-cudart-12-2 \
    cuda-cudart-dev-12-2 \
    libnpp-12-2 \
    libnpp-dev-12-2 \
    libgles2-mesa-dev \
    && rm -rf /var/lib/apt/lists/*
  

RUN ln -s /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.74.0 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.80.0 || true
RUN ln -s /usr/lib/x86_64-linux-gnu/libboost_thread.so.1.74.0 /usr/lib/x86_64-linux-gnu/libboost_thread.so.1.71.0 || true
RUN ln -s /usr/local/cuda/targets/x86_64-linux/lib/libcufftw.so.11 /usr/lib/x86_64-linux-gnu/libcufftw.so.11 || true
RUN ln -s /usr/local/cuda/targets/x86_64-linux/lib/libcudart.so.12 /usr/lib/x86_64-linux-gnu/libcudart.so.12 || true

RUN ls -lah /usr/local/cuda/lib64/libnvrtc.so || ln -s /usr/local/cuda/lib64/libnvrtc.so.12.2.140 /usr/local/cuda/lib64/libnvrtc.so
    
# Descargar e instalar DeepStream
COPY ./temp/deepstream_sdk.deb /tmp/deepstream_sdk.deb
RUN dpkg -i /tmp/deepstream_sdk.deb || apt-get install -f -y

# Configurar variables de entorno para DeepStream
ENV PATH="/opt/nvidia/deepstream/deepstream-7.1/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/nvidia/deepstream/deepstream-7.1/lib:/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
ENV GST_PLUGIN_PATH="/opt/nvidia/deepstream/deepstream-7.1/lib/gst-plugins"
ENV PYTHONPATH="/opt/nvidia/deepstream/deepstream-7.1/lib/python"

# Variables de entorno configurables
ENV AKIRAEDGE_HTTP_PORT=9090
ENV AKIRAEDGE_HTTPS_PORT=9191
ENV AKIRAEDGE_IOT_CONN_STRING="HostName=AkiraHubProd.azure-devices.net;DeviceId=p100-sumato-003;SharedAccessKey=insert_share_key"

# Instalar paquetes de Python requeridos
RUN pip install --no-cache-dir pyyaml

# Asegurar que el runtime NVIDIA está bien configurado
RUN echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
RUN echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
RUN echo 'export NVIDIA_DRIVER_CAPABILITIES=compute,utility,video' >> ~/.bashrc

#Generando .engine int8 desde /app/_locals/Models
RUN echo '#!/bin/bash' > /app/generate_engines.sh && \
    echo 'MODEL_DIR="/app/_locals/Models"' >> /app/generate_engines.sh && \
    echo 'TRT_EXEC="/usr/src/tensorrt/bin/trtexec"' >> /app/generate_engines.sh && \
    echo 'echo "🔍 Buscando modelos ONNX en \$MODEL_DIR..."' >> /app/generate_engines.sh && \
    echo 'for ONNX_MODEL in "$MODEL_DIR"/*.onnx; do' >> /app/generate_engines.sh && \
    echo '  if [ -f "$ONNX_MODEL" ]; then' >> /app/generate_engines.sh && \
    echo '    ENGINE_MODEL="${ONNX_MODEL%.onnx}.engine"' >> /app/generate_engines.sh && \
    echo '    if [ -f "$ENGINE_MODEL" ]; then' >> /app/generate_engines.sh && \
    echo '      echo "🟡 Ya existe engine: $ENGINE_MODEL, se omite."' >> /app/generate_engines.sh && \
    echo '    else' >> /app/generate_engines.sh && \
    echo '      echo "⚙️ Generando engine para: $ONNX_MODEL → $ENGINE_MODEL"' >> /app/generate_engines.sh && \
    echo '      "$TRT_EXEC" --onnx="$ONNX_MODEL" --saveEngine="$ENGINE_MODEL" --fp16' >> /app/generate_engines.sh && \
    echo '      echo "✅ Engine generado: $ENGINE_MODEL"' >> /app/generate_engines.sh && \
    echo '    fi' >> /app/generate_engines.sh && \
    echo '  fi' >> /app/generate_engines.sh && \
    echo 'done' >> /app/generate_engines.sh && \
    chmod +x /app/generate_engines.sh

ENTRYPOINT ["/bin/bash", "-c", "/app/generate_engines.sh && exec dotnet P100X.dll"]

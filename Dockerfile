FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /content

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y \
    python3-pip \
    curl \
    gnupg \
    wget \
    htop \
    sudo \
    git \
    git-lfs \
    software-properties-common \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0

RUN add-apt-repository ppa:flexiondotorg/nvtop && \
    apt-get update -y && \
    apt-get install -y nvtop

RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g configurable-http-proxy

ENV PATH="/home/admin/.local/bin:${PATH}"

RUN pip3 install --upgrade pip

# Install Python packages individually to avoid conflicts and make debugging easier
RUN pip3 install jupyterhub && \
    pip3 install notebook && \
    pip3 install oauthenticator && \
    pip3 install pandas scipy matplotlib && \
    pip3 install jupyterlab && \
    pip3 install jupyterlab-git && \
    pip3 install ipywidgets && \
    pip3 install torch torchvision torchaudio && \
    pip3 install nbgrader

RUN jupyter lab build --dev-build=False --minimize=False

RUN useradd -m admin && echo admin:change.it! | chpasswd

# Create directories for nbgrader
RUN mkdir -p /home/admin/assignments/source/First \
    /home/admin/assignments/released \
    /home/admin/assignments/submitted \
    /home/admin/assignments/feedback \
    /home/admin/exchange/incoming \
    /home/admin/exchange/outgoing \
    /usr/local/share/nbgrader/exchange
    

# Adjust permissions
RUN chown -R admin:admin /content && \
    chmod -R 777 /content && \
    chown -R admin:admin /home && \
    chmod -R 777 /home && \
    chown -R admin:admin /home/admin/assignments && \
    chmod -R 777 /home/admin/assignments && \
    chown -R admin:admin /home/admin/exchange && \
    chmod -R 777 /home/admin/exchange && \
    chown -R admin:admin /usr/local/share/nbgrader/exchange && \
    chmod -R 777 /usr/local/share/nbgrader/exchange
    
# Clone a sample repository for Jupyter configuration (adjust as necessary)
RUN git clone https://github.com/camenduru/jupyter

COPY login.html /usr/local/lib/python3.10/dist-packages/jupyter_server/templates/login.html
COPY nbgrader_config.py /etc/jupyter/nbgrader_config.py

USER admin

EXPOSE 7860

CMD jupyter-lab --ip 0.0.0.0 --port 7860 --no-browser --allow-root --NotebookApp.token='huggingface' --NotebookApp.tornado_settings="{'headers': {'Content-Security-Policy': 'frame-ancestors *'}}" --NotebookApp.cookie_options="{'SameSite': 'None', 'Secure': True}" --NotebookApp.disable_check_xsrf=True --config=/etc/jupyter/nbgrader_config.py

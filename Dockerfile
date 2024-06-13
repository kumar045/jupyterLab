# Base image
FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04
ENV DEBIAN_FRONTEND noninteractive

# Set working directory
WORKDIR /content

# Install basic dependencies
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y python3-pip && pip3 install --upgrade pip

# Install additional dependencies
RUN apt-get install -y curl gnupg wget htop sudo git git-lfs software-properties-common build-essential libgl1

# Add nvtop repository and install nvtop
RUN add-apt-repository ppa:flexiondotorg/nvtop
RUN apt-get update -y
RUN apt-get install -y nvtop

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
RUN npm install
RUN npm install -g configurable-http-proxy

# Update PATH
ENV PATH="/home/admin/.local/bin:${PATH}"

# Install Python packages
RUN pip3 install jupyterhub && \
    pip3 install --upgrade notebook && \
    pip3 install oauthenticator && \
    pip3 install pandas scipy matplotlib && \
    pip3 install --upgrade jupyterlab jupyterlab-git && \
    pip3 install ipywidgets && \
    pip3 install torch torchvision torchaudio && \
    pip3 install nbgrader && \
    jupyter lab build

# Enable Jupyter nbextension for widgets
RUN jupyter nbextension enable --py widgetsnbextension

# Create user
RUN useradd admin && echo admin:change.it! | chpasswd && mkdir /home/admin && chown -R admin:admin /home/admin

# Clone a GitHub repository
RUN git clone https://github.com/camenduru/jupyter

# Copy custom login.html
COPY login.html /usr/local/lib/python3.10/dist-packages/jupyter_server/templates/login.html

# Create directories for nbgrader
RUN mkdir -p /home/admin/assignments/source \
    /home/admin/assignments/released \
    /home/admin/assignments/submitted \
    /home/admin/assignments/feedback \
    /home/admin/exchange/incoming \
    /home/admin/exchange/outgoing

# Adjust permissions
RUN chown -R admin:admin /content
RUN chmod -R 777 /content
RUN chown -R admin:admin /home
RUN chmod -R 777 /home
RUN chown -R admin:admin /home/admin/assignments
RUN chmod -R 777 /home/admin/assignments
RUN chown -R admin:admin /home/admin/exchange
RUN chmod -R 777 /home/admin/exchange

# Switch to user
USER admin

# Expose port
EXPOSE 7860

# Start Jupyter Lab
CMD jupyter-lab --ip 0.0.0.0 --port 7860 --no-browser --allow-root --NotebookApp.token='huggingface' --NotebookApp.tornado_settings="{'headers': {'Content-Security-Policy': 'frame-ancestors *'}}" --NotebookApp.cookie_options="{'SameSite': 'None', 'Secure': True}" --NotebookApp.disable_check_xsrf=True

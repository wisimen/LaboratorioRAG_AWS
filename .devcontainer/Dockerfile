FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Update package manager
RUN apt-get update && apt-get upgrade -y

# Install Git
RUN apt-get install -y git

# Install Python 3
RUN apt-get install -y python3 python3-venv python3-pip && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/python3 /usr/local/bin/python

# Install Docker CLI
RUN apt-get install -y docker.io

# Install Terraform
RUN apt-get install -y wget unzip curl && \
    wget https://releases.hashicorp.com/terraform/1.14.6/terraform_1.14.6_linux_amd64.zip && \
    unzip terraform_1.14.6_linux_amd64.zip -d /usr/local/bin && \
    rm terraform_1.14.6_linux_amd64.zip && \
    terraform version

# Clean up apt cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

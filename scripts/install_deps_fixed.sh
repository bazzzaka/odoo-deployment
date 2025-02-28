#!/bin/bash

# Script to install all dependencies needed for Odoo deployment
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Updating package lists...${NC}"
apt-get update || echo "Some repositories might have issues, continuing anyway"

echo -e "${BLUE}Installing basic utilities...${NC}"
apt-get install -y \
    git \
    curl \
    wget \
    gnupg \
    lsb-release \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    cron \
    ufw \
    vim

# Manually add deadsnakes PPA instead of using add-apt-repository
echo "deb http://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/deadsnakes-python.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776
apt-get update

# Install Python 3.12 from deadsnakes PPA
echo -e "${BLUE}Installing Python 3.12...${NC}"
apt-get install -y python3.12 python3.12-dev python3.12-venv

# Install pip for Python 3.12
curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.12 get-pip.py
rm get-pip.py

# Install PostgreSQL client for backups
echo -e "${BLUE}Installing PostgreSQL client...${NC}"
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql-client-15

# Additional libraries required by Odoo
echo -e "${BLUE}Installing additional libraries for Odoo...${NC}"
apt-get install -y \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    libldap2-dev \
    libsasl2-dev \
    libpq-dev \
    libtiff5-dev \
    libjpeg8-dev \
    libopenjp2-7-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    node-less \
    npm

# Install wkhtmltopdf with patched qt
echo -e "${BLUE}Installing wkhtmltopdf...${NC}"
wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb
apt-get install -y ./wkhtmltox_0.12.6.1-3.jammy_amd64.deb
rm wkhtmltox_0.12.6.1-3.jammy_amd64.deb

echo -e "${GREEN}All dependencies installed successfully!${NC}"

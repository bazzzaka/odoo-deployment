FROM ubuntu:noble
LABEL maintainer="Developer <your-email@example.com>"

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG en_US.UTF-8

# Install dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        python3.12-pip \
        python3-pip \
        python3-wheel \
        python3-setuptools \
        xz-utils \
        # System dependencies
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
        # Python packages dependencies
        python3-magic \
        python3-num2words \
        python3-odf \
        python3-pdfminer \
        python3-pypdf2 \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        # Other required packages
        git \
        sudo \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install wkhtmltopdf with patched Qt
RUN curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install latest PostgreSQL client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ noble-pgdg main' > /etc/apt/sources.list.d/pgdg.list && \
    curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-15 && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/apt/sources.list.d/pgdg.list

# Install rtlcss
RUN npm install -g rtlcss

# Setup virtual environment
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Odoo Python dependencies
RUN pip install --upgrade pip && \
    pip install wheel setuptools

# Install Odoo from source code
ENV ODOO_VERSION 18.0
ARG ODOO_RELEASE=20250218
ARG ODOO_SHA=122896192ed221711dd471d27b2bd2f934c2ec07

RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb && \
    echo "${ODOO_SHA} odoo.deb" | sha1sum -c - && \
    apt-get update && \
    apt-get -y install --no-install-recommends ./odoo.deb && \
    rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and odoo config
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create odoo user
RUN useradd -m -d /var/lib/odoo -U -s /bin/bash odoo && \
    mkdir -p /var/lib/odoo /mnt/extra-addons /etc/odoo && \
    chown -R odoo:odoo /var/lib/odoo /mnt/extra-addons /etc/odoo

# Mount volumes
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set default user
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
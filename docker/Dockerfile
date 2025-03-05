FROM ubuntu:noble

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Build arguments
ARG ODOO_VERSION=18.0
ARG ODOO_RELEASE=20250218
ARG ODOO_SHA=122896192ed221711dd471d27b2bd2f934c2ec07
ARG BUILD_ENV=prod

# Set environment variables
ENV LANG=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    ODOO_VERSION=${ODOO_VERSION} \
    PATH="/opt/venv/bin:$PATH"

# Install system dependencies
RUN apt-get update && \
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
        python3-pip \
        python3-wheel \
        python3-setuptools \
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
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
        # Additional utilities
        gettext-base \
        git \
        jq \
        moreutils \
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

# Setup virtual environment for Python 3.12
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install wheel setuptools

# Install Odoo
RUN if [ "$BUILD_ENV" = "dev" ]; then \
        echo "Setting up development environment"; \
        pip install debugpy ipython; \
        curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb; \
    else \
        curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb; \
        echo "${ODOO_SHA} odoo.deb" | sha1sum -c -; \
    fi && \
    apt-get update && \
    apt-get install -y --no-install-recommends ./odoo.deb && \
    rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and make it executable
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create directories and setup permissions
RUN mkdir -p /var/lib/odoo /mnt/extra-addons /etc/odoo /var/log/odoo && \
    useradd -ms /bin/bash -d /var/lib/odoo -G odoo odoo && \
    chown -R odoo:odoo /var/lib/odoo /mnt/extra-addons /etc/odoo /var/log/odoo

# Copy wait-for script
COPY docker/wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN chmod +x /usr/local/bin/wait-for-psql.py

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC=/etc/odoo/odoo.conf

# Set odoo user for security
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
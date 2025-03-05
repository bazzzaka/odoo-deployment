# Multi-stage build for Odoo 18.0 #
# - - - - - - - - - - - - - - - - #
#   Stage 1: Build dependencies   #
# - - - - - - - - - - - - - - - - #
FROM ubuntu:noble AS builder


# Set environment variables
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH \
    PYTHON_VERSION=3.12 \
    ODOO_VERSION=18.0 \
    ODOO_RELEASE=20250218 \
    ODOO_SHA=122896192ed221711dd471d27b2bd2f934c2ec07

# Install basic dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    python3-apt \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.12
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3.12-lib2to3 \
    python3.12-full \
    build-essential \
    && python3.12 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/*

# Install Odoo system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-cjk \
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
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install wkhtmltopdf
RUN curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install PostgreSQL client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ noble-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client-15 \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss required by Odoo
RUN npm install -g rtlcss

# Download and install Odoo
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
    && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
    && apt-get update \
    && apt-get -y install --no-install-recommends ./odoo.deb \
    && rm -rf /var/lib/apt/lists/* odoo.deb


# - - - - - - - - - - - - - - - - #
#      Stage 2: Final image       #
# - - - - - - - - - - - - - - - - #
FROM ubuntu:noble

# Set environment variables
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
    
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH \
    PYTHON_VERSION=3.12 \
    ODOO_VERSION=18.0

# Copy from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/bin/wkhtmlto* /usr/bin/
COPY --from=builder /usr/bin/odoo /usr/bin/odoo
COPY --from=builder /usr/lib/python3/dist-packages/ /usr/lib/python3/dist-packages/
COPY --from=builder /usr/local/bin/rtlcss /usr/local/bin/rtlcss
COPY --from=builder /usr/lib/postgresql /usr/lib/postgresql
COPY --from=builder /usr/bin/psql /usr/bin/psql
COPY --from=builder /usr/bin/pg_dump /usr/bin/pg_dump
COPY --from=builder /usr/bin/pg_restore /usr/bin/pg_restore

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    fonts-noto-cjk \
    nodejs \
    npm \
    libxml2 \
    libxslt1.1 \
    libjpeg8 \
    # libldap2-2 \
    libsasl2-2 \
    libpq5 \
    libtiff6 \
    libopenjp2-7 \
    zlib1g \
    libfreetype6 \
    liblcms2-2 \
    # libwebp6 \
    libharfbuzz0b \
    libfribidi0 \
    libxcb1 \
    python3.12 \
    python3.12-lib2to3 \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

# Set up Odoo directories and user
RUN useradd -m -d /var/lib/odoo -U -s /bin/bash odoo && \
    mkdir -p /var/lib/odoo /mnt/extra-addons /etc/odoo /var/log/odoo && \
    chown -R odoo:odoo /var/lib/odoo /mnt/extra-addons /etc/odoo /var/log/odoo

# Copy entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create volumes
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set default user
USER odoo

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8069/web/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
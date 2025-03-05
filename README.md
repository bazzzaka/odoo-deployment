# Odoo 18 Deployment Solution

This repository provides a comprehensive, automated solution for deploying Odoo 18 in both development and production environments using Docker. The deployment is built with security, scalability, and ease of maintenance in mind.

## Features

- **Docker-based Deployment**: Isolated, reproducible environments for both development and production
- **Fully Automated Setup**: Complete setup with a single command
- **Environment-aware Configuration**: Different settings for development and production
- **Security Best Practices**: Follows industry standards for secure deployment
- **Database Management**: Automated backups with retention policy
- **Performance Optimization**: Configurable for different server sizes
- **Python 3.12 Support**: Built on the latest Python for Odoo 18
- **Easy Updates**: Simple commands for updating Odoo
- **Custom Addons Support**: Simple integration of custom modules

## Requirements

- Docker and Docker Compose v2+
- 2GB RAM minimum (4GB recommended for production)
- 20GB disk space minimum

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/odoo-deploy.git
   cd odoo-deploy
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Run setup and start Odoo**:
   ```bash
   # For initial setup
   make setup
   
   # For development environment
   make dev
   
   # For production environment
   make prod
   ```

   The system will automatically initialize the database with the modules specified in the `INIT_MODULES` environment variable during the first run.

4. **Access Odoo**:
   - Development: http://localhost:8069
   - Production: http://your-domain

## Directory Structure

```
odoo-deploy/
├── addons/              # Custom Odoo modules
├── config/              # Configuration templates
│   ├── odoo.conf.template
│   └── nginx.conf.template
├── data/                # Persistent data
│   ├── db/              # PostgreSQL data
│   ├── odoo/            # Odoo filestore
│   └── backups/         # Database backups
├── docker/              # Docker configuration
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── entrypoint.sh
├── logs/                # Log files
├── scripts/             # Utility scripts
│   ├── backup.sh
│   └── restore.sh
├── .env.example         # Environment variables template
├── Makefile             # Automation commands
└── README.md            # Documentation
```

## Configuration

The deployment is configured through environment variables in the `.env` file:

### Basic Configuration
- `DOMAIN`: Your domain name (default: localhost)
- `POSTGRES_USER`: Database username (default: odoo)
- `POSTGRES_PASSWORD`: Database password
- `POSTGRES_DB`: Database name (default: odoo)
- `ADMIN_PASSWORD`: Odoo master password
- `INIT_MODULES`: Comma-separated list of modules to install at first run (default: base,web,mail,contacts,crm,sale_management,purchase,account,stock)

### Performance Configuration
- `WORKERS`: Number of Odoo worker processes (default: 2)
- `CRON_WORKERS`: Number of cron worker processes (default: 1)
- `MEMORY_SOFT`: Soft memory limit for workers (default: 2GB)
- `MEMORY_HARD`: Hard memory limit for workers (default: 2.5GB)

### Volume Paths
- `ODOO_DATA_PATH`: Path for Odoo data files
- `DB_VOLUME_PATH`: Path for PostgreSQL data
- `ODOO_ADDONS_PATH`: Path for custom Odoo modules

## Available Commands

Use the Makefile to manage your Odoo deployment:

- **Setup and Environment**:
  - `make setup`: Initial setup of directories and configurations
  - `make dev`: Start development environment
  - `make prod`: Start production environment

- **Service Management**:
  - `make start`: Start all services
  - `make stop`: Stop all services
  - `make restart`: Restart all services
  - `make status`: Show service status
  - `make logs`: View logs

- **Maintenance**:
  - `make backup`: Create database backup
  - `make restore BACKUP_FILE=path/to/backup`: Restore database
  - `make update`: Update Odoo to latest version
  - `make clean`: Remove containers and volumes
  - `make shell`: Open shell in Odoo container
  - `make install-modules MODULES=module1,module2`: Install or update specific Odoo modules

## Module Management

### Initial Module Installation

During the first startup, the system automatically installs modules specified in the `INIT_MODULES` environment variable. By default, this includes:

```
base,web,mail,contacts,crm,sale_management,purchase,account,stock
```

You can customize this list in your `.env` file before the first run.

### Custom Modules

Place your custom Odoo modules in the `addons/` directory. They will be automatically available in Odoo.

### Installing Additional Modules

To install or update modules after the initial setup:

```bash
make install-modules MODULES=module1,module2,module3
```

This command will:
1. Connect to the running Odoo container
2. Install or update the specified modules
3. Restart the necessary services

### Module Development

For module development, use the development environment:

```bash
make dev
```

This enables Odoo's development mode with:
- Auto-reload for Python changes
- Debug tools and error reporting
- Asset generation in development mode

## Backup and Restore

The system is configured for automated daily backups. Backups are stored in the `data/backups/` directory.

**Manual backup**:
```bash
make backup
```

**Restore from backup**:
```bash
make restore BACKUP_FILE=data/backups/odoo_20250305_120000.dump.gz
```

## Security Recommendations

1. **Change default passwords** in the `.env` file
2. **Enable SSL/TLS** by uncommenting the relevant sections in the Nginx configuration
3. **Restrict database access** by setting `LIST_DB=False` in `.env`
4. **Configure a firewall** to restrict access to essential ports
5. **Regular updates** for security patches

## Troubleshooting

### Common Issues

1. **Database connection errors**:
   - Check PostgreSQL container is running: `make status`
   - Verify database credentials in `.env`
   - Ensure volume permissions are correct

2. **Odoo not starting**:
   - Check logs: `make logs`
   - Ensure database is available
   - Verify configuration in `.env`

3. **Performance issues**:
   - Adjust worker count in `.env` based on your server specs
   - Increase memory limits for larger deployments
   - Consider separate database server for high-load scenarios

## Maintenance

### Updates

To update Odoo to the latest version:
```bash
make update
```

### Monitoring

Regularly check:
- Disk space usage
- Memory usage
- Database backup integrity
- Log files for errors

## License

This deployment solution is licensed under the MIT License - see the LICENSE file for details.
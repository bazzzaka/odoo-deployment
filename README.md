# Odoo 18 Deployment Solution

This repository provides a comprehensive, automated solution for deploying Odoo 18 on a clean Ubuntu 20.04 VPS. The deployment is done using Docker and includes all necessary components for a production-ready setup.

## Features

- **Fully Automated Setup**: Deploy Odoo with just a few commands
- **Docker-based**: All components run in Docker containers for isolation and ease of management
- **Latest Technologies**: Odoo 18 with Python 3.12 and PostgreSQL 15
- **Secure Configuration**: Following best practices for secure deployment
- **Automatic Backups**: Daily database backups with retention policy
- **Nginx Integration**: Configured as a reverse proxy with proper headers
- **Custom Addons Support**: Easily add and manage custom Odoo modules
- **Comprehensive Documentation**: Clear instructions for all operations

## Requirements

- Ubuntu 20.04 VPS with root access
- At least 2GB RAM (4GB recommended)
- At least 20GB storage

## Quick Start

1. **Clone the repository**:
   ```
   git clone https://github.com/yourusername/odoo-deploy.git
   cd odoo-deploy
   ```

2. **Configure deployment**:
   ```
   cp .env.example .env
   # Edit .env with your desired settings
   nano .env
   ```

3. **Run the setup**:
   ```
   make setup
   ```

4. **Access Odoo**:
   Once the setup is complete, access Odoo at http://your-server-ip
   
## Configuration Options

Edit the `.env` file to customize your deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| DOMAIN | Your domain name | localhost |
| POSTGRES_USER | PostgreSQL username | odoo |
| POSTGRES_PASSWORD | PostgreSQL password | odoo_db_password |
| POSTGRES_DB | PostgreSQL database name | odoo |
| ADMIN_PASSWORD | Odoo master password | admin_password |
| BACKUP_RETENTION_DAYS | Days to keep backups | 30 |

## Directory Structure

- `scripts/`: Setup and maintenance scripts
- `docker/`: Docker configuration files
- `config/`: Configuration templates 
- `data/`: Persistent data storage
  - `db/`: PostgreSQL data
  - `odoo/`: Odoo data directory
  - `backups/`: Database backups
- `addons/`: Custom Odoo modules
- `logs/`: Log files

## Available Commands

Use the `make` command to manage your Odoo deployment:

- `make help`: Show available commands
- `make setup`: Initial setup of all components
- `make start`: Start all services
- `make stop`: Stop all services
- `make restart`: Restart all services
- `make status`: Show status of running services
- `make logs`: View logs from all services
- `make shell`: Open a shell in the Odoo container
- `make backup`: Create a database backup
- `make restore BACKUP_FILE=<path>`: Restore database from backup
- `make update`: Update Odoo and rebuild the container
- `make clean`: Remove all containers and volumes

## Custom Modules

To add custom Odoo modules, place them in the `addons/` directory. They will be automatically available in Odoo.

## Backup and Restore

Automatic daily backups are configured. Backups are stored in the `data/backups/` directory.

To manually create a backup:
```
make backup
```

To restore from a backup:
```
make restore BACKUP_FILE=data/backups/odoo-20250228_120000.sql.gz
```

## Security Recommendations

1. Change all default passwords in the `.env` file
2. Enable and configure SSL/TLS for production use
3. Configure a firewall to restrict access to essential ports
4. Regularly update all components
5. Monitor logs for suspicious activity

## Troubleshooting

### Common Issues

1. **Database connection errors**:
   - Check PostgreSQL container is running
   - Verify database credentials in `.env`
   - Ensure database volume permissions are correct

2. **Odoo not starting**:
   - Check logs with `make logs`
   - Ensure database is available
   - Verify configuration in `config/odoo.conf`

3. **Nginx errors**:
   - Check Nginx configuration
   - Verify domain settings
   - Ensure ports are not in use by other services

## Maintenance

### Regular Updates

To update Odoo to the latest version:
```
make update
```

### Monitoring

Monitor disk space, memory usage, and CPU utilization regularly.

## License

This deployment solution is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Odoo](https://www.odoo.com/) - The most awesome business software ever
- [Docker](https://www.docker.com/) - Container virtualization
- [PostgreSQL](https://www.postgresql.org/) - Advanced open source database
- [Nginx](https://nginx.org/) - High-performance HTTP server

## Structure
```
odoo-deploy/
├── scripts/
│   ├── setup.sh                # Main setup script
│   ├── install_deps.sh         # Install dependencies
│   ├── setup_docker.sh         # Setup Docker and docker-compose
│   ├── setup_nginx.sh          # Setup Nginx
│   └── setup_backup.sh         # Setup database backup
├── docker/
│   ├── Dockerfile              # Odoo Docker image
│   ├── docker-compose.yml      # Composition of services
│   └── entrypoint.sh           # Container entrypoint
├── config/
│   ├── odoo.conf.template      # Odoo config template
│   └── nginx.conf.template     # Nginx config template
├── data/
│   ├── db/                     # PostgreSQL data
│   ├── odoo/                   # Odoo data directory
│   └── backups/                # Database backups
├── addons/
│   └── .gitkeep                # For custom modules
├── .env.example                # Environment variables template
├── Makefile                    # Automation commands
└── README.md                   # Documentation
```
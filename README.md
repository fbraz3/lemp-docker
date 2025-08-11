[![Build Base Images](https://github.com/fbraz3/lemp-docker/actions/workflows/base-images.yml/badge.svg)](https://github.com/fbraz3/lemp-docker/actions/workflows/base-images.yml)
[![Build Phalcon Images](https://github.com/fbraz3/lemp-docker/actions/workflows/phalcon-images.yml/badge.svg)](https://github.com/fbraz3/lemp-docker/actions/workflows/phalcon-images.yml)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/fbraz3/lemp-docker)

# Braz LEMP Docker Image

This repository provides Docker images for LNMP stack (`L`inux, `N`ginx, `M`ariaDB, and `P`HP-FPM), commonly referred to as LEMP.

It is designed to simplify the deployment of PHP applications with a robust and modern environment, offering both **Development** and **Production** versions to meet different deployment needs.

The images are built on top of other modular images from the `fbraz3` ecosystem, ensuring flexibility, maintainability, and ease of use.

💡 For a complete list of available images, please visit the [PHP System Docs](https://github.com/fbraz3/php-system-docs) page.

## Table of Contents

- [Braz LEMP Docker Image](#braz-lemp-docker-image)
  - [Image Versions](#image-versions)
  - [Tags](#tags)
  - [Flavors](#flavors)
  - [How to Use](#how-to-use)
    - [Development Version](#development-version)
    - [Production Version](#production-version)
  - [Custom SQL Scripts](#custom-sql-scripts)
  - [Security Considerations](#security-considerations)
  - [Environment Variables](#environment-variables)
  - [Manage PHP Directives via Environment Variables](#manage-php-directives-via-environment-variables)
  - [Cronjobs](#cronjobs)
  - [Sending Mails](#sending-mails)
  - [Contribution](#contribution)
  - [Donation](#donation)
  - [License](#license)

## Image Versions

This project provides two distinct versions for different use cases:

### Development Version (`-dev` suffix)
- **Purpose**: Designed for local development and testing
- **Features**:
  - MariaDB with **no root password** (empty password)
  - phpMyAdmin accessible at `/pma/` endpoint
  - Relaxed security settings for ease of development
  - Direct database access without authentication

### Production Version (no suffix)
- **Purpose**: Optimized for production environments
- **Features**:
  - MariaDB with **mandatory root password** configuration
  - **Enforced password security**: Container will fail to start if using default password
  - **Custom SQL scripts support**: Execute custom SQL files at startup
  - **No phpMyAdmin** included for security
  - Secure database configuration
  - Root password configurable via environment variables
  - Anonymous users and test databases removed
  - Enhanced security settings

## Tags

The image follows a consistent tagging scheme:

### Base Images (Vanilla LNMP Stack)
- **Production**: `fbraz3/lnmp:{php_version}` (e.g., `8.2`, `8.3`, `8.4`)
- **Development**: `fbraz3/lnmp:{php_version}-dev` (e.g., `8.2-dev`, `8.3-dev`)

### Phalcon Images (With Phalcon Framework)
- **Production**: `fbraz3/lnmp:{php_version}-phalcon` (e.g., `8.2-phalcon`, `8.3-phalcon`)
- **Development**: `fbraz3/lnmp:{php_version}-phalcon-dev` (e.g., `8.2-phalcon-dev`)

### Latest Tags
- `fbraz3/lnmp:latest` - Latest production version
- `fbraz3/lnmp:latest-dev` - Latest development version  
- `fbraz3/lnmp:latest-phalcon` - Latest Phalcon production version
- `fbraz3/lnmp:latest-phalcon-dev` - Latest Phalcon development version

### Architecture Support
- All images support both `amd64` and `arm64` architectures
- LEMP variants are also available as `fbraz3/lemp:{tag}`

## Flavors

This image supports multiple flavors to cater to different use cases:

- **Vanilla**: A standard LNMP stack with no additional frameworks
- **Phalcon**: Includes the Phalcon PHP framework pre-installed

## How to Use

### Development Version

Perfect for local development with easy database access and debugging tools.

```yaml
# docker-compose.yml
services:
  web:
    image: fbraz3/lnmp:8.4-dev  # or fbraz3/lnmp:8.4-phalcon-dev
    volumes:
      - ./:/app/public/
    ports:
      - "127.0.0.1:80:80"
      - "127.0.0.1:3306:3306"
```

**Access Points:**
- Application: `http://localhost/`
- phpMyAdmin: `http://localhost/pma/`
- Database: `localhost:3306` (user: `root`, password: *empty*)

### Production Version

Secure configuration suitable for production environments.

```yaml
# docker-compose.yml
services:
  web:
    image: fbraz3/lnmp:8.4  # or fbraz3/lnmp:8.4-phalcon
    environment:
      - MYSQL_ROOT_PASSWORD=your_secure_password_here
    volumes:
      - ./:/app/public/
      - mysql_data:/var/lib/mysql
    ports:
      - "80:80"
    restart: unless-stopped

volumes:
  mysql_data:
```

**Access Points:**
- Application: `http://your-domain/`
- Database: Internal access only (user: `root`, password: set via environment)

**Important**: Always set a strong `MYSQL_ROOT_PASSWORD` in production!

## Custom SQL Scripts

The production images support executing custom SQL scripts during container startup. This feature allows you to initialize your database with custom schema, data, or configuration.

### How to Use Custom SQL Scripts

1. **Create your SQL files**: Place your `.sql` files in a directory on your host system
2. **Mount the directory**: Bind-mount your SQL scripts directory to `/sql-scripts` in the container
3. **Automatic execution**: All `.sql` files in the directory will be executed automatically during first startup

### Example Usage

```yaml
# docker-compose.yml
services:
  web:
    image: fbraz3/lnmp:8.4
    environment:
      - MYSQL_ROOT_PASSWORD=your_secure_password_here
    volumes:
      - ./:/app/public/
      - ./sql-scripts:/sql-scripts  # Mount your custom SQL scripts
      - mysql_data:/var/lib/mysql
    ports:
      - "80:80"
    restart: unless-stopped
```

```bash
# Directory structure example
project/
├── sql-scripts/
│   ├── 01-create-users.sql
│   ├── 02-create-tables.sql
│   └── 03-insert-data.sql
└── docker-compose.yml
```

### Important Notes

- SQL scripts are executed **only on first startup** (when database is initialized)
- Scripts are executed in **alphabetical order**
- Use numeric prefixes (e.g., `01-`, `02-`) to control execution order
- All scripts run with **root privileges**
- This feature is **only available in production images** for security reasons

## Security Considerations

### Development Version
- ⚠️ **Never use development images in production**
- Database has no root password
- phpMyAdmin is publicly accessible
- Intended for local development only

### Production Version
- ✅ Secure by default
- Mandatory root password
- No phpMyAdmin interface
- Anonymous users removed
- Test databases removed
- Database binds to localhost only

## Environment Variables

### Production Images

| Variable              | Required | Default               | Description               |
|-----------------------|----------|-----------------------|---------------------------|
| `MYSQL_ROOT_PASSWORD` | Yes      | `defaultrootpassword` | Root password for MariaDB |

**Example:**
```bash
docker run -e MYSQL_ROOT_PASSWORD=mySecurePassword123 fbraz3/lnmp:8.4
```

### Development Images

Development images don't require any specific environment variables and work out of the box.

## Manage PHP Directives via Environment Variables

This image allows you to customize PHP directives using environment variables. 

For detailed instructions, refer to the [php-fpm-docker documentation](https://github.com/fbraz3/php-fpm-docker#manage-php-directives-via-environment-variables).

## Cronjobs

Cronjobs can be configured by binding a file to `/cronfile` in the container. The system will automatically install and execute the jobs.

For more details, see the [php-fpm-docker documentation](https://github.com/fbraz3/php-fpm-docker#cronjobs).

## Sending Mails

To enable email sending, this image relies on the configuration provided in the `php-base-docker` project.

Follow the instructions in the [php-base-docker documentation](https://github.com/fbraz3/php-base-docker#sending-mails) to set up email functionality.

## Contribution

Contributions are welcome! Feel free to open issues or submit pull requests to improve the project.

Please visit the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines on how to contribute to this project.

#### Useful links
- [How to create a pull request](https://docs.github.com/pt/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)
- [How to report an issue](https://docs.github.com/pt/issues/tracking-your-work-with-issues/creating-an-issue)

## Donation

I spend a lot of time and effort maintaining this project. If you find it useful, consider supporting me with a donation:
- [GitHub Sponsor](https://github.com/sponsors/fbraz3)
- [Patreon](https://www.patreon.com/fbraz3)

## License

This project is licensed under the [Apache License 2.0](LICENSE), so you can use it for personal and commercial projects. However, please note that the images are provided "as is" without any warranty or guarantee of any kind. Use them at your own risk.
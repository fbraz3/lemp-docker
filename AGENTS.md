# Project: Braz LEMP Docker Image

This file contains instructions and behavioral guidelines for artificial intelligence agents working in this repository.

## About the Project
This repository provides Docker images for the LNMP stack (Linux, Nginx, MariaDB, and PHP-FPM). 
The focus is on providing environments for both **Development** (`-dev`) and **Production** (no suffix).

## Development Guidelines

### 1. Images and Versions
- Maintain a clear distinction between development (`-dev`) and production images.
- Production images must be secure by default:
  - Mandatory root password for MariaDB.
  - phpMyAdmin removed.
  - No anonymous users or test databases.
- Development images should facilitate local use (no password access, phpMyAdmin active).

### 2. Dockerfile Modifications
- Follow Docker best practices.
- Optimize image size by grouping `RUN` commands and clearing caches.
- The images are based on the `fbraz3` ecosystem. Maintain compatibility with these images.

### 3. Scripts and Automation
- The project supports executing custom SQL scripts during startup in production images. Ensure that changes do not break this functionality.
- Environment variables such as `MYSQL_ROOT_PASSWORD`, `MYSQL_APP_DATABASE`, `MYSQL_APP_USER`, and `MYSQL_APP_USER_PASSWD` are supported and must be considered in any change affecting the entrypoint or database configuration.

### 4. Code Best Practices
- Bash/shell code must be compatible with the Alpine or Debian images used.
- Keep the `README.md` file updated if there are significant changes to features, environment variables, or usage instructions.

### 5. Documentation
- Behavioral changes in the images must be properly recorded.
- Follow the instructions in `CONTRIBUTING.md` for general standards.

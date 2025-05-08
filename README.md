# Braz LEMP Docker Image

This repository provides a Docker image for an LNMP stack (`L`inux, `N`ginx, `M`ySQL, and `P`HP-FPM), commonly referred to as LEMP.  

It is designed to simplify the deployment of PHP applications with a robust and modern environment. 

The image is built on top of other modular images from the `fbraz3` ecosystem, ensuring flexibility, maintainability, and ease of use.

For more technical information, please visit our  [DeepWiki Page](https://deepwiki.com/fbraz3/lemp-docker) (AI generated).

## Build Status

[![Build Base Images](https://github.com/fbraz3/lemp-docker/actions/workflows/base-images.yml/badge.svg)](https://github.com/fbraz3/lemp-docker/actions/workflows/base-images.yml) [![Build Phalcon Images](https://github.com/fbraz3/lemp-docker/actions/workflows/phalcon-images.yml/badge.svg)](https://github.com/fbraz3/lemp-docker/actions/workflows/phalcon-images.yml)

## Tags

The image follows a consistent tagging scheme:

- `PHP Version Tags`: Each tag corresponds to a specific PHP version (e.g., `8.2`, `8.3`).
- `Flavors`: Tags may include additional flavor identifiers (e.g., `-phalcon`).
- `Multi-Arch Support`: Images are available for both `amd64` and `arm64` architectures.
- `Latest Tag`: The `latest` tag always points to the most recent stable PHP version.

## Flavors

This image supports multiple flavors to cater to different use cases:

- `Vanilla`: A standard LNMP stack with no additional frameworks.
- `Phalcon`: Includes the Phalcon PHP framework pre-installed.

## How to Use

To use this image, create a `docker-compose.yml` file in your application root directory:

```yaml
services:
web:
image: fbraz3/lnmp
volumes:
- ./:/app/public/
ports:
- "127.0.0.1:80:80"
- "127.0.0.1:3306:3306"
```

Run the following command to start the container:

```bash
docker-compose up -d
```

Your application will be accessible at `http://localhost/`, and phpMyAdmin will be available at `http://localhost/pma/`.

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
# php-contenv (TODO for v2)

**PHP Container Environment for Development**

`php-contenv` provides pre-configured Docker environments tailored for PHP development, particularly for framework Laravel. The goal is to offer a simple, consistent, and ready-to-go development environment that can be easily integrated into any project without requiring local installations of PHP, Composer, or Node.js.

By using `php-contenv` as a Git submodule, you can keep your project's Docker configuration separate and easily update it across multiple projects.

## Purpose

The primary purpose of `php-contenv` is to:

* Provide Dockerfile and configurations for different PHP versions and web servers (Apache, Nginx).
* Include common development tools and extensions (Composer, Node.js via NVM, Xdebug, image processing libraries, database clients).
* Enable live code and configuration updates via Docker volumes without rebuilding images.
* Offer a simple setup process to integrate the environment into your project.
* Allow developers to run their projects in a production-like environment locally.


## Getting Started

To integrate `php-contenv` into your project:

1.  **Add as a Git Submodule:**
```bash
git submodule add https://github.com/techgonia-devjio/php-contenv .docker
git submodule update --init --recursive
```

2.  **Run the Setup Script:**
    Navigate to your project's root directory and run the setup script:
    * **Linux/macOS:** (might require some permission)
        ```bash
        ./.docker/docky setup
        ```
    * **Windows:**
        Use git bash or similar tool which can run bash script(or WSL).
    The script will guide you through selecting your desired PHP version and web server, set up the necessary `docker-compose.yml` and `.env` files, and create required directories, if necessary.

3.  **Start the Environment:**
    Once the setup is complete, start your Docker environment:
    ```bash
    docker compose up
    ```

4.  **Access Your Application:**
    Your application should now be accessible via the port configured in your `.env` file (defaulting to 8081 if using the example `docker-compose.yml`).

## Usage

* **Running Artisan Commands:**
    ```bash
    docker exec laravel.app php artisan <command>
    ```
* **Running Composer Commands:**
    ```bash
    docker exec laravel.app composer <command>
    ```
* **Or just Bash it:**
    ```bash
    docker exec laravel.app bash
    ```
 
If the app name couldn't be found, you can run `docker container ls` and copy the container id or name and run `docker exec -it container_name_or_id bash`.


### Config flags



## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

This project is open-source software licensed under the [MIT License](LICENSE).

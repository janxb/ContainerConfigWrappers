# ContainerConfigWrappers

**IMPORTANT:** This script collection is deprecated and all components are not in active use anymore. Use at your own risk! Replacements: [NginxProxyManager](https://github.com/NginxProxyManager/nginx-proxy-manager) and [KeyHelp web hosting panel](https://www.keyhelp.de/).

---

The scripts found in this repository are used on multiple machines and virtualized containers, for providing proxy and hosting services. Feel free to check them out or provide feedback if you can think of any improvements.

## webhosting
Scripts in this folder generate config for nginx and php-fpm in the selected version. You only have to edit the `generate.sh` file, it already contains an example configuration.

A new php-fpm pool is generated for each defined vhost, so that your config does not overlap. Additional PHP extensions are defined only once and installed automatically.

## webproxy
Scripts in this folder generate config for nginx as a reverse proxy. You can use this for proxying connections from your edge servers to internal machines or virtualized containers.

Defining proxy paths is done in file `generate.sh`, some example paths are already included. You have the possibility to define http proxy, https proxy, https with dedicated certificate and some more. Feel free to check out the functions in `_source.sh`to see everything you can do.

Hint: The proxy configuration already includes the IP ranges used by Cloudflare, which means that the Cloudflare proxy IP is automatically replaced with the real client IP address.

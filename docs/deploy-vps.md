# Deploy Stewart Biology on a VPS with Podman

This site is built from Hugo source inside the container image and served as static files by an unprivileged Nginx container. The VPS reverse proxy should handle public HTTPS traffic and forward requests for `https://stewartbiology.com` to `http://127.0.0.1:8088`.

## First-time setup

Install Podman on the VPS, then clone the repository with its theme submodule:

```sh
git clone --recurse-submodules <repo-url> stewartbiology-website
cd stewartbiology-website
```

Build the image from the repository root:

```sh
podman build -t localhost/stewartbiology:latest .
```

Install the rootless Quadlet service for the deploy user:

```sh
mkdir -p ~/.config/containers/systemd
cp deploy/systemd/stewartbiology.container ~/.config/containers/systemd/stewartbiology.container
systemctl --user daemon-reload
systemctl --user enable --now stewartbiology.service
```

Enable lingering once so the user service starts after reboot, even before the deploy user logs in:

```sh
sudo loginctl enable-linger <deploy-user>
```

Configure the existing reverse proxy to send `stewartbiology.com` traffic to:

```text
http://127.0.0.1:8088
```

Keep TLS certificates, HTTP-to-HTTPS redirects, and public ports in the reverse proxy. The site container only serves plain HTTP on localhost.

## Update an existing deployment

From the repository checkout on the VPS:

```sh
git pull --ff-only
git submodule update --init --recursive
podman build -t localhost/stewartbiology:latest .
systemctl --user restart stewartbiology.service
```

## Validate the deployment

Check that the service is running:

```sh
systemctl --user status stewartbiology.service
podman ps
```

Check the local container endpoint:

```sh
curl -I http://127.0.0.1:8088/
curl -I http://127.0.0.1:8088/presentations/
curl -I http://127.0.0.1:8088/projects/
curl -I http://127.0.0.1:8088/projects/afff-alternatives/
curl -I http://127.0.0.1:8088/publications/
curl -I http://127.0.0.1:8088/robots.txt
curl -I http://127.0.0.1:8088/sitemap.xml
```

Check the public HTTPS endpoint after the reverse proxy is configured:

```sh
curl -I https://stewartbiology.com/
```

## Notes

- The committed `public/` directory is not used by the image build. Hugo generates fresh static files during `podman build`.
- The `themes/ananke` submodule must be initialized before building.
- The site `baseURL` is already set to `https://stewartbiology.com/` in `hugo.toml`.
- Hugo does not need to be installed directly on the VPS host; the builder image provides it.

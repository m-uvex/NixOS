{ ... }:

let
  composeContent = ''
    name: infra

    services:
      nginx:
        image: nginx:alpine
        container_name: nginx
        restart: unless-stopped
        ports:
          - "80:80"
          - "443:443"
        volumes:
          - /srv/infra/nginx:/etc/nginx/conf.d
          - /srv/infra/nginx/certs:/etc/nginx/certs
        extra_hosts:
          - "host.docker.internal:host-gateway"

      authelia:
        image: authelia/authelia:latest
        container_name: authelia
        restart: unless-stopped
        volumes:
          - /srv/infra/authelia:/config
        environment:
          - TZ=Europe/Istanbul
        depends_on:
          - redis
          - lldap

      lldap:
        image: lldap/lldap:latest-alpine
        container_name: lldap
        restart: unless-stopped
        ports:
          - "17170:17170"
          - "3890:3890"
        volumes:
          - /srv/infra/lldap:/data
        environment:
          - TZ=Europe/Istanbul
          - LLDAP_HTTP_PORT=17170
          - LLDAP_LDAP_PORT=3890

      redis:
        image: redis:alpine
        container_name: redis
        restart: unless-stopped
        volumes:
          - /srv/infra/redis:/data

      pihole:
        image: pihole/pihole:latest
        container_name: pihole
        restart: unless-stopped
        ports:
          - "53:53/tcp"
          - "53:53/udp"
          - "8081:80"
        volumes:
          - /srv/infra/pihole/etc-pihole:/etc/pihole
          - /srv/infra/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
        environment:
          - TZ=Europe/Istanbul
  '';
in
{
  environment.etc."stacks/infra/compose.yaml".text = composeContent;

  systemd.tmpfiles.rules = [
    "d /srv/stacks/infra 0755 root root -"
    "C+ /srv/stacks/infra/compose.yaml 0644 root root - /etc/stacks/infra/compose.yaml"
  ];
}

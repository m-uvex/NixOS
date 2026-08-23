{ ... }:

{
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  # Placeholder: add declarative containers when needed
  virtualisation.oci-containers.containers = {};
}

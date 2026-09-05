{ pkgs, ... }:

{
  users.users.m_uvex = {
    isNormalUser = true;
    description = "Musa Murad";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "storage" ];
    hashedPassword = "$6$tFhMrTUbXvCtUK2O$VyQs7xSfEOGBPZlb8UZPOZEA6tr2ZR5ixEvbO1wwhN6iGb3kmgvTCVDbGmAx1u33FSomD4wWIQFw.ly3yGj141";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK+Wl/P/x5uB5y442bA5rFw3e1k6FpY2FjYp9/m_uvex m_uvex"
    ];
  };
}

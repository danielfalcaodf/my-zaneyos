{config, pkgs, ...}: {

  environment.systemPackages = with pkgs; [
  ];

  # Add host specific flatpaks here
  services = {
    flatpak = {
      packages = [
      ];
    };
  };

  # For power mangement on laptops 

  services.auto-cpufreq.enable = false;
  services.auto-cpufreq.settings = {
    battery = {
       governor = "powersave";
       turbo = "never";
    };
    charger = {
       governor = "performance";
       turbo = "auto";
    };
  };



}

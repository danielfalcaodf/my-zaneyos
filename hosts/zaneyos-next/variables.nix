_: {
  # Welcome to your ZaneyOS configuration!
  # This block is where you can customize your NixOS experience.
  #
  # For a comprehensive list of all available options, their descriptions,
  # and default values, please refer to the following file:
  # ../../modules/options.nix
  #
  # You can override any of those options here. Most settings are optional
  # and can be removed to use the project defaults.
  zaneyos = {
    # Git Configuration
    gitUsername = "Don Williams";
    gitEmail = "don.e.williams@gmail.com";

    # does not have to be the same as the directory name, but
    # would be common
    hostName = "zaneyos-next";

    gpuProfile = "vm";

    # Set Display Manager
    # `tui` for Text login
    # `sddm` for graphical GUI (default)
    # SDDM background is set with stylixImage
    displayManager = "sddm";

    # Emable/disable bundled applications
    tmuxEnable = true;
    alacrittyEnable = true;
    weztermEnable = true;
    ghosttyEnable = true;
    vscodeEnable = true;
    antigravityEnable = true; # Google port of vscodium
    # Note: This is evil-helix with VIM keybindings by default
    helixEnable = true;
    #To install: Enable here, zcli rebuild, then run zcli doom install
    doomEmacsEnable = true;

    # Bar/Shell Settings
    # Choose between noctalia or waybar
    barChoice = "noctalia";

    # Waybar Settings (used when barChoice = "waybar")
    clock24h = false;

    # Program Options
    # Set Default Browser (google-chrome-stable for google-chrome)
    # This does NOT install your browser
    # You need to install it by adding it to the `packages.nix`
    # or as a flatpak
    browser = "brave";

    # Default applications for this host (written to ~/.config/mimeapps.list)
    # Uncomment and adjust to set per-host defaults.
    # mimeDefaultApps = {
    #   # PDFs
    #   "application/pdf" = ["okular.desktop"];
    #   "application/x-pdf" = ["okular.desktop"];
    #   # Web browser
    #   "x-scheme-handler/http"  = ["google-chrome.desktop"];  # or brave-browser.desktop, firefox.desktop
    #   "x-scheme-handler/https" = ["google-chrome.desktop"];
    #   "text/html"              = ["google-chrome.desktop"];
    #   # Text files
    #   "text/plain" = ["nvim.desktop"];             # or code.desktop, org.gnome.TextEditor.desktop
    #   # Images and video
    #   "image/png" = ["imv.desktop"];               # or org.gnome.eog.desktop
    #   "video/mp4" = ["mpv.desktop"];               # or vlc.desktop
    #   # Folders (file manager)
    #   "inode/directory" = ["thunar.desktop"];      # Thunar; or org.gnome.Nautilus.desktop, org.kde.dolphin.desktop
    # };

    # Available Options:
    # Kitty, ghostty, wezterm, aalacrity
    # Note: kitty, wezterm, alacritty have to be enabled in `variables.nix`
    # Setting it here does not enable it. Kitty is installed by default
    terminal = "kitty-bg"; # Set Default System Terminal

    keyboardLayout = "us";
    keyboardVariant = "";
    consoleKeyMap = "us";

    # Themes, waybar and animation.
    # Set Stylix Image
    # This will set your color palette
    # Default background
    # Add new images to ~/zaneyos/wallpapers
    stylixImage = ../../wallpapers/mountainscapedark.jpg;

    # Set Waybar
    #  Available Options:
    waybarChoice = ../../modules/home/waybar/waybar-curved.nix;

    # Set Animation style
    # Available options are:
    animChoice = ../../modules/home/hyprland/animations-def.nix;
  };
}

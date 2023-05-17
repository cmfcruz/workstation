#!/bin/bash

# This script switches from Wayland to X11

# Check if the user is root
switch_to_x11_gnome() {

    [[ "$(id -u)" != "0" ]] && echo "This function should be run as root." && return 1

    # For GDM/GNOME
    # Create a directory for gdm custom configuration
    mkdir -p /etc/gdm3/custom.conf.d

    # Create the custom configuration file
    echo -e "[daemon]\nWaylandEnable=false" > /etc/gdm3/custom.conf.d/disable-wayland.conf

    echo "Wayland disabled, X11 will be used next time you log in. Please reboot the system for changes to take effect."
}

switch_to_x11_kde() {

    [[ "$(id -u)" != "0" ]] && echo "This function should be run as root." && return 1

    # For KDE
    # Config file path
    KDE_CONFIG="$HOME/.config/plasma-workspace/env/set_window_manager.sh"

    # Create config directory if it does not exist
    mkdir -p "$(dirname "$KDE_CONFIG")"

    # Set the window manager to start as X11 in the config file
    echo "export KDE_FULL_SESSION=true" > "$KDE_CONFIG"
    echo "export XDG_SESSION_TYPE=x11" >> "$KDE_CONFIG"
    echo "export $(dbus-launch)" >> "$KDE_CONFIG"
    chmod +x "$KDE_CONFIG"

    echo "Switched KDE to use X11. Please log out and log back in for the changes to take effect."

}

# Check if a Wayland session is active
case "$XDG_SESSION_TYPE" in
    "wayland")
        case "$XDG_CURRENT_DESKTOP" in
            *"KDE"*)
                sudo bash -c "$(declare -f switch_to_x11_kde); switch_to_x11_kde"
                ;;
            *"GNOME"*)
                sudo bash -c "$(declare -f switch_to_x11_gnome); switch_to_x11_gnome"
                ;;
            *"Enlightenment"*)
                # For Enlightenment
                echo "Enlightenment doesn't provide a simple way to switch to X11 from Wayland. Manual intervention might be required."
                ;;
            *"Sway"*|"*Weston"*|"*Wayfire"*|"*Liri Shell"*)
                # For Sway, Weston, Wayfire, Liri Shell
                echo "These environments are designed for Wayland. If you want to use X11, consider switching to a different desktop environment."
                ;;
            *)
                # Unknown desktop environment
                echo "Unknown desktop environment. No changes were made."
                ;;
        esac
        ;;
    *)
        echo "Wayland is not currently active, no changes were made."
        ;;
esac

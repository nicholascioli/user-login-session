#!/usr/bin/env sh

# Immediately die if there is an error
set -e

# Do not expand glob * in paths
set -o noglob

# Helper function to display a dialog showing that a configuration does
#  not yet exist.
show_error_not_configured() {
    dialog \
        --title "Session Not Configured" \
        --msgbox "The current user '$USER' has not set up their session!" 10 50

    exit -1
}

# Get the XDG config directory
if [ -z "${XDG_CONFIG_HOME}" ]; then
    XDG_CONFIG_HOME=$HOME/.config
fi

# Look for the required configuration file in the set of XDG config directories
SESSION="${XDG_CONFIG_HOME}/user-login-session/session"
if [ -f "$SESSION" ]; then
    echo "Found user session at '$SESSION'. Executing..."
    sh $SESSION
else
    show_error_not_configured
fi

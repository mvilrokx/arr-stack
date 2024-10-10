#!/bin/bash

# Default base directory
BASE_DIR="/volume1"
# Make sure you create this Shared Folder in Synology DSM
DATA_DIR="${BASE_DIR}/data"
# If you installed Docker / Container Manager from the Package Center, this should have created this Shared Folder:
DOCKER_DIR="${BASE_DIR}/docker"

CREATE_TORRENT=false
CREATE_USENET=false

# Function to create torrent directories
create_torrent_dirs() {
    mkdir -p "$DATA_DIR"/torrents/{books,movies,music,tv}
    echo "Torrent directories created in $DATA_DIR/torrents"
}

# Function to create usenet directories
create_usenet_dirs() {
    mkdir -p "$DATA_DIR"/usenet/{incomplete,complete/{books,movies,music,tv}}
    echo "Usenet directories created in $DATA_DIR/usenet"
}

# Function to create media directories
create_media_dirs() {
    mkdir -p "$DATA_DIR"/media/{books,movies,music,tv}
    echo "Media directories created in $DATA_DIR/media"
}

# Function to create appdata directories
create_appdata_dirs() {
    mkdir -p "$DOCKER_DIR"/appdata/{radarr,sonarr,bazarr,lidarr,readarr,plex,prowlarr,overseerr,tautulli,pullio,homepage}
    echo "Appdata directories created in $DOCKER_DIR/appdata"
}

# Function to create usenet directories
create_watch_dir() {
    mkdir -p "$DATA_DIR"/watch
    echo "Watch directory created in $DATA_DIR/watch"
}

# Function to display help
display_help() {
    echo "Usage: $0 [-d base_directory] [-t] [-u] [-h]"
    echo "  -d: Specify the base directory (default: /volume1/data)"
    echo "  -t: Create torrent directories"
    echo "  -u: Create usenet directories"
    echo "  -h: Display this help message"
    echo "If neither -t nor -u is specified, only media directories will be created."
}

# Parse command line arguments
while getopts ":d:tuh" opt; do
    case $opt in
        d)
            BASE_DIR="$OPTARG"
            ;;
        t)
            CREATE_TORRENT=true
            ;;
        u)
            CREATE_USENET=true
            ;;
        h)
            display_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            display_help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            display_help
            exit 1
            ;;
    esac
done

# Always create media directories
create_media_dirs

# Always create appdata directories
create_appdata_dirs

# Always create watch directory
create_watch_dir

# Create torrent directories if specified
if $CREATE_TORRENT; then
    create_torrent_dirs
fi

# Create usenet directories if specified
if $CREATE_USENET; then
    create_usenet_dirs
fi

echo "All specified directories have been created."
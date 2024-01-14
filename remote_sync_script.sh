#!/bin/bash

# Local database file
database_file="remote_servers.txt"

# Function to add a new entry to the local database
add_to_database() {
    echo "$1|$2|$3|$4|$5" >> "$database_file"
}

# Function to read entries from the local database
read_database() {
    while IFS='|' read -r ip user port path pubkey; do
        echo "IP: $ip, User: $user, Port: $port, Path: $path, Public Key: $pubkey"
    done < "$database_file"
}

# Function to synchronize files with a remote server
sync_files() {
    ssh -p "$3" "$2@$1" "echo '$4' >> ~/.ssh/authorized_keys"
    rsync -avz -e "ssh -p $3 -o StrictHostKeyChecking=no" "$2@$1:$4" "$5"
}

# Prompt user for action
read -p "Do you want to add a new remote server or sync files? (add/sync): " action

if [ "$action" == "add" ]; then
    # Prompt user for remote server details
    read -p "Enter the remote server IP: " remote_ip
    read -p "Enter the remote server username: " remote_user
    read -p "Enter the remote server SSH port (default is 22): " remote_port
    remote_port=${remote_port:-22}  # Use 22 if user just presses Enter
    read -p "Enter the remote server path (absolute): " remote_path
    read -p "Enter your public key (content): " public_key

    # Add the new entry to the local database
    add_to_database "$remote_ip" "$remote_user" "$remote_port" "$remote_path" "$public_key"

    echo "Remote server added successfully!"
elif [ "$action" == "sync" ]; then
    # Prompt user to choose a remote server from the local database
    echo "Choose a remote server to sync files:"
    read_database
    read -p "Enter the index of the remote server to sync files: " server_index

    # Read the selected entry from the local database
    selected_server=$(sed -n "${server_index}p" "$database_file")

    # Extract details from the selected entry
    IFS='|' read -r remote_ip remote_user remote_port remote_path public_key <<< "$selected_server"

    # Prompt user for local path
    read -p "Enter the local path (absolute) to save files: " local_path

    # Synchronize files with the selected remote server
    sync_files "$remote_ip" "$remote_user" "$remote_port" "$remote_path" "$local_path"

    echo "Files synchronized successfully!"
else
    echo "Invalid action. Exiting."
fi

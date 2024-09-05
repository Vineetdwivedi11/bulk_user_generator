#!/bin/bash

# Check if the username file exists
if [[ ! -f "sample_users.txt" ]]; then
  echo "Error: new_list.txt file not found!"
  exit 1
fi

# Base UID and GID starting values
BASE_UID=1000
BASE_GID=1000
TOTAL_USERS=10

# Calculate end UID/GID based on total users
END_UID=$((BASE_UID + TOTAL_USERS - 1))
END_GID=$((BASE_GID + TOTAL_USERS - 1))

# Read the username file into an array
mapfile -t usernames < "sample_users.txt"

# Ensure there are enough usernames
if [[ ${#usernames[@]} -lt TOTAL_USERS ]]; then
  echo "Error: The usernames.txt file must contain at least $TOTAL_USERS usernames."
  exit 1
fi

# Create a log file
LOG_FILE="user_coordinator.log"
echo "User creation started at $(date)" > "$LOG_FILE"

# Iterate over each username
for i in $(seq 0 $((TOTAL_USERS - 1))); do
  username=${usernames[$i]}
  
  # Trim leading and trailing whitespace
  username=$(echo "$username" | xargs)
  
  # Check if username is not empty
  if [[ -n "$username" ]]; then
    # Calculate UID and GID based on index
    uid=$((BASE_UID + i))
    gid=$((BASE_GID + i))

    # Create group with a specific GID
    if groupadd -g "$gid" "$username"; then
      echo "Group '$username' with GID $gid created successfully." >> "$LOG_FILE"
    else
      echo "Failed to create group '$username' with GID $gid." >> "$LOG_FILE"
      continue
    fi
    
    # Create user with specific UID and GID and home directory
    if useradd -m -u "$uid" -g "$gid" -s /bin/bash "$username"; then
      echo "User '$username' with UID $uid created successfully." >> "$LOG_FILE"
      
      # Set the user's password to be the same as the username
      if echo "$username:$username" | chpasswd; then
        echo "Password set for '$username': $username" >> "$LOG_FILE"
      else
        echo "Failed to set password for '$username'." >> "$LOG_FILE"
      fi
      
      # Set permissions on the user's home directory
      chmod 700 /home/"$username"
      echo "Permissions set for /home/$username" >> "$LOG_FILE"
      
      # Print confirmation message
      echo "User '$username' created successfully with home directory and password set."
    else
      echo "Failed to create user '$username' with UID $uid." >> "$LOG_FILE"
      continue
    fi
  fi
done

echo "User creation completed at $(date)" >> "$LOG_FILE"
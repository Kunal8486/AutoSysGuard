# 2.3.6 Ensure RPC is not installed (Automated)
#!/bin/bash

# Function to check if rpcbind is installed
check_rpc_installed() {
    dpkg-query -W -f='${Status}' rpcbind 2>/dev/null | grep -q "install ok installed"
}

# Check if rpcbind is installed
if check_rpc_installed; then
    echo "rpcbind is currently installed."

    # Ask user for confirmation to uninstall
    read -p "Do you want to uninstall rpcbind? (y/n): " choice
    case "$choice" in
        y|Y ) 
            echo "Uninstalling rpcbind..."
            sudo apt-get purge --auto-remove rpcbind -y
            echo "rpcbind has been successfully removed.";;
        n|N ) 
            echo "rpcbind will remain installed.";;
        * ) 
            echo "Invalid choice. Please enter y or n.";;
    esac
else
    echo "rpcbind is not installed."
fi

# Optionally, provide a summary of the package status
echo "Verifying package status..."
dpkg-query -W -f='${binary:Package}\t${Status}\n' rpcbind


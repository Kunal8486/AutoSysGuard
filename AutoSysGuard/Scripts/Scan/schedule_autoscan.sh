#!/bin/bash

# ASCII banner
cat << "EOF"
 █████╗ ██╗   ██╗████████╗ ██████╗     ███████╗██╗   ██╗███████╗     ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗ 
██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗    ██╔════╝╚██╗ ██╔╝██╔════╝    ██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗
███████║██║   ██║   ██║   ██║   ██║    ███████╗ ╚████╔╝ ███████╗    ██║  ███╗██║   ██║███████║██████╔╝██║  ██║
██╔══██║██║   ██║   ██║   ██║   ██║    ╚════██║  ╚██╔╝  ╚════██║    ██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║
██║  ██║╚██████╔╝   ██║   ╚██████╔╝    ███████║   ██║   ███████║    ╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝
╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝     ╚══════╝   ╚═╝   ╚══════╝     ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
                                                                                                              
EOF

sleep 2

# Prompt user to view license information
read -r -n 1 -t 5 -p "Press 'i' to view the license information: " input
if [[ "$input" == "i" || "$input" == "I" ]]; then
    # Copyright banner
    cat << "EOF"
################################################################################
# Copyright (C) 2024 AutoSysGuard
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See the GNU General Public License
# version 3 or later for details: https://www.gnu.org/licenses/gpl-3.0.html
#
# For more information, visit: https://github.com/Kunal8486/AutoSysGuard
################################################################################
EOF
else
    echo -e "\nSkipping license info..."
fi

# Function to check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root." | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Function to prompt the user for debug mode
prompt_debug_mode() {
    read -r -p "Do you want to enable debug mode? (yes/no): " debug_choice
    case $debug_choice in
        [yY]|[yY][eE][sS])
            DEBUG=true
            debug "Creating log file..."
            LOG_FILE="log/Scheduled_Scan_AutoSysGuard.log"  # Create log file when debug mode is enabled
            exec 2> >(tee -a "$LOG_FILE")   # Redirect standard error to log file with tee for real-time logging
            ;;
        *)
            DEBUG=false
            LOG_FILE="/dev/null"  # No log file when debug mode is disabled
            ;;
    esac
}

# Debug function
debug() {
    if [[ $DEBUG == "true" ]]; then
        echo "[DEBUG] $1" | tee -a "$LOG_FILE"
    fi
}

# Function to detect the package manager
detect_package_manager() {
    echo AutoSysGuard starting...
    debug "Detecting package manager..."
    local managers=("nala" "apt" "dnf" "yum" "zypper" "pacman" "apk")
    for manager in "${managers[@]}"; do
        if command -v "$manager" &> /dev/null; then
            PKG_MANAGER="$manager"
            debug "Package manager detected: $PKG_MANAGER"
            return
        fi
    done
    echo "No supported package manager found!" | tee -a "$LOG_FILE"
    exit 1
}

# Initialize a flag variable
system_update_flag=0

# Define the function you want to run only once
prompt_system_update() {
  if [ $system_update_flag -eq 0 ]; then
    read -r -p "Highly recommended to update system before installing, do you want to update? (yes/no): " update_choice
    if [[ "$update_choice" =~ ^(yes|y)$ ]]; then
        echo "Running system update..."
        case "$PKG_MANAGER" in
            "nala" | "apt" | "dnf" | "yum")
                sudo "$PKG_MANAGER" update -y && sudo "$PKG_MANAGER" upgrade -y
                ;;
            "zypper")
                sudo zypper -vvv dup
                ;;
            "pacman")
                sudo pacman -Syu
                ;;
            "apk")
                sudo apk update
                ;;
            *)
                echo "Warning: Unsupported package manager. System update may not work."
                ;;
        esac
        # Set the flag to indicate the function has run
        system_update_flag=1
    else
        echo "Skipping system update."
    fi
  else
    echo "System Update has already been run, skipping."
  fi
}

# Function to display the loading indicator
show_loading() {
  local delay=0.2
  local ellipsis='...'

  while :; do
    for i in $(seq 0 ${#ellipsis}); do
      printf "\rWorking %s" "${ellipsis:0:i}"
      sleep $delay
    done
  done
}

# Function to check if ClamAV is already installed
check_clamav_installed() {
    echo Checking if ClamAV is installed...
    if ! command -v clamscan &> /dev/null; then
        echo "ClamAV is not currently installed..."
        read -r -p "Would you like to install it? (yes/no): " install_choice
        if [[ "$install_choice" =~ ^(yes|y)$ ]]; then
            install_clamav
            configure_freshclam
            prompt_cron_anacron_choice
        else
            echo "ClamAV installation skipped. Exiting..."
            exit 0
        fi
    else
    clamav_exists
    fi
}

#Function if ClamAV is already installed
    clamav_exists() {
        echo "ClamAV is already installed." | tee -a "$LOG_FILE"
        read -r -p "Would you like to re(i)nstall, re(c)onfigure, (r)emove it, or (e)xit?: " action_choice
        case "$action_choice" in
            [iI])
                echo Reinstalling ClamAV...
                remove_clamav
                install_clamav
                configure_freshclam
                prompt_cron_anacron_choice
                ;;
            [cC])
                echo Reconfiguring ClamAV...
                additional_setup_steps
                configure_freshclam
                prompt_cron_anacron_choice
                ;;
            [rR])
                echo Removing ClamAV...
                remove_clamav
                exit 0 # Exit script after removing ClamAV
                ;;
            [eE])
                echo "Exiting AutoSysGuard..." | tee -a "$LOG_FILE"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again." | tee -a "$LOG_FILE"
                clamav_exists
                ;;
        esac
}

# Function to install clamav based on the detected package manager
install_clamav() {
    echo Installing ClamAV...
    prompt_system_update
    debug "Installing ClamAV using package manager: $PKG_MANAGER" | tee -a "$LOG_FILE"
    case "$PKG_MANAGER" in
        "nala")
            sudo nala install -y clamav clamav-daemon
            ;;
        "apt")
            sudo apt install -y clamav clamav-daemon
            ;;
        "dnf")
            sudo dnf install -y clamav clamd clamav-update
            additional_setup_steps
            ;;
        "yum")
            sudo yum -y install clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-lib clamav-server-systemd clamav-devel # see https://www.hostinger.com/tutorials/how-to-install-clamav-centos7 or https://gist.github.com/fernandoaleman/50b134b987297f97c803c91b591e5c52
            additional_setup_steps
            ;;
        "zypper")
            sudo zypper install -y clamav # see https://en.opensuse.org/ClamAV
            additional_setup_steps
            ;;
        "pacman")
            sudo pacman -Syu clamav # see https://wiki.archlinux.org/title/ClamAV
            ;;
        "apk")
            sudo apk add clamav
            additional_setup_steps
            ;;
        *)
            echo "Unsupported package manager: $PKG_MANAGER" | tee -a "$LOG_FILE"
            exit 1
            ;;
    esac
    echo
    debug "ClamAV installation complete."
}

# Function to handle additional setup steps for specific package managers
additional_setup_steps() {
    echo Reconfiguring ClamAV
        case "$PKG_MANAGER" in
        "dnf")
            sudo systemctl stop clamav-freshclam
            prompt_system_update
            change_clamav_permissions
            sudo freshclam
            sudo systemctl enable clamav-freshclam --now
            ;;
        "yum")
            prompt_system_update
            change_clamav_permissions
            if sudo sestatus | grep -q "enabled"; then
                sudo setsebool -P antivirus_can_scan_system 1
                sudo setsebool -P clamd_use_jit 1
                sudo getsebool -a | grep antivirus
            fi
            sudo sed -i -e "s/^Example/#Example/" /etc/clamd.d/scan.conf
            sudo sed -i -e "s/^#LocalSocket /LocalSocket /" /etc/clamd.d/scan.conf
            sudo sed -i -e "s/^Example/#Example/" /etc/freshclam.conf
            sudo freshclam
            sudo systemctl start clamd@scan
            sudo systemctl enable clamd@scan
            ;;
        "zypper")
            prompt_system_update
            sudo systemctl start freshclam
            sudo systemctl enable freshclam.timer
            echo This part takes a long time on SUSE according to their documentation.
            show_loading &
            loading_pid=$!
            sleep 600  # Wait for 10 minutes
            kill $loading_pid
            echo -ne "\rDone!           \n"
            sudo systemctl start clamd
            sudo systemctl enable clamd
            ;;
        "pacman")
            sudo freshclam
            sudo systemctl start clamav-freshclam.service
            sudo systemctl enable clamav-freshclam.service
            sudo systemctl start clamav-daemon.service
            sudo systemctl enable clamav-daemon.service
            ;;
    esac
    echo Enabling and starting ClamAV service...
    echo
    if command -v systemctl &> /dev/null; then
        sudo systemctl enable clamav-freshclam.service
        sudo systemctl start clamav-freshclam.service
    else
        echo "Systemctl not found. Please enable and start clamav-freshclam manually."
    fi
    echo "Performing SELinux configuration..."
    if command -v setsebool &> /dev/null; then
        sudo setsebool -P antivirus_can_scan_system 1
    fi
    echo
    echo Additional Steps Complete
}

# Function to change permissions of the /var/lib/clamav directory
change_clamav_permissions() {
    local target_user="clamupdate"  # see https://src.fedoraproject.org/rpms/clamav
    local target_group="clamupdate" # and also https://docs.clamav.net/manual/Installing.html

    # Check if clamupdate user exists
    if ! id "$target_user" &>/dev/null; then
        echo "Error: The user $target_user does not exist."
        return 1
    fi

    # Copy the clamav-freshclam.service file to /etc/systemd/system/ if it doesn't exist
    if [ ! -f /etc/systemd/system/clamav-freshclam.service ]; then
        sudo cp /usr/lib/systemd/system/clamav-freshclam.service /etc/systemd/system/
    fi

    # Add ExecStartPre command to change ownership in clamav-freshclam.service if not already present
    if ! sudo grep -q "ExecStartPre=+/usr/bin/chown $target_user:$target_group /var/lib/clamav" /etc/systemd/system/clamav-freshclam.service; then
        sudo sed -i "/^\[Service\]/a ExecStartPre=+/usr/bin/chown $target_user:$target_group /var/lib/clamav" /etc/systemd/system/clamav-freshclam.service
    fi

    # Reload systemd daemon to apply changes
    sudo systemctl daemon-reload
}

# Function to remove ClamAV
remove_clamav() {
    echo Removing ClamAV...
    case "$PKG_MANAGER" in
        "nala")
            sudo nala remove -y clamav clamav-daemon
            ;;
        "apt")
            sudo apt remove -y clamav clamav-daemon
            ;;
        "dnf")
            sudo dnf remove -y clamav clamd clamav-update
            ;;
        "yum")
            sudo yum -y remove clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-lib clamav-server-systemd clamav-devel
            ;;
        "zypper")
            sudo zypper remove -y clamav
            ;;
        "pacman")
            sudo pacman -Rns clamav
            ;;
        "apk")
            sudo apk del clamav
            ;;
        *)
            echo "Unsupported package manager: $PKG_MANAGER" | tee -a "$LOG_FILE"
            exit 1
            ;;
    esac
        echo "ClamAV removed successfully."
}

# Function to configure freshclam
configure_freshclam() {
    echo Gathering info to configure freshclam...
    echo "Configuring freshclam..." | tee -a "$LOG_FILE"

    # Get the country code, default to US if detection fails
    country_code=$(curl -s ifconfig.co/country || echo "US")
    debug "Country code detected: $country_code"

    # List of potential locations for freshclam.conf
    config_files=(
        "/etc/clamav/freshclam.conf"
        "/etc/freshclam.conf"
        "/usr/local/etc/clamav/freshclam.conf"
        "/opt/local/etc/clamav/freshclam.conf"
    )

    file_found=false

    # Loop through the list and apply the sed command if the file exists
for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ]; then
        sudo sed -i "s/^#DatabaseMirror.*/DatabaseMirror db.${country_code}.clamav.net/" "$config_file"
        file_found=true
        break
    fi
done

if [ "$file_found" = false ]; then
    echo "Configuration file not found in the predefined locations."
    read -r -p "Would you like to search the entire filesystem for freshclam.conf? (y/n): " search_choice
    if [[ "$search_choice" =~ ^(yes|y)$ ]]; then
        # Run the find command from the root directory
        found_files=$(sudo find / -type f -name freshclam.conf 2>/dev/null)

        if [ -z "$found_files" ]; then
            echo "No freshclam.conf file found on the system."
        else
            echo "Found the following freshclam.conf files:"
            echo "$found_files"
            read -r -p "Please enter the full path of the freshclam.conf file you want to update: " config_file
            if [ -f "$config_file" ]; then
                sudo sed -i "s/^#DatabaseMirror.*/DatabaseMirror db.${country_code}.clamav.net/" "$config_file"
                echo "Updated $config_file successfully."
            else
                echo "The file path provided does not exist or is not a file."
            fi
        fi
    else
        echo "Search aborted."
    fi
fi

    sleep 2
    echo "Configuration of freshclam completed." | tee -a "$LOG_FILE"
}

# Function to prompt user to choose between cron and anacron for scheduling
prompt_cron_anacron_choice() {
    echo "Choose the scheduling method for ClamAV scans and freshclam updates:"
    echo "Cron: Jobs run at specific times. Best choice for always-on systems."
    echo "Anacron: Jobs run daily, weekly, or monthly, even if the system was off during the scheduled time. Best for user systems."
    read -r -p "Would you prefer to use (a)nacron or (c)ron for scheduling tasks? (a/c): " schedule_choice
    case $schedule_choice in
        [aA])
            echo "Anacron depends on Cron, installing Cron dependancy."
            setup_cron
            setup_anacron
            ;;
        [cC])
            setup_cron
            ;;
        *)
            echo "Invalid choice. Please try again."
            prompt_cron_anacron_choice
            ;;
    esac
}

# Function to set up cron
setup_cron() {
    echo "Checking if cron is installed..."
    if ! command -v crond &> /dev/null && ! command -v cron &> /dev/null && command -v cronie &> /dev/null; then
        echo "Cron is not installed. Would you like to install it? (yes/no)"
        read -r install_cron_choice
        if [[ "$install_cron_choice" =~ ^(yes|y)$ ]]; then
            echo "Installing Cron..."
            echo
            case "$PKG_MANAGER" in
                "nala")
                    sudo nala install -y cron
                    ;;
                "apt")
                    sudo apt install -y cron
                    ;;
                "dnf")
                    sudo dnf install -y cronie
                    ;;
                "yum")
                    sudo yum install -y cronie
                    ;;
                "zypper")
                    sudo zypper install -y cron
                    ;;
                "pacman")
                    sudo pacman -Sy --noconfirm cronie
                    ;;
                "apk")
                    sudo apk add cron
                    ;;
                *)
                    echo "No supported package manager found! Cannot install Cron." | tee -a "$LOG_FILE"
                    exit 1
                    ;;
            esac
            echo
            echo "Cron installed successfully."
        else
            echo
            echo "Cron installation skipped."
            return
        fi
    else

        echo "Cron is already installed."
    fi
    # Ensure the cron service is running
        if command -v systemctl &> /dev/null; then
            if systemctl list-units --type=service --all | grep -q 'cron.service'; then
                sudo systemctl enable --now cron
            elif systemctl list-units --type=service --all | grep -q 'crond.service'; then
               sudo systemctl enable --now crond
            elif systemctl list-units --type=service --all | grep -q 'cronie.service'; then
                sudo systemctl enable --now cronie
            else
                echo "No known cron service found. Please start it manually."
            fi
        elif command -v service &> /dev/null; then
            if service --status-all | grep -q 'cron'; then
                sudo service cron start
            elif service --status-all | grep -q 'crond'; then
                sudo service crond start
            elif service --status-all | grep -q 'cronie'; then
                sudo service cronie start
            else
                echo "No known cron service found. Please start it manually."
            fi
        elif command -v rc-service &> /dev/null; then
            if rc-service --list | grep -q 'cron'; then
                sudo rc-service cron start
            elif rc-service --list | grep -q 'crond'; then
                sudo rc-service crond start
            elif rc-service --list | grep -q 'cronie'; then
                sudo rc-service cronie start
            else
                echo "No known cron service found. Please start it manually."
            fi
        else
            echo "Unable to manage cron service. Please start it manually."
        fi
    create_cron_job
    create_freshclam_cron_job
}

# Function to set up anacron
setup_anacron() {
    echo "Checking if Anacron is installed..."
    if ! command -v anacron &> /dev/null; then
        echo "Anacron is not installed. Would you like to install it? (yes/no)"
        read -r install_anacron_choice
        if [[ "$install_anacron_choice" =~ ^(yes|y)$ ]]; then
            echo "Installing Anacron..."
            case "$PKG_MANAGER" in
                "nala")
                    sudo nala install -y anacron
                    ;;
                "apt")
                    sudo apt install -y anacron
                    ;;
                "dnf")
                    sudo dnf install -y anacron
                    ;;
                "yum")
                    sudo yum install -y anacron
                    ;;
                "zypper")
                    sudo zypper install -y anacron
                    ;;
                "pacman")
                    sudo pacman -Sy --noconfirm anacron
                    ;;
                "apk")
                    sudo apk add anacron
                    ;;
                *)
                    echo "No supported package manager found! Cannot install Anacron." | tee -a "$LOG_FILE"
                    exit 1
                    ;;
            esac
            echo "Anacron installed successfully."
        else
            echo "Anacron installation skipped."
            return
        fi
    else
        echo "Anacron is already installed."
    fi
    create_anacron_job
    create_freshclam_anacron_job
}

# Function to create a cron job for ClamAV scans
create_cron_job() {
    echo "Would you like to create a cron job for regular scans? (yes/no)"
    read -r create_cronjob
    if [[ "$create_cronjob" =~ ^(yes|y)$ ]]; then
        # Prompt for cron job schedule
        echo "Enter the time for the cron job (24-hour format, e.g., 01 for 1 AM):"
        read -r cron_hours
        echo "Enter the minutes for the cron job (0-59):"
        read -r cron_minutes
        echo "Enter the day(s) of the week for the cron job (0-6, where 0 is Sunday, 1 is Monday, ..., 6 is Saturday):"
        read -r cron_days

        # Combine hours, minutes, and days into the cron time format
        cron_time="$cron_minutes $cron_hours * * $cron_days"

        # Prompt for extra directories to scan
        directories=("/home/")
        echo "Enter extra directories to scan, one at a time. Press Enter without input to finish:"
        while true; do
            read -r extra_dir
            [[ -z "$extra_dir" ]] && break
            if [[ "$extra_dir" == /* ]]; then
                skip=false
                for dir in "${directories[@]}"; do
                    if [[ "$extra_dir" == "$dir"* || "$dir" == "$extra_dir"* ]]; then
                        echo "Skipping $extra_dir as it conflicts with an existing directory $dir"
                        skip=true
                        break
                    fi
                done
                [[ "$skip" == false ]] && directories+=("$extra_dir")
            else
                echo "Please enter an absolute path starting with '/'."
            fi
        done

        # Combine all directories into a single scan command
        scan_command=""
        for dir in "${directories[@]}"; do
            scan_command+="/usr/bin/clamscan -r --quiet --move=/home/$(whoami)/infected $dir && "
        done
        scan_command="${scan_command% && }"  # Remove the trailing '&&'

        echo "Creating cron job to scan specified directories..."
        (sudo crontab -l 2>/dev/null; echo "$cron_time $scan_command") | sudo crontab -
        echo "Cron job created for scans at $cron_time on day(s) of the week $cron_days."
    else
        echo "Cron job creation for scans skipped."
    fi
}

# Function to create a cron job for freshclam updates
create_freshclam_cron_job() {
    echo "Would you like to add a daily update check for virus definitions using freshclam? (yes/no)"
    read -r create_freshclam_cronjob
    if [[ "$create_freshclam_cronjob" =~ ^(yes|y)$ ]]; then
        echo "Configuring scheduled job for virus database updates..."
        local cron_file="/etc/cron.daily/freshclam"
        sudo bash -c "cat > $cron_file" << EOF
#!/bin/bash
# Freshclam auto-update script
/usr/bin/freshclam --quiet
EOF
        sudo chmod +x "$cron_file"
        echo "Cron job configured at $cron_file"
    else
        echo "Cron job creation for freshclam updates skipped."
    fi
}

# Function to create an anacron job for ClamAV scans
create_anacron_job() {
    echo "Would you like to create an anacron job for regular scans? (yes/no)"
    read -r create_anacronjob
    if [[ "$create_anacronjob" =~ ^(yes|y)$ ]]; then
        echo "Enter the frequency for the anacron job in days (e.g., 7 for weekly):"
        read -r anacron_frequency
        echo "Enter the delay in minutes after boot for the anacron job to run:"
        read -r anacron_delay

        # Prompt for extra directories to scan
        directories=("/home/")
        echo "Enter extra directories to scan, one at a time. Press Enter without input to finish:"
        while true; do
            read -r extra_dir
            [[ -z "$extra_dir" ]] && break
            if [[ "$extra_dir" == /* ]]; then
                skip=false
                for dir in "${directories[@]}"; do
                    if [[ "$extra_dir" == "$dir"* || "$dir" == "$extra_dir"* ]]; then
                        echo "Skipping $extra_dir as it conflicts with an existing directory $dir"
                        skip=true
                        break
                    fi
                done
                [[ "$skip" == false ]] && directories+=("$extra_dir")
            else
                echo "Please enter an absolute path starting with '/'."
            fi
        done

        # Create user-specific anacron directories and files
        mkdir -p ~/.anacron/cron.{daily,weekly,monthly} ~/.anacron/spool

        # Create the anacron job script
        anacron_job="$HOME/.anacron/cron.daily/clamscan_job"
        {
            echo "#!/bin/bash"
            for dir in "${directories[@]}"; do
                echo "/usr/bin/clamscan -r --quiet --move=$HOME/infected $dir"
            done
        } > "$anacron_job"
        chmod +x "$anacron_job"

        # Create user-specific anacrontab
        anacrontab="$HOME/.anacron/anacrontab"
        cat > "$anacrontab" << EOF
SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:$HOME/bin
HOME=$HOME
LOGNAME=$(whoami)

# period  delay  job-id  command
$anacron_frequency  $anacron_delay  user.cron.daily  nice run-parts $HOME/.anacron/cron.daily
EOF
        # Add cron job to run anacron periodically
        (crontab -l 2>/dev/null; echo "01 * * * * /usr/sbin/anacron -t $HOME/.anacron/anacrontab -S $HOME/.anacron/spool") | crontab -

        echo "Anacron job created to run every $anacron_frequency days with a delay of $anacron_delay minutes after boot if missed."
    else
        echo "Anacron job creation for scans skipped."
    fi
}

# Function to create an anacron job for freshclam updates
create_freshclam_anacron_job() {
    echo "Would you like to add a daily update check for virus definitions using freshclam? (yes/no)"
    read -r create_freshclam_anacronjob
    if [[ "$create_freshclam_anacronjob" =~ ^(yes|y)$ ]]; then
        echo "Configuring scheduled job for virus database updates..."
        local anacron_file="$HOME/.anacron/cron.daily/freshclam"
        {
            echo "#!/bin/bash"
            echo "# Freshclam auto-update script"
            echo "/usr/bin/freshclam --quiet"
        } > "$anacron_file"
        chmod +x "$anacron_file"
        echo "Anacron job configured at $anacron_file"
    else
        echo "Anacron job creation for freshclam updates skipped."
    fi
}

# Main execution
main() {
    check_root
    sleep 2
    prompt_debug_mode
    sleep 2
    detect_package_manager
    sleep 2
    check_clamav_installed
    sleep 2
}

echo "Welcome to AutoSysGuard!"
main
echo "AutoSysGuard exiting..."
exit

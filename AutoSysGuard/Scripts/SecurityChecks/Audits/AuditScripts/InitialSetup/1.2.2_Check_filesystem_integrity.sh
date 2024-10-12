#!/bin/bash

# Function to check if AIDE cron job is scheduled
check_cron_job() {
    echo "Checking for AIDE cron job..."
    if grep -Prs '^([^#\n\r]+\h+)?(\/usr\/s?bin\/|^\h*)aide(\.wrapper)?\h+(--check|([^#\n\r]+\h+)?\$AIDEARGS)\b' /etc/cron.* /etc/crontab /var/spool/cron/; then
        echo "AIDE cron job is scheduled."
        return 0  # Cron job found
    else
        echo "No AIDE cron job found."
        return 1  # No cron job
    fi
}

# Function to check the status of aidecheck.service and aidecheck.timer
check_systemd_service_timer() {
    echo "Checking aidecheck.service and aidecheck.timer..."
    systemctl is-enabled aidecheck.service 2>/dev/null
    local service_status=$?
    systemctl is-enabled aidecheck.timer 2>/dev/null
    local timer_status=$?
    local timer_running=$(systemctl is-active aidecheck.timer 2>/dev/null)

    if [[ $service_status -eq 0 && $timer_status -eq 0 && $timer_running == "active" ]]; then
        echo "AIDE check service and timer are enabled and running."
        return 0  # Both service and timer are enabled and running
    else
        echo "AIDE check service or timer is not enabled or not running."
        return 1  # Service or timer is not enabled
    fi
}

# Function to set up the cron job
setup_cron_job() {
    echo "Setting up AIDE cron job..."
    sudo crontab -u root -e <<EOF
0 5 * * * /usr/bin/aide.wrapper --config /etc/aide/aide.conf --check
EOF
    echo "AIDE cron job has been added."
}

# Function to set up the systemd service and timer
setup_systemd_service_timer() {
    echo "Setting up AIDE systemd service and timer..."

    # Create or edit the aidecheck.service file
    cat <<EOF | sudo tee /etc/systemd/system/aidecheck.service
[Unit]
Description=Aide Check

[Service]
Type=simple
ExecStart=/usr/bin/aide.wrapper --config /etc/aide/aide.conf --check

[Install]
WantedBy=multi-user.target
EOF

    # Create or edit the aidecheck.timer file
    cat <<EOF | sudo tee /etc/systemd/system/aidecheck.timer
[Unit]
Description=Aide check every day at 5AM

[Timer]
OnCalendar=*-*-* 05:00:00
Unit=aidecheck.service

[Install]
WantedBy=multi-user.target
EOF

    # Set permissions
    sudo chown root:root /etc/systemd/system/aidecheck.*
    sudo chmod 0644 /etc/systemd/system/aidecheck.*

    # Reload systemd and enable service and timer
    sudo systemctl daemon-reload
    sudo systemctl enable aidecheck.service
    sudo systemctl --now enable aidecheck.timer

    echo "AIDE systemd service and timer have been set up."
}

# Main script execution
if check_cron_job; then
    echo "Audit complete. AIDE cron job is set."
elif check_systemd_service_timer; then
    echo "Audit complete. AIDE systemd service and timer are set."
else
    echo "Would you like to set up a cron job or systemd service and timer? (Enter 'cron' or 'systemd', or 'exit' to quit)"
    read choice
    case $choice in
        cron)
            setup_cron_job
            ;;
        systemd)
            setup_systemd_service_timer
            ;;
        exit)
            echo "Exiting without making changes."
            ;;
        *)
            echo "Invalid choice. Exiting."
            ;;
    esac
fi

#!/bin/bash

# Function to audit if systemd-journald.service has the correct status
audit_journald_service() {
    echo "Auditing systemd-journald.service..."

    # Checking if the service status is 'static'
    service_status=$(systemctl is-enabled systemd-journald.service 2>/dev/null)

    if [[ "$service_status" == "static" ]]; then
        echo "Audit: systemd-journald.service is in 'static' state as expected."
    else
        echo "Audit: systemd-journald.service is not in 'static' state."
        echo "Further investigation required to understand why systemd-journald.service is not 'static'."
    fi
}

# Running the audit
audit_journald_service

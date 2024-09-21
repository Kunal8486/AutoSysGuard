#!/bin/bash

# Ensure script is run as root
if [[ $(id -u) -ne 0 ]]; then
    echo "Please run as root"
    exit 1
fi

echo "Starting comprehensive security audit on Kali Linux..."

# Update package lists and upgrade system
echo "[1] Updating package lists and upgrading system..."
apt-get update -y
apt-get upgrade -y

# 1. Basic System Information
echo "[2] Gathering basic system information..."
uname -a
df -h
free -m
uptime

# 2. Lynis System Audit
echo "[3] Running Lynis for system auditing..."
lynis audit system

# 3. OpenVAS Vulnerability Scan
echo "[4] Performing vulnerability scan with OpenVAS..."
openvas-start
openvas-check-setup
openvas-feed-update
openvas-scapdata-sync
openvas-certdata-sync
openvas-stop
openvas-start
openvasmd --rebuild --progress

# 4. Check for Weak Passwords
echo "[5] Checking for weak passwords using John the Ripper..."
john --test=0

# 5. ClamAV Malware Scan
echo "[6] Scanning for malware with ClamAV..."
clamscan -r --bell -i /

# 6. Rkhunter Rootkit Check
echo "[7] Checking for rootkits using rkhunter..."
rkhunter --check --sk

# 7. Chkrootkit Rootkit Check
echo "[8] Checking for rootkits using chkrootkit..."
chkrootkit

# 8. Debsums Filesystem Integrity Check
echo "[9] Checking filesystem integrity using debsums..."
debsums -s

# 9. Audit SSH Configuration
echo "[10] Auditing SSH configuration..."
sshd_config="/etc/ssh/sshd_config"
if [ -f "$sshd_config" ]; then
    grep -E 'PermitRootLogin|PasswordAuthentication|AllowTcpForwarding|X11Forwarding|UsePAM|ClientAliveInterval' $sshd_config
else
    echo "SSH configuration file not found."
fi

# 10. Check for Open Ports and Services
echo "[11] Checking for open ports and services..."
netstat -tuln

# 11. Check for World-Writable Files
echo "[12] Checking for world-writable files..."
find / -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print

# 12. Checking for SUID/SGID Executables
echo "[13] Checking for SUID/SGID executables..."
find / -perm -4000 -o -perm -2000 -print

# 13. List Installed Packages and Versions
echo "[14] Listing installed packages and their versions..."
dpkg -l

# 14. Check for Listening Network Services
echo "[15] Checking listening network services..."
lsof -i -P -n | grep LISTEN

# 15. Check for Suspicious Processes
echo "[16] Checking for suspicious processes..."
ps aux | grep -v '^\s*UID' | awk '$3>50.0 {print $0}'

# 16. Check for Empty Passwords
echo "[17] Checking for empty passwords..."
awk -F: '($2 == "") {print $1}' /etc/shadow

# 17. Audit PAM Modules
echo "[18] Auditing PAM modules..."
grep -rH 'pam_' /etc/pam.d/

# 18. List Active Cron Jobs
echo "[19] Listing active cron jobs..."
crontab -l
ls -la /etc/cron*

# 19. Check Kernel Logs
echo "[20] Checking kernel logs..."
dmesg | tail -n 50

# 20. Audit Logins and Failed Attempts
echo "[21] Auditing logins and failed login attempts..."
last
lastb

# 21. Check SELinux Status (if applicable)
echo "[22] Checking SELinux status..."
sestatus 2>/dev/null || echo "SELinux not installed."

# 22. Scan Network Interfaces for Promiscuous Mode
echo "[23] Scanning network interfaces for promiscuous mode..."
ip link | grep PROMISC

# 23. Check for Duplicate User IDs
echo "[24] Checking for duplicate user IDs..."
awk -F: '{print $3}' /etc/passwd | sort | uniq -d

# 24. Check for Users with No Home Directory
echo "[25] Checking for users with no home directory..."
awk -F: '($7 != "/sbin/nologin" && $6 == "") {print $1}' /etc/passwd

# 25. Check for Unauthorized SSH Keys
echo "[26] Checking for unauthorized SSH keys..."
grep -r "ssh-rsa" /home/*/.ssh/authorized_keys

# 26. Check for Duplicate Group IDs
echo "[27] Checking for duplicate group IDs..."
awk -F: '{print $3}' /etc/group | sort | uniq -d

# 27. Check for Core Dumps
echo "[28] Checking for core dumps..."
sysctl kernel.core_pattern

# 28. Audit Sudoers File
echo "[29] Auditing sudoers file..."
grep -v '^#' /etc/sudoers | grep -v '^$'

# 29. Verify System Accounts
echo "[30] Verifying system accounts..."
awk -F: '($3 < 1000) {print $1}' /etc/passwd

# 30. Check Unowned Files and Directories
echo "[31] Checking for unowned files and directories..."
find / -xdev \( -nouser -o -nogroup \) -print

# 31. Verify Network Time Protocol
echo "[32] Verifying NTP configuration..."
timedatectl status

# 32. Check for Unnecessary Packages
echo "[33] Checking for unnecessary packages..."
deborphan

# 33. Check for Unauthorized World-Writable Directories
echo "[34] Checking for unauthorized world-writable directories..."
find / -xdev -type d -perm -0002

# 34. Perform DNS Configuration Audit
echo "[35] Performing DNS configuration audit..."
cat /etc/resolv.conf

# 35. Check for Open Relay in Mail Server
echo "[36] Checking for open relay in mail server..."
grep "smtpd_recipient_restrictions" /etc/postfix/main.cf

# 36. Check System D-Bus Services
echo "[37] Checking system D-Bus services..."
systemctl list-units --type=service

# 37. Check User Account Expiry Details
echo "[38] Checking user account expiry details..."
chage -l $(whoami)

# 38. Check Installed Kernel Modules
echo "[39] Checking installed kernel modules..."
lsmod

# 39. Check for Hidden Files
echo "[40] Checking for hidden files..."
find / -type f -name ".*"

# 40. Validate File Permissions of Critical Files
echo "[41] Validating file permissions of critical files..."
ls -l /etc/passwd /etc/shadow /etc/group

# 41. Perform Kernel Hardening Checks
echo "[42] Performing kernel hardening checks..."
sysctl -a | grep 'kernel.*'

# 42. Check Network Firewall Rules
echo "[43] Checking network firewall rules..."
iptables -L -n -v

# 43. Audit Security-Enhanced Linux (SELinux) Policy (if enabled)
echo "[44] Auditing SELinux policy..."
getenforce 2>/dev/null || echo "SELinux not installed."

# 44. Check for Unattended Upgrades
echo "[45] Checking for unattended upgrades configuration..."
cat /etc/apt/apt.conf.d/20auto-upgrades

# 45. Verify the Configuration of Pluggable Authentication Modules (PAM)
echo "[46] Verifying PAM configuration..."
grep -r "^auth" /etc/pam.d/

# 46. Verify SSH Host Key Permissions
echo "[47] Verifying SSH host key permissions..."
ls -l /etc/ssh/ssh_host_*

# 47. Check for Group Policy Object (GPO) Configuration
echo "[48] Checking for GPO configuration..."
gpresult /h result.html

# 48. Check System Boot Order
echo "[49] Checking system boot order..."
ls /boot/grub/

# 49. Check the Existence of Sensitive Directories
echo "[50] Checking the existence of sensitive directories..."
ls -ld /root/ /home/ /tmp/

# 50. Run Security Content Automation Protocol (SCAP) Security Guide (SSG)
echo "[51] Running SCAP security guide..."
oscap xccdf eval --profile default /usr/share/xml/scap/ssg/content/ssg-debian8-xccdf.xml

echo "Security audit complete."

from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QTextEdit, QAction, QMainWindow
from PyQt5.QtCore import QProcess
import sys
import os

class SecurityAuditApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.initUI()

 # Ensure the script runs with sudo privileges
if os.geteuid() != 0:
    print("This application requires root privileges. Re-running with pkexec...")
    os.execv('/usr/bin/pkexec', ['pkexec', 'python3'] + sys.argv)

class SecurityAuditApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.initUI()
    
    def initUI(self):
        self.setWindowTitle('AutoSysGuard - Auditing Tool')
        self.setGeometry(100, 100, 800, 600)

        self.central_widget = QWidget(self)
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)
        
        self.process = None  # For running bash scripts

        self.output_display = QTextEdit(self)
        self.output_display.setReadOnly(True)
        self.layout.addWidget(self.output_display)

        menubar = self.menuBar()

        # Initial Setup Menu
        initial_setup_menu = menubar.addMenu('Initial Setup')
        initial_setup_menu.addAction(self.create_action('Initial Setup Audit', self.run_initial_setup))
        filesystem_menu = initial_setup_menu.addMenu('Filesystem Configuration')
        filesystem_menu.addAction(self.create_action('Disable Unused Filesystems', self.run_filesystem_config))
        filesystem_menu.addAction(self.create_action('Filesystem Integrity Checking', self.run_filesystem_integrity))
        filesystem_menu.addAction(self.create_action('Software and Patch Management', self.run_patch_management))
        initial_setup_menu.addAction(self.create_action('Secure Boot Settings', self.run_boot_settings))
        initial_setup_menu.addAction(self.create_action('Additional Process Hardening', self.run_process_hardening))
        initial_setup_menu.addAction(self.create_action('Mandatory Access Control', self.run_mac))
        initial_setup_menu.addAction(self.create_action('Command Line Warning Banners', self.run_banners))
        initial_setup_menu.addAction(self.create_action('GNOME Display Manager', self.run_gdm))

        # Services Menu
        services_menu = menubar.addMenu('Services')
        services_menu.addAction(self.create_action('Time Synchronization', self.run_time_sync))
        special_services_menu = services_menu.addMenu('Special Purpose Services')
        special_services_menu.addAction(self.create_action('Ensure NIS Server is not installed', self.run_nis_server))
        special_services_menu.addAction(self.create_action('Ensure dnsmasq is not installed', self.run_dnsmasq))
        special_services_menu.addAction(self.create_action('Ensure mail transfer agent is configured for local-only mode', self.run_mail_transfer_agent))
        special_services_menu.addAction(self.create_action('Ensure rsync service is either not installed or is masked', self.run_rsync))
        special_services_menu.addAction(self.create_action('Ensure nonessential services are removed or masked', self.run_nonessential_services))

        service_clients_menu = services_menu.addMenu('Service Clients')
        service_clients_menu.addAction(self.create_action('Ensure NIS Client is not installed', self.run_nis_client))
        service_clients_menu.addAction(self.create_action('Ensure rsh client is not installed', self.run_rsh_client))
        service_clients_menu.addAction(self.create_action('Ensure talk client is not installed', self.run_talk_client))
        service_clients_menu.addAction(self.create_action('Ensure telnet client is not installed', self.run_telnet_client))
        service_clients_menu.addAction(self.create_action('Ensure LDAP client is not installed', self.run_ldap_client))
        service_clients_menu.addAction(self.create_action('Ensure RPC is not installed', self.run_rpc))

        # Network Configuration Menu
        network_menu = menubar.addMenu('Network Configuration')
        network_menu.addAction(self.create_action('Disable Unused Network Protocols', self.run_unused_network_protocols))
        network_parameters_menu = network_menu.addMenu('Network Parameters (Host Only)')
        network_parameters_menu.addAction(self.create_action('Ensure packet redirect sending is disabled', self.run_packet_redirect))
        network_parameters_menu.addAction(self.create_action('Ensure IP forwarding is disabled', self.run_ip_forwarding))

        network_parameters_router_menu = network_menu.addMenu('Network Parameters (Host and Router)')
        network_parameters_router_menu.addAction(self.create_action('Ensure source routed packets are not accepted', self.run_source_routed_packets))
        network_parameters_router_menu.addAction(self.create_action('Ensure ICMP redirects are not accepted', self.run_icmp_redirects))
        network_parameters_router_menu.addAction(self.create_action('Ensure secure ICMP redirects are not accepted', self.run_secure_icmp))
        network_parameters_router_menu.addAction(self.create_action('Ensure suspicious packets are logged', self.run_suspicious_packets))
        network_parameters_router_menu.addAction(self.create_action('Ensure broadcast ICMP requests are ignored', self.run_broadcast_icmp))
        network_parameters_router_menu.addAction(self.create_action('Ensure bogus ICMP responses are ignored', self.run_bogus_icmp))
        network_parameters_router_menu.addAction(self.create_action('Ensure Reverse Path Filtering is enabled', self.run_reverse_path_filtering))
        network_parameters_router_menu.addAction(self.create_action('Ensure TCP SYN Cookies is enabled', self.run_tcp_syn_cookies))
        network_parameters_router_menu.addAction(self.create_action('Ensure IPv6 router advertisements are not accepted', self.run_ipv6_router_ads))

        # Firewall Configuration Menu
        firewall_menu = network_menu.addMenu('Firewall Configuration')
        ufw_menu = firewall_menu.addMenu('Configure UncomplicatedFirewall')
        ufw_menu.addAction(self.create_action('Ensure ufw is installed', self.run_ufw_installed))
        ufw_menu.addAction(self.create_action('Ensure iptables-persistent is not installed with ufw', self.run_iptables_persistent))
        ufw_menu.addAction(self.create_action('Ensure ufw service is enabled', self.run_ufw_service_enabled))
        ufw_menu.addAction(self.create_action('Ensure ufw loopback traffic is configured', self.run_ufw_loopback))
        ufw_menu.addAction(self.create_action('Ensure ufw outbound connections are configured', self.run_ufw_outbound))
        ufw_menu.addAction(self.create_action('Ensure ufw firewall rules exist for all open ports', self.run_ufw_rules))
        ufw_menu.addAction(self.create_action('Ensure ufw default deny firewall policy', self.run_ufw_default_deny))

        nftables_menu = firewall_menu.addMenu('Configure nftables')
        nftables_menu.addAction(self.create_action('Ensure nftables is installed', self.run_nftables_installed))
        nftables_menu.addAction(self.create_action('Ensure ufw is uninstalled or disabled with nftables', self.run_nftables_ufw))
        nftables_menu.addAction(self.create_action('Ensure iptables are flushed with nftables', self.run_nftables_flushed))
        nftables_menu.addAction(self.create_action('Ensure a nftables table exists', self.run_nftables_table))
        nftables_menu.addAction(self.create_action('Ensure nftables base chains exist', self.run_nftables_chains))
        nftables_menu.addAction(self.create_action('Ensure nftables loopback traffic is configured', self.run_nftables_loopback))
        nftables_menu.addAction(self.create_action('Ensure nftables outbound and established connections are configured', self.run_nftables_outbound))
        nftables_menu.addAction(self.create_action('Ensure nftables default deny firewall policy', self.run_nftables_default_deny))
        nftables_menu.addAction(self.create_action('Ensure nftables service is enabled', self.run_nftables_service))
        nftables_menu.addAction(self.create_action('Ensure nftables rules are permanent', self.run_nftables_rules))

        iptables_menu = firewall_menu.addMenu('Configure iptables')
        iptables_menu.addAction(self.create_action('Ensure iptables packages are installed', self.run_iptables_installed))
        iptables_menu.addAction(self.create_action('Ensure nftables is not installed with iptables', self.run_iptables_nftables))
        iptables_menu.addAction(self.create_action('Ensure ufw is uninstalled or disabled with iptables', self.run_iptables_ufw))
        iptables_menu.addAction(self.create_action('Ensure iptables default deny firewall policy', self.run_iptables_default_deny))
        iptables_menu.addAction(self.create_action('Ensure iptables loopback traffic is configured', self.run_iptables_loopback))
        iptables_menu.addAction(self.create_action('Ensure iptables outbound and established connections are configured', self.run_iptables_outbound))
        iptables_menu.addAction(self.create_action('Ensure iptables firewall rules exist for all open ports', self.run_iptables_rules))
        iptables_menu.addAction(self.create_action('Ensure ip6tables default deny firewall policy', self.run_ip6tables_default_deny))
        iptables_menu.addAction(self.create_action('Ensure ip6tables loopback traffic is configured', self.run_ip6tables_loopback))
        iptables_menu.addAction(self.create_action('Ensure ip6tables outbound and established connections are configured', self.run_ip6tables_outbound))
        iptables_menu.addAction(self.create_action('Ensure ip6tables firewall rules exist for all open ports', self.run_ip6tables_rules))

        # Access, Authentication and Authorization Menu
        access_menu = menubar.addMenu('Access, Authentication and Authorization')
        access_menu.addAction(self.create_action('Configure Time-based Job Schedulers', self.run_time_based_job_schedulers))
        ssh_menu = access_menu.addMenu('Configure SSH Server')
        ssh_menu.addAction(self.create_action('Ensure permissions on /etc/ssh/sshd_config are configured', self.run_sshd_config))
        ssh_menu.addAction(self.create_action('Ensure permissions on SSH private host key files are configured', self.run_ssh_private_key_permissions))
        ssh_menu.addAction(self.create_action('Ensure permissions on SSH public host key files are configured', self.run_ssh_public_key_permissions))
        ssh_menu.addAction(self.create_action('Ensure SSH access is limited', self.run_ssh_access_limited))
        ssh_menu.addAction(self.create_action('Ensure SSH LogLevel is appropriate', self.run_ssh_loglevel))
        ssh_menu.addAction(self.create_action('Ensure SSH PAM is enabled', self.run_ssh_pam))
        ssh_menu.addAction(self.create_action('Ensure SSH root login is disabled', self.run_ssh_root_login))
        ssh_menu.addAction(self.create_action('Ensure SSH HostbasedAuthentication is disabled', self.run_ssh_host_based_authentication))
        ssh_menu.addAction(self.create_action('Ensure SSH PermitEmptyPasswords is disabled', self.run_ssh_permit_empty_passwords))
        ssh_menu.addAction(self.create_action('Ensure SSH PermitUserEnvironment is disabled', self.run_ssh_permit_user_environment))
        ssh_menu.addAction(self.create_action('Ensure SSH IgnoreRhosts is enabled', self.run_ssh_ignore_rhosts))
        ssh_menu.addAction(self.create_action('Ensure SSH X11 forwarding is disabled', self.run_ssh_x11_forwarding))
        ssh_menu.addAction(self.create_action('Ensure only strong Ciphers are used', self.run_ssh_strong_ciphers))
        ssh_menu.addAction(self.create_action('Ensure only strong MAC algorithms are used', self.run_ssh_strong_mac))
        ssh_menu.addAction(self.create_action('Ensure only strong Key Exchange algorithms are used', self.run_ssh_strong_key_exchange))
        ssh_menu.addAction(self.create_action('Ensure SSH AllowTcpForwarding is disabled', self.run_ssh_allow_tcp_forwarding))
        ssh_menu.addAction(self.create_action('Ensure SSH warning banner is configured', self.run_ssh_warning_banner))
        ssh_menu.addAction(self.create_action('Ensure SSH MaxAuthTries is set to 4 or less', self.run_ssh_max_auth_tries))
        ssh_menu.addAction(self.create_action('Ensure SSH MaxStartups is configured', self.run_ssh_max_startups))
        ssh_menu.addAction(self.create_action('Ensure SSH LoginGraceTime is set to one minute or less', self.run_ssh_login_grace_time))
        ssh_menu.addAction(self.create_action('Ensure SSH MaxSessions is set to 10 or less', self.run_ssh_max_sessions))
        ssh_menu.addAction(self.create_action('Ensure SSH Idle Timeout Interval is configured', self.run_ssh_idle_timeout))

        privilege_escalation_menu = access_menu.addMenu('Configure Privilege Escalation')
        privilege_escalation_menu.addAction(self.create_action('Ensure sudo is installed', self.run_sudo_installed))
        privilege_escalation_menu.addAction(self.create_action('Ensure sudo commands use pty', self.run_sudo_use_ptty))
        privilege_escalation_menu.addAction(self.create_action('Ensure sudo log file exists', self.run_sudo_log_exists))
        privilege_escalation_menu.addAction(self.create_action('Ensure users must provide password for privilege escalation', self.run_sudo_password_required))
        privilege_escalation_menu.addAction(self.create_action('Ensure re-authentication for privilege escalation is not disabled globally', self.run_sudo_re_authentication))
        privilege_escalation_menu.addAction(self.create_action('Ensure sudo authentication timeout is configured correctly', self.run_sudo_auth_timeout))
        privilege_escalation_menu.addAction(self.create_action('Ensure access to the su command is restricted', self.run_su_restricted))

        pam_menu = access_menu.addMenu('Configure PAM')
        pam_menu.addAction(self.create_action('Ensure password creation requirements are configured', self.run_pam_password_requirements))
        pam_menu.addAction(self.create_action('Ensure lockout for failed password attempts is configured', self.run_pam_lockout))
        pam_menu.addAction(self.create_action('Ensure password reuse is limited', self.run_pam_password_reuse))
        pam_menu.addAction(self.create_action('Ensure strong password hashing algorithm is configured', self.run_pam_password_hashing))
        pam_menu.addAction(self.create_action('Ensure all current passwords use the configured hashing algorithm', self.run_pam_current_passwords))

        user_accounts_menu = access_menu.addMenu('User Accounts and Environment')
        user_accounts_menu.addAction(self.create_action('Set Shadow Password Suite Parameters', self.run_shadow_password_parameters))
        user_accounts_menu.addAction(self.create_action('Ensure system accounts are secured', self.run_system_accounts_secured))
        user_accounts_menu.addAction(self.create_action('Ensure default group for the root account is GID 0', self.run_default_group_root))
        user_accounts_menu.addAction(self.create_action('Ensure default user umask is 027 or more restrictive', self.run_default_user_umask))
        user_accounts_menu.addAction(self.create_action('Ensure default user shell timeout is configured', self.run_default_user_shell_timeout))
        user_accounts_menu.addAction(self.create_action('Ensure nologin is not listed in /etc/shells', self.run_nologin_not_in_shells))
        user_accounts_menu.addAction(self.create_action('Ensure maximum number of same consecutive characters in a password is configured', self.run_max_consecutive_characters))

        # Logging and Auditing Menu
        logging_menu = menubar.addMenu('Logging and Auditing')

        journald_menu = logging_menu.addMenu('Configure journald')
        journald_menu.addAction(self.create_action('Ensure systemd-journal-remote is installed', self.run_systemd_journal_remote_installed))
        journald_menu.addAction(self.create_action('Ensure systemd-journal-remote is configured', self.run_systemd_journal_remote_configured))
        journald_menu.addAction(self.create_action('Ensure systemd-journal-remote is enabled', self.run_systemd_journal_remote_enabled))
        journald_menu.addAction(self.create_action('Ensure journald is not configured to receive logs from a remote client', self.run_journald_no_remote_logs))
        journald_menu.addAction(self.create_action('Ensure journald service is enabled', self.run_journald_service_enabled))
        journald_menu.addAction(self.create_action('Ensure journald is configured to compress large log files', self.run_journald_compress_logs))
        journald_menu.addAction(self.create_action('Ensure journald writes logs to persistent disk', self.run_journald_persistent_logs))
        journald_menu.addAction(self.create_action('Ensure journald is not configured to send logs to rsyslog', self.run_journald_no_rsyslog))
        journald_menu.addAction(self.create_action('Ensure journald log rotation is configured per site policy', self.run_journald_log_rotation))
        journald_menu.addAction(self.create_action('Ensure journald default file permissions are configured', self.run_journald_file_permissions))

        rsyslog_menu = logging_menu.addMenu('Configure rsyslog')
        rsyslog_menu.addAction(self.create_action('Ensure rsyslog is installed', self.run_rsyslog_installed))
        rsyslog_menu.addAction(self.create_action('Ensure rsyslog service is enabled', self.run_rsyslog_service_enabled))
        rsyslog_menu.addAction(self.create_action('Ensure journald is configured to send logs to rsyslog', self.run_journald_send_rsyslog))
        rsyslog_menu.addAction(self.create_action('Ensure rsyslog default file permissions are configured', self.run_rsyslog_file_permissions))
        rsyslog_menu.addAction(self.create_action('Ensure logging is configured', self.run_rsyslog_logging_configured))
        rsyslog_menu.addAction(self.create_action('Ensure rsyslog sends logs to remote log host', self.run_rsyslog_remote_logs))
        rsyslog_menu.addAction(self.create_action('Ensure rsyslog is not configured to receive logs from a remote client', self.run_rsyslog_no_remote_logs))

        logging_menu.addAction(self.create_action('Ensure all log files have appropriate access configured', self.run_log_files_access))

        # Auditd Configuration
        auditd_menu = menubar.addMenu('Configure auditd')

        auditd_menu.addAction(self.create_action('Ensure auditd is installed', self.run_auditd_installed))
        auditd_menu.addAction(self.create_action('Ensure auditd service is enabled and active', self.run_auditd_service_enabled))
        auditd_menu.addAction(self.create_action('Ensure auditing for processes prior to auditd is enabled', self.run_auditd_preprocess_audit))
        auditd_menu.addAction(self.create_action('Ensure audit_backlog_limit is sufficient', self.run_auditd_backlog_limit))

        data_retention_menu = auditd_menu.addMenu('Configure Data Retention')
        data_retention_menu.addAction(self.create_action('Ensure audit log storage size is configured', self.run_auditd_log_storage))
        data_retention_menu.addAction(self.create_action('Ensure audit logs are not automatically deleted', self.run_auditd_no_auto_delete))
        data_retention_menu.addAction(self.create_action('Ensure system is disabled when audit logs are full', self.run_auditd_system_disabled))

        auditd_rules_menu = auditd_menu.addMenu('Configure auditd rules')
        auditd_rules_menu.addAction(self.create_action('Ensure sudoers changes are collected', self.run_auditd_collect_sudoers_changes))
        auditd_rules_menu.addAction(self.create_action('Ensure user actions are logged', self.run_auditd_user_actions))
        auditd_rules_menu.addAction(self.create_action('Ensure events modifying sudo log file are collected', self.run_auditd_sudo_log_events))
        auditd_rules_menu.addAction(self.create_action('Ensure date/time modification events are collected', self.run_auditd_time_modification))
        auditd_rules_menu.addAction(self.create_action('Ensure network environment modifications are collected', self.run_auditd_network_modifications))
        auditd_rules_menu.addAction(self.create_action('Ensure privileged commands usage is collected', self.run_auditd_privileged_commands))
        auditd_rules_menu.addAction(self.create_action('Ensure unsuccessful file access attempts are collected', self.run_auditd_unsuccessful_file_access))
        auditd_rules_menu.addAction(self.create_action('Ensure user/group information modification events are collected', self.run_auditd_user_group_modifications))
        auditd_rules_menu.addAction(self.create_action('Ensure DAC permission modifications are collected', self.run_auditd_dac_modifications))
        auditd_rules_menu.addAction(self.create_action('Ensure filesystem mounts are collected', self.run_auditd_filesystem_mounts))
        auditd_rules_menu.addAction(self.create_action('Ensure session initiation info is collected', self.run_auditd_session_info))
        auditd_rules_menu.addAction(self.create_action('Ensure login/logout events are collected', self.run_auditd_login_logout))
        auditd_rules_menu.addAction(self.create_action('Ensure file deletion events by users are collected', self.run_auditd_file_deletion))
        auditd_rules_menu.addAction(self.create_action('Ensure MAC modification events are collected', self.run_auditd_mac_modification))
        auditd_rules_menu.addAction(self.create_action('Ensure chcon command usage is recorded', self.run_auditd_chcon_usage))
        auditd_rules_menu.addAction(self.create_action('Ensure setfacl command usage is recorded', self.run_auditd_setfacl_usage))
        auditd_rules_menu.addAction(self.create_action('Ensure chacl command usage is recorded', self.run_auditd_chacl_usage))
        auditd_rules_menu.addAction(self.create_action('Ensure usermod command usage is recorded', self.run_auditd_usermod_usage))
        auditd_rules_menu.addAction(self.create_action('Ensure kernel module modifications are collected', self.run_auditd_kernel_module_modifications))
        auditd_rules_menu.addAction(self.create_action('Ensure auditd configuration is immutable', self.run_auditd_config_immutable))
        auditd_rules_menu.addAction(self.create_action('Ensure running and on-disk auditd configuration is the same', self.run_auditd_config_consistency))

        auditd_menu.addAction(self.create_action('Ensure audit log files are mode 0640 or less permissive', self.run_auditd_log_file_permissions))
        auditd_menu.addAction(self.create_action('Ensure only authorized users own audit log files', self.run_auditd_log_file_ownership))
        auditd_menu.addAction(self.create_action('Ensure audit tools are 755 or more restrictive', self.run_audit_tools_permissions))

        # System Maintenance Menu
        maintenance_menu = menubar.addMenu('System Maintenance')

        maintenance_menu.addAction(self.create_action('Ensure permissions on /etc/passwd are configured', self.run_passwd_permissions))
        maintenance_menu.addAction(self.create_action('Ensure permissions on /etc/shadow are configured', self.run_shadow_permissions))
        maintenance_menu.addAction(self.create_action('Ensure no duplicate UIDs exist', self.run_check_duplicate_uids))
        maintenance_menu.addAction(self.create_action('Ensure no duplicate GIDs exist', self.run_check_duplicate_gids))
        maintenance_menu.addAction(self.create_action('Ensure no duplicate user names exist', self.run_check_duplicate_usernames))
        maintenance_menu.addAction(self.create_action('Ensure no unowned or ungrouped files or directories exist', self.run_check_unowned_files))
        maintenance_menu.addAction(self.create_action('Ensure SUID and SGID files are reviewed', self.run_check_suid_sgid_files))
        maintenance_menu.addAction(self.create_action('Ensure world writable files are secured', self.run_secure_world_writable_files))


        self.setMenuBar(menubar)

    def create_action(self, title, slot):
        action = QAction(title, self)
        action.triggered.connect(slot)
        return action

    def run_initial_setup(self):
        self.output_display.append("Running Initial Setup Audit...")
    
    def run_filesystem_config(self):
        self.output_display.append("Running Filesystem Configuration Audit...")
    
    def run_filesystem_integrity(self):
        self.output_display.append("Running Filesystem Integrity Checking Audit...")
    
    def run_patch_management(self):
        self.output_display.append("Running Software and Patch Management Audit...")
    
    def run_boot_settings(self):
        self.output_display.append("Running Secure Boot Settings Audit...")
    
    def run_process_hardening(self):
        self.output_display.append("Running Additional Process Hardening Audit...")
    
    def run_mac(self):
        self.output_display.append("Running Mandatory Access Control Audit...")
    
    def run_banners(self):
        self.output_display.append("Running Command Line Warning Banners Audit...")
    
    def run_gdm(self):
        self.output_display.append("Running GNOME Display Manager Audit...")
    
    def run_time_sync(self):
        self.output_display.append("Running Time Synchronization Audit...")
    
    def run_nis_server(self):
        self.output_display.append("Running NIS Server Audit...")
    
    def run_dnsmasq(self):
        self.output_display.append("Running dnsmasq Audit...")
    
    def run_mail_transfer_agent(self):
        self.output_display.append("Running Mail Transfer Agent Audit...")
    
    def run_rsync(self):
        self.output_display.append("Running rsync Service Audit...")
    
    def run_nonessential_services(self):
        self.output_display.append("Running Nonessential Services Audit...")
    
    def run_nis_client(self):
        self.output_display.append("Running NIS Client Audit...")
    
    def run_rsh_client(self):
        self.output_display.append("Running RSH Client Audit...")
    
    def run_talk_client(self):
        self.output_display.append("Running Talk Client Audit...")
    
    def run_telnet_client(self):
        self.output_display.append("Running Telnet Client Audit...")
    
    def run_ldap_client(self):
        self.output_display.append("Running LDAP Client Audit...")
    
    def run_rpc(self):
        self.output_display.append("Running RPC Audit...")
    
    def run_unused_network_protocols(self):
        self.output_display.append("Running Unused Network Protocols Audit...")
    
    def run_packet_redirect(self):
        self.output_display.append("Running Packet Redirect Sending Audit...")
    
    def run_ip_forwarding(self):
        self.output_display.append("Running IP Forwarding Audit...")
    
    def run_source_routed_packets(self):
        self.output_display.append("Running Source Routed Packets Audit...")
    
    def run_icmp_redirects(self):
        self.output_display.append("Running ICMP Redirects Audit...")
    
    def run_secure_icmp(self):
        self.output_display.append("Running Secure ICMP Redirects Audit...")
    
    def run_suspicious_packets(self):
        self.output_display.append("Running Suspicious Packets Audit...")
    
    def run_broadcast_icmp(self):
        self.output_display.append("Running Broadcast ICMP Requests Audit...")
    
    def run_bogus_icmp(self):
        self.output_display.append("Running Bogus ICMP Responses Audit...")
    
    def run_reverse_path_filtering(self):
        self.output_display.append("Running Reverse Path Filtering Audit...")
    
    def run_tcp_syn_cookies(self):
        self.output_display.append("Running TCP SYN Cookies Audit...")
    
    def run_ipv6_router_ads(self):
        self.output_display.append("Running IPv6 Router Advertisements Audit...")
    
    def run_ufw_installed(self):
        self.output_display.append("Running UFW Installed Audit...")
    
    def run_iptables_persistent(self):
        self.output_display.append("Running IPTables Persistent Audit...")
    
    def run_ufw_service_enabled(self):
        self.output_display.append("Running UFW Service Enabled Audit...")
    
    def run_ufw_loopback(self):
        self.output_display.append("Running UFW Loopback Traffic Audit...")
    
    def run_ufw_outbound(self):
        self.output_display.append("Running UFW Outbound Connections Audit...")
    
    def run_ufw_rules(self):
        self.output_display.append("Running UFW Firewall Rules Audit...")
    
    def run_ufw_default_deny(self):
        self.output_display.append("Running UFW Default Deny Firewall Policy Audit...")
    
    def run_nftables_installed(self):
        self.output_display.append("Running Nftables Installed Audit...")
    
    def run_nftables_ufw(self):
        self.output_display.append("Running UFW Uninstalled or Disabled with Nftables Audit...")
    
    def run_nftables_flushed(self):
        self.output_display.append("Running IPTables Flushed with Nftables Audit...")
    
    def run_nftables_table(self):
        self.output_display.append("Running Nftables Table Exists Audit...")
    
    def run_nftables_chains(self):
        self.output_display.append("Running Nftables Base Chains Exist Audit...")
    
    def run_nftables_loopback(self):
        self.output_display.append("Running Nftables Loopback Traffic Audit...")
    
    def run_nftables_outbound(self):
        self.output_display.append("Running Nftables Outbound and Established Connections Audit...")
    
    def run_nftables_default_deny(self):
        self.output_display.append("Running Nftables Default Deny Firewall Policy Audit...")
    
    def run_nftables_service(self):
        self.output_display.append("Running Nftables Service Enabled Audit...")
    
    def run_nftables_rules(self):
        self.output_display.append("Running Nftables Rules Permanent Audit...")
    
    def run_iptables_installed(self):
        self.output_display.append("Running Iptables Installed Audit...")
    
    def run_iptables_nftables(self):
        self.output_display.append("Running Nftables Not Installed with Iptables Audit...")
    
    def run_iptables_ufw(self):
        self.output_display.append("Running UFW Uninstalled or Disabled with Iptables Audit...")
    
    def run_iptables_default_deny(self):
        self.output_display.append("Running Iptables Default Deny Firewall Policy Audit...")
    
    def run_iptables_loopback(self):
        self.output_display.append("Running Iptables Loopback Traffic Audit...")
    
    def run_iptables_outbound(self):
        self.output_display.append("Running Iptables Outbound and Established Connections Audit...")
    
    def run_iptables_rules(self):
        self.output_display.append("Running Iptables Firewall Rules Audit...")
    
    def run_ip6tables_default_deny(self):
        self.output_display.append("Running IP6Tables Default Deny Firewall Policy Audit...")
    
    def run_ip6tables_loopback(self):
        self.output_display.append("Running IP6Tables Loopback Traffic Audit...")
    
    def run_ip6tables_outbound(self):
        self.output_display.append("Running IP6Tables Outbound and Established Connections Audit...")
    
    def run_ip6tables_rules(self):
        self.output_display.append("Running IP6Tables Firewall Rules Audit...")
    
    def run_cron_enabled(self):
        self.output_display.append("Running Cron Daemon Enabled and Active Audit...")
    
    def run_crontab_permissions(self):
        self.output_display.append("Running /etc/crontab Permissions Audit...")
    
    def run_cron_hourly_permissions(self):
        self.output_display.append("Running /etc/cron.hourly Permissions Audit...")
    
    def run_cron_daily_permissions(self):
        self.output_display.append("Running /etc/cron.daily Permissions Audit...")
    
    def run_cron_weekly_permissions(self):
        self.output_display.append("Running /etc/cron.weekly Permissions Audit...")
    
    def run_cron_monthly_permissions(self):
        self.output_display.append("Running /etc/cron.monthly Permissions Audit...")
    
    def run_cron_d_permissions(self):
        self.output_display.append("Running /etc/cron.d Permissions Audit...")
    
    def run_cron_restricted_users(self):
        self.output_display.append("Running Cron Restricted to Authorized Users Audit...")
    
    def run_at_restricted_users(self):
        self.output_display.append("Running At Restricted to Authorized Users Audit...")
    
    def run_time_based_job_schedulers(self):
        self.output_display.append("Running Time-based Job Schedulers Audit...")

    def run_sshd_config(self):
        self.output_display.append("Checking /etc/ssh/sshd_config permissions...")

    def run_ssh_permissions(self):
        self.output_display.append("Running SSH Daemon Configuration Permissions Audit...")
    
    def run_ssh_private_key_permissions(self):
        self.output_display.append("Running SSH Private Host Key Files Permissions Audit...")
    
    def run_ssh_public_key_permissions(self):
        self.output_display.append("Running SSH Public Host Key Files Permissions Audit...")
    
    def run_ssh_access_limited(self):
        self.output_display.append("Running SSH Access Limited Audit...")
    
    def run_ssh_loglevel(self):
        self.output_display.append("Running SSH LogLevel Audit...")
    
    def run_ssh_pam(self):
        self.output_display.append("Running SSH PAM Enabled Audit...")
    
    def run_ssh_root_login(self):
        self.output_display.append("Running SSH Root Login Disabled Audit...")
    
    def run_ssh_host_based_authentication(self):
        self.output_display.append("Running SSH Hostbased Authentication Disabled Audit...")
    
    def run_ssh_permit_empty_passwords(self):
        self.output_display.append("Running SSH Permit Empty Passwords Disabled Audit...")
    
    def run_ssh_permit_user_environment(self):
        self.output_display.append("Running SSH Permit User Environment Disabled Audit...")
    
    def run_ssh_ignore_rhosts(self):
        self.output_display.append("Running SSH Ignore Rhosts Enabled Audit...")
    
    def run_ssh_x11_forwarding(self):
        self.output_display.append("Running SSH X11 Forwarding Disabled Audit...")
    
    def run_ssh_strong_ciphers(self):
        self.output_display.append("Running SSH Strong Ciphers Audit...")
    
    def run_ssh_strong_mac(self):
        self.output_display.append("Running SSH Strong MAC Algorithms Audit...")
    
    def run_ssh_strong_key_exchange(self):
        self.output_display.append("Running SSH Strong Key Exchange Algorithms Audit...")
    
    def run_ssh_allow_tcp_forwarding(self):
        self.output_display.append("Running SSH AllowTcpForwarding Disabled Audit...")
    
    def run_ssh_warning_banner(self):
        self.output_display.append("Running SSH Warning Banner Configured Audit...")
    
    def run_ssh_max_auth_tries(self):
        self.output_display.append("Running SSH MaxAuthTries Set to 4 or Less Audit...")
    
    def run_ssh_max_startups(self):
        self.output_display.append("Running SSH MaxStartups Configured Audit...")
    
    def run_ssh_login_grace_time(self):
        self.output_display.append("Running SSH LoginGraceTime Set to One Minute or Less Audit...")
    
    def run_ssh_max_sessions(self):
        self.output_display.append("Running SSH MaxSessions Set to 10 or Less Audit...")
    
    def run_ssh_idle_timeout(self):
        self.output_display.append("Running SSH Idle Timeout Interval Configured Audit...")
    
    def run_sudo_installed(self):
        self.output_display.append("Running Sudo Installed Audit...")
    
    def run_sudo_use_ptty(self):
        self.output_display.append("Running Sudo Commands Use Pty Audit...")
    
    def run_sudo_log_exists(self):
        self.output_display.append("Running Sudo Log File Exists Audit...")
    
    def run_sudo_password_required(self):
        self.output_display.append("Running Users Must Provide Password for Privilege Escalation Audit...")
    
    def run_sudo_re_authentication(self):
        self.output_display.append("Running Re-authentication for Privilege Escalation Not Disabled Globally Audit...")
    
    def run_sudo_auth_timeout(self):
        self.output_display.append("Running Sudo Authentication Timeout Configured Correctly Audit...")
    
    def run_su_restricted(self):
        self.output_display.append("Running Access to the Su Command Restricted Audit...")
    
    def run_pam_password_requirements(self):
        self.output_display.append("Running Password Creation Requirements Configured Audit...")
    
    def run_pam_lockout(self):
        self.output_display.append("Running Lockout for Failed Password Attempts Configured Audit...")
    
    def run_pam_password_reuse(self):
        self.output_display.append("Running Password Reuse Limited Audit...")
    
    def run_pam_password_hashing(self):
        self.output_display.append("Running Strong Password Hashing Algorithm Configured Audit...")
    
    def run_pam_current_passwords(self):
        self.output_display.append("Running All Current Passwords Use Configured Hashing Algorithm Audit...")
    
    def run_shadow_password_parameters(self):
        self.output_display.append("Running Shadow Password Suite Parameters Set Audit...")
    
    def run_system_accounts_secured(self):
        self.output_display.append("Running System Accounts Secured Audit...")
    
    def run_default_group_root(self):
        self.output_display.append("Running Default Group for Root Account GID 0 Audit...")
    
    def run_default_user_umask(self):
        self.output_display.append("Running Default User Umask 027 or More Restrictive Audit...")
    
    def run_default_user_shell_timeout(self):
        self.output_display.append("Running Default User Shell Timeout Configured Audit...")
    
    def run_nologin_not_in_shells(self):
        self.output_display.append("Running Nologin Not Listed in /etc/shells Audit...")
    
    def run_max_consecutive_characters(self):
        self.output_display.append("Running Maximum Number of Same Consecutive Characters in Password Configured Audit...")

    def run_systemd_journal_remote_installed(self):
        self.output_display.append("Checking if systemd-journal-remote is installed...")

    def run_systemd_journal_remote_configured(self):
        self.output_display.append("Checking if systemd-journal-remote is configured...")

    def run_systemd_journal_remote_enabled(self):
        self.output_display.append("Checking if systemd-journal-remote is enabled...")

    def run_journald_no_remote_logs(self):
        self.output_display.append("Ensuring journald is not configured to receive logs from a remote client...")

    def run_journald_service_enabled(self):
        self.output_display.append("Checking if journald service is enabled...")

    def run_journald_compress_logs(self):
        self.output_display.append("Ensuring journald is configured to compress large log files...")

    def run_journald_persistent_logs(self):
        self.output_display.append("Ensuring journald is writing logs to persistent disk...")

    def run_journald_no_rsyslog(self):
        self.output_display.append("Ensuring journald is not configured to send logs to rsyslog...")

    def run_journald_log_rotation(self):
        self.output_display.append("Ensuring journald log rotation is configured per site policy...")

    def run_journald_file_permissions(self):
        self.output_display.append("Ensuring journald default file permissions are configured...")

    def run_rsyslog_installed(self):
        self.output_display.append("Checking if rsyslog is installed...")

    def run_rsyslog_service_enabled(self):
        self.output_display.append("Checking if rsyslog service is enabled...")

    def run_journald_send_rsyslog(self):
        self.output_display.append("Ensuring journald is configured to send logs to rsyslog...")

    def run_rsyslog_file_permissions(self):
        self.output_display.append("Ensuring rsyslog default file permissions are configured...")

    def run_rsyslog_logging_configured(self):
        self.output_display.append("Ensuring logging is configured for rsyslog...")

    def run_rsyslog_remote_logs(self):
        self.output_display.append("Ensuring rsyslog is configured to send logs to a remote log host...")

    def run_rsyslog_no_remote_logs(self):
        self.output_display.append("Ensuring rsyslog is not configured to receive logs from a remote client...")

    def run_log_files_access(self):
        self.output_display.append("Ensuring all log files have appropriate access configured...")

    def run_auditd_installed(self):
        self.output_display.append("Checking if auditd is installed...")

    def run_auditd_service_enabled(self):
        self.output_display.append("Checking if auditd service is enabled and active...")

    def run_auditd_preprocess_audit(self):
        self.output_display.append("Ensuring auditing for processes that start prior to auditd is enabled...")

    def run_auditd_backlog_limit(self):
        self.output_display.append("Ensuring audit_backlog_limit is sufficient...")

    def run_auditd_log_storage(self):
        self.output_display.append("Ensuring audit log storage size is configured...")

    def run_auditd_no_auto_delete(self):
        self.output_display.append("Ensuring audit logs are not automatically deleted...")

    def run_auditd_system_disabled(self):
        self.output_display.append("Ensuring system is disabled when audit logs are full...")

    def run_auditd_collect_sudoers_changes(self):
        self.output_display.append("Ensuring changes to sudoers are collected...")

    def run_auditd_user_actions(self):
        self.output_display.append("Ensuring user actions are always logged...")

    def run_auditd_sudo_log_events(self):
        self.output_display.append("Ensuring sudo log file modification events are collected...")

    def run_auditd_time_modification(self):
        self.output_display.append("Ensuring date and time modification events are collected...")

    def run_auditd_network_modifications(self):
        self.output_display.append("Ensuring network environment modification events are collected...")

    def run_auditd_privileged_commands(self):
        self.output_display.append("Ensuring privileged commands usage is collected...")

    def run_auditd_unsuccessful_file_access(self):
        self.output_display.append("Ensuring unsuccessful file access attempts are collected...")

    def run_auditd_user_group_modifications(self):
        self.output_display.append("Ensuring user/group modification events are collected...")

    def run_auditd_dac_modifications(self):
        self.output_display.append("Ensuring discretionary access control permission modification events are collected...")

    def run_auditd_filesystem_mounts(self):
        self.output_display.append("Ensuring successful filesystem mounts are collected...")

    def run_auditd_session_info(self):
        self.output_display.append("Ensuring session initiation information is collected...")

    def run_auditd_login_logout(self):
        self.output_display.append("Ensuring login and logout events are collected...")

    def run_auditd_file_deletion(self):
        self.output_display.append("Ensuring file deletion events by users are collected...")

    def run_auditd_mac_modification(self):
        self.output_display.append("Ensuring modification events of Mandatory Access Controls are collected...")

    def run_auditd_chcon_usage(self):
        self.output_display.append("Ensuring chcon command usage is recorded...")

    def run_auditd_setfacl_usage(self):
        self.output_display.append("Ensuring setfacl command usage is recorded...")

    def run_auditd_chacl_usage(self):
        self.output_display.append("Ensuring chacl command usage is recorded...")

    def run_auditd_usermod_usage(self):
        self.output_display.append("Ensuring usermod command usage is recorded...")

    def run_auditd_kernel_module_modifications(self):
        self.output_display.append("Ensuring kernel module loading, unloading, and modification is collected...")

    def run_auditd_config_immutable(self):
        self.output_display.append("Ensuring audit configuration is immutable...")

    def run_auditd_config_consistency(self):
        self.output_display.append("Ensuring running and on-disk audit configuration is the same...")

    def run_auditd_log_file_permissions(self):
        self.output_display.append("Ensuring audit log files have appropriate permissions...")

    def run_auditd_log_file_ownership(self):
        self.output_display.append("Ensuring only authorized users own audit log files...")

    def run_audit_tools_permissions(self):
        self.output_display.append("Ensuring audit tools have appropriate permissions...")

    def run_passwd_permissions(self):
        self.output_display.append("Ensuring permissions on /etc/passwd are configured...")

    def run_shadow_permissions(self):
        self.output_display.append("Ensuring permissions on /etc/shadow are configured...")

    def run_check_duplicate_uids(self):
        self.output_display.append("Ensuring no duplicate UIDs exist...")

    def run_check_duplicate_gids(self):
        self.output_display.append("Ensuring no duplicate GIDs exist...")

    def run_check_duplicate_usernames(self):
        self.output_display.append("Ensuring no duplicate usernames exist...")

    def run_check_unowned_files(self):
        self.output_display.append("Ensuring no unowned or ungrouped files exist...")

    def run_check_suid_sgid_files(self):
        self.output_display.append("Ensuring SUID and SGID files are reviewed...")

    def run_secure_world_writable_files(self):
        self.output_display.append("Ensuring world writable files are secured...")


    def display_output(self):
        output = self.process.readAllStandardOutput().data().decode()
        self.output_display.append(output)

# Run the application
if __name__ == '__main__':
    app = QApplication(sys.argv)
    gui = SecurityAuditApp()
    gui.show()
    sys.exit(app.exec_())
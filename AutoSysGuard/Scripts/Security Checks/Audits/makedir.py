import os

def create_structure(base_path, structure):
    for name, contents in structure.items():
        path = os.path.join(base_path, name)
        os.makedirs(path, exist_ok=True)  # Ensure the directory exists
        if isinstance(contents, dict):
            create_structure(path, contents)  # Recursive call for subdirectories
        elif isinstance(contents, list):
            for file_name in contents:
                with open(os.path.join(path, file_name), 'w') as f:
                    f.write('')  # Create an empty file or whatever content is needed
        else:
            # If contents is not a dict or list, it should be a valid filename
            with open(os.path.join(path, contents), 'w') as f:
                f.write('')  # Create an empty file

# Example structure definition
base_dir = "./1_Initial_Setup"
# List of directories and files to create
structure = {
    "1_Initial_Setup": {
        "1.1_Filesystem_Configuration": {
            "1.1.1_Disable_unused_filesystems": [
                "ensure_mounting_of_cramfs_disabled.sh",
                "ensure_mounting_of_freevxfs_disabled.sh",
                "ensure_mounting_of_jffs2_d/bin/python ",
                "ensure_mounting_of_hfs_disabled.sh",
                "ensure_mounting_of_hfsplus_disabled.sh",
                "ensure_mounting_of_squashfs_disabled.sh",
                "ensure_mounting_of_udf_disabled.sh"
            ],
            "1.1.2_Configure_tmp": [
                "ensure_tmp_separate_partition.sh",
                "ensure_tmp_nodev_option.sh",
                "ensure_tmp_noexec_option.sh",
                "ensure_tmp_nosuid_option.sh"
            ],
            "1.1.3_Configure_var": [
                "ensure_var_separate_partition.sh",
                "ensure_var_nodev_option.sh",
                "ensure_var_nosuid_option.sh"
            ],
            "1.1.4_Configure_var_tmp": [
                "ensure_var_tmp_separate_partition.sh",
                "ensure_var_tmp_nodev_option.sh",
                "ensure_var_tmp_noexec_option.sh",
                "ensure_var_tmp_nosuid_option.sh"
            ],
            "1.1.5_Configure_var_log": [
                "ensure_var_log_separate_partition.sh",
                "ensure_var_log_nodev_option.sh",
                "ensure_var_log_noexec_option.sh",
                "ensure_var_log_nosuid_option.sh"
            ],
            "1.1.6_Configure_var_log_audit": [
                "ensure_var_log_audit_separate_partition.sh",
                "ensure_var_log_audit_nodev_option.sh",
                "ensure_var_log_audit_noexec_option.sh",
                "ensure_var_log_audit_nosuid_option.sh"
            ],
            "1.1.7_Configure_home": [
                "ensure_home_separate_partition.sh",
                "ensure_home_nodev_option.sh",
                "ensure_home_nosuid_option.sh"
            ],
            "1.1.8_Configure_dev_shm": [
                "ensure_dev_shm_nodev_option.sh",
                "ensure_dev_shm_noexec_option.sh",
                "ensure_dev_shm_nosuid_option.sh"
            ],
            "1.1.9_Disable_Automounting": [
                "ensure_automounting_disabled.sh"
            ],
            "1.1.10_Disable_USB_Storage": [
                "ensure_usb_storage_disabled.sh"
            ]
        },
        "1.2_Filesystem_Integrity_Checking": [
            "ensure_aide_installed.sh",
            "ensure_filesystem_integrity_checked.sh"
        ],
        "1.3_Configure_Software_and_Patch_Management": [
            "ensure_updates_installed.sh",
            "ensure_package_manager_repositories_configured.sh",
            "ensure_gpg_keys_configured.sh"
        ],
        "1.4_Secure_Boot_Settings": [
            "ensure_bootloader_password_set.sh",
            "ensure_permissions_on_bootloader_config.sh",
            "ensure_authentication_required_for_single_user_mode.sh"
        ],
        "1.5_Additional_Process_Hardening": [
            "ensure_aslr_enabled.sh",
            "ensure_ptrace_scope_restricted.sh",
            "ensure_prelink_not_installed.sh",
            "ensure_auto_error_reporting_not_enabled.sh",
            "ensure_core_dumps_restricted.sh"
        ],
        "1.6_Mandatory_Access_Control": {
            "1.6.1_Configure_AppArmor": [
                "ensure_apparmor_installed.sh",
                "ensure_apparmor_enabled_in_bootloader.sh",
                "ensure_apparmor_profiles_enforcing.sh",
                "ensure_apparmor_profiles_in_enforce_or_complain_mode.sh"
            ]
        },
        "1.7_Command_Line_Warning_Banners": [
            "ensure_message_of_the_day_configured.sh",
            "ensure_local_login_warning_banner_configured.sh",
            "ensure_remote_login_warning_banner_configured.sh",
            "ensure_permissions_on_motd_configured.sh",
            "ensure_permissions_on_issue_configured.sh",
            "ensure_permissions_on_issue_net_configured.sh"
        ],
        "1.8_GNOME_Display_Manager": [
            "ensure_gnome_display_manager_removed.sh",
            "ensure_gdm_login_banner_configured.sh",
            "ensure_gdm_disable_user_list_option_enabled.sh",
            "ensure_gdm_screen_locks_when_idle.sh",
            "ensure_gdm_screen_locks_not_overridden.sh",
            "ensure_gdm_auto_mounting_disabled.sh",
            "ensure_gdm_auto_mounting_not_overridden.sh",
            "ensure_gdm_autorun_never_enabled.sh",
            "ensure_gdm_autorun_never_not_overridden.sh",
            "ensure_xdcmp_not_enabled.sh"
        ]
    },
    "2_Services": {
        "2.1_Configure_Time_Synchronization": [
            "ensure_time_synchronization_in_use.sh",
            "ensure_single_time_sync_daemon_in_use.sh",
            {
                "2.1.2_Configure_chrony": [
                    "ensure_chrony_configured.sh",
                    "ensure_chrony_running_as_user.sh",
                    "ensure_chrony_enabled_running.sh"
                ]
            },
            {
                "2.1.3_Configure_systemd_timesyncd": [
                    "ensure_systemd_timesyncd_configured.sh",
                    "ensure_systemd_timesyncd_enabled_running.sh"
                ]
            },
            {
                "2.1.4_Configure_ntp": [
                    "ensure_ntp_access_control_configured.sh",
                    "ensure_ntp_configured.sh",
                    "ensure_ntp_running_as_user.sh",
                    "ensure_ntp_enabled_running.sh"
                ]
            }
        ],
        "2.2_Special_Purpose_Services": [
            "ensure_x_window_system_not_installed.sh",
            "ensure_avahi_server_not_installed.sh",
            "ensure_cups_not_installed.sh",
            "ensure_dhcp_server_not_installed.sh",
            "ensure_ldap_server_not_installed.sh",
            "ensure_nfs_not_installed.sh",
            "ensure_dns_server_not_installed.sh",
            "ensure_ftp_server_not_installed.sh",
            "ensure_http_server_not_installed.sh",
            "ensure_imap_pop3_server_not_installed.sh",
            "ensure_samba_not_installed.sh",
            "ensure_http_proxy_server_not_installed.sh",
            "ensure_snmp_server_not_installed.sh",
            "ensure_nis_server_not_installed.sh",
            "ensure_dnsmasq_not_installed.sh",
            "ensure_mail_transfer_agent_configured_for_local_only.sh",
            "ensure_rsync_service_not_installed_or_masked.sh"
        ],
        "2.3_Service_Clients": [
            "ensure_nis_client_not_installed.sh",
            "ensure_rsh_client_not_installed.sh",
            "ensure_talk_client_not_installed.sh",
            "ensure_telnet_client_not_installed.sh",
            "ensure_ldap_client_not_installed.sh",
            "ensure_rpc_not_installed.sh"
        ],
        "2.4_Nonessential_Services": [
            "ensure_nonessential_services_removed_or_masked.sh"
        ]
    },
    "3_Network_Configuration": {
        "3.1_Disable_Unused_Network_Protocols_and_Devices": [
            "ensure_ipv6_status_identified.sh",
            "ensure_wireless_interfaces_disabled.sh",
            "ensure_bluetooth_disabled.sh",
            "ensure_dccp_disabled.sh",
            "ensure_sctp_disabled.sh",
            "ensure_rds_disabled.sh",
            "ensure_tipc_disabled.sh"
        ],
        "3.2_Network_Parameters_Host_Only": [
            "ensure_packet_redirect_sending_disabled.sh",
            "ensure_ip_forwarding_disabled.sh"
        ],
        "3.3_Network_Parameters_Host_and_Router": [
            "ensure_source_routed_packets_not_accepted.sh",
            "ensure_icmp_redirects_not_accepted.sh",
            "ensure_secure_icmp_redirects_not_accepted.sh",
            "ensure_suspicious_packets_logged.sh",
            "ensure_broadcast_icmp_requests_ignored.sh",
            "ensure_bogus_icmp_responses_ignored.sh",
            "ensure_reverse_path_filtering_enabled.sh",
            "ensure_tcp_syn_cookies_enabled.sh",
            "ensure_ipv6_router_advertisements_not_accepted.sh"
        ],
        "3.4_Firewall_Configuration": {
            "3.4.1_Configure_UncomplicatedFirewall": [
                "ensure_ufw_installed.sh",
                "ensure_iptables_persistent_not_installed.sh",
                "ensure_ufw_service_enabled.sh",
                "ensure_ufw_loopback_traffic_configured.sh",
                "ensure_ufw_outbound_connections_configured.sh",
                "ensure_ufw_firewall_rules_exist.sh",
                "ensure_ufw_default_deny_policy.sh"
            ],
            "3.4.2_Configure_nftables": [
                "ensure_nftables_installed.sh",
                "ensure_ufw_uninstalled_or_disabled.sh",
                "ensure_iptables_flushed_with_nftables.sh",
                "ensure_nftables_table_exists.sh",
                "ensure_nftables_base_chains_exist.sh",
                "ensure_nftables_loopback_traffic_configured.sh",
                "ensure_nftables_outbound_connections_configured.sh",
                "ensure_nftables_additional_rules_exist.sh"
            ]
        },
        "3.5_Logging_and_Auditing": [
            "ensure_firewall_logging_enabled.sh"
        ]
    },
    "4_Access_Authentication_and_Authorization": {
        "4.1_User_Account_Policies": [
            "ensure_minimum_password_age_set.sh",
            "ensure_maximum_password_age_set.sh",
            "ensure_password_expiration_notified.sh",
            "ensure_password_length_at_least_14.sh",
            "ensure_password_complexity_requirements_enforced.sh",
            "ensure_account_lockout_enabled.sh",
            "ensure_account_lockout_threshold_set.sh",
            "ensure_successful_login_audit_recorded.sh",
            "ensure_failed_login_audit_recorded.sh",
            "ensure_login_failures_recorded.sh",
            "ensure_user_accounts_disabled_or_removed.sh",
            "ensure_root_account_disabled.sh"
        ],
        "4.2_Account_Management": [
            "ensure_account_lockout_policy_configured.sh",
            "ensure_password_reuse_limit_set.sh",
            "ensure_new_users_passwords_not_blank.sh",
            "ensure_last_login_date_enabled.sh",
            "ensure_user_accounts_active.sh"
        ],
        "4.3_Privilege_Management": [
            "ensure_no_root_login_enabled.sh",
            "ensure_sudo_access_controlled.sh",
            "ensure_sudo_no_password_enabled.sh",
            "ensure_no_users_in_sudoers_file.sh",
            "ensure_no_groups_in_sudoers_file.sh",
            "ensure_sudo_command_logging_enabled.sh"
        ]
    },
    "5_Logging_and_Auditing": {
        "5.1_System_Log_Configuration": [
            "ensure_rsyslog_installed.sh",
            "ensure_rsyslog_service_enabled.sh",
            "ensure_rsyslog_remote_logging_configured.sh",
            "ensure_rsyslog_file_permissions_configured.sh"
        ],
        "5.2_Audit_Log_Configuration": [
            "ensure_auditd_installed.sh",
            "ensure_auditd_service_enabled.sh",
            "ensure_auditd_file_permissions_configured.sh",
            "ensure_audit_log_file_max_size_configured.sh",
            "ensure_audit_log_file_retention_days_configured.sh"
        ],
        "5.3_Review_Log_Configuration": [
            "ensure_log_review_audit_enabled.sh",
            "ensure_system_log_review_enabled.sh"
        ]
    },
    "6_System_Maintenance": {
        "6.1_System_File_Permissions": [
            "ensure_permissions_on_etc_passwd_configured.sh",
            "ensure_permissions_on_etc_passwd_dash_configured.sh",
            "ensure_permissions_on_etc_group_configured.sh",
            "ensure_permissions_on_etc_group_dash_configured.sh",
            "ensure_permissions_on_etc_shadow_configured.sh",
            "ensure_permissions_on_etc_shadow_dash_configured.sh",
            "ensure_permissions_on_etc_gshadow_configured.sh",
            "ensure_permissions_on_etc_gshadow_dash_configured.sh",
            "ensure_permissions_on_etc_shells_configured.sh",
            "ensure_permissions_on_etc_opasswd_configured.sh",
            "ensure_world_writable_files_secured.sh",
            "ensure_no_unowned_or_ungrouped_files_exist.sh",
            "ensure_suid_and_sgid_files_reviewed.sh"
        ],
        "6.2_Local_User_and_Group_Settings": [
            "ensure_accounts_use_shadowed_passwords.sh",
            "ensure_shadow_password_fields_not_empty.sh",
            "ensure_all_groups_in_passwd_exist_in_group.sh",
            "ensure_shadow_group_empty.sh",
            "ensure_no_duplicate_uids_exist.sh",
            "ensure_no_duplicate_gids_exist.sh",
            "ensure_no_duplicate_usernames_exist.sh",
            "ensure_no_duplicate_groupnames_exist.sh",
            "ensure_root_path_integrity.sh",
            "ensure_root_only_uid_0_account.sh",
            "ensure_local_interactive_user_home_directories_configured.sh",
            "ensure_local_interactive_user_dot_files_access_configured.sh"
        ]
    }
}
create_structure(base_dir, structure)

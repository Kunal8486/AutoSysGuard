from PyQt5.QtCore import QProcess
import os
import sys
from PyQt5.QtWidgets import QApplication, QMainWindow, QAction, QMenu, QTextEdit, QVBoxLayout, QWidget, QProgressBar, QPushButton
from PyQt5.QtCore import Qt, QTimer
import subprocess

class AutoSysGuard(QMainWindow):
    def __init__(self):
        super().__init__()
        self.initUI()

 # Ensure the script runs with sudo privileges
if os.geteuid() != 0:
    print("This application requires root privileges. Re-running with pkexec...")
    os.execv('/usr/bin/pkexec', ['pkexec', 'python3'] + sys.argv)

class AutoSysGuard(QMainWindow):
    def __init__(self):
        super().__init__()
        self.initUI()
    
    def initUI(self):
        self.setWindowTitle('AutoSysGuard - Automated System Management Tool')
        self.setGeometry(100, 100, 800, 600)

        self.central_widget = QWidget(self)
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)

        self.output_area = QTextEdit(self)
        self.output_area.setReadOnly(True)
        self.layout.addWidget(self.output_area)

        self.progress_bar = QProgressBar(self)
        self.layout.addWidget(self.progress_bar)

        menubar = self.menuBar()

        system_menu = menubar.addMenu('System')
        system_menu.addAction(self.create_menu_action('Run All Scans', self.run_all_scans))
        
        self.process = None  # For running bash scripts

    def initUI(self):
        self.setWindowTitle('AutoSysGuard - Automated System Management Tool')
        self.setGeometry(100, 100, 800, 600)

        self.central_widget = QWidget(self)
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)

        self.output_area = QTextEdit(self)
        self.output_area.setReadOnly(True)
        self.layout.addWidget(self.output_area)

        self.progress_bar = QProgressBar(self)
        self.layout.addWidget(self.progress_bar)

        menubar = self.menuBar()

        system_menu = menubar.addMenu('System')
        system_menu.addAction(self.create_menu_action('Run All Scans', self.run_all_scans))

        network_menu = menubar.addMenu('Network')
        network_menu.addAction(self.create_menu_action('ARP Spoofing Detection', self.run_arp_spoofing_detection))
        network_menu.addAction(self.create_menu_action('Firewall Configuration', self.run_firewall_config))
        network_menu.addAction(self.create_menu_action('Network Traffic Monitor', self.run_network_traffic_monitor))
        network_menu.addAction(self.create_menu_action('Port Scan', self.run_port_scan))
        network_menu.addAction(self.create_menu_action('SSH Hardening', self.run_ssh_hardening))
        network_menu.addAction(self.create_menu_action('Brute Force Detection System', self.run_brute_force_detection_system))
        network_menu.addAction(self.create_menu_action('Intrusion Detection System', self.run_intrusion_detection_system))
        network_menu.addAction(self.create_menu_action('Packet Sniffing Detection', self.run_packet_sniffing_detection))
        network_menu.addAction(self.create_menu_action('DNS Spoofing Detection', self.run_dns_spoofing_detection))
        network_menu.addAction(self.create_menu_action('VPN Configuration Check', self.run_vpn_configuration_check))
        network_menu.addAction(self.create_menu_action('Network Segmentation Audit', self.run_network_segmentation_audit))
        network_menu.addAction(self.create_menu_action('Wireless Network Security Check', self.run_wireless_network_security_check))
        network_menu.addAction(self.create_menu_action('IP Whitelisting Management', self.run_ip_whitelisting_management))
        network_menu.addAction(self.create_menu_action('Rogue DHCP Server Detection', self.run_rogue_dhcp_server_detection))
        network_menu.addAction(self.create_menu_action('MAC Address Filtering', self.run_mac_address_filtering))
        network_menu.addAction(self.create_menu_action('SSL/TLS Configuration Analyzer', self.run_ssl_tls_configuration_analyzer))
        network_menu.addAction(self.create_menu_action('Open Ports and Vulnerability Scanning', self.run_open_ports_vulnerability_scanning))

        security_menu = menubar.addMenu('Security Checks')
        security_menu.addAction(self.create_menu_action('Security Audit', self.run_security_audit))
        security_menu.addAction(self.create_menu_action('Machine Learning Anomaly Detection', self.run_anomaly_detection))
        security_menu.addAction(self.create_menu_action('Compliance Checker', self.run_compliance_checker))
        security_menu.addAction(self.create_menu_action('User Behavior Analytics', self.run_user_behavior_analytics))


        self.backup_button = QPushButton("Run Backup", self)
        self.backup_button.clicked.connect(self.run_backup)
        self.layout.addWidget(self.backup_button)
        
        maintenance_menu = menubar.addMenu('Maintenance')

        monitoring_menu = menubar.addMenu('Monitoring')
        monitoring_menu.addAction(self.create_menu_action("Ram Monitoring", self.ram_monitor))
        monitoring_menu.addAction(self.create_menu_action("CPU Monitoring", self.cpu_monitor))
        monitoring_menu.addAction(self.create_menu_action("Disk Monitoring", self.disk_monitor))


        more_menu = menubar.addMenu('More Functions')
        more_menu.addAction(self.create_menu_action('Setup Intrusion Detection System (IDS)', self.setup_ids))

        self.show()
    
    def create_menu_action(self, name, function):
        action = QAction(name, self)
        action.triggered.connect(function)
        return action

    def update_output(self, text):
        self.output_area.append(text)

    def start_progress(self):
        self.progress_bar.setValue(0)
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_progress)
        self.timer.start(100)

    def update_progress(self):
        current_value = self.progress_bar.value()
        if current_value < 100:
            self.progress_bar.setValue(current_value + 10)
        else:
            self.timer.stop()

    def stop_progress(self):
        self.timer.stop()
        self.progress_bar.setValue(100)

    def run_all_scans(self):
        self.update_output("Running all scans...")
        self.start_progress()
        self.run_arp_spoofing_detection()
        self.run_firewall_config()
        self.run_network_traffic_monitor()
        self.run_port_scan()
        self.run_ssh_hardening()
        self.run_security_audit()
        self.stop_progress()

    def run_arp_spoofing_detection(self):
        self.update_output("Running ARP Spoofing Detection...")
        output = subprocess.getoutput('./scripts/networks/arp_spoofing_detection.sh')
        self.update_output(output)

    def run_firewall_config(self):
        self.update_output("Configuring Firewall...")
        output = subprocess.getoutput('./scripts/networks/firewall_config.sh')
        self.update_output(output)

    def run_network_traffic_monitor(self):
        self.update_output("Monitoring Network Traffic...")
        output = subprocess.getoutput('./scripts/networks/network_traffic_monitor.sh')
        self.update_output(output)

    def run_port_scan(self):
        self.update_output("Running Port Scan...")
        output = subprocess.getoutput('./scripts/networks/port_scan.sh')
        self.update_output(output)

    def run_ssh_hardening(self):
        self.update_output("Hardening SSH...")
        output = subprocess.getoutput('./scripts/networks/ssh_hardening.sh')
        self.update_output(output)
    
    def run_brute_force_detection_system(self):
        self.update_output("Running Brute Force Detection System...")
        try:
            output = subprocess.getoutput('./scripts/networks/brute_force_detection.sh')
            self.update_output(output)
        except Exception as e:
            self.update_output(f"Error: {str(e)}")

    def run_intrusion_detection_system(self):
        self.update_output("Running Intrusion Detection System...")
        try:
            output = subprocess.getoutput('./scripts/networks/intrusion_detection_system.sh')
            self.update_output(output)
        except Exception as e:
            self.update_output(f"Error: {str(e)}")  

    def run_packet_sniffing_detection(self):
        self.update_output("Running Packet Sniffing Detection...")
        output = subprocess.getoutput('./scripts/networks/packet_sniffing_detection.sh')
        self.update_output(output)

    def run_dns_spoofing_detection(self):
        self.update_output("Running DNS Spoofing Detection...")
        output = subprocess.getoutput('./scripts/networks/dns_spoofing_detection.sh')
        self.update_output(output)

    def run_vpn_configuration_check(self):
        self.update_output("Checking VPN Configuration...")
        output = subprocess.getoutput('./scripts/networks/vpn_configuration_check.sh')
        self.update_output(output)

    def run_network_segmentation_audit(self):
        self.update_output("Auditing Network Segmentation...")
        output = subprocess.getoutput('./scripts/networks/network_segmentation_audit.sh')
        self.update_output(output)

    def run_wireless_network_security_check(self):
        self.update_output("Running Wireless Network Security Check...")
        output = subprocess.getoutput('./scripts/networks/wireless_network_security_check.sh')
        self.update_output(output)

    def run_ip_whitelisting_management(self):
        self.update_output("Managing IP Whitelisting...")
        output = subprocess.getoutput('./scripts/networks/ip_whitelisting_management.sh')
        self.update_output(output)

    def run_rogue_dhcp_server_detection(self):
        self.update_output("Detecting Rogue DHCP Servers...")
        output = subprocess.getoutput('./scripts/networks/rogue_dhcp_server_detection.sh')
        self.update_output(output)

    def run_mac_address_filtering(self):
        self.update_output("Running MAC Address Filtering...")
        output = subprocess.getoutput('./scripts/networks/mac_address_filtering.sh')
        self.update_output(output)

    def run_ssl_tls_configuration_analyzer(self):
        self.update_output("Analyzing SSL/TLS Configuration...")
        output = subprocess.getoutput('./scripts/networks/ssl_tls_configuration_analyzer.sh')
        self.update_output(output)

    def run_open_ports_vulnerability_scanning(self):
        self.update_output("Running Open Ports and Vulnerability Scanning...")
        output = subprocess.getoutput('./scripts/networks/open_ports_vulnerability_scanning.sh')
        self.update_output(output)  

    def run_security_audit(self):
        self.update_output("Performing Security Audit...")
        output = subprocess.getoutput('./scripts/security_audit.sh')
        self.update_output(output)

    def run_backup(self):
        self.update_output("Launching Backup...")
        subprocess.Popen(['python3', 'backup.py'])
        self.start_progress() 

    def run_anomaly_detection(self):
        self.update_output("Running Machine Learning-Based Anomaly Detection...")
        output = subprocess.getoutput('./scripts/anomaly_detection.sh')
        self.update_output(output)

    def run_compliance_checker(self):
        self.update_output("Running Configuration Compliance Check...")
        output = subprocess.getoutput('./scripts/compliance_checker.sh')
        self.update_output(output)

    def run_user_behavior_analytics(self):
        self.update_output("Running User Behavior Analytics...")
        output = subprocess.getoutput('./scripts/user_behavior_analytics.sh')
        self.update_output(output)

    def setup_ids(self):
        self.update_output("Setting Up Intrusion Detection System (IDS)...")
        output = subprocess.getoutput('./scripts/setup_ids.sh')
        self.update_output(output)

    def ram_monitor(self):
        self.update_output("Monitoring Ram...")
        output = subprocess.getoutput('/media/kunal/DE41-8946/AutoSysGuard/Scripts/Monitoring/memory.sh')
        self.update_output(output)
    def cpu_monitor(self):
        self.update_output("Setting Up Intrusion Detection System (IDS)...")
        output = subprocess.getoutput('./scripts/Monitoring/cpu.sh')
        self.update_output(output)
    def disk_monitor(self):
        self.update_output("Setting Up Intrusion Detection System (IDS)...")
        output = subprocess.getoutput('./scripts/Monitoring/disk.sh')
        self.update_output(output)
        
if __name__ == '__main__':
    app = QApplication(sys.argv)
    gui = AutoSysGuard()
    gui.show()
    sys.exit(app.exec_())
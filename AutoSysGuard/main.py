from PyQt5.QtCore import QProcess
import os
import sys
from PyQt5.QtWidgets import QApplication, QMainWindow, QHBoxLayout, QAction, QMenu, QTextEdit, QVBoxLayout, QWidget, QProgressBar, QPushButton,  QGraphicsOpacityEffect
from PyQt5.QtCore import Qt, QTimer
import subprocess
from PyQt5.QtGui import QIcon,QPixmap
from PyQt5.QtWidgets import QLabel


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

        with open("AutoSysGuard/style.qss", "r") as f:
            self.setStyleSheet(f.read())
        self.setWindowTitle('AutoSysGuard - Automated System Management Tool')
        self.setWindowIcon(QIcon('AutoSysGuard/img/logo.ico'))

        self.setGeometry(100, 100, 800, 600)

        self.central_widget = QWidget(self)
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)
        
        self.process = None  # For running bash scripts

        self.output_area = QTextEdit(self)
        self.output_area.setReadOnly(True)

        # Initialize the output area (QTextEdit)
        self.output_area = QTextEdit(self)
        self.output_area.setReadOnly(True)

        # Set the background image for the QTextEdit
        self.output_area.setStyleSheet("""
            QTextEdit {
                background-image: url(AutoSysGuard/img/Logo3.png);
                background-repeat: no-repeat;
                background-position: center;
                background-attachment: fixed;
            }
        """)


        self.layout.addWidget(self.output_area)

        self.progress_bar = QProgressBar(self)
        self.layout.addWidget(self.progress_bar)

        menubar = self.menuBar()

        system_menu = menubar.addMenu('Scan')
        system_menu.addAction(self.create_menu_action('Quick Scan', self.quickscan))
        system_menu.addAction(self.create_menu_action('Full Scan', self.fullscan))
        system_menu.addAction(self.create_menu_action('Basic Scan', self.basicscan))
        system_menu.addAction(self.create_menu_action('Automated Scan', self.schedulescan))
        system_menu.addAction(self.create_menu_action('External Device Scan', self.externalscan))


        system_menu = menubar.addMenu('System')
        system_menu.addAction(self.create_menu_action('Performance Tuning', self.performance_tuning))
        system_menu.addAction(self.create_menu_action('Power Management', self.power_management))
        system_menu.addAction(self.create_menu_action('Service Management', self.service_management))
        system_menu.addAction(self.create_menu_action('User and Group Management', self.userandgroup_management))
        system_menu.addAction(self.create_menu_action('System Info', self.systeminfo))

        network_menu = menubar.addMenu('Network')
        network_menu.addAction(self.create_menu_action('IP Scanner', self.ipscan))
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

        
        maintenance_menu = menubar.addMenu('Maintenance')
        maintenance_menu.addAction(self.create_menu_action('Backup', self.run_backup))
        maintenance_menu.addAction(self.create_menu_action('System Backup', self.system_backup))
        maintenance_menu.addAction(self.create_menu_action('Schedule Automatic Backup', self.schedule_automatic_backup))


        monitoring_menu = menubar.addMenu('Monitoring')
        monitoring_menu.addAction(self.create_menu_action("Ram Monitoring", self.ram_monitor))
        monitoring_menu.addAction(self.create_menu_action("CPU Monitoring", self.cpu_monitor))
        monitoring_menu.addAction(self.create_menu_action("Disk Monitoring", self.disk_monitor))

        # Create Terminal Scripts submenu
        terminal_scripts_menu = menubar.addMenu("Terminals and Scripts")
        terminal_scripts_menu.addAction(self.create_menu_action("Gnome-Terminal", self.launch_gnome_terminal))
        terminal_scripts_menu.addAction(self.create_menu_action("Konsole", self.launch_konsole))
        terminal_scripts_menu.addAction(self.create_menu_action("Xterm", self.launch_xterm))
        terminal_scripts_menu.addAction(self.create_menu_action("Terminator", self.launch_terminator))
        terminal_scripts_menu.addAction(self.create_menu_action("Tilix", self.launch_tilix))
        terminal_scripts_menu.addAction(self.create_menu_action("Alacritty", self.launch_alacritty))
        terminal_scripts_menu.addAction(self.create_menu_action("Lxterminal", self.launch_lxterminal))
        terminal_scripts_menu.addAction(self.create_menu_action("Termite", self.launch_termite))
        terminal_scripts_menu.addAction(self.create_menu_action("Kitty", self.launch_kitty))
        terminal_scripts_menu.addAction(self.create_menu_action("Bash", self.launch_bash))
        terminal_scripts_menu.addAction(self.create_menu_action("Zsh", self.launch_zsh))
        terminal_scripts_menu.addAction(self.create_menu_action("Fish", self.launch_fish))
        terminal_scripts_menu.addAction(self.create_menu_action("Tcsh", self.launch_tcsh))
        terminal_scripts_menu.addAction(self.create_menu_action("Dash", self.launch_dash))
        terminal_scripts_menu.addAction(self.create_menu_action("Ksh", self.launch_ksh))
        terminal_scripts_menu.addAction(self.create_menu_action("Pwsh", self.launch_pwsh))
        terminal_scripts_menu.addAction(self.create_menu_action("Csh", self.launch_csh))
        terminal_scripts_menu.addAction(self.create_menu_action("Openbsd", self.launch_openbsd))
        terminal_scripts_menu.addAction(self.create_menu_action("Screen", self.launch_screen))
        terminal_scripts_menu.addAction(self.create_menu_action("Tmux", self.launch_tmux))
        terminal_scripts_menu.addAction(self.create_menu_action("Mintty", self.launch_mintty))
        terminal_scripts_menu.addAction(self.create_menu_action("Rxvt", self.launch_rxvt))
        terminal_scripts_menu.addAction(self.create_menu_action("Termux", self.launch_termux))


        self.show()
        button_layout = QHBoxLayout()
        self.layout.addLayout(button_layout)

        self.stop_button = QPushButton("Stop", self)
        self.stop_button.clicked.connect(self.stop_process)
        button_layout.addWidget(self.stop_button)

        self.clear_button = QPushButton("Clear Screen", self)
        self.clear_button.clicked.connect(self.clear_output)
        button_layout.addWidget(self.clear_button)



    def launch_gnome_terminal(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_gnome_terminal.sh')
        self.update_output(output)

    def launch_konsole(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_konsole.sh')
        self.update_output(output)

    def launch_xterm(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_xterm.sh')
        self.update_output(output)
        
    def launch_terminator(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_terminator.sh')
        self.update_output(output)

    def launch_tilix(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_tilix.sh')
        self.update_output(output)

    def launch_alacritty(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_alacritty.sh')
        self.update_output(output)

    def launch_lxterminal(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_lxterminal.sh')
        self.update_output(output)

    def launch_termite(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_termite.sh')
        self.update_output(output)

    def launch_kitty(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_kitty.sh')
        self.update_output(output)

    def launch_bash(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_bash.sh')
        self.update_output(output)

    def launch_zsh(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_zsh.sh')
        self.update_output(output)

    def launch_fish(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_fish.sh')
        self.update_output(output)

    def launch_tcsh(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_tcsh.sh')
        self.update_output(output)
        
    def launch_dash(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_dash.sh')
        self.update_output(output)

    def launch_ksh(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_ksh.sh')
        self.update_output(output)

    def launch_pwsh(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_pwsh.sh')
        self.update_output(output)

    def launch_csh(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_csh.sh')
        self.update_output(output)

    def launch_openbsd(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_openbsd.sh')
        self.update_output(output)

    def launch_screen(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_screen.sh')
        self.update_output(output)

    def launch_tmux(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_tmux.sh')
        self.update_output(output)

    def launch_mintty(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_mintty.sh')
        self.update_output(output)

    def launch_rxvt(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_rxvt.sh')
        self.update_output(output)

    def launch_termux(self):
        self.update_output("Launching...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Terminals/launch_termux.sh')
        self.update_output(output)



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

    def basicscan(self):
        self.update_output("Performing Basic Scan...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Scan/basic.sh')
        self.update_output(output)

    def fullscan(self):
        self.update_output("Performing Full System Scan...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Scan/full.sh')
        self.update_output(output)

    def quickscan(self):
        self.update_output("Performing Ouick System Scan...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Scan/quick.sh')
        self.update_output(output)

    def schedulescan(self):
        self.update_output("Performing Automated Scheduled Scan...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Scan/schedule.sh')
        self.update_output(output)

    def externalscan(self):
        self.update_output("Performing External Device Scan...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Scan/external.sh')
        self.update_output(output)

    def performance_tuning(self):
        self.update_output("Performing Power Tuning")
        output = subprocess.getoutput('AutoSysGuard/Scripts/System/performance.sh')
        self.update_output(output)

    def power_management(self):
        self.update_output("Managing Power...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/System/power.sh')
        self.update_output(output)

    def service_management(self):
        self.update_output("Managing Services...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/System/service.sh')
        self.update_output(output)

    def userandgroup_management(self):
        self.update_output("Managing User and Group...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/System/userandgroup.sh')
        self.update_output(output)

    def systeminfo(self):
        self.update_output("howing System Information...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/System/system_info.sh')
        self.update_output(output)

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

    def ipscan(self):
        self.update_output("Performing IP's Scan...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/ip_scanner.sh')
        self.update_output(output)

    def run_arp_spoofing_detection(self):
        self.update_output("Running ARP Spoofing Detection...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/arp_spoofing_detection.sh')
        self.update_output(output)

    def run_firewall_config(self):
        self.update_output("Configuring Firewall...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/firewall_config.sh')
        self.update_output(output)

    def run_network_traffic_monitor(self):
        self.update_output("Monitoring Network Traffic...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/network_traffic_monitor.sh')
        self.update_output(output)

    def run_port_scan(self):
        self.update_output("Port Scan Completed.")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/port_scan.sh')
        self.update_output(output)

    def run_ssh_hardening(self):
        self.update_output("Hardening SSH Done...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/ssh_hardening.sh')
        self.update_output(output)
    
    def run_brute_force_detection_system(self):
        self.update_output("Running Brute Force Detection System...")
        try:
            output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/brute_force_detection.sh')
            self.update_output(output)
            self.update_output("Completed..")

        except Exception as e:
            self.update_output(f"Error: {str(e)}")

    def run_intrusion_detection_system(self):
        self.update_output("Intrusion Detection System Completed")
        try:
            output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/intrusion_detection_system.sh')
            self.update_output(output)
        except Exception as e:
            self.update_output(f"Error: {str(e)}")  

    def run_packet_sniffing_detection(self):
        self.update_output(" Packet Sniffing Detection Completed")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/packet_sniffing_detection.sh')
        self.update_output(output)

    def run_dns_spoofing_detection(self):
        self.update_output("DNS Spoofing Detection Completed")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/dns_spoofing_detection.sh')
        self.update_output(output)

    def run_vpn_configuration_check(self):
        self.update_output("Checking VPN Configuration Completed.")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/vpn_configuration_check.sh')
        self.update_output(output)

    def run_network_segmentation_audit(self):
        self.update_output("Auditing Network Segmentation...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/network_segmentation_audit.sh')
        self.update_output(output)

    def run_wireless_network_security_check(self):
        self.update_output("Running Wireless Network Security Check...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/wireless_network_security_check.sh')
        self.update_output(output)

    def run_ip_whitelisting_management(self):
        self.update_output("Managing IP Whitelisting...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/ip_whitelisting_management.sh')
        self.update_output(output)

    def run_rogue_dhcp_server_detection(self):
        self.update_output("Detecting Rogue DHCP Servers...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/rogue_dhcp_server_detection.sh')
        self.update_output(output)

    def run_mac_address_filtering(self):
        self.update_output("Running MAC Address Filtering...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/mac_address_filtering.sh')
        self.update_output(output)

    def run_ssl_tls_configuration_analyzer(self):
        self.update_output("Analyzing SSL/TLS Configuration...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/ssl_tls_configuration_analyzer.sh')
        self.update_output(output)

    def run_open_ports_vulnerability_scanning(self):
        self.update_output("Running Open Ports and Vulnerability Scanning...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Networks/open_ports_vulnerability_scanning.sh')
        self.update_output(output)  

    def run_security_audit(self):
        self.update_output("Performing Security Audit...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/audit.sh')
        self.update_output(output)

    def run_backup(self):
        self.update_output("Launching Backup...")
        subprocess.Popen(['python3', 'AutoSysGuard/Scripts/Maintenance/backup.py'])
        self.update_output("Launched!")
        self.start_progress() 

    def system_backup(self):
        self.update_output("Launching System Backup...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Maintenance/system_backup.sh')
        self.update_output(output) 

    def schedule_automatic_backup(self):
        self.update_output("Scheduling Automatic Backup...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/Maintenance/automatic_backup.sh')
        self.update_output(output) 

    def run_anomaly_detection(self):
        self.update_output("Running Machine Learning-Based Anomaly Detection...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/SecurityChecks/anomaly_detection.sh')
        self.update_output(output)

    def run_compliance_checker(self):
        self.update_output("Running Configuration Compliance Check...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/SecurityChecks/compilance_checker.sh')
        self.update_output(output)

    def run_user_behavior_analytics(self):
        self.update_output("Running User Behavior Analytics...")
        output = subprocess.getoutput('AutoSysGuard/Scripts/SecurityChecks/ub_analystic.sh')
        self.update_output(output)


    # RAM Monitoring
    def ram_monitor(self):
        self.update_output("Monitoring RAM...")
        self.process = QProcess(self)
        self.process.readyReadStandardOutput.connect(self.handle_output)
        self.process.start('bash', ['-c', 'AutoSysGuard/Scripts/Monitoring/memory.sh'])  # Run the RAM monitor in Bash
        self.start_progress()

    # CPU Monitoring
    def cpu_monitor(self):
        self.update_output("Monitoring CPU...")
        self.process = QProcess(self)
        self.process.readyReadStandardOutput.connect(self.handle_output)
        self.process.start('bash', ['-c', 'AutoSysGuard/Scripts/Monitoring/cpu.sh'])  # Run the CPU monitor in Bash
        self.start_progress()

    # Disk Monitoring
    def disk_monitor(self):
        self.update_output("Monitoring Disk...")
        self.process = QProcess(self)
        self.process.readyReadStandardOutput.connect(self.handle_output)
        self.process.start('bash', ['-c', 'AutoSysGuard/Scripts/Monitoring/disk.sh'])  # Run the Disk monitor in Bash
        self.start_progress()



    #Handle Output
    def handle_output(self):
        output = self.process.readAllStandardOutput().data().decode()

        # Clear the output when the ANSI escape sequence to clear screen is detected
        if "\033[2J" in output:
            self.clear_output()  # Call the newly defined clear_output method
        
        # Remove the clear screen sequence from the output to display properly
        output = output.replace("\033[2J", "")
        self.update_output(output)

    def clear_output(self):
        self.output_area.clear()  # Correct the reference to the output area



    # Stop process
    def stop_process(self):
        if self.process and self.process.state() == QProcess.Running:
            self.process.terminate()
            self.update_output("Process stopped.")
            self.stop_progress()    
    
    
    def clear_output(self):
        self.output_area.clear()  # Clears the GUI display widget (output_area)



if __name__ == '__main__':
    app = QApplication(sys.argv)
    gui = AutoSysGuard()
    gui.show()
    sys.exit(app.exec_())
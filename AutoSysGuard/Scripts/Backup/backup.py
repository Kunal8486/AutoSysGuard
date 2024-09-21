from PyQt5.QtWidgets import (QApplication, QDialog, QVBoxLayout, QPushButton, QFileDialog, QLabel, 
                             QCheckBox, QLineEdit, QMessageBox)
from PyQt5.QtCore import Qt
import subprocess
import sys

class BackupWindow(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Backup Settings')
        self.setGeometry(150, 150, 500, 300)

        self.layout = QVBoxLayout(self)

        # Source directory selection
        self.source_label = QLabel("Select the directory to back up:")
        self.layout.addWidget(self.source_label)
        self.source_path = QLineEdit(self)
        self.layout.addWidget(self.source_path)
        self.source_button = QPushButton("Browse", self)
        self.source_button.clicked.connect(self.select_source_directory)
        self.layout.addWidget(self.source_button)

        # Destination directory selection
        self.dest_label = QLabel("Select the backup destination:")
        self.layout.addWidget(self.dest_label)
        self.dest_path = QLineEdit(self)
        self.layout.addWidget(self.dest_path)
        self.dest_button = QPushButton("Browse", self)
        self.dest_button.clicked.connect(self.select_dest_directory)
        self.layout.addWidget(self.dest_button)

        # Compression option
        self.compression_check = QCheckBox("Enable Compression (.tar.gz)", self)
        self.layout.addWidget(self.compression_check)

        # Backup button
        self.backup_button = QPushButton("Start Backup", self)
        self.backup_button.clicked.connect(self.start_backup)
        self.layout.addWidget(self.backup_button)

    def select_source_directory(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Directory")
        if directory:
            self.source_path.setText(directory)

    def select_dest_directory(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Directory")
        if directory:
            self.dest_path.setText(directory)

    def start_backup(self):
        source = self.source_path.text()
        destination = self.dest_path.text()
        enable_compression = self.compression_check.isChecked()

        if source and destination:
            # Call Bash script for backup
            command = ['Scripts/Backup/backup.sh', source, destination, 'compress' if enable_compression else 'no-compress']
            process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            output, error = process.communicate()

            # Handle output in the GUI
            if error:
                self.show_message("Error", error.decode())
            else:
                self.show_message("Backup Complete", output.decode())
        else:
            self.show_message("Input Error", "Source and Destination directories are required!")

    def show_message(self, title, message):
        msg_box = QMessageBox(self)
        msg_box.setIcon(QMessageBox.Information)
        msg_box.setWindowTitle(title)
        msg_box.setText(message)
        msg_box.setStandardButtons(QMessageBox.Ok)
        msg_box.exec_()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    backup_window = BackupWindow()
    backup_window.show()
    sys.exit(app.exec_())

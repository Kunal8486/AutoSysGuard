import os
import tkinter as tk
from tkinter import messagebox, Listbox, Scrollbar
import subprocess

# Function to run scripts in the selected folder (in an external terminal)
def run_scripts_in_folder():
    selected_folder = folder_listbox.get(tk.ACTIVE)
    
    if not selected_folder:
        messagebox.showwarning("No Folder Selected", "Please select a folder to run scripts from.")
        return

    folder_path = os.path.join(current_dir, selected_folder)
    scripts = [f for f in os.listdir(folder_path) if f.endswith('.sh') or f.endswith('.py')]

    if not scripts:
        messagebox.showinfo("No Scripts", f"No .sh or .py scripts found in folder: {selected_folder}")
        return

    # Run each script in an external terminal
    for script in scripts:
        script_path = os.path.join(folder_path, script)
        log_text.insert(tk.END, f"Running script: {script} in an external terminal...\n")
        log_text.see(tk.END)

        try:
            # Check if it's a shell script or a python script, and run accordingly
            if script.endswith('.sh'):
                subprocess.Popen(['gnome-terminal', '--', 'bash', '-c', f"sudo bash '{script_path}'; exec bash"])  # GNOME Terminal
            elif script.endswith('.py'):
                subprocess.Popen(['gnome-terminal', '--', 'bash', '-c', f"sudo python3 '{script_path}'; exec bash"])  # GNOME Terminal
            
            # You can also use xterm or another terminal emulator if GNOME Terminal isn't available:
            # subprocess.Popen(['xterm', '-hold', '-e', f"sudo bash {script_path}"])  # For shell scripts
            # subprocess.Popen(['xterm', '-hold', '-e', f"sudo python3 {script_path}"])  # For Python scripts

            log_text.insert(tk.END, f"Script {script} is running in an external terminal.\n")
        except Exception as e:
            log_text.insert(tk.END, f"Failed to execute {script}: {str(e)}\n")
        log_text.see(tk.END)

# Function to update the file listbox when a folder is selected
def update_file_list(event):
    selected_folder = folder_listbox.get(tk.ACTIVE)
    if not selected_folder:
        return

    folder_path = os.path.join(current_dir, selected_folder)
    files = os.listdir(folder_path)

    file_listbox.delete(0, tk.END)
    for file in files:
        file_listbox.insert(tk.END, file)

# Main application window
root = tk.Tk()
root.title("CIS Benchmark Script Runner")

# Get the current working directory
current_dir = os.getcwd()

# Display folders in the current directory
folder_label = tk.Label(root, text="Select a folder:")
folder_label.grid(row=0, column=0, padx=10, pady=10, sticky="w")

folder_listbox = Listbox(root, height=10, width=50)
folder_listbox.grid(row=1, column=0, padx=10, pady=10, sticky="w")

folder_scrollbar = Scrollbar(root)
folder_scrollbar.grid(row=1, column=1, sticky="ns")

folder_listbox.config(yscrollcommand=folder_scrollbar.set)
folder_scrollbar.config(command=folder_listbox.yview)

# Get all folders in the current directory
folders = [f for f in os.listdir(current_dir) if os.path.isdir(os.path.join(current_dir, f))]

# Insert folders into the listbox
for folder in folders:
    folder_listbox.insert(tk.END, folder)

# Display files in the selected folder
file_label = tk.Label(root, text="Files in selected folder:")
file_label.grid(row=2, column=0, padx=10, pady=10, sticky="w")

file_listbox = Listbox(root, height=10, width=50)
file_listbox.grid(row=3, column=0, padx=10, pady=10, sticky="w")

file_scrollbar = Scrollbar(root)
file_scrollbar.grid(row=3, column=1, sticky="ns")

file_listbox.config(yscrollcommand=file_scrollbar.set)
file_scrollbar.config(command=file_listbox.yview)

# Button to run scripts in the selected folder
run_button = tk.Button(root, text="Run Scripts", command=run_scripts_in_folder)
run_button.grid(row=4, column=0, padx=10, pady=10, sticky="w")

# Log output display
log_label = tk.Label(root, text="Log:")
log_label.grid(row=5, column=0, padx=10, pady=10, sticky="w")

log_text = tk.Text(root, height=10, width=60)
log_text.grid(row=6, column=0, padx=10, pady=10)

log_scrollbar = Scrollbar(root)
log_scrollbar.grid(row=6, column=1, sticky="ns")

log_text.config(yscrollcommand=log_scrollbar.set)
log_scrollbar.config(command=log_text.yview)

# Bind folder selection to update the file list
folder_listbox.bind('<<ListboxSelect>>', update_file_list)

# Run the Tkinter event loop
root.mainloop()

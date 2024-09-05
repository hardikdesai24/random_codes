import csv
import subprocess
import logging
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Define the path to the vulnerability report and PowerShell script using environment variables
vulnerability_report_path = os.getenv('VULNERABILITY_REPORT_PATH', r'\\fileserver\share\vulnerability_report.csv')
ps_script_path = os.getenv('PS_SCRIPT_PATH', r'C:\Scripts\wsus_manage.ps1')

# Function to read the vulnerability report
def read_vulnerability_report(file_path):
    vulnerable_computers = []
    try:
        with open(file_path, mode='r') as file:
            csv_reader = csv.DictReader(file)
            for row in csv_reader:
                # Assuming the CSV has a column 'ComputerName'
                computer_name = row['ComputerName']
                vulnerable_computers.append(computer_name)
    except Exception as e:
        logging.error(f"Error reading vulnerability report: {e}")
    return vulnerable_computers

# Function to call PowerShell script from Python
def run_powershell_script(script, args):
    try:
        # Construct the PowerShell command
        ps_command = ["powershell", "-ExecutionPolicy", "Bypass", "-File", script] + args
        # Execute the PowerShell script
        result = subprocess.run(ps_command, capture_output=True, text=True)
        if result.returncode != 0:
            logging.error(f"Error executing PowerShell script: {result.stderr}")
        else:
            logging.info(f"PowerShell script executed successfully: {result.stdout}")
    except Exception as e:
        logging.error(f"Error running PowerShell script: {e}")

# Main process
def main():
    # Step 1: Read the vulnerability report
    vulnerable_computers = read_vulnerability_report(vulnerability_report_path)
    
    if not vulnerable_computers:
        logging.info("No vulnerable computers found.")
        return

    # Step 2: Create/Update WSUS Group for vulnerable computers
    for computer in vulnerable_computers:
        # Step 3: Call PowerShell script to manage WSUS
        args = [computer]
        run_powershell_script(ps_script_path, args)
    
    # Completion message
    logging.info("All vulnerable computers have been processed. Check WSUS for update status.")

# This ensures the script executes only if run directly
if __name__ == "__main__":
    main()
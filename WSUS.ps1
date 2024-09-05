param(
    [string]$ComputerName
)

# Load the WSUS UpdateServices module
Import-Module UpdateServices

# Connect to WSUS
$wsus = Get-WsusServer -Name "Your-WSUS-Server" -Port 8530

# Step 1: Create or Update Computer Group for Vulnerable Machines
$groupName = "Vulnerable_Computers_Group"
$group = $wsus.GetComputerTargetGroups() | Where-Object { $_.Name -eq $groupName }

if (-not $group) {
    $group = $wsus.CreateComputerTargetGroup($groupName)
    Write-Output "Created new WSUS group: $groupName"
} else {
    Write-Output "WSUS group already exists: $groupName"
}

# Step 2: Add the vulnerable computer to the WSUS group
$computer = $wsus.GetComputer($ComputerName)
if ($computer) {
    $computer.ChangeComputerTargetGroup($group)
    Write-Output "Added $ComputerName to $groupName"
} else {
    Write-Output "Computer $ComputerName not found in WSUS"
}

# Step 3: Approve patches for the WSUS group
$updates = $wsus.GetUpdates() | Where-Object { $_.IsApproved -eq $false }
foreach ($update in $updates) {
    $update.Approve("Install", $group)
    Write-Output "Approved update $($update.Title) for $groupName"
}

# Step 4: Trigger patch installation (if configured via WSUS GPO, client will auto-install)
Write-Output "Patches approved, waiting for client installation"

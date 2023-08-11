$isAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Get Execution Priviledge
Set-ExecutionPolicy Unrestricted -Force

# Reset windows update service
# Reset-WUComponents

# Wait for internet
while (1) {
    # Get a list of DHCP-enabled interfaces that have a 
    # non-$null DefaultIPGateway property.
    $x = gwmi -class Win32_NetworkAdapterConfiguration `
            -filter DHCPEnabled=TRUE |
                    where { $_.DefaultIPGateway -ne $null }

    # If there is (at least) one available, exit the loop.
    if ( ($x | measure).count -gt 0 ) {
        break
    }

    # If $tries > 0 and we have tried $tries times without
    # success, throw an exception.
    if ( $tries -gt 0 -and $try++ -ge $tries ) {
        throw "Network unavaiable after $try tries."
    }

    # Wait one second.
    start-sleep -s 1
}

# Install modules if not already installed
if (-Not (Get-InstalledModule -Name PSWindowsUpdate)){
    # Get package installer
    Install-PackageProvider -Name NuGet -Force

    # Install the module PSWindowsUpdate    
    Install-Module -Name PSWindowsUpdate -Force
}

# Load module
Import-Module -Name PSWindowsUpdate -Force

# Place available updates in a variable
$UpdateVar = Get-WindowsUpdate

# Hide anything related to Windows 11
foreach ($UpdateVarElement in $UpdateVar){
    if ($UpdateVarElement.Title -like "*Windows 11*"){
        Get-WindowsUpdate -Title $UpdateVarElement.Title -Hide -Confirm:$false
    }
}

# Install all updates, autoreboot, and store log files in C:\
Get-WindowsUpdate -AcceptAll -Install -AutoReboot -Verbose | Out-File "C:\MSUpdate_$(get-date -f 'D:yyyy-MM-dd_T:HH:mm').log" -NoClobber -Force

# View install History
# Get-WUHistory -Last 100

#Show hidden windows update
#Show-WindowsUpdate -Verbose

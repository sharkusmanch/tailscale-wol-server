# windows-nic-metric.ps1
# ----------------------
# PowerShell script to set network interface metrics on Windows 11 desktop.
# Ensures the 10GbE NIC remains primary for outbound traffic, while the onboard Intel NIC is available for WoL.

# Set network interface metrics for Windows 11 Desktop
Set-NetIPInterface -InterfaceAlias "Ethernet 2" -InterfaceMetric 5
Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 500

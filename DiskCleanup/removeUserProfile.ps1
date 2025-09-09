$UserProfile = "USERNAME"
$ProfilePath = "C:\Users\USERNAME"

# Remove user profile
Get-WmiObject Win32_UserProfile | Where-Object { $_.LocalPath -eq $ProfilePath } | ForEach-Object { $_.Delete() }

[math]::Round((Get-PSDrive C).Free / 1GB, 2)
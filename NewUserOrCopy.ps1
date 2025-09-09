# Requires: ActiveDirectory module

Import-Module ActiveDirectory

function Read-Required {
    param(
        [string]$Prompt
    )
    do {
        $value = Read-Host $Prompt
    } while ([string]::IsNullOrWhiteSpace($value))
    return $value
}

function Prompt-UserInfo {
    do {
        $givenName = Read-Required "First name"
        $surname = Read-Required "Last name"
        $nameExists = Get-ADUser -Filter "GivenName -eq '$givenName' -and Surname -eq '$surname'" -ErrorAction SilentlyContinue
        if ($nameExists) { Write-Warning "A user with that first and last name already exists." }
    } while ($nameExists)

    do {
        $sam = Read-Required "Desired username"
        $samExists = Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue
        if ($samExists) { Write-Warning "Username $sam already exists." }
    } while ($samExists)

    $title = Read-Host "Title"
    $manager = Read-Host "Manager"
    $phone = Read-Host "Phone number"
    $email = Read-Host "Email"

    return [pscustomobject]@{
        GivenName     = $givenName
        Surname       = $surname
        SamAccountName= $sam
        Title         = $title
        Manager       = $manager
        Phone         = $phone
        Email         = $email
    }
}

$choice = ""
while ($choice -notin @('N','C')) {
    $choice = Read-Host "Is this a (N)ew user or (C)opy from existing user? (N/C)"
    $choice = $choice.ToUpper()
}

$userInfo = Prompt-UserInfo

if ($choice -eq 'N') {
    $ou = Read-Required "OU distinguished name to create user in"
    $userParams = @{
        GivenName       = $userInfo.GivenName
        Surname         = $userInfo.Surname
        Name            = "$($userInfo.GivenName) $($userInfo.Surname)"
        SamAccountName  = $userInfo.SamAccountName
        UserPrincipalName = "$($userInfo.SamAccountName)@$(Get-ADDomain).DomainName"
        Title           = $userInfo.Title
        Manager         = $userInfo.Manager
        OfficePhone     = $userInfo.Phone
        EmailAddress    = $userInfo.Email
        Path            = $ou
        Enabled         = $false
    }
    New-ADUser @userParams
    Write-Host "Created user $($userInfo.SamAccountName) in $ou"
} else {
    $sourceUser = $null
    do {
        $sourceSam = Read-Required "Enter the username to copy from"
        $sourceUser = Get-ADUser -Identity $sourceSam -Properties MemberOf,Title,Manager,OfficePhone,EmailAddress -ErrorAction SilentlyContinue
        if (-not $sourceUser) { Write-Warning "Source user $sourceSam not found." }
    } while (-not $sourceUser)

    $ou = $sourceUser.DistinguishedName -replace '^CN=[^,]+,',''
    $userParams = @{
        GivenName       = $userInfo.GivenName
        Surname         = $userInfo.Surname
        Name            = "$($userInfo.GivenName) $($userInfo.Surname)"
        SamAccountName  = $userInfo.SamAccountName
        UserPrincipalName = "$($userInfo.SamAccountName)@$(Get-ADDomain).DomainName"
        Title           = if ($userInfo.Title) { $userInfo.Title } else { $sourceUser.Title }
        Manager         = if ($userInfo.Manager) { $userInfo.Manager } else { $sourceUser.Manager }
        OfficePhone     = if ($userInfo.Phone) { $userInfo.Phone } else { $sourceUser.OfficePhone }
        EmailAddress    = if ($userInfo.Email) { $userInfo.Email } else { $sourceUser.EmailAddress }
        Path            = $ou
        Enabled         = $false
    }
    New-ADUser @userParams
    $groups = $sourceUser.MemberOf
    if ($groups) { Add-ADPrincipalGroupMembership -Identity $userInfo.SamAccountName -MemberOf $groups }
    Write-Host "Created user $($userInfo.SamAccountName) copied from $sourceSam"
}

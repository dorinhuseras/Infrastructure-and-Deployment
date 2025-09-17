param($jsonAppRolesFile, $jsonApiPermissionFile, $appName)
$context = Get-AzContext
$graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
$secureAccessToken = $graphToken | ConvertTo-SecureString -AsPlainText -Force
Connect-MgGraph -AccessToken $secureAccessToken
$directoryId = $context.Tenant.Id.ToString()

if (Get-InstalledModule -Name "Microsoft.Graph" -MinimumVersion 1.0) {
    Import-Module Microsoft.Graph.Applications
} else {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Install-Module Microsoft.Graph -Scope CurrentUser
    Import-Module Microsoft.Graph.Applications
}

function Get-Required-Resource-Access {
    [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphRequiredResourceAccess[]] $RequiredResourceAccessArray = @()
    # Loop through each object and print the content
    foreach ($obj in $jsonApiPermission) {
        $RequiredResourceAccess = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
        $RequiredResourceAccess.resourceAppId = $obj.resourceAppId
        $RequiredResourceAccess.resourceAccess = @()
        # Loop through resourceAccess array and print its content
        foreach ($resourceAccess in $obj.resourceAccess) {
            $MicrosoftGraphResourceAccess = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphResourceAccess
            $MicrosoftGraphResourceAccess.id = $resourceAccess.id
            $MicrosoftGraphResourceAccess.type = $resourceAccess.type
            $RequiredResourceAccess.resourceAccess += $MicrosoftGraphResourceAccess
        }
        $RequiredResourceAccessArray += $RequiredResourceAccess
    }
    return $RequiredResourceAccessArray
}

function Get-Api-Permissions {
    param([String]$SubdomainName)
    $newAppPermision = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphApiApplication

    $scope = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphPermissionScope
    $scope.AdminConsentDescription = "Allow the application to access $subdomainName.coraxwms.nl on behalf of the signed-in user."
    $scope.AdminConsentDisplayName =  "Access $subdomainName.coraxwms.nl"
    $scope.Id = [Guid]::NewGuid().ToString()
    $scope.IsEnabled = $true
    $scope.Type = "User"
    $scope.UserConsentDescription = "Allow the application to access $subdomainName.coraxwms.nl on your behalf."
    $scope.UserConsentDisplayName =  "Access $subdomainName.coraxwms.nl"
    $scope.Value = "user_impersonation"
    $newAppPermision.Oauth2PermissionScopes = @($scope)

    return $newAppPermision
}

function Get-Web-Config{
    param([String]$SubdomainName)
    $webConfig = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphWebApplication
    $webConfig.HomePageUrl = "https://$SubdomainName.coraxwms.nl/"
    $webConfig.ImplicitGrantSettings = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphImplicitGrantSettings
    $webConfig.ImplicitGrantSettings.EnableAccessTokenIssuance = $true
    $webConfig.ImplicitGrantSettings.EnableIdTokenIssuance = $true
    $webConfig.RedirectUris = @("https://$SubdomainName.coraxwms.nl")

    return $webConfig
}

function Get-Spa-Config{
    param([String]$SubdomainName)
    $spaConfig = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphSpaApplication
    $spaConfig.RedirectUris = @("https://$SubdomainName.coraxwms.nl/app/")
    return $spaConfig
}

function Get-Password-Credentials{
    param([int]$NumberOfMonths)
    $passCredential = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordCredential
    $passCredential.DisplayName = [Guid]::NewGuid().ToString()
    $passCredential.EndDateTime = (Get-Date).AddMonths($numberOfMonths)
    return @($passCredential)
}

function Get-Or-Create-ADApplication {
    param([String]$ApplicationName)
    try {
        $SPNObject = (Get-MgApplication -Filter "DisplayName eq '$ApplicationName'") | select Id ,AppId, AppRoles

        if (!$SPNObject){
            Write-Host "No Ad app registration found, Create one for '$ApplicationName'"
            $api = Get-Api-Permissions -SubdomainName $ApplicationName
            $webConfig =  Get-Web-Config -SubdomainName $ApplicationName
            $spaConfig = Get-Spa-Config -SubdomainName $ApplicationName 
            $SPNObject = (New-MgApplication -DisplayName $ApplicationName -Api $api -Web $webConfig -Spa $spaConfig -PasswordCredentials $passCredential -SignInAudience "AzureADMyOrg")| select Id ,AppId, AppRoles, IdentifierUris
            
            #Can be moved to a dedicated method if you want to update the MgAppApiPermissons
            $requiredResourceAccess = Get-Required-Resource-Access -ClinetId
            $identifierUri = "api://$($SPNObject.AppId)"
            Update-MgApplication -ApplicationId $SPNObject.Id -RequiredResourceAccess $requiredResourceAccess -IdentifierUris @($identifierUri)
        }
        return $SPNObject
    }
    catch {
        $message = $Error[0].Exception.Message
        Write-Host "##vso[task.logissue type=error;]$message.";
        Write-Error $message;
        return $null
    }
}

function Add-AppRoles {
        param(
            [String]$AppRoleDisplayName,
            [String]$AppRoleDescription,
            [String]$AppRoleValue,
            [String]$Origin
        )
        $newAppRole = $null
        try {
            $Id = [Guid]::NewGuid().ToString()
            $newAppRole = New-Object Microsoft.Graph.PowerShell.Models.MicrosoftGraphAppRole
            $newAppRole.AllowedMemberTypes = @("User")
            $newAppRole.DisplayName = $AppRoleDisplayName
            $newAppRole.Description = $AppRoleDescription
            $newAppRole.Value = $AppRoleValue
            $newAppRole.Id = $Id
            $newAppRole.IsEnabled = $true
            $newAppRole.Origin = $Origin    
        }
        catch {
            $message = $Error[0].Exception.Message
            Write-Host "##vso[task.logissue type=error;]$message.";
            Write-Error $message;
        }

        return $newAppRole
}

function Set-Custom-Roles-On-AppRegistration {
    param (
        $ApplicationId,
        $JsonAppRoles
    )
    $appRoles = @()
    foreach ($role in $JsonAppRoles) {
        $newAppRole = Add-AppRoles -AppRoleDisplayName $role.displayName -AppRoleDescription $role.description -AppRoleValue $role.value -Origin $role.origin
        $appRoles += $newAppRole
    }
    Update-MgApplication -ApplicationId $ApplicationId -AppRoles $appRoles
}

function Remove-Expierd-Credentioals{
    param ([String] $ApplicationId,
           [String] $KeyId)

    Write-Host "Removing expired key $KeyId from Application $ApplicationId"
    $params = @{
        KeyId = $KeyId
    }
    Remove-MgApplicationPassword -ApplicationId $ApplicationId -BodyParameter $params
}

function Get-App-Credentials-Status{
    param ([String]$ApplicationName)
    $SPNObject = (Get-MgApplication -Filter "DisplayName eq '$ApplicationName'" -All) | select Id ,AppId, DisplayName, PasswordCredentials

    foreach ($obj in $SPNObject.PasswordCredentials){
        $currentDate = Get-Date
        $ts = New-TimeSpan -Start $currentDate -End $obj.EndDateTime
        if ($ts.Days -lt 1){ # found expired credentials, need to removed them
            Remove-Expierd-Credentioals -ApplicationId $SPNObject.Id -KeyId $obj.KeyId
        }
        if ($ts.Days -gt 30){ 
            Write-Host "At least one credential is still valid, moving on..."
            return 0
        } 
    }

    Write-Host "There are no credentials or they are about to expire in 30 days"
    return 1 #Needs credentials to be created
}


function Add-App-Registration-For-Tenant {
    param (
        [String]$ApplicationName
    )
    
    Write-Host $ApplicationName
    $app = Get-Or-Create-ADApplication -ApplicationName $ApplicationName

    if ($app.AppRoles.count -eq 0) {
        Write-Host "Setting the App roles"
        set-Custom-Roles-On-AppRegistration -ApplicationId $app.Id -AppRoles -JsonAppRoles $jsonAppRoles
    }else{ 
        Write-Host "Roles are already set, moving on..." 
    }

    $appSecrets = @()

    $needCredentials = Get-App-Credentials-Status -ApplicationName $ApplicationName 
    if ($needCredentials){
        $passCredential = Get-Password-Credentials -NumberOfMonths 6
        $mgApplicationPasswordObject = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential $passCredential
        $appSecrets += @{
            Name = "$ApplicationName-AzureADAppClientSecret"
            Value = $mgApplicationPasswordObject.SecretText
        }
    }
    $appSecrets += @{
        Name = "$ApplicationName-AzureADAppClientId"
        Value = $app.AppId
    }

    $appSecrets += @{
        Name = "$ApplicationName-AzureTenantId"
        Value = $directoryId
    }

    return $appSecrets
}

function Main {
    Add-App-Registration-For-Tenant -ApplicationName $appName
}
$jsonAppRoles = Get-Content -Path $jsonAppRolesFile -Raw | ConvertFrom-Json
$jsonApiPermission = Get-Content -Path $jsonApiPermissionFile -Raw | ConvertFrom-Json

Main
#requires -Module AzureAD
$AADModule = Import-Module -Name AzureAD -ErrorAction Stop -PassThru
$adalPath = Join-Path $AADModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalformPath = Join-Path $AADModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    [System.Reflection.Assembly]::LoadFrom($adalPath) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalformPath) | Out-Null  

function Get-AccessToken () {
    <#
       .SYNOPSIS
       Returns an access token for given resource.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$authority,

        [Parameter(Mandatory=$true)]
        [string]$resource,

        [Parameter(Mandatory=$false)]
        [string]$clientId,

        [Parameter(Mandatory=$false)]
        [string]$clientSecret
    )

    $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext] $authority

    if ($clientId -and $clientSecret) {
        # Using app id and app key
        $clientCred = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential" -ArgumentList $clientId, $clientSecret
        $task = $authContext.AcquireTokenAsync($resource, $clientCred)
    } else {
        # Delegate app id(Native application app id)
        $clientId = [string]<#YOUR DELEGATE APP ID HERE#>
        $redirectUri = New-Object system.uri("https://localhost:1234")
        $platformParams = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters([Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto)
        $task = $authContext.AcquireTokenAsync($resource, $clientId, $redirectUri, $platformParams)
    }

    Wait-Job $task
    return $task
    return $task.Result.AccessToken;
}

<#
    .SYNOPSIS
    Returns an access token that can be used to call the Intel Workbench API.
#>
function Get-AccessToken () {
    Param (
        [string] $URI,
        [string] $ClientId,
        [string] $ClientSecret
    )

    # Azure Active Directory Tenant ID (microsoft.com tenant ID) 
    $tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
    $authority = "https://login.microsoftonline.com/${tenantId}"

    $resource = $URI
    return Get-AccessToken $authority $resource $ClientId $ClientSecret
}

function Get-AuthHeader () {
    Param (
        [string] $URI,
        [string] $ClientId,
        [string] $ClientSecret
    )
    $task = Get-AccessToken -URI $URI -ClientId $ClientId -ClientSecret $ClientSecret
    $authHeader = @{
       'Content-Type'='application\json'
       'Authorization'=$task.result.CreateAuthorizationHeader()
    }
    return $authHeader

}

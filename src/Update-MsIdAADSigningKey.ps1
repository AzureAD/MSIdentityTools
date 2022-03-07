<#
.SYNOPSIS
    Update a Service Princpal's preferredTokenSigningKeyThumbprint value
.EXAMPLE
    PS C:\>Update-MsIdAADSigningKey -ApplicationId <ApplicationId> -KeyThumbprint <Thumbprint>
    Update Application preffered signing key
.EXAMPLE
    PS C:\>Update-MsIdAADSigningKey -ApplicationId <ApplicationId> -Default
    Update Application preffered signing key to 'unused'
#>

Param(
    $Tenant = "common",
    $Environment = "prod",

    [parameter(mandatory = $true)]
    [string]$ApplicationId,

    [parameter(parametersetname = "SpecificCert")]
    [string]$KeyThumbprint,

    [parameter(parametersetname = "Default")]
    [switch]$Default
)

Connect-MgGraph -Scopes "Application.ReadWrite.All"

if ($Default) { $KeyThumbprint = "unused" }

if ($null -ne $KeyThumbprint) {
    $KeyThumbprint = $KeyThumbprint.Replace(" ", "").ToLower()
}
$content = @{preferredTokenSigningKeyThumbprint = $KeyThumbprint }

$sp = Get-MgServicePrincipal -Filter "appId eq '$ApplicationId'"

if ($null -ne $sp) {
    Write-Host "Service principal found"
    ""
    Write-Host $sp.DisplayName
    ""
    Write-Host "Updating service principal..."
    Update-MgServicePrincipal -ServicePrincipalId $sp.id -BodyParameter $content

    Start-Sleep 5
    Get-MgServicePrincipal -ServicePrincipalId $sp.id | Select-Object objectId, appId, displayName, preferredTokenSigningKeyThumbprint | Format-List
}
else {
    Write-Host "Service principal was not found - Please check the Client (Application) ID"
}

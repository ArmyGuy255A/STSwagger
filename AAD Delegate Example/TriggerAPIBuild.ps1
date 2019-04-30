#Load the TestOAuth script
Set-Location $PSScriptRoot
. .\OAuth.ps1

#Trigger the Swagger API Build
$CmdletIdentifier = "Test"
$OutputDirectory = "~\Desktop\TestTrial"
$AdditionalScripts = @("~\Desktop\TestTrial\OAuth.ps1")

Function BuildAADApi () {
    Param (
        $URI,
        $ModuleName,
        $SwaggerJsonFile
    )
    try {
        Write-Host "Generating API for $ModuleName : $URI" -ForegroundColor Cyan
        $SwaggerJsonFile = ("{0}\{1}\{2}SwaggerSpecification.json" -f $OutputDirectory, $ModuleName, $CmdletIdentifier)
        New-Item $SwaggerJsonFile -ItemType File -Force | Out-Null
        #Download the swagger JSON file.
        Invoke-WebRequest -Uri ($URI + "/swagger/docs/v1") -OutFile $SwaggerJsonFile -Headers $(Get-AuthHeader -uri $URI)
        & .\STSwagger.ps1 -BaseURI $URI -SwaggerJsonFile $SwaggerJsonFile -CmdletIdentifier $CmdletIdentifier -OutputDirectory $OutputDirectory -ModuleName $ModuleName -AdditionalScripts $AdditionalScripts
        $(Get-Content ("{0}\{0}.psm1" -f $ModuleName)).Replace("[hashtable] `$Headers", "[hashtable] `$Headers = `$(Get-AuthHeader -URI '$URI')").Replace("[System.Collections.IDictionary]", "[hashtable]") | Set-Content ("{0}\{0}.psm1" -f $ModuleName)
    } catch {
        #Remove the directory
        Write-Warning "Unable to create $ModuleName"
        Remove-Item ("{0}\{1}" -f $OutputDirectory, $ModuleName) -Recurse -Force
    }
}

Function BuildDomainlessApi () {
    Param (
        $URI,
        $ModuleName
    )
    
    try {
        Write-Host "Generating API for $ModuleName : $URI" -ForegroundColor Cyan
        & .\STSwagger.ps1 -BaseURI $URI -SwaggerJsonURI "$URI/swagger/docs/v1" -CmdletIdentifier $CmdletIdentifier -OutputDirectory $OutputDirectory -ModuleName $ModuleName -AdditionalScripts $AdditionalScripts
    } catch {
        #Remove the directory
        Write-Warning "Unable to create $ModuleName"
        Remove-Item ("{0}\{1}" -f $OutputDirectory, $ModuleName) -Recurse -Force
    }
}

#Development AAD
BuildAADApi -URI "https://testwebsite.microsoft.com" -ModuleName "TestAAD"

Write-Host "Removing existing modules..."
try {
    Remove-Module *Test*
} catch {

}

Write-Host "Importing new AAD Module"
Import-Module .\TestAAD

Write-Host "Testing the new API..." -ForegroundColor Yellow
$result = Get-TestAnnouncementsAllAnnouncements

if ($result) {
    Write-Host "`t"$result.Title
} else {
    Write-Warning "API Call Failed..."
}
Write-Host "Done!" -ForegroundColor Green
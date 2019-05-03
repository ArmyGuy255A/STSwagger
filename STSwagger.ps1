<# DEV
Param (
    [Parameter(Mandatory=$True, ParameterSetName="Download")]
    [Parameter(Mandatory=$True, ParameterSetName="Local")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("(((f|ht){1}(tp|tps):\/\/)[\w\d\S]+)")]
        [string] $BaseURI,
    [Parameter(Mandatory=$True, ParameterSetName="Download")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("(((f|ht){1}(tp|tps):\/\/)[\w\d\S]+)")]
        [string] $SwaggerJsonURI,
    [Parameter(Mandatory=$True, ParameterSetName="Local")]
    [ValidateNotNullOrEmpty()]
        [string] $SwaggerJsonFile,
    [Parameter(Mandatory=$False, ParameterSetName="Download")]
    [Parameter(Mandatory=$False, ParameterSetName="Local")]
    [ValidateLength(0,5)]
    [ValidatePattern("^([A-Za-z0-9]){0,5}$")]
        [string] $CmdletIdentifier,
    [Parameter(Mandatory=$True, ParameterSetName="Download")]
    [Parameter(Mandatory=$True, ParameterSetName="Local")]
    [ValidateNotNullOrEmpty()]
        [string] $OutputDirectory,
    [Parameter(Mandatory=$True, ParameterSetName="Download")]
    [Parameter(Mandatory=$True, ParameterSetName="Local")]
    [ValidatePattern("^([A-Za-z0-9]){1,50}$")]
        [string] $ModuleName,
    [Parameter(Mandatory=$False, ParameterSetName="Download")]
    [Parameter(Mandatory=$False, ParameterSetName="Local")]
    [ValidateNotNullOrEmpty()]
        [string[]] $AdditionalScripts,
    [Parameter(Mandatory=$False, ParameterSetName="Download")]
    [Parameter(Mandatory=$False, ParameterSetName="Local")]
    [ValidateNotNullOrEmpty()]
        [hashtable] $ManifestParameters
)
 #>
 Param (
    [CmdletBinding(DefaultParameterSetName="Download")]
    [Parameter(Mandatory=$False, ParameterSetName="Download")]
    $BaseURI = "https://intelworkbench/",
    $SwaggerJsonURI = "https://intelworkbench/swagger/docs/v1/",
    $CmdletIdentifier = "Iwb",
    $OutputDirectory = "~\source\github\STSwagger",
    $ModuleName = "IntelWorkbench",
    $AdditionalScripts = @("C:\Users\b-phdiep\Desktop\IWBTrial\IwbOAuth.ps1")
 )


#Input Validation

#Base URI should not contain a forwardslash at the end of the string
$trailingSlashes = "(\\*$)|(\/*$)"
$BaseURI = $BaseURI -ireplace $trailingSlashes, ""
$OutputDirectory = $OutputDirectory -ireplace $trailingSlashes, ""
if ($PSCmdlet.ParameterSetName -eq 'Download') {
    $SwaggerJsonURI = $SwaggerJsonURI -ireplace $trailingSlashes, ""
}

#CmdletIdentifier

#This function converts a raw Swagger Json file to a usable Specification Object
function ConvertTo-STSwaggerSpecification () {
    Param (
        $SwaggerContent
    )

    #Build the specification object
    $paths = $SwaggerContent.paths | Get-Member -MemberType NoteProperty

    [array]$apis = @()

    #Iterate through each path and build custom objects that are easier to work with
    foreach ($path in $paths) {
        $pathObject = $SwaggerContent.paths.($path.name)
        $methods = $pathObject | Get-Member -MemberType NoteProperty

        #Iterate through each method type eg. Get, Post, Delete, etc.. under each path
        #TODO: Add Progress Tracker
        foreach ($methodType in $methods) {
            $method = $pathObject.($methodType.name)
            $methodMembers = $method | Get-Member -MemberType NoteProperty
            
            #Store each property in a hashtable
            $apiHT = @{}
            foreach ($methodMember in $methodMembers) {
                $apiHT.Add((Get-Culture).TextInfo.ToTitleCase($methodMember.Name.ToLower()), $method.($methodMember.Name))
            }
            $apiHT.Add("Path",$path.Name)
            $apiHT.Add("Method",$methodType.Name)

            #Turn the hashtable into a custom object
            $apis += New-Object -TypeName PSObject -Property $apiHT            
        }
    }
    
    #return the array of custom objects
    return $apis
}

#This function downloads / converts a Swagger json file to a PowerShell object
function Get-STSwaggerContent () {
    Param (
        [Parameter(ParameterSetName="1")]
        [Parameter(ParameterSetName="2")]
        [string] $Uri,
        [Parameter(ParameterSetName="1")]
        [Parameter(ParameterSetName="2")]
        [string] $OutFile = $null,
        [Parameter(ParameterSetName="1")]
        [PSCredential] $Credential,
        [Parameter(ParameterSetName="2")]
        [switch] $UseDefaultCredentials,
        [Parameter(ParameterSetName="3")]
        [string] $JsonFile
    )

    if ($PSCmdlet.ParameterSetName -eq "3") {
        $content = Get-Content $JsonFile | ConvertFrom-Json  
    } else {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseDefaultCredentials:$UseDefaultCredentials -Credential $Credential        
        $content = Get-Content $OutFile | ConvertFrom-Json
        if (!$content) { throw "Unable to download Swagger Specification file from: $Uri" }
    }
    if (!$content) { throw "Unable to load Swagger Specification file." }

    return $content
}

#This function converts RestMethods to approved PowerShell verbs
function ConvertFrom-RestMethod () {
    Param (
        $Method
    )
    $Methods =@{
        Access="Get"
        Acquire="Get"
        Activate="Initialize"
        Add="Add"
        Allocate="New"
        Analyze="Test"
        Append="Add"
        Apply="Add"
        Approve="Approve"
        Assert="Assert"
        Assign="Set"
        Associate="Join"
        Attach="Add"
        Authorize="Grant"
        Backup="Backup"
        Block="Block"
        Build="Build"
        Bypass="Skip"
        Cancel="Stop"
        Capture="Export"
        Cat="Get"
        Change="Rename"
        Check="Test"
        Checkpoint="Checkpoint"
        Clear="Clear"
        Clone="Copy"
        Close="Close"
        Combine="Join"
        Compare="Compare"
        Compile="Build"
        Complete="Complete"
        Compress="Compress"
        Concatenate="Add"
        Configure="Set"
        Confirm="Confirm"
        Connect="Connect"
        Convert="Convert"
        ConvertFrom="ConvertFrom"
        ConvertTo="ConvertTo"
        Copy="Copy"
        Create="New"
        Cut="Remove"
        Debug="Debug"
        Delete="Remove"
        Deny="Deny"
        Deploy="Deploy"
        Dir="Get"
        Disable="Disable"
        Discard="Remove"
        Disconnect="Disconnect"
        Discover="Find"
        Dismount="Dismount"
        Display="Show"
        Dispose="Remove"
        Dump="Get"
        Duplicate="Copy"
        Edit="Edit"
        Enable="Enable"
        End="Stop"
        Enter="Enter"
        Erase="Clear"
        Evaluate="Test"
        Examine="Get"
        Execute="Invoke"
        Exit="Exit"
        Expand="Expand"
        Export="Export"
        Failover="Set"
        Find="Find"
        Finish="Complete"
        Flush="Clear"
        ForceReboot="Restart"
        Format="Format"
        Generalize="Reset"
        Generate="New"
        Get="Get"
        Grant="Grant"
        Group="Group"
        Hide="Hide"
        Import="Import"
        Initialize="Initialize"
        Insert="Add"
        Install="Install"
        Into="Enter"
        Invoke="Invoke"
        Is="Test"
        Join="Join"
        Jump="Skip"
        Limit="Limit"
        List="Get"
        Load="Import"
        Locate="Find"
        Lock="Lock"
        Make="New"
        Measure="Measure"
        Merge="Merge"
        Migrate="Move"
        Mount="Mount"
        Move="Move"
        Name="Move"
        New="New"
        Notify="Send"
        Nullify="Clear"
        Obtain="Get"
        Open="Open"
        Optimize="Optimize"
        Out="Out"
        Patch="Update"
        Pause="Suspend"
        Perform="Invoke"
        Ping="Ping"
        Pop="Pop"
        Post="Invoke"
        Power="Start"
        PowerOff="Stop"
        PowerOn="Start"
        Produce="Show"
        Protect="Protect"
        Provision="New"
        Publish="Publish"
        Purge="Clear"
        Push="Push"
        Put="Set"
        Read="Read"
        Reassociate="Move"
        Reboot="Restart"
        Receive="Receive"
        Recover="Restore"
        Redo="Redo"
        Refresh="Update"
        Regenerate="New"
        Register="Register"
        Reimage="Update"
        Release="Publish"
        Remove="Remove"
        Rename="Rename"
        Repair="Repair"
        Replace="Update"
        Replicate="Copy"
        Reprocess="Update"
        Request="Request"
        Reset="Reset"
        Resize="Resize"
        Resolve="Resolve"
        Restart="Restart"
        Restore="Restore"
        Restrict="Lock"
        Resubmit="Submit"
        Resume="Resume"
        Retarget="Update"
        Retrieve="Get"
        Revoke="Revoke"
        Run="Start"
        Save="Save"
        Search="Search"
        Secure="Lock"
        Select="Select"
        Send="Send"
        Separate="Split"
        Set="Set"
        Show="Show"
        Shutdown="Stop"
        Skip="Skip"
        Split="Split"
        Start="Start"
        Step="Step"
        Stop="Stop"
        Submit="Submit"
        Suggest="Get"
        Suspend="Suspend"
        Swap="Switch"
        Switch="Switch"
        Sync="Sync"
        Synch="Sync"
        Synchronize="Sync"
        Test="Test"
        Trace="Trace"
        Transfer="Move"
        Trigger="Start"
        Type="Get"
        Unblock="Unblock"
        Undelete="Restore"
        Undo="Undo"
        Uninstall="Uninstall"
        Unite="Join"
        Unlock="Unlock"
        Unmark="Clear"
        Unprotect="Unprotect"
        Unpublish="Unpublish"
        Unregister="Unregister"
        Unrestrict="Unlock"
        Unsecure="Unlock"
        Unset="Clear"
        Update="Update"
        Upgrade="Update"
        Use="Use"
        Validate="Test"
        Verify="Test"
        Wait="Wait"
        Watch="Watch"
        Wipe="Clear"
        Write="Write"
    }
    $convertedMethod = $Methods.$Method
    if (!$convertedMethod) { Write-Error "Unable to convert $Method." }
    return $convertedMethod
}

#This function creates Approved PowerShell function names
function Get-STSwaggerFunctionName () {
    Param (
        [string] $Method,
        [string] $OperationId,
        [string] $Tag,
        [string] $CmdletIdentifier
    )

    $verb = ConvertFrom-RestMethod -Method $Method

    #Doctor the Operation Id. Replace any of the matches found here.
    $noun = $OperationId -ireplace $Method, ""
    $noun = $noun -ireplace "api_", ""
    $noun = $noun -ireplace "(A|a)(P|p)(I|i)$", ""
    $noun = $noun -ireplace "_$", ""
    #TODO: Might be worth trying to deduplicate consecutive words.

    #Build the approved function name here.
    return ("{0}-{1}{2}" -f $verb, $CmdletIdentifier, $noun)
}

#This function builds a grouped object containing function names and parameter sets
# that is used to create the PowerShell API module
function Initialize-STSwaggerAPI () {
    Param (
        $STSwaggerSpecification,
        [string]$ModuleName,
        [string]$CmdletIdentifier
    )

    #Check for multiple tags
    if ($STSwaggerSpecification | Where-Object {$_.Tags.Count -eq 2}) {
        Write-Warning "Possible errors could occur."
    }

    #Get each tag. There will be one cmdlet for each tag
    $tags = $STSwaggerSpecification | Select-Object -Property Tags,Method,OperationId,Path -Unique

    #Clear the array within the tags.
    $tags | ForEach-Object {$_.Tags = $_.Tags -join ","}

    #Group the tags together by tag. Each Tag will be its own Module file
    $tags = $tags | Group-Object -Property Tags
 

    $functionSchema = @{Function="";OperationIds="";Method="";Tags=""; Module=""; Path = ""}
    $functionObjects = @()

    #Loop through each module
    foreach ($module in $tags) {
        #Loop through each function in each module and generate the raw API object that is used to create the function
        foreach ($function in $module.Group) {
            $functionObject = New-Object -TypeName PSObject -Property $functionSchema
            $functionObject.Function = Get-STSwaggerFunctionName -Method $function.Method -OperationId $function.OperationId -Tag $function.Tags -CmdletIdentifier $CmdletIdentifier
            $functionObject.OperationIds = $function.Operationid
            $functionObject.Method = $function.Method
            $functionObject.Tags = $function.Tags
            $functionObject.Module = $module.Name
            $functionObject.Path = $function.Path
            $functionObjects += $functionObject
        }        
    }

    #TODO: Add a check to ensure duplicate function names are not created.

    return $functionObjects
}

#This converts the Rest parameter type to a PowerShell type
function ConvertTo-PowerShellType () {
    Param (
        $ParameterObject
    )

    if ($ParameterObject.Schema -ne $null) {
        #Pull from the schema
        if ($ParameterObject.Schema.Type -eq "array") {
            if ($ParameterObject.Schema.items.type -ne $null) {
                return "{0}[]" -f $ParameterObject.Schema.items.type
            } else {
                return "object[]"
            }
            
        } else {
            #It's probably a definition reference
        }
    }

    if ($ParameterObject.Type -eq "string") {
        return "string"
    } elseif ($ParameterObject.Type -eq "integer") {
        return "int"
    } elseif ($ParameterObject.Type -eq "boolean") {
        return "switch"
    } else {
        return "object"
    }
}

#This generates the Param() block for a function using the specification and the API object
function Get-STSwaggerPowerShellParams {
    Param (
        $STSwaggerAPIObject,
        $STSwaggerSpecification
    )

    #Get all the proper specifications for the API object
    $specs = $STSwaggerSpecification | Where-Object {$STSwaggerAPIObject.OperationIds.Contains($_.OperationId)}

    #Loop through each specification and build the parameter sets
    $parameterSets = @()

    # Loop through each specification
    foreach ($spec in $specs) {
        #Loop through each parameter in each specification
        foreach ($parameter in $spec.Parameters) {
            #Add
            $tempParam = New-Object -TypeName PSObject -Property @{Name = $parameter.name; Type = $parameter.type; Mandatory = $parameter.required; HelpMessage = $parameter.description; Schema = $parameter.schema; Sets = [System.Collections.ArrayList]@()}
            $tempParam.Sets += $spec.Path
            $parameterSets += $tempParam
        }
    }

    #Group the parameterSets based on name
    $parameterSets = $parameterSets | Group-Object -Property Name
    $defaultParameterSet = ""

    #Use the first specification which is usually parameterless
    $defaultParameterSet = "[CmdletBinding(DefaultParameterSetName=`"{0}`")]`n" -f $specs[0].Path


    $parameterStrings = @()
    $parameterString = ""
    #Build the parameter set strings
    foreach ($parameter in $parameterSets) {
        #Get each parameter set name
        $parameterString = ""
        $uniqueParameterSets = $parameter.Group.Sets | Select-Object -Unique
        foreach ($setName in $uniqueParameterSets) {
            #$helpMessage = $parameter.Group.HelpMessage | Sort-Object -Descending | Select-Object -First 1
            $parameterString += "`t`t[Parameter(Mandatory=`${0}, ParameterSetName='{1}')]`n" -f ($parameter.Group.Mandatory | Select-Object -Unique), $setName
            
        }
        $parameterString += "`t`t`t[{0}] `${1}" -f (ConvertTo-PowerShellType $parameter.Group), ($parameter.Group.Name | Select-Object -Unique)
        $parameterStrings += $parameterString        
    }

    #Add the credential property using each of the parametersets
    $parameterString = ""
    foreach ($setName in ($parameterSets.Group.Sets | Select-Object -Unique)) {
        #Get each parameter set name
        $parameterString += "`t`t[Parameter(Mandatory=`$False, ParameterSetName='{0}')]`n" -f $setName                
    }

    $parameterString += "`t`t`t[PSCredential] `$Credential"
    $parameterStrings += $parameterString

    #Add the header property for each parameterset
    $parameterString = ""
    foreach ($setName in ($parameterSets.Group.Sets | Select-Object -Unique)) {
        #Get each parameter set name
        $parameterString += "`t`t[Parameter(Mandatory=`$False, ParameterSetName='{0}')]`n" -f $setName                
    }

    $parameterString += "`t`t`t[hashtable] `$Headers"
    $parameterStrings += $parameterString


    #return $defaultParameterSet + "`tParam (`n" + ($parameterStrings -join ",`n") + "`n`t)"
    return $defaultParameterSet + "`tParam (`n" + ($parameterStrings -join ",`n") + "`n`t)"

}

function Get-STSwaggerPowerShellParameterSetUris () {
    Param (
        $STSwaggerAPIObject,
        $STSwaggerSpecification
    )

    #Get all the proper specifications for the API object
    $specs = $STSwaggerSpecification | Where-Object {$STSwaggerAPIObject.OperationIds.Contains($_.OperationId)}

    $switch = @"
`$URI = ""
`tswitch (`$PSCmdlet.ParameterSetName)
`t{
{URIS}
`n`t}
"@
    $paths = @()
    foreach ($spec in $specs) {
        $pathString = "`t`t`"{0}`" " -f $spec.Operationid
        $pathStringUri = "`$URI = `"{0}`"" -f $spec.Path
        $pathString += "{ " + $pathStringUri + " }"
        
        $paths += $pathString
    }

    return $switch.Replace("{URIS}", $paths -join "`n")
   
}

function Get-STSwaggerPowerShellHelp () {
    Param (
        $STSwaggerAPIObject,
        $STSwaggerSpecification
    )

    #Get all the proper specifications for the API object
    $spec = $STSwaggerSpecification | Where-Object {$STSwaggerAPIObject.OperationIds.Contains($_.OperationId)}

    $helpTemplate = @"
<#
.DESCRIPTION
`t{SUMMARY}
{PARAMETERS}
#>
"@
    $parameters = @()
    foreach ($parameter in $spec.Parameters) {
        $parameterString = ""
        $parameterString += ".PARAMETER {0}`n" -f $parameter.name
        $parameterString += "`t{0}" -f $parameter.description
        $parameters += $parameterString
    }

    return $helpTemplate.Replace("{SUMMARY}", $spec.Summary).Replace("{PARAMETERS}", $parameters -join "`n")
   
}

#Generates the template used to create a function
function New-STSwaggerPowerShellFunctionTemplate {
    $template = @"
{HELP}
Function {FUNCTIONNAME} {
    {PARAMS}

    `$URI = Get-STSwaggerRestURI -Parameters `$PSBoundParameters -Uri `$PSCmdlet.ParameterSetName

    Invoke-STSwaggerRestApi -URI `$URI -Method {METHOD} -Credential `$Credential -Headers `$Headers
}
"@

    #Return the template
    return $template
}

function New-STSwaggerPowerShellCoreFunctions {
    Param (
        $BaseURI,
        $CmdletIdentifier
    )

    $coreFunctions = @"
`n
`$ENV:$CmdletIdentifier`BaseURI = '$($BaseURI -creplace "/$", "")'
function Get-STSwaggerRestUri () {
    Param (
        `$Parameters,
        `$Uri
    )

    `$options = @()
    foreach (`$boundParameter in `$Parameters.Keys) {
        #Exclude the credential parameter
        if (`$boundParameter -eq "Credential") { continue }
        #Exclude the headers parameter
        if (`$boundParameter -eq "Headers") { continue }
        if (`$Uri.Contains("{`$boundParameter}")) {
            `$Uri = `$Uri.Replace("{`$boundParameter}", `$Parameters.`$boundParameter)
        } else {
            `$options += "{0}={1}" -f `$boundParameter, `$Parameters.`$boundParameter
        }
    }
    if (`$options) { `$Uri += "?" + (`$options -join "&") }
    
    return `$ENV:$CmdletIdentifier`BaseURI + `$Uri
}

#This function invokes the rest method 
Function Invoke-STSwaggerRestApi {
    Param(
        [Parameter(Mandatory=`$true)]
        [string] `$Uri,
        [Parameter(Mandatory=`$true)]
        [string] `$Method,
        [Parameter(Mandatory=`$false)]
        [PSCredential] `$Credential = `$null,
        [Parameter(Mandatory=`$false)]
        [System.Collections.IDictionary] `$Headers = `$null
    )
    Write-Host `$Uri -ForegroundColor Magenta      
    `$result = `$null
    if (`$Credential) {
        `$result = Invoke-RestMethod -Uri `$URI -Method `$Method -ContentType "application/json" -Credential `$Credential
    } elseif (`$Headers) {
        `$result = Invoke-RestMethod -Uri `$URI -Method `$Method -ContentType "application/json" -Headers `$Headers
    } else {
        `$result = Invoke-RestMethod -Uri `$URI -Method `$Method -ContentType "application/json" -UseDefaultCredentials
    }

    if (!`$result -or `$result -eq "null") {
        return `$null
    }

    return `$result
}
"@
    return $coreFunctions
}

#Converts the STSwaggerAPI object to a PowerShell API
function ConvertTo-STSwaggerPowerShellAPI () {
    Param (
        $STSwaggerAPI,
        $STSwaggerSpecification,
        $BaseURI
    )

    $functions = @()
    foreach ($STSwaggerAPIObject in $STSwaggerAPI) {
            
        #Generate the template
        $functionBody = New-STSwaggerPowerShellFunctionTemplate
        #Generate the parameters        
        $params = Get-STSwaggerPowerShellParams -STSwaggerAPIObject $STSwaggerAPIObject -STSwaggerSpecification $STSwaggerSpecification
        #Generate the URIs
        $uris = Get-STSwaggerPowerShellParameterSetUris -STSwaggerAPIObject $STSwaggerAPIObject -STSwaggerSpecification $STSwaggerSpecification
        $help = Get-STSwaggerPowerShellHelp -STSwaggerAPIObject $STSwaggerAPIObject -STSwaggerSpecification $STSwaggerSpecification
        #Generate the mapping
        $functionBody = $functionBody.Replace("{PARAMS}", $params)
        #$functionBody = $functionBody.Replace("{URISWITCH}", $uris)
        $functionBody = $functionBody.Replace("{FUNCTIONNAME}", $STSwaggerAPIObject.Function)
        $functionBody = $functionBody.Replace("{HELP}", $help)
        $functionBody = $functionBody.Replace("{METHOD}", $STSwaggerAPIObject.Method)

        
        $function = New-Object -TypeName PSObject -Property @{CmdletName = $STSwaggerAPIObject.Function; Module = $STSwaggerAPIObject.Module; Function = $functionBody}
        $functions += $function         
    }
    return $functions
}


$ModuleDirectory = "{0}\{1}" -f $OutputDirectory, $ModuleName
$SwaggerOutFile = "{0}\{1}SwaggerSpecification.json" -f $ModuleDirectory, $CmdletIdentifier
$PowerShellModuleFile = "{0}\{1}.psm1" -f $ModuleDirectory, $ModuleName
$PowerShellManifestFile = "{0}\{1}.psd1" -f $ModuleDirectory, $ModuleName
#Make the module output directory
if (!(Test-Path $ModuleDirectory)) {
    New-Item $ModuleDirectory -ItemType Directory | Out-Null
}

#Load the swagger specification file
$swaggerContent = ""
if ($PSCmdlet.ParameterSetName -eq "Download" -or $PSCmdlet.ParameterSetName -eq "__AllParameterSets") {
    Write-Host "Downloading Specification File."
    $swaggerContent = Get-STSwaggerContent -Uri $SwaggerJsonURI -UseDefaultCredentials -OutFile $SwaggerOutFile
} else {
    
    $swaggerContent = Get-STSwaggerContent -JsonFile $SwaggerJsonFile
}
if (!$swaggerContent) { 
    Write-Error "Unable to load Swagger Specification content."
    exit 
}

#Format the swagger specification
Write-Host "Creating the STSwagger specification..."
$specification = ConvertTo-STSwaggerSpecification -SwaggerContent $swaggerContent
if (!$specification) { Write-Error "Unable to create a STSwagger Specification" }

#Build the raw API objects used to create the PowerShell functions
Write-Host "Creating the STSwagger API Objects..."
$rawAPIObjects = Initialize-STSwaggerAPI -STSwaggerSpecification $specification -ModuleName $ModuleName -CmdletIdentifier $CmdletIdentifier
if (!$rawAPIObjects) { Write-Error "Unable to create a STSwagger API objects" }

#Build the PowerShell functions
Write-Host "Building the STSwagger PowerShell API..."
$powershellApi = ConvertTo-STSwaggerPowerShellAPI -STSwaggerAPI $rawAPIObjects -STSwaggerSpecification $specification -BaseURI $BaseURI
if (!$powershellApi) { Write-Error "Unable to build the STSwagger PowerShell API" }

#Build the core functions needed to execute the PowerShell API
Write-Host "Building the STSwagger PowerShell Core API..."
$powershellCoreApi = New-STSwaggerPowerShellCoreFunctions -BaseURI $BaseURI -CmdletIdentifier $CmdletIdentifier
if (!$powershellCoreApi) { Write-Error "Unable to build the STSwagger PowerShell Core API" }

#Create the files
Write-Host "Writing the API out to : $PowerShellModuleFile"
$powershellApi.Function > $PowerShellModuleFile
$powershellCoreApi >> $PowerShellModuleFile

#Make the module manifest
if (!$ManifestParameters) {
    Write-Host "Using default manifest parameters..."
    $ManifestParameters = @{
        Path = $PowerShellManifestFile;
        FunctionsToExport = $powershellApi.CmdletName;
        ScriptsToProcess = $AdditionalScripts;
        Description = "This PowerShell API wrapper was generated with the STSwagger API Library.";
        HelpInfoUri = "https://github.com/ArmyGuy255a/STSwagger";
        Author = "Phillip A. Dieppa";
        CompanyName = "Microsoft";
        PowerShellVersion = "5.0";
        ModuleVersion = [version]::new($swaggerContent.swagger)
        RootModule =("{0}.psm1" -f $ModuleName)
    }
} else {
    Write-Host "Using user supplied manifest parameters..."
}

try {
    Write-Host "Creating Module Manifest file."
    New-ModuleManifest @ManifestParameters
} catch {
    Write-Error "Unable to create the Module Manifest."
}

if ($AdditionalScripts) { 
    #Copy dependency scripts to the module directory
    Write-Host "Copying dependency scripts..."
    $AdditionalScripts | ForEach-Object {Copy-Item $_ $ModuleDirectory} 
}

Write-Host "Successfully executed the STSwagger PowerShell API Builder. Thanks for using STSwagger to build your PowerShell API!" -ForegroundColor Green
Start-Sleep -Seconds 5

<#Examples
#Using Swagger V1
& .\STSwagger.ps1 -BaseURI https://swaggerwebsite -SwaggerJsonURI "https://swaggerwebsite/swagger/docs/v1" -CmdletIdentifier $CmdletIdentifier -OutputDirectory $OutputDirectory -ModuleName $ModuleName -AdditionalScripts $AdditionalScripts


#Using Swagger V2
& .\STSwagger.ps1 -BaseURI "https://petstore.swagger.io/v2" -SwaggerJsonURI "https://petstore.swagger.io/v2/swagger.json" -CmdletIdentifier "PetStore" -OutputDirectory $OutputDirectory -ModuleName "Petstore" -AdditionalScripts $AdditionalScripts


#>
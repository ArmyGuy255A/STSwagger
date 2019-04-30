# STSwagger
STSwagger is a PowerShell script that can be used to create PowerShell modules from a Swagger API.

### Description
STSwagger is a custom-built script that is used to convert a Swagger REST API to a PowerShell API Wrapper. The script will create a rudimentary, but mostly working core API for the module. In fact, depending on the type of authentication required, no changes will be required.

## Example
Follow these steps to create a sample PowerShell API using Swagger's demo site.

1. Collect the base URL for the Swagger site. This can be achieved by navigating to the Swagger REST API page. You can usually do a search for "base" on the page and find the base URL.
    - "https://petstore.swagger.io"
    - Base URL: "https://petstore.swagger.io/v2"
2. Collect the 'swagger.json' specification file. The URL of the file depends on the version of swagger. See below for possible locations of the swagger file.
    a. V1: Base URL + /swagger/docs/v1
        Example: "https://swaggerwebsite/swagger/docs/v1"
    b. V2: Base URL + /swagger.json
        Example: "https://petstore.swagger.io/v2/swagger.json"
3. Use the -CmdletIdentifier property to prefix the function nouns in the module
4. Specify an output directory for the module. The script will create the directory and place the module and module manifest in the new directory.
5. If any dependency scripts are required, use the -AdditionalScripts property to pass STSwagger an array of strings with the script paths.
6. Execute the following commands:
```powershell
$OutputDirectory = "~\Desktop\DemoAPI"
.\STSwagger.ps1 -BaseURI "https://petstore.swagger.io/v2" -SwaggerJsonURI "https://petstore.swagger.io/v2/swagger.json" -CmdletIdentifier "Pet" -OutputDirectory $OutputDirectory -ModuleName "Petstore"
Import-Module ~\Desktop\DemoAPI\PetStore
Get-Command -Module PetStore
#Test one of the GET commands
```

## How It Works
STSwagger performs its operation in several phases. 

### **Phase 1 - Creating the Specification**
Phase 1 consists of downloading or reading the specified swagger.json specification file. The script converts the json object to several PSCustom objects that can be parsed easily by the next phase. 

### **Phase 2 - Build raw API Objects**
Phase 2 builds an array of PSCustomObjects referred to as 'raw API objects' The raw API objects contain all the necessary data to successfully create a PowerShell function. That is, the REST methods are converted into approved PowerShell verbs. It also extracts the description text and the base URI required for the API call.

### **Phase 3 - Building the PowerShell API**
Phase 3 actually constructs the Swagger PowerShell functions. STSwagger contains a function template that is used to replace certain keys with programatically created elements. REST Data Types are converted to appropriate PowerShell data types. This phase builds the functions that can be used by STSwagger's core API functions which construct the complete URL that will be called. You will notice that ParameterSets are used in the functions to determine the appropriate URL to pass into the core API. Two parameters are always added to every function **Credential** and **Headers**

### **Phase 4 - Build the STSwagger Core API**
The core API does two important things:
1. Constructs the complete URL
2. Executes the REST method

### **Phase 5 - Saves the API**
STSwagger will attempt to create a new directory in the **OutputDirectory** with the **ModuleName**. It will deposit any **AdditionalScripts**, the module, and the manifest file into the module's directory. 

# STSwagger Parameters
There are two ways to execute STSwagger.ps1

```powershell
STSwagger.ps1 -BaseURI <string> -SwaggerJsonFile <string> -OutputDirectory <string> -ModuleName <string> [-CmdletIdentifier <string>] [-AdditionalScripts <string[]>] [-ManifestParameters <hashtable>] [<CommonParameters>]
```
```powershell
STSwagger.ps1 -BaseURI <string> -SwaggerJsonURI <string> -OutputDirectory <string> -ModuleName <string> [-CmdletIdentifier <string>] [-AdditionalScripts <string[]>] [-ManifestParameters <hashtable>] [<CommonParameters>]
```
### **BaseURI**
The Base URI that is used to build the first portion of the API URL

### **SwaggerJsonURI**
The URI used to download the swagger Json file

### **SwaggerJsonFile**
The path to the swagger Json file

### **OutputDirectory**
The path where the Module will be created

### **ModuleName**
The name of the module

### **CmdletIdentifier**
A 5-character prefix added to the PowerShell noun. The PowerShell function consisits of a Verb and Noun combination. That is, Verb-Noun.

### **AdditionalScripts**
An array of strings that your module may rely on. This could be used to add additional logic do the module for using different authentication methods like OAuth and OAuth2. An example required script array is provided below.
```powershell
@(
    "~\Desktop\DemoAPI\requiredScript1.ps1",
    "~\Desktop\DemoAPI\requiredAuthScript.ps1"
)
```

### **ManifestParameters**
Parameters used to build the manifest file. By default, the manifest will export every function that the API created. You could customize the parameters to only export certain types of commands, like GET-only commands. The default manifest parameters are listed below.
```powershell
@{
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
```

# Final Touches
STSwagger works well for creating the baseline API for your Swagger API. In my case, I had to use a different script that executed the STSwagger script. This is because I needed to replace certain elements within the script with default parameters. For example, my API uses Azure Active Directory and a delegate app for authentication. Therefore, default credentials did not work and I had to acquire a token from the delegate before I could use the PowerShell API. Here are the steps I followed to get this to work.
1. Create the API using STSwagger
2. Replace every occurence of `[hashtable] $Headers` with a function provided in **AdditionalScripts**, so mine looked like `[hashtable] $Headers = Get-AuthHeader -URI $URI`
3. Now, everytime a function is called, it attempts to get the AuthHeader and pass it into the function as a default choice.

An AAD Delegate example is provided in the source directory. 
1. Ensure STSwagger, OAuth, and TriggerAPIBuild are all in the same directory
2. Ensure all three files are in `~\Desktop\TestTrial`
3. Then run ```powershell .\TriggerAPIBuild.ps1```
4. The script will likely fail because you must provide a valid URL for **BuildAADApi** in `TriggerAPIBuild.ps1` and a valid Delegate App ID in `OAuth.ps1`.
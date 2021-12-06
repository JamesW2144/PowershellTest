Function Test-Cloudflare {
<#
.Synopsis
This will test connection to the CloudFlare DNS
.Description
This command will test the connection through the internet via CloudFlare's One.One.One.One DNS Server
.Parameter Path
Path represents the working file directory and where the results of the test will be saved. Default is current user home directory.
.Parameter Computername
Computername specifies the computer being tested.
.Parameter Output
Specifies the destination of the output when the script is ran. Accepted Values:
- Host (Output sent to screen)
- Text (Output sent to .txt file)
- CSV (Output sent to .csv file)
Both file options are saved in the users home directory. Default output option is Host.
.Notes
Author: James Wilson
Last Edit: 2021-11-7
Version 1.11 - Added exception handling to the ForEach loop
             - Modified object creation to use [pscustomobject]

--- Example 1 ---

PS C:\>.\Test-CloudFlare -computername JamesPC

Test connectivity to CloudFlare DNS on the computer specified.


--- Example 2 ---

PS C:\>.\Test-CloudFlare -Output Host

Test connectivity to cloudflare but write results to the screen


--- Example 3 ---

PS C:\>.\Test-CloudFlare -Path C:\Documents

Test connectivity to cloudflare but save results to the Documents folder
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
    [Alias('CN','Name')]
    [string[]]$computername,
    [Parameter(Mandatory=$False)]
    [string]$Path = "$Env:USERPROFILE",
    [Parameter(Mandatory=$False)]
    [ValidateSet("Host","Text","CSV")]
    [string]$Output = "Host"
) #Param

BEGIN{}

PROCESS {
# Running a test net connection for each computer.
foreach ($computer in $computername) {
    Try {
        $params = @{'Computername'=$computer
                    'ErrorAction'='Stop'
                }
    
    $DateTime = Get-Date

    Write-Verbose "Connecting to $computer ..."

    # Connecting to a remote session.
    $session = New-PSSession @params

    # Running the ping/connection test.
    $TestCF = test-netconnection -computername 'one.one.one.one' -InformationLevel Detailed
    Write-Verbose "Testing connection to CloudFlare's DNS with $computer ..."

    #Create a new object with specified properties
    $obj = [pscustomobject]@{'ComputerName'= $computer
               'PingSuccess'= $TestCF.PingSucceeded
               'NameResolve'= $TestCF.NameResolutionSucceeded
               'ResolvedAddresses'= $TestCF.ResolvedAddresses
            } #Object    
 
    #Closes session to the remote computer(s)
    Remove-PSSession $computer
        }
    Catch {
        Write-Host "Remote connection to $computer failed." -ForegroundColor Red
    } #Try/Catch

} #foreach

# Retrieving the job results and adding it to a .txt, .CSV, or displayed to screen depending on Output parameter.
Write-Verbose "Receiving test results ..."
switch ($Output) {
    "Host" {$obj}
    "Text" {
        $obj | Out-File $Path\TestResults.txt
        Add-Content $Path\RemTestNet.txt -Value "Computer Used for Testing: $Computer"
        Add-Content $Path\RemTestNet.txt -Value "When it was tested: $DateTime"
        Add-Content $Path\RemTestNet.txt -Value (Get-Content $Path\TestResults.txt)
        Notepad $Path\RemTestNet.txt
    }
    "CSV" {
         $obj | Export-Csv -path $Path\TestResults.Csv
} 
   } #switch

Write-Verbose "Getting results ..."

Write-Verbose "Test Finished."

} #process
END {}

} #function
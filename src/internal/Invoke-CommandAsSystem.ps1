<#
.SYNOPSIS
    Run PowerShell commands under system context.
.EXAMPLE
    PS C:\>Invoke-CommandAsSystem { [System.Security.Principal.WindowsIdentity]::GetCurrent().Name }
    Run the ScriptBlock under the system context.
.INPUTS
    System.Management.Automation.ScriptBlock
.LINK
    https://github.com/jasoth/Utility.PS
#>
function Invoke-CommandAsSystem {
    [CmdletBinding()]
    param (
        #
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [ScriptBlock] $ScriptBlock,
        #
        [Parameter(Mandatory = $false, Position = 2)]
        [string[]] $ArgumentList
    )

    [guid] $GUID = New-Guid

    try {
        ## Register ScheduleJob
        if ($ArgumentList) {
            $ScheduledJob = Register-ScheduledJob -Name $GUID -ScheduledJobOption (New-ScheduledJobOption -RunElevated) -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -ErrorAction Stop
        }
        else {
            $ScheduledJob = Register-ScheduledJob -Name $GUID -ScheduledJobOption (New-ScheduledJobOption -RunElevated) -ScriptBlock $ScriptBlock -ErrorAction Stop
        }

        try {
            ## Register ScheduledTask for ScheduledJob
            $ScheduledTask = Register-ScheduledTask -TaskName $GUID -Action (New-ScheduledTaskAction -Execute $ScheduledJob.PSExecutionPath -Argument $ScheduledJob.PSExecutionArgs) -Principal (New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest) -ErrorAction Stop

            ## Execute ScheduledTask Job to Run ScheduledJob Job
            $ScheduledTask | Start-ScheduledTask -AsJob -ErrorAction Stop | Wait-Job | Remove-Job -Force -Confirm:$False

            ## Wait for ScheduledTask to finish
            While (($ScheduledTask | Get-ScheduledTaskInfo).LastTaskResult -eq 267009) { Start-Sleep -Milliseconds 150 }

            ## Find ScheduledJob and get the result
            $Job = Get-Job -Name $GUID -ErrorAction SilentlyContinue | Wait-Job
            $Result = $Job | Receive-Job -Wait -AutoRemoveJob
        }
        finally {
            ## Unregister ScheduledTask for ScheduledJob
            $ScheduledTask | Unregister-ScheduledTask -Confirm:$false
        }
    }
    finally {
        ## Unregister ScheduleJob
        $ScheduledJob | Unregister-ScheduledJob -Force -Confirm:$False
    }

    return $Result
}


    function Set-MsIdServicePrincipalVisibleInMyApps {
    <#
    .SYNOPSIS
        Toggles whether application service principals are visible when launching myapplications.microsoft.com (MyApps)

    .DESCRIPTION
        For each provided service principal ID, this cmdlet will add (or remove) the 'HideApp' tag to (or from) its list of tags.

        MyApps reads this tag to determine whether to show the service principal in the UX.

        -Verbose will give insight into the cmdlet's activities.

        Requires Application.ReadWrite.All (to manage service principals), i.e. Connect-MgGraph -Scopes Application.ReadWrite.All

    .PARAMETER Visible
        Whether to show or hide the SP. Supply $true or $false.

    .PARAMETER InFile
        A file specifying the list of SP IDs to process. Provide one guid per line with no other characters.

    .PARAMETER OutFile
        (Optional) The list of changed SPs is written to a file at this location for easy recovery. A default file will be generated if a path is not provided.

    .PARAMETER WhatIf
        (Optional) When set, shows which SPs would be changed without changing them.

    .PARAMETER Top
        (Optional) The number of SPs to process from the list with each request. Default 100.

    .PARAMETER Skip
        (Optional) Determines where in the list to begin executing.

    .PARAMETER Continue
        (Optional) After a failure due to request throttling, set this to the number of inputs that were evaluated before throttling began on the previous request.

    .EXAMPLE
        Set-MsIdServicePrincipalVisibleInMyApps -Visible $false -InFile .\sps.txt -OutFile .\output.txt -Verbose

        Adds the 'HideApp' tag for each Service Principal listed by guid in the sps.txt file. This ensures that the app is no longer visible in the MyApps portal.

        Creates a list of changed SPs, written to output.txt, at the script execution directory.

        Provides verbose output to assist with monitoring.

    .EXAMPLE
        Set-MsIdServicePrincipalVisibleInMyApps -Visible $true -InFile .\sps.txt -OutFile .\output.txt -Verbose

        Removes the 'HideApp' tag for each Service Principal listed by guid in the sps.txt file. This ensures that the app is visible in the MyApps portal.

        Creates a list of changed SPs, written to output.txt, at the script execution directory.

        Provides verbose output to assist with monitoring.

    .EXAMPLE
        Set-MsIdServicePrincipalVisibleInMyApps -Visible $true -InFile .\sps.txt -WhatIf

        Removes the 'HideApp' tag for each Service Principal listed by guid in the sps.txt file. This ensures that the app is visible in the MyApps portal.

        Provides a 'whatif' analysis to show what would've been updated without the -WhatIf switch.

    .EXAMPLE
        Set-MsIdServicePrincipalVisibleInMyApps -Visible $true -InFile .\sps.txt -WhatIf -Top 200

        Removes the 'HideApp' tag for each Service Principal listed by guid in the sps.txt file. This ensures that the app is visible in the MyApps portal.

        Provides a 'whatif' analysis to show what would've been updated without the -WhatIf switch. Processes 200 service principals.

    .NOTES
        THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
        FITNESS FOR A PARTICULAR PURPOSE.

        This sample is not supported under any Microsoft standard support program or service. 
        The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
        implied warranties including, without limitation, any implied warranties of merchantability
        or of fitness for a particular purpose. The entire risk arising out of the use or performance
        of the sample and documentation remains with you. In no event shall Microsoft, its authors,
        or anyone else involved in the creation, production, or delivery of the script be liable for 
        any damages whatsoever (including, without limitation, damages for loss of business profits, 
        business interruption, loss of business information, or other pecuniary loss) arising out of 
        the use of or inability to use the sample or documentation, even if Microsoft has been advised 
        of the possibility of such damages, rising out of the use of or inability to use the sample script, 
        even if Microsoft has been advised of the possibility of such damages.   


    #>
    [CmdletBinding()]
    Param(

        [Parameter(Mandatory=$true)]
        [bool]$Visible,

        [Parameter(Mandatory=$true)]
        [string]$InFile,

        [Parameter(Mandatory=$false)]
        [string]$OutFile,

        [Parameter(Mandatory=$false)]
        [switch]$WhatIf,

        [Parameter(Mandatory=$false)]
        [int]$Top=100,

        [Parameter(Mandatory=$false)]
        [int]$Skip=0,

        [Parameter(Mandatory=$false)]
        [int]$Continue=0
    )

    begin {
        function ConvertTo-ValidGuid {
            Param(
                [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
                [string]$Value
            )
        
            try {
                $id = [System.Guid]::Parse($value)
                return $id
            } catch {
                Write-Warning "$(Get-Date -f T) - Failed to parse SP id: $($value)"
                return $null
            }
        }
        
        function ConvertTo-ServicePrincipal {
            Param(
                [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
                [string]$Value
            )
        
            try {
                $sp = Get-MgServicePrincipal -ServicePrincipalId $Value
                if ($null -eq $sp) {
                    Write-Warning "$(Get-Date -f T) - SP not found for id: $($Value)"
                }
                else {
                    Write-Verbose "$(Get-Date -f T) - SP found for id: $($Value)"
                }
                return $sp

            } catch {
                # 429 means we are being throttled
                # so we want to back off from additional calls as well
                if ($_ -Contains '429') {
                    throw $_
                }
                Write-Warning "$(Get-Date -f T) - Error retrieving SP: $($Value)"
                return $null
            }
        }
        
        function Assert-IsHidden {
            Param(
                [Parameter(Mandatory=$true)]
                [Object]$Sp,
        
                [Parameter(Mandatory=$true)]
                [bool]$Value
            )
        
            return ($Sp.Tags -Contains $Tag_HideApp) -eq $Value
        }
        
        function Set-IsHidden {
            Param(
                [Parameter(Mandatory=$true)]
                [Object]$Sp,
        
                [Parameter(Mandatory=$true)]
                [bool]$Value
            )
        
            if ($Value) {
                $tags = $Sp.Tags + $Tag_HideApp
            } else {
                if (($Sp.Tags.count -eq 1) -and ($Sp.Tags -Contains $Tag_HideApp)) {
                    $tags = @()
                } else {
                    $tags = $Sp.Tags | Where-Object {$_ -ne $Tag_HideApp}
                }
            }
        
            try {
                Update-MgServicePrincipal -ServicePrincipalId $Sp.Id -Tags $tags
                return $true
            } catch {
                # 429 means we are being throttled
                # so we want to back off from additional calls as well
                if ($_ -Contains '429') {
                    throw $_
                }
                Write-Warning "$(Get-Date -f T) - Error setting SP tags: $($Sp.Id)"
                return $false
            }
        }
        
        function New-OutFile {
            Param(
                [Parameter(Mandatory=$true)]
                [string]$Path
            )
        
            if (Test-Path -Path $Path) {
                Clear-Content -Path $Path
            } else {
                New-Item -Path $Path -ItemType "file" > $null
            }
        }

        ## Initialize Critical Dependencies

        $CriticalError = $null
        try {
            #Import-Module Microsoft.Graph.Reports -ErrorAction Stop
            Import-Module Microsoft.Graph.Applications -MinimumVersion 1.10.0 -ErrorAction Stop
        }
        catch { Write-Error -ErrorRecord $_ -ErrorVariable CriticalError; return }
        

        #Connection and profile check

        Write-Verbose -Message "$(Get-Date -f T) - Checking connection..."

        if ($null -eq (Get-MgContext)) {

            Write-Error "$(Get-Date -f T) - Please connect to MS Graph API with the Connect-MgGraph cmdlet!" -ErrorAction Stop
        }
    }

    process {

        ## Return immediately on critical error
        if ($CriticalError) { return }

        #Define outfile
        if ([string]::IsNullOrEmpty($OutFile))
        {
            $OutFile = "sp-backup-$((New-Guid).ToString()).txt"
        }
    
        #Hide app tag
        $Tag_HideApp = 'HideApp'

        #Count variables
        $i = -1
        $updated = @()
        $count_NotParsed = 0
        $count_NotFound = 0
        $count_NotChanged = 0
        $count_NotSaved = 0
        $throttled = $false
    
        #Get the list of SPs to be processed
        $sps = Get-Content $InFile
        $total = $sps.Count
        Write-Verbose -Message "$(Get-Date -f T) - $($total) inputs to process"
    
        for ($i = $Continue; $i -lt $Top -and $i+$Skip -lt $total; $i++) {
            Write-Verbose -Message "$(Get-Date -f T) - Processing $($i)"
            if ($total -eq 1) {
                $value = $sps
            } else {
                $value = $sps[$i+$Skip]
            }
            Write-Verbose -Message "$(Get-Date -f T) - Input: $($value)"
    
            $id = $value | ConvertTo-ValidGuid
            if ($null -eq $id) {
                $count_NotParsed++
                continue
            }
    
            try {
                $sp = $id | ConvertTo-ServicePrincipal
                if ($null -eq $sp) {
                    $count_NotFound++
                    continue
                }
            } catch {
                $throttled = $true
                break
            }
    
            if (Assert-IsHidden -Sp $sp -Value (!$Visible)) {
                $count_NotChanged++
                continue
            }
    
            if ($WhatIf) {
                $updated += $sp.Id
            } else {
                try {
                    if (Set-IsHidden -Sp $sp -Value (!$Visible)) {
                        $updated += $sp.Id
                    } else {
                        $count_NotSaved++
                        continue
                    }
                } catch {
                    $throttled = $true
                    break
                }
            }
        }
    
        Write-Verbose -Message "$(Get-Date -f T) - Generating output"
    
        if ($Continue -eq 0 -and $Skip -eq 0) {
            New-OutFile -Path $OutFile
        }
    
        $updated | ForEach-Object { $_ | Add-Content -Path $OutFile }
    
        Write-Verbose -Message "$(Get-Date -f T) - $($count_NotParsed) inputs not parseable as guids"
        Write-Verbose -Message "$(Get-Date -f T) - $($count_NotFound) guids do not map to SP Ids"
        Write-Verbose -Message "$(Get-Date -f T) - $($count_NotChanged) SPs were already in the desired state"
        if ($WhatIf) {
            Write-Verbose -Message "$(Get-Date -f T) - $($updated.Count) SPs would be changed. A list of guids has been written to $($OutFile)"
        } else {
            Write-Verbose -Message "$(Get-Date -f T) - $($count_NotSaved) SPs had an error trying to save the change"
            Write-Verbose -Message "$(Get-Date -f T) - $($updated.Count) SPs were changed. A list of guids has been written to $($OutFile)"
        }
    
        if ($throttled) {
            Write-Warning "Operation throttled after processing $($i) items"
            if (!$WhatIf) {
                Write-Warning "$(Get-Date -f T) - Please wait 5 minutes then execute the following script to continue:"
                Write-Warning "$(Get-Date -f T) - Set-MsIdServicePrincipalVisibleInMyApps -InFile $($InFile) -OutFile $($OutFile) -Visible `$$($Visible) -Top $($Top) -Skip $($Skip) -Continue $($i)"
            }
        } elseif ($sps.Count -gt $Skip+$Top) {
            if (!$WhatIf) {
                Write-Verbose -Message "$(Get-Date -f T) - Run the following script to process the next batch of $($Top):"
                Write-Verbose -Message "$(Get-Date -f T) - Set-MsIdServicePrincipalVisibleInMyApps -InFile $($InFile) -OutFile $($OutFile) -Visible `$$($Visible) -Top $($Top) -Skip $($Skip+$Top)"
            }
        }
        if (!$WhatIf) {
                Write-Verbose -Message "$(Get-Date -f T) - Run the following script to roll back this operation:"
                Write-Verbose -Message "$(Get-Date -f T) - Set-MsIdServicePrincipalVisibleInMyApps -InFile $($OutFile) -Visible `$$(!$Visible)"

        }
    }
}


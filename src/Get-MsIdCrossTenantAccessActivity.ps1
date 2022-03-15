<#
.SYNOPSIS
    Gets cross tenant user sign-in activity

.DESCRIPTION
    Gets user sign-in activity associated with external tenants. By default, shows both connections
    from local users access an external tenant (outbound), and external users accessing the local
    tenant (inbound). 
    
    Has a parameter, -AccessDirection, to further refine results, using the following values: 

      * Outboud - lists sign-in events of external tenant IDs accessed by local users
      * Inbound - list sign-in events of external tenant IDs of external users accessing local tenant

    Has a parameter, -ExternalTenantId, to target a single external tenant ID.

    Has a switch, -SummaryStats, to show summary statistics for each external tenant. This also works 
    when targeting a single tenant. It is best to use this with Format-Table and Out-Gridview to ensure 
    a table is produced.

    Has a switch, -ResolvelTenantId, to return additional details on the external tenant ID.

    -Verbose will give insight into the cmdlets activities.

    Requires AuditLog.Read.All scope (to access logs) and CrossTenantInfo.ReadBasic.All scope 
    (for -ResolveTenantId), i.e. Connect-MgGraph -Scopes AuditLog.Read.All


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity

    Gets all available sign-in events for external users accessing resources in the local tenant and
    local users accessing resources in an external tenant.

    Lists by external tenant ID.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -ResolveTenantId -Verbose

    Gets all available sign-in events for external users accessing resources in the local tenant and
    local users accessing resources in an external tenant.

    Lists by external tenant ID. Attempts to resolve the external tenant ID GUID.

    Provides verbose output for insight into the cmdlet's execution.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -SummaryStats | Format-Table

    Provides a summary for sign-in information for the external tenant 3ce14667-9122-45f5-bcd4-f618957d9ba1, for both external
    users accessing resources in the local tenant and local users accessing resources in an external tenant.

    Use Format-Table to ensure a table is returned.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -ExternalTenantId 3ce14667-9122-45f5-bcd4-f618957d9ba1

    Gets all available sign-in events for local users accessing resources in the external tenant 3ce14667-9122-45f5-bcd4-f618957d9ba1, 
    and external users from tenant 3ce14667-9122-45f5-bcd4-f618957d9ba1 accessing resources in the local tenant.

    Lists by targeted external tenant.

    
.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -AccessDirection Outbound

    Gets all available sign-in events for local users accessing resources in an external tenant. 

    Lists by unique external tenant.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -AccessDirection Outbound -Verbose

    Gets all available sign-in events for local users accessing resources in an external tenant. 

    Lists by unique external tenant.

    Provides verbose output for insight into the cmdlet's execution.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -AccessDirection Outbound -SummaryStats -ResolveTenantId

    Provides a summary of sign-ins for local users accessing resources in an external tenant.

    Attempts to resolve the external tenant ID GUID.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -AccessDirection Outbound -ExternalTenantId 3ce14667-9122-45f5-bcd4-f618957d9ba1

    Gets all available sign-in events for local users accessing resources in the external tenant 3ce14667-9122-45f5-bcd4-f618957d9ba1.

    Lists by unique external tenant.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -AccessDirection Inbound

    Gets all available sign-in events for external users accessing resources in the local tenant. 

    Lists by unique external tenant.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -AccessDirection Inbound -Verbose

    Gets all available sign-in events for external users accessing resources in the local tenant. 

    Lists by unique external tenant.

    Provides verbose output for insight into the cmdlet's execution.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -AccessDirection Inbound -SummaryStats | Out-Gridview

    Provides a summary of sign-ins for external users accessing resources in the local tenant.

    Use Out-Gridview to display a table in the Out-Gridview window.


.EXAMPLE
    Get-MsIdCrossTenantAccessActivity -AccessDirection Inbound -ExternalTenantId 3ce14667-9122-45f5-bcd4-f618957d9ba1

    Gets all available sign-in events for external user from external tenant 3ce14667-9122-45f5-bcd4-f618957d9ba1 accessing
    resources in the local tenant.

    Lists by unique external tenant.


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
function Get-MsIdCrossTenantAccessActivity {

    [CmdletBinding()]
    param(

        #Return events based on external tenant access direction, either 'Inbound', 'Outbound', or 'Both'
        [Parameter(Position = 0)]
        [ValidateSet('Inbound', 'Outbound')] 
        [string]$AccessDirection,

        #Return events for the supplied external tenant ID
        [Parameter(Position = 1)]
        [guid]$ExternalTenantId,

        #Show summary statistics by tenant
        [switch]$SummaryStats,

        #Atemmpt to resolve the external tenant ID
        [switch]$ResolveTenantId

    )
    
    begin {

        ## Initialize Critical Dependencies

        $CriticalError = $null
        try {
            #Import-Module Microsoft.Graph.Reports -ErrorAction Stop
            Import-Module Microsoft.Graph.Reports -MinimumVersion 1.9.2 -ErrorAction Stop
        }
        catch { Write-Error -ErrorRecord $_ -ErrorVariable CriticalError; return }
        

        #Connection and profile check

        Write-Verbose -Message "$(Get-Date -f T) - Checking connection..."

        if ($null -eq (Get-MgContext)) {

            Write-Error "$(Get-Date -f T) - Please connect to MS Graph API with the Connect-MgGraph cmdlet!" -ErrorAction Stop
        }
        else {

            Write-Verbose -Message "$(Get-Date -f T) - Checking profile..."

            if ((Get-MgProfile).Name -eq 'v1.0') {

                Write-Error "$(Get-Date -f T) - Current MGProfile is set to v1.0, and some cmdlets may need to use the beta profile. Run 'Select-MgProfile -Name beta' to switch to beta API profile" -ErrorAction Stop
            }

        }

        Write-Verbose -Message "$(Get-Date -f T) - Connection and profile OK"


        #External Tenant ID check

        if ($ExternalTenantId) {

            Write-Verbose -Message "$(Get-Date -f T) - Checking supplied external tenant ID - $ExternalTenantId..."

            if ($ExternalTenantId -eq (Get-MgContext).TenantId) {

                Write-Error "$(Get-Date -f T) - Supplied external tenant ID ($ExternalTenantId) cannot match connected tenant ID ($((Get-MgContext).TenantId)))" -ErrorAction Stop

            }
            else {

                Write-Verbose -Message "$(Get-Date -f T) - Supplied external tenant ID OK"
            }

        }

    }
    
    process {
        ## Return Immediately On Critical Error
        if ($CriticalError) { return }

        #Get filtered sign-in logs and handle parameters

        if ($AccessDirection -eq "Outbound") {

            if ($ExternalTenantId) {

                Write-Verbose -Message "$(Get-Date -f T) - Access direction 'Outbound' selected"
                Write-Verbose -Message "$(Get-Date -f T) - Outbound: getting sign-ins for local users accessing external tenant ID - $ExternalTenantId"
            
                $SignIns = Get-MgAuditLogSignIn -Filter ("ResourceTenantId eq '{0}'" -f $ExternalTenantId) -All:$True | Group-Object ResourceTenantID

            }
            else {

                Write-Verbose -Message "$(Get-Date -f T) - Access direction 'Outbound' selected"
                Write-Verbose -Message "$(Get-Date -f T) - Outbound: getting external tenant IDs accessed by local users"

                $SignIns = Get-MgAuditLogSignIn -Filter ("ResourceTenantId ne '{0}'" -f (Get-MgContext).TenantId) -All:$True | Group-Object ResourceTenantID

            }

        }
        elseif ($AccessDirection -eq 'Inbound') {

            if ($ExternalTenantId) {

                Write-Verbose -Message "$(Get-Date -f T) - Access direction 'Inbound' selected"
                Write-Verbose -Message "$(Get-Date -f T) - Inbound: getting sign-ins for users accessing local tenant from external tenant ID - $ExternalTenantId"

                $SignIns = Get-MgAuditLogSignIn -Filter ("HomeTenantId eq '{0}' and TokenIssuerType eq 'AzureAD'" -f $ExternalTenantId) -All:$True | Group-Object HomeTenantID

            }
            else {

                Write-Verbose -Message "$(Get-Date -f T) - Access direction 'Inbound' selected"
                Write-Verbose -Message "$(Get-Date -f T) - Inbound: getting external tenant IDs for external users accessing local tenant"

                $SignIns = Get-MgAuditLogSignIn -Filter ("HomeTenantId ne '{0}' and TokenIssuerType eq 'AzureAD'" -f (Get-MgContext).TenantId) -All:$True | Group-Object HomeTenantID

            }

        }
        else {

            if ($ExternalTenantId) {

                Write-Verbose -Message "$(Get-Date -f T) - Default access direction 'Both'"
                Write-Verbose -Message "$(Get-Date -f T) - Outbound: getting sign-ins for local users accessing external tenant ID - $ExternalTenantId"
            
                $Outbound = Get-MgAuditLogSignIn -Filter ("ResourceTenantId eq '{0}'" -f $ExternalTenantId) -All:$True | Group-Object ResourceTenantID


                Write-Verbose -Message "$(Get-Date -f T) - Inbound: getting sign-ins for users accessing local tenant from external tenant ID - $ExternalTenantId"

                $Inbound = Get-MgAuditLogSignIn -Filter ("HomeTenantId eq '{0}' and TokenIssuerType eq 'AzureAD'" -f $ExternalTenantId) -All:$True | Group-Object HomeTenantID


            }
            else {

                Write-Verbose -Message "$(Get-Date -f T) - Default access direction 'Both'"
                Write-Verbose -Message "$(Get-Date -f T) - Outbound: getting external tenant IDs accessed by local users"

                $Outbound = Get-MgAuditLogSignIn -Filter ("ResourceTenantId ne '{0}'" -f (Get-MgContext).TenantId) -All:$True | Group-Object ResourceTenantID


                Write-Verbose -Message "$(Get-Date -f T) - Inbound: getting external tenant IDs for external users accessing local tenant"

                $Inbound = Get-MgAuditLogSignIn -Filter ("HomeTenantId ne '{0}' and TokenIssuerType eq 'AzureAD'" -f (Get-MgContext).TenantId) -All:$True | Group-Object HomeTenantID



            }

            #Combine outbound and inbound results

            [array]$SignIns = $Outbound
            $SignIns += $Inbound



        }


        #Analyse sign-in logs

        Write-Verbose -Message "$(Get-Date -f T) - Checking for sign-ins..."

        if ($SignIns) {
            
            Write-Verbose -Message "$(Get-Date -f T) - Sign-ins obtained"
            Write-Verbose -Message "$(Get-Date -f T) - Iterating Sign-ins..."

            foreach ($TenantID in $SignIns) {

                #Handle resolving tenant ID

                if ($ResolveTenantId) {

                    Write-Verbose -Message "$(Get-Date -f T) - Attempting to resolve external tenant - $($TenantId.Name)"

                    #Nullify $ResolvedTenant value

                    $ResolvedTenant = $null


                    #Attempt to resolve tenant ID

                    try { $ResolvedTenant = Resolve-MSIDTenant -TenantId $TenantId.Name -ErrorAction SilentlyContinue }
                    catch { Write-Verbose -Message "$(Get-Date -f T) - Issue resolving external tenant - $($TenantId.Name)" }

                    if ($ResolvedTenant) {

                        if ($ResolvedTenant.Result -eq 'Resolved') {

                            $ExternalTenantName = $ResolvedTenant.DisplayName
                            $DefaultDomainName = $ResolvedTenant.DefaultDomainName


                        }
                        else {

                            $ExternalTenantName = $ResolvedTenant.Result
                            $DefaultDomainName = $ResolvedTenant.Result

                        }
 
                        if ($ResolvedTenant.oidcMetadataResult -eq 'Resolved') {
    
                            $oidcMetadataTenantRegionScope = $ResolvedTenant.oidcMetadataTenantRegionScope

                        }
                        else {

                            $oidcMetadataTenantRegionScope = 'NotFound'

                        }

                    }
                    else {

                        $ExternalTenantName = "NotFound"
                        $DefaultDomainName = "NotFound"
                        $oidcMetadataTenantRegionScope = 'NotFound'


                    }

                }

                #Handle access direction

                if (($AccessDirection -eq 'Inbound') -or ($AccessDirection -eq 'Outbound')) {

                    $Direction = $AccessDirection

                }
                else {

                    if ($TenantID.Name -eq $TenantID.Group[0].HomeTenantId) {

                        $Direction = "Inbound"

                    }
                    elseif ($TenantID.Name -eq $TenantID.Group[0].ResourceTenantId) {

                        $Direction = "Outbound"

                    }

                }

                #Provide summary

                if ($SummaryStats) {

                    Write-Verbose -Message "$(Get-Date -f T) - Creating summary stats for external tenant - $($TenantId.Name)"

                    #Handle resolving tenant ID

                    if ($ResolveTenantId) {

                        $Analysis = [pscustomobject]@{

                            ExternalTenantId          = $TenantId.Name
                            ExternalTenantName        = $ExternalTenantName
                            ExternalTenantRegionScope = $oidcMetadataTenantRegionScope
                            AccessDirection           = $Direction
                            SignIns                   = ($TenantId).count
                            SuccessSignIns            = ($TenantID.Group.Status | Where-Object { $_.ErrorCode -eq 0 } | Measure-Object).count
                            FailedSignIns             = ($TenantID.Group.Status | Where-Object { $_.ErrorCode -ne 0 } | Measure-Object).count
                            UniqueUsers               = ($TenantID.Group | Select-Object UserId -Unique | Measure-Object).count
                            UniqueResources           = ($TenantID.Group | Select-Object ResourceId -Unique | Measure-Object).count

                        }

                    }
                    else {

                        #Build custom output object

                        $Analysis = [pscustomobject]@{

                            ExternalTenantId = $TenantId.Name
                            AccessDirection  = $Direction
                            SignIns          = ($TenantId).count
                            SuccessSignIns   = ($TenantID.Group.Status | Where-Object { $_.ErrorCode -eq 0 } | Measure-Object).count
                            FailedSignIns    = ($TenantID.Group.Status | Where-Object { $_.ErrorCode -ne 0 } | Measure-Object).count
                            UniqueUsers      = ($TenantID.Group | Select-Object UserId -Unique | Measure-Object).count
                            UniqueResources  = ($TenantID.Group | Select-Object ResourceId -Unique | Measure-Object).count

                        }


                    }

                    Write-Verbose -Message "$(Get-Date -f T) - Adding stats for $($TenantId.Name) to total analysis object"

                    [array]$TotalAnalysis += $Analysis

                }
                else {

                    #Get individual events by external tenant

                    Write-Verbose -Message "$(Get-Date -f T) - Getting individual sign-in events for external tenant - $($TenantId.Name)"

                    
                    foreach ($Event in $TenantID.group) {


                        if ($ResolveTenantId) {

                            $CustomEvent = [pscustomobject]@{

                                ExternalTenantId          = $TenantId.Name
                                ExternalTenantName        = $ExternalTenantName
                                ExternalDefaultDomain     = $DefaultDomainName
                                ExternalTenantRegionScope = $oidcMetadataTenantRegionScope
                                AccessDirection           = $Direction
                                UserDisplayName           = $Event.UserDisplayName
                                UserPrincipalName         = $Event.UserPrincipalName
                                UserId                    = $Event.UserId
                                UserType                  = $Event.UserType
                                CrossTenantAccessType     = $Event.CrossTenantAccessType
                                AppDisplayName            = $Event.AppDisplayName
                                AppId                     = $Event.AppId 
                                ResourceDisplayName       = $Event.ResourceDisplayName
                                ResourceId                = $Event.ResourceId
                                SignInId                  = $Event.Id
                                CreatedDateTime           = $Event.CreatedDateTime
                                StatusCode                = $Event.Status.Errorcode
                                StatusReason              = $Event.Status.FailureReason


                            }

                            $CustomEvent

                        }
                        else {

                            $CustomEvent = [pscustomobject]@{

                                ExternalTenantId      = $TenantId.Name
                                AccessDirection       = $Direction
                                UserDisplayName       = $Event.UserDisplayName
                                UserPrincipalName     = $Event.UserPrincipalName
                                UserId                = $Event.UserId
                                UserType              = $Event.UserType
                                CrossTenantAccessType = $Event.CrossTenantAccessType
                                AppDisplayName        = $Event.AppDisplayName
                                AppId                 = $Event.AppId 
                                ResourceDisplayName   = $Event.ResourceDisplayName
                                ResourceId            = $Event.ResourceId
                                SignInId              = $Event.Id
                                CreatedDateTime       = $Event.CreatedDateTime
                                StatusCode            = $Event.Status.Errorcode
                                StatusReason          = $Event.Status.FailureReason


                            }

                            $CustomEvent

                        }


                    }
                    

                }

            }

        }
        else {

            Write-Warning "$(Get-Date -f T) - No sign-ins matching the selected criteria found."

        }

        #Display summary table

        if ($SummaryStats) {

            #Show array of summary objects for each external tenant

            Write-Verbose -Message "$(Get-Date -f T) - Displaying total analysis object"

            if (!$AccessDirection) {
            
                $TotalAnalysis | Sort-Object ExternalTenantId 
            
            }
            else {
           
                $TotalAnalysis | Sort-Object SignIns -Descending 

            }

        }


    }
       
}
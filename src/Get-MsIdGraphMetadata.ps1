function New-XmlNamespaceManager {
    [CmdletBinding()]
    param (
        #
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument] $XmlDocument,
        #
        [Parameter(Mandatory = $false)]
        [switch] $AddNamespacesInScope,
        #
        [Parameter(Mandatory = $false)]
        [string] $DefaultNamespacePrefix,
        #
        [Parameter(Mandatory = $false)]
        [switch] $AsHashtable
    )

    [System.Xml.XmlNamespaceManager] $XmlNamespaceManager = New-Object System.Xml.XmlNamespaceManager -ArgumentList $XmlDocument.NameTable

    if ($AddNamespacesInScope) {
        [System.Xml.XPath.XPathNavigator] $XPathNavigator = $XmlDocument.CreateNavigator()
        while ($XPathNavigator.MoveToFollowing([System.Xml.XPath.XPathNodeType]::Element)) {
            $Namespaces = $XPathNavigator.GetNamespacesInScope([System.Xml.XmlNamespaceScope]::Local);
            foreach ($Namespace in $Namespaces.GetEnumerator()) {
                if (!$Namespace.Key) {
                    if (!$DefaultNamespacePrefix -and $Namespace.Value -match '[A-Za-z0-9]+$') {
                        $XmlNamespaceManager.AddNamespace($Matches[0], $Namespace.Value)
                    }
                    else { $XmlNamespaceManager.AddNamespace($DefaultNamespacePrefix, $Namespace.Value) }
                }
                $XmlNamespaceManager.AddNamespace($Namespace.Key, $Namespace.Value)
            }
        }
    }

    if ($AsHashtable) {
        $AllNamespaces = @{}
        foreach ($Prefix in $XmlNamespaceManager) {
            if ($Prefix -notin '', 'xml', 'xmlns') {
                $AllNamespaces[$Prefix] = $XmlNamespaceManager.LookupNamespace($Prefix)
            }
        }
        Write-Output $AllNamespaces
    }
    else { Write-Output $XmlNamespaceManager -NoEnumerate }
}

function Get-MsGraphSchemaItem {
    [CmdletBinding()]
    param (
        #
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Xml.XmlDocument] $MsGraphMetadata,
        #
        [Parameter(Mandatory = $true)]
        [string] $Name,
        #
        [Parameter(Mandatory = $false)]
        [string] $SchemaNamespace,
        #
        [Parameter(Mandatory = $false)]
        [string] $Type = '*'
    )

    $XmlNamespaceManager = New-XmlNamespaceManager $MsGraphMetadata -AddNamespacesInScope -AsHashtable

    if ($Name -match '#?(?:(.+)\.)?(.+)$') {
        $Name = $Matches[2]
        $SchemaNamespace = $Matches[1]
    }
    #$Schemas = Select-Xml $MsGraphMetadata -Namespace $XmlNamespaceManager -XPath '/edmx:Edmx/edmx:DataServices/edm:Schema' | Select-Object -ExpandProperty Node

    function Get-MsGraphSchemaAnnotations {
        param (
            # 
            [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
            [System.Xml.XmlElement] $Schema,
            # 
            [Parameter(Mandatory = $true)]
            [System.Xml.XmlElement] $SchemaType,
            # 
            [Parameter(Mandatory = $false)]
            [System.Xml.XmlElement] $Property
        )

        process {
            #foreach ($_Property in $Property) {
            $Target = '{0}.{1}' -f $Schema.Namespace, $SchemaType.Name
            if ($Property) { $Target += '/{0}' -f $Property.Name }
            $Annotations = Select-Xml $Schema -Namespace $XmlNamespaceManager -XPath "./edm:Annotations[@Target='$Target']/edm:Annotation" | Select-Object -ExpandProperty Node
            foreach ($Annotation in $Annotations) {
                [pscustomobject]@{
                    Term   = Get-ObjectPropertyValue $Annotation Term
                    String = Get-ObjectPropertyValue $Annotation String
                    Record = @(Get-ObjectPropertyValue $Annotation Record PropertyValue | ForEach-Object { [pscustomobject]@{ Property = Get-ObjectPropertyValue $_ Property; Bool = Get-ObjectPropertyValue $_ Bool } })
                }
            }
            #}
        }
    }

    function Process-Property {
        param (
            [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
            [System.Xml.XmlElement[]] $Property
        )

        process {
            foreach ($_Property in $Property) {
                $OutputObject = [pscustomobject]@{
                    Name        = $_Property.Name
                    Type        = Get-ObjectPropertyValue $_Property Type
                    TypeDefinition = $null
                    Nullable    = Get-ObjectPropertyValue $_Property Nullable
                    Annotations = @(Get-MsGraphSchemaAnnotations -Schema $_Property.ParentNode.ParentNode -SchemaType $_Property.ParentNode -Property $_Property)
                }
                if ($OutputObject.Type -match ('^(?:Collection\()?({0}\.([^()]+))\)?$' -f $_Property.ParentNode.ParentNode.Alias)) {
                    $OutputObject.TypeDefinition = Get-MsGraphSchemaItem $MsGraphMetadata -Name $Matches[1]
                }
                $OutputObject
            }
        }
    }

    function Process-NavigationProperty {
        param (
            [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
            [System.Xml.XmlElement[]] $Property
        )

        process {
            foreach ($_Property in $Property) {
                [pscustomobject]@{
                    Name           = $_Property.Name
                    Type           = Get-ObjectPropertyValue $_Property Type
                    TypeDefinition = $null
                    ContainsTarget = Get-ObjectPropertyValue $_Property ContainsTarget
                    Annotations    = @(Get-MsGraphSchemaAnnotations -Schema $_Property.ParentNode.ParentNode -SchemaType $_Property.ParentNode -Property $_Property)
                }
            }
        }
    }
    
    $ResultType = Select-Xml $MsGraphMetadata -Namespace $XmlNamespaceManager -XPath ('/edmx:Edmx/edmx:DataServices/edm:Schema[@Namespace="{0}" or @Alias="{0}"]/edm:{2}[@Name="{1}"]' -f $SchemaNamespace, $Name, $Type) | Select-Object -ExpandProperty Node

    if ($ResultType) {
        $OutputObject = [pscustomobject]@{
            Type               = $ResultType.LocalName
            Name               = $ResultType.Name
            OpenType           = Get-ObjectPropertyValue $ResultType OpenType
            BaseType           = Get-ObjectPropertyValue $ResultType BaseType
            Property           = @(Get-ObjectPropertyValue $ResultType Property | Process-Property)
            NavigationProperty = @(Get-ObjectPropertyValue $ResultType NavigationProperty | Process-NavigationProperty)
            Annotations        = @(Get-MsGraphSchemaAnnotations -Schema $ResultType.ParentNode -SchemaType $ResultType)
        }
    
        if (Get-ObjectPropertyValue $ResultType BaseType) {
            $BaseType = Get-MsGraphSchemaItem $MsGraphMetadata -Name $OutputObject.BaseType
            if ($BaseType) {
                $OutputObject.BaseType = $BaseType
                if ($BaseType.Property) { $OutputObject.Property += $BaseType.Property }
                if ($BaseType.NavigationProperty) { $OutputObject.NavigationProperty += $BaseType.NavigationProperty }
            }
        }
        $OutputObject
    }
}
.'C:\Users\jasoth\Source\Repos\MSIdentityTools\src\internal\Get-ObjectPropertyValue.ps1'
if (!$MsGraphMetadata) { $MsGraphMetadata = Invoke-RestMethod 'https://graph.microsoft.com/v1.0/$metadata' }
$test = Get-MsGraphSchemaItem $MsGraphMetadata -Name 'microsoft.graph.user'

$test.Property


return


function Get-MsGraphType {
    param (
        # MS Graph Type Name. Wildcards are permitted.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string] $Name,
        # 
        [Parameter(Mandatory = $false)]
        [string] $Type,
        # Metadata URL for Microsoft Graph API.
        [Parameter(Mandatory = $false)]
        [uri] $MetadataUri = 'https://graph.microsoft.com/v1.0/$metadata'
    )

    process {
        $MsGraphMetadata = Invoke-RestMethod $MetadataUri
        # $XmlNamespaceManager = New-XmlNamespaceManager $MsGraphMetadata -AddNamespacesInScope -AsHashtable
        # Select-Xml $MsGraphMetadata -Namespace $XmlNamespaceManager -XPath '/edmx:Edmx/edmx:DataServices'

        foreach ($Schema in $MsGraphMetadata.Edmx.DataServices.Schema) {

            foreach ($EntitySet in $Schema.EntityContainer.EntitySet) {
                if ($EntitySet.Name -like $Name) {
                    $EntitySet
                    $global:EntityType = $Schema.EntityType | Where-Object Name -EQ $EntitySet.EntityType.Substring($Schema.Namespace.Length + 1)
                    $global:EntityTypeBase = $Schema.EntityType | Where-Object Name -EQ $global:EntityType.BaseType.Substring($Schema.Alias.Length + 1)
                    $global:Annotation = $Schema.Annotations | Where-Object Target -EQ $EntitySet.EntityType
                    $global:Action = @()
                    foreach ($Action in $Schema.Action) {
                        if ($Action.Parameter[0].Type -eq $EntitySet.EntityType.Replace($Schema.Namespace, $Schema.Alias)) {
                            $global:Action += $Action
                        }
                    }
                    $global:Function = @()
                    foreach ($Function in $Schema.Function) {
                        if ($Function.Parameter[0].Type -eq $EntitySet.EntityType.Replace($Schema.Namespace, $Schema.Alias)) {
                            $global:Function += $Function
                        }
                    }
                }
            }

            # foreach ($EntityType in $Schema.EntityType) {
            #     if ($EntityType.Name -like $Name) {
            #         Write-Output $EntityType
            #     }
            # }

            # foreach ($ComplexType in $Schema.ComplexType) {
            #     if ($ComplexType.Name -like $Name) {
            #         Write-Output $ComplexType
            #     }
            # }

            # foreach ($EnumType in $Schema.EnumType) {
            #     if ($EnumType.Name -like $Name) {
            #         Write-Output $EnumType
            #     }
            # }
        }
    }
}
Get-MsGraphType 'servicePrincipals'


return

$MsGraphMetadata = Invoke-RestMethod 'https://graph.microsoft.com/v1.0/$metadata'
$XmlNamespaceManager = New-XmlNamespaceManager $MsGraphMetadata -AddNamespacesInScope -AsHashtable
$Schemas = Select-Xml $MsGraphMetadata -Namespace $XmlNamespaceManager -XPath '/edmx:Edmx/edmx:DataServices/edm:Schema' | Select-Object -ExpandProperty Node
# Select-Xml $MsGraphMetadata -Namespace $XmlNamespaceManager -XPath '/edmx:Edmx/edmx:DataServices/edm:Schema/edm:EntityType[@Name="{0}"] | //edm:ComplexType[@Name="{0}"] | //edm:EnumType[@Name="{0}"]'


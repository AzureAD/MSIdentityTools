function Resolve-XmlElement {
    [CmdletBinding(DefaultParameterSetName = "QualifiedName")]
    [OutputType([System.Xml.XmlElement[]])]
    param
    (
        # 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, Position = 1)]
        [System.Xml.XmlElement] $ParentNode,
        # 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "QualifiedName")]
        [string] $QualifiedName,
        # 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Prefix")]
        [string] $Prefix,
        # 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Prefix")]
        [string] $LocalName,
        # 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true,  ParameterSetName = "QualifiedName")]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Prefix")]
        [string] $NamespaceURI,
        # 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias("Clear")]
        [switch] $ClearExisting = $false,
        # 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias("Create")]
        [switch] $CreateMissing
    )
        
    process {
        [System.Xml.XmlElement[]] $xmlElement = @()
                
        switch ($PSCmdlet.ParameterSetName) {
            'QualifiedName' {
                [Microsoft.PowerShell.Commands.SelectXmlInfo[]] $resultSelectXml = Select-Xml -Xml $ParentNode -XPath ('./p:{0}' -f $QualifiedName) -Namespace @{ 'p' = $ParentNode.NamespaceURI }
                if ($ClearExisting) {
                    foreach ($result in $resultSelectXml) { $ParentNode.RemoveChild($result.Node) | Out-Null }
                    $resultSelectXml = @()
                }
                if ($resultSelectXml) { $xmlElement = $resultSelectXml.Node }
                elseif ($CreateMissing) { $xmlElement = $ParentNode.AppendChild($ParentNode.OwnerDocument.CreateElement($QualifiedName, $ParentNode.NamespaceURI)) }
                break 
            }
            'Prefix' {
                [Microsoft.PowerShell.Commands.SelectXmlInfo[]] $resultSelectXml = Select-Xml -Xml $ParentNode -XPath ('./{0}:{1}' -f $Prefix, $LocalName) -Namespace @{ $Prefix = $ParentNode.GetNamespaceOfPrefix($Prefix) }
                if ($ClearExisting) {
                    foreach ($result in $resultSelectXml) { $ParentNode.RemoveChild($result.Node) | Out-Null }
                    $resultSelectXml = @()
                }
                if ($resultSelectXml) { $xmlElement = $resultSelectXml.Node }
                elseif ($CreateMissing) { $xmlElement = $ParentNode.AppendChild($ParentNode.OwnerDocument.CreateElement($Prefix, $LocalName, $ParentNode.GetNamespaceOfPrefix($Prefix))) }
                break 
            }
        }
        return $xmlElement
    }
}
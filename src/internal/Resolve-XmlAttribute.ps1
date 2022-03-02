function Resolve-XmlAttribute {
    [CmdletBinding(DefaultParameterSetName = "QualifiedName")]
    [OutputType([System.Xml.XmlAttribute])]
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
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Prefix")]
        [string] $LocalName,
        # 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = "QualifiedName")]
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Prefix")]
        [string] $NamespaceURI,
        # 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias("Create")]
        [switch] $CreateMissing
    )

    process {
        [System.Xml.XmlAttribute] $xmlAttribute = $null
        switch ($PSCmdlet.ParameterSetName) {
            'QualifiedName' {
                $resultSelectXml = Select-Xml -Xml $ParentNode -XPath ('@{0}' -f $QualifiedName)
                if ($resultSelectXml) { $xmlAttribute = $resultSelectXml.Node }
                elseif ($CreateMissing) {
                    if ($NamespaceURI) { $xmlAttribute = $ParentNode.SetAttributeNode($ParentNode.OwnerDocument.CreateAttribute($QualifiedName, $NamespaceURI)) }
                    else { $xmlAttribute = $ParentNode.SetAttributeNode(($ParentNode.OwnerDocument.CreateAttribute($QualifiedName))) }
                }
                break 
            }
            'Prefix' {
                if ($Prefix -eq "xmlns") { $resultSelectXml = Select-Xml -Xml $ParentNode -XPath ('namespace::{0}' -f $LocalName) }
                else { $resultSelectXml = Select-Xml -Xml $ParentNode -XPath ('@{0}:{1}' -f $Prefix, $LocalName) -Namespace @{ $Prefix = $ParentNode.GetNamespaceOfPrefix($Prefix) } }
                if ($resultSelectXml) { $xmlAttribute = $resultSelectXml.Node }
                elseif ($CreateMissing) { $xmlAttribute = $ParentNode.SetAttributeNode($ParentNode.OwnerDocument.CreateAttribute($Prefix, $LocalName, $ParentNode.GetNamespaceOfPrefix($Prefix))) }
                break 
            }
        }
        return $xmlAttribute
    }
}

$ErrorActionPreference = "SilentlyContinue"
[Reflection.Assembly]::LoadFile("c:\windows\system32\srmlib.dll") | Out-Null
$QuotaManager = New-Object "Microsoft.Storage.FSrmQuotaManagerClass"
$QuotaTemplateManager = New-Object "Microsoft.Storage.FSrmQuotaTemplateManagerClass"

set-variable -name FsrmQuotaFlags_Enforce -value 0x100 -option constant 
set-variable -name FsrmQuotaFlags_Disable -value 0x200 -option constant 
set-variable -name FsrmQuotaFlags_StatusIncomplete -value 0x10000 -option constant 
set-variable -name FsrmQuotaFlags_StatusRebuilding -value 0x20000  -option constant 
$ErrorActionPreference = "Stop"

Function Get-FsrmQuotaV2K8([String] $Path)
{
    return $QuotaManager.GetQuota($Path)
}

Function Get-FsrmAutoQuotaV2K8([String] $Path)
{
    return $QuotaManager.GetAutoApplyQuota($Path)
}

Function Get-FsrmQuotaTemplateV2K8([String] $Name)
{
    return $QuotaTemplateManager.GetTemplate($Name)
}

<# Function New-FsrmQuotaTemplateV2K8([String] $Name, $Size, [String] $Description, [Object[]] $Threshold, [switch] $SoftLimit)
{
    $Size = Get-ScaledSizeUnits $Size
    $QuotaTemplate = $QuotaTemplateManager.CreateTemplate()
    if ($SoftLimit -eq $true) { $QuotaTemplate.QuotaFlags = $QuotaTemplate.QuotaFlags -bxor $FsrmQuotaFlags_Enforce }
    else  { $QuotaTemplate.QuotaFlags = $QuotaTemplate.QuotaFlags -bor $FsrmQuotaFlags_Enforce }
    $QuotaTemplate.Name = $Name
    $QuotaTemplate.QuotaLimit = $Size
    $QuotaTemplate.Description = $Description
    if ($Threshold -ne $Null)
    {
        foreach ($t in $Threshold)
        {
            $QuotaTemplate.AddThreshold($t.Percentage) | Out-Null
            $QuotaTemplate.CreateThresholdAction($t.Percentage, $t.Action)
        }
    }
    try
    {
        $QuotaTemplate.Commit()
    }
    catch 
    {
        throw $exception
    }
    
    return $QuotaTemplate
}
#>

Function New-FsrmQuotaV2K8([String] $Path,  [String] $Description, [String] $Template, $Size, [switch] $SoftLimit, [switch] $Disabled)
{
    if($Size) {$Size = Get-ScaledSizeUnits $Size}
    $Quota = $QuotaManager.CreateQuota($Path)
    if ($SoftLimit -eq $true) { $Quota.QuotaFlags = $Quota.QuotaFlags -bxor $FsrmQuotaFlags_Enforce }
    else  { $Quota.QuotaFlags = $Quota.QuotaFlags -bor $FsrmQuotaFlags_Enforce }
    
    if ($Disabled -eq $true) { $Quota.QuotaFlags = $Quota.QuotaFlags -bor $FsrmQuotaFlags_Disable }
    
    if($Template) {$Quota.ApplyTemplate($Template)}
    if($QuotaLimit) { $Quota.QuotaLimit = $Size}
    if($Description) {$Quota.Description = $Description}
    $Quota.Commit()
}

Function New-FsrmAutoQuotaV2K8([String] $Path, [String] $Template, [switch] $Disabled)
{
    $AutoQuota = $QuotaManager.CreateAutoApplyQuota($Template, $Path)
    if ($Disabled -eq $true) { $AutoQuota.QuotaFlags = $AutoQuota.QuotaFlags -bor $FsrmQuotaFlags_Disable }
    $AutoQuota.Commit()
}


<#
Function New-FsrmQuotaThresholdV2K8([int32] $Percentage, $Action)
{
    $Threshold = New-Object Object |Add-Member NoteProperty Percentage $Percentage -PassThru | Add-Member NoteProperty Action  $Action -PassThru
    return $Threshold
}

#>




Function Remove-FsrmAutoQuotaV2K8([String] $Path, $InputObject)
{
    if ($Path) { $AutoQuota = $QuotaManager.GetAutoApplyQuota($Path) }
    else {$AutoQuota = $InputObject}
    $Path = $AutoQuota.Path
    $AutoQuota.Delete()
    $AutoQuota.Commit()
    if ($PassThru -eq $true) {return $AutoQuota}
    
}

Function Set-FsrmQuotaV2K8 ([String] $Path, [String] $Description, [String] $Size, [Switch] $Disabled, $Threshold, $InputObject)
{
    if($Path) {$Quota = $QuotaManager.GetQuota($Path)}
    else {$Quota = $InputObject}
    if($Description){$Quota.Description = $Description}
    if($Size){$Quota.QuotaLimit = Get-ScaledSizeUnits $Size}
    if($Disabled){$Quota.QuotaFlags = $Quota.QuotaFlags -bor $FsrmQuotaFlags_Disable}
    if($Threshold)
    {
        foreach ($t in $Quota.Thresholds)
        {
            $quota.DeleteThreshold($t)
        }
        foreach ($t in $Threshold)
        {
            $Quota.AddThreshold($t.Percentage) | Out-Null
            $Quota.CreateThresholdAction($t.Percentage, $t.Action)
        }
    }
    $Quota.Commit()
}

Function Remove-FsrmQuotaV2K8([String] $Path, $Quota)
{
    if($Path) { $Quota = $QuotaManager.GetQuota($Path)} 
    $Path = $Quota.Path
    $Quota.Delete()
    $Quota.Commit()
    if ($PassThru -eq $true) {return $Path}
}

<#Function Remove-FsrmQuotaTemplateV2K8([String] $Name, $InputObject)
{
    if($Name) { $QuotaTemplate = $QuotaTemplateManager.GetTemplate($Name) }
    else {$QuotaTemplate = $InputObject}
    $Name = $QuotaTemplate.Name
    $QuotaTemplate.Delete()
    $QuotaTemplate.Commit()
    if($PassThru -eq $true) { return $Name }
}#>

Function Reset-FsrmQuotaV2K8([String] $Path, [String] $Template, $InputObject)
{
    if($Path) { $Quota = $QuotaManager.GetQuota($Path) }
    else {$Quota = $InputObject}
    if($Template) { $Quota.ApplyTemplate($Template) }
    else {$Quota.ApplyTemplate($Quota.SourceTemplateName)}
    $Quota.Commit()
}

Function Set-FsrmAutoQuotaV2K8([String] $Path, [String] $Template, [Switch] $Disabled, [Switch] $UpdateDerived, [Switch] $UpdateDerivedMatching, $InputObject)
{
    if($Path) { $AutoQuota = $QuotaManager.GetAutoApplyQuota($Path) }
    else {$AutoQuota = $InputObject}
    if($Template) {$AutoQuota.ApplyTemplate($Template)}
    else{$AutoQuota.ApplyTemplate($AutoQuota.SourceTemplateName)}
    if($Disabled) {$AutoQuota.QuotaFlags = $AutoQuota.QuotaFlags -bor $FsrmQuotaFlags_Disable}
    if($UpdateDerived)
    {
        $AutoQuota.CommitAndUpdateDerived([Microsoft.Storage._FsrmCommitOptions]::FsrmCommitOptions_None,[Microsoft.Storage._FsrmTemplateApplyOptions]::FsrmTemplateApplyOptions_ApplyToDerivedAll) | Out-Null
    }
    elseif($UpdateDerivedMatching)
    {
        $AutoQuota.CommitAndUpdateDerived([Microsoft.Storage._FsrmCommitOptions]::FsrmCommitOptions_None,[Microsoft.Storage._FsrmTemplateApplyOptions]::FsrmTemplateApplyOptions_ApplyToDerivedMatching) | Out-Null
    } 
    else
    {
        $AutoQuota.Commit()
    }
    if($passthru -eq $true) {return $AutoQuota}
}

Function Search-FsrmQuotasV2K8([String] $path)
{
    return $QuotaManager.Scan($path)
}

Function Private:Get-ScaledSizeUnits([String] $Size)
{
   $MultiplicationFactor = [Int64]1
   Switch (($Size.Remove(0,$Size.Length-1)).ToUpper())
        {
            "K" {$MultiplicationFactor=1024}
            "M" {$MultiplicationFactor=[Math]::Pow(1024,2)}
            "G" {$MultiplicationFactor=[Math]::Pow(1024,3)}
            "T" {$MultiplicationFactor=[Math]::Pow(1024,4)}
        }
    if ($MultiplicationFactor -ne 1)
    { 
        $Size = [Int64]::Parse($Size.Remove($Size.Length-1,1))
    }
    else
    {
        $Size = [Int64]::Parse($Size)
    }
    return [Int64]$Size*$MultiplicationFactor
}
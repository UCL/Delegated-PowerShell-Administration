$AdminUserName = "WIN-DDQ1VGD930D\FSRMDelegation"
$AdminPassword = "fsrm,1234"
$AdminPasswordEncrypted = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
Clear-Variable -Name AdminPassword
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminUserName, $AdminPasswordEncrypted
Clear-Variable -Name AdminUserName
Clear-Variable -Name AdminPasswordEncrypted
$AdminSession = New-PSSession  -Credential $cred  
Clear-Variable -Name cred
invoke-command -ScriptBlock { import-module -Name "c:\users\public\documents\FileServerResourceManager.psm1" } -Session $AdminSession
Import-PSSession -Session $AdminSession -Module FileServerResourceManager -AllowClobber


Function Get-FsrmQuotaV2K8
{
  param(
    [System.String]
    ${Path})

begin
{
   Test-NotAdminPath $path
    try {
        
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand("FileServerResourceManager\Get-FsrmQuotaV2K8", [System.Management.Automation.CommandTypes]::Function)
        $PSBoundParameters.Add('$args', $args)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($myInvocation.ExpectingInput, $ExecutionContext)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
}

Function Test-NotAdminPath($Path)
{
    if ($path.ToUpper().StartsWith("C:")) { throw "Access is denied." }
}

Function Remove-AdminSession
{
    Remove-PSSession $AdminSession
}
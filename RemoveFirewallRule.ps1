[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true)][String] $ResourceName,
    [Parameter(ValueFromPipeline = $true)][String] $ResourceGroup
     )

$ExistingFirewallRuleName = "AzureDevOps"
                                     
$AServiceServer = Get-AzAnalysisServicesServer -Name $ResourceName -ResourceGroupName $ResourceGroup
$FirewallRules = ($AServiceServer).FirewallConfig.FirewallRules
$FirewallRuleNameList = $FirewallRules.FirewallRuleName
$powerBi = ($AServiceServer).FirewallConfig.EnablePowerBIService
                    
Write-Output "Updating Analysis Service firewall config"
$ruleNumberIndex = 1
$Rules = @() -as [System.Collections.Generic.List[Microsoft.Azure.Commands.AnalysisServices.Models.PsAzureAnalysisServicesFirewallRule]]
                
#Storing Analysis Service firewall rules
$FirewallRules | ForEach-Object {
    $ruleNumberVar = "rule" + "$ruleNumberIndex"
    #Exception of storage of firewall rule is made for the rule to be updated
    if (!($_.FirewallRuleName -match "$ExistingFirewallRuleName")) {
                
        $start = $_.RangeStart
        $end = $_.RangeEnd
        $tempRule = New-AzAnalysisServicesFirewallRule `
            -FirewallRuleName $_.FirewallRuleName `
            -RangeStart $start `
            -RangeEnd $end
                
        Set-Variable -Name "$ruleNumberVar" -Value $tempRule
        $Rules.Add((Get-Variable $ruleNumberVar -ValueOnly))
        $ruleNumberIndex = $ruleNumberIndex + 1
    }
}
                    
Write-Output $FirewallRules         #Write all FireWall Rules to Host
                
                                      
#Creating Firewall config object
if ($powerBi) {
        $conf = New-AzAnalysisServicesFirewallConfig -EnablePowerBiService -FirewallRule $Rules 
    }
else {       
        $conf = New-AzAnalysisServicesFirewallConfig -FirewallRule $Rules 
    }
                    
#Setting firewall config
if ([String]::IsNullOrEmpty($AServiceServer.BackupBlobContainerUri)) {
    $AServiceServer | Set-AzAnalysisServicesServer `
        -FirewallConfig $conf `
        -DisableBackup `
        -Sku $AServiceServer.Sku.Name.TrimEnd()
}
else {
    $AServiceServer | Set-AzAnalysisServicesServer `
        -FirewallConfig $conf `
        -BackupBlobContainerUri $AServiceServer.BackupBlobContainerUri `
        -Sku $AServiceServer.Sku.Name.TrimEnd()
                    
}
Write-Output "Updated firewall rule to remove current IP: $currentIP"
Write-Output "Enable Power Bi Service was set to: $powerBi" 
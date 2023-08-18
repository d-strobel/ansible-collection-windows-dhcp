#!powershell

# Copyright: (c) 2022, Dustin Strobel (@d-strobel)
# GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell Ansible.ModuleUtils.AddType

$spec = @{
    options             = @{
        name                = @{ type = "str"; required = $true }
        partner_server      = @{ type = "str"; required = $true }
        scopes              = @{ type = "list" ; elements = "str"; required = $true }
        shared_secret       = @{ type = "str" }
        mode                = @{ type = "str"; choices = "loadbalance", "hotstandby"; default = "loadbalance" }
        server_role         = @{ type = "str"; choices = "active", "standby" }
        loadbalance_percent = @{ type = "int"; default = 50 }
        state               = @{ type = "str"; choices = "absent", "present"; default = "present" }
    }

    required_if         = @(
        , @("mode", "loadbalance", @("loadbalance_percent"))
        , @("mode", "hotstandby", @("server_role"))
    )

    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

# Map variables
$name = $module.Params.name
$partnerServer = $module.Params.partner_server
$scopeId = $module.Params.scopes
$sharedSecret = $module.Params.shared_secret
$mode = $module.Params.mode
$serverRole = $module.Params.server_role
$loadbalancePercent = $module.Params.loadbalance_percent
$state = $module.Params.state

# ErrorAction
$ErrorActionPreference = 'Stop'

# Get failover
$dhcpServersFailover = Get-DhcpServerv4Failover -Name $name -ErrorAction SilentlyContinue

# Remove failover
if (($null -ne $dhcpServersFailover) -and ($state -eq "absent")) {
    try {
        Remove-DhcpServerv4Failover -Name $name -Confirm:$false | Out-Null

        $module.Result.changed = $true
        $module.ExitJson()
    }
    catch {
        $module.FailJson("Failed to remove the failover '$name'", $Error[0])
    }
}

# New failover
if (($null -eq $dhcpServersFailover) -and ($state -eq "present")) {
    try {
        if ($mode -eq "loadbalance") {
            Add-DhcpServerv4Failover `
                -Name $name `
                -PartnerServer $partnerServer `
                -ScopeId $scopeId `
                -SharedSecret $sharedSecret `
                -LoadBalancePercent $loadbalancePercent `
                -Confirm:$false
        }
        else {
            Add-DhcpServerv4Failover `
                -Name $name `
                -PartnerServer $partnerServer `
                -ScopeId $scopeId `
                -SharedSecret $sharedSecret `
                -ServerRole $serverRole `
                -Confirm:$false
        }

        $module.Result.changed = $true
        $module.ExitJson()
    }
    catch {
        $module.FailJson("Failed to add the failover '$name'", $Error[0])
    }
}

# # Compare changes
# if (
#     ($dhcpServersScope.StartRange -ne $startRange) -or
#     ($dhcpServersScope.EndRange -ne $endRange) -or
#     ($dhcpServersScope.Name.Trim() -ne $name) -or
#     ($dhcpServersScope.Description.Trim() -ne $description) -or
#     ($dhcpServersScope.Type -ne $type) -or
#     ($dhcpServersScope.State -ne $scopeState)
# ) {
#     try {
#         Set-DhcpServerv4Scope `
#             -ScopeId $scopeId `
#             -StartRange $startRange `
#             -EndRange $endRange `
#             -Name $name`
#             -Description $description`
#             -State $scopeState `
#             -Type $type `
#             -Confirm:$false

#         $module.Result.changed = $true
#     }
#     catch {
#         $module.FailJson("Failed to set changed parameters for scope '$scopeId'", $Error[0])
#     }
# }

$module.ExitJson()
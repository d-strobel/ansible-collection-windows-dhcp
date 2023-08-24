#!powershell

# Copyright: (c) 2022, Dustin Strobel (@d-strobel)
# GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell Ansible.ModuleUtils.AddType

$spec = @{
    options             = @{
        name         = @{ type = "str"; required = $true }
        description  = @{ type = "str" }
        option_id    = @{ type = "int"; required = $true }
        vendor_class = @{ type = "str" }
        type         = @{ type = "str"; choices = "byte", "word", "dword", "dworddword", "ipv4address", "string", "binarydata", "encapsulateddata"; required = $true }
        state        = @{ type = "str"; choices = "absent", "present" ; default = "present" }
    }

    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

# Map variables
$name = $module.Params.name
$description = $module.Params.description
$optionID = $module.Params.option_id
$vendorClass = $module.Params.vendor_class
$type = $module.Params.type
$state = $module.Params.state

# ErrorAction
$ErrorActionPreference = 'Stop'

# Get VendorClass
if ($vendorClass) {
    $dhcpServerOptionDefinition = Get-DhcpServerv4OptionDefinition -Type $type -Name $name -VendorClass $vendorclass -ErrorAction SilentlyContinue
}
else {
    $dhcpServerOptionDefinition = Get-DhcpServerv4OptionDefinition -Type $type -Name $name -ErrorAction SilentlyContinue
}

# Early exit
if (($null -eq $dhcpServerOptionDefinition) -and ($state -eq "absent")) {
    $module.ExitJson()
}

# Remove option Definition
if (($null -ne $dhcpServerOptionDefinition) -and ($state -eq "absent")) {
    try {
        if ($vendorClass) {
            Remove-DhcpServerv4OptionDefinition -Type $type -Name $name -Confirm:$false | Out-Null
        }
        else {
            Remove-DhcpServerv4OptionDefinition -Type $type -Name $name -VendorClass $vendorclass -Confirm:$false | Out-Null
        }

        $module.Result.changed = $true
        $module.ExitJson()
    }
    catch {
        $module.FailJson("Failed to remove the dhcp option definition '$name'", $Error[0])
    }
}

# New option definition
if (($null -eq $dhcpServerOptionDefinition) -and ($state -eq "present")) {
    try {
        if ($vendorClass) {
            Add-DhcpServerv4OptionDefinition `
                -Name $name `
                -Type $type `
                -OptionID $optionID `
                -Description $description `
                -Confirm:$false
        }
        else {
            Add-DhcpServerv4OptionDefinition `
                -Name $name `
                -Type $type `
                -OptionID $optionID `
                -Description $description `
                -VendorClass $vendorclass `
                -Confirm:$false
        }

        $module.Result.changed = $true
        $module.ExitJson()
    }
    catch {
        $module.FailJson("Failed to add the dhcp option definition '$name'", $Error[0])
    }
}

# Compare changes
if (
    ($dhcpServerOptionDefinition.Type -ne $type) -or
    ($dhcpServerOptionDefinition.Description.Trim() -ne $description)
) {
    try {
        if ($vendorClass) {
            Set-DhcpServerv4OptionDefinition `
                -Name $name `
                -Type $type `
                -OptionID $optionID `
                -Description $description `
                -Confirm:$false
        }
        else {
            Set-DhcpServerv4OptionDefinition `
                -Name $name `
                -Type $type `
                -OptionID $optionID `
                -Description $description `
                -VendorClass $vendorclass `
                -Confirm:$false
        }

        $module.Result.changed = $true
    }
    catch {
        $module.FailJson("Failed to set changed parameters for dhcp option definition '$name'", $Error[0])
    }
}

$module.ExitJson()
<#
Copyright (c) 2012-2014 VMware, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
#>

<#
	.SYNOPSIS
		Take / restore / remove snapshot

	.DESCRIPTION
		This command takes, restores or removes a VM snapshot.
		This command could run against multiple virtual machines.
		
	.FUNCTIONALITY
		Snapshot, VM
		
	.NOTES
		AUTHOR: Jerry Liu
		EMAIL: liuj@vmware.com
#>

Param (
	[parameter(
		Mandatory=$true,
		HelpMessage="IP or FQDN of the ESX or VC server where target VM is located"
	)]
	[string]
		$serverAddress, 
	
	[parameter(
		HelpMessage="User name to connect to the server (default is root)"
	)]
	[string]
		$serverUser="root", 
	
	[parameter(
		HelpMessage="Password of the user"
	)]
	[string]
		$serverPassword=$env:defaultPassword, 
	
	[parameter(
		Mandatory=$true,
		HelpMessage="Name of target VM. Support multiple values seperated by comma and also wildcard."
	)]
	[string]
		$vmName, 

	[parameter(
		Mandatory=$true,
		HelpMessage="Name of snapshot"
	)]
	[string]
		$ssName,
	
	[parameter(
		Mandatory=$true,
		HelpMessage="Action against the snapshot"
	)]
	[ValidateSet(
		"Take",
		"Restore",
		"Remove"
	)]
	[string]
		$action,
	
	[parameter(
		HelpMessage="Snapshot description"
	)]
	[string]
		$ssDescription=""
)

foreach ($paramKey in $psboundparameters.keys) {
	$oldValue = $psboundparameters.item($paramKey)
	$newValue = [System.Net.WebUtility]::urldecode("$oldValue")
	set-variable -name $paramKey -value $newValue
}

. .\objects.ps1

$server = newServer $serverAddress $serverUser $serverPassword
$vmNameList = $vmName.split(",") | %{$_.trim()}	
$vivmList = get-vm -name $vmNameList -server $server.viserver
$vivmList | select -uniq | % { 
	$vm = newVm $server $_.name
	writeCustomizedMsg "Info - VM name is $($vm.name)"
	switch($action) {
		"take" {
			$vm.stop()
			Get-FloppyDrive -VM $vm.vivm | Set-FloppyDrive -NoMedia -Confirm:$False
			Get-CDDrive -VM $vm.vivm | Set-CDDrive -NoMedia -Confirm:$False   
			$vm.takeSnapshot($ssName,$ssDescription)
		}
		"restore" {
			$vm.restoreSnapshot($ssName)
		}
		"remove" {
			$vm.removeSnapshot($ssName)
		}
		default {
			writeCustomizedMsg "Fail - undefined action $action"
		}
	}
}
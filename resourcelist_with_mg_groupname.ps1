#-------------------------------------Notes----------------------------------------------
#Run the following commands till Connect-AzAccount separately via a powershell session before running this script
#Install-Module Az -confirm:$False
#Update-Module Az -confirm:$False
#Set-ExecutionPolicy UnRestricted -Confirm:$False
#Import-Module Az
#Connect-AzAccount

#Permissions required by the user running this script -- At least Global Reader role on all subscription.

$currentDir = $(Get-Location).Path
$outFile = "$($currentDir)\List_Of_All_Azure_Resources_$($date).csv"

if(Test-Path $outFile){
    Remove-Item $outFile -Force
}

"ManagementGroupName,SubscriptionName,ResourceGroupName,ResourceName,ResourceType,Tags,VMPowerState" | Out-File $outFile -Append -Encoding ascii

Get-AzManagementGroup | ForEach-Object {
    $managementGroupName = $_.Name

    Get-AzManagementGroupSubscription -GroupName $managementGroupName | ForEach-Object {
        $subscriptionId = $_.SubscriptionId
        $subscriptionName = $_.DisplayName

        if (![string]::IsNullOrEmpty($subscriptionId)) {
            Set-AzContext $subscriptionId 
        } else {
            # Remove the line that writes the message to the console
        }
        Get-AzResourceGroup | ForEach-Object {
            $resourceGroupName = $_.ResourceGroupName
            Get-AzResource -ResourceGroupName $resourceGroupName | ForEach-Object {
            $resourceName = $_.Name
            $resourceType = $_.ResourceType

            if ($resourceType -eq "Microsoft.Compute/virtualMachines") {
                (Get-AzVM -ResourceGroupName $resourceGroupName -Name $resourceName -Status).Statuses | Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -ExpandProperty DisplayStatus > $null
            }

                if(!([string]::IsNullOrEmpty($_.Tags))){
                    $tags = @()
                    $_.Tags.GetEnumerator() | ForEach-Object {
                        $tags += $_.Key + "=" + $_.Value + ";"
                    }
                }
                else{
                    $tags = ""
                }
                $powerState = ""
                if ($resourceType -eq "Microsoft.Compute/virtualMachines") {
                    $powerState = (Get-AzVM -ResourceGroupName $resourceGroupName -Name $resourceName -Status).Statuses | Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -ExpandProperty DisplayStatus
                }
                "$managementGroupName,$subscriptionName,$resourceGroupName,$resourceName,$resourceType,$tags,$powerState" | Out-File $outFile -Append -Encoding ascii
            }
        }
    }
}
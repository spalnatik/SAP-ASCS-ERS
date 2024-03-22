$ResourceGroup = "sles-ha-rg"
$Location = "EastUS"

$DiskSizeInGB = 4
$DiskName = "SBD-disk1"

$ShareNodes = 2

$SkuName = "Premium_LRS"

$diskConfig = New-AzDiskConfig -Location $Location -SkuName $SkuName -CreateOption Empty -DiskSizeGB $DiskSizeInGB -MaxSharesCount $ShareNodes
$dataDisk = New-AzDisk -ResourceGroupName $ResourceGroup -DiskName $DiskName -Disk $diskConfig

$VM1 = "nw1-cl1-0"
$VM2 = "nw1-cl1-1"


$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VM1
$vm = Add-AzVMDataDisk -VM $vm -Name $DiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun 0
Update-AzVm -VM $vm -ResourceGroupName $ResourceGroup -Verbose

$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VM2
$vm = Add-AzVMDataDisk -VM $vm -Name $DiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun 0
Update-AzVm -VM $vm -ResourceGroupName $ResourceGroup -Verbose

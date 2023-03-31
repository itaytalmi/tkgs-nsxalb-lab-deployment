# Author: William Lam
# Website: www.williamlam.com

# Reference blog post:
# https://williamlam.com/2021/04/automated-lab-deployment-script-for-vsphere-with-tanzu-using-nsx-advanced-load-balancer-nsx-alb.html

# vCenter Server used to deploy vSphere with Tanzu with NSX Advanced Load Balancer Lab
$VIServer = "vcsa@cloudnativeapps.cloud"
$VIUsername = "your-vsphere-user"
$VIPassword = "your-vsphere-password"

# https://williamlam.com/nested-virtualization/nested-esxi-virtual-appliance
# Full Path to both the Nested ESXi 7.0 VA, Extracted VCSA 7.0 ISO & NSX Advanced 20.1.7 OVA
$NestedESXiApplianceOVA = "C:\Users\itay\Downloads\tkgs\Nested_ESXi7.0u3k_Appliance_Template_v1.ova"
$VCSAInstallerPath = "C:\Users\itay\Downloads\tkgs\VMware-VCSA-all-7.0.3-21290409"
$NSXAdvLBOVA = "C:\Users\itay\Downloads\tkgs\controller-20.1.7-9154.ova"

# TKG Content Library URL
$TKGContentLibraryName = "tkg-content-library"
$TKGContentLibraryURL = "https://wp-content.vmware.com/v2/latest/lib.json"

# Nested ESXi VMs to deploy
$NestedESXiHostnameToIPs = @{
    "l01-tkgs-esxi-01" = "172.16.51.71"
    "l01-tkgs-esxi-02" = "172.16.51.72"
    "l01-tkgs-esxi-03" = "172.16.51.73"
}

# Nested ESXi VM Resources
$NestedESXivCPU = "4"
$NestedESXivMEM = "48" #GB
$NestedESXiCachingvDisk = "8" #GB
# Note: ensure you have enough capacity for the TKG content library (~250GB), Kubernetes nodes, persistent volumes, etc.
$NestedESXiCapacityvDisk = "300" #GB

# VCSA Deployment Configuration
$VCSADeploymentSize = "tiny"
$VCSADisplayName = "l01-tkgs-vcsa-01"
$VCSAIPAddress = "172.16.51.70"
$VCSAHostname = "l01-tkgs-vcsa-01.cloudnativeapps.cloud" #Change to IP if you don't have valid DNS
$VCSAPrefix = "24"
$VCSASSODomainName = "vsphere.local"
$VCSASSOPassword = "VMware1!"
$VCSARootPassword = "VMware1!"
$VCSASSHEnable = "true"

# NSX Advanced LB Configuration
$NSXALBVersion = "20.1.7"
$NSXAdvLBDisplayName = "l01-tkgs-nsxalb-01"
$NSXAdvLByManagementIPAddress = "172.16.51.69"
$NSXAdvLBHostname = "l01-tkgs-nsxalb-01.cloudnativeapps.cloud"
$NSXAdvLBAdminPassword = "VMware1!"
$NSXAdvLBvCPU = "8" #GB
$NSXAdvLBvMEM = "24" #GB
$NSXAdvLBPassphrase = "VMware1!"
$NSXAdvLBIPAMName = "tkgs-ipam"
$NSXALBLicenseType = "ESSENTIALS"
$NSXALBDefaultAdminPassword = "58NFaGDJm(PJH0G"
$NSXALBSEVMFolder = "nsxalb-service-engines"
$NSXALBSENamePrefix = "tkg_nsxalb"

# Service Engine Management Network Configuration
$NSXAdvLBManagementNetwork = "172.16.51.0"
$NSXAdvLBManagementNetworkPrefix = "24"
$NSXAdvLBManagementNetworkStartRange = "172.16.51.74"
$NSXAdvLBManagementNetworkEndRange = "172.16.51.77"

# VIP Network Configuration
$NSXAdvLBVIPNetworkName = "itay-k8s-vips"
$NSXAdvLBVIPNetwork = "172.16.53.0"
$NSXAdvLBVIPNetworkGateway = "172.16.53.1"
$NSXAdvLBVIPNetworkPrefix = "24"
$NSXAdvLBVIPNetworkStartRange = "172.16.53.20"
$NSXAdvLBVIPNetworkEndRange = "172.16.53.40"

# Self-Signed TLS Certificate
$NSXAdvLBSSLCertName = "nsx-alb"
$NSXAdvLBSSLCertExpiry = "365" # Days
$NSXAdvLBSSLCertEmail = "admin@lab.test"
$NSXAdvLBSSLCertOrganizationUnit = "k8s"
$NSXAdvLBSSLCertOrganization = "k8s"
$NSXAdvLBSSLCertLocation = "US"
$NSXAdvLBSSLCertState = "NY"
$NSXAdvLBSSLCertCountry = "US"

# General Deployment Configuration for Nested ESXi, VCSA & NSX Adv LB VM
$VMDatacenter = "Main"
$VMCluster = "LAB-V3"
$VMResourcePool = "US"
$VMNetwork = "itay-k8s-mgmt"
$WorkloadNetwork = "itay-k8s-nodes"
$VMDatastore = "LAB-V3-vSANDatastore"
$VMNetmask = "255.255.255.0"
$VMGateway = "172.16.51.1"
$VMDNS = "172.16.20.10"
$VMNTP = "172.16.20.10"
$VMPassword = "VMware1!"
$VMDomain = "cloudnativeapps.cloud"
$VMSyslog = "172.16.51.51"
$VMFolder = "tkgs-nested-infra"
$VMFolderFullPath = "LABS/itay/l01/tkgs-nested-infra"
# Applicable to Nested ESXi only
$VMSSH = "true"
$VMVMFS = "false"

# Name of new vSphere Datacenter/Cluster when VCSA is deployed
$NewVCDatacenterName = "tanzu-datacenter"
$NewVCVSANClusterName = "tanzu-cluster"
$NewVCVDSName = "tanzu-vds"
$NewVCMgmtPortgroupName = "dvpg-mgmt-network"
$NewVCWorkloadPortgroupName = "dvpg-node-network"
$NewVCVIPPortgroupName = "dvpg-vip-network"
$vSANDatastoreName = "vsanDatastore"

# Tanzu Configuration
$StoragePolicyName = "tkg-storage-policy"
$StoragePolicyTagCategory = "tkg-tag-category"
$StoragePolicyTagName = "tkg-storage"
$DevOpsUsername = "devops"
$DevOpsPassword = "VMware1!"

# Advanced Configurations
# Set to 1 only if you have DNS (forward/reverse) for ESXi hostnames
$addHostByDnsName = 1

#### DO NOT EDIT BEYOND HERE ####

$verboseLogFile = "tanzu-nsx-adv-lb-lab-deployment.log"
$random_string = -join ((65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
$VAppName = "Nested-Tanzu-NSX-Adv-LB-Lab-$random_string"

$preCheck = 1
$confirmDeployment = 1
$deployNSXAdvLB = 1
$deployNestedESXiVMs = 1
$deployVCSA = 1
$setupNewVC = 1
$addESXiHostsToVC = 1
$configureVSANDiskGroup = 1
$configureVDS = 1
$clearVSANHealthCheckAlarm = 1
$setupTanzuStoragePolicy = 1
$setupTanzu = 1
$setupNSXAdvLB = 1
$moveVMsIntovApp = 0

$vcsaSize2MemoryStorageMap = @{
    "tiny"   = @{"cpu" = "2"; "mem" = "12"; "disk" = "415" };
    "small"  = @{"cpu" = "4"; "mem" = "19"; "disk" = "480" };
    "medium" = @{"cpu" = "8"; "mem" = "28"; "disk" = "700" };
    "large"  = @{"cpu" = "16"; "mem" = "37"; "disk" = "1065" };
    "xlarge" = @{"cpu" = "24"; "mem" = "56"; "disk" = "1805" }
}

$esxiTotalCPU = 0
$vcsaTotalCPU = 0
$esxiTotalMemory = 0
$vcsaTotalMemory = 0
$esxiTotalStorage = 0
$vcsaTotalStorage = 0
$nsxalbTotalStorage = 128

$StartTime = Get-Date

Function GetNetworkSubnetMaskByPrefixLength {
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)
        ]
        [Alias('NetworkPrefixLength')]
        [String]$PrefixLength
    )

    $bitString = ('1' * $PrefixLength).PadRight(32, '0')

    $ipString = [String]::Empty

    # make 1 string combining a string for each byte and convert to int
    for ($i = 0; $i -lt 32; $i += 8) {
        $byteString = $bitString.Substring($i, 8)
        $ipString += "$([Convert]::ToInt32($byteString, 2))."
    }

    Return $ipString.TrimEnd('.')
}

Function Get-SSLThumbprint {
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)
        ]
        [Alias('FullName')]
        [String]$URL
    )

    $Code = @'
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
namespace CertificateCapture
{
    public class Utility
    {
        public static Func<HttpRequestMessage,X509Certificate2,X509Chain,SslPolicyErrors,Boolean> ValidationCallback =
            (message, cert, chain, errors) => {
                var newCert = new X509Certificate2(cert);
                var newChain = new X509Chain();
                newChain.Build(newCert);
                CapturedCertificates.Add(new CapturedCertificate(){
                    Certificate =  newCert,
                    CertificateChain = newChain,
                    PolicyErrors = errors,
                    URI = message.RequestUri
                });
                return true;
            };
        public static List<CapturedCertificate> CapturedCertificates = new List<CapturedCertificate>();
    }
    public class CapturedCertificate
    {
        public X509Certificate2 Certificate { get; set; }
        public X509Chain CertificateChain { get; set; }
        public SslPolicyErrors PolicyErrors { get; set; }
        public Uri URI { get; set; }
    }
}
'@
    if ($PSEdition -ne 'Core') {
        Add-Type -AssemblyName System.Net.Http
        if (-not ("CertificateCapture" -as [type])) {
            Add-Type $Code -ReferencedAssemblies System.Net.Http
        }
    }
    else {
        if (-not ("CertificateCapture" -as [type])) {
            Add-Type $Code
        }
    }

    $Certs = [CertificateCapture.Utility]::CapturedCertificates

    $Handler = [System.Net.Http.HttpClientHandler]::new()
    $Handler.ServerCertificateCustomValidationCallback = [CertificateCapture.Utility]::ValidationCallback
    $Client = [System.Net.Http.HttpClient]::new($Handler)
    $Client.GetAsync($Url).Result | Out-Null

    $sha1 = [Security.Cryptography.SHA1]::Create()
    $certBytes = $Certs[-1].Certificate.GetRawCertData()
    $hash = $sha1.ComputeHash($certBytes)
    $thumbprint = [BitConverter]::ToString($hash).Replace('-', ':')
    return $thumbprint.toLower()
}

Function MyLogger {
    param(
        [Parameter(Mandatory = $true)][String]$message,
        [Parameter(Mandatory = $false)][String]$color = "green"
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor $color " $message"
    $logMessage = "[$timeStamp] $message"
    $logMessage | Out-File -Append -LiteralPath $verboseLogFile
}

if ($preCheck -eq 1) {
    if (!(Test-Path $NestedESXiApplianceOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NestedESXiApplianceOVA ...`n"
        exit
    }

    if (!(Test-Path $VCSAInstallerPath)) {
        Write-Host -ForegroundColor Red "`nUnable to find $VCSAInstallerPath ...`n"
        exit
    }

    if (!(Test-Path $NSXAdvLBOVA) -and $deployNSXAdvLB -eq 1) {
        Write-Host -ForegroundColor Red "`nUnable to find $NSXAdvLBOVA ...`n"
        exit
    }

    if ($PSVersionTable.PSEdition -ne "Core") {
        Write-Host -ForegroundColor Red "`tPowerShell Core was not detected, please install that before continuing ... `n"
        exit
    }
}

if ($confirmDeployment -eq 1) {
    Write-Host -ForegroundColor Magenta "`nPlease confirm the following configuration will be deployed:`n"

    Write-Host -ForegroundColor Yellow "---- vSphere with Tanzu Basic Automated Lab Deployment Configuration ---- "
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi Image Path: "
    Write-Host -ForegroundColor White $NestedESXiApplianceOVA
    Write-Host -NoNewline -ForegroundColor Green "VCSA Image Path: "
    Write-Host -ForegroundColor White $VCSAInstallerPath
    Write-Host -NoNewline -ForegroundColor Green "HA Proxy Image Path: "
    Write-Host -ForegroundColor White $NSXAdvLBOVA

    Write-Host -ForegroundColor Yellow "`n---- vCenter Server Deployment Target Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "vCenter Server Address: "
    Write-Host -ForegroundColor White $VIServer
    Write-Host -NoNewline -ForegroundColor Green "VM Network: "
    Write-Host -ForegroundColor White $VMNetwork

    Write-Host -NoNewline -ForegroundColor Green "VM Storage: "
    Write-Host -ForegroundColor White $VMDatastore
    Write-Host -NoNewline -ForegroundColor Green "VM Cluster: "
    Write-Host -ForegroundColor White $VMCluster
    Write-Host -NoNewline -ForegroundColor Green "VM vApp: "
    Write-Host -ForegroundColor White $VAppName

    Write-Host -ForegroundColor Yellow "`n---- vESXi Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "# of Nested ESXi VMs: "
    Write-Host -ForegroundColor White $NestedESXiHostnameToIPs.count
    Write-Host -NoNewline -ForegroundColor Green "vCPU: "
    Write-Host -ForegroundColor White $NestedESXivCPU
    Write-Host -NoNewline -ForegroundColor Green "vMEM: "
    Write-Host -ForegroundColor White "$NestedESXivMEM GB"
    Write-Host -NoNewline -ForegroundColor Green "Caching VMDK: "
    Write-Host -ForegroundColor White "$NestedESXiCachingvDisk GB"
    Write-Host -NoNewline -ForegroundColor Green "Capacity VMDK: "
    Write-Host -ForegroundColor White "$NestedESXiCapacityvDisk GB"
    Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
    Write-Host -ForegroundColor White $NestedESXiHostnameToIPs.Values
    Write-Host -NoNewline -ForegroundColor Green "Netmask "
    Write-Host -ForegroundColor White $VMNetmask
    Write-Host -NoNewline -ForegroundColor Green "Gateway: "
    Write-Host -ForegroundColor White $VMGateway
    Write-Host -NoNewline -ForegroundColor Green "DNS: "
    Write-Host -ForegroundColor White $VMDNS
    Write-Host -NoNewline -ForegroundColor Green "NTP: "
    Write-Host -ForegroundColor White $VMNTP
    Write-Host -NoNewline -ForegroundColor Green "Syslog: "
    Write-Host -ForegroundColor White $VMSyslog
    Write-Host -NoNewline -ForegroundColor Green "Enable SSH: "
    Write-Host -ForegroundColor White $VMSSH
    Write-Host -NoNewline -ForegroundColor Green "Create VMFS Volume: "
    Write-Host -ForegroundColor White $VMVMFS

    Write-Host -ForegroundColor Yellow "`n---- VCSA Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "Deployment Size: "
    Write-Host -ForegroundColor White $VCSADeploymentSize
    Write-Host -NoNewline -ForegroundColor Green "SSO Domain: "
    Write-Host -ForegroundColor White $VCSASSODomainName
    Write-Host -NoNewline -ForegroundColor Green "Enable SSH: "
    Write-Host -ForegroundColor White $VCSASSHEnable
    Write-Host -NoNewline -ForegroundColor Green "Hostname: "
    Write-Host -ForegroundColor White $VCSAHostname
    Write-Host -NoNewline -ForegroundColor Green "IP Address: "
    Write-Host -ForegroundColor White $VCSAIPAddress
    Write-Host -NoNewline -ForegroundColor Green "Netmask "
    Write-Host -ForegroundColor White $VMNetmask
    Write-Host -NoNewline -ForegroundColor Green "Gateway: "
    Write-Host -ForegroundColor White $VMGateway

    Write-Host -ForegroundColor Yellow "`n---- NSX Advanced LB Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "Hostname: "
    Write-Host -ForegroundColor White $NSXAdvLBHostname
    Write-Host -NoNewline -ForegroundColor Green "Management IP Address: "
    Write-Host -ForegroundColor White $NSXAdvLByManagementIPAddress
    Write-Host -ForegroundColor Green "Service Engine: "
    Write-Host -NoNewline -ForegroundColor Green "   Portgroup: "
    Write-Host -ForegroundColor White $VMNetwork
    Write-Host -NoNewline -ForegroundColor Green "   Network: "
    Write-Host -ForegroundColor White $NSXAdvLBManagementNetwork/$NSXAdvLBManagementNetworkPrefix
    Write-Host -NoNewline -ForegroundColor Green "   Range: "
    Write-Host -ForegroundColor White "$NSXAdvLBManagementNetworkStartRange to $NSXAdvLBManagementNetworkEndRange"
    Write-Host -ForegroundColor Green "VIP: "
    Write-Host -NoNewline -ForegroundColor Green "   Portgroup: "
    Write-Host -ForegroundColor White $NSXAdvLBVIPNetworkName
    Write-Host -NoNewline -ForegroundColor Green "   Network: "
    Write-Host -ForegroundColor White $NSXAdvLBVIPNetwork/$NSXAdvLBVIPNetworkPrefix
    Write-Host -NoNewline -ForegroundColor Green "   Range: "
    Write-Host -ForegroundColor White "$NSXAdvLBVIPNetworkStartRange to $NSXAdvLBVIPNetworkEndRange"

    $esxiTotalCPU = $NestedESXiHostnameToIPs.count * [int]$NestedESXivCPU
    $esxiTotalMemory = $NestedESXiHostnameToIPs.count * [int]$NestedESXivMEM
    $esxiTotalStorage = ($NestedESXiHostnameToIPs.count * [int]$NestedESXiCachingvDisk) + ($NestedESXiHostnameToIPs.count * [int]$NestedESXiCapacityvDisk)
    $vcsaTotalCPU = $vcsaSize2MemoryStorageMap.$VCSADeploymentSize.cpu
    $vcsaTotalMemory = $vcsaSize2MemoryStorageMap.$VCSADeploymentSize.mem
    $vcsaTotalStorage = $vcsaSize2MemoryStorageMap.$VCSADeploymentSize.disk

    Write-Host -ForegroundColor Yellow "`n---- Resource Requirements ----"
    Write-Host -NoNewline -ForegroundColor Green "ESXi     VM CPU: "
    Write-Host -NoNewline -ForegroundColor White $esxiTotalCPU
    Write-Host -NoNewline -ForegroundColor Green " ESXi    VM Memory: "
    Write-Host -NoNewline -ForegroundColor White $esxiTotalMemory "GB "
    Write-Host -NoNewline -ForegroundColor Green "ESXi     VM Storage: "
    Write-Host -ForegroundColor White $esxiTotalStorage "GB"
    Write-Host -NoNewline -ForegroundColor Green "VCSA     VM CPU: "
    Write-Host -NoNewline -ForegroundColor White $vcsaTotalCPU
    Write-Host -NoNewline -ForegroundColor Green " VCSA     VM Memory: "
    Write-Host -NoNewline -ForegroundColor White $vcsaTotalMemory "GB "
    Write-Host -NoNewline -ForegroundColor Green "VCSA     VM Storage: "
    Write-Host -ForegroundColor White $vcsaTotalStorage "GB"
    Write-Host -NoNewline -ForegroundColor Green "NSX ALB  VM CPU: "
    Write-Host -NoNewline -ForegroundColor White $NSXAdvLBvCPU
    Write-Host -NoNewline -ForegroundColor Green " NSX ALB  VM Memory: "
    Write-Host -NoNewline -ForegroundColor White $NSXAdvLBvMEM "GB "
    Write-Host -NoNewline -ForegroundColor Green "NSX ALB  VM Storage: "
    Write-Host -ForegroundColor White $nsxalbTotalStorage "GB"

    Write-Host -ForegroundColor White "---------------------------------------------"
    Write-Host -NoNewline -ForegroundColor Green "Total CPU: "
    Write-Host -ForegroundColor White ($esxiTotalCPU + $vcsaTotalCPU + $nsxManagerTotalCPU + $NSXAdvLBvCPU)
    Write-Host -NoNewline -ForegroundColor Green "Total Memory: "
    Write-Host -ForegroundColor White ($esxiTotalMemory + $vcsaTotalMemory + $NSXAdvLBvMEM) "GB"
    Write-Host -NoNewline -ForegroundColor Green "Total Storage: "
    Write-Host -ForegroundColor White ($esxiTotalStorage + $vcsaTotalStorage + $nsxalbTotalStorage) "GB"

    Write-Host -ForegroundColor Magenta "`nWould you like to proceed with this deployment?`n"
    $answer = Read-Host -Prompt "Do you accept (Y or N)"
    if ($answer -ne "Y" -or $answer -ne "y") {
        exit
    }
    Clear-Host
}

if ($deployNestedESXiVMs -eq 1 -or $deployVCSA -eq 1 -or $deployNSXAdvLB -eq 1) {
    MyLogger "Connecting to Management vCenter Server $VIServer ..."
    $viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue -Force

    $datastore = Get-Datastore -Server $viConnection -Name $VMDatastore | Select-Object -First 1
    $cluster = Get-Cluster -Server $viConnection -Name $VMCluster
    $ResourcePool = Get-ResourcePool -Server $viConnection -Name $VMResourcePool -Location $cluster
    $datacenter = $cluster | Get-Datacenter
    $vmhost = $cluster | Get-VMHost | Select-Object -First 1
}

if ($deployNestedESXiVMs -eq 1) {
    $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value

        $ovfconfig = Get-OvfConfiguration $NestedESXiApplianceOVA
        $networkMapLabel = ($ovfconfig.ToHashTable().keys | Where-Object { $_ -Match "NetworkMapping" }).replace("NetworkMapping.", "").replace("-", "_").replace(" ", "_")
        $ovfconfig.NetworkMapping.$networkMapLabel.value = $VMNetwork

        $ovfconfig.common.guestinfo.hostname.value = $VMName
        $ovfconfig.common.guestinfo.ipaddress.value = $VMIPAddress
        $ovfconfig.common.guestinfo.netmask.value = $VMNetmask
        $ovfconfig.common.guestinfo.gateway.value = $VMGateway
        $ovfconfig.common.guestinfo.dns.value = $VMDNS
        $ovfconfig.common.guestinfo.domain.value = $VMDomain
        $ovfconfig.common.guestinfo.ntp.value = $VMNTP
        $ovfconfig.common.guestinfo.syslog.value = $VMSyslog
        $ovfconfig.common.guestinfo.password.value = $VMPassword
        if ($VMSSH -eq "true") {
            $VMSSHVar = $true
        }
        else {
            $VMSSHVar = $false
        }
        $ovfconfig.common.guestinfo.ssh.value = $VMSSHVar

        MyLogger "Deploying Nested ESXi VM $VMName ..."
        $vm = Import-VApp -Source $NestedESXiApplianceOVA -OvfConfiguration $ovfconfig -Name $VMName -Location $ResourcePool -InventoryLocation $VMFolder -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

        MyLogger "Adding vmnic2/vmnic3/vmnic4 for $VMNetwork/$WorkloadNetwork/$NSXAdvLBVIPNetworkName to passthrough to Nested ESXi VMs ..."

        $VMNetworkPorgroup = Get-VDPortgroup $VMNetwork
        $WorkloadNetworkPortgroup = Get-VDPortgroup $WorkloadNetwork
        $NSXAdvLBVIPNetworkPortgroup = Get-VDPortgroup $NSXAdvLBVIPNetworkName

        New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $VMNetworkPorgroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $WorkloadNetworkPortgroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $NSXAdvLBVIPNetworkPortgroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet2.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet2.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet3.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet3.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        MyLogger "Updating vCPU Count to $NestedESXivCPU & vMEM to $NestedESXivMEM GB ..."
        Set-VM -Server $viConnection -VM $vm -NumCpu $NestedESXivCPU -MemoryGB $NestedESXivMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        MyLogger "Updating vSAN Cache VMDK size to $NestedESXiCachingvDisk GB & Capacity VMDK size to $NestedESXiCapacityvDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB $NestedESXiCachingvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB $NestedESXiCapacityvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        MyLogger "Powering On $vmname ..."
        $vm | Start-Vm -RunAsync | Out-Null
    }
}

if ($deployNSXAdvLB -eq 1) {
    $ovfconfig = Get-OvfConfiguration $NSXAdvLBOVA

    $ovfconfig.NetworkMapping.Management.value = $VMNetwork
    $ovfconfig.avi.CONTROLLER.mgmt_ip.value = $NSXAdvLByManagementIPAddress

    $ovfconfig.avi.CONTROLLER.mgmt_mask.value = GetNetworkSubnetMaskByPrefixLength($NSXAdvLBManagementNetworkPrefix)
    $ovfconfig.avi.CONTROLLER.default_gw.value = $VMGateway

    MyLogger "Deploying NSX Advanced LB VM $NSXAdvLBDisplayName ..."
    $vm = Import-VApp -Source $NSXAdvLBOVA -OvfConfiguration $ovfconfig -Name $NSXAdvLBDisplayName -Location $ResourcePool -InventoryLocation $VMFolder -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

    MyLogger "Updating vCPU Count to $NSXAdvLBvCPU & vMEM to $NSXAdvLBvMEM GB ..."
    Set-VM -Server $viConnection -VM $vm -NumCpu $NSXAdvLBvCPU -MemoryGB $NSXAdvLBvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

    MyLogger "Powering On $NSXAdvLBDisplayName ..."
    $vm | Start-Vm -RunAsync | Out-Null
}

if ($deployVCSA -eq 1) {
    if ($IsWindows) {
        $config = (Get-Content -Raw "$($VCSAInstallerPath)\vcsa-cli-installer\templates\install\embedded_vCSA_on_VC.json") | convertfrom-json
    }
    else {
        $config = (Get-Content -Raw "$($VCSAInstallerPath)/vcsa-cli-installer/templates/install/embedded_vCSA_on_VC.json") | convertfrom-json
    }

    $config.'new_vcsa'.vc.hostname = $VIServer
    $config.'new_vcsa'.vc.username = $VIUsername
    $config.'new_vcsa'.vc.password = $VIPassword
    $config.'new_vcsa'.vc.deployment_network = $VMNetwork
    $config.'new_vcsa'.vc.datastore = $datastore.Name
    $config.'new_vcsa'.vc.datacenter = $datacenter.Name
    $config.'new_vcsa'.vc.target = @($VMCluster, "Resources", $ResourcePool.Name)
    $config.'new_vcsa'.vc | Add-Member NoteProperty -Name 'vm_folder' -Value $VMFolderFullPath.Split("/")
    $config.'new_vcsa'.appliance.thin_disk_mode = $true
    $config.'new_vcsa'.appliance.deployment_option = $VCSADeploymentSize
    $config.'new_vcsa'.appliance.name = $VCSADisplayName
    $config.'new_vcsa'.network.ip_family = "ipv4"
    $config.'new_vcsa'.network.mode = "static"
    $config.'new_vcsa'.network.ip = $VCSAIPAddress
    $config.'new_vcsa'.network.dns_servers[0] = $VMDNS
    $config.'new_vcsa'.network.prefix = $VCSAPrefix
    $config.'new_vcsa'.network.gateway = $VMGateway
    $config.'new_vcsa'.os.ntp_servers = $VMNTP
    $config.'new_vcsa'.network.system_name = $VCSAHostname
    $config.'new_vcsa'.os.password = $VCSARootPassword
    if ($VCSASSHEnable -eq "true") {
        $VCSASSHEnableVar = $true
    }
    else {
        $VCSASSHEnableVar = $false
    }
    $config.'new_vcsa'.os.ssh_enable = $VCSASSHEnableVar
    $config.'new_vcsa'.sso.password = $VCSASSOPassword
    $config.'new_vcsa'.sso.domain_name = $VCSASSODomainName

    if ($IsWindows) {
        MyLogger "Creating VCSA JSON Configuration file for deployment ..."
        $config | ConvertTo-Json -Depth 3 | Set-Content -Path "$($ENV:Temp)\jsontemplate.json"

        MyLogger "Deploying the VCSA ..."
        Invoke-Expression "$($VCSAInstallerPath)\vcsa-cli-installer\win32\vcsa-deploy.exe install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:Temp)\jsontemplate.json" | Out-File -Append -LiteralPath $verboseLogFile
    }
    elseif ($IsMacOS) {
        MyLogger "Creating VCSA JSON Configuration file for deployment ..."
        $config | ConvertTo-Json -Depth 3 | Set-Content -Path "$($ENV:TMPDIR)jsontemplate.json"

        MyLogger "Deploying the VCSA ..."
        Invoke-Expression "$($VCSAInstallerPath)/vcsa-cli-installer/mac/vcsa-deploy install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:TMPDIR)jsontemplate.json" | Out-File -Append -LiteralPath $verboseLogFile
    }
    elseif ($IsLinux) {
        MyLogger "Creating VCSA JSON Configuration file for deployment ..."
        $config | ConvertTo-Json -Depth 3 | Set-Content -Path "/tmp/jsontemplate.json"

        MyLogger "Deploying the VCSA ..."
        Invoke-Expression "$($VCSAInstallerPath)/vcsa-cli-installer/lin64/vcsa-deploy install --no-esx-ssl-verify --accept-eula --acknowledge-ceip /tmp/jsontemplate.json" | Out-File -Append -LiteralPath $verboseLogFile
    }
}

if ($moveVMsIntovApp -eq 1) {
    # Check whether DRS is enabled as that is required to create vApp
    if ((Get-Cluster -Server $viConnection $cluster).DrsEnabled) {
        MyLogger "Creating vApp $VAppName ..."
        $VApp = New-VApp -Name $VAppName -Server $viConnection -Location $cluster

        if (-Not (Get-Folder $VMFolder -ErrorAction Ignore)) {
            MyLogger "Creating VM Folder $VMFolder ..."
            New-Folder -Name $VMFolder -Server $viConnection -Location (Get-Datacenter $VMDatacenter | Get-Folder vm) | Out-Null
        }

        if ($deployNestedESXiVMs -eq 1) {
            MyLogger "Moving Nested ESXi VMs into $VAppName vApp ..."
            $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
                $vm = Get-VM -Name $_.Key -Server $viConnection
                Move-VM -VM $vm -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            }
        }

        if ($deployVCSA -eq 1) {
            $vcsaVM = Get-VM -Name $VCSADisplayName -Server $viConnection
            MyLogger "Moving $VCSADisplayName into $VAppName vApp ..."
            Move-VM -VM $vcsaVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        if ($deployNSXAdvLB -eq 1) {
            $nsxAdvLBVM = Get-VM -Name $NSXAdvLBDisplayName -Server $viConnection
            MyLogger "Moving $NSXAdvLBDisplayName into $VAppName vApp ..."
            Move-VM -VM $nsxAdvLBVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        MyLogger "Moving $VAppName to VM Folder $VMFolder ..."
        Move-VApp -Server $viConnection $VAppName -Destination (Get-Folder -Server $viConnection $VMFolder) | Out-File -Append -LiteralPath $verboseLogFile
    }
    else {
        MyLogger "vApp $VAppName will NOT be created as DRS is NOT enabled on vSphere Cluster ${cluster} ..."
    }
}

if ($deployNestedESXiVMs -eq 1 -or $deployVCSA -eq 1 -or $deployNSXAdvLB -eq 1) {
    MyLogger "Disconnecting from $VIServer ..."
    Disconnect-VIServer * -Confirm:$false
}

if ($setupNewVC -eq 1) {
    MyLogger "Connecting to the new VCSA ..."
    $vc = Connect-VIServer $VCSAIPAddress -User "administrator@$VCSASSODomainName" -Password $VCSASSOPassword -WarningAction SilentlyContinue -Force

    $d = Get-Datacenter -Server $vc $NewVCDatacenterName -ErrorAction Ignore
    if (-Not $d) {
        MyLogger "Creating Datacenter $NewVCDatacenterName ..."
        New-Datacenter -Server $vc -Name $NewVCDatacenterName -Location (Get-Folder -Type Datacenter -Server $vc) | Out-File -Append -LiteralPath $verboseLogFile
    }

    $c = Get-Cluster -Server $vc $NewVCVSANClusterName -ErrorAction Ignore
    if (-Not $c) {
        MyLogger "Creating VSAN Cluster $NewVCVSANClusterName ..."
        New-Cluster -Server $vc -Name $NewVCVSANClusterName -Location (Get-Datacenter -Name $NewVCDatacenterName -Server $vc) -DrsEnabled -HAEnabled -VsanEnabled | Out-File -Append -LiteralPath $verboseLogFile

        (Get-Cluster $NewVCVSANClusterName) | New-AdvancedSetting -Name "das.ignoreRedundantNetWarning" -Type ClusterHA -Value $true -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    }

    if ($addESXiHostsToVC -eq 1) {
        $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value

            $targetVMHost = $VMIPAddress
            if ($addHostByDnsName -eq 1) {
                $targetVMHost = $VMName
            }
            MyLogger "Adding ESXi host $targetVMHost to Cluster ..."
            Add-VMHost -Server $vc -Location (Get-Cluster -Name $NewVCVSANClusterName) -User "root" -Password $VMPassword -Name $targetVMHost -Force | Out-File -Append -LiteralPath $verboseLogFile
        }

        $haRuntime = (Get-Cluster $NewVCVSANClusterName).ExtensionData.RetrieveDasAdvancedRuntimeInfo
        $totalHaHosts = $haRuntime.TotalHosts
        $totalHaGoodHosts = $haRuntime.TotalGoodHosts
        while ($totalHaGoodHosts -ne $totalHaHosts) {
            MyLogger "Waiting for vSphere HA configuration to complete ..."
            Start-Sleep -Seconds 60
            $haRuntime = (Get-Cluster $NewVCVSANClusterName).ExtensionData.RetrieveDasAdvancedRuntimeInfo
            $totalHaHosts = $haRuntime.TotalHosts
            $totalHaGoodHosts = $haRuntime.TotalGoodHosts
        }
    }

    if ($configureVSANDiskGroup -eq 1) {
        MyLogger "Enabling VSAN & disabling VSAN Health Check ..."
        Get-VsanClusterConfiguration -Server $vc -Cluster $NewVCVSANClusterName | Set-VsanClusterConfiguration -HealthCheckIntervalMinutes 0 | Out-File -Append -LiteralPath $verboseLogFile

        foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
            $luns = $vmhost | Get-ScsiLun | Select-Object CanonicalName, CapacityGB

            MyLogger "Querying ESXi host disks to create VSAN Diskgroups ..."
            foreach ($lun in $luns) {
                if (([int]($lun.CapacityGB)).toString() -eq "$NestedESXiCachingvDisk") {
                    $vsanCacheDisk = $lun.CanonicalName
                }
                if (([int]($lun.CapacityGB)).toString() -eq "$NestedESXiCapacityvDisk") {
                    $vsanCapacityDisk = $lun.CanonicalName
                }
            }
            MyLogger "Creating VSAN DiskGroup for $vmhost ..."
            New-VsanDiskGroup -Server $vc -VMHost $vmhost -SsdCanonicalName $vsanCacheDisk -DataDiskCanonicalName $vsanCapacityDisk | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    if ($configureVDS -eq 1) {
        # vmnic0 = Management on VSS
        # vmnic1 = unused
        # vmnic2 = Management on VDS (uplink1)
        # vmnic3 = Wrokload on VDS (uplink2)
        # vmnic4 = Frontend on VDS (uplink3)

        $vds = New-VDSwitch -Server $vc -Name $NewVCVDSName -Location (Get-Datacenter -Name $NewVCDatacenterName) -Mtu 1600 -NumUplinkPorts 3

        MyLogger "Creating VDS Management Network Portgroup"
        New-VDPortgroup -Server $vc -Name $NewVCMgmtPortgroupName -Vds $vds | Out-File -Append -LiteralPath $verboseLogFile
        Get-VDPortgroup -Server $vc $NewVCMgmtPortgroupName | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort @("dvUplink1") -UnusedUplinkPort @("dvUplink2", "dvUplink3") | Out-File -Append -LiteralPath $verboseLogFile

        MyLogger "Creating VDS Supervisor Cluster Management Network Portgroup"
        New-VDPortgroup -Server $vc -Name $NewVCWorkloadPortgroupName -Vds $vds | Out-File -Append -LiteralPath $verboseLogFile
        Get-VDPortgroup -Server $vc $NewVCWorkloadPortgroupName | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort @("dvUplink2") -UnusedUplinkPort @("dvUplink1", "dvUplink3") | Out-File -Append -LiteralPath $verboseLogFile

        MyLogger "Creating VDS Frontend Network Portgroup"
        New-VDPortgroup -Server $vc -Name $NewVCVIPPortgroupName -Vds $vds | Out-File -Append -LiteralPath $verboseLogFile
        Get-VDPortgroup -Server $vc $NewVCVIPPortgroupName | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort @("dvUplink3") -UnusedUplinkPort @("dvUplink1", "dvUplink2") | Out-File -Append -LiteralPath $verboseLogFile

        foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
            MyLogger "Adding $vmhost to $NewVCVDSName"
            $vds | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null

            $vmhostNetworkAdapter = Get-VMHost $vmhost | Get-VMHostNetworkAdapter -Physical -Name vmnic2, vmnic3, vmnic4
            $vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$false
        }
    }

    if ($clearVSANHealthCheckAlarm -eq 1) {
        MyLogger "Clearing default VSAN Health Check Alarms, not applicable in Nested ESXi env ..."
        $alarmMgr = Get-View AlarmManager -Server $vc
        Get-Cluster -Server $vc | Where-Object { $_.ExtensionData.TriggeredAlarmState } | ForEach-Object {
            $cluster = $_
            $Cluster.ExtensionData.TriggeredAlarmState | ForEach-Object {
                $alarmMgr.AcknowledgeAlarm($_.Alarm, $cluster.ExtensionData.MoRef)
            }
        }
        $alarmSpec = New-Object VMware.Vim.AlarmFilterSpec
        $alarmMgr.ClearTriggeredAlarms($alarmSpec)
    }

    # Final configure and then exit maintanence mode in case patching was done earlier
    foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
        # Disable Core Dump Warning
        Get-AdvancedSetting -Entity $vmhost -Name UserVars.SuppressCoredumpWarning | Set-AdvancedSetting -Value 1 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        # Enable vMotion traffic
        $vmhost | Get-VMHostNetworkAdapter -VMKernel | Set-VMHostNetworkAdapter -VMotionEnabled $true -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        if ($vmhost.ConnectionState -eq "Maintenance") {
            Set-VMHost -VMhost $vmhost -State Connected -RunAsync -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    if ($setupTanzuStoragePolicy) {
        MyLogger "Creating Tanzu Storage Policies and attaching to $vSANDatastoreName..."
        New-TagCategory -Server $vc -Name $StoragePolicyTagCategory -Cardinality single -EntityType Datastore | Out-File -Append -LiteralPath $verboseLogFile
        New-Tag -Server $vc -Name $StoragePolicyTagName -Category $StoragePolicyTagCategory | Out-File -Append -LiteralPath $verboseLogFile
        Get-Datastore -Server $vc -Name $vSANDatastoreName | New-TagAssignment -Server $vc -Tag $StoragePolicyTagName | Out-File -Append -LiteralPath $verboseLogFile
        New-SpbmStoragePolicy -Server $vc -Name $StoragePolicyName -AnyOfRuleSets (New-SpbmRuleSet -Name "tanzu-ruleset" -AllOfRules (New-SpbmRule -AnyOfTags (Get-Tag $StoragePolicyTagName))) | Out-File -Append -LiteralPath $verboseLogFile
    }

    MyLogger "Disconnecting from new VCSA ..."
    Disconnect-VIServer * -Confirm:$false
}

if ($setupTanzu -eq 1) {
    MyLogger "Connecting to Management vCenter Server $VIServer for enabling Tanzu ..."
    Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue -Force | Out-Null

    MyLogger "Creating local $DevOpsUsername User in vCenter Server ..."
    $devopsUserCreationCmd = "/usr/lib/vmware-vmafd/bin/dir-cli user create --account $DevOpsUsername --first-name `"Dev`" --last-name `"Ops`" --user-password `'$DevOpsPassword`' --login `'administrator@$VCSASSODomainName`' --password `'$VCSASSOPassword`'"
    Invoke-VMScript -ScriptText $devopsUserCreationCmd -vm (Get-VM -Name $VCSADisplayName) -GuestUser "root" -GuestPassword "$VCSARootPassword" | Out-File -Append -LiteralPath $verboseLogFile

    MyLogger "Disconnecting from Management vCenter ..."
    Disconnect-VIServer * -Confirm:$false | Out-Null

    $vc = Connect-VIServer $VCSAIPAddress -User "administrator@$VCSASSODomainName" -Password $VCSASSOPassword -WarningAction SilentlyContinue -Force

    MyLogger "Creating TKG Subscribed Content Library $TKGContentLibraryName ..."
    $clScheme = ([System.Uri]$TKGContentLibraryURL).scheme
    $clHost = ([System.Uri]$TKGContentLibraryURL).host
    $clPort = ([System.Uri]$TKGContentLibraryURL).port
    $clThumbprint = Get-SSLThumbprint -Url "${clScheme}://${clHost}:${clPort}"

    New-ContentLibrary -Server $vc -Name $TKGContentLibraryName -Description "Subscribed TKG Content Library" -Datastore (Get-Datastore -Server $vc $vSANDatastoreName) -AutomaticSync -SubscriptionUrl $TKGContentLibraryURL -SslThumbprint $clThumbprint | Out-File -Append -LiteralPath $verboseLogFile

    Disconnect-VIServer * -Confirm:$false | Out-Null
}

if ($setupNSXAdvLB -eq 1) {
    # Create NSX ALB Service Engines VM folder
    MyLogger "Creating NSX ALB Service Engines VM folder in new vCSA..."
    $vc = Connect-VIServer $VCSAIPAddress -User "administrator@$VCSASSODomainName" -Password $VCSASSOPassword -WarningAction SilentlyContinue -Force
    New-Folder -Server $vc -Location VM -Name $NSXALBSEVMFolder | Out-Null
    Remove-Folder -Server $vc -Folder "Discovered virtual machine" -Confirm:$false | Out-Null

    Disconnect-VIServer * -Confirm:$false | Out-Null

    # NSX ALB can take up to several minutes to initialize upon initial power on
    while (1) {
        try {
            $response = Invoke-WebRequest -Uri http://${NSXAdvLByManagementIPAddress} -SkipCertificateCheck
            if ($response.StatusCode -eq 200) {
                MyLogger "$NSXAdvLBDisplayName is now ready for configuration ..."
                break
            }
        }
        catch {
            MyLogger "$NSXAdvLBDisplayName is not ready, sleeping for 2 minutes ..."
            Start-Sleep -Seconds 120
        }
    }

    # Assumes Basic Auth has been enabled per automation below
    $pair = "admin:$NSXAdvLBAdminPassword"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)

    $newPassbasicAuthHeaders = @{
        "Authorization" = "basic $base64";
        "Content-Type"  = "application/json";
        "Accept"        = "application/json";
        "x-avi-version" = $NSXALBVersion;
    }

    $enableBasicAuth = 1
    $updateAdminPassword = 1
    $updateBackupPassphrase = 1
    $updateDnsNtpSmtpSettings = 1
    $updateWelcomeWorkflow = 1
    $createSSLCertificate = 1
    $updateSSlCertificate = 1
    $registervCenter = 1
    $updateVCMgmtNetwork = 1
    $updateVCWorkloadNetwork = 1
    $createDefaultIPAM = 1
    $updateDefaultIPAM = 1
    $updateNSXALBLicense = 1

    if ($enableBasicAuth -eq 1) {
        $headers = @{
            "Content-Type" = "application/json"
            "Accept"       = "application/json"
        }

        $payload = @{
            username = "admin";
            password = $NSXALBDefaultAdminPassword;
        }

        $defaultPasswordBody = $payload | ConvertTo-Json

        $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/login -Body $defaultPasswordBody -Method POST -Headers $headers -SessionVariable WebSession -SkipCertificateCheck
        $csrfToken = $WebSession.Cookies.GetCookies("https://${NSXAdvLByManagementIPAddress}/login")["csrftoken"].value

        $headers = @{
            "Content-Type"  = "application/json"
            "Accept"        = "application/json"
            "x-avi-version" = $NSXALBVersion
            "x-csrftoken"   = $csrfToken
            "referer"       = "https://${NSXAdvLByManagementIPAddress}/login"
        }

        $json = (Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Method GET -Headers $headers -WebSession $WebSession -SkipCertificateCheck).Content | ConvertFrom-Json
        $json.portal_configuration.allow_basic_authentication = $true
        $systemConfigBody = $json | ConvertTo-Json -Depth 10

        try {
            MyLogger "Enabling basic auth ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Body $systemConfigBody -Method PUT -Headers $headers -WebSession $WebSession -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to update basic auth" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully enabled basic auth for $NSXAdvLBDisplayName ..."
        }
        else {
            MyLogger "Something went wrong enabling basic auth" "yellow"
            $response
            break
        }
    }

    if ($updateAdminPassword -eq 1) {
        $pair = "admin:$NSXALBDefaultAdminPassword"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)

        $basicAuthHeaders = @{
            "Authorization" = "basic $base64"
            "Content-Type"  = "application/json"
            "Accept"        = "application/json"
        }

        $payload = @{
            old_password = $NSXALBDefaultAdminPassword;
            password     = $NSXAdvLBAdminPassword;
            username     = "admin"
        }

        $newPasswordBody = $payload | ConvertTo-Json

        try {
            MyLogger "Changing default admin password"
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/useraccount -Body $newPasswordBody -Method PUT -Headers $basicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to change admin password" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully changed default admin password ..."
        }
        else {
            MyLogger "Something went wrong changing default admin password" "yellow"
            $response
            break
        }
    }

    if ($updateBackupPassphrase -eq 1) {
        $backupJsonResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/backupconfiguration -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results[0]

        $passPhraseJson = @{
            "add" = @{
                "backup_passphrase" = $nsxAdvLBPassphrase;
            }
        }
        $newBackupJsonBody = ($passPhraseJson | ConvertTo-json)

        try {
            MyLogger "Configuring backup passphrase ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/backupconfiguration/$($backupJsonResult.uuid) -body $newBackupJsonBody -Method PATCH -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to update backup passphrase" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully updated backup passphrase ..."
        }
        else {
            MyLogger "Something went wrong updating backup passphrase" "yellow"
            $response
            break
        }
    }

    if ($updateDnsNtpSmtpSettings -eq 1) {
        $dnsNtpResults = (Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json

        $dnsNtpResults.dns_configuration.search_domain = "$VMDomain"
        $dnsNtpResults.email_configuration.smtp_type = "SMTP_NONE"

        $dnsConfig = @{
            "addr" = "$VMDNS";
            "type" = "V4";
        }

        $ntpConfig = @{
            "server" = @{
                "addr" = "$VMNTP";
                "type" = "V4";
            }
        }

        $dnsNtpResults.dns_configuration | Add-Member -Force -MemberType NoteProperty -Name server_list -Value @($dnsConfig)
        $dnsNtpResults.ntp_configuration | Add-Member -Force -MemberType NoteProperty -Name ntp_servers -Value @($ntpConfig)
        $newDnsNtpJsonBody = ($dnsNtpResults | ConvertTo-json -Depth 4)

        try {
            MyLogger "Configuring DNS, NTP and SMTP settings"
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -body $newDnsNtpJsonBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to update DNS, NTP and SMTP settings" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully updated DNS, NTP and SMTP settings ..."
        }
        else {
            MyLogger "Something went wrong with updating DNS, NTP and SMTP settings" "yellow"
            $response
            break
        }
    }

    if ($updateNSXALBLicense -eq 1) {
        $NSXALBSystemConfig = (Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json

        $NSXALBSystemConfig.default_license_tier = $NSXALBLicenseType

        $NewNSXALBSystemConfig = ($NSXALBSystemConfig | ConvertTo-json -Depth 4)

        try {
            MyLogger "Configuring licensing"
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -body $NewNSXALBSystemConfig -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to update licensing" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully updated licensing..."
        }
        else {
            MyLogger "Something went wrong with updating licensing" "yellow"
            $response
            break
        }
    }

    if ($updateWelcomeWorkflow -eq 1) {
        $welcomeWorkflowJson = @{
            "replace" = @{
                "welcome_workflow_complete" = "true";
            }
        }

        $welcomeWorkflowBody = ($welcomeWorkflowJson | ConvertTo-json)

        try {
            MyLogger "Disabling initial welcome message ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -body $welcomeWorkflowBody -Method PATCH -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to disable welcome workflow message" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully disabled welcome workflow message ..."
        }
        else {
            MyLogger "Something went wrong disabling welcome workflow message" "yellow"
            $response
            break
        }
    }

    if ($createSSLCertificate -eq 1) {

        $selfSignCertPayload = @{
            "certificate"        = @{
                "expiry_status"     = "SSL_CERTIFICATE_GOOD";
                "days_until_expire" = $NSXAdvLBSSLCertExpiry;
                "self_signed"       = "true"
                "subject"           = @{
                    "common_name"       = $NSXAdvLBHostname;
                    "email_address"     = $NSXAdvLBSSLCertEmail;
                    "organization_unit" = $NSXAdvLBSSLCertOrganizationUnit;
                    "organization"      = $NSXAdvLBSSLCertOrganization;
                    "locality"          = $NSXAdvLBSSLCertLocation;
                    "state"             = $NSXAdvLBSSLCertState;
                    "country"           = $NSXAdvLBSSLCertCountry;
                };
                "subject_alt_names" = @($NSXAdvLByManagementIPAddress);
            };
            "key_params"         = @{
                "algorithm"  = "SSL_KEY_ALGORITHM_RSA";
                "rsa_params" = @{
                    "key_size" = "SSL_KEY_2048_BITS";
                    "exponent" = "65537";
                };
            };
            "status"             = "SSL_CERTIFICATE_FINISHED";
            "format"             = "SSL_PEM";
            "certificate_base64" = "true";
            "key_base64"         = "true";
            "type"               = "SSL_CERTIFICATE_TYPE_SYSTEM";
            "name"               = $NSXAdvLBSSLCertName;
        }

        $selfSignCertBody = ($selfSignCertPayload | ConvertTo-Json -Depth 8)

        try {
            MyLogger "Creating self-signed TLS certificate ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/sslkeyandcertificate -body $selfSignCertBody -Method POST -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Error in creating self-sign TLS certificate" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 201) {
            MyLogger "Successfully created self-sign TLS certificate ..."
        }
        else {
            MyLogger "Something went wrong creating self-sign TLS certificate" "yellow"
            $response
            break
        }
    }

    if ($updateSSlCertificate -eq 1) {
        $certJsonResults = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/sslkeyandcertificate?include_name -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | Where-Object { $_.name -eq $NSXAdvLBSSLCertName }

        $systemConfigJsonResults = (Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json

        $systemConfigJsonResults.portal_configuration.sslkeyandcertificate_refs = @(${certJsonResults}.url)

        $updateSSLCertBody = $systemConfigJsonResults | ConvertTo-Json -Depth 4

        try {
            MyLogger "Updating NSX ALB to new self-sign TLS ceretificate ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -body $updateSSLCertBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Error in updating self-sign TLS certificate" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully updated to new self-sign TLS certificate ..."
        }
        else {
            MyLogger "Something went wrong updating to new self-sign TLS certificate" "yellow"
            $response
            break
        }
    }

    if ($registervCenter -eq 1) {
        $cloudConfigResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results[0]

        $cloudConfigResult.vtype = "CLOUD_VCENTER"

        $vcConfig = @{
            "username"             = "administrator@vsphere.local"
            "password"             = "$VCSASSOPassword";
            "vcenter_url"          = "$VCSAHostname";
            "privilege"            = "WRITE_ACCESS";
            "datacenter"           = "$NewVCDatacenterName";
            "management_ip_subnet" = @{
                "ip_addr" = @{
                    "addr" = "$NSXAdvLBManagementNetwork";
                    "type" = "V4";
                };
                "mask"    = "$NSXAdvLBManagementNetworkPrefix";
            }
        }

        $cloudConfigResult | Add-Member -MemberType NoteProperty -Name vcenter_configuration -Value $vcConfig

        $newCloudConfigBody = ($cloudConfigResult | ConvertTo-Json -Depth 4)

        try {
            MyLogger "Register Tanzu vCenter Server $VCSAHostname to NSX ALB ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud/$($cloudConfigResult.uuid) -body $newCloudConfigBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to register Tanzu vCenter Server" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully registered Tanzu vCenter Server ..."
        }
        else {
            MyLogger "Something went wrong registering Tanzu vCenter Server" "yellow"
            $response
            break
        }
    }

    if ($updateVCMgmtNetwork -eq 1) {
        Start-Sleep -Seconds 20

        $cloudNetworkResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | Where-Object { $_.name -eq $NewVCMgmtPortgroupName }

        $mgmtNetworkConfig = @{
            "prefix"           = @{
                "ip_addr" = @{
                    "addr" = "$NSXAdvLBManagementNetwork";
                    "type" = "V4";
                };
                "mask"    = "$NSXAdvLBManagementNetworkPrefix";
            };
            "static_ip_ranges" = @(
                @{
                    "range" = @{
                        "begin" = @{
                            "addr" = $NSXAdvLBManagementNetworkStartRange;
                            "type" = "V4";
                        };
                        "end"   = @{
                            "addr" = $NSXAdvLBManagementNetworkEndRange;
                            "type" = "V4";
                        }
                    };
                    "type"  = "STATIC_IPS_FOR_VIP_AND_SE";
                }
            )
        }

        $cloudNetworkResult | Add-Member -MemberType NoteProperty -Name configured_subnets -Value @($mgmtNetworkConfig)

        $newCloudMgmtNetworkBody = ($cloudNetworkResult | ConvertTo-Json -Depth 10)

        # Create Subnet mapping
        try {
            MyLogger "Creating subnet mapping for Service Engine Network ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network/$($cloudNetworkResult.uuid) -body $newCloudMgmtNetworkBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to create subnet mapping for $NewVCMgmtPortgroupName" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully created subnet mapping for $NewVCMgmtPortgroupName ..."
        }
        else {
            MyLogger "Something went wrong creating subnet mapping for $NewVCMgmtPortgroupName" "yellow"
            $response
            break
        }

        # Add default Gateway
        $vrfContextResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/vrfcontext -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | Where-Object { $_.name -eq "global" }

        $staticRouteConfig = @{
            "next_hop" = @{
                "addr" = $NSXAdvLBVIPNetworkGateway;
                "type" = "V4";
            };
            "route_id" = "1";
            "prefix"   = @{
                "ip_addr" = @{
                    "addr" = "0.0.0.0";
                    "type" = "V4";
                };
                "mask"    = "0"
            }
        }

        $vrfContextResult | Add-Member -Force -MemberType NoteProperty -Name static_routes -Value @($staticRouteConfig)

        $newvrfContextBody = ($vrfContextResult | ConvertTo-Json -Depth 10)

        try {
            MyLogger "Updating VRF Context for default gateway ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/vrfcontext/$(${vrfContextResult}.uuid) -body $newvrfContextBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to update VRF context" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully updated VRF context ..."
        }
        else {
            MyLogger "Something went wrong updating VRF context" "yellow"
            $response
            break
        }

        # Configure Service Engine group
        $ServiceEngineGroupResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/serviceenginegroup -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | Where-Object { $_.name -eq "Default-Group" }

        $vSphereClusterRefURL = (((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/vimgrclusterruntime -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | where-object { $_.name -eq $NewVCVSANClusterName }).url

        $ServiceEngineGroupResult.vcenter_folder = $NSXALBSEVMFolder
        $ServiceEngineGroupResult.se_name_prefix = $NSXALBSENamePrefix
        $ServiceEngineGroupResult.vcenter_datastores_include = $True
        $ServiceEngineGroupResult.vcenter_datastore_mode = "VCENTER_DATASTORE_SHARED"

        $NSXALBSEGDatastore = @{
            "datastore_name" = $vSANDatastoreName
        }

        $ServiceEngineGroupResult | Add-Member -Force -MemberType NoteProperty -Name vcenter_datastores -Value @($NSXALBSEGDatastore)

        $NSXALBvSphereClusterConfig = @{
            "include" = $True
            "cluster_refs" = @(
                $vSphereClusterRefURL
            )
        }

        $ServiceEngineGroupResult | Add-Member -Force NoteProperty -Name 'vcenter_clusters' -Value $NSXALBvSphereClusterConfig

        $NewSEGJSONBody = ($ServiceEngineGroupResult | ConvertTo-Json -Depth 10)

        try {
            MyLogger "Updating Service Engine Group configuration.."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/serviceenginegroup/$(${ServiceEngineGroupResult}.uuid) -body $NewSEGJSONBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to update Service Engine Group" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully updated Service Engine Group..."
        }
        else {
            MyLogger "Something went wrong updating Service Engine Group" "yellow"
            $response
            break
        }

        # Associate Tanzu Management Network to vCenter
        $cloudNetworkResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | Where-Object { $_.name -eq $NewVCMgmtPortgroupName }

        $cloudConfigResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results[0]


        $cloudConfigResult.vcenter_configuration | Add-Member -MemberType NoteProperty -Name management_network -Value $(${cloudNetworkResult}.vimgrnw_ref)
        $newCloudConfigBody = ($cloudConfigResult | ConvertTo-Json -Depth 4)

        try {
            MyLogger "Associating Service Engine network to Tanzu vCenter Server ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud/$(${cloudConfigResult}.uuid) -body $newCloudConfigBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to associate service engine network to Tanzu vCenter Server" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully associated service engine network to Tanzu vCenter Server ..."
        }
        else {
            MyLogger "Something went wrong associating service engine network to Tanzu vCenter Server" "yellow"
            $response
            break
        }
    }

    if ($updateVCWorkloadNetwork -eq 1) {
        $cloudNetworkResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | Where-Object { $_.name -eq $NewVCVIPPortgroupName }

        $workloadNetworkConfig = @{
            "prefix"           = @{
                "ip_addr" = @{
                    "addr" = "$NSXAdvLBVIPNetwork";
                    "type" = "V4";
                };
                "mask"    = "$NSXAdvLBVIPNetworkPrefix";
            };
            "static_ip_ranges" = @(
                @{
                    "range" = @{
                        "begin" = @{
                            "addr" = $NSXAdvLBVIPNetworkStartRange;
                            "type" = "V4";
                        };
                        "end"   = @{
                            "addr" = $NSXAdvLBVIPNetworkEndRange;
                            "type" = "V4";
                        }
                    };
                    "type"  = "STATIC_IPS_FOR_VIP_AND_SE";
                }
            )
        }

        $cloudNetworkResult | Add-Member -MemberType NoteProperty -Name configured_subnets -Value @($workloadNetworkConfig)

        $newCloudWorkloadNetworkBody = ($cloudNetworkResult | ConvertTo-Json -Depth 10)

        # Create Subnet mapping
        try {
            MyLogger "Creating subnet mapping for Workload Network ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network/$($cloudNetworkResult.uuid) -body $newCloudWorkloadNetworkBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to create subnet mapping for $NewVCVIPPortgroupName" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully created subnet mapping for $NewVCVIPPortgroupName ..."
        }
        else {
            MyLogger "Something went wrong creating subnet mapping for $NewVCVIPPortgroupName" "yellow"
            $response
            break
        }
    }

    if ($createDefaultIPAM -eq 1) {
        $cloudNetworkResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | Where-Object { $_.name -eq $NewVCVIPPortgroupName }

        $ipamConfig = @{
            "name"               = $NSXAdvLBIPAMName;
            "tenant_ref"         = "https://${NSXAdvLByManagementIPAddress}/tenant/admin";
            "type"               = "IPAMDNS_TYPE_INTERNAL";
            "internal_profile"   = @{
                "ttl"             = "30";
                "usable_networks" = @(
                    @{
                        "nw_ref" = "$(${cloudNetworkResult}.url)"
                    }
                );
            };
            "allocate_ip_in_vrf" = "true"
        }

        $ipamBody = $ipamConfig | ConvertTo-Json -Depth 4

        try {
            MyLogger "Creating new IPAM Default Profile ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/ipamdnsproviderprofile -body $ipamBody -Method POST -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to create IPAM default profile" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 201) {
            MyLogger "Successfully created IPAM default profile ..."
        }
        else {
            MyLogger "Something went wrong creating IPAM default profile" "yellow"
            $response
            break
        }
    }

    if ($updateDefaultIPAM -eq 1) {
        $ipamResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/ipamdnsproviderprofile -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | Where-Object { $_.name -eq $NSXAdvLBIPAMName }

        $cloudConfigResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results[0]

        $cloudConfigResult | Add-Member -MemberType NoteProperty -Name ipam_provider_ref -Value $ipamResult.url

        $newClouddConfigBody = ($cloudConfigResult | ConvertTo-Json -Depth 10)

        try {
            MyLogger "Updating Default Cloud to new IPAM Profile ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud/$($cloudConfigResult.uuid) -body $newClouddConfigBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        }
        catch {
            MyLogger "Failed to update default IPAM profile" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if ($response.Statuscode -eq 200) {
            MyLogger "Successfully updated default IPAM profile ..."
        }
        else {
            MyLogger "Something went wrong updating default IPAM profile" "yellow"
            $response
            break
        }
    }
}

$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes, 2)

MyLogger "vSphere with Tanzu NSX Advanced LB Lab Deployment Complete!"
MyLogger "StartTime: $StartTime"
MyLogger "EndTime: $EndTime"
MyLogger "Duration: $duration minutes"
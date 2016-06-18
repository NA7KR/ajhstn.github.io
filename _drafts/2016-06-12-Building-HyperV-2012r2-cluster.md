---
layout: post
published: false
---
1. Assign the volume to the new host/s
2. Move VM config and dependent files into the same CSV
3. Copy Cluster Roles Wizard
4. Move active disk session to HIL1
5. Shut server down
6. !important! Take CSV offline
7. Remove CSV
8. Enable processor compatability (only needed because HPDEMO has a different processor)
9. !important! Disconnect all sessions for that volume from each old host
10. Unassign the volume from the old servers (in Virtual Store)
11. Reconnect them all to the new host/s
12. Bring CSV online
13. Start VM
14. Upgrade Integration Services
15. When happy, delete the VM from the old cluster
Building/Adding a cluster node.
In our case, we i am evicting a server node from the old cluster, rebuild it and join it to the new cluster.
16. Drain roles
17. Disconnect all iSCSI targets
~~~PowerShell
 Get-IscsiTarget | Where-Object {$_.IsConnected -eq $true} | Disconnect-IscsiTarget -Confirm:$false -WhatIf
 ~~~v
18. stop cluster service
19. Evict node from cluster
20. Shutdown node
21. Disconnect/Remove SAN server node in StoreVirtual
Configuring the new node using PowerShell
Using the steps below will quickly configure and get your new host read.  I have included comments to explain the commands.
Here is a summary of what i am doing.
22. Configure the physical Nics
23. Create a Nic team
24. Install the Hyper-V roles
25. Create and configure the virtual switches
26. Activate windows
27. Join it to the domain
28. Join it to the cluster
29. connect up all the iscsi targets
PS C:\ Install-WindowsFeature hyper-v,failover-clustering,multipath-io -IncludeManagementTools -IncludeAllSubFeatures -Restart
 
PS C:\ Get-NetAdapter
This will list your network adapter so that you know how to rename them.  It is important to know that "HP FlexFabric 10Gb" are your LAN adapters and "HP NC552SFP Dual Port 10GbE" are you iSCSI adapters.  Then run the commands below to rename your 4 adapters.  If you wish its only most helpful to rename the two LAN adapters, you will see why next.
PS C:\ Rename-NetAdapter 'Ethernet x' -NewName iSCSI1
PS C:\ Rename-NetAdapter 'Ethernet x' -NewName iSCSI2
PS C:\ Rename-NetAdapter 'Ethernet x' -NewName LAN1
PS C:\ Rename-NetAdapter 'Ethernet x' -NewName LAN2
 
PS C:\ New-NetLbfoTeam -Name LANTeam -TeamMembers LAN1,LAN2 -TeamingMode LACP -LoadBalancingAlgorithm TransportPorts
Here you will create a network team using the two LAN adapters.  You can see above, why the renaming makes life a lot easier.
PS C:\ New-NetIPAddress -ifIndex <> -IPAddress 10.0.0.103 -AddressFamily ipv4 -PrefixLength 24 -DefaultGateway 10.0.0.1
After you the get-netadapter above, you will see the new team adapter and its ifIndex number.  Now use that ifIndex in the command above to set its IP address.  This step isnt necessary, as you will likely have to do it again later on the virtual adapter.
PS C:\ Get-NetAdapter
PS C:\ Set-DnsClientServerAddress InterfaceIndex <> -ServerAddresses 10.0.0.14,10.0.0.15
And now its DNS servers.
PS C:\ netsh advfirewall set allprofiles state off
Turn off Windows Firewall.
PS C:\ ping 10.0.0.1
Now do some ping tests and make sure all is well.  PS, the combined command above only works in powershell.
PS C:\ slmgr.vbs -ipk NW89Y-BTCM2-23WRP-276XD-JTXCW, or X6GFD-TNRR4-H9DVY-R899V-94QWW
PS C:\ slmgr.vbs -ato
This activates windows 2012 r2.
PS C:\ Add-Computer -DomainName hillsong.net -NewName 'newname' -Credential hillsong\marcellus -Restart
Join the computer to the domain and give it a new name at the same time.
PS C:\ New-VMSwitch -EnableIov $true -AllowManagementOS $true -NetAdapterInterfaceDescription "Microsoft Network Adapter Multiplexor Driver" -Name "External Virtual Switch"
Here we need to run another get-netadapter and take note of the lan team's interfaceDescription, then use it above to create a virtual switch.
PS C:\ Set-VMNetworkAdapterVlan -Access -VlanId 3 -ManagementOS -VMNetworkAdapterName "External Virtual Switch"
PS C:\ New-VMSwitch -Name "iSCSI-1 Virtual Switch" -AllowManagementOS $true -NetAdapterName iSCSI1
PS C:\ New-VMSwitch -Name "iSCSI-2 Virtual Switch" -AllowManagementOS $true -NetAdapterName iSCSI2
The above two lines, create the iSCSI virtual switches.
PS C:\ New-NetIPAddress -ifIndex 30 -IPAddress 10.0.15.85 -AddressFamily ipv4 -PrefixLength 24
PS C:\ New-NetIPAddress -ifIndex 31 -IPAddress 10.0.15.86 -AddressFamily ipv4 -PrefixLength 24
The above two lines set the iSCSI ip addresses.
PS C:\ Get-NetAdapter
This is just to show you now your adapter list, it includes your team, and you can see its set to vlan 3.
Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
LANTeam - VLAN 3          Microsoft Network Adapter Multiplexo...      33 Up           E8-39-35-C5-24-7C        20 Gbps
LAN2                      HP FlexFabric 10Gb 2-port 554FLR-S...#2      15 Up           E8-39-35-C5-24-7C        10 Gbps
LAN1                      HP FlexFabric 10Gb 2-port 554FLR-SFP...      14 Up           E8-39-35-C5-24-78        10 Gbps
iSCSI1                    HP NC552SFP Dual Port 10GbE Server A...      12 Up           10-60-4B-01-22-0C        10 Gbps
iSCSI2                    HP NC552SFP Dual Port 10GbE Server...#2      13 Up           10-60-4B-01-22-08        10 Gbps
Now we will connect the node to all the available volumes so its ready for migrations and cluster operations.
 
PS C:\ iscsicpl
Start up the iscsi initiator service.
PS C:\Scripts> iscsicli
Microsoft iSCSI Initiator Version 6.2 Build 9200
[iqn.1991-05.com.microsoft:hil1hv4.hillsong.net] Enter command or ^C to exit
Login to StoreVirtual, and using the host initiator node name above, add the server.
PS C:\ New-IscsiTargetPortal -TargetPortalAddress 10.0.15.5
PS C:\ New-IscsiTargetPortal -TargetPortalAddress 10.0.15.6
It would be fine to use the above lines, but you cant select the local adapter.  So follow these steps instead.
Start up iscsi initiator, click Discovery tab, click Discover Portal, add 10.0.15.5, click Advanced, select the "Microsoft iSCSI Initiator" local adapter, then OK, OK.  Repeat this for the 10.0.15.6 portal.
Now add the node to the cluster.
 
Once you have added the server node in store virtual and assigned it to the appropriate volumes, this command updates the initiator, so that it can 'see' the volumes.
~~~powershell
PS C:\ $nodes = Invoke-Command hil2hv4 {(Get-IscsiTarget|Where-Object {$_.IsConnected -eq $true}).NodeAddress}
PS C:\ $nodes | Foreach-Object {Connect-IscsiTarget -NodeAddress $_ -IsPersistent $true -IsMultipathEnabled $true}
PS C:\ iscsicli BindPersistentVolumes
PS C:\ iscsicli BindPersistentDevices
~~~

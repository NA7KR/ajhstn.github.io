Set-Location C:\Build

. .\Convert-WindowsImage.ps1

# Mount the wim, inject updates
@'
ImageIndex       : 1
ImageName        : Windows Server 2012 R2 SERVERSTANDARDCORE
ImageDescription : Windows Server 2012 R2 SERVERSTANDARDCORE
ImageSize        : 7,460,086,466 bytes

ImageIndex       : 2
ImageName        : Windows Server 2012 R2 SERVERSTANDARD
ImageDescription : Windows Server 2012 R2 SERVERSTANDARD
ImageSize        : 13,068,096,479 bytes
'@

Get-ChildItem -Recurse .\Updates\* -Filter *.msu | Where-Object {$_.FullName -like "*2012r2*"} | Copy-Item -Destination .\MSUPackages

Dism /Mount-Image /ImageFile:C:\Build\install.wim /index:2 /MountDir:C:\Build\offline

Dism /Image:C:\Build\offline /LogPath:AddPackage.log /Add-Package /PackagePath:C:\Build\MSUPackages

Dism /Unmount-Image /MountDir:C:\Build\offline /commit

Convert-WindowsImage -SourcePath .\install.wim -Edition 'serverstandardcore' -SizeBytes 96GB -VHDType Dynamic -VHDPartitionStyle GPT -UnattendPath .\unattend.xml -VHDPath .\base.vhdx -Verbose

Import-Module .\BoseSoundTouch.psm1

#Generate Random ;)
$Preset = Get-Random -Minimum 1 -Maximum 6

$Master = "192.168.1.67"
$Slave  = "192.168.1.102"

#Set SoundTouch to low Volume Level (Power on qual volume = 10)
BoseSoundTouch -SoundTouchIP $Master -SetVolume 1 -Power off
BoseSoundTouch -SoundTouchIP $Slave  -SetVolume 1 -Power off

#Make Group (testing)
BoseSoundTouch -SoundTouchIP $Master -Power on -PostApiKey "setZone" -ApiXml "<zone master='8030DC6C68BE'><member ipaddress='$Master' role='NORMAL'>8030DC6C68BE</member><member ipaddress='$Slave ' role='NORMAL'>B0D5CCBE08EB</member></zone>"

#Set Preset and Volume
BoseSoundTouch -SoundTouchIP $Master -SetVolume 50 -SetPreset $Preset -VolumeFadeTime 60 -SendKey REPEAT_ALL

#Set Volume second speaker
BoseSoundTouch -SoundTouchIP $Slave  -SetVolume 50 -VolumeFadeTime 20
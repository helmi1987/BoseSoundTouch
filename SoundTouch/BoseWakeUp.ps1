Import-Module .\BoseSoundTouch.psm1

#Generate Random ;)
$Preset = Get-Random -Minimum 1 -Maximum 6

#Run SoundTouch with Random Preset :)
BoseSoundTouch -SoundTouchIP <IP or DNS> -SetVolume 50 -SetPreset $Preset
Function BoseSoundTouch{

    #Get-Help
    <# 
    .SYNOPSIS 
    Control the Bose SoundTouch System

    .DESCRIPTION 
    Description coming soon

    .PARAMETER SoundtouchIp
    Set the IP oder DNS Adress 

    .PARAMETER OutputPath 


    .INPUTS 


    .OUTPUTS 


    .EXAMPLE
    BoseSoundTouch -SoundTouchIP <IP/DNS> -SetVolume 20
    Set Bose SoundTouch Volume to 20%


    .NOTES
    script creator: helmi1987
	
    VERSION HISTORY
    1.0.0   2016-06-30   Initial version
    1.0.1   2016*07-01   add Power On/Off Parameter
    1.0.2   2016-07-02   add Get-Help Section   

    #> 

    [CmdletBinding()]
    #PARAM
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$SoundTouchIP,
        
        
        [parameter(Mandatory=$false)]
        [ValidateRange(1,100)]
        [int32]$SetVolume,
        
        
        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [string]$PostApiKey,[string]$ApiXml,


        [parameter(Mandatory=$false)]
        [ValidateRange(1,6)]
        [int32]$SetPreset,

        
        [parameter(Mandatory=$false)]
        [ValidateSet("on", "ein", "off", "aus")]
        [string]$Power,
        
        
        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [string]$SendKey 
    )

    #PROCESS
    PROCESS{
        #GlobalVariable
        IF("GlobalVariable"){
            [string]$URL               = "http://" + $SoundTouchIP + ":8090"
            [xml]$SoundTouchVolume     = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/volume"
            [xml]$SoundTouchPresets    = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/presets"
            [xml]$SoundTouchNowPlaying = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/now_playing"
        }

        #Set Volume
        IF($SetVolume){
            IF($SoundTouchVolume.volume.actualvolume -ne $SetVolume){
                $Result = Invoke-WebRequest -UseBasicParsing "$URL/volume" -Method Post -ContentType 'text/xml' -Body "<volume>$SetVolume</volume>"
                Write-Host SetVolume to $SetVolume = $Result.StatusDescription
            } else {
            Write-Host Volume was on $SetVolume
            }
        }

        #Change to Preset
        IF($SetPreset){
            IF($SoundTouchPresets.presets.preset.ContentItem[$SetPreset - 1].location -ne $SoundTouchNowPlaying.nowPlaying.ContentItem.location){
                $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">PRESET_$SetPreset</key>"
                $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">PRESET_$SetPreset</key>"
                Write-Host SetPreset to $SetPreset = $Result.StatusDescription
            } else {
                Write-Host Preset was on $SetPreset
            }
        }

        #Send a key
        IF($SendKey){
            $SendKey = $SendKey.ToUpper()
            $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">$SendKey</key>"
            $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">$SendKey</key>"
            Write-Host Sendkey "$Sendkey" = $Result.StatusDescription
        }

        #Send a API-Key
        IF($PostApiKey -and $ApiXml){
            $Result = Invoke-WebRequest -UseBasicParsing "$URL/$PostApiKey" -Method Post -ContentType 'text/xml' -Body "$ApiXml"
            Write-Host PostApiKey $PostApi = $Result.StatusDescription
        }

        #Set Power on/off
        IF($Power){
            IF(($Power -eq "on") -or ($Power -eq "ein")){
                IF($SoundTouchNowPlaying.nowPlaying.source -eq "STANDBY"){
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">POWER</key>"
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">POWER</key>"
                } else {
                    Write-Host SoundTouch power was $Power
                }
            } else {
                IF($SoundTouchNowPlaying.nowPlaying.source -ne "STANDBY"){
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">POWER</key>"
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">POWER</key>"
                } else {
                    Write-Host SoundTouch power was $Power
                }
            }
        }
    }
}
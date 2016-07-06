Function BoseSoundTouch{
    #region Get-Help
    <#
    .SYNOPSIS 
    Control the Bose SoundTouch System

    .DESCRIPTION
    A Simple Powershell_Module for Controlling the BOSE SoundTouch over the BOSE API
    
    .PARAMETER SetVolume
    Set the Volume Level from 1-100

    .PARAMETER SetPreset
    Set the Preset to 1-6

    .PARAMETER Power
    Turn the SoundToch on or off

    .PARAMETER SendKey
    Send a Custom Button to the SoundTouch
    Value: PLAY, PAUSE, STOP, PREV_TRACK, NEXT_TRACK, THUMBS_UP, THUMBS_DOWN, BOOKMARK, POWER, MUTE, VOLUME_UP, VOLUME_DOWN, PRESET_1, PRESET_2, PRESET_3, PRESET_4, PRESET_5, PRESET_6, AUX_INPUT, SHUFFLE_OFF, SHUFFLE_ON, REPEAT_OFF, REPEAT_ONE, REPEAT_ALL, PLAY_PAUSE, ADD_FAVORITE, REMOVE_FAVORITE, INVALID_KEY

    .PARAMETER PostApiKey, ApiXml
    Send a Custom Api key to SoundTouch

    .PARAMETER OutputPath
    Specifies the name and path for the CSV-based output file. By default, 
    MonthlyUpdates.ps1 generates a name from the date and time it runs, and
    saves the output in the local directory.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> BoseSoundTouch -SoundTouchIP <IP/DNS> -SetVolume 20
    Set Bose SoundTouch Volume to 20%

    .EXAMPLE
    C:\PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv

    .EXAMPLE
    C:\PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv -outputPath C:\Reports\2009\January.csv
    
    .NOTES
    script creator: helmi1987
	
    VERSION HISTORY
    1.0.0   2016-06-30   Initial version
    1.0.1   2016-07-01   add Power On/Off Parameter
    1.0.2   2016-07-02   add Get-Help Section
    1.0.3   2016-07-03   add Output Object
    1.0.4   2016-07-06   add Volume fade in Function

    .LINK
    Github repo: https://github.com/helmi1987/SoundTouch

    #>
    #endregion

    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$SoundTouchIP,
        
        
        [parameter(Mandatory=$false)]
        [ValidateRange(1,100)]
        [int32]$SetVolume,


        [parameter(Mandatory=$false)]
        [ValidateRange(1,20)]
        [int32]$VolumeFadeTime,

        
        [parameter(Mandatory=$false)]
        [ValidateRange(1,6)]
        [int32]$SetPreset,
        
        
        [parameter(Mandatory=$false)]
        [ValidateSet("on", "off")]
        [string]$Power,


        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [string]$SendKey, 


        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [string]$PostApiKey,[string]$ApiXml
    )

    Begin{
        #region GlobalVariable
        #Make URL-Adress für the API
        [string]$URL               = "http://" + $SoundTouchIP + ":8090"
    
        #Read status form SoundTouch
        [xml]$SoundTouchVolume     = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/volume"
        [xml]$SoundTouchPresets    = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/presets"
        [xml]$SoundTouchNowPlaying = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/now_playing"
        #endregion

        #region Functions
        #Create Result Data Array
        $ResultDataArray = New-Object System.Collections.Generic.List[object]
    
        #Write Output to Object $ResultDataArray
        Function ResultOutput([string]$function,[string]$value,[string]$Result){
            $ResultOutput =  New-Object Psobject -Property @{
            function = $function
            value    = $value
            status   = $Result
            }
            $ResultDataArray.add($ResultOutput)
        }
         
        #Send Key to SoundTouch
        Function PostKey($Key){
            $Key = $Key.ToUpper()
            $PostKey = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">$Key</key>"
            $PostKey = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">$Key</key>"
            return $PostKey.StatusDescription
        }

        #Post Volume Level
        Function PostVolume($Volume){
            $PostVolume = Invoke-WebRequest -UseBasicParsing "$URL/volume" -Method Post -ContentType 'text/xml' -Body "<volume>$Volume</volume>"
            return $PostVolume.StatusDescription
        }

        #VolumeFadeIn
        Function FadeInVolume($FadeTime,$SetVolume){
            $FadeStart    = 1                                   #Start Volume

            $VolStepTotal = $SetVolume - $FadeStart             #Total Steps
            $FadeTimestep = ($FadeTime * 60000) / $VolStepTotal #Time in Millisecond from 1 to 2

            $PostVolume   = PostVolume $FadeStart               #Start Volume

            Do{
                Start-Sleep -m $FadeTimeStep
                $FadeStart  = $FadeStart + 1
                $PostVolume = PostVolume $FadeStart
            }
            while([int]$FadeStart -ne [int]$SetVolume)
            return $PostVolume
        }
        #endregion
    }
    
    Process{
        
        #region SetVolume
        IF(-not $VolumeFadeTime -and $SetVolume){
            IF($SoundTouchVolume.volume.actualvolume -ne $SetVolume){
                $PostVolume = PostVolume $SetVolume
                ResultOutput "SetVolume" $SetVolume $PostVolume
            } else {
                ResultOutput "SetVolume" $SetVolume "Do nothing value was $SetVolume"
            }
        }
        #endregion

        #region Change to Preset
        IF($SetPreset){
            IF($Power -ne "off"){
                IF($SoundTouchPresets.presets.preset.ContentItem[$SetPreset - 1].location -ne $SoundTouchNowPlaying.nowPlaying.ContentItem.location){
                    $PostKey = PostKey "PRESET_$SetPreset";
                    ResultOutput "SetPreset" $SetPreset $PostKey
                } else {
                    ResultOutput "SetPreset" $SetPreset "Do nothing value was $SetPreset"
                }
                IF($Power -eq "on"){
                    ResultOutput "Power" $Power "Power $Power over SetPreset"
                    Remove-Variable Power
                }
            } else {
                ResultOutput "SetPreset" $Power "Do nothing Power value is $Power"
            }
        }
        #endregion

        #region VolumeFadeTime
        IF($VolumeFadeTime -and $SetVolume){
            $VolumeFadeIn = FadeInVolume $VolumeFadeTime $SetVolume
            ResultOutput "SetVolume" $SetVolume "$VolumeFadeIn over VolumeFadeTime, FadeTime was $VolumeFadeTime minute(s)"
        }
        #endregion

        #region Send a key
        IF($SendKey){
            $PostKey = PostKey $SendKey;
            ResultOutput "SendKey" $SendKey $PostKey
        }
        #endregion

        #region Set Power on/off
        IF($Power){
            IF($Power -eq "on"){
                IF($SoundTouchNowPlaying.nowPlaying.source -eq "STANDBY"){
                    $PostKey = PostKey "POWER"
                    ResultOutput "Power" $Power $PostKey
                } else {
                    ResultOutput "Power" $Power "Do nothing System Power was $Power"
                }
            }
            IF($Power -eq "off"){
                IF($SoundTouchNowPlaying.nowPlaying.source -ne "STANDBY"){
                    $PostKey = PostKey "POWER"
                    ResultOutput "Power" $Power $PostKey
                } else {
                    ResultOutput "Power" $Power "Do nothing System Power was $Power"
                }
            }
        }
        #endregion

        #region Send a API-Key
        IF($PostApiKey -and $ApiXml){
            $Result = Invoke-WebRequest -UseBasicParsing "$URL/$PostApiKey" -Method Post -ContentType 'text/xml' -Body "$ApiXml"
            ResultOutput "PostCustomApiKey" $PostApiKey $Result.StatusDescription
        }
        #endregion
    }

    End{
        #region Result Output
        $ResultDataArray | Select function,value,status | FT
        #endregion
    }
}
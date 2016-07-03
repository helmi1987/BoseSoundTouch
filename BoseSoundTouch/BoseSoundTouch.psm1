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
    1.0.3   2016-07-03   add Output Object  

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
        [ValidateSet("on", "off")]
        [string]$Power,
        
        
        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [string]$SendKey 
    )
    #PROCESS
    PROCESS{
        #GlobalVariable
        IF("GlobalVariable"){
            #Make URL-Adress für the API
            [string]$URL               = "http://" + $SoundTouchIP + ":8090"
            
            #Read status form SoundTouch
            [xml]$SoundTouchVolume     = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/volume"
            [xml]$SoundTouchPresets    = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/presets"
            [xml]$SoundTouchNowPlaying = Invoke-WebRequest -Method Get -UseBasicParsing "$URL/now_playing"
        }

        #Functions
        IF("Functions"){
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
        }

        #Set Volume
        IF($SetVolume){
            IF($SoundTouchVolume.volume.actualvolume -ne $SetVolume){
                $PostVolume = PostVolume $SetVolume
                ResultOutput "SetVolume" $SetVolume $PostVolume
            } else {
                ResultOutput "SetVolume" $SetVolume "Do nothing value was $SetVolume"
            }
        }

        #Change to Preset
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

        #Send a key
        IF($SendKey){
            $PostKey = PostKey $SendKey;
            ResultOutput "SendKey" $SendKey $PostKey
        }

        #Set Power on/off
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

        #Send a API-Key
        IF($PostApiKey -and $ApiXml){
            $Result = Invoke-WebRequest -UseBasicParsing "$URL/$PostApiKey" -Method Post -ContentType 'text/xml' -Body "$ApiXml"
            ResultOutput "PostCustomApiKey" $PostApiKey $Result.StatusDescription
        }


        #Result Output
        $ResultDataArray | Select function,value,status | FT
    }

}
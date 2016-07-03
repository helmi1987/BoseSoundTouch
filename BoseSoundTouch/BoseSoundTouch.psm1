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
            
            #Create Result Data Array
            $ResultDataArray = New-Object System.Collections.Generic.List[object]

            #Write Output to Object $ResultDataArray
            function ResultOutput([string]$function,[string]$value,[string]$result){
                $ResultOutput =  New-Object Psobject -Property @{
                    function = $function
                    value    = $value
                    status   = $result
                }
                    $ResultDataArray.add($ResultOutput)
            }
        }

        #Set Volume
        IF($SetVolume){
            IF($SoundTouchVolume.volume.actualvolume -ne $SetVolume){
                $Result = Invoke-WebRequest -UseBasicParsing "$URL/volume" -Method Post -ContentType 'text/xml' -Body "<volume>$SetVolume</volume>"
                ResultOutput "SetVolume" $SetVolume $Result.StatusDescription;
            } else {
                ResultOutput "SetVolume" $SetVolume "Do nothing value was $SetVolume";
            }
        }

        #Change to Preset
        IF($SetPreset){
            IF($Power -ne "off"){
                IF($SoundTouchPresets.presets.preset.ContentItem[$SetPreset - 1].location -ne $SoundTouchNowPlaying.nowPlaying.ContentItem.location){
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">PRESET_$SetPreset</key>"
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">PRESET_$SetPreset</key>"
                    ResultOutput "SetPreset" $SetPreset $Result.StatusDescription;
                } else {
                    ResultOutput "SetPreset" $SetPreset "Do nothing value was $SetPreset";
                }
                IF($Power -eq "on"){
                    Remove-Variable Power
                    ResultOutput "Power" $Power "Power on over SetPreset";
                }
            } else {
                ResultOutput "SetPreset" $Power "Do nothing Power value is $Power";
            }
        }

        #Send a key
        IF($SendKey){
            $SendKey = $SendKey.ToUpper()
            $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">$SendKey</key>"
            $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">$SendKey</key>"
            ResultOutput "SendKey" $SendKey $Result.StatusDescription;
        }

        #Send a API-Key
        IF($PostApiKey -and $ApiXml){
            $Result = Invoke-WebRequest -UseBasicParsing "$URL/$PostApiKey" -Method Post -ContentType 'text/xml' -Body "$ApiXml"
            ResultOutput "PostCustomApiKey" $PostApiKey $Result.StatusDescription;
        }

        #Set Power on/off
        IF($Power){
            IF($Power -eq "on"){
                IF($SoundTouchNowPlaying.nowPlaying.source -eq "STANDBY"){
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">POWER</key>"
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">POWER</key>"
                    ResultOutput "Power" $Power $Result.StatusDescription;
                } else {
                    ResultOutput "Power" $Power "Do nothing System Power was $Power";
                }
            }
            IF($Power -eq "off"){
                IF($SoundTouchNowPlaying.nowPlaying.source -ne "STANDBY"){
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""press"" sender=""Gabbo"">POWER</key>"
                    $Result = Invoke-WebRequest -UseBasicParsing "$URL/key" -Method Post -ContentType 'text/xml' -Body "<key state=""release"" sender=""Gabbo"">POWER</key>"
                    ResultOutput "Power" $Power $Result.StatusDescription;
                } else {
                    ResultOutput "Power" $Power "Do nothing System Power was $Power";
                }
            }
        }

        #Result Output
        $ResultDataArray | Select function,value,status | FT
    }

}
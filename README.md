# BoseSoundTouch
Control BOSE SoundTouch with Powershell

## SYNTAX
 BoseSoundTouch -SoundTouchIP "DNS_or_IP" -SetVolume "1-100" -SetPreset "1-6" -Power "on/off" -SendKey "KEY_VALUE" -PostApiKey "string" -ApiXml "string"

Button for -SendKey
KEY_VALUE { 
            PLAY,
	    PAUSE,
	    STOP,
	    PREV_TRACK,
	    NEXT_TRACK,
	    THUMBS_UP,
	    THUMBS_DOWN,
	    BOOKMARK,
	    POWER,
	    MUTE,
	    VOLUME_UP,
	    VOLUME_DOWN,
	    PRESET_1,
	    PRESET_2,
	    PRESET_3,
	    PRESET_4,
	    PRESET_5,
	    PRESET_6,
	    AUX_INPUT,
	    SHUFFLE_OFF,
	    SHUFFLE_ON,
	    REPEAT_OFF,
	    REPEAT_ONE,
	    REPEAT_ALL,
	    PLAY_PAUSE,
	    ADD_FAVORITE,
	    REMOVE_FAVORITE,
	    INVALID_KEY
	    }

Example for -PostApiKey -ApiXml

BoseSoundTouch -SoundTouchIP "DNS_or_IP" -PostApiKey "bass" -ApiXml "/<bass/>$INT/</bass/>"

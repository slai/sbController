import sbcontroller.PlaylistItem;
/**
 * Represents the player state.
 * 
 * @author Samuel Lai
 */
class sbcontroller.PlayerState 
{
	//{ static constants
	public static var PLAYMODE_STOPPED:String = "stopped";
	public static var PLAYMODE_PAUSED:String = "paused";
	public static var PLAYMODE_PLAYING:String = "playing";
	
	public static var SHUFFLE_OFF:String = "off";
	public static var SHUFFLE_ALBUMS:String = "albums";
	public static var SHUFFLE_SONGS:String = "songs";
	
	public static var REPEAT_OFF:String = "off";
	public static var REPEAT_ONE:String = "one";
	public static var REPEAT_ALL:String = "all";
	
	public static var PLAYLIST_RADIUS:Number = 2;
	//}
	
	//{ instance variables - screw properties!
	public var playerId:String;
	public var poweredOn:Boolean;
	public var playMode:String;
	public var shuffleMode:String;
	public var repeatMode:String;
	public var volume:Number;
	public var bass:Number;
	public var treble:Number;
	public var playlist:Array;
	public var playlistLength:Number;
	public var playlistPosition:Number;
	public var secondsElapsed:Number;
	public var secondsTotal:Number;
	//}
	
	public function PlayerState() 
	{
		//initialise variables
		playerId = "";
		poweredOn = false;
		playMode = PLAYMODE_STOPPED;
		shuffleMode = SHUFFLE_OFF;
		repeatMode = REPEAT_OFF;
		volume = 0;
		bass = 0;
		treble = 0;
		playlist = [];
		playlistLength = 0;
		playlistPosition = -1;
		secondsElapsed = 0;
		secondsTotal = 0;
	}
	
	//properties
	public function get secondsPercent():Number
	{
		if (secondsTotal <= 0)
			return 0;
		else
			return secondsElapsed / secondsTotal * 100;
	}

	//methods
	public function getItemInPlaylistById(id:Number):PlaylistItem
	{
		for (var i in playlist)
		{
			if (playlist[i].id == id)
				return playlist[i];
		}
		
		//not found
		return null;
	}
	
	public function removeRedundantPlaylistItems():Void
	{
		var itemsToKeep:Array = [];
		var curPlaylistItem:PlaylistItem = null;
		
		while (playlist.length > 0)
		{
			curPlaylistItem = PlaylistItem(playlist.pop());
			
			//check if in range
			if (curPlaylistItem.position > playlistLength - 1 ||
				curPlaylistItem.position > playlistPosition + PLAYLIST_RADIUS ||
				curPlaylistItem.position < playlistPosition - PLAYLIST_RADIUS)
			{
				//out of range, delete
				delete curPlaylistItem;
			}
			else
			{
				//in range, keep
				itemsToKeep.push(curPlaylistItem);
			}
		}
		
		//add items to keep back to the playlist
		playlist = playlist.concat(itemsToKeep);
	}
	
	public function sortPlaylist():Void
	{
		playlist.sort(
			function (a:PlaylistItem, b:PlaylistItem):Number
			{
				return a.position - b.position;
			}
		);
	}
	
}
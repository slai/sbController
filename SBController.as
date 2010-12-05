/* 
Copyright (c) 2008 Chumby Industries

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
import com.chumby.util.Delegate;
import com.chumby.util.MCUtil;
import com.chumby.util.xml.XmlUtil;
import mx.data.encoders.Bool;
import sbcontroller.widgets.InactiveStateOverlay;
import sbcontroller.widgets.PlayerSelector;
import sbcontroller.PlayerInfo;
import sbcontroller.PlayerState;
import sbcontroller.PlaylistItem;
import sbcontroller.widgets.PlaylistStrip;
import sbcontroller.widgets.PlaylistStripItem;

class SBController extends MovieClip
{	
	//{ constants
	private var PLAYER_SELECTOR_DEPTH:Number = 1000;
	private var INACTIVE_OVERLAY_DEPTH:Number = 1000;
	private var MESSAGETEXT_DEPTH:Number = 100;
	private var PLAYLISTSTRIP_DEPTH:Number = 1;
	//}
	
	//{ instance variables
	private var _SCaddress:String = "";
	private var _SCcauth:String = "";
	private var _SCUpdateInterval:Number = 15000; //if too often, SC will just refuse to respond
	
	private var _playerInfo:PlayerInfo = null;
	private var _playerState:PlayerState = null;
	
	private var _playerSelector:PlayerSelector = null;
	private var _inactiveOverlay:InactiveStateOverlay = null;
	private var _messageText:TextField;
	private var _playlistStrip:PlaylistStrip;

	private var _xml:XML;
	//}
	
	//-------------------------------------------------------------------
	// MTASC starts with this entry point
	public static function main()
	{
		MCUtil.CreateWithClass(SBController, _root, "main", 1);
	}
	
	public function SBController()
	{	
		//create initial status textbox
		_messageText = this.createTextField("messageText", MESSAGETEXT_DEPTH, 5, 10, 300, 48);
		_messageText.multiline = true;
		_messageText.wordWrap = true;
		
		//get chumby widget variables
		_SCaddress = _root["sbcontroller_scaddress"];
		_SCcauth = _root["sbcontroller_sccauth"];

		if (_root["sbcontroller_scupdateinterval"] != undefined)
			_SCUpdateInterval = parseInt(_root["sbcontroller_scupdateinterval"]); //otherwise defaults to 15000 (above)
		
		//validate
		if (_SCaddress == undefined || _SCaddress == null || _SCaddress.length == 0) 
		{
			showError("Missing SqueezeCenter address.");
			return;
		}

		this.showStatus("Loading...", 0xffffff);
		
		getPlayers();
	}
	
	//{ gets the currently registered players
	private function getPlayers()
	{
		_xml = new XML();
		_xml.ignoreWhite = true;
		_xml.onLoad = Delegate.create(this, gotPlayers);
		
		var url:String = "http://" + _SCaddress + "/xml/status_header.xml";
		
		//add cache tricker to skirt around caching in flash and chumby
		url += "?cachetricker=" + getTimer();
		
		_xml.load(url);
		
		this.showStatus("Getting players...", 0xffffff);
	}
	
	private function gotPlayers(success:Boolean)
	{
		if (success == false)  
		{
			this.showStatus("Error when getting players.", 0xffffff);
			return;
		}
		
		//get players node
		var playersNode:XMLNode = XmlUtil.firstChildOfType(_xml.firstChild, "players");
		if (playersNode == null)
		{
			this.showStatus("Error when getting players - invalid XML.", 0xffffff);
			return;
		}
		
		//parse all players
		var playerNodes:Array = XmlUtil.childrenOfType(playersNode, "player");
		var playerInfoArray:Array = [];
		var curPlayerNode:XMLNode = null;
		var curPlayerId:String = null;
		var curPlayerName:String = null;
		for (var i in playerNodes)
		{
			curPlayerNode = playerNodes[i];
			
			//parse values
			curPlayerId = XmlUtil.firstValueOfType(curPlayerNode, "player_id");
			curPlayerName = XmlUtil.firstValueOfType(curPlayerNode, "player_name");
			
			//create object
			try
			{
				playerInfoArray.push(new PlayerInfo(curPlayerId, curPlayerName));
			}
			catch (e:Error)
			{
				trace("An error occurred when creating the player info object - " + e.message);
				//just continue to the next one
			}
		}
		
		if (playerInfoArray.length == 0)
		{
			//no players registered
			_playerInfo = null;
			this.showStatus("There are no players registered with SC.", 0xffffff);
		}
		else if (playerInfoArray.length == 1)
		{
			//only 1 player registered, this is the selected one
			_playerInfo = playerInfoArray[0];
			playerSelected(_playerInfo);
		}
		else
		{
			//ask user
			this.showStatus("There are " + playerInfoArray.length + " players registered with SC.", 0xffffff);
			
			_playerSelector = 
					MCUtil.CreateWithClass(
							PlayerSelector, this, "playerSelector", PLAYER_SELECTOR_DEPTH, { _x:_x, _y:_y }, [playerInfoArray]);
							
			//attach handlers
			_playerSelector.onPlayerSelected = Delegate.create(this, playerSelected);
		}
	}
	
	private function playerSelected(playerInfo:PlayerInfo):Void
	{
		_playerInfo = playerInfo;
		
		//remove player selector - not sure if this is necessary
		_playerSelector.removeMovieClip();
		_playerSelector = null;
		
		setInterval(this, "getPlayerState", _SCUpdateInterval);
		//kick things off
		getPlayerState();
	}
	//}
	
	//{ gets the current player state
	private function getPlayerState():Void
	{
		trace("getplayerstate: " + getTimer());
		
		_xml = new XML();
		_xml.ignoreWhite = true;
		_xml.onLoad = Delegate.create(this, gotPlayerState);
		
		var url:String = "http://" + _SCaddress + "/xml/status.xml?player=" + escape(_playerInfo.playerId) + 
				"&itemsPerPage=" + (PlayerState.PLAYLIST_RADIUS * 2 + 1);

		//add the offset if it is available to get the right items
		var urlStart:Number = 0;
		if (_playerState != null && _playerState.playlistPosition >= 0)
		{
			urlStart = _playerState.playlistPosition - PlayerState.PLAYLIST_RADIUS;
			if (urlStart < 0) urlStart = 0;
		}
		url += "&start=" + urlStart;
		
		//add cache tricker to skirt around caching in flash and chumby
		url += "&cachetricker=" + getTimer();
		trace(url);
			
		_xml.load(url);
		
		//only show message if it is the first go (otherwise it is just annoying)
		if (_playerState == null)
			this.showStatus("Getting " + _playerInfo.playerName + "'s player state...", 0xffffff);
	}
	
	private function gotPlayerState(success:Boolean)
	{
		if (success == false)  
		{
			showError("Error when getting player state.", 0xffffff);
			return;
		}
		
		//variables for storing current playlist offset
		var playlistStart:Number = 0;
		var playlistEnd:Number = 0;
		
		//create a player state object if one does not exist
		if (_playerState == null)
		{
			_playerState = new PlayerState();
			_playerState.playerId = _playerInfo.playerId;
		}
		
		//get player status node
		var playerStatusNode:XMLNode = XmlUtil.firstChildOfType(_xml.firstChild, "player_status");
		if (playerStatusNode == null)
		{
			showError("Error player status XML (player_status).", 0xffffff);
			return;
		}
		
		var curNode:XMLNode = null;
		var curValue:String = null;
		
		//get transport node (poweredOn, play mode)
		curNode = XmlUtil.firstChildOfType(playerStatusNode, "transport");
		if (curNode == null)
		{
			showError("Error player status XML (transport).", 0xffffff);
			return;
		}
		
		_playerState.poweredOn = XmlUtil.firstValueOfType(curNode, "mode") == "on";
		_playerState.playMode = XmlUtil.firstValueOfType(curNode, "playmode");
		
		//get shuffle node (shuffleMode)
		curNode = XmlUtil.firstChildOfType(playerStatusNode, "shuffle");
		if (curNode != null)
		{
			if (XmlUtil.firstChildOfType(curNode, "shuffle_off") != null)
				_playerState.shuffleMode = PlayerState.SHUFFLE_OFF;
			else if (XmlUtil.firstChildOfType(curNode, "shuffle_songs") != null)
				_playerState.shuffleMode = PlayerState.SHUFFLE_SONGS;
			else if (XmlUtil.firstChildOfType(curNode, "shuffle_albums") != null)
				_playerState.shuffleMode = PlayerState.SHUFFLE_ALBUMS;
			else
				trace("The shuffle mode value is unexpected.");
		}
		else
		{
			trace("The shuffle node does not exist.");
		}
		
		//get repeat node (repeatMode)
		curNode = XmlUtil.firstChildOfType(playerStatusNode, "repeat");
		if (curNode != null)
		{
			if (XmlUtil.firstChildOfType(curNode, "repeat_off") != null)
				_playerState.repeatMode = PlayerState.REPEAT_OFF;
			else if (XmlUtil.firstChildOfType(curNode, "repeat_one") != null)
				_playerState.repeatMode = PlayerState.REPEAT_ONE;
			else if (XmlUtil.firstChildOfType(curNode, "repeat_all") != null)
				_playerState.repeatMode = PlayerState.REPEAT_ALL;
			else
				trace("The repeat mode value is unexpected.");
		}
		else
		{
			trace("The repeat node does not exist.");
		}
		
		//get audio node (volume, bass, treble)
		curNode = XmlUtil.firstChildOfType(playerStatusNode, "audio");
		if (curNode != null)
		{
			curValue = XmlUtil.firstValueOfType(curNode, "volume");
			if (curValue != null)
				_playerState.volume = parseInt(curValue);
				
			curValue = XmlUtil.firstValueOfType(curNode, "bass");
			if (curValue != null)
				_playerState.bass = parseInt(curValue);
				
			curValue = XmlUtil.firstValueOfType(curNode, "treble");
			if (curValue != null)
				_playerState.treble = parseInt(curValue);
		}
		else
		{
			trace("The audio node does not exist.");
		}
		
		//get current_song node (playlistPosition, playlistLength, secondsElapsed, secondsTotal)
		curNode = XmlUtil.firstChildOfType(playerStatusNode, "current_song");
		if (curNode != null)
		{
			curValue = XmlUtil.firstValueOfType(curNode, "playlist_offset");
			if (curValue != null)
				_playerState.playlistPosition = parseInt(curValue);
			else 
				//set to -1 if none found - this property is very important, so it needs to be accurate
				_playerState.playlistPosition = -1;
				
			curValue = XmlUtil.firstValueOfType(curNode, "playlist_length");
			if (curValue != null)
				_playerState.playlistLength = parseInt(curValue);
				
			curValue = XmlUtil.firstValueOfType(curNode, "secondsElapsed");
			if (curValue != null)
				_playerState.secondsElapsed = parseInt(curValue);
				
			curValue = XmlUtil.firstValueOfType(curNode, "secondsTotal");
			if (curValue != null)
				_playerState.secondsTotal = parseInt(curValue);
		}
		else
		{
			//no song is play now
			_playerState.playlistPosition = -1;
			_playerState.playlistLength = 0;
			_playerState.secondsElapsed = 0;
			_playerState.secondsTotal = 0;
		}
		
		//parse playlist items
		var playlistNode:XMLNode = XmlUtil.firstChildOfType(_xml.firstChild, "playlist");
		var playlistItemNodes:Array = XmlUtil.childrenOfType(playlistNode, "status_entry");
		var curPlaylistItem:PlaylistItem = null;
		var curPlaylistPosition:Number = 0;
		
		//get playlist range
		curNode = XmlUtil.firstChildOfType(playlistNode, "offsets");
		if (curNode != null)
		{
			playlistStart = parseInt(XmlUtil.firstValueOfType(curNode, "from"));
			trace("raw xml play to: " + XmlUtil.firstValueOfType(curNode, "to"));
			playlistEnd = parseInt(XmlUtil.firstValueOfType(curNode, "to"));
		}
		else
		{
			//sometimes the offsets node isn't included, just assume
			playlistStart = 0;
			playlistEnd = playlistItemNodes.length - 1;
		}
		
		for (var i:Number = 0; i < playlistItemNodes.length; i++)
		{
			curNode = playlistItemNodes[i];
			
			//get position
			curPlaylistPosition = parseInt(XmlUtil.firstValueOfType(curNode, "offset"));
			
			//get song node for everything else
			curNode = XmlUtil.firstChildOfType(curNode, "song");
			if (curNode == null)
			{
				trace("No song node found for this playlist item.");
				continue;
			}
			
			//get song id
			curValue = XmlUtil.firstValueOfType(curNode, "song_id");
			//trace("processing item id: " + curValue + " position: " + curPlaylistPosition);
			//check if this already exists in the playlist
			curPlaylistItem = _playerState.getItemInPlaylistById(parseInt(curValue));
			if (curPlaylistItem != null)
			{
				//trace("existing item id: " + curPlaylistItem.id);
				//trace("existing item pos: " + curPlaylistItem.position);
				
				//reassign existing item to the playlist position
				curPlaylistItem.position = curPlaylistPosition;
			}
			else
			{
				//doesn't exist, create and fill
				curPlaylistItem = new PlaylistItem();
				
				curPlaylistItem.id = parseInt(curValue);
				curPlaylistItem.position = curPlaylistPosition;
				
				//title
				curValue = XmlUtil.firstValueOfType(curNode, "title");
				if (curValue != null)
					curPlaylistItem.title = curValue;
				else
				{
					trace("Playlist item " + curPlaylistPosition + " has no title.");
					continue;
				}
				
				//artist
				curValue = XmlUtil.firstValueOfType(curNode, "artist");
				if (curValue != null)
					curPlaylistItem.artist = curValue;
				
				//album
				curValue = XmlUtil.firstValueOfType(curNode, "album");
				if (curValue != null)
					curPlaylistItem.album = curValue;
					
				//genre
				curValue = XmlUtil.firstValueOfType(curNode, "genre");
				if (curValue != null)
					curPlaylistItem.genre = curValue;
				
				//track number
				curValue = XmlUtil.firstValueOfType(curNode, "track");
				if (curValue != null)
					curPlaylistItem.trackNumber = parseInt(curValue);
					
				//duration
				curValue = XmlUtil.firstValueOfType(curNode, "duration");
				if (curValue != null)
					curPlaylistItem.duration = curValue;
					
				//type
				curValue = XmlUtil.firstValueOfType(curNode, "type");
				if (curValue != null)
					curPlaylistItem.type = curValue;
				else
				{
					trace("Playlist item " + curPlaylistPosition + " has no type.");
					continue;
				}
				
				//cover art url
				curValue = XmlUtil.firstValueOfType(curNode, "coverart");
				if (curValue != null)
					curPlaylistItem.coverArtUrl = "http://" + _SCaddress + curValue; //cover art is missing the domain prefix
			
				//add to playlist
				_playerState.playlist.push(curPlaylistItem);
			}
			
			//check if this position is already being used by another item
			var curPlaylistItem2:PlaylistItem = null;
			for (var j:Number = 0; j < _playerState.playlist.length; j++)
			{
				curPlaylistItem2 = _playerState.playlist[j];
				if (curPlaylistItem2.position == curPlaylistPosition &&
					curPlaylistItem2.id != curPlaylistItem.id)
				{
					//found, delete it
					//trace("found existing pos, with id: " + curPlaylistItem2.id);
					//remove from array
					_playerState.playlist.splice(j, 1);
					//remove from memory
					delete curPlaylistItem2;
					
					break;
				}
			}
		}

		if (playlistItemNodes.length == 0)
			//clear the playlist
			_playerState.playlist = [];
		else
			//remove redundant items
			_playerState.removeRedundantPlaylistItems();
		
		//if the playlist is now empty yet the current playlist position positive, 
		//repeat (this will automatically set the start parameter)
		//if (_playerState.playlist.length == 0 && _playerState.playlistPosition >= 0)
		//check if current playlist position is within range, otherwise, repeat
		if (_playerState.playlistLength > 0 && 
		    (_playerState.playlistPosition < playlistStart || _playerState.playlistPosition > playlistEnd))
		{
			trace("play start: " + playlistStart);
			trace("play end: " + playlistEnd);
			
			trace("play items: " + _playerState.playlist.length);
			//for (var bbb:Number = 0; bbb < _playerState.playlist.length; bbb++)
			//{
			//	trace(_playerState.playlist[bbb].title + " | pos: " + _playerState.playlist[bbb].position); 
			//}
			
			getPlayerState();
			return;
		}
		
		_playerState.sortPlaylist();
		
		//create UI if needed
		if (_playlistStrip == null)
		{
			_playlistStrip = MCUtil.CreateWithClass(PlaylistStrip, this, "playlistStrip", PLAYLISTSTRIP_DEPTH);
			_playlistStrip.addEventListener(PlaylistStrip.STOPPED, Delegate.create(this, playlistStripMoved));
			_playlistStrip.addEventListener(PlaylistStrip.CLICKED, Delegate.create(this, playlistStripClicked));
		}
		
		//create copy of playlist items array
		var playlistItemsCopy:Array = [];
		for (var i:Number = 0; i < _playerState.playlist.length; i++)
			playlistItemsCopy.push(_playerState.playlist[i]);
		
		//update UI
		_playlistStrip.processItems(playlistItemsCopy);
		
		//find index of current song
		var curItemIndex:Number = 0;
		for (var i:Number = 0; i < _playerState.playlist.length; i++)
		{
			if (_playerState.playlist[i].position == _playerState.playlistPosition)
			{
				curItemIndex = i;
				break;
			}
		}
		_playlistStrip.setShowingIndex(curItemIndex);
		
		hideStatus();
		
		//activate the overlay if needed
		if (_playerState.poweredOn == false)
		{
			//powered off, show overlay
			activateInactiveOverlay("powered off", "use your remote to turn it on");
		}
		else if (_playerState.playlistLength == 0)
		{
			//empty playlist
			activateInactiveOverlay("playlist is empty", "access SqueezeCenter to add songs");
		}
		else if (_playerState.playMode == PlayerState.PLAYMODE_PAUSED)
		{
			//paused
			activateInactiveOverlay("paused", "tap the screen to play again");
		}
		else if (_playerState.playMode == PlayerState.PLAYMODE_STOPPED)
		{
			//stopped
			activateInactiveOverlay("stopped", "tap the screen to play again");
		}
		else
		{
			//should be playing
			removeInactiveOverlay();
		}
	}
	
	private function playlistStripMoved():Void
	{
		//check if the strip showing index has changed
		var posDiff:Number = _playlistStrip._items[_playlistStrip.getCurrentIndex()].item.position - _playerState.playlistPosition;
		
		//determine if going to previous or next track
		if (posDiff < 0)
		{
			//go to previous track
			activateInactiveOverlay("previous track", "sending command...");
			sbPrevious();
		}
		else if (posDiff > 0)
		{
			//go to next track
			activateInactiveOverlay("next track", "sending command...");
			sbNext();
		}
	}
	
	private function playlistStripClicked():Void
	{
		activateInactiveOverlay("pausing", "sending command...");
		sbPause();
	}
	//}
	
	//{ inactive overlay functions
	private function isInactiveOverlayShowing():Boolean
	{
		return _inactiveOverlay != null;
	}
	
	private function activateInactiveOverlay(messageTitle:String, message:String):Void
	{
		if (!isInactiveOverlayShowing())
		{
			//does not exist, create it
			_inactiveOverlay = 
					MCUtil.CreateWithClass(
							InactiveStateOverlay, this, "inactiveOverlay", INACTIVE_OVERLAY_DEPTH, { _x:_x, _y:_y });
							
			//attach handlers
			_inactiveOverlay.onClicked = Delegate.create(this, inactiveOverlayClicked);
		}
		
		//set messages
		_inactiveOverlay.messageTitle = messageTitle;
		_inactiveOverlay.message = message;
	}
	
	private function removeInactiveOverlay():Void
	{
		if (_inactiveOverlay != null)
		{
			_inactiveOverlay.removeOverlay();
			_inactiveOverlay.removeMovieClip();
			_inactiveOverlay = null;
		}
	}
	
	private function inactiveOverlayClicked():Void
	{
		//if paused, unpause
		if (_playerState.poweredOn)
		{
			if (_playerState.playMode == PlayerState.PLAYMODE_PAUSED)
			{
				//send unpause command
				sbUnpause();
				_inactiveOverlay.message = "sending command...";
			}
			else if (_playerState.playMode == PlayerState.PLAYMODE_STOPPED)
			{
				//send play command
				sbPlay();
				_inactiveOverlay.message = "sending command...";
			}
		}
		else
		{
			//powered off, no command to turn on so do nothing
		}
	}
	//}
	
	//{ status methods
	private function showStatus(str:String, textColor:Number):Void
	{
		_messageText.text = str;
		_messageText._visible = true;
		
		var messageTextFormat:TextFormat = new TextFormat();
		with (messageTextFormat)
		{
			color = textColor;
			size = 15;
			font = "Arial";
		}
		_messageText.setTextFormat(messageTextFormat);
	}
	
	private function hideStatus():Void
	{
		_messageText._visible = false;
	}
	
	private function showError(str:String):Void
	{
		this.showStatus(str, 0xffff00);
		
		//destroy stuff
		/*if (_playlistStrip != null)
		{
			_playlistStrip.unloadMovie();
			_playlistStrip.removeMovieClip();
		}*/
	}
	//}
	
	//{ squeezebox commands
	private function sbSendCommand(p0:String, p1:String, p2:String, p3:String, p4:String):Void
	{
		//base url
		var url:String = "http://" + _SCaddress + "/xml/status.xml?player=" + escape(_playerInfo.playerId) + "&omit_playlist=1";
		
		//this is a required parameter
		if (p0 == undefined || p0 == null)
			return;
		
		url += "&p0=" + escape(p0);
		
		//optional parameters
		if (p1 != undefined && p1 != null)
			url += "&p1=" + escape(p1);
		
		if (p2 != undefined && p2 != null)
			url += "&p2=" + escape(p2);
		
		if (p3 != undefined && p3 != null)
			url += "&p3=" + escape(p3);
		
		if (p4 != undefined && p4 != null)
			url += "&p4=" + escape(p4);
		
		//add cache tricker
		url += "&cachetricker=" + getTimer();
		
		//add cauth
		// cauth (CSRF protection) seems to be disabled by default on new installs
		if (_SCcauth != undefined && _SCcauth != null)
			url += "&;cauth=" + _SCcauth;
		
		//send command
		trace("sending command: " + url);
		loadVariables(url);
	}
	
	private function sbPause():Void
	{
		sbSendCommand("pause", "1");
	}
	
	private function sbUnpause():Void
	{
		sbSendCommand("pause", "0");
	}
	
	private function sbTogglePause():Void
	{
		sbSendCommand("pause");
	}
	
	private function sbPlay():Void
	{
		sbSendCommand("play");
	}
	
	private function sbPrevious():Void
	{
		//if at the start of the playlist
		if (_playerState.playlistPosition == 0)
			return;
			
		sbSendCommand("playlist", "jump", String(_playerState.playlistPosition - 1));
	}
	
	private function sbNext():Void
	{
		//if at the end of the playlist
		if (_playerState.playlistPosition == _playerState.playlistLength - 1)
			return;
			
		sbSendCommand("playlist", "jump", String(_playerState.playlistPosition + 1));
	}
	//}
}

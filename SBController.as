﻿/* 

sbController Widget for Chumby and Squeezebox Server 7.3 and up.
Samuel Lai, sam@edgylogic.com
https://github.com/slai/sbController/wiki/

This code has been derived from code with the following copyright message:

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
import sbcontroller.util.StringUtil;
import System.security;

class SBController extends MovieClip
{	
	//{ constants
	private var MC_WIDTH:Number = 800;
	private var MC_HEIGHT:Number = 600;
	
	private var PLAYER_SELECTOR_DEPTH:Number = 1000;
	private var INACTIVE_OVERLAY_DEPTH:Number = 1000;
	private var MESSAGETEXT_DEPTH:Number = 100;
	private var PLAYLISTSTRIP_DEPTH:Number = 1;
	private var TIMEBAR_HEIGHT:Number = 10;
	//}
	
	//{ instance variables
	private var _SCaddress:String = "";
	private var _SCcauth:String = "";
	private var _SCUpdateInterval:Number = 5000; //if too often, SBS will just refuse to respond
	
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
		_messageText = this.createTextField("messageText", MESSAGETEXT_DEPTH, 5, 10, 780, 200);
		_messageText.multiline = true;
		_messageText.wordWrap = true;
		
		//get chumby widget variables
		_SCaddress = _root["_private_sbcontroller_address"];
		_SCcauth = _root["_private_sbcontroller_cauth"];
		
		// this property is undefined when run locally, but set to an empty string when run from the chumby network
		if (_root["_private_sbcontroller_updateInterval"] != undefined && _root["_private_sbcontroller_updateInterval"] != "")
			_SCUpdateInterval = parseInt(_root["_private_sbcontroller_updateInterval"]); //otherwise defaults to 5000 (above)
		
		//validate
		if (_SCaddress == undefined || _SCaddress == null || _SCaddress.length == 0) 
		{
			showError("Missing Squeezebox Server address.\n\nYou can specify the address by configuring this widget at http://www.chumby.com.");
			return;
		}
		
		security.loadPolicyFile("http://" + _SCaddress + "/crossdomain.xml");
		this.showStatus("Loading...", 0xffffff);
		
		// this property is undefined when run locally, but set to an empty string when run from the chumby network
		if (_root["_private_sbcontroller_defaultId"] != undefined && _root["_private_sbcontroller_defaultId"] != "")
		{
			playerSelected(new PlayerInfo(_root["_private_sbcontroller_defaultId"], "Default"));
		}
		else
		{
			getPlayers();
		}
	}
	
	//{ gets the currently registered players
	private function getPlayers()
	{
		_xml = new XML();
		_xml.ignoreWhite = true;
		_xml.onLoad = Delegate.create(this, gotPlayers);
		// I'd like to catch the HTTPStatus, but Flash Lite doesn't support onHTTPStatus. Weird.
		
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
			removeInactiveOverlay();
			_xml = null;
			return;
		}
		
		if (_xml.status != 0)
		{
			this.showStatus("Error when getting players - XML error code " + _xml.status + ".", 0xffffff);
			removeInactiveOverlay();
			_xml = null;
			return;
		}
		
		//get players node
		var playersNode:XMLNode = XmlUtil.firstChildOfType(_xml.firstChild, "players");
		if (playersNode == null)
		{
			this.showStatus("Error when getting players - invalid XML.", 0xffffff);
			removeInactiveOverlay();
			_xml = null;
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
		
		_xml = null;
		
		if (playerInfoArray.length == 0)
		{
			//no players registered
			_playerInfo = null;
			this.showStatus("There are no players registered with your Squeezebox Server.", 0xffffff);
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
			this.showStatus("There are " + playerInfoArray.length + " players registered with your Squeezebox Server.", 0xffffff);
			
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
	private function getPlayerState(addParamsString:String):Void
	{
		trace("getplayerstate: " + getTimer());
		
		// proceed anyway if we have parameters; otherwise cmd won't be sent
		if (_xml != null && (addParamsString == undefined || addParamsString == null))
		{
			trace("A player state refresh is already in progress.");
			return;
		}
		
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
		
		// this must be the last addition to the URL because it may contain the cauth value, which must be at the end of the URL.
		if (addParamsString != undefined && addParamsString != null)
		{
			url += addParamsString;
		}
		
		trace(url);
			
		_xml.load(url);
		
		//only show message if it is the first go (otherwise it is just annoying)
		if (_playerState == null)
			this.showStatus("Getting " + _playerInfo.playerName + "'s player state...", 0xffffff);
	}
	
	private function gotPlayerState(success:Boolean)
	{
		// this can occur if there are concurrent player state refreshes
		if (_xml == null || !_xml.loaded)
		{
			return;
		}
		
		if (success == false)  
		{
			showError("Error when getting player state.", 0xffffff);
			removeInactiveOverlay();
			_xml = null;
			return;
		}
		
		if (_xml.status != 0)
		{
			// HACK: no other way to detect if HTML is returned unless with onData. This works because the error HTML is not XHTML and has un-paired tags.
			//       Ideally would like to check based on HTTP status (unavailable in Flash Lite) or check HTML content (XML object can't parse HTML).
			if (_xml.status == -10)
			{
				if (StringUtil.isNullOrEmpty(_SCcauth))
					activateInactiveOverlay("cauth not configured", "Visit http://goo.gl/amubj for instructions to fix this error.");
				else
					activateInactiveOverlay("cauth invalid", "Visit http://goo.gl/amubj for instructions to fix this error.");
				
				// don't null out _xml here because we don't want this message to go away (when player state timer expires)
				return;
			}
			else 
			{
				showError("Error when getting player state - XML error code " + _xml.status + ".", 0xffffff);
				removeInactiveOverlay();
				_xml = null;
				return;
			}
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
				
			curValue = XmlUtil.firstValueOfType(curNode, "seconds_elapsed");
			if (curValue != null)
				_playerState.secondsElapsed = parseInt(curValue);
				
			curValue = XmlUtil.firstValueOfType(curNode, "seconds_total");
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
			
			_xml = null;
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
		
		//get prev, current and next items
		var prevStripItem:PlaylistItem = null, curStripItem:PlaylistItem = null, nextStripItem:PlaylistItem = null;
		for (var i:Number = 0; i < _playerState.playlist.length; i++) 
		{
			curPlaylistItem = _playerState.playlist[i];
			if (curPlaylistItem.position == _playerState.playlistPosition)
			{
				curStripItem = curPlaylistItem;
				if (i != 0)
					prevStripItem = _playerState.playlist[i - 1];
				if (i + 1 < _playerState.playlist.length)
					nextStripItem = _playerState.playlist[i + 1];
				
				break;
			}
		}
		
		//update UI
		_playlistStrip.processItems(prevStripItem, curStripItem, nextStripItem);
		
		// draw the time bar
		// clear that area first
		moveTo(0, MC_HEIGHT);
		beginFill(0x000000, 100);
		lineTo(MC_WIDTH, MC_HEIGHT);
		lineTo(MC_WIDTH, MC_HEIGHT - TIMEBAR_HEIGHT);
		lineTo(0, MC_HEIGHT - TIMEBAR_HEIGHT);
		endFill();
		
		// now draw the time bar
		moveTo(0, MC_HEIGHT);
		beginFill(0xFFFF00, 100);
		lineTo(MC_WIDTH * (_playerState.secondsPercent / 100), MC_HEIGHT);
		lineTo(MC_WIDTH * (_playerState.secondsPercent / 100), MC_HEIGHT - TIMEBAR_HEIGHT);
		lineTo(0, MC_HEIGHT - TIMEBAR_HEIGHT);
		endFill();
		
		// clean up
		_xml = null;
		
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
			activateInactiveOverlay("playlist is empty", "use your Squeezebox to add songs");
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
		var posDiff:Number = _playlistStrip.getCurrentIndex();
		trace(_playlistStrip.getCurrentIndex());
		
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
		_messageText.embedFonts = true;
		_messageText.text = str;
		_messageText._visible = true;
		
		var messageTextFormat:TextFormat = new TextFormat();
		with (messageTextFormat)
		{
			color = textColor;
			size = 22;
			font = "main.ttf";
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
		var params = "";
		
		//this is a required parameter
		if (p0 == undefined || p0 == null)
			return;
		
		params += "&p0=" + escape(p0);
		
		//optional parameters
		if (p1 != undefined && p1 != null)
			params += "&p1=" + escape(p1);
		
		if (p2 != undefined && p2 != null)
			params += "&p2=" + escape(p2);
		
		if (p3 != undefined && p3 != null)
			params += "&p3=" + escape(p3);
		
		if (p4 != undefined && p4 != null)
			params += "&p4=" + escape(p4);
		
		//add cauth
		// cauth (CSRF protection) seems to be disabled by default on new installs
		// must be added at the end of the URL
		if (_SCcauth != undefined && _SCcauth != null)
			params += "&;cauth=" + _SCcauth;
			
		//send command
		trace("sending command: " + params);
		getPlayerState(params);
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

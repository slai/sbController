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
import com.gskinner.events.GDispatcher;
import sbcontroller.PlaylistItem;

class sbcontroller.widgets.PlaylistStripItem extends MovieClip
{
	//{ static constants
	public static var LOADING:Number = 1;
	public static var LOADED:Number = 2;
	public static var UNLOADED:Number = 3;
	public static var LOAD_ERR:Number = 4;
	
	private static var MAX_LOADING:Number = 4;
	//}
	
	//{ constants
	private var HITAREA_DEPTH:Number = 1;
	private var COVERART_DEPTH:Number = 5;
	private var ARTISTTEXT_DEPTH:Number = 10;
	private var ALBUMTEXT_DEPTH:Number = 11;
	private var TITLETEXT_DEPTH:Number = 12;
	private var DURATIONTEXT_DEPTH:Number = 13;
	private var STATUSTEXT_DEPTH:Number = 100;
	
	private var TEXT_WIDTH_LEEWAY:Number = 10;
	//}
	
	//{ static variables
	private static var NumLoading:Number = 0;
	//}
	
	//{ instance variables
	// passed in during attachMovie:
	private var _item:PlaylistItem;
	private var _maxWidth:Number;
	private var _maxHeight:Number;
	
	private var _loadState:Number;
	private var _keepLoaded:Boolean;
	private var _mcl:MovieClipLoader;
	
	private var _coverArt:MovieClip;
	private var _artistText:TextField;
	private var _albumText:TextField;
	private var _titleText:TextField;
	private var _durationText:TextField;
	private var _statusText:TextField;
	private var _curCoverArtUrl:String;
	
	private var _hitAreaMC:MovieClip;
	
	private var _errorCount:Number;
	
	private var Width:Number;
	private var Height:Number;
	
	private var UNLOAD_T:Number;
	private var LOAD_T1:Number;
	private var LOAD_T2:Number;
	
	private var _timerTest:Number;
	
	public var addEventListener:Function;
	public var removeEventListener:Function;
	private var dispatchEvent:Function;
	//}
	
	public function PlaylistStripItem()
	{
		_loadState = UNLOADED;
		_keepLoaded = false;		
		_errorCount = 0;
		
		_mcl = new MovieClipLoader();
		_mcl.addListener(this);
		GDispatcher.initialize(this);
		
		//set dimensions
		if(_maxWidth != undefined)
			setWidth(_maxWidth);
		else
			setWidth(320);
			
		if(_maxHeight != undefined)
			setHeight(_maxHeight);
		else
			setHeight(240);
		
		// HACK: load a black image to force movieclip to use 320x240 as hit area.
		//       can't work out how to do it properly using FD.
		attachMovie("black320x240.jpg", "hitAreaMC", HITAREA_DEPTH, null);
	}
	
	public function get item():PlaylistItem
	{
		return _item;
	}
	
	public function set item(value:PlaylistItem):Void
	{
		if (_item == null || value == null || _item.id != value.id)
		{
			_item = value;
			
			//trace("ITEM [" + _name + "]: " + _item.title);
			
			unloadUI();
			
			if (_item != null)
			{
				//generate and load UI
				generateUI();
				refreshUI();
				checkLoad();
			}
		}
	}
	
	private function generateUI():Void
	{
		//cover art loaded when needed
		
		var textFormat:TextFormat = null;
		
		_artistText = this.createTextField("artistText", ARTISTTEXT_DEPTH, 10, 50, 300, 30);
		_artistText.embedFonts = true;
		textFormat = new TextFormat();
		with (textFormat)
		{
			color = 0xffffff;
			size = 22;
			font = "main.ttf";
			bold = true;
		}
		_artistText.setNewTextFormat(textFormat);
		_artistText.background = true;
		_artistText.backgroundColor = 0x000000;

		_albumText = this.createTextField("albumText", ALBUMTEXT_DEPTH, 10, 80, 300, 30);
		_albumText.embedFonts = true;
		textFormat = new TextFormat();
		with (textFormat)
		{
			color = 0xffffff;
			size = 22;
			font = "main.ttf";
			bold = true;
		}
		_albumText.setNewTextFormat(textFormat);
		_albumText.background = true;
		_albumText.backgroundColor = 0x000000;
		
		_titleText = this.createTextField("titleText", TITLETEXT_DEPTH, 10, 110, 300, 36);
		_titleText.embedFonts = true;
		textFormat = new TextFormat();
		with (textFormat)
		{
			color = 0xffffff;
			size = 28;
			font = "main.ttf";
			bold = true;
		}
		_titleText.setNewTextFormat(textFormat);
		_titleText.background = true;
		_titleText.backgroundColor = 0x000000;
		_titleText.multiline = true;
		_titleText.wordWrap = true;
		
		
		_durationText = this.createTextField("durationText", DURATIONTEXT_DEPTH, 10, 150, 300, 30);
		_durationText.embedFonts = true;
		textFormat = new TextFormat();
		with (textFormat)
		{
			color = 0xffffff;
			size = 20;
			font = "main.ttf";
			bold = true;
		}
		_durationText.setNewTextFormat(textFormat);
		_durationText.background = true;
		_durationText.backgroundColor = 0x000000;
		
		_statusText = this.createTextField("statusText", STATUSTEXT_DEPTH, 5, 210, 310, 24);
	}
	
	private function refreshUI():Void
	{
		var maxTextWidth:Number = Width - TEXT_WIDTH_LEEWAY;
		
		_artistText.text = item.artist;
		_artistText._width = _artistText.textWidth + TEXT_WIDTH_LEEWAY > maxTextWidth ? maxTextWidth : _artistText.textWidth + TEXT_WIDTH_LEEWAY;
		
		_albumText.text = item.album;
		_albumText._width = _albumText.textWidth + TEXT_WIDTH_LEEWAY > maxTextWidth ? maxTextWidth : _albumText.textWidth + TEXT_WIDTH_LEEWAY;
		
		_titleText.text = item.title;
		_titleText._width = _titleText.textWidth + TEXT_WIDTH_LEEWAY > maxTextWidth ? maxTextWidth : _titleText.textWidth + TEXT_WIDTH_LEEWAY;
		//adjust for multi-line. 36 comes from the single line height set in generateUI.
		//cannot rely on textHeight, as it returns a height close but too small for all lines to show. weird.
		_titleText._height = Math.ceil(_titleText.textHeight / 36) * 36;
		//trace("title: " + item.title);
		//trace("title text width and height: " + _titleText.textWidth + " x " + _titleText.textHeight);
		
		//relocate duration so it is below any multi-line title
		_durationText._y = _titleText._y + _titleText._height;
		_durationText.text = item.duration;
		_durationText._width = _durationText.textWidth + TEXT_WIDTH_LEEWAY > maxTextWidth ? maxTextWidth : _durationText.textWidth + TEXT_WIDTH_LEEWAY;
	}
	
	private function unloadUI():Void
	{
		if (_artistText != null)
		{
			_artistText.removeTextField();
			_artistText = null;
		}
		
		if (_albumText != null)
		{
			_albumText.removeTextField();
			_albumText = null;
		}
		
		if (_titleText != null)
		{
			_titleText.removeTextField();
			_titleText = null;
		}
		
		if (_durationText != null)
		{
			_durationText.removeTextField();
			_durationText = null;
		}
			
		if (_statusText != null)
		{
			_statusText.removeTextField();
			_statusText = null;
		}
			
		if (_coverArt != null)
		{
			_mcl.unloadClip(_coverArt);
			_curCoverArtUrl = "";
			_coverArt = null;
		}
	}
	
	//-----------------------------------------------------------------------------------------------
	public static function numLoading():Number 
	{
		return NumLoading;
	}
	
	private function setHeight(h:Number) 
	{
		Height = h;
	}

	private function setWidth(w:Number) 
	{
		Width = w;
		UNLOAD_T = w * 3;
		LOAD_T1  = w * 2.5;
		LOAD_T2  = w * 1.5;
	}
	
	//-----------------------------------------------------------------------------------------------
	public function keepLoaded()
	{
		_keepLoaded = true;
	}
	
	//-----------------------------------------------------------------------------------------------
	// this function is called from the parent movieclip as it moves.
	// the strategy here is to load photos when they're near the display, and unload them otherwise.
	// the "unload" range is larger for hysteresis to discourage thrashing.  We also try to
	// load the images when the images are "stopped", unless they're too close.
	public function checkLoad() 
	{
		if (_curCoverArtUrl != item.coverArtUrl)
		{
			_mcl.unloadClip(_coverArt);
			
			if (item.coverArtUrl != null)
			{
				_coverArt = createEmptyMovieClip('coverArt', COVERART_DEPTH);
				this._timerTest = getTimer();
				_mcl.loadClip(item.coverArtUrl, _coverArt);
				NumLoading++;
				_loadState = LOADING;
				dispatchEvent({type:LOADING});
				showLoadingMessage();
				_curCoverArtUrl = item.coverArtUrl;
			}
		}
	}

	private function showStatus(str:String, textColor:Number):Void
	{
		_statusText.text = str;
		_statusText._visible = true;
		
		var statusTextFormat:TextFormat = new TextFormat();
		with (statusTextFormat)
		{
			color = textColor;
			align = "center"
			size = 12;
			font = "Arial";
		}
		_statusText.setTextFormat(statusTextFormat);
	}
	
	private function showLoadingMessage()
	{
		showStatus("Loading Image...", 0x777777);
	}

	private function hideStatus()
	{
		_statusText._visible = false;
	}
	
	private function showErrorMessage()
	{
		showStatus("Error.", 0x999999);
	}
	
	//-----------------------------------------------------------------------------------------------
	// basic resizing/centering code after the image has been loaded
	private function onLoadInit(target:MovieClip) 
	{
		if(target._width == 0) 
		{
			onLoadError(target);
			return;
		}
		
		var n:Number = (getTimer() - this._timerTest);
		NumLoading--;
		_loadState = LOADED;
		dispatchEvent({type:LOADED, name:this._name});
		hideStatus();
		var scaleX:Number = Math.min(1, Width/_coverArt._width);
		var scaleY:Number = Math.min(1, Height/_coverArt._height);
		var scale:Number = Math.min(scaleX,scaleY);
		if(scale != 1) 
		{
			_coverArt._width  = scale * _coverArt._width;
			_coverArt._height = scale * _coverArt._height;
		}
		_coverArt._x = (Width-_coverArt._width)/2;
		_coverArt._y = (Height-_coverArt._height)/2;
	}
	
	//-----------------------------------------------------------------------------------------------
	// on chumby onLoadError doesn't get called directly, but we call it from onLoadInit if _width is 0
	private function onLoadError(target:MovieClip)
	{
		trace("* onLoadError Aborting Load *");
		_errorCount++;
		if (_errorCount > 2)
		{
			_loadState = LOADED;
			keepLoaded();
			hideStatus();
			showErrorMessage();
		}
		else
		{
			_loadState = UNLOADED;
			hideStatus();
		}
		NumLoading--;
		dispatchEvent({type:LOAD_ERR});
	}
}

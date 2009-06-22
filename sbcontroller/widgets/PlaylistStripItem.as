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
	private var COVERART_DEPTH:Number = 1;
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
	public var item:PlaylistItem;
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
			
		//generate and load UI
		generateUI();
		refreshUI();
	}
	
	private function generateUI():Void
	{
		//cover art loaded when needed
		
		var textFormat:TextFormat = null;
		
		_artistText = this.createTextField("artistText", ARTISTTEXT_DEPTH, 10, 50, 300, 24);
		textFormat = new TextFormat();
		with (textFormat)
		{
			color = 0xffffff;
			size = 15;
			font = "Arial";
			bold = true;
		}
		_artistText.setNewTextFormat(textFormat);
		_artistText.background = true;
		_artistText.backgroundColor = 0x000000;

		_albumText = this.createTextField("albumText", ALBUMTEXT_DEPTH, 10, 70, 300, 24);
		textFormat = new TextFormat();
		with (textFormat)
		{
			color = 0xffffff;
			size = 15;
			font = "Arial";
			bold = true;
		}
		_albumText.setNewTextFormat(textFormat);
		_albumText.background = true;
		_albumText.backgroundColor = 0x000000;
		
		_titleText = this.createTextField("titleText", TITLETEXT_DEPTH, 10, 90, 300, 28);
		textFormat = new TextFormat();
		with (textFormat)
		{
			color = 0xffffff;
			size = 20;
			font = "Arial";
			bold = true;
		}
		_titleText.setNewTextFormat(textFormat);
		_titleText.background = true;
		_titleText.backgroundColor = 0x000000;
		_titleText.multiline = true;
		_titleText.wordWrap = true;
		
		
		_durationText = this.createTextField("durationText", DURATIONTEXT_DEPTH, 10, 120, 300, 20);
		textFormat = new TextFormat();
		with (textFormat)
		{
			color = 0xffffff;
			size = 12;
			font = "Arial";
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
		//adjust for multi-line. 28 comes from the single line height set in generateUI.
		//cannot rely on textHeight, as it returns a height close but too small for all line to show. weird.
		_titleText._height = Math.ceil(_titleText.textHeight / 28) * 28;
		//trace("title: " + item.title);
		//trace("title text width and height: " + _titleText.textWidth + " x " + _titleText.textHeight);
		
		//relocate duration so it is below any multi-line title
		_durationText._y = _titleText._y + _titleText._height;
		_durationText.text = item.duration;
		_durationText._width = _durationText.textWidth + TEXT_WIDTH_LEEWAY > maxTextWidth ? maxTextWidth : _durationText.textWidth + TEXT_WIDTH_LEEWAY;
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
		var offset:Number = this._x + this._parent._x;// + Width/2;
		if (_loadState == LOADED && _keepLoaded == false)
		{
			if (offset < -UNLOAD_T || offset > UNLOAD_T)
			{
				//trace('unloading '+this+' (offset '+offset+')');
				_mcl.unloadClip(_coverArt);
				_loadState = UNLOADED;
				dispatchEvent({type:UNLOADED});
			}
		} 
		else if ((_loadState == UNLOADED) && (NumLoading < MAX_LOADING) && (_errorCount < 3))
		{
			if ((_parent._isStopped && offset > -LOAD_T1 && offset < LOAD_T1) || (offset > -LOAD_T2 && offset < LOAD_T2)) 
			{
				if (item.coverArtUrl != null)
				{
					_coverArt = createEmptyMovieClip('coverArt', COVERART_DEPTH);
					this._timerTest = getTimer();
					_mcl.loadClip(item.coverArtUrl, _coverArt);
					NumLoading++;
					_loadState = LOADING;
					dispatchEvent({type:LOADING});
					showLoadingMessage();
				}
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

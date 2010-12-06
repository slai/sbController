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
import com.chumby.util.Delegate;
import com.chumby.util.MCUtil;
import sbcontroller.PlaylistItem;
import sbcontroller.widgets.PlaylistStripItem;

class sbcontroller.widgets.PlaylistStrip extends MovieClip
{
	private static var InitialDelayTime:Number = 4000; // ms
	private static var DelayTime:Number = 4000; // ms
	private static var AlignTime:Number = 500; // ms
	private static var AdvanceTime:Number = 1000; // ms
	
	private var _xspacing:Number;
	private var _itemWidth:Number;
	private var _itemHeight:Number;
	
	public  var _isStopped:Boolean; // used to tell images when it's safe to load
	private var _delay:Number;
	private var _startTime:Number;
	private var _startX:Number;
	private var _startXMouse:Number;
	private var _deltaX:Number;
	private var _velocity:Number;
	private var _duration:Number;
	private var _autoAdvance:Boolean;
	private var _moveStartTime:Number;
	
	private var _stripItemsAdded:Boolean;
	private var _prevStripItem:PlaylistStripItem;
	private var _curStripItem:PlaylistStripItem;
	private var _nextStripItem:PlaylistStripItem;
	private var _curShowingIndex:Number;
	
	public static var LOADEDFIRST:Number = 1;
	public static var MOVING:Number = 2;
	public static var STOPPED:Number = 3;
	public static var LOADED:Number = 4;
	public static var CLICKED:Number = 5;
	
	public var addEventListener:Function;
	public var removeEventListener:Function;
	private var dispatchEvent:Function;
	private var _delegateFirstItemReady:Function;
	private var _delegateItemLoaded:Function;
	
	public var onClicked:Function;
	
	//-----------------------------------------------------------------------------------------------
	function PlaylistStrip()
	{
		_isStopped = true;
		_autoAdvance = false;
		_xspacing = 320;
		_itemWidth = 320;
		_itemHeight = 240;
		_stripItemsAdded = false;
		GDispatcher.initialize(this);
		_delegateFirstItemReady = Delegate.create(this, firstItemReady);
		_delegateItemLoaded = Delegate.create(this, itemLoaded);
		_curShowingIndex = 0;
		
		onClicked = null;
	}

	//-----------------------------------------------------------------------------------------------
	// -1 for prev, 0 for cur, 1 for next.
	public function getCurrentIndex()
	{
		return _curShowingIndex;
	}
	
	public function setItemSpacing(w:Number)
	{
		_xspacing = w;
	}
	
	public function setItemSize(w:Number, h:Number)
	{
		_itemWidth = w;
		_itemHeight = h;
	}
		
	//-----------------------------------------------------------------------------------------------
	// attach the movie clips for each item, space them out, then start the autoadvancer
	public function processItems(prevItem:PlaylistItem, curItem:PlaylistItem, nextItem:PlaylistItem) 
	{
		if (!_stripItemsAdded)
		{
			//paint background black so entire movieclip acts as a hotspot
			moveTo(0, 0);
			beginFill(0x000000, 1);
			lineTo(0, _itemWidth);
			lineTo(_itemWidth, _itemHeight);
			lineTo(0, _itemHeight);
			lineTo(0, 0);
			endFill();
			
			this.onPress = mover;	// when initially touched, switch to the manual mover
			this.onRelease = this.onReleaseOutside = aligner;	// when touch released, switch to the aligner	
			this.onEnterFrame = advancer;
			
			_x = -_xspacing;
			
			// create strip items
			var x:Number = 0;
			var mc_name:String = null;
			var uiItem:MovieClip = null;
			
			// prev item
			mc_name = "item_prev";
			_prevStripItem = MCUtil.CreateWithClass(
								PlaylistStripItem, this, mc_name, this.getNextHighestDepth() + 1, 
								{ _x:x, _maxWidth:_itemWidth, _maxHeight:_itemHeight } );
			
			trace("adding: " + _prevStripItem._name);
				
			_prevStripItem.addEventListener(PlaylistStripItem.LOADED, _delegateItemLoaded);
			_prevStripItem.keepLoaded();
			
			// cur item
			x += _xspacing;
			mc_name = "item_cur";
			_curStripItem = MCUtil.CreateWithClass(
								PlaylistStripItem, this, mc_name, this.getNextHighestDepth() + 1, 
								{ _x:x, _maxWidth:_itemWidth, _maxHeight:_itemHeight } );
			
			trace("adding: " + _curStripItem._name);
				
			_curStripItem.addEventListener(PlaylistStripItem.LOADED, _delegateItemLoaded);
			_curStripItem.keepLoaded();
			
			// next item
			x += _xspacing;
			mc_name = "item_next";
			_nextStripItem = MCUtil.CreateWithClass(
								PlaylistStripItem, this, mc_name, this.getNextHighestDepth() + 1, 
								{ _x:x, _maxWidth:_itemWidth, _maxHeight:_itemHeight } );
			
			trace("adding: " + _nextStripItem._name);
				
			_nextStripItem.addEventListener(PlaylistStripItem.LOADED, _delegateItemLoaded);
			_nextStripItem.keepLoaded();
			
			_delay = InitialDelayTime;
			_startTime = getTimer();
			_stripItemsAdded = true;
		}
		
		// assign playlist items to strip items
		_prevStripItem.item = prevItem;
		_curStripItem.item = curItem;
		_nextStripItem.item = nextItem;
		checkItemsLoad();
		
		// realign so the current item is showing, but only if we aren't moving
		if (_isStopped)
		{
			_x = -_xspacing;
			_curShowingIndex = 0;
		}
	}

	//-----------------------------------------------------------------------------------------------
	public function removeAll()
	{
		trace(this._name + " removing all items");

		_prevStripItem.removeEventListener(PlaylistStripItem.LOADED, _delegateFirstItemReady);
		_prevStripItem.removeEventListener(PlaylistStripItem.LOADED, _delegateItemLoaded);
		_prevStripItem.removeMovieClip();
		
		_curStripItem.removeEventListener(PlaylistStripItem.LOADED, _delegateFirstItemReady);
		_curStripItem.removeEventListener(PlaylistStripItem.LOADED, _delegateItemLoaded);
		_curStripItem.removeMovieClip();
		
		_nextStripItem.removeEventListener(PlaylistStripItem.LOADED, _delegateFirstItemReady);
		_nextStripItem.removeEventListener(PlaylistStripItem.LOADED, _delegateItemLoaded);
		_nextStripItem.removeMovieClip();
	}
	
	//-----------------------------------------------------------------------------------------------	
	private function itemLoaded(obj:Object) 
	{
		dispatchEvent({type:LOADED, name:obj.name});
	}

	//-----------------------------------------------------------------------------------------------
	function firstItemReady(event:Object)
	{
		//trace("firstItemReady " + event.target);
		dispatchEvent({type:LOADEDFIRST});
	}
	
	//-----------------------------------------------------------------------------------------------
	// t=time, b=start, c=delta, d=duration
	private function easeOutQuad(t, b, c, d) 
	{
		return -c *(t/=d)*(t-2) + b;
	}

	//-----------------------------------------------------------------------------------------------
	private function easeInOutQuad(t, b, c, d) 
	{
		if ((t/=d/2) < 1) 
			return c/2*t*t + b;
		else
			return -c/2 * ((--t)*(t-2) - 1) + b;
	}

	//-----------------------------------------------------------------------------------------------
	// initialize the manual mover, keeping track of the initial press
	private function mover() 
	{
		//trace('mover');
		_startX = _x;
		_startXMouse = this._parent._xmouse;
		this.onEnterFrame = move;
		_isStopped = false;
		_moveStartTime = getTimer();
		move();
	}

	//-----------------------------------------------------------------------------------------------
	// move the images to track the user's pointer
	private function move() 
	{
		//trace('move');
		var nowXMouse = this._parent._xmouse;
		var x:Number = _startX+(nowXMouse-_startXMouse);
		//x = Math.max(Math.min(x,0),_xspacing-(_lastItem._x+_lastItem._width));
		if (x!=_x) {
			dispatchEvent({type:MOVING});
			_velocity = x-_x;// record the velocity
			_x = x;
		}
	}

	//-----------------------------------------------------------------------------------------------
	private function checkItemsLoad()
	{
		_prevStripItem.checkLoad();
		_curStripItem.checkLoad();
		_nextStripItem.checkLoad();
	}
	
	//-----------------------------------------------------------------------------------------------
	// align the images to the nearest image boundary, taking into account how fast the
	// user was moving the images when the mouse was released
	private function aligner() 
	{
		//trace('aligner');
		var x:Number = _x;
		// -1 so -1 == prev strip item
		var itemIndex:Number = int(-x/_xspacing+0.5) - 1; // figure out closest image to which to align
		var remaining = itemIndex * _xspacing + x;
		
		// don't advance if there is no item to show
		if (itemIndex < 0 && _prevStripItem.item == null)
			itemIndex = 0;
		if (itemIndex > 0 && _nextStripItem.item == null)
			itemIndex = 0;
		
		_startTime = getTimer();
		_duration = AlignTime;
		_startX = x;
		_deltaX = -(itemIndex+1)*_xspacing-_startX;
		this.onEnterFrame = align;
		align();
		
		//call onClicked if moved within 10 pixels and within 250ms
		trace("delta x: " + _deltaX + " duration: " + (getTimer() - _moveStartTime));
		if (_deltaX < 25 && _deltaX > -25 && (getTimer() - _moveStartTime) < 250)
		{
			trace("strip clicked");
			dispatchEvent( { type:CLICKED } );
		}
	}

	//-----------------------------------------------------------------------------------------------
	private function align() 
	{
		var t = getTimer() - _startTime;
		
		if (t<=_duration) 
		{
			var x = easeOutQuad(t,_startX,_deltaX,_duration);
			if (x!=_x) {
				_x = x;
			}
		} 
		else 
		{
			_x = _startX+_deltaX; // done with this advance, force alignment

			_delay = DelayTime;
			_startTime = getTimer();
			_isStopped = true;
			
			// -1 so it fits with -1 as prev
			var itemIndex:Number = Math.round(-_x/_xspacing) - 1;
			
			trace("align DeltaX: " + _deltaX + ", itemIndex: " + itemIndex);
			
			// drag from right to left
			if (_deltaX < 0 && _curShowingIndex != itemIndex)
				_curShowingIndex = 1;
			
			// drag from left to right
			if (_deltaX > 0 && _curShowingIndex != itemIndex)
				_curShowingIndex = -1;
			
			dispatchEvent({type:STOPPED});
			this.onEnterFrame = advancer;
		}
	}

	//-----------------------------------------------------------------------------------------------
	// advance to the next image after the specified delay
	private function advancer() 
	{
		//trace('advancer '+_delay);
		if (_autoAdvance == true && getTimer() > _startTime+_delay) 
		{
			var x:Number = _x;
			// -1 so -1 == prev item
			var itemIndex:Number = Math.round( -x / _xspacing) - 1; // current image
			
			trace("ADVANCER: index [" + itemIndex + "], prev item is null [" + _prevStripItem.item == null + "], next item is null [" + _nextStripItem.item == null + "]");
			if (// don't advance if the prev or next item is null
				(itemIndex < 0 && _prevStripItem.item != null) ||
				(itemIndex > 0 && _nextStripItem.item != null)
			   )
			{ 
				_startTime = getTimer(); // set up advance
				_duration = AdvanceTime;
				_startX = _x;
				_deltaX = -_xspacing;
				this.onEnterFrame = advance;
				dispatchEvent({type:MOVING});
				_isStopped = false;
				advance();
			} 
			else 
			{
				delete this.onEnterFrame; // no more images
			}
		}
	}

	//-----------------------------------------------------------------------------------------------
	private function advance() 
	{
		//trace('advance '+t);
		var t = getTimer() - _startTime;
		if (t <= _duration) 
		{
			var x = easeInOutQuad(t,_startX,_deltaX,_duration);
			if (x!=_x) {
				_x = x;
			}
		} 
		else 
		{			
			var itemIndex:Number = Math.round(-_x/_xspacing);
			//trace("advance index = " + itemIndex);
			_x = _startX + _deltaX; // doen with this advance, force alignment
			
			_delay = DelayTime; // set up next advance
			_startTime = getTimer();
			_isStopped = true;
			this.onEnterFrame = advancer;
			dispatchEvent({type:STOPPED});
		}
	}
}
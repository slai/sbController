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
	private var _itemCount:Number;
	private var _delay:Number;
	private var _startTime:Number;
	private var _startX:Number;
	private var _startXMouse:Number;
	private var _deltaX:Number;
	private var _velocity:Number;
	private var _lastItem:MovieClip;
	private var _duration:Number;
	private var _continuous:Boolean;
	private var _autoAdvance:Boolean;
	private var _itemSymbol:String;
	public var _items:Array;
	private var _lastCheckLoadPos:Number;
	private var _moveStartTime:Number;
	
	public static var LOADEDFIRST:Number = 1;
	public static var MOVING:Number = 2;
	public static var STOPPED:Number = 3;
	public static var LOADED:Number = 4;
	public static var CLICKED:Number = 5;
	
	public var addEventListener:Function;
	public var removeEventListener:Function;
	private var dispatchEvent:Function;
	private var _numLoading:Number = 0;
	private var _numLoaded:Number = 0;
	private var _delegateFirstItemReady:Function;
	private var _delegateItemLoaded:Function;
	
	public var onClicked:Function;
	
	//-----------------------------------------------------------------------------------------------
	function PlaylistStrip()
	{
		_isStopped = true;
		_continuous = false;
		_autoAdvance = false;
		_xspacing = 320;
		_itemWidth = 320;
		_itemHeight = 240;
		_items = [];
		GDispatcher.initialize(this);
		_delegateFirstItemReady = Delegate.create(this, firstItemReady);
		_delegateItemLoaded = Delegate.create(this, itemLoaded);
		
		onClicked = null;
	}

	//-----------------------------------------------------------------------------------------------
	public function setAutoAdvance(isAuto:Boolean)
	{
		_autoAdvance = isAuto;
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
	public function processItems(items:Array, showingIndex:Number) 
	{
		if (showingIndex == undefined) 
			showingIndex = 0;
		
		if(items.length > 1)
		{
			this.onPress = mover;	// when initially touched, switch to the manual mover
			this.onRelease = this.onReleaseOutside = aligner;	// when touch released, switch to the aligner	
			this.onEnterFrame = advancer;
			
			// ** continuous/circular mode
			if (_continuous)
			{
				var first:String = items[0];
				var last:String = items[items.length - 1];
				items.unshift(last);
				items.push(first);
			}
			
			//_x = -_xspacing;  
			_x = -_xspacing * (showingIndex + 1);
		}
		
		_itemCount = items.length;  // count including duplicate first and last items if continuous
		//_items = new Array();
		//trace("_itemCount : " + _itemCount);
		
		var x:Number = 0;
		for (var i=0; i<_itemCount; i++) 
		{
			var mc_name:String = "item_" + items[i].id;
			trace("processing for mc item name: " + mc_name);
			//see if it exists already
			var uiItem:MovieClip = null;
			for (var j = 0; j < _items.length; j++)
			{
				if (_items[j]._name == mc_name)
				{
					uiItem = _items[j];
					break;
				}
			}
			
			if (uiItem != null)
			{
				//item exists
				trace("item exists in slot " + i);
				//put this in the expected place
				_items[i] = uiItem;
				//and set correct depth
				uiItem.swapDepths(_items[i]);
				
				//set location
				uiItem._x = x;
			}
			else
			{
				//create it
				trace("item doesn't exist, creating...");
				uiItem = 
						MCUtil.CreateWithClass(
								PlaylistStripItem, this, mc_name, this.getNextHighestDepth() + 1, 
								{ _x:x, item:items[i], _maxWidth:_itemWidth, _maxHeight:_itemHeight } );
				
				//replace or add, so position in array is right
				if (_items.length > i)
				{
					//replace
					trace("new item replacing item at " + i);
					//push to the end of array so it can be removed later if necessary
					_items.push(_items[i]);
					_items[i] = uiItem;
					trace("replaced - " + _items[i]._name);
				}
				else
				{
					//add
					trace("adding: " + uiItem._name);
					_items.push(uiItem);
				}
				
				uiItem.addEventListener(PlaylistStripItem.LOADED, _delegateItemLoaded);
				if (_itemCount == 1) { // first image when only 1 image in array
					uiItem.addEventListener(PlaylistStripItem.LOADED, _delegateFirstItemReady);
				}
				else if(i == 1) {  // first visible image
					uiItem.addEventListener(PlaylistStripItem.LOADED, _delegateFirstItemReady);
				}
				if(i==1 || i==_itemCount-2) {
					uiItem.keepLoaded();
				}
			}
			
			x += _xspacing;
			_lastItem = this[mc_name];
		}
		
		//remove redundant mc items
		for (var i:Number = items.length; i < _items.length; i++)
		{
			trace("removing redundant item at " + i + " with id " + _items[i].item.id);
			
			var curMCItem:MovieClip = _items[i];
			
			//check to see if it exists elsewhere in the array
			var foundElsewhere:Boolean = false;
			for (var j:Number = 0; j < i; j++)
			{
				if (_items[j] == curMCItem)
				{
					foundElsewhere = true;
					break;
				}
			}
			trace("found elsewhere: " + foundElsewhere);
			if (!foundElsewhere)
			{
				trace("not found elsewhere, removing...");
				//not found elsewhere, unload and remove
				_items[i].unloadMovie();
				_items[i].removeMovieClip();
				delete curMCItem;
			}
			
			//delete from array
			_items.splice(i, 1);
		}
		
		checkItemLoad();
		_delay = InitialDelayTime;
		_startTime = getTimer();
		
		trace("items");
		for (var aaa:Number = 0; aaa < items.length; aaa++)
			trace(items[aaa].id + " pos: " + items[aaa].position);
		
		trace("mc items");
		for (var aaa:Number = 0; aaa < _items.length; aaa++)
			trace(aaa + " : " + _items[aaa]._name + " at depth " + _items[aaa].getDepth());
	}

	//-----------------------------------------------------------------------------------------------
	public function removeAll()
	{
		trace(this._name + " removing " + _itemCount + " items");
		for (var i=0; i<_itemCount; i++) 
		{
			var mc_name:String = "item_"+i;
			var item:MovieClip = this[mc_name];
			item.removeEventListener(PlaylistStripItem.LOADED, _delegateFirstItemReady);
			item.removeEventListener(PlaylistStripItem.LOADED, _delegateItemLoaded);
			item.removeMovieClip();
		}
		_items = new Array();
		_itemCount = 0;
	}
	
	//-----------------------------------------------------------------------------------------------	
	private function itemLoaded(obj:Object) 
	{
		var i:Number = Number(obj.name.split('_')[1]);
		var index:Number = (i==0) ? (_itemCount - 1) : (i-1);
		//trace("itemLoaded " + i);
		dispatchEvent({type:LOADED, index:i});
	}

	//-----------------------------------------------------------------------------------------------
	public function setShowingIndex(index:Number)
	{
		//trace("setShowingIndex " + index);
		_x = -_xspacing * (index); //removed + 1 on index in original code (don't know why it was there)
		_startTime = getTimer();
		checkItemLoad();
		if(this._autoAdvance)
			this.onEnterFrame = advancer;
		else
			delete this.onEnterFrame;
	}
	
	//-----------------------------------------------------------------------------------------------
	public function getCurrentIndex():Number
	{
		var itemIndex:Number = Math.round( -_x / _xspacing); // current item
		return _continuous ? itemIndex - 1 : itemIndex;   // subtract the duplicated item if continuous mode
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
		x = Math.max(Math.min(x,0),_xspacing-(_lastItem._x+_lastItem._width));
		if (x!=_x) {
			dispatchEvent({type:MOVING});
			_velocity = x-_x;// record the velocity
			_x = x;
			if(Math.abs(nowXMouse-_lastCheckLoadPos) > _xspacing) {
				checkItemLoad();
			}
		}
	}

	//-----------------------------------------------------------------------------------------------
	private function checkItemLoad()
	{
		_lastCheckLoadPos = this._parent._xmouse;
		var curr:Number = Math.round(-_x/_xspacing); // current item index
		//trace("checkItemLoad " + curr);
		var delta:Number = Math.min(15, Math.floor(_items.length / 2));
		_items[curr].checkLoad();
		for(var d:Number = 1; d <= delta; d++) 
		{
			var pos1:Number = (curr + d) % _items.length;
			var pos2:Number = (curr + _items.length - d) % _items.length;
			//trace("checkLoad: " + pos1 + " , " + pos2);
			_items[pos1].checkLoad();
			_items[pos2].checkLoad();
		}
	}
	
	//-----------------------------------------------------------------------------------------------
	// align the images to the nearest image boundary, taking into account how fast the
	// user was moving the images when the mouse was released
	private function aligner() 
	{
		//trace('aligner');
		var x:Number = _x;
		var itemIndex:Number = int(-x/_xspacing+0.5); // figure out closest image to which to align
		var remaining = itemIndex*_xspacing+x;
		if (_velocity>10 && remaining>0) {
			itemIndex--;
		} else if (_velocity<-10 && remaining<0) {
			itemIndex++;
		}
		itemIndex = Math.max(0,Math.min(itemIndex,_itemCount-1));
		_velocity = 0;
		_startTime = getTimer();
		_duration = AlignTime;
		_startX = x;
		_deltaX = -itemIndex*_xspacing-_startX;
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
		//trace('align '+t);
		if (t<=_duration) 
		{
			var x = easeOutQuad(t,_startX,_deltaX,_duration);
			if (x!=_x) {
				_x = x;
			}
		} 
		else 
		{
			var itemIndex:Number = Math.round(-_x/_xspacing);
			//trace("align index = " + itemIndex);
			if(_continuous && itemIndex == _itemCount-1) {
				//trace("wrap");
				_x = -_xspacing;
			}
			else if(_continuous && itemIndex == 0) {
				//trace("wrap");
				_x = -(_itemCount-2) * _xspacing;
			}
			else {
				_x = _startX+_deltaX; // done with this advance, force alignment
			}
			_delay = DelayTime;
			_startTime = getTimer();
			_isStopped = true;
			checkItemLoad();
			dispatchEvent({type:STOPPED});
			this.onEnterFrame = advancer;
		}
	}

	//-----------------------------------------------------------------------------------------------
	// advance to the next image after the specified delay
	private function advancer() 
	{
		//trace('advancer '+delay);
		if (_autoAdvance == true && getTimer() > _startTime+_delay) 
		{
			var x:Number = _x;
			var itemIndex:Number = Math.round(-x/_xspacing); // current image
			if (_continuous || (itemIndex < _itemCount-1))  // any item left?
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
			if(_continuous && itemIndex == _itemCount-1) {
				//trace("wrap");
				_x = -_xspacing;
			}
			else {
				_x = _startX+_deltaX; // doen with this advance, force alignment
			}
			_delay = DelayTime; // set up next advance
			_startTime = getTimer();
			_isStopped = true;
			checkItemLoad();
			this.onEnterFrame = advancer;
			dispatchEvent({type:STOPPED});
		}
	}
}
/**
 * Shown when device is off or paused.
 * 
 * @author Samuel Lai
 */

 import sbcontroller.util.StringUtil;
 import com.chumby.util.Delegate;
 
 class sbcontroller.widgets.InactiveStateOverlay extends MovieClip
{
	//{ constants
	private var MC_WIDTH:Number = 320;
	private var MC_HEIGHT:Number = 240;
	private var TITLETEXT_DEPTH:Number = 1;
	private var MESSAGETEXT_DEPTH:Number = 2;
	//}
	
	//{ instance variables
	private var _messageTitle:String;
	private var _message:String;
	private var _messageTitleText:TextField;
	private var _messageText:TextField;
	private var _onClicked:Function;
	//}
	
	public function InactiveStateOverlay() 
	{
		//initialise variables
		_messageTitle = "";
		_message = "";
		
		//attach handlers
		this.onPress = Delegate.create(this, overlayClicked);
		
		generateUI();
		refreshUI();
	}
	
	//properties
	public function get onClicked():Function
	{
		return _onClicked;
	}
	
	public function set onClicked(value:Function):Void
	{
		_onClicked = value;
	}
	
	public function get messageTitle():String
	{
		return _messageTitle;
	}
	
	public function set messageTitle(value:String):Void
	{
		if (_messageTitle != value)
		{
			_messageTitle = value;
			
			// for some odd reason, previous text artifacts remain, so need to recreate text field
			_messageTitleText.removeTextField();
			_messageTitleText = null;
			generateUI();
			
			refreshUI();
		}
	}
	
	public function get message():String
	{
		return _message;
	}
	
	public function set message(value:String):Void
	{
		if (_message != value)
		{
			_message = value;
			refreshUI();
		}
	}
	
	//methods
	private function generateUI()
	{
		this._alpha = 90;
		
		//set background
		this.moveTo(0, 0);
		this.beginFill(0x333333, 100);
		this.lineTo(MC_WIDTH, 0);
		this.lineTo(MC_WIDTH, MC_HEIGHT);
		this.lineTo(0, MC_HEIGHT);
		this.lineTo(0, 0);
		this.endFill();
		
		//create title text
		if (_messageTitleText == null)
		{
			_messageTitleText = this.createTextField("messageTitleText", TITLETEXT_DEPTH, 0, 60, 310, 36);
			_messageTitleText.embedFonts = true;
			_messageTitleText.selectable = false;
			var titleTextFormat:TextFormat = new TextFormat();
			with (titleTextFormat)
			{
				align = "center";
				color = 0xffffff;
				size = 40;
				font = "main.ttf";
				bold = true;
			}
			_messageTitleText.setNewTextFormat(titleTextFormat);
		}
		
		//create message text
		if (_messageText == null) 
		{
			_messageText = this.createTextField("messageText", MESSAGETEXT_DEPTH, 0, 130, 320, 28);
			_messageText.embedFonts = true;
			_messageText.selectable = false;
			var messageTextFormat:TextFormat = new TextFormat();
			with (messageTextFormat)
			{
				align = "center";
				color = 0x999999;
				size = 26;
				font = "main.ttf";
				bold = true;
			}
			_messageText.setNewTextFormat(messageTextFormat);
		}
	}
	
	public function refreshUI():Void
	{
		_messageTitleText.text = _messageTitle;
		_messageText.text = _message;
	}
	
	private function overlayClicked():Void
	{
		onClicked();
	}
	
	public function removeOverlay():Void
	{
		this.unloadMovie();
		this.removeMovieClip();
	}
}
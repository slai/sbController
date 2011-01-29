import com.chumby.util.MCUtil;
import com.chumby.util.Delegate;

/**
 * Configuration dialog for iiNet net usage widget.
 * 
 * @author Samuel Lai
 */
class SBControllerConfig extends MovieClip
{
	//{ static constants
	private static var MC_WIDTH:Number = 320;
	private static var MC_HEIGHT:Number = 240;
	//}
	
	//{ constants
	private var ADDRESSTEXT_DEPTH:Number = 10;
	private var ADDRESSINPUT_DEPTH:Number = 11;
	private var CAUTHTEXT_DEPTH:Number = 12;
	private var CAUTHINPUT_DEPTH:Number = 13;
	private var DEFAULTIDTEXT_DEPTH:Number = 14;
	private var DEFAULTIDINPUT_DEPTH:Number = 15;
	private var UPDATEINTERVALTEXT_DEPTH:Number = 16;
	private var UPDATEINTERVALINPUT_DEPTH:Number = 17;
	
	private var SAVEBUTTON_DEPTH:Number = 20;
	private var CANCELBUTTON_DEPTH:Number = 21;
	
	private var MESSAGEOVERLAY_DEPTH:Number = 1000;
	
	private var HEADER_HEIGHT:Number = 54;
	//}
	
	//{ instance variables
	private var _addressInput:TextField;
	private var _cauthInput:TextField;
	private var _defaultIdInput:TextField;
	private var _updateIntervalInput:TextField;
	
	private var _messageOverlay:MessageOverlay;
	//}
	
	//-------------------------------------------------------------------
	// MTASC starts with this entry point
	public static function main()
	{
		//load UI
		var mainMC:MovieClip = MCUtil.CreateWithClass(SBControllerConfig, _root, "main", 1);
	}
	
	public function SBControllerConfig()
	{
		//create UI
		generateUI();
		
		//load parameters
		//TEST
		//showMessageOverlay("testing", _root._chumby_instance_url);
		showMessageOverlay("Loading settings", "Contacting chumby servers...");
		WidgetParameters.getWidgetParameters(Delegate.create(this, loadedParameters));
	}
	
	private function generateUI():Void
	{
		var curTextField:TextField = null;
		var tf:TextFormat = null;
		var curY:Number = 0;
		
		tf = new TextFormat();
		with (tf)
		{
			font = "Arial";
			size = 13;
			color = 0x676767;
		}
		
		// gap
		curY += 7;
		
		//address
		curTextField = createTextField("addressText", ADDRESSTEXT_DEPTH, 10 /* gap */, curY, 300, 20);
		curTextField.setNewTextFormat(tf);
		curTextField.text = "Squeezebox Server address & port (address:port):";
		curY += 20 /* height of address text */;
		
		_addressInput = createTextField("addressInput", ADDRESSINPUT_DEPTH, 10 /* gap */, curY, 300, 20);
		_addressInput.setNewTextFormat(tf);
		_addressInput.border = true;
		_addressInput.type = "input";
		curY += 20 /* height of username input */;
		
		//cauth
		curY += 10 /* gap */;
		curTextField = createTextField("cauthText", CAUTHTEXT_DEPTH, 10 /* gap */, curY, 300, 20);
		curTextField.setNewTextFormat(tf);
		curTextField.text = "CAuth (optional, 32 characters):";
		curY += 20 /* height of cauth text */;
		
		_cauthInput = createTextField("cauthInput", CAUTHINPUT_DEPTH, 10 /* gap */, curY, 300, 20);
		_cauthInput.setNewTextFormat(tf);
		_cauthInput.border = true;
		_cauthInput.type = "input";
		curY += 20 /* height of cauth input */;
		
		//default player ID
		curY += 10 /* gap */;
		curTextField = createTextField("defaultIdText", DEFAULTIDTEXT_DEPTH, 10 /* gap */, curY, 300, 20);
		curTextField.setNewTextFormat(tf);
		curTextField.text = "Default player ID (optional, xx:xx:xx:xx:xx:xx):";
		curY += 20 /* height of default player ID text */;
		
		_defaultIdInput = createTextField("defaultIdInput", DEFAULTIDINPUT_DEPTH, 10 /* gap */, curY, 300, 20);
		_defaultIdInput.setNewTextFormat(tf);
		_defaultIdInput.border = true;
		_defaultIdInput.type = "input";
		curY += 20 /* height of default player ID input */;
		
		//update interval
		curY += 10 /* gap */;
		curTextField = createTextField("updateIntervalText", UPDATEINTERVALTEXT_DEPTH, 10 /* gap */, curY, 300, 20);
		curTextField.setNewTextFormat(tf);
		curTextField.text = "Update interval override (optional, in ms):";
		curY += 20 /* height of default player ID text */;
		
		_updateIntervalInput = createTextField("updateIntervalInput", UPDATEINTERVALINPUT_DEPTH, 10 /* gap */, curY, 300, 20);
		_updateIntervalInput.setNewTextFormat(tf);
		_updateIntervalInput.border = true;
		_updateIntervalInput.type = "input";
		curY += 20 /* height of default player ID input */;
		
		//save button
		curY += 10 /* gap */;
		var button:MovieClip = MCUtil.CreateWithClass(BasicButton, this, "saveButton", SAVEBUTTON_DEPTH, { _x:10, _y:curY }, ["Save"]);
		button.onPress = Delegate.create(this, saveButtonClicked);
		
		//cancel button
		button = MCUtil.CreateWithClass(BasicButton, this, "cancelButton", CANCELBUTTON_DEPTH, { _x:70, _y:curY }, ["Cancel"]);
		button.onPress = Delegate.create(this, cancelButtonClicked);
		
	}
	
	private function loadedParameters(parameters:Object):Void
	{
		//for (var i in parameters)
		//	trace(i + ": " + parameters[i]);
		
		//check for error
		if (parameters["error"] == true)
		{
			showMessageOverlay("An error occurred", "Could not contact chumby servers.");
			return;
		}
		
		//no error, fill text boxes
		if (parameters["_private_sbcontroller_address"] != undefined)
			_addressInput.text = parameters["_private_sbcontroller_address"];
			
		if (parameters["_private_sbcontroller_cauth"] != undefined)
			_cauthInput.text = parameters["_private_sbcontroller_cauth"];
		
		if (parameters["_private_sbcontroller_defaultId"] != undefined)
			_defaultIdInput.text = parameters["_private_sbcontroller_defaultId"];
		
		if (parameters["_private_sbcontroller_updateInterval"] != undefined)
			_updateIntervalInput.text = parameters["_private_sbcontroller_updateInterval"];
			
		removeMessageOverlay();
	}
	
	private function saveButtonClicked():Void
	{
		//validate
		var failedValidation:Boolean = false;
		if (StringUtil.isNullOrEmpty(_addressInput.text))
		{
			failedValidation = true;
			_addressInput.background = true;
			_addressInput.backgroundColor = 0xFFFF00;
			
			showMessageOverlay("Address is required", "This is the address and port of your Squeezebox Server.\n\nUse this format: <SBS address>:<port>, e.g. 192.168.1.100:9000.\n\nTap to dismiss message", removeMessageOverlay);
		}
		else if (_addressInput.text.indexOf(":") < 0)
		{
			failedValidation = true;
			_addressInput.background = true;
			_addressInput.backgroundColor = 0xFFFF00;
			
			showMessageOverlay("Port is required", "This is the port of your Squeezebox Server. By default, it is port 9000.\n\nUse this format: <SBS address>:<port>, e.g. 192.168.1.100:9000.\n\nTap to dismiss message", removeMessageOverlay);
		}
		else if (!StringUtil.isNullOrEmpty(_cauthInput.text) && _cauthInput.length != 32)
		{
			failedValidation = true;
			_cauthInput.background = true;
			_cauthInput.backgroundColor = 0xFFFF00;
			
			showMessageOverlay("Cauth value is invalid", "The cauth value is 32 characters long. Visit http://<SBS address>:<port>/xml/?p0=pref in your browser, find the link with the cauth parameter, copy and paste that value here.\n\nTap to dismiss message", removeMessageOverlay);
		}
		else if (!StringUtil.isNullOrEmpty(_defaultIdInput.text) && _defaultIdInput.length != 17)
		{
			failedValidation = true;
			_defaultIdInput.background = true;
			_defaultIdInput.backgroundColor = 0xFFFF00;
			
			showMessageOverlay("Default player ID is invalid", "A player ID identifies your Squeezebox. It can be found in Settings -> Player, in the Player Information section. They look like this: 02:2f:a3:ee:4d:c2.\n\nLeave empty to select from the widget.\n\nTap to dismiss message", removeMessageOverlay);
		}
		else if (!StringUtil.isNullOrEmpty(_updateIntervalInput.text) && (isNaN(Number(_updateIntervalInput.text)) || Number(_updateIntervalInput.text) < 0))
		{
			failedValidation = true;
			_updateIntervalInput.background = true;
			_updateIntervalInput.backgroundColor = 0xFFFF00;
			
			showMessageOverlay("Update interval is invalid", "This interval tells the widget how often to update itself. It is specified in milliseconds; enter 5000 for every 5 seconds. If you make this too frequent, the server may start rejecting requests.\n\nLeave it empty for the default interval.\n\nTap to dismiss message", removeMessageOverlay);
		}
		
		if (failedValidation)
			return;
		
		//send parameters
		showMessageOverlay("saving parameters", "sending to chumby servers...");
		WidgetParameters.setWidgetParameters(Delegate.create(this, saveCompleted), 
			{
				_private_sbcontroller_address : _addressInput.text,
				_private_sbcontroller_cauth : _cauthInput.text,
				_private_sbcontroller_defaultId : _defaultIdInput.text
			}
		);
	}
	
	private function saveCompleted(success:Boolean):Void
	{
		WidgetParameters.closeConfigDialog();
	}
	
	private function cancelButtonClicked():Void
	{
		WidgetParameters.closeConfigDialog();
	}
	
	//{ message overlay functions
	private function isMessageOverlayShowing():Boolean
	{
		return _messageOverlay != null;
	}
	
	private function showMessageOverlay(messageTitle:String, message:String, callback:Function):Void
	{
		if (!isMessageOverlayShowing())
		{
			//does not exist, create it
			//keep header and account name showing
			_messageOverlay = 
					MCUtil.CreateWithClass(MessageOverlay, this, "messageOverlay", MESSAGEOVERLAY_DEPTH);
							
			//attach handlers
			if (callback != undefined)
				_messageOverlay.onClicked = Delegate.create(this, callback);
			else
				_messageOverlay.onClicked = Delegate.create(this, messageOverlayClicked);
		}
		
		//set messages
		_messageOverlay.messageTitle = messageTitle;
		_messageOverlay.message = message;
	}
	
	private function removeMessageOverlay():Void
	{
		if (_messageOverlay != null)
		{
			_messageOverlay.removeOverlay();
			_messageOverlay.removeMovieClip();
			_messageOverlay = null;
		}
	}
	
	private function messageOverlayClicked():Void
	{
		//not used
	}
	//}
	
}
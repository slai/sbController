import com.chumby.util.Delegate;
import sbcontroller.PlayerInfo;
/**
 * Represents the button for each player info.
 * 
 * @author Samuel Lai
 */
class sbcontroller.widgets.PlayerSelectorButton extends MovieClip
{
	//constants
	public static var MC_WIDTH:Number = 780;
	public static var MC_HEIGHT:Number = 40;
	private var BG_RADIUS:Number = 10;
	private var NAMETEXT_DEPTH:Number = 1;
	private var IDTEXT_DEPTH:Number = 2;
	
	//instance variables
	private var _playerInfo:PlayerInfo;
	private var _onClicked:Function;
	
	public function PlayerSelectorButton(playerInfo:PlayerInfo) 
	{
		if (playerInfo == null)
			throw new Error("The player info cannot be null.");
		
		_playerInfo = playerInfo;
		
		generateUI();
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
	
	//methods
	private function generateUI()
	{
		//set background
		this.moveTo(0, BG_RADIUS);
		this.beginFill(0x565656, 100);
		this.curveTo(0, 0, BG_RADIUS, 0);
		this.lineTo(MC_WIDTH - BG_RADIUS, 0);
		this.curveTo(MC_WIDTH, 0, MC_WIDTH, BG_RADIUS);
		this.lineTo(MC_WIDTH, MC_HEIGHT - BG_RADIUS);
		this.curveTo(MC_WIDTH, MC_HEIGHT, MC_WIDTH - BG_RADIUS, MC_HEIGHT);
		this.lineTo(BG_RADIUS, MC_HEIGHT);
		this.curveTo(0, MC_HEIGHT, 0, MC_HEIGHT - BG_RADIUS);
		this.lineTo(0, BG_RADIUS);
		this.endFill();
		
		//create name
		var nameText:TextField = this.createTextField("nameText", NAMETEXT_DEPTH, 5, 5, 780, 20);
		nameText.text = " " + _playerInfo.playerName; //add space to avoid first char being chopped off
		nameText.selectable = false;
		var nameTextFormat:TextFormat = new TextFormat();
		with (nameTextFormat)
		{
			color = 0xffffff;
			size = 12;
			font = "Arial";
			bold = true;
		}
		nameText.setTextFormat(nameTextFormat);
		
		//create id
		var idText:TextField = this.createTextField("idText", IDTEXT_DEPTH, 5, 20, 780, 14);
		idText.text = " " + _playerInfo.playerId; //added space for consistency
		idText.selectable = false;
		var idTextFormat:TextFormat = new TextFormat();
		with (idTextFormat)
		{
			color = 0x999999;
			size = 9;
			font = "Arial";
		}
		idText.setTextFormat(idTextFormat);
		
		//attach handler
		this.onPress = Delegate.create(this, buttonClicked);
	}
	
	private function buttonClicked():Void
	{
		//call the clicked handler
		onClicked(_playerInfo);
	}
}
import com.chumby.util.MCUtil;
import com.chumby.util.Delegate;
import sbcontroller.widgets.PlayerSelectorButton;
import sbcontroller.PlayerInfo;
/**
 * Component for asking users to select a player
 * 
 * @author Samuel Lai
 */
class sbcontroller.widgets.PlayerSelector extends MovieClip
{
	//constants
	private var MC_WIDTH:Number = 320;
	private var MC_HEIGHT:Number = 240;
	private var HEADERTEXT_DEPTH:Number = 1;
	private var PLAYERBUTTON_START_DEPTH:Number = 10;
	private var PLAYERBUTTON_Y_OFFSET:Number = 40;
	private var PLAYERBUTTON_GAP:Number = 5;
	
	//instance variables
	private var _playerInfos:Array;
	private var _onPlayerSelected:Function;
	
	public function PlayerSelector(playerInfos:Array) 
	{
		if (playerInfos == null)
			throw new Error("The player infos array cannot be null.");
		
		_playerInfos = playerInfos;
		
		generateUI();
	}
	
	//properties
	public function get onPlayerSelected():Function
	{
		return _onPlayerSelected;
	}
	
	public function set onPlayerSelected(value:Function):Void
	{
		_onPlayerSelected = value;
	}
	
	//methods
	private function generateUI()
	{
		//set background
		this.moveTo(0, 0);
		this.beginFill(0x333333, 100);
		this.lineTo(MC_WIDTH, 0);
		this.lineTo(MC_WIDTH, MC_HEIGHT);
		this.lineTo(0, MC_HEIGHT);
		this.lineTo(0, 0);
		this.endFill();
		
		//create header
		var headerText:TextField = this.createTextField("headerText", HEADERTEXT_DEPTH, 10, 10, 300, 24);
		headerText.text = "Select a player";
		headerText.selectable = false;
		var headerTextFormat:TextFormat = new TextFormat();
		with (headerTextFormat)
		{
			color = 0xffffff;
			size = 15;
			font = "Arial";
			bold = true;
		}
		headerText.setTextFormat(headerTextFormat);
		
		//create player buttons
		var curPlayerButton:PlayerSelectorButton = null;
		var curPlayerInfo:PlayerInfo = null;
		var curY:Number = _y + PLAYERBUTTON_Y_OFFSET;
		var i:Number = 0;
		for (i = 0; i < _playerInfos.length; i++)
		{
			curPlayerInfo = _playerInfos[i];
			curY += i * (PlayerSelectorButton.MC_HEIGHT + PLAYERBUTTON_GAP);
			curPlayerButton = 
					MCUtil.CreateWithClass(
							PlayerSelectorButton, this, "playerButton-" + curPlayerInfo.playerId, 
							PLAYERBUTTON_START_DEPTH + i, { _x:_x + 10, _y:curY }, 
							[curPlayerInfo]);
			
			//attach handlers
			curPlayerButton.onClicked = Delegate.create(this, buttonClicked);
		}
	}
	
	private function buttonClicked(playerInfo:PlayerInfo):Void
	{
		onPlayerSelected(playerInfo);
		this.unloadMovie();
	}
	
}
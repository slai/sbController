/**
 * Represents player information
 * 
 * @author Samuel Lai
 */
import sbcontroller.util.StringUtil;
 
class sbcontroller.PlayerInfo 
{
	//instance variables
	private var _playerId:String;
	private var _playerName:String;
	
	public function PlayerInfo(playerId:String, playerName:String) 
	{
		//validate
		if (StringUtil.isNullOrEmpty(playerId))
			throw new Error("The player id cannot be null or empty.");
			
		if (StringUtil.isNullOrEmpty(playerName))
			throw new Error("The player name cannot be null or empty.");
			
		//set variables
		_playerId = playerId;
		_playerName = playerName;
	}
	
	//properties
	public function get playerId():String
	{
		return _playerId;
	}
	
	public function get playerName():String
	{
		return _playerName;
	}
}
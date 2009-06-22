/**
 * Represents an item in the playlist
 * 
 * @author Samuel Lai
 */
class sbcontroller.PlaylistItem 
{
	//{ instance variables - screw properties
	public var position:Number;
	public var id:Number;
	public var type:String;
	public var title:String;
	public var album:String;
	public var artist:String;
	public var genre:String;
	public var trackNumber:Number;
	public var duration:String;
	public var coverArtUrl:String;
	//}
	
	public function PlaylistItem() 
	{
		//initialize variables
		position = -1;
		id = 0;
		type = "";
		title = "";
		album = "";
		artist = "";
		genre = "";
		trackNumber = 0;
		duration = "";
		coverArtUrl = null;
	}
	
}
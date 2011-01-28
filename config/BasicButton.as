/**
 * Class for basic buttons for the configuration widget.
 * 
 * @author Samuel Lai
 */
class BasicButton extends MovieClip 
{
	//{ constants
	private var MC_HEIGHT:Number = 24;
	
	private var LABELTEXT_DEPTH:Number = 1;
	
	private var BG_RADIUS:Number = 5;
	//}
	
	//{ instance variables
	private var _label:String;
	private var _labelText:TextField;
	//}
	
	public function BasicButton(label:String) 
	{
		//validate
		if (StringUtil.isNullOrEmpty(label))
			throw new Error("Button label cannot be null or empty.");
		
		_label = label;
		useHandCursor = true;
		
		generateUI();
		paintUI();
	}
	
	private function generateUI():Void
	{
		var tf:TextFormat = null;
		
		tf = new TextFormat();
		with (tf)
		{
			font = "Arial";
			size = 13;
			color = 0xFFFFFF;
		}
		
		//label
		_labelText = createTextField("labelText", LABELTEXT_DEPTH, 10 /* gap */, 2 /* gap */, 30 /* start with this */, 20);
		_labelText.setNewTextFormat(tf);
		_labelText.text = _label;
		_labelText.selectable = false;
		
		//adjust width depending on text width
		_labelText._width = _labelText.textWidth + 10 /* x-gap */ + 15 /* leeway */;
	}
	
	private function paintUI():Void
	{
		var buttonWidth:Number = _labelText._width;
		
		//set background
		this.moveTo(0, BG_RADIUS);
		this.beginFill(0x333333, 100);
		this.curveTo(0, 0, BG_RADIUS, 0);
		this.lineTo(buttonWidth - BG_RADIUS, 0);
		this.curveTo(buttonWidth, 0, buttonWidth, BG_RADIUS);
		this.lineTo(buttonWidth, MC_HEIGHT - BG_RADIUS);
		this.curveTo(buttonWidth, MC_HEIGHT, buttonWidth - BG_RADIUS, MC_HEIGHT);
		this.lineTo(BG_RADIUS, MC_HEIGHT);
		this.curveTo(0, MC_HEIGHT, 0, MC_HEIGHT - BG_RADIUS);
		this.lineTo(0, BG_RADIUS);
		this.endFill();
	}
}
/**
 * Gets and sets widget parameters for the configuration SWF.
 * 
 * Not needed for actual SWF - the parameters are automatically loaded.
 * 
 * @author Samuel Lai
 */
import com.chumby.util.xml.XmlUtil;
 
class WidgetParameters 
{
	
	public static function getWidgetParameters(callback:Function):Void
	{
		var xml:XML = new XML();
		xml["target"] = WidgetParameters;

		xml.onLoad = function (success:Boolean) 
		{
			this.target.gotWidgetParameters(callback, this, success);
		};
			
		xml.load(_root._chumby_instance_url);
	}
	

	public static function gotWidgetParameters(callback:Function, xml:XML, success:Boolean) 
	{
		if (!success)
		{
			callback( { error : true } );
			return;
		}
		
		var curNode:XMLNode = XmlUtil.firstChildOfType(xml, "widget_instance");
		if (curNode == null)
		{
			callback( { error : true } );
			return;
		}
		
		curNode = XmlUtil.firstChildOfType(curNode, "widget_parameters");
		if (curNode == null)
		{
			//no parameters, first time configuring this widget instance
			callback( { } );
			return;
		}
		
		var parameterNodes:Array = XmlUtil.childrenOfType(curNode, "widget_parameter");
		var parameters:Object = { };
		
		for (var i in parameterNodes)
		{
			parameters[XmlUtil.firstChildOfType(parameterNodes[i], "name").firstChild.nodeValue] = 
				XmlUtil.firstChildOfType(parameterNodes[i], "value").firstChild.nodeValue;
		}
		
		callback(parameters);
	}
	
	public static function setWidgetParameters(callback:Function, parameters:Object):Void
	{
		//build xml
		var xml:XML = new XML();
		var curNode:XMLNode = null;
		
		curNode = xml.createElement("widget_instance");
		xml.appendChild(curNode);
		
		var widgetParametersNode:XMLNode = xml.createElement("widget_parameters");
		xml.firstChild.appendChild(widgetParametersNode);
		
		var curParameterNode:XMLNode = null;
		for (var i in parameters)
		{
			curParameterNode = xml.createElement("widget_parameter");
			
			curNode = xml.createElement("name");
			curNode.appendChild(xml.createTextNode(i));
			curParameterNode.appendChild(curNode);
			
			curNode = xml.createElement("value");
			curNode.appendChild(xml.createTextNode(parameters[i]));
			curParameterNode.appendChild(curNode);
			
			widgetParametersNode.appendChild(curParameterNode);
		}
		
		var resultXml:XML = new XML();
		resultXml["target"] = WidgetParameters;
		resultXml.onLoad = function(success:Boolean) 
		{
			this.target.uploadedWidgetParameters(callback, success);
        }
		
		xml.sendAndLoad(_root._chumby_instance_url, resultXml);
	}

	public static function uploadedWidgetParameters(callback:Function, success:Boolean) 
	{
		callback(success);
	}

	public static function closeConfigDialog():Void  
	{
		getURL("javascript:dismiss()");
	}

}
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
/*
* Useful XML functions
*/

class com.chumby.util.xml.XmlUtil
{	
	public static function childrenOfType(x:XMLNode, s:String) :Array
	{
		var a:Array = new Array();
		var n:XMLNode = x.firstChild;
		while (n) {
			if (n.nodeName==s) {
				a.push(n);
			}
			n = n.nextSibling;
		}
		return a;
	}

	public static function childrenThat(x:XMLNode, f:Function) :Array
	{
		var a:Array = new Array();
		var n:XMLNode = x.firstChild;
		while (n) {
			if (f(n)) {
				a.push(n);
			}
			n = n.nextSibling;
		}
		return a;
	}

	public static function firstChildOfType(x:XMLNode, s:String) :XMLNode
	{
		//trace("firstChildOfType: " + s);
		var n:XMLNode = x.firstChild;
		while (n) {
			//trace(n.nodeName);
			if (n.nodeName==s) {
				//trace("---");
				return n;
			}
			n = n.nextSibling;
		}
		return null;
	}

	public static function firstChildThat(x:XMLNode, f:Function) :XMLNode
	{
		var n:XMLNode = x.firstChild;
		while (n) {
			if (f(n)) {
				return n;
			}
			n = n.nextSibling;
		}
		return null;
	}

	public static function firstDescendantOfType(x:XMLNode, s:String) :XMLNode
	{
		var n:XMLNode = firstChildOfType(x,s);
		if (n) return n;
		n = x.firstChild;
		while (n) {
			var k:XMLNode = firstDescendantOfType(n, s);
			if (k) return k;
			n = n.nextSibling;
		}
		return null;
	}

	// returns the text of first child item of an element with the given tag
	public static function firstValueOfType(x:XMLNode, s:String) :String
	{
		var n:XMLNode = x.firstChild;
		while (n) {
			if (n.nodeName==s) {
				return n.firstChild.nodeValue;
			}
			n = n.nextSibling;
		}
		return null;
	}
}
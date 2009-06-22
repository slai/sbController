/* 
* functions for associating movieclips with classes
* see flashdevelop.org for more info
*/

class com.chumby.util.MCUtil
{
    //create a movieClip and associate a class with it
	//Sam: added constructorArgs
    static public function CreateWithClass( classRef:Function,target:MovieClip, name:String, depth:Number, params:Object, constructorArgs:Array )
	{
        var mc:MovieClip=target.createEmptyMovieClip(name,depth);
        mc.__proto__ = classRef.prototype;
        if (params != null) for (var i in params) mc[i] = params[i];
		if (constructorArgs == undefined)
			classRef.apply(mc);
		else
			classRef.apply(mc, constructorArgs);
        return mc;
    }
	
    //attach a movieClip from the library and associate a class with it
    static public function AttachWithClass( classRef:Function, target:MovieClip, id:String, name:String, depth:Number, params:Object )
	{
        var mc:MovieClip = target.attachMovie(id, name, depth, params);
        mc.__proto__ = classRef.prototype;
        classRef.apply(mc);
        return mc;
    }

    //link a class with an existing movieClip, use for _root / timeline association
    static public function LinkWithClass( classRef:Function, target:MovieClip )
	{
        var mc:MovieClip = target;
        mc.__proto__ = classRef.prototype;
        classRef.apply(mc);
        return target;
    }
}

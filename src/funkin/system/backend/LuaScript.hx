package funkin.system.backend;

#if (linc_lua)
import vm.lua.Lua;
#end

class LuaScript
{
	#if (linc_lua) // doing hxvm-lua just break break...
	public var vm:Lua;
	#end
	public var scriptName:String = "";

	private var scriptContents(default, null):String = "";

	public static var FUNCTION_STOP:String = "##vanillafunctionstop##";
	public static var FUNCTION_CONTINUE:String = "##vanillafunctioncontinue##";

	public function new(path:String, scriptName:String)
	{
		scriptContents = Assets.getText(path);
		#if (linc_lua)
		vm = new Lua();
		vm.run(scriptContents);
		#end

		set('version', 0.01);
		set('curBeat', 0.0);
		set('curStep', 0.0);
		set('curSection', 0.0);

		set('Function_Stop', FUNCTION_STOP);
		set('Function_Continue', FUNCTION_CONTINUE);

		trace('loaded lua script: ' + scriptName);
	}

	public function set(name:String, ?value:Any)
	{
		#if (linc_lua)
		vm.setGlobalVar(name, value);
		#end
	}

	public function call(name:String, ?args:Array<Any>)
	{
		args ??= [];
		#if (linc_lua)
		try
		{
			return vm.call(name, args);
		}
		catch (e)
		{
			return e;
		}
		#else
		return "null";
		#end
	}

	public var closed:Bool = false;

	public function destroy()
	{
		call('destroy');
		closed = true;

		#if (linc_lua)
		vm.destroy();
		#end
	}
}

package funkin.system.backend;

class LuaScript
{
	public var scriptName:String = "";

	private var scriptContents(default, null):String = "";

	public static var FUNCTION_STOP:String = "##vanillafunctionstop##";
	public static var FUNCTION_CONTINUE:String = "##vanillafunctioncontinue##";

	public function new(path:String, scriptName:String)
	{
		scriptContents = Assets.getText(path);

		set('version', 0.01);
		set('curBeat', 0.0);
		set('curStep', 0.0);
		set('curSection', 0.0);

		set('Function_Stop', FUNCTION_STOP);
		set('Function_Continue', FUNCTION_CONTINUE);

		trace('loaded lua script: ' + scriptName);
	}

	public function set(name:String, ?value:Any) {}

	public function call(name:String, ?args:Array<Any>)
	{
		args ??= [];

		return "null";
	}

	public var closed:Bool = false;

	public function destroy()
	{
		call('destroy');
		closed = true;
	}
}

package;

import flixel.system.scaleModes.RatioScaleMode;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.MovieClip;
import openfl.Lib;
import debug.*;

#if windows
@:buildXml('
<target id="haxe">
	<lib name="wininet.lib" if="windows" />
	<lib name="dwmapi.lib" if="windows" />
</target>
')
@:cppFileCode('
#include <windows.h>
#include <winuser.h>
#pragma comment(lib, "Shell32.lib")
extern "C" HRESULT WINAPI SetCurrentProcessExplicitAppUserModelID(PCWSTR AppID);
')
#end
class FunkinGame extends flixel.FlxGame
{
	public static var mainInstance(default, null):Sprite;
	public static var applicationScreen(get, never):MovieClip;

	public static var novid:Bool = false;
	public static var flippymode:Bool = false;

	@:noCompletion inline static function get_applicationScreen()
		return Lib.current;

	public static function main():Void
	{
		// ReplaceClassMacro.replaceClass("a", "b");
		mainInstance = new Main();
	}

	public function new()
	{
		#if (cpp && windows)
		untyped __cpp__("SetProcessDPIAware(); // allows for more crisp visuals
						SetConsoleOutputCP(CP_UTF8);
						DisableProcessWindowsGhosting() // lets you move the window and such if it's not responding
			");
		#end

		#if sys
		novid = Sys.args().contains("-novid");
		flippymode = Sys.args().contains("-flippymode");
		#end

		super(0, 0, FreeplayState, 60, 60, true);

		scrollRect = new openfl.geom.Rectangle();
		__scrollRect.setTo(0, 0, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y);
		applicationScreen.addChild(this);

		#if !mobile
		applicationScreen.stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE;
		#end

		FlxG.signals.gameResized.add((w, h) -> __scrollRect.setTo(0, 0, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));

		trace("-=Args=-");
		trace("novid: " + novid);
		trace("flippymode: " + flippymode);

		#if hxcpp_debug_server
		trace('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
		#else
		trace('hxcpp_debug_server is disabled! This build does not support debugging.');
		#end

		// grafex.util.tools.ShaderResizeFix.init();
	}

	var skipNextTickUpdate:Bool = false;

	public override function switchState()
	{
		super.switchState();
		draw();
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
	}

	public override function onEnterFrame(t)
	{
		if (skipNextTickUpdate != (skipNextTickUpdate = false))
			_total = ticks = getTicks();
		super.onEnterFrame(t);
	}
}

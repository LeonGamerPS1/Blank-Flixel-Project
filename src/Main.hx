package;

import haxe.ui.core.Screen;
import haxe.ui.Toolkit;
import funkin.ui.debug.MemoryCounter;
import openfl.display.FPS;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.display.StageScaleMode;
import flixel.graphics.FlxGraphic;

#if windows
@:headerCode("
	#include <windows.h>
	#include <winuser.h>
")
#end
class Main extends Sprite
{
	/**
	 * A frame counter displayed at the top left.
	 */
	public static var fpsCounter:FPS;

	/**
	 * A RAM counter displayed at the top left.
	 */
	public static var memoryCounter:MemoryCounter;

	public function new()
	{
		super();

		Toolkit.init();

		addChild(new FunkinGame());
		
		WeekData.init();
		ClientPrefs.load();
		ClientPrefs.saveToFlixel();
		haxe.ui.focus.FocusManager.instance.autoFocus = false;
		FlxG.drawFramerate = ClientPrefs.data.fps;
		FlxG.updateFramerate = ClientPrefs.data.fps;

		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);

		#if !flash
		// TODO: disabled on flash (todo: find another method that works?)
		memoryCounter = new MemoryCounter(10, 13, 0xFFFFFF);
		addChild(memoryCounter);
		#end


		registerAsDPICompatible();
		setFlxDefines();
		Controls.instance = new Controls('__funkin__control__.exe');
		FlxG.inputs.addUniqueType(Controls.instance);
	}

	function setFlxDefines()
	{
	
	}

	@:functionCode('
        SetProcessDPIAware();
    ')
	public static function registerAsDPICompatible() {}

	// Get rid of hit test function because mouse memory ramp up during first move (-Bolo)
	@:noCompletion #if !flash override #end function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool,
			hitObject:DisplayObject):Bool
		return false;

	@:noCompletion #if !flash override #end function __hitTestHitArea(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool,
			hitObject:DisplayObject):Bool
		return false;

	@:noCompletion #if !flash override #end function __hitTestMask(x:Float, y:Float):Bool
		return false;
}

package;

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

		addChild(new FlxGame(1280, 720, PlayState, 120,120));

		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);

		trace(Paths.readAssetsDirectoryFromLibrary('weeks','TEXT',''));


		
		#if !html5
		// TODO: disabled on HTML5 (todo: find another method that works?)
		memoryCounter = new MemoryCounter(10, 13, 0xFFFFFF);
		addChild(memoryCounter);
		#end

		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		registerAsDPICompatible();
		setFlxDefines();
		Controls.instance = new Controls('__funkin__control__.exe');
		FlxG.inputs.addUniqueType(Controls.instance);
	}

	function setFlxDefines()
	{
		// FlxG.autoPause = false;
		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
	}

	@:functionCode('
        SetProcessDPIAware();
    ')
	public static function registerAsDPICompatible() {}

	// Get rid of hit test function because mouse memory ramp up during first move (-Bolo)
	@:noCompletion override function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject):Bool
		return false;

	@:noCompletion override function __hitTestHitArea(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool,
			hitObject:DisplayObject):Bool
		return false;

	@:noCompletion override function __hitTestMask(x:Float, y:Float):Bool
		return false;
}

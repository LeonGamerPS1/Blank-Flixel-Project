package funkin.graphics;

import flixel.system.FlxAssets;
import flixel.FlxSprite;

using StringTools;

class HoldCover extends FlxSprite
{
	public var parent:Strum;

	public static var fag = ["Purple", "Blue", "Green", "Red"];

	public function new(id:Int = 0, parent:Strum)
	{
		super(parent.x, parent.y);
		var png = 'holdCover${fag[id % fag.length]}';
		frames = Paths.getSparrowAtlas(png);

		animation.addByPrefix('hold', png, 24, true);
		animation.play('hold');
		antialiasing = true;

		if (parent.isPixel)
			scale.set(0, 0);
	}
}


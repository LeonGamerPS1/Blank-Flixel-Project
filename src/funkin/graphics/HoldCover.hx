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
		frames = Paths.getAtlas('ui/base/$png');

		animation.addByPrefix('hold', png, 24, true);
		animation.addByPrefix('splash', png.replace('holdCover','holdCoverEnd'), 24, false);
		animation.play('hold');
		scale.x = 0.7;
		scale.y = 0.7;
		updateHitbox();
		centerOffsets();
		centerOrigin();
		antialiasing = true;

		if (parent.isPixel)
			scale.set(0, 0);
	}

	public override function update(_:Float) {
		super.update(_);
		if(animation.finished && animation.name == 'splash')
		{
			animation.play('hold');
			visible = false;
		}
	}
}


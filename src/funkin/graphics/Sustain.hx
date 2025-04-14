package funkin.graphics;

class Sustain extends TiledSprite
{
	var parent:Note;

	public function new(parent:Note)
	{
		super(-3000, 0);
		this.parent = parent;
		parent.sustain = this;

		init();
	}

	function init()
	{
		if (parent.isPixel)
			pixel();
		else
			normal();
	}

	function pixel()
	{
		frames = parent.frames;
		animation.copyFrom(parent.animation);

		animation.play('hold');
		setTail('end');
		updateHitbox();

		setGraphicSize(width * 5);
		updateHitbox();
	}

	function normal()
	{
		frames = parent.frames;
		animation.copyFrom(parent.animation);

		animation.play('hold');
		setTail('end');
		updateHitbox();

		setGraphicSize(width * 0.7);
		updateHitbox();

		antialiasing = ClientPrefs.data.antialiasing;
	}

	static public var colArray:Array<FlxColor> = [FlxColor.PURPLE, FlxColor.BLUE, FlxColor.GREEN, FlxColor.RED];

	override function draw()
	{
		var length:Float = parent.sustainLength;
		if (shader != parent.shader)
			shader = parent.shader;

		var expectedHeight:Float = (length * 0.45 * parent.speed) + (tailHeight() - 10);
		if (height != expectedHeight)
			this.height = Math.max(expectedHeight, 0);

		if (alpha != parent.alpha * 0.7)
			alpha = parent.alpha * 0.7;

		// regenPos();

		super.draw();
	}

	public function regenPos()
	{
		setPosition(parent.x + ((parent.width - width) * 0.5), parent.y + (parent.height * 0.5));

		var calcAngle:Float = 0;
		calcAngle += parent.sustainAngle;
		if (parent.downScroll) // fuck you no directional scrolling for downscroll /j
		{
			angle = 0;
			flipY = true;
			y -= height;
		}
		else
			angle = calcAngle;
	}
}

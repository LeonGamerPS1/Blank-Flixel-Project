package funkin.graphics;

class Sustain extends NonRoundedSprite
{
	public var parent:Note;
	public var tail:NonRoundedSprite;

	public function new(parent:Note)
	{
		super();
		this.parent = parent;
		reloadSustain(parent);
	}

	public var scrollFromBottom:Bool = true;

	public function reloadSustain(parent:Note)
	{
		normal();
	}

	override function draw()
	{
		setGraphicSize(width, Math.abs((parent.sustainLength * 0.45 * parent.speed) - tail.height));
		updateHitbox();
		if (alpha != parent.alpha)
			alpha = parent.alpha;

		setPosition(parent.x + (parent.width - width) / 2, parent.y + parent.height / 2);
		if (tail.cameras != cameras)
			tail.cameras = cameras;

		if (tail.alpha != alpha)
			tail.alpha = alpha;

		if (tail.x != x)
			tail.x = x;
		tail.y = y + (!parent.downScroll ? height : (-height - tail.height));

		if (tail.flipY != flipY)
			tail.flipY = flipY;
		if (parent.downScroll)
		{
			flipY = true;
			y += -height;
		}
		else
			flipY = false;

		if (parent.wasGoodHit)
			clip();
		super.draw();

		tail.draw();
	}

	function normal()
	{
		var size = !parent.isPixel ? 0.7 : 6;
		frames = parent.frames;
		animation.copyFrom(parent.animation);

		animation.play('hold');
		updateHitbox();
		@:privateAccess
		setGraphicSize(width * size);
		updateHitbox();

		tail = new NonRoundedSprite(x, y);
		tail.frames = frames;
		tail.animation.copyFrom(animation);
		tail.animation.play('end');
		tail.updateHitbox();

		tail.setGraphicSize(tail.width * size);
		tail.updateHitbox();
		tail.antialiasing = parent.antialiasing;
	}

	inline public function clip()
	{
		var center:Float = parent.clipPoint.y;

		var swagRect:FlxRect = clipRect;
		if (swagRect == null)
			swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

		if (parent.downScroll)
		{
			if (y - offset.y * scale.y + height >= center)
			{
				swagRect.width = frameWidth;
				swagRect.height = (center - y) / scale.y;
				swagRect.y = frameHeight - swagRect.height;
			}
		}
		else if (y + offset.y * scale.y <= center && !parent.downScroll)
		{
			swagRect.y = (center - y) / scale.y;
			swagRect.width = width / scale.x;
			swagRect.height = (height / scale.y) - swagRect.y;
		}

		clipRect = swagRect;
		clipTail();
	}

	inline public function clipTail()
	{
		var center:Float = parent.clipPoint.y;
		var tailEnd = tail;
		var isDownscroll = parent.downScroll;
		if (clipRect.height < 0)
		{
			var swagRect:FlxRect = tailEnd.clipRect;
			if (swagRect == null)
				swagRect = FlxRect.get(0, 0, isDownscroll ? tailEnd.frameWidth : tailEnd.width / tailEnd.scale.x, tailEnd.frameHeight);

			if (parent.downScroll)
			{
				if (tailEnd.y + tailEnd.height >= center)
				{
					swagRect.height = (center - tailEnd.y) / tailEnd.scale.y;
					swagRect.y = tailEnd.frameHeight - swagRect.height;
				}
			}
			else
			{
				if (tailEnd.y <= center)
				{
					swagRect.y = (center - tailEnd.y) / tailEnd.scale.y;
					swagRect.height = (tailEnd.height / tailEnd.scale.y) - swagRect.y;
				}
			}
			tailEnd.clipRect = swagRect;
		}
	}

	override function destroy()
	{
		tail.destroy();
		tail = null;
		super.destroy();
	}
}

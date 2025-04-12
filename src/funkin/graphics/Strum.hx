package funkin.graphics;

class Strum extends FlxSprite
{
	public static final dirArray:Array<String> = ['left', 'down', 'up', 'right'];

	public var id:Int = 0;
	public var skin(default, set):String;
	public var downScroll:Bool = true;
	public var isPixel:Bool = false;

	public function new(id:Int = 0, isPixel:Bool = false)
	{
		super();
		this.id = id;
		this.isPixel = isPixel;
		skin = 'NOTE_assets';
	}

	function set_skin(value:String):String
	{
		var lastTex = skin;
		skin = value;
		if (skin != lastTex)
			reload();
		return skin = value;
	}

	var confirm = [[12, 16], [13, 17], [14, 18], [15, 19]];

	function reload()
	{
		if (!isPixel)
		{
			frames = Paths.getSparrowAtlas('ui/base/noteSkins/$skin');

			animation.addByPrefix('static', 'arrow' + dirArray[Std.int(id * 1.0) % dirArray.length].toUpperCase(), 24, false);
			animation.addByPrefix('confirm', dirArray[id % dirArray.length] + ' confirm0', 24, false);
			animation.addByPrefix('press', dirArray[id % dirArray.length] + ' press0', 24, false);

			setGraphicSize(width * 0.7);
			updateHitbox();

			playAnim('static');
			antialiasing = true;
		}
		else
		{
			loadGraphic(Paths.image('ui/pixel/noteSkins/$skin'), true, 17, 17);
			animation.add('static', [id % 4], 24, false);
			animation.add('press', [id % 4 + 4, id % 4 + 8], 24, false);
			animation.add('confirm', confirm[id % confirm.length], 24, false);
			setGraphicSize(width * 6);
			updateHitbox();

			playAnim('static');
		}
	}

	public var anim:String = "";
	public var r:Float = 0;

	public function playAnim(name:String = '', ?force:Bool = false)
	{
		animation.play(name, force);

		anim = name;
		centerOffsets();
		centerOrigin();
	}

	override function update(elapsed:Float)
	{
		if (r > 0)
		{
			r -= elapsed;
			if (r < 0)
			{
				r = 0;
				playAnim('static');
			}
		}
		super.update(elapsed);
	}
}

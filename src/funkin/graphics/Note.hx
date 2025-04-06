package funkin.graphics;

class Note extends FlxSprite
{
	public static final dirArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var data:NoteData;
	public var skin(default, set):String;
	public var downScroll:Bool = false;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var wasHitByOpponent:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var multAlpha:Float = 1;

	public var noteType:String = "normal";
	public var conductor:Conductor;
	public var sustain:Sustain;
	public var sustainLength:Float = 0;
	public var clipPoint:FlxPoint = FlxPoint.get(0, 0);
	public var ignoreNote:Bool = false;
	public var tooLate:Bool = false;

	public function new(data:NoteData, conductor:Conductor, ?isPixel:Bool = false)
	{
		super();
		this.data = data;
		this.noteType = data.type;
		this.mustPress = data.data > 3;
		this.conductor = conductor;
		this.sustainLength = data.length;
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

	public var isPixel:Bool = false;

	function reload()
	{
		if (!isPixel)
		{
			frames = Paths.getSparrowAtlas('ui/base/noteSkins/$skin');

			var dir:Int = data.data;

			animation.addByPrefix('arrow', dirArray[Std.int(dir * 1.0) % dirArray.length] + '0', 24, false);
			animation.addByPrefix('hold', dirArray[dir % dirArray.length] + ' hold piece', 24, false);
			animation.addByPrefix('end', dirArray[dir % dirArray.length] + ' hold end', 24, false);

			setGraphicSize(width * 0.7);
			updateHitbox();

			playAnim('arrow');
			antialiasing = true;
		}
		else
		{
			loadGraphic(Paths.image('ui/pixel/noteSkins/$skin'), true, 17, 17);

			animation.add('arrow', [data.data % 4 + 4], 12, false);
			animation.add('hold', [data.data % 4 + 20], 12, false);
			animation.add('end', [data.data % 4 + 24], 12, false);
			setGraphicSize(width * 6);

			antialiasing = false;
			updateHitbox();
			playAnim('arrow');
		}
	}

	public var anim:String = "";

	public function playAnim(name:String = '', ?force:Bool = false)
	{
		animation.play(name, force);

		anim = name;
		centerOffsets();
		centerOrigin();
	}

	public var speed:Float = 1;

	public function followObject(object:Strum, ?speed:Float = 1)
	{
		if (this.speed != speed)
			this.speed = speed;

		if (object == null || conductor == null)
			return;
		clipPoint.set(object.x, object.y + (160 / 2 * 0.7));
		downScroll = object.downScroll;

		x = object.x + offsetX;
		y = object.y + (data.time - conductor.time) * (0.45 * speed * (!object.downScroll ? 1 : -1)) + offsetY;
	}

	override function draw()
	{
		if (!wasGoodHit)
			super.draw();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!(conductor != null))
			return;

		if (!mustPress)
		{
			if (data.time <= conductor.time)
				wasGoodHit = true;

			canBeHit = false;
		}
		else
		{
			// The * 0.5 us so that its easier to hit them too late, instead of too early
			if (data.time > conductor.time - Conductor.safeZoneOffset && data.time < conductor.time + (Conductor.safeZoneOffset * 0.5))
				canBeHit = true;
			else
				canBeHit = false;

			if (data.time < conductor.time - Conductor.safeZoneOffset)
				tooLate = true;
		}
	}
}

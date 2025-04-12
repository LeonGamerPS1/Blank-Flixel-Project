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
	public var missed:Bool = false;

	public function new(data:NoteData, conductor:Conductor, isSustainNote:Bool = false, ?isPixel:Bool = false, ?prevNote:Note)
	{
		super();
		this.data = data;
		this.noteType = data.type;
		this.mustPress = data.data > 3;
		this.conductor = conductor;
		this.sustainLength = data.length;
		this.isPixel = isPixel;
		this.prevNote = prevNote;
		this.isSustainNote = isSustainNote;

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
	public var isSustainNote:Bool = false;
	public var prevNote:Note;

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

			if (isSustainNote && prevNote != null)
			{
				offsetX += width / 2;
				playAnim('end');
				scale.y = 1;
				updateHitbox();
				offsetX -= width / 2;

				if (prevNote.isSustainNote)
				{
					prevNote.playAnim('hold');
					prevNote.scale.y = 0.7 * conductor.stepCrochet / 100 * 1.5 * PlayState.song.speed;
					prevNote.updateHitbox();
				}
			}
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

			if (isSustainNote && prevNote != null)
			{
				offsetX += width / 2;
				playAnim('end');
				updateHitbox();
				offsetX -= width / 2;

				if (prevNote.isSustainNote)
				{
					prevNote.playAnim('hold');
					prevNote.setGraphicSize(prevNote.width, 54);
					prevNote.scale.y *= conductor.stepCrochet / 100 * 0.834 * PlayState.song.speed;
					prevNote.updateHitbox();
				}
			}
		}
		if (isSustainNote)
			multAlpha = 0.8;
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
		y = object.y + (data.time - conductor.time) * (0.45 * speed * (!object.downScroll ? 1 : -1)) + offsetY * Math.cos(90);
		alpha = object.alpha * multAlpha;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!(conductor != null))
			return;

		if (!mustPress)
		{
			if (data.time <= conductor.time
				|| isSustainNote
				&& prevNote.wasGoodHit
				&& (data.time < conductor.time + (Conductor.safeZoneOffset * 0.5)))
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

			if (data.time < conductor.time - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
	}

	public function clipToStrumNote(myStrum:Strum)
	{
		var center:Float = myStrum.y + offsetY + (160 * 0.7) / 2;
		if ((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if (swagRect == null)
				swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if (y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}
}

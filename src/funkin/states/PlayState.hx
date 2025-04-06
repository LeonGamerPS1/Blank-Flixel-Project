package funkin.states;

import haxe.io.Bytes;
import funkin.system.backend.chart.LegacyFNFToVanilla;
import moonchart.formats.fnf.legacy.FNFPsych;
import lime.ui.FileDialog;
import openfl.net.FileReference;

class PlayState extends flixel.FlxState
{
	public var conductor:Conductor;

	public static var song:SongMap;

	public var tracks:Map<String, FlxSound> = [];

	public var camHUD:FlxCamera;
	public var uiGroup:FlxGroup = new FlxGroup();
	public var plrStrums:StrumLine;
	public var cpuStrums:StrumLine;

	public var startedSong:Bool = false;
	public var startedCountdown:Bool = false;
	public var text:FlxText;

	public var notes:FlxTypedGroup<Note>;
	public var sustains:FlxTypedGroup<Sustain>;
	public var playCpu:Bool = false;

	override public function create()
	{
		super.create();
		bgColor = FlxColor.GRAY;

		song ??= Song.grabSong();
		songSpeed = song.speed;
		conductor = new Conductor(song.bpm);
		conductor.onMeasure.add(sectionHit);
		conductor.onBeat.add(beatHit);
		conductor.onStep.add(stepHit);

		initChars();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		uiGroup.cameras = [camHUD];
		add(uiGroup);

		cpuStrums = new StrumLine();
		uiGroup.add(cpuStrums);

		plrStrums = new StrumLine(false, true);
		uiGroup.add(plrStrums);

		sustains = new FlxTypedGroup<Sustain>();
		uiGroup.add(sustains);

		notes = new FlxTypedGroup<Note>();
		uiGroup.add(notes);

		text = new FlxText(FlxG.width, FlxG.height - 18, 0, 'v0.0.1 PROTOTYPE | FUNKIN VANILLA');
		text.setFormat(Paths.font('vcr'), 16, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		text.x -= text.width;
		text.borderSize = 1;
		text.antialiasing = true;
		uiGroup.add(text);

		var mainTrackPath:String = 'assets/' + song.tracks.main;
		var trackMain:FlxSound = FlxG.sound.load(mainTrackPath);
		tracks.set('main', trackMain);
		var diddy = 0;

		conductor.time = -(conductor.crochet * 5);
		if (song.tracks.extra != null)
			for (trackPath in song.tracks.extra)
			{
				var trackDir:String = 'assets/' + trackPath;
				var track:FlxSound = FlxG.sound.load(trackDir);
				tracks.set(trackDir + diddy, track);
				diddy++;
			}
		else
			trace('[INFO] No extra tracks found for song ${song.displayName}. Skipping Extra tracks.');

		startCallback();
	}

	public var lastBpmChangeIndex:Int = 0;
	public var lastNoteIndex:Int = 0;
	public var songSpeed:Float = 0;

	public var BF_X:Float = 770;

	public static var isPixelStage:Bool = true;

	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var boyfriend:Character;
	public var dad:Character;
	public var girlfriend:Character;

	public var camFollow:FlxObject;

	inline function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
			girlfriend.kill();
		}
		char.x += char.position[0];
		char.y += char.position[1];
	}

	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];

	function initChars()
	{
		boyfriend = new Character(song.players[2], true);
		dad = new Character(song.players[0]);
		girlfriend = new Character(song.players[1]);
		girlfriend.scrollFactor.set(0.95, 0.95);

		add(girlfriend);
		add(dad);
		add(boyfriend);
		boyfriend.setPosition(BF_X, BF_Y);
		girlfriend.setPosition(GF_X, GF_Y);
		dad.setPosition(DAD_X, DAD_Y);
		boyfriend.Conductor = conductor;
		dad.Conductor = conductor;
		girlfriend.Conductor = conductor;

		startCharacterPos(dad, true);
		startCharacterPos(boyfriend);
		startCharacterPos(girlfriend);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (girlfriend != null)
		{
			camPos.x += girlfriend.getGraphicMidpoint().x + girlfriend.camera_position[0];
			camPos.y += girlfriend.getGraphicMidpoint().y + girlfriend.camera_position[1];
		}

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		add(camFollow);
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		openfl.system.System.gc();
	}

	inline public function playerDance():Void
	{
		var anim:String = boyfriend.getAnimationName();
		if (boyfriend.holdTimer > conductor.stepCrochet * (0.0011 #if FLX_PITCH / tracks.get("main")
			.pitch #end) * boyfriend.singDuration && anim.startsWith('sing'))
			boyfriend.dance();
	}

	inline public function characterBopper(beat:Int):Void
	{
		if (girlfriend != null
			&& beat % Math.round(1 * girlfriend.danceEveryNumBeats) == 0
			&& !girlfriend.getAnimationName().startsWith('sing')
			&& !girlfriend.stunned)
			girlfriend.dance();
		if (boyfriend != null
			&& beat % boyfriend.danceEveryNumBeats == 0
			&& !boyfriend.getAnimationName().startsWith('sing')
			&& !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();

		if (!(Controls.instance.pressed.check(NOTE_LEFT)
			|| Controls.instance.pressed.check(NOTE_DOWN)
			|| Controls.instance.pressed.check(NOTE_UP)
			|| Controls.instance.pressed.check(NOTE_RIGHT)))
			playerDance();
	}

	override function update(elapsed:Float)
	{
		if (!startedSong)
		{
			if (startedCountdown)
			{
				conductor.time += FlxG.elapsed * 1000;
				if (conductor.time >= 0)
					startSong();
			}
		}

		if (startedSong)
		{
			conductor.time = tracks["main"].time;
			for (track in tracks)
				if (Math.abs(track.time - tracks["main"].time) > 20 && track != tracks.get("main"))
					track.time = tracks["main"].time;
		}

		if (song.bpmMap != null && song.bpmMap[lastBpmChangeIndex] != null && startedSong)
		{
			if (song.bpmMap[lastBpmChangeIndex].time <= conductor.time)
			{
				conductor.changeBpmAt(song.bpmMap[lastBpmChangeIndex].time, song.bpmMap[lastBpmChangeIndex].bpm, song.bpmMap[lastBpmChangeIndex].numerator,
					song.bpmMap[lastBpmChangeIndex].denominator);
				lastBpmChangeIndex++;
			}
		}

		if (startedCountdown)
		{
			if (song.notes[lastNoteIndex] != null)
			{
				var time:Float = 3000;
				if (songSpeed < 1)
					time /= songSpeed;

				if (song.notes[lastNoteIndex].time - conductor.time < time)
				{
					var dunceNote:Note = new Note(song.notes[lastNoteIndex], conductor, isPixelStage);
					notes.sort(sortNotesByTimeHelper, FlxSort.DESCENDING);

					notes.insert(0, dunceNote);
					lastNoteIndex++;

					if (dunceNote.data.length > 0)
					{
						var sustain:Sustain = new Sustain(dunceNote);
						dunceNote.sustain = sustain;
						sustains.add(sustain);
					}
				}
			}
		}

		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 7));
		super.update(elapsed);

		for (daNote in notes)
		{
			if (!daNote.alive || !daNote.exists || !daNote.active)
				continue;

			var strum = getStrum(daNote.data);
			daNote.followObject(strum, songSpeed);

			var _maxTime:Float = daNote.data.time + daNote.data.length;

			if (!daNote.mustPress && daNote.wasGoodHit)
			{
				strum.r = conductor.stepCrochet * 1.5 / 1000;

				dad.confirmAnimation(daNote, !daNote.wasHitByOpponent);
				if (!daNote.wasHitByOpponent)
				{
					strum.playAnim('confirm', true);
					daNote.wasHitByOpponent = true;
				}
			}

			if (!playCpu
				&& daNote.wasGoodHit
				&& strum.anim != "confirm"
				&& daNote.mustPress
				&& daNote.sustainLength > 0
				&& !(_maxTime - (conductor.stepCrochet) < conductor.time))
			{
				invalidateNote(daNote);
				return;
			}

			if (daNote.wasGoodHit && _maxTime < conductor.time)
			{
				invalidateNote(daNote);
			}

			if (conductor.time - daNote.data.time - daNote.sustainLength > (350 / song.speed))
			{
				if (daNote.mustPress && !daNote.ignoreNote && !daNote.wasGoodHit)
					noteMiss(daNote.data.data % 4);

				daNote.active = daNote.visible = false;
				invalidateNote(daNote);
			}
		}
		keyShit();
	}

	function noteMiss(i:Int = 0) {}

	function invalidateNote(daNote:Note)
	{
		if (daNote.sustain != null)
			daNote.sustain.destroy();
		daNote.sustain = null;
		daNote.destroy();
		notes.remove(daNote, true);
		daNote = null;
	}

	function getStrum(arg:NoteData):Strum
	{
		var group = arg.data > 3 ? plrStrums : cpuStrums;
		return group.members[arg.data % group.length];
	}

	function keyShit()
	{
		var hitNotes:Array<Note> = [];
		var directions:Array<Int> = [];
		var dumbNotes:Array<Note> = [];

		var pressed:Array<Bool> = [
			Controls.instance.justPressed.NOTE_LEFT,
			Controls.instance.justPressed.NOTE_DOWN,
			Controls.instance.justPressed.NOTE_UP,
			Controls.instance.justPressed.NOTE_RIGHT
		];
		var released:Array<Bool> = [
			Controls.instance.justReleased.NOTE_LEFT,
			Controls.instance.justReleased.NOTE_DOWN,
			Controls.instance.justReleased.NOTE_UP,
			Controls.instance.justReleased.NOTE_RIGHT
		];

		var holding:Array<Bool> = [
			Controls.instance.pressed.NOTE_LEFT,
			Controls.instance.pressed.NOTE_DOWN,
			Controls.instance.pressed.NOTE_UP,
			Controls.instance.pressed.NOTE_RIGHT
		];

		if (FlxG.keys.justPressed.C)
		{
			var fileRef:FileDialog = new FileDialog();
			fileRef.onOpen.add(function(yes)
			{
				var psych:FNFPsych = new FNFPsych().fromJson(yes);
				var dial:FileReference = new FileReference();
				dial.save(Bytes.ofString(Json.stringify(LegacyFNFToVanilla.convert(psych))), 'default.json');
			});
			fileRef.open('json', null, "Legacy convert/ 0.7.3 psych");
		}

		for (strum in plrStrums)
		{
			if (strum != null)
			{
				if (pressed[strum.id] && strum.anim != "confirm")
					strum.playAnim('press');
				else if (!holding[strum.id])
					strum.playAnim('static', true);
			}
		}

		notes.forEachAlive((note) ->
		{
			if (note.mustPress && note.canBeHit)
				hitNotes.push(note);
		});

		if (pressed.contains(true))
		{
			notes.forEachAlive((daNote:Note) ->
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.wasGoodHit)
				{
					hitNotes.push(daNote);
					directions.push(daNote.data.data % 4);
				}
			});

			for (shit in 0...pressed.length)
				if (pressed[shit] && !directions.contains(shit) && hitNotes.length > 0)
					noteMiss(shit);

			for (coolNote in hitNotes)
				if (pressed[coolNote.data.data % 4])
					goodNoteHit(coolNote);
		}
	}

	public function beatHit(beat:Float)
	{
		if (!(beat > 0))
			return;
		characterBopper(Std.int(beat));
	}

	inline public function sortNotesByTimeHelper(Order:Int, Obj1:Note, Obj2:Note)
		return FlxSort.byValues(Order, Obj1.data.time, Obj2.data.time);

	public function stepHit(step:Float) {}

	public function sectionHit(section:Float)
	{
		camHUD.zoom += 0.04;
	}

	public dynamic function startCallback()
	{
		startCountdown();
	}

	public dynamic function startCountdown()
	{
		startedCountdown = true;
	}

	public function startSong()
	{
		startedSong = true;

		for (kvIt in tracks.keyValueIterator())
			kvIt.value.play();
	}

	function goodNoteHit(coolNote:Note)
	{
		var strum = getStrum(coolNote.data);

		var _maxTime:Float = coolNote.data.time + coolNote.data.length;
		var _inHoldRange:Bool = coolNote.data.length > 0 && conductor.time < _maxTime - conductor.stepCrochet * 2;

		boyfriend.confirmAnimation(coolNote, !coolNote.wasGoodHit);
		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			// popUpScore(coolNote);
			// health += 0.04;
			strum.playAnim("confirm", true);
		}

		if (coolNote.wasGoodHit && _maxTime < conductor.time)
			invalidateNote(coolNote);
	}
}

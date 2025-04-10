package funkin.states;

import haxe.io.Path;
import funkin.shaders.PixelPerfect;
import openfl.filters.ShaderFilter;
import funkin.gameplay.stages.BaseStage;
import funkin.interfaces.IStageState;
import haxe.io.Bytes;
import funkin.system.backend.chart.LegacyFNFToVanilla;
import moonchart.formats.fnf.legacy.FNFPsych;
import lime.ui.FileDialog;
import openfl.net.FileReference;

class PlayState extends flixel.FlxState implements IStageState
{
	public static var daPixelZoom(default, null):Float = 6;
	public static var isStoryMode:Bool = false;

	public var conductor:Conductor;

	public static var song:SongMap;

	public var tracks:Map<String, FlxSound> = [];
	public var luaArray:Array<LuaScript> = [];

	public var camHUD:FlxCamera;
	public var uiGroup:FlxGroup = new FlxGroup();
	public var plrStrums:StrumLine;
	public var cpuStrums:StrumLine;

	public var startedSong:Bool = false;
	public var startedCountdown:Bool = false;
	public var text:FlxText;

	public var notes:FlxTypedGroup<Note>;
	public var playCpu:Bool = false;

	public var health(default, set):Float = 1;
	public var trackHealth:Float = 1;
	public var downScroll:Bool = false;
	public var stages:Array<BaseStage> = [];

	public function forEachStage(func_:BaseStage->Void):Void
	{
		if (func_ == null)
			return;
		for (i in 0...stages.length)
		{
			var stage:BaseStage = stages[i];
			func_(stage);
		}
	}

	public function addStage(stage:BaseStage)
	{
		if (!stages.contains(stage))
			stages.push(stage);
	}

	public function callOnLuas(name:String, ?args:Array<Any>, ?scriptExclusions:Array<String>, ?returnExclusions:Array<Dynamic>):Any
	{
		scriptExclusions ??= [];
		returnExclusions ??= [];
		args ??= [];
		var returnval = null;
		var arr:Array<LuaScript> = [];

		for (i in luaArray)
		{
			if (i.closed)
			{
				arr.push(i);
				continue;
			}

			if (scriptExclusions.contains(i.scriptName))
				continue;

			var returnVal = i.call(name, args);

			if (returnVal != null && !returnExclusions.contains(returnVal))
				returnval = returnVal;

			if (i.closed)
				arr.push(i);
		}

		if (arr.length > 0)
			for (script in arr)
				luaArray.remove(script);

		return returnval;
	}

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

		var names = [];
		for (scriptName in Paths.readAssetsDirectoryFromLibrary('scripts'))
		{
			if (scriptName.endsWith('.lua') && !names.contains(scriptName))
			{
				var lua:LuaScript = new LuaScript(scriptName, Path.withExtension(scriptName, '.lua'));
				luaArray.push(lua);
			}
		}

		for (i in song.events)
			preloadEvent(i);

		callOnScripts('onCreate');
		parseStage();
		initNotes();
		initChars();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		uiGroup.cameras = [camHUD];
		add(uiGroup);

		cpuStrums = new StrumLine(downScroll);
		uiGroup.add(cpuStrums);

		plrStrums = new StrumLine(downScroll, true);
		uiGroup.add(plrStrums);

		notes = new FlxTypedGroup<Note>();
		uiGroup.add(notes);

		healthBar = new Bar(0, !downScroll ? FlxG.height - 100 : 100, 'healthBar', () ->
		{
			return trackHealth;
		}, 0, 2);
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);
		healthBar.leftToRight = false;
		healthBar.screenCenter(X);
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.json.health_icon, true);
		iconP2 = new HealthIcon(dad.json.health_icon);
		uiGroup.add(iconP1);
		uiGroup.add(iconP2);

		iconP1.y = iconP2.y = healthBar.y - 75;

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

		forEachStage((_) -> _.createPost());
		callOnScripts('onCreatePost');

		startCallback();
	}

	function initNotes()
	{
		for (note in song.notes)
		{
			var oldNote:Note;
			if (unspawnNotes.length > 0)
				oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
			else
				oldNote = null;

			var swagNote:Note = new Note(note, conductor, false, isPixelStage, oldNote);
			unspawnNotes.push(swagNote);

			if (note.length > 0)
				for (sus in 0...Math.floor(note.length / conductor.stepCrochet))
				{
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						unspawnNotes.push(new Note({
							time: note.time + (conductor.stepCrochet * sus) + (conductor.stepCrochet / songSpeed),
							data: note.data,
							type: note.type,
							length: 0
						}, conductor, true, isPixelStage, oldNote));
					}
				}
		}
		unspawnNotes.sort(sortNotesByTimeHelperUnspawn);
	}

	public var lastBpmChangeIndex:Int = 0;
	public var lastNoteIndex:Int = 0;
	public var lastEventIndex:Int = 0;
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

	public var healthBar:Bar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

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

		camFollow = new FlxObject();
		moveCamera('dad');
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		FlxG.camera.snapToTarget();

		add(camFollow);

		openfl.system.System.gc();
	}

	public var curStage:String = "";
	public var defaultCamZoom:Null<Float> = 1.05;
	public var camSPEED:Float = 1;
	public var stageJson:StageFile;

	function parseStage()
	{
		// path ??= "stage";
		if (song.stage == null || song.stage.length < 1)
			song.stage = StageUtil.vanillaSongStage(Paths.formatSongName(song.songName));

		curStage = song.stage;
		if (song.players[1] == null || song.stage.length < 1)
			song.players[1] = StageUtil.vanillaGF(song.stage);

		if (Assets.exists('assets/stages/$curStage.json'))
			stageJson = cast Json.parse(Assets.getText('assets/stages/$curStage.json'));
		else
			stageJson = cast Json.parse(Assets.getText('assets/stages/stage.json'));
		if (stageJson.defaultCamZoom != null)
			defaultCamZoom = stageJson.defaultCamZoom;
		if (stageJson.bfOffsets != null && stageJson.bfOffsets.length > 1)
		{
			BF_X = stageJson.bfOffsets[0];
			BF_Y = stageJson.bfOffsets[1];
		}
		if (stageJson.dadOffsets != null && stageJson.dadOffsets.length > 1)
		{
			DAD_X = stageJson.dadOffsets[0];
			DAD_Y = stageJson.dadOffsets[1];
		}
		if (stageJson.gfOffsets != null && stageJson.gfOffsets.length > 1)
		{
			GF_X = stageJson.gfOffsets[0];
			GF_X = stageJson.gfOffsets[1];
		}
		if (stageJson.cam_bf != null && stageJson.cam_bf.length > 1)
			boyfriendCameraOffset = stageJson.cam_bf;
		if (stageJson.cam_gf != null && stageJson.cam_gf.length > 1)
			girlfriendCameraOffset = stageJson.cam_gf;
		if (stageJson.cam_dad != null && stageJson.cam_dad.length > 1)
			opponentCameraOffset = stageJson.cam_dad;
		if (stageJson.camSPEED != null)
			camSPEED = stageJson.camSPEED;

		isPixelStage = stageJson.isPixel == true;

		switch curStage
		{
			case "stage":
				add(new funkin.gameplay.stages.StageWeek1(this, true));

			case "spooky":
				add(new funkin.gameplay.stages.Spooky(this, true));
			case "school":
				add(new funkin.gameplay.stages.School(this, true));
		}
	}

	public static var instance:PlayState;

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
			if (unspawnNotes[0] != null)
			{
				var time:Float = 3000;
				if (songSpeed < 1)
					time /= songSpeed;

				if (unspawnNotes[0].data.time - conductor.time < time)
				{
					notes.insert(0, unspawnNotes[0]);
					notes.sort(sortNotesByTimeHelper, FlxSort.DESCENDING);
					unspawnNotes.remove(unspawnNotes[0]);
				}
			}
		}

		var multi = 55;

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * multi));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * multi));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		// var center:Float = healthBar.x + healthBar.width * (healthBar.percent / 100);

		var iconOffset:Int = 26;

		iconP1.x = (healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset));
		iconP2.x = (healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset));

		if (healthBar.percent < 20)
		{
			iconP1.animation.curAnim.curFrame = 1;
			iconP2.animation.curAnim.curFrame = iconP2.winningIconFrame;
		}
		else if (healthBar.percent > 80)
		{
			iconP2.animation.curAnim.curFrame = 1;
			iconP1.animation.curAnim.curFrame = iconP1.winningIconFrame;
		}
		else
		{
			iconP2.animation.curAnim.curFrame = 0;
			iconP1.animation.curAnim.curFrame = 0;
		}

		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 6));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 6));
		trackHealth = FlxMath.lerp(health, trackHealth, Math.exp(-elapsed * 8));

		if (song.events[lastEventIndex] != null && song.events[lastEventIndex].time <= conductor.time)
		{
			triggerEvent(song.events[lastEventIndex]);
			lastEventIndex++;
		}

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
				var retVal:Dynamic = callOnLuas('opponentNoteHitPre', [daNote.data.time, daNote.data.data, daNote.data.length, daNote.data.type]);
				if (retVal != LuaScript.FUNCTION_STOP)
				{
					strum.r = conductor.stepCrochet * 1.5 / 1000;
					callOnLuas('opponentNoteHit', [daNote.data.time, daNote.data.data, daNote.data.length, daNote.data.type]);

					dad.confirmAnimation(daNote, !daNote.wasHitByOpponent);
					if (!daNote.wasHitByOpponent)
					{
						strum.playAnim('confirm', true);
						daNote.wasHitByOpponent = true;
					}
					invalidateNote(daNote);
				}
				else
					daNote.wasGoodHit = false;
			}

			if (daNote.tooLate)
			{
				if (daNote.mustPress && !daNote.ignoreNote && !daNote.wasGoodHit && !daNote.missed)
					noteMiss(daNote.data.data % 4);
				daNote.missed = true;
				daNote.multAlpha = 0.6;
			}

			if (conductor.time - daNote.data.time > (350 / song.speed))
			{
				daNote.active = daNote.visible = false;
				invalidateNote(daNote);
			}
		}
		keyShit();
	}

	public var unspawnNotes:Array<Note> = [];

	public function triggerEvent(event:Event)
	{
		if (event == null)
			return;

		switch (event.name)
		{
			case "Camera Focus":
				moveCamera(event.values[0]);
		}
	}

	function noteMiss(i:Int = 0)
	{
		health -= 0.04;
	}

	public function preloadEvent(event:Event) {}

	function invalidateNote(daNote:Note)
	{
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

		if (Controls.instance.justPressed.CHART)
		{
			FlxG.switchState(() -> new ChartingState());
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
		if (beat < 0)
			return;
		for (icon in [iconP1, iconP2])
		{
			icon.scale.set(1.2, 1.2);
			icon.updateHitbox();
		}

		callOnScripts('onBeatHit', [beat]);

		characterBopper(Std.int(beat));
		forEachStage((_) ->
		{
			_.curBeat = beat;
			_.beatHit();
		});
	}

	public function callOnScripts(name:String, ?args:Array<Any>)
	{
		callOnLuas(name, args);
	}

	inline public function sortNotesByTimeHelper(Order:Int, Obj1:Note, Obj2:Note)
		return FlxSort.byValues(Order, Obj1.data.time, Obj2.data.time);

	inline public function sortNotesByTimeHelperUnspawn(Obj1:Note, Obj2:Note)
		return Math.floor(Obj1.data.time - Obj2.data.time);

	public function stepHit(step:Float)
	{
		callOnScripts('onStepHit', [step]);
		forEachStage((_) ->
		{
			_.curStep = step;
			_.stepHit();
		});
	}

	public function sectionHit(section:Float)
	{
		camHUD.zoom += 0.03;
		FlxG.camera.zoom += 0.05;
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
		var retVal:Dynamic = callOnLuas('goodNoteHitPre', [coolNote.data.time, coolNote.data.data, coolNote.data.length, coolNote.data.type]);
		if (retVal == LuaScript.FUNCTION_STOP)
			return;

		var strum = getStrum(coolNote.data);

		var _maxTime:Float = coolNote.data.time + coolNote.data.length;
		var _inHoldRange:Bool = coolNote.data.length > 0 && conductor.time < _maxTime - conductor.stepCrochet * 2;

		boyfriend.confirmAnimation(coolNote, !coolNote.wasGoodHit);
		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			// popUpScore(coolNote);
			health += 0.04;
			strum.playAnim("confirm", true);
		}

		callOnLuas('goodNoteHit', [coolNote.data.time, coolNote.data.data, coolNote.data.length, coolNote.data.type]);
		invalidateNote(coolNote);
	}

	function set_health(value:Float):Float
	{
		value = FlxMath.bound(value, 0, 2);
		health = value;

		return health = value;
	}

	public function moveCamera(target:String = "dad")
	{
		switch (target.toLowerCase())
		{
			case 'dad' | 'opponent':
				if (dad == null)
					return;
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				camFollow.x += dad.camera_position[0] + opponentCameraOffset[0];
				camFollow.y += dad.camera_position[1] + opponentCameraOffset[1];
			case 'gf' | 'girlfriend':
				if (dad == null)
					return;
				camFollow.setPosition(girlfriend.getMidpoint().x + 150, girlfriend.getMidpoint().y - 100);
				camFollow.x += girlfriend.camera_position[0] + girlfriendCameraOffset[0];
				camFollow.y += girlfriend.camera_position[1] + girlfriendCameraOffset[1];
			case 'bf' | 'boyfriend':
				if (boyfriend == null)
					return;

				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
				camFollow.x -= boyfriend.camera_position[0] - boyfriendCameraOffset[0];
				camFollow.y += boyfriend.camera_position[1] + boyfriendCameraOffset[1];
		}
	}
}

@:publicFields
class StageUtil
{
	static function vanillaGF(s:String):String
	{
		trace(s);
		switch (s)
		{
			case "school":
				return "gf-pixel";
			case "schoolEvil":
				return "gf-pixel";
			case 'mall':
				return 'gf-christmas';
			case 'mallEvil':
				return 'gf-christmas';
			case 'spooky':
				return 'gf';
			case 'philly':
				return 'gf';
			case 'limo':
				return 'gf-car';
			case 'tank':
				return 'gf-tankman';
			default:
				return 'gf';
		}
		return 'gf';
	}

	public static function vanillaSongStage(songName):String
	{
		switch (songName)
		{
			case 'spookeez' | 'south' | 'monster':
				return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice':
				return 'philly';
			case 'milf' | 'satin-panties' | 'high':
				return 'limo';
			case 'cocoa' | 'eggnog':
				return 'mall';
			case 'winter-horrorland':
				return 'mallEvil';
			case 'senpai' | 'roses':
				return 'school';
			case 'thorns':
				return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress':
				return 'tank';
			default:
				return 'stage';
		}
		return 'stage';
	}
}

typedef StageFile =
{
	public var bfOffsets:Null<Array<Float>>;
	public var gfOffsets:Null<Array<Float>>;
	public var dadOffsets:Array<Float>;

	public var cam_dad:Null<Array<Float>>;
	public var cam_bf:Null<Array<Float>>;
	public var cam_gf:Null<Array<Float>>;

	public var isPixel:Null<Bool>;
	public var camSPEED:Null<Float>;

	public var defaultCamZoom:Null<Float>;
}

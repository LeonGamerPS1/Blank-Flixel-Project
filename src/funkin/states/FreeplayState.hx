package funkin.states;

import lime.app.Application;

class FreeplayState extends FlxState
{
	public var menuItems:FlxTypedGroup<FreeplayCapsule>;
	public var curSelected:Int = 0;
	public var camFollow:FlxObject;
	public var bf:Character;

	var selected:Bool = false;

	override function create()
	{
		super.create();

		// Initialize camera follow object
		camFollow = new FlxObject(0, 0, 1, 1);
		FlxG.camera.follow(camFollow, LOCKON, 0.15);
		add(camFollow);

		WeekData.init();

		// Setup menu items
		menuItems = new FlxTypedGroup<FreeplayCapsule>();
		add(menuItems);

		var itemIndex = 0;
		for (week in WeekData.weeks)
		{
			for (song in week.songs)
			{
				var capsule = new FreeplayCapsule(song);
				capsule.screenCenter();
				capsule.y += 150 * itemIndex++;
				menuItems.add(capsule);
			}
		}

		// Setup character
		bf = new Character('freeplaybf', true);
		bf.scrollFactor.set();
		bf.playAnim('intro');
		bf.animation.onFinish.add(anim ->
		{
			if (anim == 'intro')
				bf.playAnim('idle');
		});
		add(bf);

		// Apply character position offset
		bf.x += bf.position[0];
		bf.y += bf.position[1];

		// Start selected index adjustments
		change(1, false);
		new FlxTimer().start(0.1, _ -> change(-1, false));
	}

	static inline var sinOffset = 60;
	static inline var baseX = 270;

	override function update(elapsed:Float)
	{
		// Handle input
		if (Controls.instance.justPressed.check(UI_DOWN)
			|| Controls.instance.repeat(0.2).UI_DOWN #if FLX_MOUSE || FlxG.mouse.wheel < 0 #end)
		{
			change(1);
		}
		if (Controls.instance.justPressed.check(UI_UP) || Controls.instance.repeat(0.2).UI_UP #if FLX_MOUSE || FlxG.mouse.wheel > 0 #end)
		{
			change(-1);
		}

		if (Controls.instance.justPressed.check(UI_ACCEPT) && !selected)
		{
			handleAccept();
		}

		super.update(elapsed);

		// Animate capsules

		for (i in 0...menuItems.length)
		{
			final capsule = menuItems.members[i];
			final targetX = baseX + sinOffset * Math.sin(i - curSelected);
			capsule.x = FlxMath.lerp(targetX, capsule.x, Math.exp(-elapsed * 8));

			#if FLX_MOUSE
			final isMouseOver = FlxG.mouse.overlaps(capsule);
			if (isMouseOver)
			{
				capsule.setState(SELECTED);
				if (FlxG.mouse.justPressed)
				{
					curSelected = i;
					change();
				}
			}
			else if (capsule != menuItems.members[curSelected])
			{
				capsule.setState(IDLE);
			}
			#end
		}
	}

	function handleAccept()
	{
		selected = true;
		bf.playAnim('hey');
		FlxG.sound.play(Paths.sound('confirmMenu'));

		bf.animation.onFinish.add(anim ->
		{
			if (anim != 'hey')
				return;

			final songName = menuItems.members[curSelected].songInfo.name;
			final path = 'assets/songs/$songName/default.json';

			if (!Assets.exists(path))
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				Application.current.window.alert('Error: Could not find song file "$path"', 'Error');
				bf.playAnim('idle');
				selected = false;
				return;
			}

			FlxG.sound.music.stop();
			PlayState.song = Song.grabSong(songName);
			FlxG.switchState(() -> new PlayState());
		});
	}

	public function change(i:Int = 0, ?sound:Bool = true)
	{
		if (selected)
			return;

		curSelected = (curSelected + i + menuItems.length) % menuItems.length;

		final curSelect = menuItems.members[curSelected];
		camFollow.setPosition(curSelect.x + curSelect.capsule.width / 2, curSelect.y);

		if (sound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		FlxG.sound.playMusic('assets/songs/${curSelect.songInfo.name}/Inst.ogg', 0.6);

		// Update capsule states
		for (capsule in menuItems)
		{
			capsule.setState(capsule == curSelect ? SELECTED : IDLE);
		}
	}
}

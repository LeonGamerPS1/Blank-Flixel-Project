package funkin.states;

import lime.app.Application;

class FreeplayState extends FlxState
{
	public var menuItems:FlxTypedGroup<FreeplayCapsule>;
	public var curSelected:Int = 0;
	public var camFollow:FlxObject;
	public var bf:Character;

	override function create()
	{
		super.create();
		camFollow = new FlxObject(0, 0, 1, 1);
		FlxG.camera.follow(camFollow, LOCKON, 0.15);
		add(camFollow);
		WeekData.init();

		menuItems = new FlxTypedGroup<FreeplayCapsule>();
		add(menuItems);

		for (week in WeekData.weeks)
		{
			for (song in week.songs)
			{
				var capsule:FreeplayCapsule = new FreeplayCapsule(song);
				capsule.screenCenter();
				capsule.y += 150 * (menuItems.length);
				menuItems.add(capsule);
			}
		}

		bf = new Character('freeplaybf', true);
		bf.scrollFactor.set();
		bf.playAnim('intro');
		bf.animation.onFinish.add((_) ->
		{
			if (_ == 'intro')
				bf.playAnim('idle');
		});
		add(bf);
		var char = bf;
		char.x += char.position[0];
		char.y += char.position[1];

		change(1, false);
		new FlxTimer().start(0.1, (_) -> change(-1, false));
	}

	var selected:Bool = false;

	override function update(elapsed:Float)
	{
		if (Controls.instance.justPressed.check(UI_DOWN)
			|| Controls.instance.repeat(0.2).UI_DOWN #if FLX_MOUSE || FlxG.mouse.wheel < 0 #end)
			change(1);
		if (Controls.instance.justPressed.check(UI_UP) || Controls.instance.repeat(0.2).UI_UP #if FLX_MOUSE || FlxG.mouse.wheel > 0 #end)
			change(-1);
		if (Controls.instance.justPressed.check(UI_ACCEPT) && !selected)
		{
			bf.playAnim('hey');
			FlxG.sound.play(Paths.sound('confirmMenu'));
			selected = true;
			bf.animation.onFinish.add((_:String) ->
			{
				if (_ == 'hey')
				{
					if (!Assets.exists('assets/songs/${menuItems.members[curSelected].songInfo.name}/default.json'))
					{
						FlxG.sound.play(Paths.sound('cancelMenu'));
						Application.current.window.alert('Error: Could not find song file "assets/songs/${menuItems.members[curSelected].songInfo.name}/default.json"',
							'Error');
						bf.playAnim('idle');
						selected = false;
						return;
					}

					FlxG.sound.music.stop();
					PlayState.song = Song.grabSong(menuItems.members[curSelected].songInfo.name);
					FlxG.switchState(() -> new PlayState());
				}
			});
		}
		super.update(elapsed);

		for (capsule in menuItems)
		{
			// capsule.screenCenter(X);
			capsule.x = FlxMath.lerp(270 + (60 * (Math.sin((menuItems.members.indexOf(capsule)) - curSelected))), capsule.x, Math.exp(-elapsed * 8));
			#if FLX_MOUSE
			if (FlxG.mouse.overlaps(capsule))
			{
				capsule.setState(SELECTED);
				if (FlxG.mouse.justPressed)
				{
					curSelected = menuItems.members.indexOf(capsule);
					change();
				}
			}
			else if (!FlxG.mouse.overlaps(capsule) && capsule != menuItems.members[curSelected])
				capsule.setState(IDLE);
			#end
		}
	}

	public function change(i:Int = 0, ?sound:Bool = true)
	{
		if (selected)
			return;
		curSelected += i;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected > menuItems.length - 1)
			curSelected = 0;

		var curSelect = menuItems.members[curSelected];

		camFollow.setPosition(curSelect.x + curSelect.capsule.width / 2, curSelect.y);
		if (sound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		FlxG.sound.playMusic('assets/songs/${curSelect.songInfo.name}/Inst.ogg', 0.6);

		curSelect.setState(SELECTED);
		for (_ in menuItems.keyValueIterator())
		{
			if (_.value != curSelect)
				_.value.setState(IDLE);
		}
	}
}

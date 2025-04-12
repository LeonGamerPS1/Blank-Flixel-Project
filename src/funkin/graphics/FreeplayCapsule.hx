package funkin.graphics;

import funkin.system.backend.WeekData.WSongMeta;
import flixel.tweens.FlxTween;
import flixel.addons.effects.FlxSkewedSprite;

class FreeplayCapsule extends FlxSpriteGroup
{
	public var capsule:FlxSkewedSprite;
	public var songInfo:WSongMeta;
	public var capsuleState:CapsuleState = IDLE;
	public var icon:HealthIcon;
	public var text:FlxText;

	public function new(songInfo:WSongMeta)
	{
		super();
		this.songInfo = songInfo;

		capsule = new FlxSkewedSprite();
		capsule.frames = Paths.getAtlas('freeplay/freeplayCapsule');
		capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
		capsule.animation.addByPrefix('idle', 'mp3 capsule w backing NOT SELECTED0', 24);
		capsule.scale.x = 0.5;
		capsule.scale.y = 0.5;
		capsule.updateHitbox();
		setState();
		add(capsule);

		text = new FlxText(capsule.x + 90, capsule.y + 20, 0, songInfo.name);
		text.clipRect = new FlxRect(0, 0, capsule.width - 20, text.height);
        text.antialiasing = true;
        text.setFormat(Paths.font('vcr'), 13, FlxColor.WHITE,text.alignment);
		add(text);

		icon = new HealthIcon(songInfo.freeplayIcon);
		icon.setPosition(capsule.x + 5, capsule.y - 5);
		icon.scale.set(0.6, 0.6);
		icon.updateHitbox();
		add(icon);
     
        

        antialiasing = true;
	}

	public function setState(state:CapsuleState = SELECTED)
	{
		if (capsuleState != state)
		{
			capsuleState = state;
			capsule.animation.play(Std.string(state).toLowerCase(), true);
			capsule.centerOffsets();
			capsule.centerOrigin();
		}
	}
}

enum abstract CapsuleState(String) from String to String
{
	var IDLE = 'idle';
	var SELECTED = 'selected';
}

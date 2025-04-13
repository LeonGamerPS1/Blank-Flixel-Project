package funkin.graphics;

import funkin.system.backend.WeekData.WSongMeta;
import flixel.tweens.FlxTween;
import flixel.addons.effects.FlxSkewedSprite;

class FreeplayCapsule extends FlxSpriteGroup {
	public var capsule:FlxSkewedSprite;
	public var songInfo:WSongMeta;
	public var capsuleState:CapsuleState = IDLE;
	public var icon:HealthIcon;
	public var text:FlxText;

	public function new(songInfo:WSongMeta) {
		super();
		this.songInfo = songInfo;

		// Setup capsule sprite
		capsule = new FlxSkewedSprite();
		capsule.frames = Paths.getAtlas('freeplay/freeplayCapsule');
		capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
		capsule.animation.addByPrefix('idle', 'mp3 capsule w backing NOT SELECTED0', 24);
		capsule.scale.set(0.5, 0.5);
		capsule.updateHitbox();
		add(capsule);

		// Setup song name text
		text = new FlxText(0, 0, 0, songInfo.name);
		text.setFormat(Paths.font('vcr'), 13, FlxColor.WHITE, LEFT);
		text.antialiasing = true;
		text.clipRect = new FlxRect(0, 0, capsule.width - 20, text.height);
		add(text);

		// Setup icon
		icon = new HealthIcon(songInfo.freeplayIcon);
		icon.scale.set(0.6, 0.6);
		icon.updateHitbox();
		add(icon);

		// Position text and icon relative to capsule
		updatePositions();

		// Antialiasing for whole group
		antialiasing = true;

		setState(IDLE); // default visual state
	}

	public function setState(state:CapsuleState = SELECTED) {
		if (capsuleState == state) return;

		capsuleState = state;
		capsule.animation.play(state, true);
		capsule.centerOffsets();
		capsule.centerOrigin();
	}

	// Helper to position icon and text based on capsule's current position
	private function updatePositions():Void {
		text.setPosition(capsule.x + 90, capsule.y + 20);
		icon.setPosition(capsule.x + 5, capsule.y - 5);
	}
}

enum abstract CapsuleState(String) from String to String {
	public var IDLE = "idle";
	public var SELECTED = "selected";
}

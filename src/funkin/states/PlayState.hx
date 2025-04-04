package funkin.states;

import funkin.system.backend.Song.SongMap;
import flixel.tweens.FlxTween;

class PlayState extends flixel.FlxState {

	public var conductor:Conductor;
	public static var song:SongMap;

	override public function create() { 
		song ??= Song.grabSong();
		super.create();
		conductor = new Conductor(102);
		conductor.time = 2;
	

		 var text = new flixel.text.FlxText(0, 0, 1000, 'Hello Piece of shi-', 30);
		text.active = false;
		text.alignment = 'center';
		text.screenCenter();
		FlxTween.tween(text,{"scale.x":2},1,{type:PINGPONG,onUpdate: (_)->text.updateHitbox()});
		add(text);
	}
}
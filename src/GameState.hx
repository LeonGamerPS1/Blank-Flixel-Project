package;

import flixel.tweens.FlxTween;

class GameState extends flixel.FlxState {

	public var conductor:Conductor;
	override public function create() { 
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
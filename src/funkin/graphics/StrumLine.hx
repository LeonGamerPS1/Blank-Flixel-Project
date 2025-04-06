package funkin.graphics;

class StrumLine extends FlxTypedSpriteGroup<Strum>
{
	public var player:Bool = false;

	public function new(downScroll:Bool = false, ?player:Bool = false)
	{
		var targetX:Float = 50;
		if (player)
			targetX = 50 + (FlxG.width / 2);

		super(targetX, downScroll ? FlxG.height - 150 : 50);
		this.player = player;

		for (i in 0...4)
		{
			var strumNote:Strum = new Strum(i, PlayState.isPixelStage);
			strumNote.downScroll = downScroll;
			strumNote.x += (160 * 0.7) * i;
			add(strumNote);
		}
	}
}

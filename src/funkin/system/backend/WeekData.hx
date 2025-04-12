package funkin.system.backend;

import haxe.io.Path;

class WeekData
{
	public static var weeks:Array<WeekFile> = [];

	public static function init()
	{
		for (path in Paths.readAssetsDirectoryFromLibrary('weeks', 'TEXT'))
		{
			var week = parseWeek(path);
			weeks.push(week);
		}
		weeks.sort((_, __)-> return _.order - __.order);
	}

	/** 
	 * this also is called by PolymodHandler lol ------------------
	 * calls init  but it actually clears the week cache it does so no duplicates exist
	**/
	public static function reload()
	{
		weeks = [];
		init();
	}

	public static function parseWeek(weekName:String):WeekFile
	{
		return cast Json.parse(Assets.getText(weekName));
	}
}

typedef WeekFile =
{
	var weekImage:String;
	var displayText:String;
	var weekBefore:String;

	var startsUnlocked:Bool;
	var order:Int;
	var difficulties:Array<String>;
	var songs:Array<WSongMeta>;
}

typedef WSongMeta =
{
	var name:String;
	var freeplayIcon:String;
	var color:RGBColor;
}

typedef RGBColor = Array<Int>;

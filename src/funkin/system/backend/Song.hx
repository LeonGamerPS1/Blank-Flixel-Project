package funkin.system.backend;

typedef SongMap =
{
	var displayName:String; // name of the song to be displayed
	var players:Array<String>; // dad is first, boyfriend is second and gf is third
	var songName:String; // name of the song

	var speed:Float; // speed of the song
	var bpm:Float; // beats per minute

	var composer:String; // who composed the song
	var charter:String; // who charted the song
	var tracks:Array<String>; // give a full path to the track eg. "songs/yourSong/yourSong.ogg"

	var notes:Array<NoteData>;
	var events:Array<Event>; // events that happen in the song like camera movement, etc
}

typedef NoteData =
{
	var time:Float; // time of the note
	var data:Int; // data of the note
	var length:Float; // length of the note
	var type:String; // type of the note
}

typedef Event =
{
	var time:Float; // time of the event
	var values:Array<Dynamic>;
	var name:String; // name of the event
}

class Song
{
	private static var _cache(default, null):Map<String, SongMap> = new Map<String, SongMap>();

	public static function grabSong(songID:String = "tutorial", jsonName:String = "normal"):SongMap
	{
		var id:String = songID + '-$jsonName';
		if (_cache.exists(id))
			return Reflect.copy(_cache.get(id));
		if (Assets.exists('assets/songs/$songID/$jsonName.json'))
		{
			var json = Json.parse(Assets.getText('assets/songs/$songID/$jsonName.json'));
			_cache.set(id, json);
			return Reflect.copy(json);
		}
		return cast {};
	}
}

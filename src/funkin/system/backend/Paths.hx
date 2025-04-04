package funkin.system.backend;

class Paths
{
	public static var sound_ext(default, null):String = ".ogg";
	public static var image_ext(default, null):String = ".png";
	public static var image_xml_ext(default, null):String = ".xml";
	public static var data_ext(default, null):String = ".json";

	public static var dumpExclusions:Array<String> = [];

	static var currentLevel:String;

	inline static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	inline static public function getLibraryPath(file:String, library = "preload")
	{
		var result = if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
		if (result.contains(':'))
			result = result.split(':')[1];
		return result;
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	public static var bitmapCache:Map<String, FlxGraphic> = new Map();

	inline static public function cacheBitmap(key:String, ?library:String)
	{
		var path = key;
		if (bitmapCache.exists(path))
			return bitmapCache.get(path);
		if (Assets.exists(path))
		{
			var graphic = FlxG.bitmap.add(path);
			var bitmap:BitmapData = graphic.bitmap;
			bitmap.disposeImage();

			graphic.destroyOnNoUse = false;
			graphic.persist = true;
			bitmapCache.set(path, graphic);
			return graphic;
		}
		return null;
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		var result = new String("");
		result = getPath(file, type, library);

		return result;
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('images/$key.txt', TEXT, library);
	}

	inline static public function week(key:String, ?library:String)
	{
		return getPath('weeks/$key.json', TEXT, library);
	}

	inline static public function event(key:String, ?library:String)
	{
		return getPath('events/$key.json', TEXT, library);
	}

	inline static public function video(key:String, ?library:String)
	{
		return getPath('videos/$key.mp4', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		var path = getPath('images/$key.xml', TEXT, library);

		return path;
	}

	inline static public function voices(key:String)
	{
		key = key.toLowerCase();
		key = formatSongName(key);
		return getPath('songs/$key/Voices.ogg', SOUND);
	}

	inline static public function audioStream(key:String)
	{
		var vorbis = VorbisFile.fromFile(key);

		var buffer = AudioBuffer.fromVorbisFile(vorbis);
		return Sound.fromAudioBuffer(buffer);
	}

	inline static public function inst(key:String)
	{
		key = Paths.formatSongName(key.toLowerCase());
		return getPath('songs/$key/Inst.ogg', SOUND);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('songs/$key.json', TEXT, library);
	}

	static public inline function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key$sound_ext', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key$sound_ext', MUSIC, library);
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = new String("");
			levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	public static inline function getText(path:String):String
	{
		return openfl.utils.Assets.getText(path);
	}

	inline public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		return (Assets.exists(getPath(key, type, parentFolder)));
	}

	inline static public function img(key:String, ?library:String):String
	{
		var file:String = "";

		file = getPath('images/$key.png', IMAGE, library);
		return file;
	}

	inline static public function image(key:String, ?library:String, ?allowGPU:Bool = true):Dynamic
	{
		var bitmap = cacheBitmap(img(key), library);

		return bitmap;
	}

	public static inline function getSparrowAtlas(key:String)
	{
		return FlxAtlasFrames.fromSparrow(image('$key'), xml('$key'));
	}

	public static function getAtlas(key:String)
	{
		if (Assets.exists(txt(key)))
			return getPackerAtlas(key);
		if (Assets.exists(xml('$key')))
			return getSparrowAtlas(key);

		return getSparrowAtlas(key);
	}

	inline static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded = image(key, library, allowGPU);

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath('images/$key.txt', TEXT));
	}

	public static inline function getFlxAnimatePath(key:String)
	{
		return getPath('images/$key', TEXT);
	}

	inline static public function newsvoices(key:String, variation:String = "")
	{
		key = key.toLowerCase();
		return getPath('songs/$key/Voices${variation != "" ? '-$variation' : ""}.ogg', SOUND);
	}

	static var shaderContentCache:Map<String, String> = new Map();

	inline public static function shaderFrag(key:String)
	{
		var path = getPath('shaders/$key.frag', TEXT);
		if (shaderContentCache.exists(key))
			return shaderContentCache.get(key);
		if (OpenFlAssets.exists(path))
		{
			final cont = OpenFlAssets.getText(path);
			shaderContentCache.set(path, cont);
			return cont;
		}

		return null;
	}

	inline public static function formatSongName(s:String):String
	{
		return s.toLowerCase().replace(" ", "-");
	}

	inline static public function font(key:String, ?library:String):String
	{
		var file:String = "";

		file = getPath('fonts/$key.ttf', FONT, library);
		return file;
	}

	inline static public function fontotf(key:String, ?library:String):String
	{
		var file:String = "";

		file = getPath('fonts/$key.otf', FONT, library);
		return file;
	}

	public static function atlas(character:String)
	{
		var file:String = "";

		file = getPath('images/$character/spritemap1.png', IMAGE);

		return file;
	}

	public static function atlasPure(character:String)
	{
		var file:String = "";

		file = getPath('images/$character', IMAGE);
		return file;
	}
}

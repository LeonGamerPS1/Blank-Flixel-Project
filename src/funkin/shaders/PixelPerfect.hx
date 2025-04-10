package funkin.shaders;

class PixelPerfect extends flixel.system.FlxAssets.FlxShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float scale;
		
		vec4 pixelColor(vec2 coord)
		{
			return texture2D(bitmap, coord / openfl_TextureSize);
		}
		
		vec4 bigPixelCenterColor(vec2 coord)
		{
			return pixelColor(coord + vec2(1 / 2.0, 1 / 2.0));
		}
		
		vec2 bigPixelTopLeft(vec2 coord)
		{
			return vec2(coord.x - mod(coord.x, scale), coord.y - mod(coord.y, scale));
		}
		
		void main()
		{
			vec2 topLeft = bigPixelTopLeft(openfl_TextureCoordv * openfl_TextureSize);
			gl_FragColor = bigPixelCenterColor(topLeft);
		}
	')
	
	public function new(scale:Float)
	{
		super();
		this.scale.value = [scale];
	}
}
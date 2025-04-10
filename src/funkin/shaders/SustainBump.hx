package funkin.shaders;

import flixel.addons.display.FlxRuntimeShader;

class SustainBump extends FlxRuntimeShader
{
	@:isVar public var downScroll(default, set):Bool = false;
	@:isVar public var yCorrection(default, set):Float = 0;
	@:isVar public var force(default, set):Float = 0;

	public function new()
	{
		super('#pragma header
uniform float force;
uniform bool downScroll;
uniform float yCorrection;
vec2 uv = openfl_TextureCoordv.xy;
void main(){
    float gwa = downScroll ? 1. : 0.;
    gl_FragColor = flixel_texture2D(bitmap, vec2(uv.x+sin((uv.y-gwa-yCorrection)*6.)*((uv.y-gwa+yCorrection)*2.*force), uv.y));
}');
	}

	function set_force(value:Float)
	{
		setFloat('force', value);
		return force = value;
	}

	

	function set_yCorrection(value:Float)
	{
		setFloat('yCorrection', value);
		return yCorrection = value;
	}


	function set_downScroll(value:Bool):Bool
	{
		setBool('downScroll', value);
		return downScroll = value;
	}


}

package;

import flixel.FlxG;
import openfl.display.BitmapData;
import flixel.FlxSprite;
import lime.utils.Assets;
import lime.system.System;
import flixel.graphics.FlxGraphic;
import tjson.TJSON;
using StringTools;
import flash.display.BlendMode;
import flixel.tweens.FlxEase;
import openfl.filters.ColorMatrixFilter;

class CoolUtil
{
	public static var fps:Int = 60;
	// hxs, like kotlin's kts
	public static final HSCRIPT_EXT:Array<String> = ['hscript', 'hxs'];
	public static final JSON_EXT:Array<String> = ['json', 'jsonc'];
	public static var directionArray:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	public static var holdAnimationFix:Bool = true;
	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = FNFAssets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function coolDynamicTextFile(path:String):Array<String>
		return coolTextFile(path);
	inline public static function boundTo(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));
	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}
	public static function clamp(mini:Float, maxi:Float, value:Float):Float
		return Math.min(Math.max(mini,value), maxi);
	// can either return an array or a dynamic
	public static function parseJson(json:String):Dynamic
		return TJSON.parse(json);
	public static function stringifyJson(json:Dynamic, ?fancy:Bool = true):String {
		// use tjson to prettify it
		var style:String = if (fancy) 'fancy' else null;
		return TJSON.encode(json,style);
	}
	// include all helper functions to keep shit in the same place
	public static function truncateFloat(number:Float, precision:Int):Float
		return HelperFunctions.truncateFloat(number, precision);
	public static function erf(x:Float):Float
		return HelperFunctions.erf(x);
	public static function getNotes():Int
		return HelperFunctions.getNotes();
	public static function getHolds():Int
		return HelperFunctions.getHolds();
	public static function getMapMaxScore():Int
		return HelperFunctions.getMapMaxScore();
	public static function wife3(maxms:Float, ts:Float)
		return HelperFunctions.wife3(maxms, ts);
	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}
	public static function getFilter(filterName:String, ?customArray:Array<Float>) {
		var daFilter = switch(filterName.toLowerCase()) {
			case 'grayscale' | 'monochrome' | 'blackandwhite':
				new ColorMatrixFilter(
					[0.5, 0.5, 0.5, 0, 0,
					0.5, 0.5, 0.5, 0, 0,
					0.5, 0.5, 0.5, 0, 0,
					0, 0, 0, 1, 0]
				);
			case 'invert' | 'negative':
				new ColorMatrixFilter(
					[-1, 0, 0, 0, 255,
					 0, -1, 0, 0, 255,
					 0, 0, -1, 0, 255,
					 0, 0, 0, 1, 0]
				);
			case 'deuteranopia' | 'deuter':
				new ColorMatrixFilter(
					[0.43, 0.72, -.15, 0, 0,
					0.34, 0.57, 0.09, 0, 0,
					-.02, 0.03, 1, 0, 0,
					0, 0, 0, 1, 0]
				);
			case 'protanopia' | 'prot':
				new ColorMatrixFilter(
					[0.20, 0.99, -.19, 0, 0,
					0.16, 0.79, 0.04, 0, 0,
					0.01, -.01, 1, 0, 0,
					0, 0, 0, 1, 0]
				);
			case 'tritanopia' | 'trit':
				new ColorMatrixFilter(
					[0.97, 0.11, -.08, 0, 0,
					0.02, 0.82, 0.16, 0, 0,
					0.06, 0.88, 0.18, 0, 0,
					0, 0, 0, 1, 0]
				);
			case 'blank' | 'normal' | 'default':
				new ColorMatrixFilter(
					[1, 0, 0, 0, 0,
					0, 1, 0, 0, 0,
					0, 0, 1, 0, 0,
					0, 0, 0, 1, 0]
				);
			case 'custom':
				if (customArray != null)
					new ColorMatrixFilter(customArray);
				else
					null;
			default:
				null;
		}
		return daFilter;
	}

	//i think its easier??
	public static function getMoveEase(name:String):Float->Float
	{
		return switch(name.trim().toLowerCase())
		{
			case 'linear': FlxEase.linear;
			case 'quadin': FlxEase.quadIn;
			case 'quadout': FlxEase.quadOut;
			case 'quadinout': FlxEase.quadInOut;
			case 'cubein': FlxEase.cubeIn;
			case 'cubeout': FlxEase.cubeOut;
			case 'cubeinout': FlxEase.cubeInOut;
			case 'quartin': FlxEase.quartIn;
			case 'quartout': FlxEase.quartOut;
			case 'quartinout': FlxEase.quartInOut;
			case 'quintin': FlxEase.quintIn;
			case 'quintout': FlxEase.quintOut;
			case 'quintinout': FlxEase.quintInOut;
			case 'sinein': FlxEase.sineIn;
			case 'sineout': FlxEase.sineOut;
			case 'sineinout': FlxEase.sineInOut;
			case 'expoin': FlxEase.expoIn;
			case 'expoout': FlxEase.expoOut;
			case 'expoinout': FlxEase.expoInOut;
			case 'circin': FlxEase.circIn;
			case 'circout': FlxEase.circOut;
			case 'circinout': FlxEase.circInOut;
			case 'elasticin': FlxEase.elasticIn;
			case 'elasticout': FlxEase.elasticOut;
			case 'elasticinout': FlxEase.elasticInOut;
			case 'backin': FlxEase.backIn;
			case 'backout': FlxEase.backOut;
			case 'backinout': FlxEase.backInOut;
			case 'bouncein': FlxEase.bounceIn;
			case 'bounceout': FlxEase.bounceOut;
			case 'bounceinout': FlxEase.bounceInOut;
			case 'smoothstepin': FlxEase.smoothStepIn;
			case 'smoothstepout': FlxEase.smoothStepOut;
			case 'smoothstepinout': FlxEase.smoothStepInOut;
			default: FlxEase.linear;
		}
	}

	public static function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
			case 'normal': return NORMAL;
		}
		return NORMAL;
	}
}

class FlxTools {
	// Load a graphic and ensure it exists
	static public function loadGraphicDynamic(s:FlxSprite, path:String, animated:Bool=false, width:Int=0, height:Int=0, unique:Bool=false, ?key:String):FlxSprite {
		var sus:BitmapData = FNFAssets.getBitmapData(path);
		s.loadGraphic(sus,animated,width,height,unique,key);
		return s;
	}
}
package;

import flash.display.BitmapData;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;
import lime.system.System;
import DynamicSprite.DynamicAtlasFrames;
using StringTools;

#if sys
import flash.media.Sound;
import haxe.io.Path;
import lime.media.AudioBuffer;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;
#end


class EdtNote extends FlxSprite
{
	public var mustBeUpdated:Bool = false;
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var duoMode:Bool = false;
	public var oppMode:Bool = false;
	public var sustainLength:Float = 0;

	public var funnyMode:Bool = false;
	public var noteScore:Float = 1;
	public var altNote:Bool = false;
	public var altNum:Int = 0;
	public var isPixel:Bool = false;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';
	public var eventVal3:String = '';

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;
	public static var NOTE_AMOUNT:Int = 4;

	public var rating = "miss";
	public var isLiftNote:Bool = false;
	public var mineNote:Bool = false;
	public var healMultiplier:Float = 1;
	public var damageMultiplier:Float = 1;
	// Whether to always do the same amount of healing for hitting and the same amount of damage for missing notes
	public var consistentHealth:Bool = false;
	// How relatively hard it is to hit the note. Lower numbers are harder, with 0 being literally impossible
	public var timingMultiplier:Float = 1;
	// whether to play the sing animation for hitting this note
	public var shouldBeSung:Bool = true;
	public var ignoreHealthMods:Bool = false;
	public var nukeNote = false;
	public var drainNote = false;

	static var coolCustomGraphics:Array<FlxGraphic> = [];

	static var COLORS:Array<String> = [
		"purple", "blue", "green", "red",
		"white", "yellow", "lila", "cherry", "cyan"
	];

	static var NOTE_MAP = [
		4 => ["purpleScroll","blueScroll","greenScroll","redScroll"],
		6 => ["purpleScroll","greenScroll","redScroll","yellowScroll","blueScroll","cyanScroll"],
		7 => ["purpleScroll","greenScroll","redScroll","whiteScroll","yellowScroll","blueScroll","cyanScroll"],
		9 => ["purpleScroll","greenScroll","blueScroll","redScroll","whiteScroll","yellowScroll","lilaScroll","cherryScroll","cyanScroll"]
	];

	public function new(strumTime:Float, noteData:Int, ?LiftNote:Bool = false)
	{
		super();

		var mania = PlayState.SONG.mania;
		NOTE_AMOUNT = Main.ammo[mania];

		isLiftNote = LiftNote;
		if (isLiftNote) shouldBeSung = false;

		x += 50;
		y -= 2000;

		this.strumTime = strumTime;
		this.noteData = noteData % 8;

		var sussy:Bool = false;

		if (noteData > -1)
		{
			var band = Std.int(noteData / NOTE_AMOUNT);

			mineNote  = band == 2 || band == 3;
			if (!isLiftNote && (band == 4 || band == 5))
				isLiftNote = true;
			nukeNote = band == 6 || band == 7;
			drainNote = band == 8 || band == 9;
			sussy = band >= 10;
			frames = DynamicAtlasFrames.fromSparrow(
				SUtil.getPath() + 'assets/images/custom_ui/ui_packs/normal/NOTE_assets.png',
				SUtil.getPath() + 'assets/images/custom_ui/ui_packs/normal/NOTE_assets.xml'
			);

			if (sussy)
			{
				var sussyInfo = Math.floor(noteData / (NOTE_AMOUNT * 2)) - 5;
				if (coolCustomGraphics[sussyInfo] == null)
					coolCustomGraphics[sussyInfo] =
						FlxGraphic.fromAssetKey(SUtil.getPath() + 'assets/images/custom_ui/ui_packs/normal/NOTE_assets.png', true);

				frames = FlxAtlasFrames.fromSparrow(
					coolCustomGraphics[sussyInfo],
					SUtil.getPath() + 'assets/images/custom_ui/ui_packs/normal/NOTE_assets.xml'
				);
			}
			addAnimations("0");

			if (isLiftNote) addAnimations(" lift");
			else if (nukeNote) addAnimations(" nuke");
			else if (mineNote) addAnimations(" mine");

			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			antialiasing = true;
			var idx = noteData % NOTE_AMOUNT;
			var animList = NOTE_MAP.get(NOTE_AMOUNT);

			if (animList != null && idx < animList.length)
			{
				x += swagWidth * idx;
				animation.play(animList[idx]);
			}
			if (noteData >= NOTE_AMOUNT * 10)
			{
				var sussyInfo = Math.floor(noteData / (NOTE_AMOUNT * 2)) - 4;
				var text = new FlxText(0, 0, 0, cast sussyInfo, 64);
				stamp(text, Std.int(width / 2), 20);
			}
		}
	}

	inline function addAnimations(suffix:String)
	{
		for (c in COLORS)
		{
			var name = c + "Scroll";
			var prefix = c + suffix;

			if (animation.getByName(name) == null)
				animation.addByPrefix(name, prefix);
		}
	}
}

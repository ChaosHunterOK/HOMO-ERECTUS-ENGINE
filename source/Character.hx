package;

import hscript.Expr;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import hscript.Interp;
import hscript.ParserEx;
import haxe.xml.Parser;
import hscript.InterpEx;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flash.display.BitmapData;
import lime.utils.Assets;
import flixel.FlxG;
import lime.system.System;
import lime.app.Application;
import flixel.system.FlxSound;
import openfl.utils.AssetType;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
#end
import haxe.Json;
import tjson.TJSON;
import haxe.format.JsonParser;
import FNFAssets.Extensions;
using StringTools;
enum abstract EpicLevel(Int) from Int to Int {
	var Level_NotAHoe = 0;
	var Level_Boogie = 1;
	var Level_Sadness = 2;
	var Level_Sing = 3;

	@:op(A > B) static function gt(a:EpicLevel, b:EpicLevel):Bool;
	@:op(A >= B) static function gte(a:EpicLevel, b:EpicLevel):Bool;
	@:op(A == B) static function equals(a:EpicLevel, b:EpicLevel):Bool;
	@:op(A != B) static function nequals(a:EpicLevel, b:EpicLevel):Bool;
	@:op(A < B) static function lt(a:EpicLevel, b:EpicLevel):Bool;
	@:op(A <= B) static function lte(a:EpicLevel, b:EpicLevel):Bool;
}
typedef TCharacterRefJson = {
	var like:String;
	var icons:Array<Int>;
	var ?colors:Array<String>;
}
class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var animOffsets2:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var useOtherOffsets:Bool = false;
	public var curCharacter:String = 'bf';
	public var altAnim:String = "";
	public var altNum:Int = 0;
	public var enemyOffsetX:Int = 0;
	public var enemyOffsetY:Int = 0;
	public var playerOffsetX:Int = 0;
	public var playerOffsetY:Int = 0;
	public var camOffsetX:Int = 0;
	public var camOffsetY:Int = 0;
	public var followCamX:Int = 150;
	public var followCamY:Int = -100;
	public var midpointX:Int = 0;
	public var midpointY:Int = 0;
	public var isCustom:Bool = false;
	public var holdTimer:Float = 0;
	public var sustainLock:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var like:String = "bf";
	public var beNormal:Bool = true;
	public var forceColor:Bool = false;
	public var syncFrames:Bool = false;

	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var idleSuffix:String = '';

	public var animationLoops:Map<String, Bool>;
    public var singDuration:Float = 4;
    public var danceSteps:Int = 2;
	public var instantIdleOnSingEnd:Bool = false;

	//Extra parameters for more fun!
	public var paramA:Int = 0;
	public var paramB:Int = 0;
	public var paramC:Int = 0;
	public var canSing:Bool = true;
	public var noSkipGOver:Bool = false;

	public var freezeFrame:Int = 10;
	public var isFreezing:Bool = false;
	/**
	 * Color used by default for enemy, when not in duo mode or oppnt play.
	 */
	public var enemyColor:FlxColor = 0xFFFF0000;
	/**
	 * Color used by default for enemy in duo mode and oppnt play.
	 */
	public var opponentColor:FlxColor = 0xFFE7C53C;
	/**
	 * Color used by player while not in duo mode or oppnt play.
	 */
	public var playerColor:FlxColor = 0xFF66FF33;
	/**
	 * Color used by player when poisoned in fragile funkin.
	 */
	public var poisonColor:FlxColor = 0xFFA22CD1;
	/**
	 * Color used by enemy when poisoned in fragile funkin. 
	 */
	public var poisonColorEnemy:FlxColor = 0xFFEA2FFF;
	/**
	 * Color used by player in duo mode or oppnt play.
	 */
	public var bfColor:FlxColor = 0xFF149DFF;
	/**
	 * Color used for the Cross Fades ;3.
	 */
	public var crossFadeColor:FlxColor = 0xFF00FFFF;
	// sits on speakers, replaces gf
	public var likeGf:Bool = false;
	// uses animation notes
	public var hasGun:Bool = false;
	public var stunned(get, default):Bool = false;
	public var beingControlled:Bool = false;
	/**
	 * how many animations our current gf supports. 
	 * acts like a level meter, 0 means we aren't gf,
	 * 1 means we support the least animations (i think pixel-gf)
	 * 2 means we support the middle amount of animations (i think gf-tankmen)
	 * 3 means we support the full amount of animations (regular gf)
	 * you can have an epic level lower than your actual animations, 
	 * but the game will be safe and act like you don't have one.
	 */
	public var gfEpicLevel:EpicLevel = Level_NotAHoe;
	// like bf, is playable
	public var likeBf:Bool = false;
	public var isDie:Bool = false;
	public var isPixel:Bool = false;
	private var interp:Interp;
	function get_stunned():Bool {
		if (OptionsHandler.options.useMissStun){
			return stunned;
		}
		return false;
	}
	function callInterp(func_name:String, args:Array<Dynamic>) {
		if (interp == null) return;
		if (!interp.variables.exists(func_name)) return;
		var method = interp.variables.get(func_name);
		switch (args.length)
		{
			case 0:
				method();
			case 1:
				method(args[0]);
			case 2:
				method(args[0], args[1]);
		}
	}
	function mixtex(frames1:FlxAtlasFrames, frames2:FlxAtlasFrames) {
		for (frame in frames2.frames){
			frames1.pushFrame(frame);
		}
		return frames1;
	}
	/* coming soon flipping offsets
	public function flipChar(animRef:String = "idle"):Void
	{
		playAnim(animRef);
		var widthCenter = frameWidth;
		flipX = !flipX;
		for (anim => offsets in animOffsets)
		{
			var daAnim = animOffsets.get(anim);
			var daOffX = daAnim[0];
			daAnim[0] = widthCenter - daOffX * -1;
			animOffsets.set(anim, daAnim);
		}
	}
	*/
	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		animOffsets = new Map<String, Array<Dynamic>>();
		animOffsets2 = new Map<String, Array<Dynamic>>();
		animationLoops = new Map<String, Bool>();
		super(x, y);

		curCharacter = character;
		this.isPlayer = isPlayer;

		var tex:FlxAtlasFrames;
		antialiasing = true;

		curCharacter = curCharacter.trim();
		trace(curCharacter);
		isCustom = true;
		if (StringTools.endsWith(curCharacter, "-dead"))
		{
			isDie = true;
			curCharacter = curCharacter.substr(0, curCharacter.length - 5);
		}
		trace(curCharacter);
		var charJson:Dynamic = null;
		var isError:Bool = false;
		charJson = CoolUtil.parseJson(FNFAssets.getJson(SUtil.getPath() + 'assets/images/custom_chars/custom_chars'));
		interp = Character.getAnimInterp(curCharacter);
		callInterp("init", [this]);
		dance();

		if (isPlayer)
		{
			flipX = !flipX;
			// Doesn't flip for BF, since his are already in the right place???
			if (!likeBf && !isDie)
			{
				// var animArray
				var oldRight = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldRight;

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}
		}
	}
	public function sing(direction:Int, ?miss:Bool = false, ?alt:Int = 0)
	{
		holdTimer = 0;

		var directions = ["LEFT", "DOWN", "UP", "RIGHT"];
		var maniaMap:Map<Int, Array<Int>> = [
			6 => [0, 2, 3, 0, 1, 3], 
			7 => [0, 2, 3, 2, 0, 1, 3],
			9 => [0, 1, 2, 3, 2, 0, 1, 2, 3]
		];

		var ammo = Main.ammo[PlayState.mania];
		var dirIdx = directions[direction];

		if (maniaMap.exists(ammo))
			dirIdx = directions[maniaMap.get(ammo)[direction]];

		var baseAnim:String = "sing" + dirIdx;
		var animToPlay:String = baseAnim;

		// Miss anims
		if (miss)
		{
			if (animation.getByName(baseAnim + "miss") != null)
				animToPlay = baseAnim + "miss";

			if (forceColor)
				color = 0xCFAFFF;
		}
		else if (forceColor)
		{
			color = FlxColor.WHITE;
		}
		if (!miss && alt > 0)
		{
			var altSuffix = (alt == 1) ? "-alt" : "-" + alt + "alt";
			var altAnim = baseAnim + altSuffix;

			if (animation.getByName(altAnim) != null)
				animToPlay = altAnim;
		}

		if (canSing)
			playAnim(animToPlay, true);
	}
	override function update(elapsed:Float)
    {
        if(!debugMode && animation.curAnim != null)
        {
            if (animationLoops.exists(animation.curAnim.name)) {
                var shouldLoop:Bool = animationLoops.get(animation.curAnim.name);
                if (animation.curAnim.looped != shouldLoop) {
                    animation.play(animation.curAnim.name, false, false, animation.curAnim.curFrame);
                }
            }

            if(heyTimer > 0)
            {
                heyTimer -= elapsed;
                if(heyTimer <= 0)
                {
                    if(specialAnim && (animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer'))
                    {
                        specialAnim = false;
                        dance();
                    }
                    heyTimer = 0;
                }
            } 
            else if(specialAnim && animation.curAnim.finished)
            {
                specialAnim = false;
                dance();
            }
			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
				if (instantIdleOnSingEnd && animation.curAnim.finished)
				{
					dance();
					holdTimer = 0;
				}
			}

			var shouldLock:Bool = beingControlled && sustainLock;
			if (!shouldLock)
			{
				if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001)
				{
					dance();
					holdTimer = 0;
				}
			}
            if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
            {
                dance();
                animation.finish();
            }

            if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
                playAnim('deathLoop');
        }
        
        if (hasGun) {
            if (0 < animationNotes.length && Conductor.songPosition > animationNotes[0][0]) {
                var idkWhatThisISLol = (2 <= animationNotes[0][1]) ? 3 : 1;
                idkWhatThisISLol += FlxG.random.int(0, 1);
                playAnim("shoot" + idkWhatThisISLol, true);
                animationNotes.shift();
            }
        }

        callInterp("update", [elapsed, this]);
        super.update(elapsed);
    }

	private var danced:Bool = false;
	public function dance()
    {
        if (!debugMode && !specialAnim)
        {
            holdTimer = 0;

            if (interp != null)
                callInterp("dance", [this]);
            else
                playAnim('idle' + idleSuffix);

            if (color != FlxColor.WHITE && forceColor)
            {
                color = FlxColor.WHITE;
            }
        }
    }

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		var forcedLoop:Bool = false;
		if (animationLoops.exists(AnimName)) {
			forcedLoop = animationLoops.get(AnimName);
		}

		if (!syncFrames)
			animation.play(AnimName, Force, Reversed, Frame);
		else {
			var frame = (animation.curAnim != null) ? animation.curAnim.curFrame : 0;
			animation.play(AnimName, Force, Reversed, frame);
		}

		if (animation.curAnim != null && forcedLoop) {
			animation.curAnim.paused = false; 
			if (animation.curAnim.finished) animation.curAnim.restart();
		}

		var animName = "";
		if (animation.curAnim == null) {
			if (isDie)
				animName = "firstDeath";
			else
				animName = "idle";
			trace("dead");
		} else {
			// kalm
			animName = animation.curAnim.name;
		}

		if (!useOtherOffsets)
		{
			if (animOffsets.exists(animName))
			{
				var daOffset = animOffsets.get(animName);
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);
		}
		else
		{
			if (animOffsets2.exists(animName))
			{
				var daOffset = animOffsets2.get(animName);
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);
		}

		// should spooky be on this?
		if (likeGf)
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}
	public function loadMappedAnims() {
		// todo, make better
		var picoAnims = Song.loadFromJson(curCharacter, PlayState.SONG.song).notes;
		for (anim in picoAnims) {
			// this code looks fucking awful because I am reading the compiled
			// html build
			for (note in anim.sectionNotes) {
				animationNotes.push(note);
			}
		} 
		animationNotes.sort(sortAnims);
	}
	function sortAnims(a, b) {
		var aThing = a[0];
		var bThing = b[0];
		return aThing < bThing ? -1 : 1;
	}
	public function addOffset(name:String, x:Float = 0, y:Float = 0, ?isMain:Bool = true)
	{
		if (isMain == true)
			animOffsets[name] = [x, y];
		else
			animOffsets2[name] = [x, y];
	}
	public function addLoop(name:String, shouldLoop:Bool = true)
    {
        animationLoops[name] = shouldLoop;
    }
	public static function getAnimInterp(char:String):Interp {
		var interp = PluginManager.createSimpleInterp();
		var parser = new hscript.Parser();
		var charJson = CoolUtil.parseJson(FNFAssets.getJson(SUtil.getPath() + 'assets/images/custom_chars/custom_chars'));
		var program:Expr;
		if (FNFAssets.exists(SUtil.getPath() + 'assets/images/custom_chars/' + Reflect.field(charJson, char).like, Hscript))
			program = parser.parseString(FNFAssets.getHscript(SUtil.getPath() + 'assets/images/custom_chars/' + Reflect.field(charJson, char).like));
		else
			program = parser.parseString(FNFAssets.getText(SUtil.getPath() + 'assets/images/custom_chars/jsonbased.hscript'));
		if (!FNFAssets.exists(SUtil.getPath() + 'assets/images/custom_chars/' + Reflect.field(charJson, char).like, Hscript)) 
			interp.variables.set("charJson", CoolUtil.parseJson(FNFAssets.getJson(SUtil.getPath() + 'assets/images/custom_chars/'+Reflect.field(charJson, char).like)));
		else
			interp.variables.set("charJson", {});
		interp.variables.set("hscriptPath", SUtil.getPath() + 'assets/images/custom_chars/' + char + '/');
		interp.variables.set("charName", char);
		interp.variables.set("Level_NotAHoe", Level_NotAHoe);
		interp.variables.set("Level_Boogie", Level_Boogie);
		interp.variables.set("Level_Sadness", Level_Sadness);
		interp.variables.set("Level_Sing", Level_Sing);
		interp.variables.set("portraitOffset", [0, 0]);
		interp.variables.set("dadVar", 4.0);
		interp.variables.set("isPixel", false);
		interp.variables.set("colors", [FlxColor.CYAN]);
		interp.execute(program);
		trace(interp);
		return interp;
	}
}

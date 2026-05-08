package;

import DynamicSprite.DynamicAtlasFrames;
import Judgement.TUI;
import flixel.animation.FlxAnimationController;
import openfl.errors.Error;
import flixel.util.typeLimit.OneOfTwo;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import lime.system.System;
import flixel.graphics.FlxGraphic;
import flash.display.BitmapData;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
#end
using StringTools;
enum abstract Direction(Int) from Int to Int {
	var left = 0;
	var down = 1;
	var up = 2;
	var right = 3;
}

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String,
	value3:String
}

typedef NoteInfo = {
	var animNames:Array<String>;
	var animInt:Array<Null<Int>>;
	var ?healAmount:Null<Float>;
	var ?damageAmount:Null<Float>;
	var ?shouldSing:Null<Bool>;
	var ?healMultiplier:Null<Float>;
	var ?damageMultiplier:Null<Float>;
	var ?consistentHealth:Null<Bool>;
	var ?healCutoff:Null<String>;
	var ?timingMultiplier:Null<Float>;
	var ?ignoreHealthMods:Null<Bool>;
	var ?dontCountNote:Null<Bool>;
	var ?dontStrum:Null<Bool>;
	var ?dontMiss:Null<Bool>;
	var ?singInfo:Null<SingInfo>;
	var ?classes:Null<Array<String>>;
	var ?id:Null<String>;
	var ?customNotePath:Null<String>;
}

typedef SingInfo = {
	var direction:Int;
	var ?alt:Null<Int>;
	var ?miss:Null<Bool>;
}
class Note extends DynamicSprite
{
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red', 'white', 'yellow', 'lila', 'cherry', 'cyan'];
	public static var maniaData:Array<Array<Int>> = [
		[0, 1, 2, 3],
		[0, 2, 3, 5, 1, 8],
		[0, 2, 3, 4, 5, 1, 8],
		[0, 1, 2, 3, 4, 5, 6, 7, 8]
	];
	public var strumTime:Float = 0;
	public static var getFrames:Bool = true;
	static var gotFrames:FlxAtlasFrames = null;
	public static var getSpecialFrames:Bool = true;
	static var specialFramesKey:Array<String> = [];
	static var gotSpecialFrames:Array<FlxAtlasFrames> = [];
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var duoMode:Bool = false;
	public var oppMode:Bool = false;
	public var copyAngle:Bool = false;
	public var sustainLength:Float = 0;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var alphaMultiplier:Float = 1;
	public var isSustainNote:Bool = false;
	public var modifiedByLua:Bool = false;
	public var funnyMode:Bool = false;
	public var noteScore:Float = 1;
	public var altNote:Bool = false;
	public var crossFade:Bool = false;
	public var altNum:Int = 0;
	public var dontMiss:Bool = false;
	public var isPixel:Bool = false;
	public static var swagWidth:Float = 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;
	public static var NOTE_AMOUNT:Int = 4;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';
	public var eventVal3:String = '';

	public static var specialNoteJson:Null<Array<NoteInfo>>;
	public var damageAmount:Null<Float> = null;
	public var healAmount:Null<Float> = null;
	public var dontEdit:Bool = false;
	public var rating = "miss";
	public var isLiftNote:Bool = false;
	public var mineNote:Bool = false;
	public var specialSinger:Null<Character> = null;
	public var nukeNote:Bool = false;
	public var drainNote:Bool =  false;
	public var healMultiplier:Float = 1;
	public var damageMultiplier:Float = 1;
	public var consistentHealth:Bool = false;
	public var timingMultiplier:Float = 1;
	public var shouldBeSung:Bool = true;
	public var hittedNote:Bool = false;
	public var ignoreHealthMods:Bool = false;
	public var healCutoff:Null<String>;
	var specialNoteInfo:NoteInfo;
	public var dontCountNote = false;
	public var dontStrum = false;
	public var oppntAnim:Null<String> = null;
	public var classes:Null<Array<String>> = [];
	public var coolId:Null<String> = null;
	public var oppntSing:Null<SingInfo>;
	public var customNotePath:Null<String> = null;
	public static var scales:Array<Float> = [0.7, 0.6, 0.55, 0.46];
	public static var pixelscales:Array<Float> = [1, 0.9, 0.85, 0.76];
	public static var swidths:Array<Float> = [160, 120, 110, 90];
	public static var posRest:Array<Int> = [0, 35, 50, 70];
	public var sustainScale:Float = 1;
	public var isHoldEnd:Bool = false;
	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var mania = PlayState.SONG.mania;

	public function getSustainScale():Float {
		var num = !isPixel ? 1.05 : PlayState.daPixelZoom * 1.25;
		return (Conductor.stepCrochet / 100) * num * PlayState.instance.daScrollSpeed;
	}
	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?customImage:Null<BitmapData>, ?customXml:Null<String>, ?customEnds:Null<BitmapData>, ?LiftNote:Bool=false, ?animSuffix:String, ?numSuffix:Int)
	{
		super();
		if (prevNote == null) prevNote = this;
		
		NOTE_AMOUNT = Main.ammo[mania];

		this.prevNote = prevNote;
		this.isSustainNote = sustainNote;
		this.isLiftNote = LiftNote;
		this.strumTime = strumTime;
		x += (42 + 50) - posRest[mania];
		y -= 2000;

		this.noteData = noteData % NOTE_AMOUNT;
		if (noteData >= NOTE_AMOUNT * 2) {
			if (noteData < NOTE_AMOUNT * 4) mineNote = true;
			else if (noteData < NOTE_AMOUNT * 6) isLiftNote = true;
			else if (noteData < NOTE_AMOUNT * 8) nukeNote = true;
			else if (noteData < NOTE_AMOUNT * 10) drainNote = true;
			else if (specialNoteJson != null) {
				setupSpecialNote(noteData);
			}
		}

		if (mineNote || nukeNote) {
			shouldBeSung = false;
			dontCountNote = true;
			dontStrum = true;
		}
		if (isLiftNote) shouldBeSung = false;

		var curUiType:TUI = Reflect.field(Judgement.uiJson, PlayState.SONG.uiType);
		this.isPixel = curUiType.isPixel;

		if (!isPixel) {	
			handleSparrowAssets(curUiType, animSuffix);
		} else {
			handlePixelAssets(curUiType, animSuffix, numSuffix);
		}
		x += swidths[mania] * swagWidth * (this.noteData % NOTE_AMOUNT);
		var animToPlay:Int = getAnimID(mania);
		animation.play(colArray[animToPlay] + 'Scroll');
		if (isSustainNote && prevNote != null)
		{
			if (OptionsHandler.options.downscroll) flipY = true;
			offsetX += width / 2;
			animation.play(colArray[animToPlay] + 'holdend');
			updateHitbox();
			offsetX -= width / 2;
			if (isPixel) offsetX += 30;
			if (prevNote.isSustainNote)
			{
				var prevAnimID = prevNote.getAnimID(mania);
				prevNote.animation.play(colArray[prevAnimID] + 'hold');
				prevNote.scale.y = prevNote.getSustainScale();
				prevNote.updateHitbox();
				isHoldEnd = true;
			}
		}
		x += offsetX;
	}

	private function setupSpecialNote(noteData:Int):Void {
		var sussyNoteThing = Math.floor(noteData / (NOTE_AMOUNT * 2)) - 5;
		var thingie = specialNoteJson[sussyNoteThing];
		if (thingie == null) return;

		dontEdit = true;
		specialNoteInfo = thingie;
		
		if (thingie.damageAmount != null) damageAmount = thingie.damageAmount;
		if (thingie.damageMultiplier != null) damageMultiplier = thingie.damageMultiplier;
		if (thingie.healAmount != null) healAmount = thingie.healAmount;
		if (thingie.healMultiplier != null) healMultiplier = thingie.healMultiplier;
		if (thingie.shouldSing != null) shouldBeSung = thingie.shouldSing;
		if (thingie.consistentHealth != null) consistentHealth = thingie.consistentHealth;
		if (thingie.dontCountNote != null) dontCountNote = thingie.dontCountNote;
		if (thingie.healCutoff != null) healCutoff = thingie.healCutoff;
		if (thingie.timingMultiplier != null) timingMultiplier = thingie.timingMultiplier;
		if (thingie.dontStrum != null) dontStrum = thingie.dontStrum;
		if (thingie.classes != null) classes = thingie.classes;
		if (thingie.id != null) coolId = thingie.id;
		if (thingie.dontMiss != null) dontMiss = thingie.dontMiss;
		if (thingie.customNotePath != null) customNotePath = thingie.customNotePath;
		
		if (healAmount < 0 || healMultiplier < 0) dontCountNote = true;
		
		if (thingie.singInfo != null) {
			oppntSing = thingie.singInfo;
			if (oppntSing.alt == null) oppntSing.alt = 0;
			if (oppntSing.miss == null) oppntSing.miss = false;
		}
		ignoreHealthMods = thingie.ignoreHealthMods == true;
	}

	private function handleSparrowAssets(curUiType:TUI, animSuffix:String):Void {
		if (customNotePath != null) {
			if (getSpecialFrames) {
				getSpecialFrames = false;
				specialFramesKey = [];
				gotSpecialFrames = [];
			}
			var funnyNum = specialFramesKey.indexOf(customNotePath);
			if (funnyNum == -1) {
				var daFrames = DynamicAtlasFrames.fromSparrow(customNotePath + '.png', customNotePath + '.xml');
				specialFramesKey.push(customNotePath);
				gotSpecialFrames.push(daFrames);
				funnyNum = specialFramesKey.length - 1;
			}
			frames = gotSpecialFrames[funnyNum];
		} else {
			if (getFrames) {
				getFrames = false;
				gotFrames = DynamicAtlasFrames.fromSparrow('assets/images/custom_ui/ui_packs/${curUiType.uses}/NOTE_assets.png',
					'assets/images/custom_ui/ui_packs/${curUiType.uses}/NOTE_assets.xml');
			}
			frames = gotFrames;
		}

		var suffix:String = (animSuffix == null) ? '' : ' ' + animSuffix;
		loadNoteAnims(suffix);
		
		if (!isSustainNote)
			setGraphicSize(Std.int(width * scales[mania]));
		else
			setGraphicSize(Std.int(width * scales[mania]), Std.int(height * scales[0]));

		updateHitbox();
		antialiasing = true;
	}

	public static function resetNotePosition(note:Note, ?targetX:Null<Float> = null, ?targetY:Null<Float> = null):Void {
        if (note == null) return;

        var mania = PlayState.SONG.mania;
        var ammo = Main.ammo[mania];
        var baseX:Float = (42 + 50) - Note.posRest[mania];
        baseX += Note.swidths[mania] * Note.swagWidth * (note.noteData % ammo);
        baseX += note.offsetX;
        note.x = baseX + (targetX != null ? targetX : 0);
        
        if (targetY != null) {
            note.y = targetY;
        }

        note.updateHitbox();
    }

	private function handlePixelAssets(curUiType:TUI, animSuffix:String, numSuffix:Null<Int>):Void {
		var pixelPath = (customNotePath != null) ? customNotePath : 'assets/images/custom_ui/ui_packs/${curUiType.uses}/arrows-pixels';
		loadGraphic(pixelPath + '.png', true, 17, 17);
		
		if (animSuffix != null && numSuffix == null) numSuffix = Std.parseInt(animSuffix);

		if (numSuffix != null) {
			for (col in colArray) animation.add(col + 'Scroll', [numSuffix]);
			if (isSustainNote) {
				loadGraphic('assets/images/custom_ui/ui_packs/${curUiType.uses}/arrowEnds.png', true, 7, 6);
				for (col in colArray) {
					animation.add(col + 'holdend', [numSuffix]);
					animation.add(col + 'hold', [numSuffix]);
				}
			}
		} else {
			// Standard Pixel Anims
			var pixelInd:Array<Int> = [4, 5, 6, 7, 52, 36, 37, 38, 39]; // purp, blue, green, red, white, yellow, lila, cherry, cyan
			for (i in 0...colArray.length) animation.add(colArray[i] + 'Scroll', [pixelInd[i]]);

			if (isSustainNote) {
				loadGraphic('assets/images/custom_ui/ui_packs/${curUiType.uses}/arrowEnds.png', true, 7, 6);
				var holdEndInd:Array<Int> = [4, 5, 6, 7, 20, 12, 13, 14, 15];
				var holdInd:Array<Int> = [0, 1, 2, 3, 16, 8, 9, 10, 11];
				for (i in 0...colArray.length) {
					animation.add(colArray[i] + 'holdend', [holdEndInd[i]]);
					animation.add(colArray[i] + 'hold', [holdInd[i]]);
				}
			}
			
			if (isLiftNote) {
				animation.add('purpleScroll', [20]); animation.add('blueScroll', [21]);
				animation.add('greenScroll', [22]); animation.add('redScroll', [23]);
			}
			if (mineNote) {
				var mineInd = [24, 25, 26, 27, 26, 24, 25, 26, 27];
				for (i in 0...colArray.length) animation.add(colArray[i] + 'Scroll', [mineInd[i]]);
			}
			if (nukeNote) {
				var nukeInd = [28, 29, 30, 31, 30, 28, 29, 30, 31];
				for (i in 0...colArray.length) animation.add(colArray[i] + 'Scroll', [nukeInd[i]]);
			}
		}

		if (dontEdit && specialNoteInfo.animInt != null) 
		{
			var totalAnims = specialNoteInfo.animInt.length;
			for (i in 0...colArray.length) 
			{
				if (i < totalAnims) 
				{
					animation.add(colArray[i] + 'Scroll', [specialNoteInfo.animInt[i]]);
				}
			}
		}
		
		setGraphicSize(Std.int(width * PlayState.daPixelZoom * pixelscales[PlayState.SONG.mania]));
		updateHitbox();
		antialiasing = false;
	}

	private function getAnimID(mania:Int):Int {
		var maniaIdx:Int = 0;
		if (NOTE_AMOUNT == 6) maniaIdx = 1;
		else if (NOTE_AMOUNT == 7) maniaIdx = 2;
		else if (NOTE_AMOUNT == 9) maniaIdx = 3;
		
		return maniaData[maniaIdx][noteData % NOTE_AMOUNT];
	}

	function loadNoteAnims(?animSuffix:String)
	{
		animation.addByPrefix('greenScroll', 'green${animSuffix}0');
		animation.addByPrefix('redScroll', 'red${animSuffix}0');
		animation.addByPrefix('blueScroll', 'blue${animSuffix}0');
		animation.addByPrefix('purpleScroll', 'purple${animSuffix}0');
		animation.addByPrefix('whiteScroll', 'white${animSuffix}0');
		animation.addByPrefix('yellowScroll', 'yellow${animSuffix}0');
		animation.addByPrefix('lilaScroll', 'lila${animSuffix}0');
		animation.addByPrefix('cherryScroll', 'cherry${animSuffix}0');
		animation.addByPrefix('cyanScroll', 'cyan${animSuffix}0');

		if (animation.getByName('whiteScroll') == null)
			animation.addByPrefix('whiteScroll', 'green${animSuffix}0');

		if (animation.getByName('yellowScroll') == null)
			animation.addByPrefix('yellowScroll', 'purple${animSuffix}0');

		if (animation.getByName('lilaScroll') == null)
			animation.addByPrefix('lilaScroll', 'blue${animSuffix}0');

		if (animation.getByName('cherryScroll') == null)
			animation.addByPrefix('cherryScroll', 'green${animSuffix}0');

		if (animation.getByName('cyanScroll') == null)
			animation.addByPrefix('cyanScroll', 'red${animSuffix}0');

		if (isSustainNote)
		{
			animation.addByPrefix('purpleholdend', 'pruple end hold${animSuffix}');
			animation.addByPrefix('greenholdend', 'green hold end${animSuffix}');
			animation.addByPrefix('redholdend', 'red hold end${animSuffix}');
			animation.addByPrefix('blueholdend', 'blue hold end${animSuffix}');
			animation.addByPrefix('whiteholdend', 'white hold end${animSuffix}');
			animation.addByPrefix('yellowholdend', 'yellow hold end${animSuffix}');
			animation.addByPrefix('lilaholdend', 'lila hold end${animSuffix}');
			animation.addByPrefix('cherryholdend', 'cherry hold end${animSuffix}');
			animation.addByPrefix('cyanholdend', 'cyan hold end${animSuffix}');

			if (animation.getByName('whiteholdend') == null)
				animation.addByPrefix('whiteholdend', 'green hold end${animSuffix}');
	
			if (animation.getByName('yellowholdend') == null)
				animation.addByPrefix('yellowholdend', 'pruple hold end${animSuffix}');
	
			if (animation.getByName('lilaholdend') == null)
				animation.addByPrefix('lilaholdend', 'blue hold end${animSuffix}');
	
			if (animation.getByName('cherryholdend') == null)
				animation.addByPrefix('cherryholdend', 'green hold end${animSuffix}');
	
			if (animation.getByName('cyanholdend') == null)
				animation.addByPrefix('cyanholdend', 'red hold end${animSuffix}');

			animation.addByPrefix('purplehold', 'purple hold piece${animSuffix}');
			animation.addByPrefix('greenhold', 'green hold piece${animSuffix}');
			animation.addByPrefix('redhold', 'red hold piece${animSuffix}');
			animation.addByPrefix('bluehold', 'blue hold piece${animSuffix}');
			animation.addByPrefix('whitehold', 'white hold piece${animSuffix}');
			animation.addByPrefix('yellowhold', 'yellow hold piece${animSuffix}');
			animation.addByPrefix('lilahold', 'lila hold piece${animSuffix}');
			animation.addByPrefix('cherryhold', 'cherry hold piece${animSuffix}');
			animation.addByPrefix('cyanhold', 'cyan hold piece${animSuffix}');

			if (animation.getByName('whitehold') == null)
				animation.addByPrefix('whitehold', 'green hold piece${animSuffix}');
	
			if (animation.getByName('yellowhold') == null)
				animation.addByPrefix('yellowhold', 'pruple hold piece${animSuffix}');
	
			if (animation.getByName('lilahold') == null)
				animation.addByPrefix('lilahold', 'blue hold piece${animSuffix}');
	
			if (animation.getByName('cherryhold') == null)
				animation.addByPrefix('cherryhold', 'green hold piece${animSuffix}');
	
			if (animation.getByName('cyanhold') == null)
				animation.addByPrefix('cyanhold', 'red hold piece${animSuffix}');
		}

		if (isLiftNote)
		{
			animation.addByPrefix('greenScroll', 'green lift${animSuffix}');
			animation.addByPrefix('redScroll', 'red lift${animSuffix}');
			animation.addByPrefix('blueScroll', 'blue lift${animSuffix}');
			animation.addByPrefix('purpleScroll', 'purple lift${animSuffix}');
			animation.addByPrefix('whiteScroll', 'white lift${animSuffix}');
			animation.addByPrefix('yellowScroll', 'yellow lift${animSuffix}');
			animation.addByPrefix('lilaScroll', 'lila lift${animSuffix}');
			animation.addByPrefix('cherryScroll', 'cherry lift${animSuffix}');
			animation.addByPrefix('cyanScroll', 'cyan lift${animSuffix}');
			if (animation.getByName('whiteScroll') == null)
				animation.addByPrefix('whiteScroll', 'green lift${animSuffix}');
	
			if (animation.getByName('yellowScroll') == null)
				animation.addByPrefix('yellowScroll', 'purple lift${animSuffix}');
	
			if (animation.getByName('lilaScroll') == null)
				animation.addByPrefix('lilaScroll', 'blue lift${animSuffix}');
	
			if (animation.getByName('cherryScroll') == null)
				animation.addByPrefix('cherryScroll', 'green lift${animSuffix}');
	
			if (animation.getByName('cyanScroll') == null)
				animation.addByPrefix('cyanScroll', 'purple lift${animSuffix}');
		}
		if (nukeNote)
		{
			animation.addByPrefix('greenScroll', 'green nuke${animSuffix}');
			animation.addByPrefix('redScroll', 'red nuke${animSuffix}');
			animation.addByPrefix('blueScroll', 'blue nuke${animSuffix}');
			animation.addByPrefix('purpleScroll', 'purple nuke${animSuffix}');
			animation.addByPrefix('whiteScroll', 'white nuke${animSuffix}');
			animation.addByPrefix('yellowScroll', 'yellow nuke${animSuffix}');
			animation.addByPrefix('lilaScroll', 'lila nuke${animSuffix}');
			animation.addByPrefix('cherryScroll', 'cherry nuke${animSuffix}');
			animation.addByPrefix('cyanScroll', 'cyan nuke${animSuffix}');

			if (animation.getByName('whiteScroll') == null)
				animation.addByPrefix('whiteScroll', 'green nuke${animSuffix}');
	
			if (animation.getByName('yellowScroll') == null)
				animation.addByPrefix('yellowScroll', 'purple nuke${animSuffix}');
	
			if (animation.getByName('lilaScroll') == null)
				animation.addByPrefix('lilaScroll', 'blue nuke${animSuffix}');
	
			if (animation.getByName('cherryScroll') == null)
				animation.addByPrefix('cherryScroll', 'green nuke${animSuffix}');
	
			if (animation.getByName('cyanScroll') == null)
				animation.addByPrefix('cyanScroll', 'purple nuke${animSuffix}');
		}
		
		if (mineNote)
		{
			animation.addByPrefix('greenScroll', 'green mine${animSuffix}');
			animation.addByPrefix('redScroll', 'red mine${animSuffix}');
			animation.addByPrefix('blueScroll', 'blue mine${animSuffix}');
			animation.addByPrefix('purpleScroll', 'purple mine${animSuffix}');
			animation.addByPrefix('whiteScroll', 'white mine${animSuffix}');
			animation.addByPrefix('yellowScroll', 'yellow mine${animSuffix}');
			animation.addByPrefix('lilaScroll', 'lila mine${animSuffix}');
			animation.addByPrefix('cherryScroll', 'cherry mine${animSuffix}');
			animation.addByPrefix('cyanScroll', 'cyan mine${animSuffix}');
			if (animation.getByName('whiteScroll') == null)
				animation.addByPrefix('whiteScroll', 'green mine${animSuffix}');
	
			if (animation.getByName('yellowScroll') == null)
				animation.addByPrefix('yellowScroll', 'purple mine${animSuffix}');
	
			if (animation.getByName('lilaScroll') == null)
				animation.addByPrefix('lilaScroll', 'blue mine${animSuffix}');
	
			if (animation.getByName('cherryScroll') == null)
				animation.addByPrefix('cherryScroll', 'green mine${animSuffix}');
	
			if (animation.getByName('cyanScroll') == null)
				animation.addByPrefix('cyanScroll', 'purple mine${animSuffix}');
		}
		if (dontEdit) {
			animation.addByPrefix('greenScroll', specialNoteInfo.animNames[2]);
			animation.addByPrefix('redScroll', specialNoteInfo.animNames[3]);
			animation.addByPrefix('purpleScroll', specialNoteInfo.animNames[0]);
			animation.addByPrefix('blueScroll', specialNoteInfo.animNames[1]);
			animation.addByPrefix('whiteScroll', specialNoteInfo.animNames[4]);
			animation.addByPrefix('yellowScroll', specialNoteInfo.animNames[5]);
			animation.addByPrefix('lilaScroll', specialNoteInfo.animNames[6]);
			animation.addByPrefix('cherryScroll', specialNoteInfo.animNames[7]);
			animation.addByPrefix('cyanScroll', specialNoteInfo.animNames[8]);
		}
	}

	public function reloadSkin():Void
	{
		var curUiType:TUI = Reflect.field(Judgement.uiJson, PlayState.SONG.uiType);
		this.isPixel = curUiType.isPixel;
		animation = new FlxAnimationController(this);

		if (isPixel)
		{
			handlePixelAssets(curUiType, null, null);
		}
		else
		{
			Note.getFrames = true;
			handleSparrowAssets(curUiType, null);
		}

		var animToPlay = getAnimID(mania);
		if (isSustainNote)
		{
			if (prevNote != null && prevNote.isSustainNote)
			{
				animation.play(colArray[animToPlay] + 'holdend');
				prevNote.animation.play(colArray[animToPlay] + 'hold');
			}
			else
			{
				animation.play(colArray[animToPlay] + 'holdend');
			}
		}
		else
		{
			var animName = colArray[animToPlay] + 'Scroll';
			if (animation.getByName(animName) != null)
				animation.play(animName);
			else
				animation.play('purpleScroll');
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if ((((mustPress && !oppMode) || duoMode) || (oppMode && !mustPress)) && !funnyMode)
		{
			var signedDiff = Conductor.songPosition - strumTime;
			var noteDiff = Math.abs(signedDiff);
			if (noteDiff < Judge.wayoffJudge * timingMultiplier)
			{
				canBeHit = true;
			}
			else
				canBeHit = false;
			if (nukeNote && !(noteDiff < Judge.badJudge * timingMultiplier)) {
				canBeHit = false;
			}
			if (mineNote && !(noteDiff < Judge.shitJudge * timingMultiplier))
			{
				canBeHit = false;
			}
			if (signedDiff > Judge.wayoffJudge)
				tooLate = true;
			if (nukeNote && signedDiff > Judge.badJudge) {
				tooLate = true;
			}
			if (mineNote && signedDiff > Judge.shitJudge) {
				tooLate = true;
			}
		}
		else
		{
			if (!dontStrum) {
				canBeHit = false;

				if (strumTime <= Conductor.songPosition)
				{
					wasGoodHit = true;
				}
			}
			
		}

		if (tooLate)
		{
			alpha = Math.min(alpha, 0.3 * alphaMultiplier);
		}
	}
	public inline function daStrumTime():Float {
		return strumTime + OptionsHandler.options.offset;
	}
	public static inline function getTrueStrumTime(strumTime:Float):Float {
		return strumTime + OptionsHandler.options.offset;
	}
	public function getHealth(rating:String):Float {
		if (mineNote) {
			if (rating != 'miss') {
				return -0.45;
			} else {
				return 0;
			}
		}
		if (nukeNote) {
			if (rating != 'miss')
				return -69;
			else
				return 0;
		}
		if (consistentHealth)
		{
			var ouchie = false;
			switch (healCutoff)
			{
				case 'shit':
					ouchie = rating == 'shit' || rating == 'wayoff' || rating == 'miss';
				case 'wayoff':
					ouchie = rating == 'wayoff' || rating == 'miss';
				case 'miss':
					ouchie = rating == 'miss';
				case 'bad' | null:
					ouchie = rating == 'shit' || rating == 'wayoff' || rating == 'bad' || rating == 'miss';
				case 'good':
					ouchie = rating == 'shit' || rating == 'wayoff' || rating == 'bad' || rating == 'miss' || rating == 'good';
				case 'sick':
					ouchie = true;
				case 'none':
					ouchie = false;
			}
			if (ouchie)
			{
				if (damageAmount != null)
				{
					return damageAmount * (ignoreHealthMods ? 1 : PlayState.healthLossMultiplier);
				}
				else
				{
					return damageMultiplier * -0.04 * (ignoreHealthMods ? 1 : PlayState.healthLossMultiplier);
				}
			}
			else
			{
				if (healAmount != null)
				{
					return healAmount * (ignoreHealthMods ? 1 : PlayState.healthGainMultiplier);
				}
				else
				{
					return healMultiplier * (ignoreHealthMods ? 1 : PlayState.healthGainMultiplier) * 0.04;
				}
			}
		} else {
			var healies = 0.0;
			var shitHeal = OptionsHandler.options.useKadeHealth ? 0.2 : 0.06;
			var badHeal = OptionsHandler.options.useKadeHealth ? 0.06 : 0.03;
			var goodHeal = OptionsHandler.options.useKadeHealth ? 0.04  : 0.03;
			var missHeal = 0.04;
			var sickHeal = OptionsHandler.options.useKadeHealth ? 0.1 : 0.07;
			switch (healCutoff) {
				case "shit":
					switch (rating) {
						case "shit" | 'wayoff':
							healies = -shitHeal;
						case "bad":
							healies = badHeal;
						case "good":
							healies = goodHeal;
						case "miss":
							
							healies = -missHeal;
						case "sick":
							healies = sickHeal;
					}
				case "bad" | null: 
					switch (rating)
					{
						case "shit" | 'wayoff':
							healies = -shitHeal;
						case "bad":
							healies = -badHeal;
						case "good":
							healies = goodHeal;
						case "miss":
							healies = -missHeal;
						case "sick":
							healies = sickHeal;
					}
				case "good": 
					switch (rating)
					{
						case "shit" | 'wayoff':
							healies = -shitHeal;
						case "bad":
							healies = -badHeal;
						case "good":
							healies = -goodHeal;
						case "miss":
							healies = -missHeal;
						case "sick":
							healies = sickHeal;
					}
				case "wayoff":
					switch (rating)
					{
						case "shit":
							healies = shitHeal;
						case 'wayoff': 
							healies = -shitHeal;
						case "bad":
							healies = badHeal;
						case "good":
							healies = goodHeal;
						case "miss":
							healies = -missHeal;
						case "sick":
							healies = sickHeal;
					}
				case "miss":
					switch (rating)
					{
						case "shit" | 'wayoff':
							healies = shitHeal;
						case "bad":
							healies = badHeal;
						case "good":
							healies = goodHeal;
						case "miss":
							healies = -missHeal;
						case "sick":
							healies = sickHeal;
					}

				case "sick":
					switch (rating)
					{
						case "shit" | 'wayoff':
							healies = -shitHeal;
						case "bad":
							healies = -badHeal;
						case "good":
							healies = -goodHeal;
						case "miss":
							healies = -missHeal;
						case "sick":
							healies = -sickHeal;
					}
			}
			if (healies > 0) {
				if (healAmount != null) {
					return healAmount * (ignoreHealthMods ? 1 : PlayState.healthGainMultiplier);
				} else {
					return healMultiplier * healies * (ignoreHealthMods ? 1 : PlayState.healthGainMultiplier);

				}

			} else {
				if (damageAmount != null)
				{
					return damageAmount * (ignoreHealthMods ? 1 : PlayState.healthLossMultiplier);
				}
				else
				{
					return damageMultiplier * healies * (ignoreHealthMods ? 1 : PlayState.healthLossMultiplier);
				}
			}
		}
	}
}
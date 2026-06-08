package;

import openfl.media.Sound;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;
import flixel.FlxSprite;
import lime.media.AudioBuffer;
import Section.SwagSection;
import Song.SwagSong;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSprite;
import flash.geom.Rectangle;
import haxe.io.Bytes;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.FlxObject;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import lime.system.System;
import flixel.util.FlxSort;
import lime.system.Clipboard;
import flixel.math.FlxRect;
#if sys
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
import tjson.TJSON;
#end

import hscript.InterpEx;
import hscript.Interp;
import hscript.Parser;
import hscript.ParserEx;
import hscript.ClassDeclEx;

using StringTools;
#if mobile
import flixel.input.actions.FlxActionInput;
import android.AndroidControls.AndroidControls;
import android.FlxVirtualPad;
#end
enum abstract NoteTypes(Int) from Int to Int
{
	@:op(A == B) static function _(_, _):Bool;

	var Normal;
	var Lift;
	var Mine;
	var Death;
}

class ChartingState extends MusicBeatState
{
	public static var lastSection:Int = 0;

	var hscriptStates:Map<String, Interp> = [];
	var exInterp:InterpEx = new InterpEx();
	var haxeSprites:Map<String, FlxSprite> = [];

	#if debug
		var debugTarget = true;
	#else
		var debugTarget = false;
	#end

	#if sys
		var sysTarget = true;
	#else
		var sysTarget = false;
	#end

	function callHscript(func_name:String, args:Array<Dynamic>, usehaxe:String) {
		// if function doesn't exist
			try{
		if (!hscriptStates.get(usehaxe).variables.exists(func_name)) {
			trace("Function doesn't exist, silently skipping...");
			return;
		}
		var method = hscriptStates.get(usehaxe).variables.get(func_name);
		switch(args.length) {
			case 0:
				method();
			case 1:
				method(args[0]);
			case 2:
				method(args[0], args[1]);
			case 3:
				method(args[0], args[1], args[2]);
			case 4:
				method(args[0], args[1], args[2], args[3]);
			case 5:
				method(args[0], args[1], args[2], args[3], args[4]);
			case 6:
				method(args[0], args[1], args[2], args[3], args[4], args[5]);
			case 7:
				method(args[0], args[1], args[2], args[3], args[4], args[5], args[6]);
			case 8:
				method(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]);
		}
	}
	catch(e){
		openfl.Lib.application.window.alert(e.message, "your function had some problem...");
	}
}
	function callAllHScript(func_name:String, args:Array<Dynamic>) {
		for (key in hscriptStates.keys()) {
			callHscript(func_name, args, key);
		}
	}
	function setHaxeVar(name:String, value:Dynamic, usehaxe:String) {
		try{
		hscriptStates.get(usehaxe).variables.set(name,value);
		}
		catch(e){
			openfl.Lib.application.window.alert(e.message, "your variable had some problem...");
		}
	}
	function getHaxeVar(name:String, usehaxe:String):Dynamic {
		var theValue = hscriptStates.get(usehaxe).variables.get(name);
		return theValue;
	}
	function setAllHaxeVar(name:String, value:Dynamic) {
		for (key in hscriptStates.keys())
			setHaxeVar(name, value, key);
	}
	function makeHaxeState(usehaxe:String, path:String, filename:String) {
		trace("opening a haxe state (because we are cool :))");
		var parser = new ParserEx();
		var program = parser.parseString(FNFAssets.getHscript(path + filename));
		var interp = PluginManager.createSimpleInterp();
		// set vars
		interp.variables.set("FlxTextBorderStyle", FlxTextBorderStyle);
		interp.variables.set("MainMenuState", MainMenuState);
		interp.variables.set("CategoryState", CategoryState);
		interp.variables.set("ChartingState", ChartingState);
		interp.variables.set("lastSection", lastSection);
		interp.variables.set("Alphabet", Alphabet);
		interp.variables.set("instance", this);
		interp.variables.set("add", add);
		interp.variables.set("remove", remove);
		interp.variables.set("insert", insert);
        interp.variables.set("FlxRect", FlxRect);
		interp.variables.set("replace", replace);
		interp.variables.set("generateWaveform", generateWaveform);
		interp.variables.set("calculateSectionDuration", calculateSectionDuration);
		interp.variables.set("calculateSectionTimings", calculateSectionTimings);
		interp.variables.set("generateSectionWaveform", generateSectionWaveform);
		interp.variables.set("generateAllSectionWaveforms", generateAllSectionWaveforms);
		interp.variables.set("pi", Math.PI);
		interp.variables.set("curMusicName", Main.curMusicName);
		interp.variables.set("Highscore", Highscore);
		interp.variables.set("HealthIcon", HealthIcon);
		interp.variables.set("debugTarget", debugTarget);
		interp.variables.set("StoryMenuState", StoryMenuState);
		interp.variables.set("FreeplayState", FreeplayState);
		interp.variables.set("CreditsState", CreditsState);
		interp.variables.set("SaveDataState", SaveDataState);
		interp.variables.set("DifficultyIcons", DifficultyIcons);
		interp.variables.set("Controls", Controls);
		interp.variables.set("Tooltip", Tooltip);
		interp.variables.set("SongInfoPanel", SongInfoPanel);
		interp.variables.set("DifficultyManager", DifficultyManager);
		interp.variables.set("flixelSave", FlxG.save);
		interp.variables.set("Record", Record);
		interp.variables.set("Math", Math);
		interp.variables.set("Song", Song);
		interp.variables.set("ModifierState", ModifierState);
        interp.variables.set("ChooseCharState", ChooseCharState);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("colorFromString", FlxColor.fromString);
		interp.variables.set("PlayState", PlayState);
		interp.variables.set("NewCharacterState", NewCharacterState);
		interp.variables.set("NewStageState", NewStageState);
		interp.variables.set("NewSongState", NewSongState);
		interp.variables.set("NewWeekState", NewWeekState);
		interp.variables.set("SelectSortState", SelectSortState);
		interp.variables.set("CategoryState", CategoryState);
		interp.variables.set("ControlsState", ControlsState);
		interp.variables.set("NumberDisplay", NumberDisplay);
		interp.variables.set("controls", controls);
		interp.variables.set("ModifierState", ModifierState);
		interp.variables.set("SortState", SortState);
		interp.variables.set("FlxObject", FlxObject);
		interp.variables.set("Ratings", Ratings);
		interp.variables.set("VictoryLoopState", VictoryLoopState);
		interp.variables.set("FlxTypedGroup", FlxTypedGroup);
		interp.variables.set("EdtNote", EdtNote);
		interp.variables.set("FlixG", FlxG);
		interp.variables.set("FlxUITabMenu", FlxUITabMenu);
		interp.variables.set("FlxUICheckBox", FlxUICheckBox);
		interp.variables.set("FlxUIDropDownMenuCustom", FlxUIDropDownMenuCustom);
		interp.variables.set("FlxUIInputText", FlxUIInputText);
		interp.variables.set("FlxButton", FlxButton);
		interp.variables.set("Prompt", Prompt);
		interp.variables.set("FlxUINumericStepper", FlxUINumericStepper);
		interp.variables.set("FlxUI", FlxUI);
		interp.variables.set("sysTarget", sysTarget);
		interp.variables.set("FlxSound", FlxSound);
		interp.variables.set("Normal", Normal);
		interp.variables.set("Lift", Lift);
		interp.variables.set("Mine", Mine);
		interp.variables.set("Death", Death);
		interp.variables.set("FlxGridOverlay", FlxGridOverlay);
		interp.variables.set("FlxSort", FlxSort);
		interp.variables.set("AttachedFlxText", AttachedFlxText);
		interp.variables.set("Json", Json);
		interp.variables.set("isNumericStepper", isNumericStepper);
		interp.variables.set("isInputText", isInputText);
		interp.variables.set("Section", Section);
		interp.variables.set("Map", haxe.ds.StringMap);
		interp.variables.set("getStepperTextField", getStepperTextField);
		interp.variables.set("createDefaultTabMenu", createDefaultTabMenu);
		interp.variables.set("openSubState", openSubState);
		interp.variables.set("curStep", curStep);
		interp.variables.set("curBeat", curBeat);
		interp.variables.set("checkBoxEvent", FlxUICheckBox.CLICK_EVENT);
		interp.variables.set("numericStepperEvent", FlxUINumericStepper.CHANGE_EVENT);
		interp.variables.set("inputTextEvent", FlxUIInputText.CHANGE_EVENT);
		interp.variables.set("Rectangle", Rectangle);
		interp.variables.set("Bytes", Bytes);
		interp.variables.set("AudioBuffer", AudioBuffer);
		interp.variables.set("FileReference", FileReference);

		#if sys
		interp.variables.set("FileSystem", sys.FileSystem);
		interp.variables.set("IoPath", haxe.io.Path);
		interp.variables.set("readDirectory", readDirectory);
		interp.variables.set("isDirectory", isDirectory);
		#end
		#if mobile
		interp.variables.set("addVirtualPad", addVirtualPad);
		interp.variables.set("removeVirtualPad", removeVirtualPad);
		interp.variables.set("addPadCamera", addPadCamera);
		interp.variables.set("addAndroidControls", addAndroidControls);
		interp.variables.set("_virtualpad", _virtualpad);
		interp.variables.set("dPadModeFromString", dPadModeFromString);
		interp.variables.set("actionModeModeFromString", actionModeModeFromString);
	
		#end
		interp.variables.set("addVirtualPads", addVirtualPads);
		interp.variables.set("visPressed", visPressed);
	
try{
		trace("set stuff");
		interp.execute(program);
		hscriptStates.set(usehaxe,interp);
		callHscript("create", [], usehaxe);
		trace('executed');
}
catch (e) {
	openfl.Lib.application.window.alert(e.message, "THE CHARTING STATE CRASHED!");
	LoadingState.loadAndSwitchState(new PlayState());
}
	}
	function addVirtualPads(dPad:String,act:String){
		#if mobile
		addVirtualPad(dPadModeFromString(dPad),actionModeModeFromString(act));
		#end
	}
	#if mobile
	public function dPadModeFromString(lmao:String):FlxDPadMode{
	switch (lmao){
	case 'up_down':return FlxDPadMode.UP_DOWN;
	case 'left_right':return FlxDPadMode.LEFT_RIGHT;
	case 'up_left_right':return FlxDPadMode.UP_LEFT_RIGHT;
	case 'full':return FlxDPadMode.FULL;
	case 'right_full':return FlxDPadMode.RIGHT_FULL;
	case 'none':return FlxDPadMode.NONE;
	}
	return FlxDPadMode.NONE;
	}
	public function actionModeModeFromString(lmao:String):FlxActionMode{
		switch (lmao){
		case 'a':return FlxActionMode.A;
		case 'b':return FlxActionMode.B;
		case 'd':return FlxActionMode.D;
		case 'a_b':return FlxActionMode.A_B;
		case 'a_b_c':return FlxActionMode.A_B_C;
		case 'a_b_e':return FlxActionMode.A_B_E;
		case 'a_b_7':return FlxActionMode.A_B_7;
		case 'a_b_x_y':return FlxActionMode.A_B_X_Y;
		case 'a_b_c_x_y':return FlxActionMode.A_B_C_X_Y;
		case 'a_b_c_x_y_z':return FlxActionMode.A_B_C_X_Y_Z;
		case 'full':return FlxActionMode.FULL;
		case 'none':return FlxActionMode.NONE;
		}
		return FlxActionMode.NONE;
		}
	#end
	public function visPressed(dumbass:String = ''):Bool{
		#if mobile
		
		return _virtualpad.returnPressed(dumbass);
		#else
		return false;
		#end
	}
	function isNumericStepper(variable:Dynamic):Bool
	{
		return false;
		
		if (variable is FlxUINumericStepper)
		{
			return true;
		}
	}

	function isInputText(variable:Dynamic):Bool
	{
		return false;
		
		if (variable is FlxUIInputText)
		{
			return true;
		}
	}

	function createMap():Map<String, String>
	{
		var daMap:Map<String, String> = new Map<String, String>();

		return daMap;
	}

	function getStepperTextField(stepper:FlxUINumericStepper):Dynamic
	{
		@:privateAccess
		return stepper.text_field;
	}

	function createDefaultTabMenu(tabs:Dynamic):FlxUITabMenu
	{
		var daBox:FlxUITabMenu = new FlxUITabMenu(null, tabs, true);
		return daBox;
	}

	#if sys
	function readDirectory(directory:String):Array<String>
	{
		return FileSystem.readDirectory(directory);
	}

	function isDirectory(directory:String):Bool
	{
		return FileSystem.isDirectory(directory);
	}
	#end

	override function create()
	{
		FNFAssets.clearStoredMemory();
		makeHaxeState("charting", SUtil.getPath() + 'assets/scripts/custom_menus/', 'ChartingState');
		super.create();
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		callAllHScript("getEvent", [id, sender, data, params]);
	}

	override function update(elapsed:Float)
	{
		callAllHScript("update", [elapsed]);
		super.update(elapsed);
	}
	
	override function beatHit()
	{
		super.beatHit();
		setAllHaxeVar('curBeat', curBeat);
		callAllHScript('beatHit', [curBeat]);
	}

	override function stepHit()
	{
		super.stepHit();
		setAllHaxeVar('curStep', curStep);
		callAllHScript("stepHit", [curStep]);
	}

	@:access(openfl.media.Sound)
	public function generateWaveform(sound:Sound, width:Int, height:Int, color:Int):FlxSprite
	{
		if (sound == null || sound.__buffer == null)
			return null;

		var sprite = new FlxSprite();
		sprite.makeGraphic(width, height, FlxColor.TRANSPARENT, true);

		var buffer:AudioBuffer = sound.__buffer;
		var data = buffer.data;

		if (data == null)
			return sprite;

		var centerX:Int = Std.int(width * 0.5);

		var totalSamples:Int = data.length;
		var samplesPerRow:Int = Std.int(totalSamples / height);

		if (samplesPerRow < 1)
			samplesPerRow = 1;

		var bmp = sprite.pixels;
		bmp.lock();

		for (y in 0...height)
		{
			var startSample = y * samplesPerRow;
			var endSample = startSample + samplesPerRow;

			if (endSample > totalSamples)
				endSample = totalSamples;

			var peak:Float = 0;

			for (i in startSample...endSample)
			{
				var sample = data[i] / 32768.0;
				var amp = Math.abs(sample);

				if (amp > peak)
					peak = amp;
			}

			var waveSize:Int = Std.int(peak * (width * 0.5));

			if (waveSize < 1)
				waveSize = 1;

			bmp.fillRect(
				new Rectangle(centerX - waveSize, y, waveSize * 2, 1),
				color
			);
		}

		bmp.unlock();
		sprite.dirty = true;

		return sprite;
	}
	public function calculateSectionDuration(sections:Array<SwagSection>, sectionIndex:Int, baseBPM:Float):Float
	{
		if (sectionIndex < 0 || sectionIndex >= sections.length)
			return 0;

		var section = sections[sectionIndex];
		var sectionBPM = (section.changeBPM && section.bpm > 0) ? section.bpm : baseBPM;
		var msPerStep = (60 / sectionBPM) * 1000 / 4;
		var duration = msPerStep * section.lengthInSteps;

		return duration;
	}
	public function calculateSectionTimings(sections:Array<SwagSection>,baseBPM:Float):Array<{sectionIndex:Int,startTime:Float,endTime:Float}>
	{
		var timings = [];
		var currentTime:Float = 0;
		var curBPM:Float = baseBPM;

		for (i in 0...sections.length)
		{
			var sec = sections[i];

			if (sec.changeBPM && sec.bpm > 0)
				curBPM = sec.bpm;

			var msPerStep = (60 / curBPM) * 1000 / 4;
			var duration = msPerStep * sec.lengthInSteps;

			timings.push({
				sectionIndex: i,
				startTime: currentTime,
				endTime: currentTime + duration
			});

			currentTime += duration;
		}

		return timings;
	}
	@:access(openfl.media.Sound)
	private function extractAudioRange(sound:Sound, startMs:Float, endMs:Float, sampleRate:Int = 44100):Array<Float>
	{
		var samples:Array<Float> = [];

		if (sound == null || sound.__buffer == null)
			return samples;

		var buffer:AudioBuffer = sound.__buffer;
		var data = buffer.data;

		if (data == null)
			return samples;

		var startSample = Std.int((startMs / 1000) * sampleRate);
		var endSample = Std.int((endMs / 1000) * sampleRate);
		startSample = Std.int(Math.max(0, startSample));
		endSample = Std.int(Math.min(data.length, endSample));

		for (i in startSample...endSample)
		{
			if (i < data.length)
				samples.push(data[i]);
		}

		return samples;
	}
	@:access(openfl.media.Sound)
	public function generateSectionWaveform(sound:Sound, sections:Array<SwagSection>, sectionIndex:Int, baseBPM:Float, width:Int, height:Int, color:FlxColor):FlxSprite
	{
		var sprite = new FlxSprite();
		sprite.makeGraphic(width, height, FlxColor.TRANSPARENT);

		if (sectionIndex < 0 || sectionIndex >= sections.length || sound == null || sound.__buffer == null)
			return sprite;

		var timings = calculateSectionTimings(sections, baseBPM);
		var timing = timings[sectionIndex];
		var sectionSamples = extractAudioRange(sound, timing.startTime, timing.endTime);

		if (sectionSamples.length == 0)
			return sprite;

		var bmp = sprite.pixels;
		bmp.lock();

		var midX = Std.int(width / 2);
		var samplesPerPixel = sectionSamples.length / height;

		for (y in 0...height)
		{
			var startSample = Std.int(y * samplesPerPixel);
			var endSample = Std.int((y + 1) * samplesPerPixel);

			var sum:Float = 0;
			var count:Int = 0;

			for (i in startSample...endSample)
			{
				if (i >= sectionSamples.length)
					break;

				var value = sectionSamples[i] / 32768.0;

				sum += value * value;
				count++;
			}

			var amp:Float = count > 0 ? Math.sqrt(sum / count) : 0;

			var barWidth = Std.int(amp * midX);

			for (x in (midX - barWidth)...(midX + barWidth))
			{
				if (x >= 0 && x < width)
					bmp.setPixel32(x, y, color);
			}
		}

		bmp.unlock();
		sprite.dirty = true;

		return sprite;
	}
	@:access(openfl.media.Sound)
	public function generateAllSectionWaveforms(sound:Sound, sections:Array<SwagSection>, baseBPM:Float, width:Int, height:Int, color:FlxColor):Map<Int, FlxSprite>
	{
		var waveforms:Map<Int, FlxSprite> = new Map<Int, FlxSprite>();

		if (sound == null || sound.__buffer == null || sections == null || sections.length == 0)
			return waveforms;

		for (i in 0...sections.length)
		{
			var waveform = generateSectionWaveform(sound, sections, i, baseBPM, width, height, color);
			waveforms.set(i, waveform);
		}

		return waveforms;
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}
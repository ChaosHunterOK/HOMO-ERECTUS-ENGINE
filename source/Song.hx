package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import tjson.TJSON;
#if sys
import sys.io.File;
import lime.system.System;
import haxe.io.Path;
#end
using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var stage:String;
	var gf:String;
	var isMoody:Null<Bool>;
	var cutsceneType:String;
	var uiType:String;
	var ?forceLayout:String;
	var isSpooky:Null<Bool>;
	var isHey:Null<Bool>;
	var isCheer:Null<Bool>;
	var preferredNoteAmount:Null<Int>;
	var forceJudgements:Null<Bool>;
	var convertMineToNuke:Null<Bool>;
	var mania:Null<Int>;
	var ?opponentCount:Null<Int>;
	var ?timeSigNumerator:Null<Int>;
	var ?timeSigDenominator:Null<Int>;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var stage:String = 'stage';
	public var gf:String = 'gf';
	public var isMoody:Null<Bool> = false;
	public var isSpooky:Null<Bool> = false;
	public var cutsceneType:String = "none";
	public var uiType:String = 'normal';
	public var isHey:Null<Bool> = false;
	public var timeSigNumerator:Null<Int> = 4;
	public var timeSigDenominator:Null<Int> = 4;
	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson:String = "";
		if (jsonInput != folder && FNFAssets.exists(SUtil.getPath() + "assets/data/" + folder.toLowerCase() + "/" + folder.toLowerCase() + ".json"))
			rawJson = FNFAssets.getText(SUtil.getPath() + "assets/data/"+folder.toLowerCase()+"/"+folder.toLowerCase()+".json").trim();
		else
			rawJson = FNFAssets.getText(SUtil.getPath() + "assets/data/" + folder.toLowerCase() + "/" + jsonInput.toLowerCase() + '.json').trim();

		if (jsonInput == 'events')
			rawJson = FNFAssets.getText(SUtil.getPath() + "assets/data/" + folder.toLowerCase() + "/" + jsonInput.toLowerCase() + '.json').trim();
		
		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}
		var parsedJson = parseChartJson(rawJson, folder);
		if (parsedJson.stage == null) {
			// sw-switch case :fuckboy:
			parsedJson.stage = switch (parsedJson.song.toLowerCase()) {
				case 'spookeez' | 'monster' | 'south':
					'spooky';
				case 'philly' | 'pico' | 'blammed':
					'philly';
				case 'milf' | 'high' | 'satin-panties':
					'limo';
				case 'cocoa' | 'eggnog':
					'mall';
				case 'winter-horrorland':
					'mallEvil';
				case 'senpai' | 'roses':
					'school';
				case 'thorns':
					'schoolEvil';
				case 'ugh' | 'stress' | 'guns':
					'tank';
				default:
					'stage';
			
			}
		}
		if (parsedJson.isHey == null) {
			parsedJson.isHey = false;
			if (parsedJson.song.toLowerCase() == 'bopeebo')
				parsedJson.isHey = true;
		}

		if(parsedJson.events == null)
		{
			parsedJson.events = [];
			for (secNum in 0...parsedJson.notes.length)
			{
				var sec:SwagSection = parsedJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						parsedJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		if (parsedJson.isCheer = null) {
			parsedJson.isCheer = false;
			if (parsedJson.song.toLowerCase() == "tutorial")
				parsedJson.isCheer = true;
		}
		if (parsedJson.preferredNoteAmount == null) {
			switch (parsedJson.mania) {
				case 1:
					parsedJson.preferredNoteAmount = 6;
				case 2:
					parsedJson.preferredNoteAmount = 7;
				case 3:
					parsedJson.preferredNoteAmount = 9;
				default:
					parsedJson.preferredNoteAmount = 4;
			}
		}
		if (parsedJson.mania == null) {
			switch (parsedJson.preferredNoteAmount) {
				case 4:
					parsedJson.mania = 0;
				case 6:
					parsedJson.mania = 1;
				case 7:
					parsedJson.mania = 2;
				case 9:
					parsedJson.mania = 3;
				default:
					parsedJson.mania = 0;
			}
		}
		trace(parsedJson.stage);
		if (parsedJson.gf == null) {
			// are you kidding me did i really do song to lowercase
			switch (parsedJson.stage) {
				case 'limo':
					parsedJson.gf = 'gf-car';
				case 'mall':
					parsedJson.gf = 'gf-christmas';
				case 'mallEvil':
					parsedJson.gf = 'gf-christmas';
				case 'school' 
				| 'schoolEvil':
					parsedJson.gf = 'gf-pixel';
				case 'tank':
					parsedJson.gf = 'gf-tankmen';
					if (parsedJson.song.toLowerCase() == "stress")
						parsedJson.gf = "pico-speaker";
				default:
					parsedJson.gf = 'gf';
			}

		}
		if (parsedJson.isMoody == null) {
			if (parsedJson.song.toLowerCase() == 'roses')
				parsedJson.isMoody = true;
			else
				parsedJson.isMoody = false;
		}
		// is spooky means trails on spirit
		if (parsedJson.isSpooky == null) {
			if (parsedJson.stage.toLowerCase() == 'mallEvil')
				parsedJson.isSpooky = true;
			else
				parsedJson.isSpooky = false;
		}
		if (parsedJson.song.toLowerCase() == 'winter-horrorland')
			parsedJson.cutsceneType = "monster";
		if (parsedJson.forceJudgements == null)
			parsedJson.forceJudgements = false;
		if (parsedJson.timeSigNumerator == null || parsedJson.timeSigNumerator <= 0)
			parsedJson.timeSigNumerator = 4;
		if (parsedJson.timeSigDenominator == null || parsedJson.timeSigDenominator <= 0)
			parsedJson.timeSigDenominator = 4;
		if (parsedJson.forceLayout == null)
			parsedJson.forceLayout = 'none';
		if (parsedJson.cutsceneType == null) {
			switch (parsedJson.song.toLowerCase()) {
				case 'roses':
					parsedJson.cutsceneType = "angry-senpai";
				case 'senpai':
					parsedJson.cutsceneType = "senpai";
				case 'thorns':
					parsedJson.cutsceneType = 'spirit';
				case 'winter-horrorland':
					parsedJson.cutsceneType = 'monster';
				case 'ugh':
					parsedJson.cutsceneType = "ugh";
				case 'guns':
					parsedJson.cutsceneType = "guns";
				case 'stress':
					parsedJson.cutsceneType = 'stress';
				default:
					parsedJson.cutsceneType = 'none';
			}
		}
		if (parsedJson.convertMineToNuke == null) {
			if (parsedJson.song.toLowerCase() == "expurgation")
				parsedJson.convertMineToNuke = true;
			else
				parsedJson.convertMineToNuke = false;
		}
		if (parsedJson.uiType == null) {

			parsedJson.uiType = switch (parsedJson.song.toLowerCase()) {
				case 'roses' | 'senpai' | 'thorns':
					'pixel';
				default:
					'normal';
			}
		}
		if (parsedJson.player1 == "bf-pixel" && OptionsHandler.options.stressTankmen)
			parsedJson.player1 = "bulb-pixel";
		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/*
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daSections = songData.sections;
				daBpm = songData.bpm;
				daSectionLengths = songData.sectionLengths; */
		if (jsonInput != folder)
		{
			// means this isn't normal difficulty
			// lets finally overwrite notes
			var realJson = parseChartJson(FNFAssets.getText(SUtil.getPath() + "assets/data/" + folder.toLowerCase() + "/" + jsonInput.toLowerCase() + '.json').trim(), folder);
			parsedJson.notes = realJson.notes;
			parsedJson.bpm = realJson.bpm;
			parsedJson.needsVoices = realJson.needsVoices;
			parsedJson.speed = realJson.speed;
			if (realJson.timeSigNumerator != null && realJson.timeSigNumerator > 0)
				parsedJson.timeSigNumerator = realJson.timeSigNumerator;
			if (realJson.timeSigDenominator != null && realJson.timeSigDenominator > 0)
				parsedJson.timeSigDenominator = realJson.timeSigDenominator;
			//parsedJson.events = realJson.events;
		}
		return parsedJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast CoolUtil.parseJson(rawJson).song;
		return swagShit;
	}
	public static function parseChartJson(rawJson:String, ?folder:String):SwagSong
	{
		var quick:Dynamic = null;
		try
			quick = haxe.Json.parse(rawJson)
		catch (e:Dynamic)
			quick = null;

		if (quick != null && isCodenameChart(quick))
			return convertCodenameChart(quick, folder);

		return parseJSONshit(rawJson);
	}

	public static function isCodenameChart(parsed:Dynamic):Bool
	{
		if (parsed == null) return false;
		if (Reflect.hasField(parsed, "notes")) return false; // already a normal SwagSong-shaped json
		return (Reflect.hasField(parsed, "codenameChart") && parsed.codenameChart == true) || Reflect.hasField(parsed, "strumLines");
	}

	public static function convertCodenameChart(codename:Dynamic, ?folder:String):SwagSong
	{
		var meta:Dynamic = null;
		if (folder != null)
		{
			var metaPath = SUtil.getPath() + "assets/data/" + folder.toLowerCase() + "/meta.json";
			if (FNFAssets.exists(metaPath))
			{
				try
					meta = haxe.Json.parse(FNFAssets.getText(metaPath).trim())
				catch (e:Dynamic)
					meta = null;
			}
		}

		var customValues:Dynamic = (meta != null && Reflect.hasField(meta, "customValues")) ? meta.customValues : null;

		inline function metaField(name:String, def:Dynamic):Dynamic
		{
			if (meta != null && Reflect.hasField(meta, name) && Reflect.field(meta, name) != null)
				return Reflect.field(meta, name);
			if (Reflect.hasField(codename, name) && Reflect.field(codename, name) != null)
				return Reflect.field(codename, name);
			return def;
		}

		var songName:String = folder;
		if (songName == null)
		{
			if (customValues != null && Reflect.hasField(customValues, "songName") && customValues.songName != null)
				songName = customValues.songName;
			else if (meta != null && Reflect.hasField(meta, "name") && meta.name != null)
				songName = meta.name;
			else
				songName = "unknown";
		}

		var song:SwagSong = cast {};
		song.song = songName;
		song.bpm = metaField("bpm", 100);
		song.needsVoices = metaField("needsVoices", true);
		song.speed = codename.scrollSpeed != null ? codename.scrollSpeed : 1;
		song.stage = codename.stage != null ? codename.stage : "stage";
		song.player1 = "bf";
		song.player2 = "dad";
		song.gf = "gf";
		{
			var slList:Array<Dynamic> = Reflect.hasField(codename, "strumLines") ? codename.strumLines : [];
			for (sl in slList)
			{
				if (sl.characters == null || sl.characters.length == 0) continue;
				var charName:String = sl.characters[0];
				switch (sl.type)
				{
					case 0: song.player1 = charName;
					case 1: song.player2 = charName;
					case 2: song.gf = charName;
				}
			}
			if (song.player1 == "bf" && customValues != null && Reflect.hasField(customValues, "character") && customValues.character != null)
				song.player1 = customValues.character;
		}
		if (meta != null && Reflect.hasField(meta, "beatsPerMeasure") && meta.beatsPerMeasure != null)
			song.timeSigNumerator = meta.beatsPerMeasure;

		var events:Array<Dynamic> = [];
		if (Reflect.hasField(codename, "events") && codename.events != null)
		{
			for (ev in (codename.events:Array<Dynamic>))
			{
				var t:Float = ev.t != null ? ev.t : (ev.time != null ? ev.time : 0);
				var name:String = ev.e != null ? ev.e : (ev.event != null ? ev.event : (ev.name != null ? ev.name : ""));
				var val1:Dynamic = null;
				var val2:Dynamic = null;
				if (ev.v != null)
				{
					if (Reflect.hasField(ev.v, "value1")) val1 = Reflect.field(ev.v, "value1");
					if (Reflect.hasField(ev.v, "value2")) val2 = Reflect.field(ev.v, "value2");
				}
				events.push([t, [[name, val1, val2]]]);
			}
		}
		song.events = events;
		var strumLines:Array<Dynamic> = Reflect.hasField(codename, "strumLines") ? codename.strumLines : [];
		var noteTypeNames:Array<String> = Reflect.hasField(codename, "noteTypes") ? codename.noteTypes : [];

		var ammo:Int = 4;
		for (sl in strumLines)
			if (sl.keyCount != null && sl.keyCount > ammo)
				ammo = sl.keyCount;

		var flat:Array<{time:Float, lane:Int, sus:Float, isPlayer:Bool}> = [];
		for (sl in strumLines)
		{
			if (sl.notes == null) continue;
			var isPlayer:Bool = (sl.type == 0);
			for (n in (sl.notes:Array<Dynamic>))
			{
				var lane:Int = n.id != null ? n.id : 0;
				if (n.type != null && n.type > 0 && noteTypeNames[n.type] != null && noteTypeNames[n.type].toLowerCase().indexOf("mine") != -1)
					lane += ammo * 2;

				flat.push({time: n.time, lane: lane, sus: n.sLen != null ? n.sLen : 0, isPlayer: isPlayer});
			}
		}
		flat.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));

		var stepsPerBeat:Int = (meta != null && Reflect.hasField(meta, "stepsPerBeat") && meta.stepsPerBeat != null) ? meta.stepsPerBeat : 4;
		var beatsPerMeasure:Int = (meta != null && Reflect.hasField(meta, "beatsPerMeasure") && meta.beatsPerMeasure != null) ? meta.beatsPerMeasure : 4;

		var stepCrochet:Float = (60000 / song.bpm) / stepsPerBeat;
		var stepsPerSection:Int = stepsPerBeat * beatsPerMeasure;
		var sectionLength:Float = stepCrochet * stepsPerSection;
		if (sectionLength <= 0) sectionLength = 1;

		var sections:Array<SwagSection> = [];
		var i:Int = 0;
		var sectionStart:Float = 0;
		while (i < flat.length)
		{
			var sec:SwagSection = cast {};
			sec.sectionNotes = [];
			sec.lengthInSteps = stepsPerSection;
			sec.mustHitSection = true;
			sec.changeBPM = false;
			sec.bpm = song.bpm;
			sec.altAnim = false;

			var sectionEnd = sectionStart + sectionLength;
			while (i < flat.length && flat[i].time < sectionEnd)
			{
				var note = flat[i];
				sec.sectionNotes.push([note.time, note.lane, note.sus, 0]);
				i++;
			}
			sections.push(sec);
			sectionStart = sectionEnd;
		}
		song.notes = sections;

		song.preferredNoteAmount = ammo;
		song.mania = switch (ammo)
		{
			case 6: 1;
			case 7: 2;
			case 9: 3;
			default: 0;
		}

		return song;
	}
}

package;

import Song.SwagSong;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	var timeSigNum:Int;
	var timeSigDen:Int;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000);
	public static var stepCrochet:Float = crochet / 4;
	public static var timeSigNumerator:Int = 4;
	public static var timeSigDenominator:Int = 4;
	public static var stepsPerBeat:Float = 4;
	public static var stepsPerMeasure:Float = 16;

	public static var songPosition:Float = 0;
	public static var lastSongPos:Float = 0;

	public static var offset:Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = (safeFrames / 60) * 1000;
	public static var timeScale:Float = safeZoneOffset / 166;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static var sectionStepMap:Array<Int> = [];

	public static var curStep(get, default):Int;
	public static var waveformAmplitude:Float = 0;

	private static function get_curStep():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			timeSigNum: timeSigNumerator,
			timeSigDen: timeSigDenominator
		}
		for (i in 0...bpmChangeMap.length)
		{
			if (songPosition >= bpmChangeMap[i].songTime)
			lastChange = bpmChangeMap[i];
		}
		var beatLength = (60 / lastChange.bpm) * 1000;
		var noteLength = beatLength * (4.0 / lastChange.timeSigDen);
		var dynamicStepCrochet = noteLength / (16.0 / lastChange.timeSigDen);
		return lastChange.stepTime + Math.floor((songPosition - lastChange.songTime) / dynamicStepCrochet);
	}
	public static function getSectionAtStep(step:Int):Int
	{
		if (sectionStepMap.length == 0) return 0;

		var sectionIndex = 0;
		for (i in 0...sectionStepMap.length)
		{
			if (step >= sectionStepMap[i])
				sectionIndex = i;
			else
				break;
		}
		return sectionIndex;
	}

	public function new() {}

	public static function mapBPMChanges(song:SwagSong)
	{
		if (song == null || song.notes == null)
		{
			trace("its null");
			bpmChangeMap = [];
			sectionStepMap = [];
			return;
		}

		bpmChangeMap = [];
		sectionStepMap = [];

		var songTimeSigNum:Int = (song.timeSigNumerator != null && song.timeSigNumerator > 0) ? song.timeSigNumerator : 4;
		var songTimeSigDen:Int = (song.timeSigDenominator != null && song.timeSigDenominator > 0) ? song.timeSigDenominator : 4;

		var curBPM:Float = (song.bpm > 0) ? song.bpm : 100;
		var curTimeSigNum:Int = songTimeSigNum;
		var curTimeSigDen:Int = songTimeSigDen;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.notes.length)
		{
			var note = song.notes[i];
			if (note == null) continue;

			sectionStepMap.push(totalSteps);
			var secChangeTimeSig:Bool = Reflect.field(note, "changeTimeSig") == true;
			var secTimeSigNum:Dynamic = Reflect.field(note, "timeSigNum");
			var secTimeSigDen:Dynamic = Reflect.field(note, "timeSigDen");

			var bpmChanged = (note.changeBPM && note.bpm > 0 && note.bpm != curBPM);
			var timeSigChanged = (secChangeTimeSig && secTimeSigNum != null && secTimeSigNum > 0
				&& secTimeSigDen != null && secTimeSigDen > 0
				&& (secTimeSigNum != curTimeSigNum || secTimeSigDen != curTimeSigDen));

			if (bpmChanged)
				curBPM = note.bpm;

			if (timeSigChanged)
			{
				curTimeSigNum = secTimeSigNum;
				curTimeSigDen = secTimeSigDen;
			}

			if (bpmChanged || timeSigChanged)
			{
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					timeSigNum: curTimeSigNum,
					timeSigDen: curTimeSigDen
				};

				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = (note.lengthInSteps > 0) ? note.lengthInSteps : 0;
			totalSteps += deltaSteps;

			var stepLength = ((60 / curBPM) * 1000) / 4;
			totalPos += stepLength * deltaSteps;
		}
		changeTimeSig(songTimeSigNum, songTimeSigDen);

		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	public static function setWaveformAmplitude(value:Float)
	{
		value = Math.max(0, Math.min(1, value));

		var speed = (value > waveformAmplitude) ? 0.45 : 0.12;
		waveformAmplitude += (value - waveformAmplitude) * speed;
	}

	public static function changeBPM(newBpm:Float)
	{
		if (newBpm <= 0)
		{
			trace("invalid bpm");
			return;
		}

		bpm = newBpm;
		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / stepsPerBeat;
	}

	public static function changeTimeSig(newNum:Int, newDen:Int)
	{
		if (newNum <= 0 || newDen <= 0)
			return;

		timeSigNumerator = newNum;
		timeSigDenominator = newDen;
		stepsPerBeat = 16.0 / newDen;
		stepsPerMeasure = Std.int(newNum * stepsPerBeat);
	}
}
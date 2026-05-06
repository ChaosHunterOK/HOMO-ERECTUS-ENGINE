package;

import Song.SwagSong;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000);
	public static var stepCrochet:Float = crochet / 4;

	public static var songPosition:Float = 0;
	public static var lastSongPos:Float = 0;

	public static var offset:Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = (safeFrames / 60) * 1000;
	public static var timeScale:Float = safeZoneOffset / 166;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new() {}

	public static function mapBPMChanges(song:SwagSong)
	{
		if (song == null || song.notes == null)
		{
			trace("its null");
			bpmChangeMap = [];
			return;
		}

		bpmChangeMap = [];

		var curBPM:Float = (song.bpm > 0) ? song.bpm : 100;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.notes.length)
		{
			var note = song.notes[i];
			if (note == null) continue;

			if (note.changeBPM && note.bpm > 0 && note.bpm != curBPM)
			{
				curBPM = note.bpm;

				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};

				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = (note.lengthInSteps > 0) ? note.lengthInSteps : 0;
			totalSteps += deltaSteps;

			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}

		trace("new BPM map BUDDY " + bpmChangeMap);
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
		stepCrochet = crochet / 4;
	}
}
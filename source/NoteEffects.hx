package;

import flixel.FlxG;
import flixel.math.FlxMath;


class NoteEffects
{
	static var snakeBase:Float = 0;
	static var snakeValue:Float = 0;
	static var drunkTime:Float = 0;
	public static function updateTimers(elapsed:Float):Void
	{
		snakeBase += elapsed * Math.PI;
		snakeValue = Math.sin(snakeBase) * 100;
		drunkTime += elapsed;
	}

	public static function resetTimers():Void
	{
		snakeBase = 0;
		snakeValue = 0;
		drunkTime = 0;
	}
	public static function drunk(note:Note):Void
	{
		var mod = PlayState.instance.getNoteMod(note);
		var phase = note.strumTime * 0.004;
		mod.xOffset += Math.sin((drunkTime * 2.2) + phase) * 22;
		mod.rotation += Math.sin((drunkTime * 1.4) + phase) * 6;
	}
	public static function snake(note:Note):Void
	{
		var mod = PlayState.instance.getNoteMod(note);
		var targetX = note.mustPress ? (FlxG.width / 2) + snakeValue + (Note.swagWidth * note.noteData) + 50 : snakeValue + (Note.swagWidth * note.noteData) + 50;
		mod.xOffset += targetX - note.x;
	}
	public static var perspTravelTime:Float = 1400;
	public static var perspStartScale:Float = 0.25;
}

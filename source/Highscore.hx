package;

import OptionsHandler.TOptions;
import Judge.Jury;
import flixel.FlxG;

@:forward
enum abstract FCLevel(Int) from Int to Int {
    var None = 0;
    var Sdcb = 1;
    var Shit = 2;
    var Bad = 3;
    var Good = 4;
    var Sick = 5;

    @:op(A > B) static function gt(A:FCLevel, B:FCLevel):Bool;
    @:op(A >= B) static function gte(A:FCLevel, B:FCLevel):Bool;
    @:op(A < B) static function lt(A:FCLevel, B:FCLevel):Bool;
    @:op(A <= B) static function lte(A:FCLevel, B:FCLevel):Bool;
    @:op(A == B) static function eq(A:FCLevel, B:FCLevel):Bool;
}

class Highscore {
    public static var songScores:Map<String, Int> = [];
    public static var songAccuracy:Map<String, Float> = [];
    public static var songCompletions:Map<String, Bool> = [];
    public static var songFCLevels:Map<String, Int> = [];
    public static var songJudge:Map<String, Int> = [];
    public static var songOptionsUsed:Map<String, TOptions> = [];
    public static var songModifiersUsed:Map<String, Dynamic> = [];

    public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?accuracy:Float = 0, ?rating:FCLevel, ?judge:Jury):Void {
        var curOptions = OptionsHandler.options;
        var modifierDynamic = ModifierState.namedModifiers;
        
        var recentKey = formatSong(song, diff, "recent");
        var bestScoreKey = formatSong(song, diff, "best-score");
        var bestAccKey = formatSong(song, diff, "best-accuracy");
        var bestFCKey = formatSong(song, diff, "best-fullcombo");
        var bestOfAllKey = formatSong(song, diff, "best");
        updateSongData(recentKey, score, accuracy, rating, judge, curOptions, modifierDynamic);
        if (score > getRawScore(bestScoreKey)) {
            updateSongData(bestScoreKey, score, accuracy, rating, judge, curOptions, modifierDynamic);
            songScores.set(bestOfAllKey, score);
        }
        if (accuracy > getRawAccuracy(bestAccKey)) {
            updateSongData(bestAccKey, score, accuracy, rating, judge, curOptions, modifierDynamic);
            songAccuracy.set(bestOfAllKey, accuracy);
        }
        if (rating >= getRawFC(bestFCKey)) {
            updateSongData(bestFCKey, score, accuracy, rating, judge, curOptions, modifierDynamic);
            if (rating >= getRawFC(bestOfAllKey)) {
                songFCLevels.set(bestOfAllKey, rating);
            }
        }
        
        saveToFlxG();
    }
    private static function updateSongData(key:String, score:Int, acc:Float, fc:Int, judge:Int, opt:TOptions, mod:Dynamic) {
        songScores.set(key, score);
        songAccuracy.set(key, acc);
        songFCLevels.set(key, fc);
        songJudge.set(key, judge);
        songOptionsUsed.set(key, opt);
        songModifiersUsed.set(key, mod);
    }

    public static function saveWeekScore(week:Int = 1, score:Int = 0, ?diff:Int = 0, ?accuracy:Float = 0, saving:String = "best"):Void {
        var daWeek = formatSong('week' + week, diff, saving);
        if (score > getRawScore(daWeek)) {
            songScores.set(daWeek, score);
            songAccuracy.set(daWeek, accuracy);
            saveToFlxG();
        }
    }
    static function saveToFlxG() {
        FlxG.save.data.songScores = songScores;
        FlxG.save.data.songAccuracy = songAccuracy;
        FlxG.save.data.songCompletions = songCompletions;
        FlxG.save.data.songFCLevels = songFCLevels;
        FlxG.save.data.songJudge = songJudge;
        FlxG.save.data.songOptionsUsed = songOptionsUsed;
        FlxG.save.data.songModifiersUsed = songModifiersUsed;
        FlxG.save.flush();
    }

	//shitty stuff lol
    public static function formatSong(song:String, diff:Int, saving:String):String {
        var daSong:String = song + DifficultyIcons.getEndingFP(diff);
        return (saving != "best") ? '$daSong-$saving' : daSong;
    }
    public static function getScore(song:String, diff:Int, useFor:String = "best"):Int 
        return getRawScore(formatSong(song, diff, useFor));

    static function getRawScore(key:String):Int 
        return songScores.exists(key) ? songScores.get(key) : 0;

    public static function getAccuracy(song:String, diff:Int, useFor:String = "best"):Float 
        return songAccuracy.exists(formatSong(song, diff, useFor)) ? songAccuracy.get(formatSong(song, diff, useFor)) : 0;

    static function getRawAccuracy(key:String):Float 
        return songAccuracy.exists(key) ? songAccuracy.get(key) : 0;

    public static function getFCLevel(song:String, diff:Int, useFor:String):Int 
        return getRawFC(formatSong(song, diff, useFor));

    static function getRawFC(key:String):Int 
        return songFCLevels.exists(key) ? songFCLevels.get(key) : cast None;

    public static function getOptionsUsed(song:String, diff:Int, useFor:String = "best"):TOptions {
        var key = formatSong(song, diff, useFor);
        return songOptionsUsed.exists(key) ? songOptionsUsed.get(key) : OptionsHandler.options;
    }
	public static function getModifiersUsed(song:String, diff:Int, useFor:String = "best"):Dynamic
	{
		var key = formatSong(song, diff, useFor);
		return songModifiersUsed.exists(key) ? songModifiersUsed.get(key) : ModifierState.namedModifiers;
	}
	public static function getJudge(song:String, diff:Int, useFor:String):Int
	{
		var key = formatSong(song, diff, useFor);
		return songJudge.exists(key) ? songJudge.get(key) : 0; //usually 0
	}

    public static function getTotalScore():Int {
        var total:Int = 0;
        for (score in songScores) total += score;
        return total;
    }

    public static function load():Void {
        if (FlxG.save.data.songScores != null) songScores = FlxG.save.data.songScores;
        if (FlxG.save.data.songAccuracy != null) songAccuracy = FlxG.save.data.songAccuracy;
        if (FlxG.save.data.songFCLevels != null) songFCLevels = FlxG.save.data.songFCLevels;
        if (FlxG.save.data.songJudge != null) songJudge = FlxG.save.data.songJudge;
        if (FlxG.save.data.songModifiersUsed != null) songModifiersUsed = FlxG.save.data.songModifiersUsed;
        if (FlxG.save.data.songOptionsUsed != null) songOptionsUsed = FlxG.save.data.songOptionsUsed;
        if (FlxG.save.data.songCompletions != null) songCompletions = FlxG.save.data.songCompletions;
    }
}
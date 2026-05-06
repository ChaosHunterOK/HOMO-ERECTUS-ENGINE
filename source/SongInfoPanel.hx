package;

import flixel.math.FlxMath;
import Highscore.FCLevel;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import Judge.Jury;

enum abstract DisplayOptions(Int) from Int to Int {
    var BestScore = 0;
    var Recent = 1;
    var BestAccuracy = 2;
    var BestFc = 3;
    var BestOverall = 4;
    public static function fromString(s:String):DisplayOptions {
        return switch (s) {
            case "best-score": BestScore;
            case "recent": Recent;
            case "best-accuracy": BestAccuracy;
            case "best-fullcombo": BestFc;
            case "best": BestOverall;
            default: Recent;
        }
    }

    @:to public function toString():String {
        return switch (cast this : DisplayOptions) {
            case BestScore: "best-score";
            case Recent: "recent";
            case BestAccuracy: "best-accuracy";
            case BestFc: "best-fullcombo";
            case BestOverall: "best";
            default: "recent";
        }
    }
}

class SongInfoPanel extends FlxTypedSpriteGroup<FlxSprite> {
    var backpanel:FlxSprite;
    var scoreTxt:FlxText;
    var displayTxt:FlxText;
    
    var displaying:String = "best";
    var curSong:String = "tutorial";
    var curDiff:Int = 1;

    public function new(X:Float, Y:Float, song:String, diff:Int) {
        super(X, Y);

        curSong = song;
        curDiff = diff;
        
        backpanel = new FlxSprite().makeGraphic(400, 400, 0xCC000000);
        scoreTxt = new FlxText(20, 20, 350, "", 22);
        displayTxt = new FlxText(20, 260, 0, displaying, 22);
        
        add(backpanel);
        add(scoreTxt);
        add(displayTxt);

        changeSong(song, diff);
    }   

    public function changeSong(song:String, diff:Int) {
        curSong = song;
        curDiff = diff;

        var score = Highscore.getScore(song, diff, displaying);
        var acc = Highscore.getAccuracy(song, diff, displaying);
        var fcLevel:FCLevel = Highscore.getFCLevel(song, diff, displaying);
        
        var strAcc = CoolUtil.truncateFloat(acc * 100, 2);
        
        var fcText = switch (fcLevel) {
            case Sick: "Sick";
            case Good: "Good";
            case Bad:  "Bad";
            case Shit: "Shit";
            case Sdcb: "Sdcb";
            default:   "Clear";
        }

        scoreTxt.text = 'Score: $score\nAccuracy: $strAcc%\nFC Level: $fcText';

        if (displaying != 'best') {
            //judging yo dihh
            var judgeVal:Jury = cast Highscore.getJudge(song, diff, displaying);
            var judgeStr = switch (judgeVal) {
                case Judge9:  "Judge JUSTICE";
                case Classic: "Classic Judge";
                case Hard:    "Hard Judge";
                default:      "Judge " + (cast (judgeVal : Int) + 1);
            }
            scoreTxt.text += '\n$judgeStr';
            var mods = Highscore.getModifiersUsed(song, diff, displaying);
            if (mods != null && mods.mfc != null) {
                if (mods.mfc.value || mods.gfc.value || mods.fc.value) {
                    scoreTxt.text += "\nTotally grinded for this lmao";
                }
            }
        }
        
        displayTxt.text = displaying;
    }

    public function changeDisplay(change:Int = 0) {
        //idc anymore, let me live
        var currentEnum:DisplayOptions = DisplayOptions.fromString(displaying);
        var nextEnum:Int = FlxMath.wrap(cast (currentEnum : Int) + change, 0, 4);
        
        var finalEnum:DisplayOptions = cast nextEnum;
        displaying = finalEnum.toString();
        
        changeSong(curSong, curDiff);
    }
}
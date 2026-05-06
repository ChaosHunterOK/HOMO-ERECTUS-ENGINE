import flixel.util.FlxColor;
using StringTools;
typedef DialogTextInfo = {
    var speaker:String;
    var speakermood:String;
    var boxmood:String;
    var speech:String;
}
typedef AdvancedDialogDefines = {
    var backgroundColorR:Int;
    var backgroundColorG:Int;
    var backgroundColorB:Int;
    var backgroundColorA:Int;
    var musicName:String;
    var musicVolume:Int;
    var characterScale:Float;
    var dialogueBox:String;
    var fadeInTime:Float;
    var fadeInLoop:Int;
    var fadeOutTime:Float;
    var fadeOutLoop:Int;
    var bgFIT:Float;
    var bfFIL:Int;
    var textboxSprite:String;
    var acceptSound:String;
}
typedef AdvancedDialogInfo = {
    var dialogue:String;
    var speaker:String;
    var emotion:String;
    var fontname:String;
    var fontscale:Int;
    var musicVolume:Int;
    var shakeAmount:Float;
    var shakeDuration:Int;
    var shakeDelay:Int;
    var flashDuration:Int;
    var flashDelay:Int;
    var writingSpeed:Float;
    var flipSides:Bool;
    var dialogueBox:String;
    var dialogueSound:String;
    var textColor:FlxColor;
    var textShadowColor:FlxColor;
    var portraitColor:FlxColor;
    var skipAfter:Int;
}
typedef AdvancedDialogFile = {
    var defines:AdvancedDialogDefines;
    var info:Array<AdvancedDialogInfo>;
}


class FileParser {
    static inline function safeGet(arr:Array<String>, i:Int, def:String = ""):String {
        return i < arr.length && arr[i] != "" ? arr[i] : def;
    }

    static inline function parseIntSafe(v:String, def:Int = 0):Int {
        return v != null ? Std.parseInt(v) : def;
    }

    static inline function parseFloatSafe(v:String, def:Float = 0):Float {
        return v != null ? Std.parseFloat(v) : def;
    }
    static public function parseDialog(content:String):Array<DialogTextInfo> {
        var result:Array<DialogTextInfo> = [];

        for (line in content.split('\n')) {
            var parts = line.split(":");
            if (parts.length < 2) continue;

            result.push({
                speaker: safeGet(parts, 1),
                speakermood: safeGet(parts, 2, "normal"),
                boxmood: safeGet(parts, 3, "normal"),
                speech: parts.length > 4 ? parts.slice(4).join(":") : safeGet(parts, 2)
            });
        }

        return result;
    }
    static function defaultDefines():AdvancedDialogDefines {
        return {
            textboxSprite: 'hand_textbox',
            backgroundColorA: 178,
            backgroundColorB: 216,
            backgroundColorG: 223,
            backgroundColorR: 179,
            acceptSound: 'clickText',
            bfFIL: 4,
            bgFIT: 0.08,
            dialogueBox: 'classic',
            musicVolume: 1,
            musicName: 'lunchbox',
            fadeOutLoop: 5,
            fadeOutTime: 0.2,
            fadeInLoop: 5,
            fadeInTime: 0.83,
            characterScale: 1
        };
    }

    static function defaultInfo():AdvancedDialogInfo {
        return {
            dialogue: "",
            writingSpeed: 0.0,
            textShadowColor: FlxColor.WHITE,
            textColor: FlxColor.WHITE,
            speaker: "",
            skipAfter: 0,
            shakeDuration: 0,
            shakeDelay: 0,
            shakeAmount: 0.0,
            portraitColor: FlxColor.WHITE,
            musicVolume: 100,
            fontscale: 32,
            fontname: "Funkin",
            dialogueSound: "pixelText",
            dialogueBox: "classic",
            emotion: "normal",
            flashDelay: 0,
            flashDuration: 0,
            flipSides: false
        };
    }
    public static function parseOldDialogAsAdvanced(content:String):AdvancedDialogFile {
        var file:AdvancedDialogFile = {
            defines: defaultDefines(),
            info: []
        };

        for (line in content.split('\n')) {
            var parts = line.split(":");
            if (parts.length < 3) continue;

            var speaker = switch (parts[1]) {
                case "dad": PlayState.SONG.player2;
                case "bf": PlayState.SONG.player1;
                case s: s.substr(5);
            };

            var info = defaultInfo();
            info.speaker = speaker;
            info.dialogue = parts[2];

            file.info.push(info);
        }

        return file;
    }
    static function extract(dialog:String, delim:String, apply:String->Void):String {
        var i = dialog.indexOf(delim);
        if (i == -1) return dialog;

        var value = dialog.substr(i + 1).split(delim)[0];
        apply(value);

        return dialog.substr(value.length + 2).trim();
    }
    public static function parseAdvancedDialog(content:String):AdvancedDialogFile {
        var lines = content.split('\n');
        var first = lines.shift();

        if (first == null || !first.contains("[")) {
            return parseOldDialogAsAdvanced(content);
        }

        var file:AdvancedDialogFile = {
            defines: defaultDefines(),
            info: []
        };
        first = extract(first, "[", v -> file.defines.backgroundColorA = parseIntSafe(v));
        first = extract(first, "[", v -> file.defines.backgroundColorR = parseIntSafe(v));
        first = extract(first, "[", v -> file.defines.backgroundColorG = parseIntSafe(v));
        first = extract(first, "[", v -> file.defines.backgroundColorB = parseIntSafe(v));
        first = extract(first, "|", v -> file.defines.musicName = v);
        first = extract(first, "*", v -> file.defines.musicVolume = parseIntSafe(v));
        first = extract(first, "=", v -> file.defines.characterScale = parseFloatSafe(v));

        for (line in lines) {
            var info = defaultInfo();

            line = extract(line, ":", v -> info.speaker = v);
            line = extract(line, "!", v -> info.emotion = v);
            line = extract(line, "[", v -> info.fontname = v);
            line = extract(line, "]", v -> info.fontscale = parseIntSafe(v));
            line = extract(line, "*", v -> info.musicVolume = parseIntSafe(v));
            line = extract(line, "=", v -> info.shakeAmount = parseFloatSafe(v));
            line = extract(line, "+", v -> info.shakeDuration = parseIntSafe(v));
            line = extract(line, "-", v -> info.shakeDelay = parseIntSafe(v));

            info.dialogue = line;
            file.info.push(info);
        }

        return file;
    }
}
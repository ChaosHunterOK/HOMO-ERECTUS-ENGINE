package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.text.TextFormat;
import openfl.utils.Assets;
import haxe.Json;
import lime.system.System;

#if CRASH_HANDLER
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#if desktop
import Discord.DiscordClient;
#end
#end

using StringTools;

typedef WindowConfig = {
    var title:String;
    var version:String;
    var borderless:Bool;
    var cursorVisible:Bool;
    var width:Int;
    var height:Int;
    var borderColor:String;
}

class Main extends Sprite
{
    // Constants
    static inline final DEFAULT_WIDTH:Int = 1280;
    static inline final DEFAULT_HEIGHT:Int = 720;

    public static var ammo:Array<Int> = [4, 6, 7, 9];
    public static var curMusicName:String = "";
    public static var fpsVar:FPS;
    public static var memoryVar:MemoryCounter;
    public static var globalVars:Map<String, Dynamic> = [];

    #if sys
    public static var cwd:String = Sys.getCwd();
    #end

    public static var path:String = System.applicationStorageDirectory;

    public static function main():Void {
        Lib.current.addChild(new Main());
    }

    public function new() {
        super();
        SUtil.gameCrashCheck();

        if (stage != null)
            init();
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(?E:Event):Void {
        if (hasEventListener(Event.ADDED_TO_STAGE))
            removeEventListener(Event.ADDED_TO_STAGE, init);

        setupGame();
    }

    private function setupGame():Void {
        var gameWidth:Int = DEFAULT_WIDTH;
        var gameHeight:Int = DEFAULT_HEIGHT;
        var initialState:Class<FlxState> = TitleState;
        var framerate:Int = 60;
        var skipSplash:Bool = true;
        try {
            if (Assets.exists("assets/data/window.json")) {
                var config:WindowConfig = Json.parse(Assets.getText("assets/data/window.json"));
                gameWidth = config.width;
                gameHeight = config.height;

                var win = Lib.application.window;
                win.title = config.title;
                win.borderless = config.borderless;
                win.resize(gameWidth, gameHeight);
                
                win.x = Std.int((win.display.bounds.width - gameWidth) / 2);
                win.y = Std.int((win.display.bounds.height - gameHeight) / 2);

                if (config.borderColor != null)
                    Lib.current.stage.color = Std.parseInt(config.borderColor);
                else
                    Lib.current.stage.color = 0xFF000000;
            }
        } catch(e:Dynamic) {
            trace('Non-critical error: Could not load window.json ($e)');
        }
        var options = OptionsHandler.options;
        if (options != null) {
            if (options.fpsCap != null) framerate = options.fpsCap;
            if (options.showHaxeSplash != null) skipSplash = !options.showHaxeSplash;
        }
        var game = null;

        #if (haxe <= "4.3.0")
        game = new FlxGame(gameWidth, gameHeight, initialState, 1, framerate, framerate, skipSplash, false);
        #else
        game = new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, false);
        #end
        addChild(game);
        setupOverlays(options);
        stage.align = "tl";
        stage.scaleMode = StageScaleMode.NO_SCALE;

        #if mobile SUtil.doTheCheck(); #end
    }

    private function setupOverlays(options:Dynamic):Void {
        var fontName:String = Assets.getFont("assets/fonts/vcr.ttf").fontName;

        if (options != null && options.showFPS) {
            fpsVar = new FPS(10, 3, 0xFFFFFF);
            fpsVar.defaultTextFormat = new TextFormat(fontName, 22, 0xFFFFFF);
            fpsVar.embedFonts = true;
            fpsVar.selectable = false;
            fpsVar.mouseEnabled = false;
            fpsVar.cacheAsBitmap = true;
            addChild(fpsVar);
        }

        if (options != null && options.showMemory) {
            memoryVar = new MemoryCounter(10, 3, 0xFFFFFF);
            memoryVar.defaultTextFormat = new TextFormat(fontName, 12, 0xFFFFFF);
            memoryVar.embedFonts = true; 
            memoryVar.y = (fpsVar != null) ? fpsVar.y + 20 : 3; 
            memoryVar.cacheAsBitmap = true;
            addChild(memoryVar);
        }
    }
}
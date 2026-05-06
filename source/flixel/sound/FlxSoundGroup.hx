package flixel.sound;

import flixel.system.FlxSound;

class FlxSoundGroup {
    public var volume:Float = 1;

    public function new() {}
    public function add(s:FlxSound):Void {}
    public function remove(s:FlxSound):Void {}
}
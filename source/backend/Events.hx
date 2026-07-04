package backend;

import Character;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import Conductor;
import Note.EventNote;
import PlayState;
using StringTools;
using CoolUtil.FlxTools;

class Events {
    public static function loadEvents(playState:PlayState, lowerSong:String, offset:Float, songData:Dynamic):Void {
        var file = SUtil.getPath() + 'assets/data/' + lowerSong + '/events.json';

        if (FNFAssets.exists(file)) {
            var eventsData:Array<Dynamic> = Song.loadFromJson('events', lowerSong).events;
            for (event in eventsData)
                appendEventEntry(playState, event, offset);
        }

        if (songData != null && songData.events != null) {
            var songEvents:Array<Dynamic> = cast songData.events;
            for (event in songEvents)
                appendEventEntry(playState, event, offset);
        }

        if (playState.eventNotes != null && playState.eventNotes.length > 1)
            playState.eventNotes.sort(sortByTime);
    }

    private static function appendEventEntry(playState:PlayState, event:Dynamic, offset:Float):Void {
        if (event[1] == null) return;
        
        var baseTime:Float = event[0] + offset;
        var eventList:Array<Dynamic> = cast event[1];

        for (i in 0...eventList.length) {
            var ev = eventList[i];
            var subEvent:EventNote = {
                strumTime: baseTime,
                event: ev[0],
                value1: ev[1],
                value2: ev[2],
                value3: ev[3]
            };
            subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
            playState.eventNotes.push(subEvent);
            eventPushed(playState, subEvent);
        }
    }

    public static function changeCharacterCore(playState:PlayState, charName:String, charType:Int, ?deleteBefore:Bool = false):Void {
        if (charType < 0) charType = 0;
        if (charType > 2) charType = 2;

        var oldChar:Character = null;

        switch (charType) {
            case 0:
                oldChar = playState.boyfriend;
                if (oldChar.curCharacter != charName) {
                    if (!playState.boyfriendMap.exists(charName))
                        playState.addCharacterToList(charName, charType);

                    var lastAlpha = oldChar.alpha;
                    oldChar.alpha = 0.00001;
                    oldChar.active = false;

                    playState.boyfriend = playState.boyfriendMap.get(charName);

                    if (playState.charSwapUpdateX || playState.charSwapUpdateY) {
                        var newX = playState.charSwapUpdateX ? (playState.BF_X + playState.boyfriend.playerOffsetX) : playState.boyfriend.x;
                        var newY = playState.charSwapUpdateY ? (playState.BF_Y + playState.boyfriend.playerOffsetY) : playState.boyfriend.y;
                        playState.boyfriend.setPosition(newX, newY);
                    }

                    playState.boyfriend.alpha = lastAlpha;
                    playState.boyfriend.active = true;
                    playState.iconP1.switchAnim(playState.boyfriend.curCharacter);

                    if (deleteBefore && playState.boyfriendMap.exists(oldChar.curCharacter))
                        playState.removeCharacterFromList(oldChar.curCharacter, charType);
                }
                playState.setAllHaxeVar('boyfriend', playState.boyfriend);
            case 1:
                oldChar = playState.dad;
                if (oldChar.curCharacter != charName) {
                    if (!playState.dadMap.exists(charName))
                        playState.addCharacterToList(charName, charType);

                    var wasGf = oldChar.curCharacter.startsWith('gf');
                    var lastAlpha = oldChar.alpha;
                    oldChar.alpha = 0.00001;
                    oldChar.active = false;

                    playState.dad = playState.dadMap.get(charName);

                    if (playState.charSwapUpdateX || playState.charSwapUpdateY) {
                        var newX = playState.charSwapUpdateX ? (playState.DAD_X + playState.dad.enemyOffsetX) : playState.dad.x;
                        var newY = playState.charSwapUpdateY ? (playState.DAD_Y + playState.dad.enemyOffsetY) : playState.dad.y;
                        playState.dad.setPosition(newX, newY);
                    }

                    if (playState.dad.curCharacter.startsWith('gf'))
                        if (playState.gf != null) playState.gf.visible = false;
                    else if (wasGf && playState.gf != null)
                        playState.gf.visible = true;

                    oldChar.alpha = lastAlpha;
                    playState.dad.alpha = lastAlpha;
                    playState.dad.active = true;
                    playState.iconP2.switchAnim(playState.dad.curCharacter);

                    if (deleteBefore && playState.dadMap.exists(oldChar.curCharacter))
                        playState.removeCharacterFromList(oldChar.curCharacter, charType);
                }
                playState.setAllHaxeVar('dad', playState.dad);
            case 2:
                if (playState.gf == null) return;
                oldChar = playState.gf;

                if (oldChar.curCharacter != charName) {
                    if (!playState.gfMap.exists(charName))
                        playState.addCharacterToList(charName, charType);

                    var lastAlpha = oldChar.alpha;
                    oldChar.alpha = 0.00001;
                    oldChar.active = false;

                    playState.gf = playState.gfMap.get(charName);

                    if (playState.charSwapUpdateX || playState.charSwapUpdateY) {
                        var newX = playState.charSwapUpdateX ? (playState.GF_X + playState.gf.camOffsetX) : playState.gf.x;
                        var newY = playState.charSwapUpdateY ? (playState.GF_Y + playState.gf.camOffsetY) : playState.gf.y;
                        playState.gf.setPosition(newX, newY);
                    }

                    playState.gf.alpha = lastAlpha;
                    playState.gf.active = true;

                    if (deleteBefore && playState.gfMap.exists(oldChar.curCharacter))
                        playState.removeCharacterFromList(oldChar.curCharacter, charType);
                }
                playState.setAllHaxeVar('gf', playState.gf);
        }

        playState.reloadHealthBarColors();
    }

    public static function changeCharacter(playState:PlayState, value1:String, value2:String, value3:String):Void {
        var charType:Int = 0;

        switch (value1.toLowerCase()) {
            case 'bf', 'boyfriend', '0':
                charType = 0;
            case 'dad', 'opponent', '1':
                charType = 1;
            case 'gf', 'girlfriend', '2':
                charType = 2;
            default:
                charType = Std.parseInt(value1);
                if (Math.isNaN(charType)) charType = 0;
        }

        var deleteBefore = (value3 == 'true' || value3 == '1');
        changeCharacterCore(playState, value2, charType, deleteBefore);
    }

    public static function eventPushed(playState:PlayState, event:EventNote):Void {
        if (event.event == 'Change Character') {
            var charType:Int = 0;
            switch(event.value1.toLowerCase()) {
                case 'gf' | 'girlfriend' | '1': charType = 2;
                case 'dad' | 'opponent' | '0': charType = 1;
                default:
                    charType = Std.parseInt(event.value1);
                    if (Math.isNaN(charType)) charType = 0;
            }
            playState.addCharacterToList(event.value2, charType);
        }

        if (!playState.eventPushedMap.exists(event.event))
            playState.eventPushedMap.set(event.event, true);
    }

    public static function eventNoteEarlyTrigger(event:EventNote):Float
        return 0;

    public static function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
        return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

    public static function sortEventNotes(playState:PlayState):Void {
        if (playState.eventNotes != null && playState.eventNotes.length > 1)
            playState.eventNotes.sort(sortByTime);
    }

    public static function checkEventNote(playState:PlayState):Void {
        var len = playState.eventNotes.length;
        while (playState.eventIndex < len) {
            var event = playState.eventNotes[playState.eventIndex];
            if (Conductor.songPosition < event.strumTime)
                break;

            var value1:String = (event.value1 != null) ? event.value1 : '';
            var value2:String = (event.value2 != null) ? event.value2 : '';
            var value3:String = (event.value3 != null) ? event.value3 : '';
            triggerEventNote(playState, event.event, value1, value2, value3);
            playState.eventIndex++;
        }
    }

    public static function triggerEventNote(playState:PlayState, eventName:String, value1:String, value2:String, value3:String):Void {
        var val1Trim = value1.trim();
        var val2Trim = value2.trim();

        switch (eventName) {
            case 'Hey!':
                var value:Int = 2;
                switch(val1Trim.toLowerCase()) {
                    case 'bf' | 'boyfriend' | '0':
                        value = 0;
                    case 'gf' | 'girlfriend' | '1':
                        value = 1;
                }

                var time:Float = Std.parseFloat(value2);
                if (Math.isNaN(time) || time <= 0) time = 0.6;

                if (value != 0) {
                    if (playState.dad.curCharacter.startsWith('gf')) {
                        playState.dad.playAnim('cheer', true);
                        playState.dad.specialAnim = true;
                        playState.dad.heyTimer = time;
                    } else if (playState.gf != null) {
                        playState.gf.playAnim('cheer', true);
                        playState.gf.specialAnim = true;
                        playState.gf.heyTimer = time;
                    }
                }
                if (value != 1) {
                    playState.boyfriend.playAnim('hey', true);
                    playState.boyfriend.specialAnim = true;
                    playState.boyfriend.heyTimer = time;
                }

            case 'Set GF Speed':
                var value:Int = Std.parseInt(value1);
                if (Math.isNaN(value) || value < 1) value = 1;
                playState.gfSpeed = value;

            case 'Add Camera Zoom':
                if (FlxG.camera.zoom < playState.maxCamZoom) {
                    var camZoom:Float = Std.parseFloat(value1);
                    var hudZoom:Float = Std.parseFloat(value2);
                    if (Math.isNaN(camZoom)) camZoom = 0.015;
                    if (Math.isNaN(hudZoom)) hudZoom = 0.03;

                    FlxG.camera.zoom += camZoom;
                    playState.camHUD.zoom += hudZoom;
                }

            case 'Play Animation':
                var char:Character = playState.dad;
                switch(val2Trim.toLowerCase()) {
                    case 'bf' | 'boyfriend':
                        char = playState.boyfriend;
                    case 'gf' | 'girlfriend':
                        char = playState.gf;
                    default:
                        var val2:Int = Std.parseInt(val2Trim);
                        if (Math.isNaN(val2)) val2 = 0;

                        switch(val2) {
                            case 1: char = playState.boyfriend;
                            case 2: char = playState.gf;
                        }
                }

                if (char != null) {
                    char.playAnim(value1, true);
                    char.specialAnim = true;
                }
            case 'Camera Follow Pos':
                var val1:Float = Std.parseFloat(value1);
                var val2:Float = Std.parseFloat(value2);
                var hasPos:Bool = !Math.isNaN(val1) || !Math.isNaN(val2);

                if (Math.isNaN(val1)) val1 = 0;
                if (Math.isNaN(val2)) val2 = 0;

                if (!hasPos) {
                    playState.forceCamera = false;
                    playState.cancelTweensOn(playState.camFollow);
                    playState.cancelTweensOn(playState.camHUD.scroll);
                } else {
                    playState.forceCamera = true;
                    var moveType:String = 'snap';
                    var moveDuration:Float = 0.5;
                    var moveEase:String = 'linear';
                    var moveTarget:String = 'game';

                    if (value3 != null && value3.trim().length > 0) {
                        var split:Array<String> = value3.split(',');
                        if (split[0] != null && split[0].trim().length > 0) moveType = split[0].trim().toLowerCase();
                        if (split[1] != null && split[1].trim().length > 0) {
                            var parsedDur:Float = Std.parseFloat(split[1].trim());
                            if (!Math.isNaN(parsedDur)) moveDuration = parsedDur;
                        }
                        if (split[2] != null && split[2].trim().length > 0) moveEase = split[2].trim();
                        if (split[3] != null && split[3].trim().length > 0) moveTarget = split[3].trim().toLowerCase();
                    }

                    var doGame:Bool = (moveTarget == 'game' || moveTarget == 'both');
                    var doHud:Bool = (moveTarget == 'hud' || moveTarget == 'both');

                    playState.cancelTweensOn(playState.camFollow);
                    playState.cancelTweensOn(playState.camHUD.scroll);

                    if (moveType == 'tween' && moveDuration > 0) {
                        var ease:Float->Float = CoolUtil.getMoveEase(moveEase);
                        if (doGame)
                            playState.addTrackedTween(playState.camFollow, {x: val1, y: val2}, moveDuration, {ease: ease});
                        if (doHud)
                            playState.addTrackedTween(playState.camHUD.scroll, {x: val1, y: val2}, moveDuration, {ease: ease});
                    } else {
                        if (doGame) {
                            playState.camFollow.x = val1;
                            playState.camFollow.y = val2;
                        }
                        if (doHud) {
                            playState.camHUD.scroll.x = val1;
                            playState.camHUD.scroll.y = val2;
                        }
                    }
                }
            case 'Alt Idle Animation':
                var char:Character = playState.dad;
                switch(value1.toLowerCase()) {
                    case 'gf' | 'girlfriend':
                        char = playState.gf;
                    case 'boyfriend' | 'bf':
                        char = playState.boyfriend;
                    default:
                        var val:Int = Std.parseInt(value1);
                        if (Math.isNaN(val)) val = 0;
                        switch(val) {
                            case 1: char = playState.boyfriend;
                            case 2: char = playState.gf;
                        }
                }

                if (char != null) {
                    char.idleSuffix = value2;
                }
            case 'Screen Shake':
                var valuesArray:Array<String> = [value1, value2];
                var targetsArray:Array<FlxCamera> = [playState.camGame, playState.camHUD];
                for (i in 0...targetsArray.length) {
                    var split:Array<String> = valuesArray[i].split(',');
                    var duration:Float = 0;
                    var intensity:Float = 0;
                    if (split[0] != null) duration = Std.parseFloat(split[0].trim());
                    if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
                    if (Math.isNaN(duration)) duration = 0;
                    if (Math.isNaN(intensity)) intensity = 0;

                    if (duration > 0 && intensity != 0)
                        targetsArray[i].shake(intensity, duration);
                }
            case 'Change Character':
                changeCharacter(playState, value1, value2, value3);
            case 'Change Scroll Speed':
                var val1:Float = Std.parseFloat(value1);
                var val2:Float = Std.parseFloat(value2);

                if (Math.isNaN(val1)) val1 = 1;
                if (Math.isNaN(val2)) val2 = 0;

                var newValue:Float = playState.daScrollSpeed * val1;

                if (val2 <= 0) {
                    playState.daScrollSpeed = newValue;
                    for (note in playState.notes) {
                        if (note.isSustainNote && !note.isHoldEnd) {
                            note.scale.y = note.getSustainScale();
                            note.updateHitbox();
                        }
                    }
                } else {
                    playState.songSpeedTween = FlxTween.tween(playState, {daScrollSpeed: newValue}, val2, {
                        ease: FlxEase.linear,

                        onUpdate: function(twn:FlxTween) {
                            for (note in playState.notes) {
                                if (note.isSustainNote && !note.isHoldEnd) {
                                    note.scale.y = note.getSustainScale();
                                    note.updateHitbox();
                                }
                            }
                        },

                        onComplete: function(twn:FlxTween) {
                            playState.songSpeedTween = null;

                            for (note in playState.notes) {
                                if (note.isSustainNote) {
                                    note.scale.y = note.getSustainScale();
                                    note.updateHitbox();
                                }
                            }
                        }
                    });

                    playState.modTweens.push(playState.songSpeedTween);
                }
            case 'Setting Crossfades':
                var val1:Float = Std.parseFloat(value1);
                var val2:Float = Std.parseFloat(value2);
                if (Math.isNaN(val1)) val1 = 0.75;
                if (Math.isNaN(val2)) val2 = 1.0;

                playState.cfDuration = val1;
                playState.cfIntensity = val2;
                playState.cfBlend = (value3 == '') ? 'normal' : value3;
            case 'Flash Screen':
                var flashColor:FlxColor = FlxColor.fromString(value1);
                var duration:Float = Std.parseFloat(value2);
                var alpha:Float = Std.parseFloat(value3);

                if (Math.isNaN(duration) || duration <= 0)
                    duration = 0.4;
                if (Math.isNaN(alpha) || alpha <= 0)
                    alpha = 1.0;
                if (flashColor == 0)
                    flashColor = FlxColor.WHITE;

                FlxG.camera.flash(flashColor, duration, null, true);
                playState.camHUD.flash(flashColor, duration * 0.75, null, true);
                playState.camHUD.alpha = alpha;
            case 'Add Filter':
                var filterName:String = val1Trim.toLowerCase();
                var targetCam:String = val2Trim.toLowerCase();
                var filter = CoolUtil.getFilter(filterName);
                var filterArray:Array<openfl.filters.BitmapFilter> = (filter != null) ? [filter] : null;
                switch (targetCam) {
                    case 'hud' | 'camhud' | '1':
                        playState.camHUD.setFilters(filterArray);
                    case 'game' | 'camgame' | '0':
                        playState.camGame.setFilters(filterArray);
                    case 'all' | 'both' | '2':
                        playState.camGame.setFilters(filterArray);
                        playState.camHUD.setFilters(filterArray);
                    default:
                        playState.camGame.setFilters(filterArray);
                }
        }
        playState.callAllHScript('onEvent', [eventName, value1, value2, value3]);
    }
}
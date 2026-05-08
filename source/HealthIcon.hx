package;

import flixel.FlxSprite;
import lime.utils.Assets;
import lime.system.System;
import flash.display.BitmapData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;

import sys.FileSystem;
#end
import haxe.Json;
import haxe.format.JsonParser;
import tjson.TJSON;
using StringTools;
enum abstract IconState(Int) from Int to Int {
	var Normal;
	var Dying;
	var Poisoned;
	var Winning;
}
class HealthIcon extends FlxSprite
{
	var player:Bool = false;
	public var sprTracker:FlxSprite;
	public var iconState(default, set):IconState = Normal;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var hasAnim:Bool = false;
	public var frameCount:Int = 1;
	
	function set_iconState(x:IconState):IconState {
        if (!hasAnim)
        {
            var frameIndex:Int = switch(x) {
                case Normal: 0;
                case Dying: frameCount > 1 ? 1 : 0;
                case Poisoned: frameCount > 2 ? 2 : 0;
                case Winning: frameCount > 3 ? 3 : 0;
            };
            animation.curAnim.curFrame = frameIndex;
        }
        else
        {
            var animNames:Map<IconState, String> = [
                Normal => 'normal',
                Dying => 'losing',
                Poisoned => 'poison',
                Winning => 'winning'
            ];
            
            var targetAnim = animNames.get(x);
            var currentAnimName = animation.curAnim != null ? animation.curAnim.name : '';
            
            if (targetAnim != currentAnimName)
            {
                if (targetAnim == 'winning' && animation.getByName('winning') == null)
                    animation.play('normal', true);
                else if (animation.getByName(targetAnim) != null)
                    animation.play(targetAnim, true);
            }
        }

        return iconState = x;
    }
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		player = isPlayer;
		super();
		antialiasing = true;
		switchAnim(char);
		scrollFactor.set();

	}
	public function switchAnim(char:String = 'bf') {
		var charJson:Dynamic = CoolUtil.parseJson(FNFAssets.getJson(SUtil.getPath() + "assets/images/custom_chars/custom_chars"));
		var iconJson:Dynamic = CoolUtil.parseJson(FNFAssets.getJson(SUtil.getPath() + "assets/images/custom_chars/icon_only_chars"));
		
		var iconData:Dynamic = null;
		if (Reflect.hasField(charJson, char))
			iconData = Reflect.field(charJson, char);
		else if (Reflect.hasField(iconJson, char))
			iconData = Reflect.field(iconJson, char);
		
		var iconFrames:Array<Int> = iconData != null && Reflect.hasField(iconData, 'icons') ? Reflect.field(iconData, 'icons') : 
									  iconData != null && Reflect.hasField(iconData, 'frames') ? Reflect.field(iconData, 'frames') : [0, 0, 0, 0];
		var isAnimated:Bool = iconData != null && Reflect.hasField(iconData, 'isAnimatedIcon') ? Reflect.field(iconData, 'isAnimatedIcon') :
							   iconData != null && Reflect.hasField(iconData, 'isAnimated') ? Reflect.field(iconData, 'isAnimated') : false;
		var iconAnimations:Array<String> = iconData != null && Reflect.hasField(iconData, 'iconAnimations') ? Reflect.field(iconData, 'iconAnimations') :
											iconData != null && Reflect.hasField(iconData, 'animations') ? Reflect.field(iconData, 'animations') : [];
		var boWidth:Int = iconData != null && Reflect.hasField(iconData, 'iconWidth') ? Reflect.field(iconData, 'iconWidth') :
						  iconData != null && Reflect.hasField(iconData, 'width') ? Reflect.field(iconData, 'width') : 150;
		var boHeight:Int = iconData != null && Reflect.hasField(iconData, 'iconHeight') ? Reflect.field(iconData, 'iconHeight') :
						   iconData != null && Reflect.hasField(iconData, 'height') ? Reflect.field(iconData, 'height') : 150;

		frameCount = iconFrames.length;
		hasAnim = isAnimated;

		//loading
		var iconPath:String = SUtil.getPath() + 'assets/images/custom_chars/' + char;
		var iconPngPath:String = iconPath + "/icons.png";
		var iconXmlPath:String = iconPath + "/icons.xml";
		
		if (FNFAssets.exists(iconPngPath))
		{
			if (isAnimated && FNFAssets.exists(iconXmlPath))
			{
				var rawPic:BitmapData = FNFAssets.getBitmapData(iconPngPath);
				var rawXml:String = FNFAssets.getText(iconXmlPath);
				frames = FlxAtlasFrames.fromSparrow(rawPic, rawXml);
				
				var animPrefixes = ['normal', 'losing', 'poison', 'winning'];
				for (i in 0...animPrefixes.length)
				{
					if (i < iconAnimations.length)
						animation.addByPrefix(animPrefixes[i], iconAnimations[i], 24, true, player);
				}
			}
			else
			{
				var rawPic:BitmapData = FNFAssets.getBitmapData(iconPngPath);
				loadGraphic(rawPic, true, boWidth, boHeight);
				animation.add('icon', iconFrames, false, player);
			}
		}
		else
		{
			makeGraphic(150, 150, 0x00000000);
			hasAnim = false;
			frameCount = 1;
		}

		if (!hasAnim)
		{
			animation.play('icon');
			animation.pause();
		}
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10 + xAdd, sprTracker.y + yAdd - 30);
	}
}

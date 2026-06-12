package animateatlas;

import flixel.util.FlxDestroyUtil;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.Assets;
import haxe.Json;
import openfl.display.BitmapData;
import animateatlas.JSONData.AtlasData;
import animateatlas.JSONData.AnimationData;
import animateatlas.displayobject.SpriteAnimationLibrary;
import animateatlas.displayobject.SpriteMovieClip;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFrame;

#if desktop
import sys.FileSystem;
import sys.io.File;
#elseif !mobile
import js.html.FileSystem;
import js.html.File;
#end

using StringTools;

class AtlasFrameMaker extends FlxFramesCollection
{
	public static function construct(key:String, ?_excludeArray:Array<String> = null, ?noAntialiasing:Bool = false):FlxFramesCollection
	{
		var frameCollection:FlxFramesCollection;
		var frameArray:Array<Array<FlxFrame>> = [];
		var animationData:AnimationData = Json.parse(FNFAssets.getText(key + 'Animation.json'));
		var atlasData:AtlasData = Json.parse(FNFAssets.getText(key + 'spritemap.json').replace("\uFEFF", ""));
		var graphic:FlxGraphic = FNFAssets.getGraphicData(key + 'spritemap.png');
			
		var baseBitmap:BitmapData = graphic.bitmap;
		var pageIndex:Int = 1;
		while (FNFAssets.exists(key + 'spritemap' + pageIndex + '.json'))
		{
			var extraAtlasData:AtlasData = Json.parse(FNFAssets.getText(key + 'spritemap' + pageIndex + '.json').replace("\uFEFF", ""));
			var extraGraphic:FlxGraphic = FNFAssets.getGraphicData(key + 'spritemap' + pageIndex + '.png');
			if (extraGraphic != null && extraGraphic.bitmap != null && extraAtlasData != null)
			{
				var baseBitmap:BitmapData = graphic.bitmap;
				var combinedWidth:Int = Std.int(Math.max(baseBitmap.width, extraGraphic.bitmap.width));
				var oldHeight:Int = baseBitmap.height;
				var combinedHeight:Int = oldHeight + extraGraphic.bitmap.height;

				var stitchedCanvas:BitmapData = new BitmapData(combinedWidth, combinedHeight, true, 0);
				stitchedCanvas.copyPixels(baseBitmap, baseBitmap.rect, new Point(0, 0));
				stitchedCanvas.copyPixels(extraGraphic.bitmap, extraGraphic.bitmap.rect, new Point(0, oldHeight));
				
				if (extraAtlasData.ATLAS != null && extraAtlasData.ATLAS.SPRITES != null)
				{
					for (sprite in extraAtlasData.ATLAS.SPRITES)
					{
						sprite.SPRITE.y += oldHeight;
						if (atlasData.ATLAS != null && atlasData.ATLAS.SPRITES != null)
						{
							atlasData.ATLAS.SPRITES.push(sprite);
						}
					}
				}
				if (baseBitmap != graphic.bitmap) {
					baseBitmap.dispose();
				}
				baseBitmap = stitchedCanvas;
			}
			pageIndex++;
		}
		if (pageIndex > 1) {
			graphic = FlxGraphic.fromBitmapData(baseBitmap, false, null, false);
		}
		var ss:SpriteAnimationLibrary = new SpriteAnimationLibrary(animationData, atlasData, graphic.bitmap);
		var t:SpriteMovieClip = ss.createAnimation(noAntialiasing);
		
		if(_excludeArray == null)
		{
			_excludeArray = t.getFrameLabels();
		}
		trace('Creating: ' + _excludeArray);
		frameCollection = new FlxFramesCollection(graphic, IMAGE);
		for(x in _excludeArray)
		{
			frameArray.push(getFramesArray(t, x));
		}

		for(x in frameArray)
		{
			for(y in x)
			{
				frameCollection.pushFrame(y);
			}
		}
		return frameCollection;
	}

	@:noCompletion static function getFramesArray(t:SpriteMovieClip, animation:String):Array<FlxFrame>
	{
		var startFrame:Int = t.getFrame(animation);
		if (startFrame == -1) {
			trace("Warning: Animation label '" + animation + "' not found!");
			return [];
		}

		var sizeInfo:Rectangle = new Rectangle(0, 0);
		t.currentLabel = animation;
		var bitMapArray:Array<BitmapData> = [];
		var daFramez:Array<FlxFrame> = [];
		var firstPass = true;
		var frameSize:FlxPoint = FlxPoint.get(0, 0);
		
		for (i in startFrame...t.numFrames)
		{
			t.currentFrame = i;
			@:privateAccess if (t.symbol != null) {
				t.symbol.update();
			}

			if (t.currentLabel == animation)
			{
				sizeInfo = t.getBounds(t);
				var targetWidth:Int = Std.int(sizeInfo.width + sizeInfo.x);
				var targetHeight:Int = Std.int(sizeInfo.height + sizeInfo.y);
				
				if (targetWidth <= 0 || targetHeight <= 0) {
					targetWidth = 1;
					targetHeight = 1;
				}

				var bitmapShit:BitmapData = new BitmapData(targetWidth, targetHeight, true, 0);
				bitmapShit.draw(t, null, null, null, null, true);
				bitMapArray.push(bitmapShit);
				
				if (firstPass)
				{
					frameSize.set(bitmapShit.width, bitmapShit.height);
					firstPass = false;
				}
			}
			else break;
		}
		
		for (i in 0...bitMapArray.length)
		{
			var b = FlxGraphic.fromBitmapData(bitMapArray[i]);
			var theFrame = new FlxFrame(b);
			theFrame.parent = b;
			theFrame.name = animation + i;
			theFrame.sourceSize.set(frameSize.x, frameSize.y);
			theFrame.frame = FlxRect.get(0, 0, bitMapArray[i].width, bitMapArray[i].height);
			daFramez.push(theFrame);
		}
		frameSize.put();
		
		return daFramez;
	}
}
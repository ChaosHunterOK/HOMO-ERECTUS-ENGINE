package;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;
import animateatlas.AtlasFrameMaker;
/**
 * A sprite that automatically handles loading files dynamically. This is used in hscripts by default.
 * Only overwrites "loadGraphic."
 */
class DynamicSprite extends FlxSprite {
    override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String) {
        if ((Graphic is String)) {
            // show time baby
            var data = FNFAssets.getBitmapData(Graphic);
            return super.loadGraphic(data, Animated, Width, Height, Unique, Key);
        }
        return super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
    }
}
/**
 * A replacement for FlxAtlasFrames that dynamically handles loading assets.
 * Passed to hscripts by default.
 * Because of how this works only "fromSparrow" and "fromSpriteSheetPAcker is supported."
 */
class DynamicAtlasFrames {
    public static function fromSparrow(png:FlxGraphicAsset, xml:String) {
        if (FNFAssets.exists(xml)) {
            xml = FNFAssets.getText(xml);
        }
        if ((png is String)) {
            // show time again
            png = FNFAssets.getBitmapData(png);
        }
        return FlxAtlasFrames.fromSparrow(png, xml);
    }
    public static function fromSpriteSheetPacker(png:FlxGraphicAsset, txt:String) {
		if (FNFAssets.exists(txt))
		{
			txt = FNFAssets.getText(txt);
		}
		if ((png is String))
		{
			// show time again
			png = FNFAssets.getBitmapData(png);
		}
        return FlxAtlasFrames.fromSpriteSheetPacker(png,txt);
    }
    public static function fromTextureAtlas(folder:String) {
        try {
            return AtlasFrameMaker.construct(folder);
        } catch(e:Dynamic) {
            trace("Error loading Animate Atlas at " + folder + ": " + e);
            return null;
        }
    }
    public static function fromAnimate(png:FlxGraphicAsset, spriteJson:String, animationJson:String) {
        if ((png is String)) {
            png = FNFAssets.getBitmapData(png);
        }
        
        // convert paths to content if they are strings
        if (FNFAssets.exists(spriteJson)) spriteJson = FNFAssets.getText(spriteJson);
        if (FNFAssets.exists(animationJson)) animationJson = FNFAssets.getText(animationJson);
        return AtlasFrameMaker.construct(folderPathFromPath(spriteJson)); 
    }

    private static function folderPathFromPath(path:String):String {
        var parts = path.split('/');
        parts.pop();
        return parts.join('/');
    }
}
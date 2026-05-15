package;

// A helper class to make supporting web easier
//#if sys
import sys.FileSystem;
import animateatlas.AtlasFrameMaker;
import sys.io.File;
//#end
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import openfl.display.BitmapData;
import openfl.display.MovieClip;
import openfl.media.Sound;
import haxe.io.Path;
import flixel.FlxG;
import flash.net.FileReference;
import flash.events.Event;
import openfl.events.IOErrorEvent;
import haxe.io.Bytes;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetType;
import openfl.system.System;
using StringTools;
enum Extensions {
	None;
	Json;
	Hscript;
}
/**
 * Assets reader and writer
 */
class FNFAssets {
    public static var _file:FileReference;
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];
	private static function resolvePath(id:String):String {
		#if sys
		return Assets.exists(id) ? Assets.getPath(id) : id;
		#else
		return id;
		#end
	}
	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> = [
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'fonts',
		'scripts'
	];
	#end
    public static function getText(id:String):String {
        #if sys
            if (!isInScope(id))
                throw "Tried to access a file that is out of scope.";
            if (Assets.exists(id))
                return Assets.getText(id);
            try {
                return File.getContent(id);
            } catch (e:Any) {
                throw 'File $id doesn\'t exist or cannot be read.';
            }
        #else
            return Assets.getText(id);
        #end
    }
	static public function getJson(id:String):Null<String> {
		return getAmbigAsset([id], CoolUtil.JSON_EXT, AssetType.TEXT);
	}
	static public function getHscript(id:String):Null<String> {
		return getAmbigAsset([id], CoolUtil.HSCRIPT_EXT, AssetType.TEXT);
	}
	public static function getAssetWithBackup(id:String, backupID:String, type:AssetType):Dynamic {
		if (FNFAssets.exists(id)) {
			return FNFAssets.getAsset(id, type);
		}
		return FNFAssets.getAsset(backupID, type);
	} 
	public static function getAsset(id:String, type:AssetType):Dynamic {
		switch (type) {
			case TEXT:
				return FNFAssets.getText(id);
			case BINARY:
				return FNFAssets.getBytes(id);
			case MUSIC | SOUND:
				return FNFAssets.getSound(id);
			case IMAGE:
				return FNFAssets.getBitmapData(id);
			default:
				throw "Unsure of how to get type " + type;
		}
	}
	public static function getAmbigAsset(id:Array<String>, ext:Array<String>, type:AssetType):Dynamic {
		var fullPath = existsAmbig(id, ext);
		return fullPath != '' ? getAsset(fullPath, type) : null;
	}
	public static function existsAmbig(id:Array<String>, extension:Array<String>):String {
		for (path in id)
			for (ext in extension)
				if (exists(path + '.' + ext))
					return path + '.' + ext;
		return '';
	}
	public static function getBytes(id:String):Bytes {
		#if sys
		if (!isInScope(id))
			throw "Tried to access a file that is out of scope.";
		if (Assets.exists(id))
			return Assets.getBytes(id);
		try {
			return File.getBytes(id);
		} catch (e:Any) {
			throw 'File $id doesn\'t exist or cannot be read.';
		}
		#else
		return LimeAssets.getBytes(id);
		#end
	}
    static public function exists(id:String, ?ext:Extensions):Bool {
		switch (ext) {
			case Json: 
				return existsAmbig([id], CoolUtil.JSON_EXT) != '';
			case Hscript: 
				return existsAmbig([id], CoolUtil.HSCRIPT_EXT) != '';
			default: 
				if (!isInScope(id))
					return false;
				#if sys
				var path = Assets.exists(id) ? Assets.getPath(id) : null;
				if (path == null)
					path = id;
				else
					return true;
				return FileSystem.exists(path);
				#else
				return Assets.exists(id);
				#end
		}
    }
	public static function isInScope(id:String) {
		#if sys
		if (Assets.exists(id))
			return true;
		if (!Path.normalize(FileSystem.absolutePath(id)).contains(Path.normalize(Main.cwd)))
			return false;
		#end
		return true;
	}
	 public static function getBitmapData(id:String, ?useCache:Bool = true):BitmapData {
        #if sys
			if (!isInScope(id))
				throw "Tried to access a file that is out of scope.";
            if (Assets.exists(id))
                return Assets.getBitmapData(id, useCache);
			try {
				return BitmapData.fromFile(id);
			} catch (e:Any) {
				throw 'File $id doesn\'t exist or cannot be read.';
			}
        #else
            return Assets.getBitmapData(id, useCache);
        #end
    }

	public static function getImage(id:String):Null<FlxGraphic>
		{
			var newBitmap:BitmapData = null;
			if (currentTrackedAssets.exists(id))
				{
					return currentTrackedAssets.get(id);
				}
				else{
			if(FileSystem.exists(id)) {
				if(!currentTrackedAssets.exists(id)) {
					newBitmap = BitmapData.fromFile(id);
					var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, id);
					newGraphic.persist = true;
			        newGraphic.destroyOnNoUse = false;
					currentTrackedAssets.set(id, newGraphic);
					return newGraphic;
				}
				
			}
		}
	
			return null;
		}
	public static function getGraphicData(id:String):Null<FlxGraphic>
	{
		if(FileSystem.exists(id)) {
			if(!currentTrackedAssets.exists(id)) {
				var newBitmap:BitmapData = BitmapData.fromFile(id);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, id);
				currentTrackedAssets.set(id, newGraphic);
			}
			return currentTrackedAssets.get(id);
		}

		return null;
	}

	public static function precacheSound(path:String):Sound
	{
		return getSound(path);
	}
	public static function getSound(id:String, ?useCache:Bool = true):Sound {
		#if sys
		if (!isInScope(id))
			throw "Out of scope";

		var path = resolvePath(id);

		if (currentTrackedSounds.exists(path))
			return currentTrackedSounds.get(path);

		var snd = Sound.fromFile(path);
		currentTrackedSounds.set(path, snd);
		return snd;
		#else
		return Assets.getSound(id, useCache);
		#end
	}
    public static function saveContent(id:String, data:String):Void {
        #if sys
			if (!isInScope(id))
				throw "Tried to access a file that is out of scope.";
			try {
				File.saveContent(id, data);
			} catch (e:Any) {
				throw "Couldn't save to " + id + ". Is it in use?";
			}
        #else
            askToSave(id, data);
        #end
    }
	public static function saveBytes(id:String, data:Bytes):Void {
		#if sys
		if (!isInScope(id))
			throw "Tried to access a file that is out of scope.";
		try {
			File.saveBytes(id, data);
		} catch (e:Any) {
			throw "Couldn't save to " + id + ". Is it in use?";
		}
		#else
		askToSave(id, data);
		#end
	}
	public static function askToSave(id:String, data:Dynamic)
	{
		_file = new FileReference();

		_file.addEventListener(Event.COMPLETE, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		var idSus = Path.withoutDirectory(id);
		_file.save(data, idSus);
	}
	
	static function cleanupFileReference():Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}
	
	static function onSaveComplete(_):Void {
		cleanupFileReference();
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}
	
	static function onSaveCancel(_):Void {
		cleanupFileReference();
	}
	
	static function onSaveError(_):Void {
		cleanupFileReference();
		FlxG.log.error("Problem saving Level data");
	}
	public static function clearStoredMemory(?cleanUnused:Bool = false):Void {
		@:privateAccess {
			// Clear tracked assets
			for (key in currentTrackedAssets.keys()) {
				var obj = currentTrackedAssets.get(key);
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
				}
			}
			currentTrackedAssets.clear();
			for (key in FlxG.bitmap._cache.keys()) {
				var obj = FlxG.bitmap._cache.get(key);
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
				}
			}
			EdtNote.coolCustomGraphics = [];
			Note.specialFramesKey = [];
			Note.gotSpecialFrames = [];
		}
		for (key in currentTrackedSounds.keys()) {
			Assets.cache.clear(key);
		}
		currentTrackedSounds.clear();
		openfl.Assets.cache.clear("assets");
		openfl.Assets.cache.clear("assets/sounds");
		openfl.Assets.cache.clear("assets/music");
		System.gc();
	}
}
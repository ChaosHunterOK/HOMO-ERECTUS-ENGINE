package;

// A helper class to make supporting web easier
//#if sys
import sys.FileSystem;
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
import flixel.graphics.frames.FlxAtlasFrames;
import DynamicSprite.DynamicAtlasFrames;
import lime.media.AudioBuffer;
#if (sys && target.threaded)
import sys.thread.Thread;
import sys.thread.Lock;
#end
using StringTools;
enum Extensions {
	None;
	Json;
	Hscript;
}
#if (sys && target.threaded)
typedef PendingSound = {
	var lock:Lock;
	var buffer:Null<AudioBuffer>;
}
#end
/**
 * Assets reader and writer
 */
class FNFAssets {
    public static var _file:FileReference;
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];
	private static var MAX_ASSET_CACHE_SIZE:Int = 50;
	private static var MAX_SOUND_CACHE_SIZE:Int = 30;
	private static var assetAccessOrder:Array<String> = [];
	private static var soundAccessOrder:Array<String> = [];
	private static var extractedVideoPaths:Map<String, String> = new Map();
	private static var existsCache:Map<String, Bool> = new Map();
	private static var scopeCache:Map<String, Bool> = new Map();
	private static var cwdRaw:String = null;
	private static var cwdNormalized:String = null;
	private static var bitmapCache:Map<String, BitmapData> = new Map();
	private static var bitmapCacheOrder:Array<String> = [];
	private static inline var MAX_BITMAP_CACHE_SIZE:Int = 128;
	private static var atlasCache:Map<String, FlxAtlasFrames> = new Map();
	public static var asyncAudioPreload:Bool = true;
	#if (sys && target.threaded)
	private static var pendingSounds:Map<String, PendingSound> = new Map();
	#end
	private static function resolvePath(id:String):String {
		#if sys
		return Assets.exists(id) ? Assets.getPath(id) : id;
		#else
		return id;
		#end
	}
	public static function getVideo(id:String):String
	{
		#if sys
		if (!isInScope(id))
			throw "Tried to access a video that is out of scope.";

		var path = resolvePath(id);
		if (path != null && path != "" && FileSystem.exists(path))
			return path;

		if (Assets.exists(id))
		{
			var cachedPath = extractedVideoPaths.get(id);
			if (cachedPath != null && cachedPath != "" && FileSystem.exists(cachedPath))
				return cachedPath;

			var extractedPath = extractEmbeddedAsset(id);
			if (extractedPath != "")
			{
				extractedVideoPaths.set(id, extractedPath);
				return extractedPath;
			}
		}

		if (!FileSystem.exists(path))
			throw 'Video $path doesn\'t exist.';

		return path;
		#else
		return id;
		#end
	}

	private static function extractEmbeddedAsset(id:String):String
	{
		#if sys
		if (!Assets.exists(id))
			return "";

		var bytes = Assets.getBytes(id);
		if (bytes == null)
			return "";

		var fileName = Path.withoutDirectory(id);
		if (fileName == "" || fileName == ".")
			fileName = "asset";

		var extension = Path.extension(id);
		if (extension != "")
			fileName = fileName + "." + extension;

		var tempDir = Path.join([Main.cwd, "TempFiles", "embedded_assets"]);
		if (!FileSystem.exists(tempDir))
			FileSystem.createDirectory(tempDir);

		var outputPath = Path.join([tempDir, fileName]);
		try {
			File.saveBytes(outputPath, bytes);
			return outputPath;
		} catch (e:Any) {
			trace("Failed to extract embedded asset " + id + " to " + outputPath + ": " + e);
			return "";
		}
		#else
		return "";
		#end
	}

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
		if (FNFAssets.exists(id))
			return FNFAssets.getAsset(id, type);
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
				#if sys
				var cachedExists = existsCache.get(id);
				if (cachedExists != null)
					return cachedExists;
				var result = existsUncached(id);
				existsCache.set(id, result);
				return result;
				#else
				if (!isInScope(id))
					return false;
				return Assets.exists(id);
				#end
		}
    }
	#if sys
	private static function existsUncached(id:String):Bool {
		if (!isInScope(id))
			return false;
		var path = Assets.exists(id) ? Assets.getPath(id) : null;
		if (path == null)
			path = id;
		else
			return true;
		return FileSystem.exists(path);
	}
	#end
	public static function clearExistsCache(?id:String):Void {
		if (id != null)
			existsCache.remove(id);
		else
			existsCache.clear();
	}
	public static function isInScope(id:String):Bool {
		#if sys
		var cached = scopeCache.get(id);
		if (cached != null)
			return cached;
		var result:Bool = true;
		if (!Assets.exists(id)) {
			if (cwdRaw != Main.cwd || cwdNormalized == null) {
				cwdRaw = Main.cwd;
				cwdNormalized = Path.normalize(Main.cwd);
			}
			result = Path.normalize(FileSystem.absolutePath(id)).contains(cwdNormalized);
		}
		scopeCache.set(id, result);
		return result;
		#else
		return true;
		#end
	}
	 public static function getBitmapData(id:String, ?useCache:Bool = true):BitmapData {
        #if sys
			if (!isInScope(id))
				throw "Tried to access a file that is out of scope.";
            if (Assets.exists(id))
                return Assets.getBitmapData(id, useCache);
			if (useCache) {
				var cachedBmp = bitmapCache.get(id);
				if (cachedBmp != null && cachedBmp.width > 0)
					return cachedBmp;
				if (cachedBmp != null) {
					bitmapCache.remove(id);
					bitmapCacheOrder.remove(id);
				}
			}
			try {
				var bmp = BitmapData.fromFile(id);
				if (useCache && bmp != null) {
					if (bitmapCacheOrder.length >= MAX_BITMAP_CACHE_SIZE)
						bitmapCache.remove(bitmapCacheOrder.shift());
					bitmapCache.set(id, bmp);
					bitmapCacheOrder.push(id);
				}
				return bmp;
			} catch (e:Any) {
				throw 'File $id doesn\'t exist or cannot be read.';
			}
        #else
            return Assets.getBitmapData(id, useCache);
        #end
    }

	public static function getImage(id:String):Null<FlxGraphic>
		{
			if (currentTrackedAssets.exists(id)) {
				updateLRU(id, assetAccessOrder);
				return currentTrackedAssets.get(id);
			}
			if (!FileSystem.exists(id)) return null;
			if (assetAccessOrder.length >= MAX_ASSET_CACHE_SIZE)
				evictOldestAsset();
			try {
				var newBitmap:BitmapData = BitmapData.fromFile(id);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, id);
				newGraphic.persist = true;
				newGraphic.destroyOnNoUse = false;
				currentTrackedAssets.set(id, newGraphic);
				assetAccessOrder.push(id);
				return newGraphic;
			} catch (e:Any) {
				trace("Error loading image " + id + ": " + e);
				return null;
			}
		}
	public static function getGraphicData(id:String):Null<FlxGraphic>
	{
		if (currentTrackedAssets.exists(id)) {
			updateLRU(id, assetAccessOrder);
			return currentTrackedAssets.get(id);
		}
		if (!FileSystem.exists(id)) return null;
		if (assetAccessOrder.length >= MAX_ASSET_CACHE_SIZE)
			evictOldestAsset();
		
		try {
			var newBitmap:BitmapData = BitmapData.fromFile(id);
			var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, id);
			currentTrackedAssets.set(id, newGraphic);
			assetAccessOrder.push(id);
			return newGraphic;
		} catch (e:Any) {
			trace("Error loading graphic " + id + ": " + e);
			return null;
		}
	}
	public static function getAtlasFrames(png:String, xml:String):FlxAtlasFrames {
		var key = png + "|" + xml;
		var cached = atlasCache.get(key);
		if (cached != null && cached.parent != null && cached.parent.bitmap != null && cached.parent.bitmap.width > 0)
			return cached;
		var frames = DynamicAtlasFrames.fromSparrow(png, xml);
		if (frames != null)
			atlasCache.set(key, frames);
		else
			atlasCache.remove(key);
		return frames;
	}
	public static function preloadSoundAsync(id:String):Void {
		#if (sys && target.threaded)
		if (!asyncAudioPreload)
			return;
		try {
			if (!isInScope(id))
				return;
			var path = resolvePath(id);
			if (currentTrackedSounds.exists(path) || pendingSounds.exists(path))
				return;
			if (!FileSystem.exists(path))
				return;
			var entry:PendingSound = {lock: new Lock(), buffer: null};
			pendingSounds.set(path, entry);
			Thread.create(function() {
				try {
					entry.buffer = AudioBuffer.fromFile(path);
				} catch (e:Any) {
					entry.buffer = null;
				}
				entry.lock.release();
			});
		} catch (e:Any) {
			trace("Async preload failed for " + id + ": " + e);
		}
		#end
	}

	//i think its better yeah
	private static function takePending(path:String):Null<Sound> {
		#if (sys && target.threaded)
		var entry = pendingSounds.get(path);
		if (entry == null)
			return null;
		pendingSounds.remove(path);
		entry.lock.wait();
		return entry.buffer == null ? null : Sound.fromAudioBuffer(entry.buffer);
		#else
		return null;
		#end
	}

	public static function takePreloadedSound(id:String):Null<Sound> {
		#if sys
		return takePending(resolvePath(id));
		#else
		return null;
		#end
	}

	public static function precacheSound(path:String):Sound
		return getSound(path);
	public static function getSound(id:String, ?useCache:Bool = true):Sound {
		#if sys
		if (!isInScope(id))
			throw "Out of scope";

		var path = resolvePath(id);
		if (currentTrackedSounds.exists(path)) {
			updateLRU(path, soundAccessOrder);
			return currentTrackedSounds.get(path);
		}
		if (soundAccessOrder.length >= MAX_SOUND_CACHE_SIZE)
			evictOldestSound();
		
		try {
			var snd = takePending(path);
			if (snd == null) {
				if (!FileSystem.exists(path)) {
					trace("Warning: Sound file does not exist: " + path);
					return null;
				}
				snd = Sound.fromFile(path);
			}
			currentTrackedSounds.set(path, snd);
			soundAccessOrder.push(path);
			return snd;
		} catch (e:Any) {
			trace("Error loading sound " + path + ": " + e);
			return null;
		}
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
				existsCache.remove(id);
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
			existsCache.remove(id);
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
	
	static function onSaveCancel(_):Void
		cleanupFileReference();
	
	static function onSaveError(_):Void {
		cleanupFileReference();
		FlxG.log.error("Problem saving Level data");
	}
	private static function getMapSize<K, V>(map:Map<K, V>):Int
	{
		var count = 0;
		for (key in map.keys())
			count++;
		return count;
	}
	
	private static function updateLRU(id:String, orderArray:Array<String>):Void
	{
		var index = orderArray.indexOf(id);
		if (index >= 0)
			orderArray.splice(index, 1);
		orderArray.push(id);
	}
	
	private static function evictOldestAsset():Void
	{
		if (assetAccessOrder.length == 0) return;
		
		var oldestId = assetAccessOrder.shift();
		var asset = currentTrackedAssets.get(oldestId);
		if (asset != null) {
			try {
				asset.destroy();
			} catch (e:Any) {}
		}
		currentTrackedAssets.remove(oldestId);
		trace("Evicted asset from cache: " + oldestId);
	}
	private static function evictOldestSound():Void
	{
		if (soundAccessOrder.length == 0) return;
		
		var oldestId = soundAccessOrder.shift();
		var sound = currentTrackedSounds.get(oldestId);
		if (sound != null) {
			try {
				Assets.cache.clear(oldestId);
			} catch (e:Any) {}
		}
		currentTrackedSounds.remove(oldestId);
		trace("Evicted sound from cache: " + oldestId);
	}

	public static function clearStoredMemory(?cleanUnused:Bool = false):Void {
		@:privateAccess {
			try {
				var keysToRemove:Array<String> = [];
				for (key in currentTrackedAssets.keys()) {
					keysToRemove.push(key);
				}
				for (key in keysToRemove) {
					var obj = currentTrackedAssets.get(key);
					if (obj != null) {
						try { openfl.Assets.cache.removeBitmapData(key); } catch(e:Any) {}
						try { FlxG.bitmap._cache.remove(key); } catch(e:Any) {}
						obj.destroy();
					}
					currentTrackedAssets.remove(key);
				}
				currentTrackedAssets.clear();
				var bitmapKeysToRemove:Array<String> = [];
				for (key in FlxG.bitmap._cache.keys()) {
					bitmapKeysToRemove.push(key);
				}
				for (key in bitmapKeysToRemove) {
					var obj = FlxG.bitmap._cache.get(key);
					if (obj != null) {
						try { openfl.Assets.cache.removeBitmapData(key); } catch(e:Any) {}
						try { FlxG.bitmap._cache.remove(key); } catch(e:Any) {}
						try { obj.destroy(); } catch(e:Any) {}
					}
				}
				EdtNote.coolCustomGraphics = [];
				Note.specialFramesKey = [];
				Note.gotSpecialFrames = [];
			} catch(e:Any) {
				trace("Error clearing bitmap assets: " + e);
			}
		}

		try {
			var soundKeysToRemove:Array<String> = [];
			for (key in currentTrackedSounds.keys()) {
				soundKeysToRemove.push(key);
			}
			for (key in soundKeysToRemove) {
				try { Assets.cache.clear(key); } catch(e:Any) {}
				currentTrackedSounds.remove(key);
			}
			currentTrackedSounds.clear();
		} catch(e:Any) {
			trace("Error clearing sounds: " + e);
		}

		try {
			openfl.Assets.cache.clear("assets");
			openfl.Assets.cache.clear("assets/sounds");
			openfl.Assets.cache.clear("assets/music");
		} catch(e:Any) {
			trace("Error clearing asset cache: " + e);
		}
		
		assetAccessOrder.splice(0, assetAccessOrder.length);
		soundAccessOrder.splice(0, soundAccessOrder.length);

		existsCache.clear();
		bitmapCache.clear();
		bitmapCacheOrder.splice(0, bitmapCacheOrder.length);
		atlasCache.clear();
		#if (sys && target.threaded)
		pendingSounds.clear();
		#end
		
		openfl.system.System.gc();
	}
	
	public static function unloadAsset(id:String):Void
	{
		if (currentTrackedAssets.exists(id)) {
			var asset = currentTrackedAssets.get(id);
			if (asset != null) {
				try {
					asset.destroy();
				} catch (e:Any) {}
			}
			currentTrackedAssets.remove(id);
			var index = assetAccessOrder.indexOf(id);
			if (index >= 0) assetAccessOrder.splice(index, 1);
		}
	}
	
	public static function unloadSound(id:String):Void
	{
		if (currentTrackedSounds.exists(id)) {
			try {
				Assets.cache.clear(id);
			} catch (e:Any) {}
			currentTrackedSounds.remove(id);
			var index = soundAccessOrder.indexOf(id);
			if (index >= 0) soundAccessOrder.splice(index, 1);
		}
	}
}
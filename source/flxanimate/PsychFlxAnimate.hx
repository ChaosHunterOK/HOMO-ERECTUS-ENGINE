package flxanimate;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flxanimate.FlxAnimate as OriginalFlxAnimate;
import flxanimate.data.AnimationData;
import flxanimate.frames.FlxAnimateFrames;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
typedef SpritemapSource =
{
	var data:Dynamic;
	var image:FlxGraphicAsset;
}

private class AtlasCacheEntry
{
	public var frames:FlxAtlasFrames;
	public var graphics:Array<FlxGraphic> = [];
	public var users:Int = 0;
	public var disposed:Bool = false;
	var oldPersist:Array<Bool> = [];
	var oldDestroyOnNoUse:Array<Bool> = [];
	var balance:Array<FlxGraphic> = [];

	public function new(frames:FlxAtlasFrames, graphics:Array<FlxGraphic>, combined:Bool)
	{
		this.frames = frames;
		this.graphics = graphics;
		for (g in graphics)
		{
			oldPersist.push(g.persist);
			oldDestroyOnNoUse.push(g.destroyOnNoUse);
			g.persist = true;
			if (combined) balance.push(g);
		}
	}
	public function isAlive():Bool
	{
		if (disposed || frames == null) return false;
		for (g in graphics)
			if (g == null || g.bitmap == null || g.bitmap.width <= 0) return false;
		return true;
	}
	public function dispose(destroy:Bool = true):Void
	{
		if (disposed) return;
		disposed = true;

		for (i in 0...graphics.length)
		{
			var g = graphics[i];
			if (g == null) continue;
			g.persist = oldPersist[i];
			g.destroyOnNoUse = oldDestroyOnNoUse[i];
		}

		if (destroy)
		{
			for (g in balance)
			{
				if (g == null || g.bitmap == null) continue;
				#if (flixel >= "5.6.0")
				g.decrementUseCount();
				#else
				g.useCount--;
				#end
			}
			for (g in graphics)
				if (g != null && g.bitmap != null) FlxG.bitmap.removeIfNoUse(g);
		}

		frames = null;
		graphics = [];
		balance = [];
	}
}
class PsychFlxAnimate extends OriginalFlxAnimate
{
	static var cache:Map<String, AtlasCacheEntry> = new Map();
	var cacheEntry:AtlasCacheEntry = null;
	public var cacheKey(default, null):String = null;
	public static function isCached(key:String):Bool
	{
		if (key == null) return false;
		var entry = cache.get(key);
		if (entry == null) return false;
		if (entry.isAlive()) return true;

		cache.remove(key);
		entry.dispose(false);
		return false;
	}
	public static function clearCache():Void
	{
		for (key in cache.keys())
		{
			var entry = cache.get(key);
			if (entry != null) entry.dispose(entry.users <= 0);
		}
		cache = new Map();
	}
	public function loadAtlasEx(img:FlxGraphicAsset, pathOrStr:String = null, myJson:Dynamic = null, ?key:String):Bool
	{
		if (pathOrStr == null || myJson == null)
		{
			FlxG.log.error('PsychFlxAnimate: loadAtlasEx needs both a spritemap and an Animation.json');
			return false;
		}

		var anim:Dynamic = (myJson is String) ? resolveText(myJson) : myJson;
		return loadAtlasData(anim, [{data: resolveText(pathOrStr), image: img}], null, null, key);
	}
	public function loadAtlasData(animation:Dynamic, spritemaps:Array<SpritemapSource>, ?metadata:String, ?library:Map<String, String>, ?key:String):Bool
	{
		releaseCache();

		try
		{
			var animJson = normalizeAnimation(animation, metadata, library);
			if (animJson == null) return false;

			// 1. frames (shared)
			var entry:AtlasCacheEntry = null;
			if (key != null && isCached(key))
				entry = cache.get(key);
			else
			{
				entry = buildEntry(spritemaps);
				if (entry == null) return false;
				if (key != null) cache.set(key, entry);
			}

			entry.users++;
			cacheEntry = entry;
			cacheKey = key;
			frames = entry.frames;
			anim._loadAtlas(animJson);
			if (anim.curInstance == null || anim.curSymbol == null)
			{
				FlxG.log.error('PsychFlxAnimate: the atlas has no main symbol.');
				return false;
			}
			origin.copyFrom(anim.curInstance.symbol.transformationPoint);
			return true;
		}
		catch (e:haxe.Exception)
		{
			FlxG.log.error('PsychFlxAnimate: failed to load atlas: ' + e.message);
			trace('PsychFlxAnimate: failed to load atlas: ' + e.details());
			return false;
		}
	}

	function buildEntry(spritemaps:Array<SpritemapSource>):AtlasCacheEntry
	{
		if (spritemaps == null || spritemaps.length == 0)
		{
			FlxG.log.error('PsychFlxAnimate: no spritemaps were given.');
			return null;
		}

		var list:Array<FlxAtlasFrames> = [];
		var graphics:Array<FlxGraphic> = [];

		for (sm in spritemaps)
		{
			if (sm == null || sm.image == null) continue;

			var graphic:FlxGraphic = FlxG.bitmap.add(sm.image);
			if (graphic == null || graphic.bitmap == null || graphic.bitmap.width <= 0)
			{
				FlxG.log.error('PsychFlxAnimate: a spritemap image is missing or was disposed.');
				continue;
			}

			var data:Dynamic = sm.data;
			if (data is String) data = resolveText(data);

			var sheet:FlxAtlasFrames = null;
			if (data is String)
			{
				var text:String = removeBOM(data).trim();
				if (text.charAt(0) == '<') sheet = FlxAnimateFrames.fromSparrow(cast Xml.parse(text), graphic);
				else sheet = FlxAnimateFrames.fromSpriteMap(cast haxe.Json.parse(text), graphic);
			}
			else
				sheet = FlxAnimateFrames.fromSpriteMap(cast data, graphic);

			if (sheet == null) continue;

			list.push(sheet);
			if (graphics.indexOf(graphic) == -1) graphics.push(graphic);
		}

		if (list.length == 0)
		{
			FlxG.log.error('PsychFlxAnimate: none of the spritemaps could be parsed.');
			return null;
		}

		if (list.length == 1) return new AtlasCacheEntry(list[0], graphics, false);

		var combined = new FlxAnimateFrames();
		for (sheet in list)
			combined.addAtlas(sheet);
		return new AtlasCacheEntry(combined, graphics, true);
	}
	function normalizeAnimation(animation:Dynamic, metadata:String, library:Map<String, String>):AnimAtlas
	{
		var json:Dynamic = null;
		if (animation is String) json = haxe.Json.parse(removeBOM(animation));
		else json = animation;

		if (json == null)
		{
			FlxG.log.error('PsychFlxAnimate: Animation.json is empty.');
			return null;
		}

		// metadata.json (split export) wins over whatever is inside Animation.json
		var md:Dynamic = null;
		if (metadata != null && metadata.trim().length > 0)
			md = haxe.Json.parse(removeBOM(metadata));
		if (md == null) md = getField(json, ['MD', 'metadata']);
		if (md == null) md = {};

		if (getField(md, ['FRT', 'framerate']) == null) Reflect.setField(md, 'FRT', 24);
		Reflect.setField(json, 'MD', md);

		var hasLibrary:Bool = false;
		if (library != null)
		{
			var sd:Dynamic = getField(json, ['SD', 'SYMBOL_DICTIONARY']);
			if (sd == null)
			{
				sd = {};
				Reflect.setField(json, 'SD', sd);
			}

			var symbolsKey:String = Reflect.hasField(sd, 'Symbols') && !Reflect.hasField(sd, 'S') ? 'Symbols' : 'S';
			var symbols:Array<Dynamic> = Reflect.field(sd, symbolsKey);
			if (symbols == null)
			{
				symbols = [];
				Reflect.setField(sd, symbolsKey, symbols);
			}

			var known:Map<String, Bool> = new Map();
			for (s in symbols)
			{
				var n:String = getField(s, ['SN', 'SYMBOL_name']);
				if (n != null) known.set(n, true);
			}

			for (name => text in library)
			{
				if (known.exists(name)) continue;
				symbols.push({SN: name, TL: haxe.Json.parse(removeBOM(text))});
				hasLibrary = true;
			}
			if (hasLibrary && getField(md, ['V', 'version']) == null) Reflect.setField(md, 'V', '1.0.0');
		}

		return cast json;
	}

	static function getField(obj:Dynamic, names:Array<String>):Dynamic
	{
		if (obj == null) return null;
		for (n in names)
			if (Reflect.hasField(obj, n)) return Reflect.field(obj, n);
		return null;
	}
	function resolveText(str:String):String
	{
		if (str == null) return null;

		var trimmed:String = str.trim();
		var lower:String = trimmed.toLowerCase();
		var isPath:Bool = (lower.endsWith('.json') || lower.endsWith('.xml')) && trimmed.charAt(0) != '{' && trimmed.charAt(0) != '<';
		if (!isPath) return str;

		#if sys
		if (FileSystem.exists(trimmed)) return File.getContent(trimmed);
		#end
		return openfl.utils.Assets.getText(trimmed);
	}

	static function removeBOM(str:String):String
	{
		if (str != null && str.length > 0 && str.charCodeAt(0) == 0xFEFF) return str.substr(1);
		return str;
	}

	function releaseCache():Void
	{
		var entry = cacheEntry;
		var key = cacheKey;
		cacheEntry = null;
		cacheKey = null;
		if (entry == null || entry.disposed) return;
		if (frames == entry.frames) frames = null;

		entry.users--;
		if (entry.users > 0) return;

		if (key != null && cache.get(key) == entry) cache.remove(key);
		entry.dispose();
	}

	override function draw()
	{
		if (anim == null || frames == null || anim.curInstance == null || anim.curSymbol == null) return;
		super.draw();
	}

	override function destroy()
	{
		if (anim != null && anim.symbolDictionary == null) anim.symbolDictionary = new Map();

		try
		{
			super.destroy();
		}
		catch (e:haxe.Exception)
		{
			trace('PsychFlxAnimate: error while destroying: ' + e.message);
			try
			{
				frames = null;
			}
			catch (e2:haxe.Exception) {}
		}
		releaseCache();
	}

	public function pauseAnimation()
	{
		if (anim == null || anim.curInstance == null || anim.curSymbol == null) return;
		anim.pause();
	}

	public function resumeAnimation()
	{
		if (anim == null || anim.curInstance == null || anim.curSymbol == null) return;
		anim.resume();
	}
}
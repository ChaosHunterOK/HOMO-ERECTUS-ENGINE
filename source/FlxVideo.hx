#if web
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
#else
import openfl.events.Event;
#end
#if sys
import sys.FileSystem;
#end
#if cpp
import hxvlc.flixel.FlxVideoSprite;
import hxvlc.openfl.Video as VlcVideo;
#end
import StringTools;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class FlxVideo
{
	public static var instances:Array<FlxVideo> = [];

	public var finishCallback:Void->Void = null;

	public var stateCallback:FlxState;

	#if cpp
	public var videoSprite(default, null):FlxVideoSprite;
	#end
	public var sprite:FlxSprite;

	public var fadeToBlack:Bool = false;

	public var fadeFromBlack:Bool = false;

	public var allowSkip:Bool = false;
	public var repeat:Bool = false;

	public var isPaused(default, null):Bool = false;

	private var currentPath:String = "";

	private var isPlaybackFinished:Bool = false;

	public function new()
	{
		if (instances.indexOf(this) == -1)
			instances.push(this);
	}
	public function pause():Void
	{
		#if cpp
		if (videoSprite != null && videoSprite.bitmap != null && !isPaused)
		{
			try
			{
				videoSprite.bitmap.pause();
				isPaused = true;
			}
			catch (e:Dynamic)
			{
				trace("FlxVideo: failed to pause video: " + e);
			}
		}
		#end
	}
	public function resume():Void
	{
		#if cpp
		if (videoSprite != null && videoSprite.bitmap != null && isPaused)
		{
			try
			{
				videoSprite.bitmap.resume();
				isPaused = false;
			}
			catch (e:Dynamic)
			{
				trace("FlxVideo: failed to resume video: " + e);
			}
		}
		#end
	}
	public function hide():Void
	{
		#if cpp
		if (videoSprite != null)
			videoSprite.visible = false;
		#end

		if (sprite != null)
			sprite.visible = false;

		kill();
	}
	public static function pauseAll():Void
	{
		for (video in instances)
			if (video != null)
				video.pause();
	}
	public static function resumeAll():Void
	{
		for (video in instances)
			if (video != null)
				video.resume();
	}
	public static function hideAll():Void
	{
		for (video in instances.copy())
			if (video != null)
				video.hide();
	}

	public function playMP4(path:String, ?repeat:Bool = false, ?outputTo:FlxSprite = null, ?isWindow:Bool = false, ?isFullscreen:Bool = false)
	{
		#if cpp
		isPlaybackFinished = false;
		this.repeat = repeat;

		if (isWindow || isFullscreen)
			trace("FlxVideo: isWindow/isFullscreen are no longer supported (FlxVideoSprite always renders in-scene) -- ignoring.");

		var resolvedPath = resolveVideoPath(path);
		if (resolvedPath == "")
		{
			trace("Video path is empty, skipping playback.");
			notifyPlaybackFinished();
			return;
		}

		#if sys
		if (!FileSystem.exists(resolvedPath) && resolvedPath.indexOf("http://") == -1 && resolvedPath.indexOf("https://") == -1 && resolvedPath.indexOf("file://") == -1)
		{
			trace("Video file does not exist, skipping playback: " + resolvedPath);
			notifyPlaybackFinished();
			return;
		}
		#end

		currentPath = resolvedPath;

		try
		{
			if (FlxG.stage == null)
			{
				trace("Stage is not ready yet, skipping video playback.");
				notifyPlaybackFinished();
				return;
			}

			cleanupVideo();

			videoSprite = new FlxVideoSprite();

			videoSprite.bitmap.onFormatSetup.add(onVLCVideoReady);
			videoSprite.bitmap.onEndReached.add(onVLCComplete);
			videoSprite.bitmap.onEncounteredError.add(onVLCError);

			if (outputTo != null)
				sprite = outputTo;

			if (sprite != null)
				videoSprite.visible = false;

			FlxG.state.add(videoSprite);

			if (allowSkip)
				FlxG.stage.addEventListener(Event.ENTER_FRAME, checkSkip);

			if (!videoSprite.load(currentPath))
			{
				trace("Failed to load video: " + currentPath);
				cleanupVideo();
				notifyPlaybackFinished();
				return;
			}

			videoSprite.play();
		}
		catch (e:Dynamic)
		{
			trace("Failed to start video playback: " + e);
			cleanupVideo();
			notifyPlaybackFinished();
		}
		#end
	}

	function resolveVideoPath(path:String):String
	{
		if (path == null)
			return "";

		var trimmed = StringTools.trim(path);

		if (trimmed == "")
			return "";

		#if sys
		if (trimmed.indexOf("http://") == 0 || trimmed.indexOf("https://") == 0 || trimmed.indexOf("file://") == 0)
			return trimmed;

		try
		{
			return FNFAssets.getVideo(trimmed);
		}
		catch (e:Dynamic)
		{
			trace("FNFAssets couldn't resolve video path '" + trimmed + "': " + e);
		}

		if (FileSystem.exists(trimmed))
			return FileSystem.absolutePath(trimmed);

		if (FileSystem.exists(Sys.getCwd() + "/" + trimmed))
			return FileSystem.absolutePath(Sys.getCwd() + "/" + trimmed);
		#end
		return trimmed;
	}

	#if cpp
	function onVLCVideoReady():Void
	{
		trace("video loaded!");

		if (sprite != null && videoSprite != null && videoSprite.bitmap != null && videoSprite.bitmap.bitmapData != null)
			sprite.loadGraphic(FlxGraphic.fromBitmapData(videoSprite.bitmap.bitmapData, false, null, false));

		if (fadeFromBlack)
			FlxG.camera.fade(FlxColor.BLACK, 0, false);
	}

	public function onVLCComplete():Void
	{
		if (repeat && videoSprite != null && !isPlaybackFinished)
		{
			videoSprite.load(currentPath);
			videoSprite.play();
			return;
		}

		if (videoSprite != null)
			videoSprite.stop();

		if (fadeToBlack)
			FlxG.camera.fade(FlxColor.BLACK, 0, false);

		if (fadeFromBlack)
			FlxG.camera.fade(FlxColor.BLACK, 1, true);

		trace("Big, Big Chungus, Big Chungus!");

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			cleanupVideo();
			notifyPlaybackFinished();
		});
	}

	function onVLCError(error:String):Void
	{
		trace("Video playback error: " + error);
		cleanupVideo();
		notifyPlaybackFinished();
	}
	#end

	public function kill()
	{
		#if cpp
		cleanupVideo();
		notifyPlaybackFinished();
		#end
		instances.remove(this);
	}

	private function cleanupVideo():Void
	{
		isPaused = false;

		#if cpp
		if (FlxG.stage != null)
		{
			try
				FlxG.stage.removeEventListener(Event.ENTER_FRAME, checkSkip)
			catch (e:Dynamic) {}
		}

		if (videoSprite != null)
		{
			try
				videoSprite.stop()
			catch (e:Dynamic) {}

			if (FlxG.state != null && FlxG.state.members.indexOf(videoSprite) != -1)
				FlxG.state.remove(videoSprite, true);

			try
				videoSprite.destroy()
			catch (e:Dynamic) {}

			videoSprite = null;
		}
		#end
	}

	private function notifyPlaybackFinished():Void
	{
		if (isPlaybackFinished)
			return;

		isPlaybackFinished = true;
		cleanupVideo();
		instances.remove(this);

		if (finishCallback != null)
		{
			finishCallback();
		}
		else if (stateCallback != null)
		{
			LoadingState.loadAndSwitchState(stateCallback);
		}
	}

	#if cpp
	function checkSkip(e:Event)
	{
		if (FlxG.keys.justPressed.ENTER)
			trySkip();
	}

	function trySkip()
	{
		if (allowSkip && videoSprite != null && videoSprite.bitmap != null && videoSprite.bitmap.isPlaying)
			onVLCComplete();
	}
	#end
}

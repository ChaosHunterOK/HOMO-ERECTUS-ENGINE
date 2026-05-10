package;

#if android
import android.Tools;
import android.Permissions;
import android.PermissionsList;
#end

import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;

import haxe.CallStack;
import haxe.io.Path;

import sys.FileSystem;
import sys.io.File;

import flash.system.System;

using StringTools;

class SUtil
{
	#if android
	static var androidPath:String;
	#end

	public static function getPath():String
	{
		#if android
		if (androidPath == null)
		{
			androidPath = Tools.getExternalStorageDirectory()
				+ '/.' + Application.current.meta.get('file') + '/';
		}

		return androidPath;
		#else
		return '';
		#end
	}
	
	public static function doTheCheck()
	{
		#if android
		try
		{
			requestPermissions();

			var basePath = getPath();

			if (!FileSystem.exists(basePath))
				FileSystem.createDirectory(basePath);

			if (!FileSystem.exists(basePath + "assets"))
			{
				alert(
					"Missing Files",
					"Assets folder not found.\nPlease extract the APK files correctly."
				);

				CoolUtil.browserLoad("https://youtu.be/zjvkTmdWvfU");
				System.exit(0);
			}
		}
		catch (e)
		{
			handleCrash("doTheCheck", e);
		}
		#end
	}

	#if android
	static function requestPermissions()
	{
		var granted = Permissions.getGrantedPermissions();

		if (!granted.contains(PermissionsList.READ_EXTERNAL_STORAGE)
		 || !granted.contains(PermissionsList.WRITE_EXTERNAL_STORAGE))
		{
			Permissions.requestPermissions([
				PermissionsList.READ_EXTERNAL_STORAGE,
				PermissionsList.WRITE_EXTERNAL_STORAGE
			]);
		}
	}
	#end
	public static function gameCrashCheck()
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
			UncaughtErrorEvent.UNCAUGHT_ERROR,
			onCrash
		);
	}
	static function onCrash(e:UncaughtErrorEvent):Void
	{
		handleCrash("crash", e.error);
	}

	static function handleCrash(tag:String, error:Dynamic)
	{
		var message = buildCrashMessage(error);

		var crashDir = getPath() + "crash/";

		if (!FileSystem.exists(crashDir))
			FileSystem.createDirectory(crashDir);

		var fileName = tag + "_" + formatDate() + ".txt";

		File.saveContent(crashDir + fileName, message);

		Sys.println(message);
		alert("Crash", message);

		System.exit(0);
	}
	static function buildCrashMessage(error:Dynamic):String
	{
		var msg = "ERROR!\n\n";
		msg += "Message: " + Std.string(error) + "\n\n";

		for (item in CallStack.exceptionStack(true))
		{
			msg += Std.string(item) + "\n";
		}

		return msg;
	}
	static function formatDate():String
	{
		return Date.now().toString()
			.replace(" ", "_")
			.replace(":", "'");
	}
	static function alert(title:String, text:String)
	{
		Application.current.window.alert(text, title);
	}

	#if android
	public static function saveContent(
		fileName:String = "file",
		extension:String = ".json",
		data:String = "empty"
	)
	{
		var saveDir = getPath() + "saves/";

		if (!FileSystem.exists(saveDir))
			FileSystem.createDirectory(saveDir);

		File.saveContent(saveDir + fileName + extension, data);

		alert("Done", "File saved successfully!");
	}
	public static function saveClipboard(data:String)
	{
		openfl.system.System.setClipboard(data);
		alert("Done", "Copied to clipboard!");
	}
	public static function copyContent(from:String, to:String)
	{
		if (!FileSystem.exists(to))
		{
			File.saveBytes(to, openfl.utils.Assets.getBytes(from));
		}
	}
	#end
}
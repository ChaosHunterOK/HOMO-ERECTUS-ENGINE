package;

import flixel.FlxG;
import flixel.FlxState;

class LoadingState extends FlxState
{
	public static function loadAndSwitchState(target:FlxState, ?allowDjkf:Bool)
	{
		PlayerSettings.player1.controls.setKeyboardScheme(Solo(false));
		if (Std.isOfType(target, ChartingState))
		{
			FlxG.switchState(new LoadingState());
			return;
		}

		FlxG.switchState(target);
	}

	override function create()
	{
		super.create();
		FlxG.switchState(new ChartingState());
	}

	public static function loadAndSwitchCustomState(scriptName:String,scriptPath:String = "assets/scripts/custom_menus/")
	{
		var fullPath = scriptPath + scriptName + ".hscript";
		if (!FNFAssets.exists(fullPath)) return;
		CustomState.customStateScriptPath = scriptPath;
		CustomState.customStateScriptName = scriptName;
		PlayerSettings.player1.controls.setKeyboardScheme(Solo(false));
		FlxG.switchState(new CustomState());
	}
}
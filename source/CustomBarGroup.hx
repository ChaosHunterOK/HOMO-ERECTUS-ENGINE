package;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxDestroyUtil;

class CustomBarGroup extends FlxSpriteGroup {
	public var updateBar:Void->Void;
	public var parentRef:Dynamic;
	public var variable:String;

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		if (updateBar != null) {
			updateBar();
		}
	}

	override public function destroy():Void {
		super.destroy();
		updateBar = null;
		parentRef = null;
		variable = null;
	}
}

import flixel.FlxSprite;

typedef TUI = {
	var isPixel:Bool;
	var builtInJudgement:Bool;
	var uses:String;
};
class Judgement extends FlxSprite {
	public static var uiJson:Dynamic;
	private static final JUDGEMENT_INDICES:Map<String, Int> = [
		"sick" => 0,
		"good" => 1,
		"bad" => 2,
		"shit" => 3,
		"wayoff" => 4,
		"miss" => 5
	];

	public function new(X:Float, Y:Float, Judged:String, Display:String, early:Bool, isPixel:Bool) {
		super(X, Y);

		var curUItype:TUI = Reflect.field(uiJson, PlayState.SONG.uiType);
		var basePath:String = SUtil.getPath() + 'assets/images/';
		var customPixel:Bool = isPixel;

		if (curUItype != null && curUItype.builtInJudgement) {
			var packPath:String = basePath + 'custom_ui/ui_packs/${curUItype.uses}/$Judged' + (isPixel ? '-pixel.png' : '.png');
			loadGraphic(FNFAssets.getBitmapData(packPath));
		} else {
			var judgeDir:String = basePath + 'judgements/$Display/';
			var singleImg:String = judgeDir + '$Judged' + (isPixel ? '-pixel.png' : '.png');
			var sheet1x6:String = judgeDir + 'judgement 1x6.png';
			var sheet2x6:String = judgeDir + 'judgement 2x6.png';

			if (FNFAssets.exists(singleImg)) {
				loadGraphic(FNFAssets.getBitmapData(singleImg));
			} else if (FNFAssets.exists(sheet1x6)) {
				var bitmap = FNFAssets.getBitmapData(sheet1x6);
				loadGraphic(bitmap, true, bitmap.width, Std.int(bitmap.height / 6));

				var frameIdx:Int = JUDGEMENT_INDICES.exists(Judged) ? JUDGEMENT_INDICES.get(Judged) : 0;
				animation.add('judgement', [frameIdx]);
				animation.play('judgement');

				setGraphicSize(Std.int(width / 1.5));
				customPixel = false;
			} else if (FNFAssets.exists(sheet2x6)) {
				var bitmap = FNFAssets.getBitmapData(sheet2x6);
				loadGraphic(bitmap, true, Std.int(bitmap.width / 2), Std.int(bitmap.height / 6));

				var baseIdx:Int = JUDGEMENT_INDICES.exists(Judged) ? JUDGEMENT_INDICES.get(Judged) : 0;
				var frameIdx:Int = (baseIdx * 2) + (early ? 0 : 1);
				
				animation.add('judgement', [frameIdx]);
				animation.play('judgement');

				setGraphicSize(Std.int(width / 1.5));
				customPixel = false;
			} else {
				var fallbackImg:String = basePath + 'judgements/normal/$Judged' + (isPixel ? '-pixel.png' : '.png');
				loadGraphic(fallbackImg);
			}
		}

		if (customPixel) {
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			antialiasing = false;
		}

		updateHitbox();
	}
}
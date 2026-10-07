package;

enum abstract Jury(Int) from Int to Int {
	var Judge1 = 0;
	var Judge2 = 1;
	var Judge3 = 2;
	var Judge4 = 3;
	var Judge5 = 4;
	var Judge6 = 5;
	var Judge7 = 6;
	var Judge8 = 7;
	var Judge9 = 8; // JUSTICE
	var Classic = 9;
	var Hard = 10;
}

class Judge {
	public static var sickJudge:Float = 45;
	public static var goodJudge:Float = 90;
	public static var badJudge:Float = 135;
	public static var shitJudge:Float = 166;
	public static var wayoffJudge:Float = 203;
	private static final JUDGE_PRESETS:Array<Array<Float>> = [
		[33, 68, 135, 203, 270],
		[29, 60, 120, 180, 239],
		[26, 52, 104, 157, 209],
		[22, 45, 90, 135, 180],
		[18, 38, 76, 113, 151],
		[15, 30, 59, 89, 119],
		[11, 23, 45, 68, 90],
		[7, 15, 30, 45, 59],
		[ 4, 9, 18, 27, 36]
	];

	public static function resetJudge():Void {
		sickJudge = 45;
		goodJudge = 90;
		badJudge = 135;
		shitJudge = 166;
		wayoffJudge = 203;
	}

	public static function setJudge(judge:Jury):Void {
		trace(judge);

		if (judge == Classic) {
			resetJudge();
			return;
		}

		if (judge == Hard) {
			resetJudge();
			sickJudge /= 2;
			goodJudge /= 2;
			badJudge /= 2;
			shitJudge /= 2;
			wayoffJudge /= 2;
			return;
		}

		var preset:Array<Float> = JUDGE_PRESETS[judge];
		if (preset != null) {
			sickJudge = preset[0];
			goodJudge = preset[1];
			badJudge = preset[2];
			shitJudge = preset[3];
			wayoffJudge = preset[4];
		}
	}
}
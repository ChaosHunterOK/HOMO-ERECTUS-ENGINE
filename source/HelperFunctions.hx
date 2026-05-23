class HelperFunctions
{
	static inline var A1:Float = 0.254829592;
	static inline var A2:Float = -0.284496736;
	static inline var A3:Float = 1.421413741;
	static inline var A4:Float = -1.453152027;
	static inline var A5:Float = 1.061405429;
	static inline var P:Float = 0.3275911;
	static inline var MAX_POINTS:Float = 1.0;
	static inline var MISS_WEIGHT:Float = -5.5;
	static inline var RIDIC:Float = 5.0;
	static inline var MAX_BOO_WEIGHT:Float = 180.0;
	static inline var ZERO:Float = 65.0;
	static inline var DEV:Float = 22.7;

	public static inline function truncateFloat(number:Float, precision:Int):Float
	{
		var mult = Math.pow(10, precision);
		return Math.round(number * mult) / mult;
	}
	public static inline function erf(x:Float):Float
	{
		var sign = (x < 0) ? -1 : 1;
		x = Math.abs(x);
		var t = 1.0 / (1.0 + P * x);
		var poly = (((((A5 * t + A4) * t + A3) * t + A2) * t + A1) * t);
		return sign * (1.0 - poly * Math.exp(-x * x));
	}
	public static function getNotes():Int
	{
		var total = 0;
		var songNotes = PlayState.SONG.notes;

		for (section in songNotes)
		{
			for (note in section.sectionNotes)
			{
				if (note[1] <= 0)
					total++;
			}
		}

		return total;
	}
	public static function getHolds():Int
	{
		var total = 0;
		var songNotes = PlayState.SONG.notes;

		for (section in songNotes)
		{
			for (note in section.sectionNotes)
			{
				if (note[1] > 0)
					total++;
			}
		}

		return total;
	}
	public static inline function getMapMaxScore():Int
	{
		return getNotes() * 350;
	}
	public static inline function wife3(maxms:Float, ts:Float):Float
	{
		if (maxms <= RIDIC)
			return MAX_POINTS;

		if (maxms <= ZERO)
			return MAX_POINTS * erf((ZERO - maxms) / DEV);

		if (maxms <= MAX_BOO_WEIGHT)
			return (maxms - ZERO) * MISS_WEIGHT / (MAX_BOO_WEIGHT - ZERO);

		return MISS_WEIGHT;
	}
}
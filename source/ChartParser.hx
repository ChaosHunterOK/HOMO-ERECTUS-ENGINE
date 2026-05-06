package;

import flixel.util.FlxStringUtil;
using StringTools;

class ChartParser
{
	static public function parse(songName:String, section:Int):Array<Int>
	{
		var path = SUtil.getPath() + 'assets/data/' + songName + '/' + songName + '_section' + section + '.png';
		var csvData = FlxStringUtil.imageToCSV(path).replace("\n", ",");

		var rows = csvData.split(",").filter(s -> s != "");
		var dopeArray:Array<Int> = [];

		var widthInTiles = 0;
		var index = 0;

		while (index < rows.length)
		{
			var row:Array<String> = [];

			// build row dynamically
			while (index < rows.length && rows[index] != "")
			{
				row.push(rows[index++]);
			}
			index++; // skip separator

			if (row.length == 0)
				continue;

			if (widthInTiles == 0)
				widthInTiles = row.length;

			var pushed = false;

			for (column in 0...widthInTiles)
			{
				if (column >= row.length)
					break;

				var value = Std.parseInt(row[column]);
				if (value == null)
					throw 'Invalid integer at column $column: "${row[column]}"';

				if (value == 1)
				{
					dopeArray.push(column < 4 ? column + 1 : -column - 1 + 4);
					pushed = true;
				}
			}

			if (!pushed)
				dopeArray.push(0);
		}

		return dopeArray;
	}
}
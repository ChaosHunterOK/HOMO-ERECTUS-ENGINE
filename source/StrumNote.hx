package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxAtlasFrames;
import Judgement.TUI;
using StringTools;
import DynamicSprite.DynamicAtlasFrames;
import PlayState;
import NoteHoldCover;
//a StrumNote can fixed that spin angle offsets
@:access(flixel.animation.FlxAnimationController)
class StrumNote extends FlxSprite
{
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	public var isPixelNote:Bool = false;
	private var player:Int;
	var flippedNotes:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var holdCover:NoteHoldCover;
	public var holdStarted:Bool = false;
	public var holdEnding:Bool = false;
	var wasHolding:Bool = false;

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animOffsets = new Map<String, Array<Float>>();
		var curUiType:TUI = Reflect.field(Judgement.uiJson, PlayState.SONG.uiType);
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		flippedNotes = ModifierState.namedModifiers.flipped.value;
		isPixelNote = curUiType.isPixel;
		super(x, y);
		if(isPixelNote)
		loadGraphic(FNFAssets.getBitmapData(SUtil.getPath() + 'assets/images/custom_ui/ui_packs/' + curUiType.uses + "/arrows-pixels.png"), true, 17, 17);
		else
		frames = DynamicAtlasFrames.fromSparrow(SUtil.getPath() + 'assets/images/custom_ui/ui_packs/' + curUiType.uses + "/NOTE_assets.png", SUtil.getPath() + 'assets/images/custom_ui/ui_packs/' + curUiType.uses + "/NOTE_assets.xml");
						
		loadNoteAnims();
		scrollFactor.set();
		
		holdCover = new NoteHoldCover(this);
		
			animOffsets.set('static',[0,0]);
			animOffsets.set('pressed',[0,0]);
			animOffsets.set('confirm',[0,0]);
	}

	private function addPixelNoteAnims(staticFrame:Int, pressedFrames:Array<Int>, confirmFrames:Array<Int>, flippedStatic:Int = -1, flippedPressed:Array<Int> = null, flippedConfirm:Array<Int> = null):Void
	{
		animation.add('static', [staticFrame]);
		animation.add('pressed', pressedFrames, 12, false);
		animation.add('confirm', confirmFrames, 24, false);
		if (flippedNotes && flippedStatic != -1)
		{
			animation.add('static', [flippedStatic]);
			animation.add('pressed', flippedPressed, 12, false);
			animation.add('confirm', flippedConfirm, 24, false);
		}
	}

	private function loadPixelNoteAnims():Void
	{
		antialiasing = false;
		setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelscales[PlayState.SONG.mania]));
		animation.add('green', [6]);
		animation.add('red', [7]);
		animation.add('blue', [5]);
		animation.add('purplel', [4]);
		animation.add('space', [55]);
		if (flippedNotes)
		{
			animation.add('blue', [6]);
			animation.add('purplel', [7]);
			animation.add('green', [5]);
			animation.add('red', [4]);
		}

		var maniaType = Main.ammo[PlayState.SONG.mania];
		var noteType = Math.abs(noteData);

		if (maniaType == 4)
		{
			switch (noteType)
			{
				case 0: addPixelNoteAnims(0, [4, 8], [12, 16], 3, [7, 11], [15, 19]);
				case 1: addPixelNoteAnims(1, [5, 9], [13, 17], 2, [6, 10], [14, 18]);
				case 2: addPixelNoteAnims(2, [6, 10], [14, 18], 1, [5, 9], [13, 17]);
				case 3: addPixelNoteAnims(3, [7, 11], [15, 19], 0, [4, 8], [12, 16]);
			}
		}
		else if (maniaType == 6)
		{
			switch (noteType)
			{
				case 0: addPixelNoteAnims(0, [4, 8], [12, 16], 3, [7, 11], [15, 19]);
				case 1: addPixelNoteAnims(2, [6, 10], [14, 18], 1, [5, 9], [13, 17]);
				case 2: addPixelNoteAnims(3, [7, 11], [15, 19], 0, [4, 8], [12, 16]);
				case 3: addPixelNoteAnims(0, [36, 40], [44, 48], 3, [39, 43], [47, 51]);
				case 4: addPixelNoteAnims(1, [5, 9], [13, 17], 2, [6, 10], [14, 18]);
				case 5: addPixelNoteAnims(3, [39, 43], [47, 51], 0, [36, 40], [44, 48]);
			}
		}
		else if (maniaType == 7)
		{
			switch (noteType)
			{
				case 0: addPixelNoteAnims(0, [4, 8], [12, 16], 3, [7, 11], [15, 19]);
				case 1: addPixelNoteAnims(2, [6, 10], [14, 18], 1, [5, 9], [13, 17]);
				case 2: addPixelNoteAnims(3, [7, 11], [15, 19], 0, [4, 8], [12, 16]);
				case 3: animation.add('static', [52]); animation.add('pressed', [55, 53], 12, false); animation.add('confirm', [54, 55], 24, false);
				case 4: addPixelNoteAnims(0, [36, 40], [44, 48], 3, [39, 43], [47, 51]);
				case 5: addPixelNoteAnims(1, [5, 9], [13, 17], 2, [6, 10], [14, 18]);
				case 6: addPixelNoteAnims(3, [39, 43], [47, 51], 0, [36, 40], [44, 48]);
			}
		}
		else if (maniaType == 9)
		{
			switch (noteType)
			{
				case 0: addPixelNoteAnims(0, [4, 8], [12, 16], 3, [7, 11], [15, 19]);
				case 1: addPixelNoteAnims(1, [5, 9], [13, 17], 2, [6, 10], [14, 18]);
				case 2: addPixelNoteAnims(2, [6, 10], [14, 18], 1, [5, 9], [13, 17]);
				case 3: addPixelNoteAnims(3, [7, 11], [15, 19], 0, [4, 8], [12, 16]);
				case 4: animation.add('static', [52]); animation.add('pressed', [55, 53], 12, false); animation.add('confirm', [54, 55], 24, false);
				case 5: addPixelNoteAnims(0, [36, 40], [44, 48], 3, [39, 43], [47, 51]);
				case 6: addPixelNoteAnims(1, [37, 41], [45, 49], 2, [38, 42], [46, 50]);
				case 7: addPixelNoteAnims(2, [38, 42], [46, 50], 1, [37, 41], [45, 49]);
				case 8: addPixelNoteAnims(3, [39, 43], [47, 51], 0, [36, 40], [44, 48]);
			}
		}
	}

	private function loadSparrowNoteAnims():Void
	{
		animation.addByPrefix('green', 'arrowUP');
		animation.addByPrefix('blue', 'arrowDOWN');
		animation.addByPrefix('purple', 'arrowLEFT');
		animation.addByPrefix('red', 'arrowRIGHT');
		animation.addByPrefix('white', 'arrowSPACE');

		if (animation.getByName('white') == null)
		{
			animation.addByPrefix('white', 'arrowUP');
		}

		if (flippedNotes)
		{
			animation.addByPrefix('blue', 'arrowUP');
			animation.addByPrefix('green', 'arrowDOWN');
			animation.addByPrefix('red', 'arrowLEFT');
			animation.addByPrefix('purple', 'arrowRIGHT');
		}
		antialiasing = true;
		setGraphicSize(Std.int(width * Note.scales[PlayState.SONG.mania]));
		PlayState.instance.setArrowsAnim(this, noteData);
	}

	public function loadNoteAnims()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(isPixelNote)
		{
			loadPixelNoteAnims();
		}
		else
		{
			loadSparrowNoteAnims();
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function reloadSkin():Void
	{
		var curUiType:TUI = Reflect.field(Judgement.uiJson, PlayState.SONG.uiType);
		this.isPixelNote = curUiType.isPixel;
		animation = new FlxAnimationController(this);

		if (isPixelNote)
		{
			loadGraphic(FNFAssets.getBitmapData(SUtil.getPath() + 'assets/images/custom_ui/ui_packs/' + curUiType.uses + "/arrows-pixels.png"), true, 17, 17);
		}
		else
		{
			frames = DynamicAtlasFrames.fromSparrow(SUtil.getPath() + 'assets/images/custom_ui/ui_packs/' + curUiType.uses + "/NOTE_assets.png", SUtil.getPath() + 'assets/images/custom_ui/ui_packs/' + curUiType.uses + "/NOTE_assets.xml");
		}

		loadNoteAnims();
		playAnim('static');
		centerOrigin();
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swidths[PlayState.SONG.mania] * Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		x -= Note.posRest[PlayState.SONG.mania];
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		//if(animation.curAnim != null){ //my bad i was upset
		if(animation.curAnim.name == 'confirm' && !isPixelNote) {
			var daOffset = [0.0,0.0];
			if (animOffsets.exists('confirm'))
				{
					daOffset = animOffsets.get('confirm');
				}
			offset.x = (frameWidth - width) * 0.5+ daOffset[0];
		offset.y = (frameHeight - height) * 0.5 + daOffset[1];
			
		//}
		}

		super.update(elapsed);

		if (holdCover != null)
		{
			holdCover.x = x - 108;
			holdCover.y = y - 92;

			if (!holdStarted && wasHolding && !holdEnding)
			{
				holdEnding = true;
				holdCover.playEnd();
			}

			wasHolding = holdStarted;
		}
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		var daOffset = [0.0,0.0];
		if (animOffsets.exists(anim))
			{
		 daOffset = animOffsets.get(anim);
			}
		offset.x = (frameWidth - width) * 0.5 +daOffset[0];
		offset.y = (frameHeight - height) * 0.5 + daOffset[1];
		centerOrigin();
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
	//do nothing...since no shader... or you can add stuff here idk lol
		} else {
			if(animation.curAnim.name == 'confirm' && !isPixelNote) {
				centerOrigin();
			}
		}
	}
	public static function resetStrumPosition(strum:StrumNote, ?targetX:Null<Float> = null, ?targetY:Null<Float> = null):Void {
		if (strum == null) return;
		var baseX:Float = 92;
		baseX += Note.swidths[PlayState.SONG.mania] * Note.swagWidth * strum.noteData;
		baseX += ((FlxG.width / 2) * strum.player);
		baseX -= Note.posRest[PlayState.SONG.mania];

		var baseY:Float = strum.downScroll ? FlxG.height - 150 : 50; 
		strum.x = baseX + (targetX != null ? targetX : 0);
		strum.y = baseY + (targetY != null ? targetY : 0);

		//strum.updateHitbox();
	}
}
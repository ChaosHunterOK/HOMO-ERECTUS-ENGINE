import StringTools;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxSprite;
import Judgement.TUI;
import DynamicSprite.DynamicAtlasFrames;
import SUtil;
import StrumNote;

class NoteHoldCover extends FlxTypedSpriteGroup<FlxSprite>
{
  static final FRAMERATE_DEFAULT:Int = 24;
  public var strumNote:StrumNote;
  public var glow:FlxSprite;
  var sparks:FlxSprite;
  public var ending:Bool = false;

  public function new(strumNote:StrumNote)
  {
    super(0, 0);

    this.strumNote = strumNote;
    setupHoldNoteCover(strumNote);
  }
  function setupHoldNoteCover(strumNote:StrumNote):Void
  {
    glow = new FlxSprite();
    add(glow);

    sparks = new FlxSprite();
    add(sparks);

    var curUiType:TUI = Reflect.field(Judgement.uiJson, PlayState.SONG.uiType);
    var maniaIdx:Int = Std.int(Math.max(0, Math.min(Note.maniaData.length - 1, PlayState.SONG.mania - 1)));
    var ammo = Main.ammo[PlayState.SONG.mania];
    var colorIdx = Note.maniaData[maniaIdx][strumNote.noteData % ammo];
    var color = Note.colArray[colorIdx];
    var colorTitle = color.charAt(0).toUpperCase() + color.substr(1);
    var strumAlpha:Float = strumNote.alpha;

    //if (!strumNote.isPixelNote)
    //{
        var path = SUtil.getPath() + 'assets/images/custom_ui/ui_packs/' + curUiType.uses + "/holdCover" + colorTitle;

        glow.frames = DynamicAtlasFrames.fromSparrow(path + ".png", path + ".xml");

        glow.animation.addByPrefix('holdCoverStart' + colorTitle, 'holdCoverStart' + colorTitle, FRAMERATE_DEFAULT, false);
        glow.animation.addByPrefix('holdCover' + colorTitle, 'holdCover' + colorTitle, FRAMERATE_DEFAULT, true);
        glow.animation.addByPrefix('holdCoverEnd' + colorTitle, 'holdCoverEnd' + colorTitle, FRAMERATE_DEFAULT, false);

        glow.antialiasing = true;
        glow.updateHitbox();
        glow.centerOffsets();
        glow.centerOrigin();

        var finishSignal = Reflect.field(glow.animation, "onFinish");
        if (finishSignal != null)
        {
            Reflect.callMethod(finishSignal, Reflect.field(finishSignal, "add"), [onAnimationFinished]);
        }
        else
        {
            glow.animation.finishCallback = onAnimationFinished;
        }
        if (glow.animation.getByName('holdCoverStart' + colorTitle) == null && glow.animation.getByName('holdCoverStart') != null)
        {
            glow.animation.addByPrefix('holdCoverStart' + colorTitle, 'holdCoverStart', FRAMERATE_DEFAULT, false);
        }
        if (glow.animation.getByName('holdCover' + colorTitle) == null && glow.animation.getByName('holdCover') != null)
        {
            glow.animation.addByPrefix('holdCover' + colorTitle, 'holdCover', FRAMERATE_DEFAULT, true);
        }
        if (glow.animation.getByName('holdCoverEnd' + colorTitle) == null && glow.animation.getByName('holdCoverEnd') != null)
        {
            glow.animation.addByPrefix('holdCoverEnd' + colorTitle, 'holdCoverEnd', FRAMERATE_DEFAULT, false);
        }
    //}

    glow.alpha = 0.8 * strumAlpha;
    sparks.alpha = 0.8 * strumAlpha;
    this.alpha = 0.8 * strumAlpha;

    glow.visible = false;
    sparks.visible = false;
    this.visible = false;

    if (glow.animation.getAnimationList().length < 3)
    {
      trace('WARNING: NoteHoldCover failed to initialize all animations.');
    }
  }

  public override function update(elapsed):Void
  {
    super.update(elapsed);
    var a = 0.8 * strumNote.alpha;
    this.alpha = a;
    if (glow != null) glow.alpha = a;
    if (sparks != null) sparks.alpha = a;
  }

  public function playStart():Void
  {
    this.visible = true;
    glow.visible = true;
    if (sparks != null) sparks.visible = true;
    glow.setPosition(this.x, this.y);
    var maniaIdx:Int = Std.int(Math.max(0, Math.min(Note.maniaData.length - 1, PlayState.SONG.mania - 1)));
    var ammo = Main.ammo[PlayState.SONG.mania];
    var colorIdx = Note.maniaData[maniaIdx][strumNote.noteData % ammo];
    var color = Note.colArray[colorIdx];
    var colorTitle = color.charAt(0).toUpperCase() + color.substr(1);
    var anim = 'holdCoverStart' + colorTitle;
    if (glow.animation.curAnim == null || glow.animation.curAnim.name != anim)
    {
        glow.animation.play(anim, true);
    }
  }

  public function playContinue():Void
  {
    this.visible = true;
    glow.visible = true;
    if (sparks != null) sparks.visible = true;
    glow.setPosition(this.x, this.y);
    var maniaIdx:Int = Std.int(Math.max(0, Math.min(Note.maniaData.length - 1, PlayState.SONG.mania - 1)));
    var ammo = Main.ammo[PlayState.SONG.mania];
    var colorIdx = Note.maniaData[maniaIdx][strumNote.noteData % ammo];
    var color = Note.colArray[colorIdx];
    var colorTitle = color.charAt(0).toUpperCase() + color.substr(1);
    var animName = 'holdCover' + colorTitle;
    
    if (glow.animation.curAnim != null)
    {
      var curName = glow.animation.curAnim.name;
      var isPlayingStart = StringTools.startsWith(curName, 'holdCover' + colorTitle);
      var isPlayingContinue = (curName == animName);
      
      if (!isPlayingStart && !isPlayingContinue)
      {
        glow.animation.play(animName);
      }
    }
    else
    {
      glow.animation.play(animName);
    }
  }

    public function playEnd():Void
    {
        ending = true;

        this.visible = true;
        glow.visible = true;
        if (sparks != null) sparks.visible = true;

        glow.setPosition(this.x, this.y);

        var maniaIdx:Int = Std.int(Math.max(0, Math.min(Note.maniaData.length - 1, PlayState.SONG.mania - 1)));
        var ammo = Main.ammo[PlayState.SONG.mania];
        var colorIdx = Note.maniaData[maniaIdx][strumNote.noteData % ammo];
        var color = Note.colArray[colorIdx];
        var colorTitle = color.charAt(0).toUpperCase() + color.substr(1);

        glow.animation.play('holdCoverEnd' + colorTitle, true);
    }

  public override function kill():Void
  {
    //super.kill();

    this.visible = false;

    if (glow != null) glow.visible = false;
    if (sparks != null) sparks.visible = false;
  }

  public override function revive():Void
  {
    //super.revive();

    this.visible = true;
    this.alpha = 0.8 * strumAlpha;

    if (glow != null) glow.visible = true;
    if (sparks != null) sparks.visible = true;
  }

  public function onAnimationFinished(animationName:String):Void
  {
    var maniaIdx:Int = Std.int(Math.max(0, Math.min(Note.maniaData.length - 1, PlayState.SONG.mania - 1)));
    var ammo = Main.ammo[PlayState.SONG.mania];
    var colorIdx = Note.maniaData[maniaIdx][strumNote.noteData % ammo];
    var color = Note.colArray[colorIdx];
    var colorTitle = color.charAt(0).toUpperCase() + color.substr(1);
    
    if (StringTools.startsWith(animationName, 'holdCoverStart' + colorTitle))
    {
      playContinue();
    }
    else if (StringTools.startsWith(animationName, 'holdCoverEnd' + colorTitle))
    {
        ending = false;

        if (sparks != null) sparks.visible = false;
        if (glow != null) glow.visible = false;

        this.visible = false;
    }
  }
}
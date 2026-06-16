package;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

class SaveFile extends FlxSpriteGroup
{
    private static inline var ASSET_PATH:String = 'assets/images/save-data';
    private static var ICON_TYPES:Array<String> = [
        'bf', 'bf-old', 'bf-pixel', 'spooky', 'dad', 'pico', 'mom', 'gf', 'monster', 'senpai'
    ];
    private static var ICON_COLORS:Array<FlxColor> = [
        0xFF31B0D1, 0xFFE9FF48, 0xFF7BD6F6, 0xFFD57E00, 0xFFAF66CE,
        0xFFB7D855, 0xFFD8558E, 0xFFA5004D, 0xFFF3FF6E, 0xFFFFAA6F
    ];

    public var targetY:Float = 0;
    public var save:FlxSprite;
    public var loadSprite:FlxSprite;
    public var leftArrow:FlxSprite;
    public var rightArrow:FlxSprite;
    public var deleteConfirm:FlxSprite;
    public var erasedSprite:FlxSprite;
    
    public var beingSelected:Bool = false;
    public var askingToConfirm:Bool = false;
    public var selectingLoad:Bool = true;
    public var playerIcon:HealthIcon;

    public function new(x:Float, y:Float, saveNum:Int = 0)
    {
        super(x, y);
        selectingLoad = true;
        targetY = saveNum;

        var pathPrefix:String = SUtil.getPath();
        var tex:FlxAtlasFrames = FlxAtlasFrames.fromSparrow(pathPrefix + ASSET_PATH + '.png', pathPrefix + ASSET_PATH + '.xml');
        save = new FlxSprite();
        leftArrow = new FlxSprite(350, 280);
        rightArrow = new FlxSprite(60, leftArrow.y);
        deleteConfirm = new FlxSprite(350, 100);
        loadSprite = new FlxSprite(leftArrow.x + leftArrow.width, leftArrow.y);
        erasedSprite = new FlxSprite(200, 100);
        var sprites:Array<FlxSprite> = [save, leftArrow, rightArrow, deleteConfirm, loadSprite, erasedSprite];

        for (sprite in sprites) {
            sprite.frames = tex;
            sprite.antialiasing = true;
        }
        save.setGraphicSize(Std.int(save.width * 3));
        leftArrow.setGraphicSize(Std.int(leftArrow.width * 2));
        rightArrow.setGraphicSize(Std.int(rightArrow.width * 2));
        loadSprite.setGraphicSize(Std.int(loadSprite.width * 2));
		rightArrow.antialiasing = false;
		leftArrow.antialiasing = false;
		erasedSprite.antialiasing = false;
		loadSprite.antialiasing = false;
		deleteConfirm.antialiasing = false;
        deleteConfirm.setGraphicSize(Std.int(deleteConfirm.width * 1.5));
        save.animation.addByPrefix('default', 'save file', 24);
		save.antialiasing = false;
        loadSprite.animation.addByPrefix('load', 'load', 24);
        loadSprite.animation.addByPrefix('delete', 'deletea', 24);
		loadSprite.antialiasing = false;
        leftArrow.animation.addByPrefix('default', 'left arrow', 24);
        rightArrow.animation.addByPrefix('default', 'right arrow', 24);
        deleteConfirm.animation.addByPrefix('default', 'delete confirm', 24);
        erasedSprite.animation.addByPrefix('default', 'deleted', 24);
        var safeIndex:Int = FlxMath.wrap(saveNum, 0, ICON_TYPES.length - 1);
        save.color = ICON_COLORS[safeIndex];

        playerIcon = new HealthIcon(ICON_TYPES[safeIndex], false);
        playerIcon.setGraphicSize(Std.int(playerIcon.width * 2));
        playerIcon.updateHitbox();
        playerIcon.setPosition(x + 20, y + 70);
        for (sprite in sprites) {
            add(sprite);
            var animName:String = (sprite == loadSprite) ? 'load' : 'default';
            sprite.animation.play(animName);
            sprite.animation.pause();
            sprite.updateHitbox();
        }
        add(playerIcon);
        loadSprite.x = leftArrow.x + leftArrow.width;
        rightArrow.x = loadSprite.x + loadSprite.width;

        erasedSprite.visible = false;
        deleteConfirm.visible = false;
        
        updateAlpha(0.5);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        var targetPos:Float = 150 + (targetY * 420);
        y = FlxMath.lerp(y, targetPos, 1 - Math.pow(1 - 0.17, elapsed * 60));
    }

    public function askToConfirm(?turnOn:Bool = true) 
    {
        askingToConfirm = turnOn;
        deleteConfirm.visible = turnOn;
        erasedSprite.visible = false;
        
        if (playerIcon.animation.curAnim != null)
            playerIcon.animation.curAnim.curFrame = turnOn ? 1 : 0;
    }

    public function beSelected(?selected:Bool = true) 
    {
        beingSelected = selected;
        updateAlpha(selected ? 1.0 : 0.5);
    }

    public function changeSelection() 
    {
        selectingLoad = !selectingLoad;
        loadSprite.animation.play(selectingLoad ? 'load' : 'delete');
        loadSprite.updateHitbox();
        leftArrow.x = selectingLoad ? 750 : 750;
        loadSprite.x = leftArrow.x + leftArrow.width;
        rightArrow.x = loadSprite.x + loadSprite.width;
    }

    private inline function updateAlpha(value:Float) 
    {
        loadSprite.alpha = value;
        rightArrow.alpha = value;
        leftArrow.alpha = value;
    }
}
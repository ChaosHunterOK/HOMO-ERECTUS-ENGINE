package;

import flixel.input.gamepad.mappings.XInputMapping;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
using Lambda;

typedef KeyLayoutEntry = {name:String, field:String};

class ControlsState extends MusicBeatState {
    var askToBind:FlxTypedSpriteGroup<FlxSprite>;
    var bindTxt:FlxText;
    var askingToBind:Bool = false;
    var grpBind:FlxTypedGroup<Alphabet>;
    var awaitingFor:Int = -1;
    var curSelected:Int = 0;
    static final KEY_LAYOUTS:Array<Array<KeyLayoutEntry>> = [
        //4 keys
        [
            {name: "Left", field: "left"},
            {name: "Down", field: "down"},
            {name: "Up", field: "up"},
            {name: "Right", field: "right"}
        ],
        //6/7 keys
        [
            {name: "Left-6/7k", field: "A1"},
            {name: "Up-6/7k", field: "A2"},
            {name: "Right-6/7k", field: "A3"},
            {name: "Middle-7k", field: "A4"},
            {name: "Left2-6/7k", field: "A5"},
            {name: "Down-6/7k", field: "A6"},
            {name: "Right2-6/7k", field: "A7"}
        ],
        //9 keys
        [
            {name: "Left-9k", field: "B1"},
            {name: "Down-9k", field: "B2"},
            {name: "Up-9k", field: "B3"},
            {name: "Right-9k", field: "B4"},
            {name: "Middle-9k", field: "B5"},
            {name: "Left2-9k", field: "B6"},
            {name: "Down2-9k", field: "B7"},
            {name: "Up2-9k", field: "B8"},
            {name: "Right2-9k", field: "B9"}
        ]
    ];
    inline function keysToString(keys:Array<FlxKey>):String {
        return keys.map(key -> FlxKey.toStringMap.get(key)).join(",");
    }
    function getKeyBindText(globalIndex:Int):String {
        var offset = 0;
        for (layout in KEY_LAYOUTS) {
            if (globalIndex < offset + layout.length) {
                var localIndex = globalIndex - offset;
                var entry = layout[localIndex];
                var keys:Array<FlxKey> = Reflect.field(FlxG.save.data.keys, entry.field);
                return '${entry.name}: ${keysToString(keys)}';
            }
            offset += layout.length;
        }
        return "Invalid";
    }
    function getKeysForIndex(index:Int):Array<FlxKey> {
        var offset = 0;
        for (layout in KEY_LAYOUTS) {
            if (index < offset + layout.length) {
                var localIndex = index - offset;
                var entry = layout[localIndex];
                return Reflect.field(FlxG.save.data.keys, entry.field);
            }
            offset += layout.length;
        }
        return [];
    }
    function setKeysForIndex(index:Int, keys:Array<FlxKey>):Void {
        var offset = 0;
        for (layout in KEY_LAYOUTS) {
            if (index < offset + layout.length) {
                var localIndex = index - offset;
                var entry = layout[localIndex];
                Reflect.setField(FlxG.save.data.keys, entry.field, keys);
                return;
            }
            offset += layout.length;
        }
    }
    
    override function create() {
        FlxG.mouse.visible = true;
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(SUtil.getPath() + 'assets/images/menuBG.png');
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg); 
        
        askToBind = new FlxTypedSpriteGroup<FlxSprite>();
        var askGraphic = new FlxSprite().makeGraphic(Std.int(FlxG.width/2), Std.int(FlxG.height/2), FlxColor.YELLOW);
        bindTxt = new FlxText(60, 20, 0, "Waiting for input\n (press esc or enter to stop binding)");
        bindTxt.setFormat(null, 24, FlxColor.BLACK);
        askToBind.add(askGraphic);
        askToBind.add(bindTxt);
        askToBind.visible = false;
        askToBind.x = 500;
        askToBind.y = 80;
        
        grpBind = new FlxTypedGroup<Alphabet>();
        add(grpBind);

        var itemIndex = 0;
        for (layout in KEY_LAYOUTS) {
            for (i => entry in layout) {
                var text = getKeyBindText(itemIndex);
                var songText:Alphabet = new Alphabet(0, (70 * itemIndex) + 30, text, true, false, false, null, null, null, true);
                songText.itemType = "Classic";
                songText.isMenuItem = true;
                songText.targetY = itemIndex;
                grpBind.add(songText);
                itemIndex++;
            }
        }

        add(askToBind);
		#if mobile
		addVirtualPad(UP_DOWN, A_B);
		#end
        super.create();
    }
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(SUtil.getPath() + 'assets/sounds/custom_menu_sounds/'
			+ CoolUtil.parseJson(FNFAssets.getText(SUtil.getPath() + "assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuScroll
			+ '/scrollMenu'
			+ TitleState.soundExt,
			0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = 19;
		if (curSelected >= 20)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		// comment out because lag?
		// if (!soundTest)
		//	FlxG.sound.playMusic(FNFAssets.getSound(SUtil.getPath() + "assets/music/"+songs[curSelected].songName+"_Inst"+TitleState.soundExt), 0);
		var bullShit:Int = 0;

		for (item in grpBind.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		/*
			var dealphaedColors:Array<FlxColor> = [];
			for (color in (Reflect.field(charJson,songs[curSelected].songCharacter).colors : Array<String>)) {
				var newColor = FlxColor.fromString(color);
				newColor.alphaFloat = 0.5;
				dealphaedColors.push(newColor);
		}*/
		// remove(curOverlay);
		// curOverlay = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, dealphaedColors);
		// insert(1, curOverlay);
	}
	var currentKeys:Array<FlxKey> = [];
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        if (!askingToBind) {
			if (controls.ACCEPT) {
				awaitingFor = curSelected;
				askingToBind = true;
                askToBind.visible = true;
			}
            if (controls.UP_MENU) {
                changeSelection(-1);
            } else if (controls.DOWN_MENU) {
                changeSelection(1);
            }
            if (controls.BACK) {
                LoadingState.loadAndSwitchState(new SaveDataState());
            }
        } else {
			if (FlxG.keys.firstJustPressed() == ESCAPE || FlxG.keys.firstJustPressed() == ENTER) {
				if (currentKeys.length != 0) {
					setKeysForIndex(awaitingFor, currentKeys);
					FlxG.save.flush();
					
					var text = getKeyBindText(awaitingFor);
					grpBind.members[awaitingFor] = new Alphabet(0, (70 * awaitingFor) + 30, text, true, false, false, null, null, null, true);
					grpBind.members[awaitingFor].itemType = "Classic";
					grpBind.members[awaitingFor].isMenuItem = true;
					grpBind.members[awaitingFor].targetY = 0;
				}
				awaitingFor = -1;
				askingToBind = false;
				askToBind.visible = false;
				currentKeys = [];
			} else if (FlxG.keys.firstJustPressed() != -1) {
                currentKeys.push(FlxG.keys.firstJustPressed());
            }
        }
    }
}
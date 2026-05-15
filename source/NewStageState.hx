package;

using StringTools;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import haxe.Json;
import openfl.utils.ByteArray;
#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
#end

class NewStageState extends MusicBeatState
{
    var spritePaths:Map<FlxSprite, String> = new Map();
	var epicHscripts:Array<String> = [];
    var editorGroup:FlxTypedGroup<FlxSprite>;
    var assetGroup:FlxTypedGroup<FlxSprite>;
    var gridGroup:FlxTypedGroup<FlxSprite>;
    var UI_box:FlxUITabMenu;
    var nameText:FlxUIInputText;
    var zoomStepper:FlxUINumericStepper;
    var toolbar:FlxTypedGroup<FlxSprite>;
    var statusBar:FlxText;
    var propsPanel:FlxUI;
    var selectedSprite:FlxSprite;
    var epicFiles:Array<String> = [];
	var selectionBox:FlxSprite;
	var handles:Array<FlxSprite> = [];
	var transformMode:String = "none";
	var activeHandle:Int = -1;
    var showGrid:Bool = true;
    var gridSize:Int = 32;
    var snapToGrid:Bool = true;
    var panOffset:Float = 0;
    var isPanning:Bool = false;
    var lastMousePos:FlxPoint;
    var history:Array<EditorAction> = [];
    var historyIndex:Int = -1;
    var maxHistory:Int = 50;
    var objPosX:FlxText;
    var objPosY:FlxText;
    var objWidth:FlxText;
    var objHeight:FlxText;
    var objRotation:FlxText;
    var objScaleX:FlxText;
    var objScaleY:FlxText;
    var layerUpBtn:FlxButton;
    var layerDownBtn:FlxButton;
    var deleteBtn:FlxButton;
    var duplicateBtn:FlxButton;
    var gridToggleBtn:FlxButton;
    var snapToggleBtn:FlxButton;
	var loadedBitmaps:Map<String, openfl.display.BitmapData> = new Map();

    override function create()
    {
        FlxG.mouse.visible = true;
        lastMousePos = new FlxPoint();
        
        var bg:FlxSprite = new FlxSprite().loadGraphic(SUtil.getPath() + 'assets/images/menuBGBlue.png');
        bg.color = 0xFF222222;
        bg.scrollFactor.set();
        add(bg);
        gridGroup = new FlxTypedGroup<FlxSprite>();
        add(gridGroup);
        
        editorGroup = new FlxTypedGroup<FlxSprite>();
        assetGroup = new FlxTypedGroup<FlxSprite>();
        add(editorGroup);
        add(assetGroup);
        
        var tabs = [
            {name: "Stage", label: 'Stage Settings'},
            {name: "Assets", label: 'Asset Library'},
            {name: "Layers", label: 'Layers'},
        ];

        UI_box = new FlxUITabMenu(null, tabs, true);
        UI_box.resize(300, 400);
        UI_box.x = FlxG.width - UI_box.width - 20;
        UI_box.y = 20;
        UI_box.scrollFactor.set();
        add(UI_box);

		selectionBox = new FlxSprite();
		selectionBox.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		selectionBox.scrollFactor.set();
		add(selectionBox);
		selectionBox.visible = false;

		for (i in 0...4)
		{
			var h = new FlxSprite();
			h.makeGraphic(6, 6, FlxColor.WHITE);
			h.scrollFactor.set();
			add(h);
			handles.push(h);
		}

        // Create toolbar
        createToolbar();
        
        // Create status bar
        statusBar = new FlxText(10, FlxG.height - 25, FlxG.width - 320, "Ready | Grid: ON | Snap: ON", 12);
        statusBar.setFormat(null, 12, FlxColor.WHITE, LEFT);
        statusBar.scrollFactor.set();
        
        // Status bar background
        var statusBg = new FlxSprite(10, FlxG.height - 25).makeGraphic(Std.int(FlxG.width - 320), 25, 0xAA000000);
        statusBg.scrollFactor.set();
        add(statusBg);
		add(statusBar);

        addStageUI();
        addAssetUI();
        addLayersUI();
        
        // Draw initial grid
        drawGrid();

        super.create();
    }
    
    function createToolbar()
    {
        toolbar = new FlxTypedGroup<FlxSprite>();
        var xThingy = 80;
        // Toolbar background
        var toolbarBg = new FlxSprite(10, 10).makeGraphic(FlxG.width - 340, 30, 0xCC1a1a2e);
        toolbar.add(toolbarBg);
        
        // Grid toggle button
		gridToggleBtn = new FlxButton(10 + xThingy, 12, "Grid", function() {
			showGrid = !showGrid;
			drawGrid();
			updateStatus();
		});
        toolbar.add(gridToggleBtn);
        
        // Snap toggle button
		snapToggleBtn = new FlxButton(10 + xThingy + 60, 12, "Snap", function() {
			snapToGrid = !snapToGrid;
			updateStatus();
		});
        toolbar.add(snapToggleBtn);
        
        // Delete button
        deleteBtn = new FlxButton(10 + xThingy + 120, 12, "Del", function() {
            deleteSelected();
        });
        toolbar.add(deleteBtn);
        
        // Duplicate button
        duplicateBtn = new FlxButton(10 + xThingy + 180, 12, "Dup", function() {
            duplicateSelected();
        });
        toolbar.add(duplicateBtn);
        
        // Layer up
        layerUpBtn = new FlxButton(10 + xThingy + 240, 12, "↑", function() {
            moveLayerUp();
        });
        toolbar.add(layerUpBtn);
        
        // Layer down
        layerDownBtn = new FlxButton(10 + xThingy + 300, 12, "↓", function() {
            moveLayerDown();
        });
        toolbar.add(layerDownBtn);
        
        // Zoom controls
        var zoomOutBtn = new FlxButton(10 + xThingy + 360, 12, "-", function() {
            FlxG.camera.zoom = Math.max(0.1, FlxG.camera.zoom - 0.1);
        });
        toolbar.add(zoomOutBtn);
        
        var zoomInBtn = new FlxButton(10 + xThingy + 390, 12, "+", function() {
            FlxG.camera.zoom = Math.min(5, FlxG.camera.zoom + 0.1);
        });
        toolbar.add(zoomInBtn);
        
        // Reset view
        var resetBtn = new FlxButton(10 + xThingy + 420, 12, "Reset", function() {
            FlxG.camera.zoom = 1;
            FlxG.camera.x = 0;
            FlxG.camera.y = 0;
        });
        toolbar.add(resetBtn);
        
        // Undo button
        var undoBtn = new FlxButton(10 + xThingy + 480, 12, "Undo", function() {
            undo();
        });
        toolbar.add(undoBtn);
        
        // Redo button
        var redoBtn = new FlxButton(10 + xThingy + 540, 12, "Redo", function() {
            redo();
        });
        toolbar.add(redoBtn);
        
        add(toolbar);
    }
    
    function drawGrid()
    {
        gridGroup.clear();
        
        if (!showGrid) return;
        
        var gridColor = 0x33FFFFFF;
        var w = Std.int(FlxG.width / FlxG.camera.zoom) + 100;
        var h = Std.int(FlxG.height / FlxG.camera.zoom) + 100;
        var offsetX = Std.int(FlxG.camera.x) % (gridSize * Std.int(FlxG.camera.zoom));
        var offsetY = Std.int(FlxG.camera.y) % (gridSize * Std.int(FlxG.camera.zoom));
        
        // Vertical lines
        var x = -offsetX;
        while (x < w) {
            var line = new FlxSprite(x, -50).makeGraphic(1, h + 100, gridColor);
            line.scrollFactor.set();
            gridGroup.add(line);
            x += gridSize;
        }
        
        // Horizontal lines
        var y = -offsetY;
        while (y < h) {
            var line = new FlxSprite(-50, y).makeGraphic(w + 100, 1, gridColor);
            line.scrollFactor.set();
            gridGroup.add(line);
            y += gridSize;
        }
    }
    
    function updateStatus()
    {
        var status = "Ready";
        if (selectedSprite != null) {
            status = 'Selected: ${selectedSprite.width}x${selectedSprite.height} at (${Std.int(selectedSprite.x)}, ${Std.int(selectedSprite.y)})';
        }
        status += ' | Grid: ${showGrid ? "ON" : "OFF"} | Snap: ${snapToGrid ? "ON" : "OFF"} | Zoom: ${Math.round(FlxG.camera.zoom * 100)}%';
        statusBar.text = status;
    }

    function addStageUI()
    {
        var tab_group = new FlxUI(null, UI_box);
        tab_group.name = "Stage";

        nameText = new FlxUIInputText(10, 30, 150, "template_stage", 8);
        var label = new FlxText(nameText.x, nameText.y - 15, 0, "Stage Name:", 8);

        zoomStepper = new FlxUINumericStepper(10, 70, 0.1, 1, 0.1, 5, 1);
        var zoomLabel = new FlxText(zoomStepper.x, zoomStepper.y - 15, 0, "Default Zoom:", 8);
        
        // Grid size stepper
        var gridSizeStepper = new FlxUINumericStepper(10, 110, 1, 32, 1, 128, 1);
		gridSizeStepper.value = gridSize;
        var gridSizeLabel = new FlxText(gridSizeStepper.x, gridSizeStepper.y - 15, 0, "Grid Size:", 8);
		if (gridSize != Std.int(gridSizeStepper.value)) {
			gridSize = Std.int(gridSizeStepper.value);
			drawGrid();
		}

        // Save button
        var saveBtn = new FlxButton(10, 150, "Export Stage", function() {
            writeCharacters();
        });
        
        // Load button
        var loadBtn = new FlxButton(100, 150, "Load Stage", function() {
            loadStage();
        });
        
        // Clear button
        var clearBtn = new FlxButton(10, 180, "Clear All", function() {
            if (selectedSprite != null) {
                addToHistory({type: "delete", sprite: selectedSprite, data: null});
            }
            editorGroup.clear();
            epicFiles = [];
            refreshAssetList();
        });

        tab_group.add(label);
        tab_group.add(nameText);
        tab_group.add(zoomLabel);
        tab_group.add(zoomStepper);
        tab_group.add(gridSizeLabel);
        tab_group.add(gridSizeStepper);
        tab_group.add(saveBtn);
        tab_group.add(loadBtn);
        tab_group.add(clearBtn);

        UI_box.addGroup(tab_group);
    }
    
    function addLayersUI()
    {
        var tab_group = new FlxUI(null, UI_box);
        tab_group.name = "Layers";
        
        var layerLabel = new FlxText(10, 20, 0, "Object Properties", 12);
        tab_group.add(layerLabel);
        
        // Position X
        var posXLabel = new FlxText(10, 45, 0, "X:", 8);
        objPosX = new FlxText(30, 45, 80, "0", 8);
        tab_group.add(posXLabel);
        tab_group.add(objPosX);
        
        // Position Y
        var posYLabel = new FlxText(120, 45, 0, "Y:", 8);
        objPosY = new FlxText(140, 45, 80, "0", 8);
        tab_group.add(posYLabel);
        tab_group.add(objPosY);
        
        // Width
        var wLabel = new FlxText(10, 70, 0, "W:", 8);
        objWidth = new FlxText(30, 70, 80, "0", 8);
        tab_group.add(wLabel);
        tab_group.add(objWidth);
        
        // Height
        var hLabel = new FlxText(120, 70, 0, "H:", 8);
        objHeight = new FlxText(140, 70, 80, "0", 8);
        tab_group.add(hLabel);
        tab_group.add(objHeight);
        
        // Rotation
        var rotLabel = new FlxText(10, 95, 0, "Rotation:", 8);
        objRotation = new FlxText(70, 95, 80, "0", 8);
        tab_group.add(rotLabel);
        tab_group.add(objRotation);
        
        // Scale X
        var scaleXLabel = new FlxText(10, 120, 0, "Scale X:", 8);
        objScaleX = new FlxText(70, 120, 80, "1.0", 8);
        tab_group.add(scaleXLabel);
        tab_group.add(objScaleX);
        
        // Scale Y
        var scaleYLabel = new FlxText(10, 145, 0, "Scale Y:", 8);
        objScaleY = new FlxText(70, 145, 80, "1.0", 8);
        tab_group.add(scaleYLabel);
        tab_group.add(objScaleY);
        
        // Apply button
        var applyBtn = new FlxButton(10, 175, "Apply", function() {
            applyObjectProperties();
        });
        tab_group.add(applyBtn);
        
        // Flip horizontal
        var flipHBtn = new FlxButton(80, 175, "Flip H", function() {
            if (selectedSprite != null) {
                selectedSprite.flipX = !selectedSprite.flipX;
                updateSelectionBox();
            }
        });
        tab_group.add(flipHBtn);
        
        // Flip vertical
        var flipVBtn = new FlxButton(150, 175, "Flip V", function() {
            if (selectedSprite != null) {
                selectedSprite.flipY = !selectedSprite.flipY;
                updateSelectionBox();
            }
        });
        tab_group.add(flipVBtn);
        
        // Center button
        var centerBtn = new FlxButton(10, 205, "Center", function() {
            if (selectedSprite != null) {
                selectedSprite.x = FlxG.width / 2 - selectedSprite.width / 2;
                selectedSprite.y = FlxG.height / 2 - selectedSprite.height / 2;
                updateSelectionBox();
                updateHandles();
            }
        });
        tab_group.add(centerBtn);
        
        UI_box.addGroup(tab_group);
    }
    
    function applyObjectProperties()
    {
        if (selectedSprite == null) return;
        
        var oldX = selectedSprite.x;
        var oldY = selectedSprite.y;
        var oldW = selectedSprite.width;
        var oldH = selectedSprite.height;
        var oldRot = selectedSprite.angle;
        var oldScaleX = selectedSprite.scale.x;
        var oldScaleY = selectedSprite.scale.y;
        
        selectedSprite.x = Std.parseFloat(objPosX.text);
        selectedSprite.y = Std.parseFloat(objPosY.text);
        selectedSprite.scale.set(Std.parseFloat(objScaleX.text), Std.parseFloat(objScaleY.text));
        selectedSprite.angle = Std.parseFloat(objRotation.text);
        selectedSprite.updateHitbox();
        
        updateSelectionBox();
        updateHandles();
        updateStatus();
    }
    
    function updateObjectProperties()
    {
        if (selectedSprite != null) {
            objPosX.text = Std.string(Std.int(selectedSprite.x));
            objPosY.text = Std.string(Std.int(selectedSprite.y));
            objWidth.text = Std.string(Std.int(selectedSprite.width));
            objHeight.text = Std.string(Std.int(selectedSprite.height));
            objRotation.text = Std.string(Std.int(selectedSprite.angle));
            objScaleX.text = Std.string(selectedSprite.scale.x);
            objScaleY.text = Std.string(selectedSprite.scale.y);
        } else {
            objPosX.text = "0";
            objPosY.text = "0";
            objWidth.text = "0";
            objHeight.text = "0";
            objRotation.text = "0";
            objScaleX.text = "1.0";
            objScaleY.text = "1.0";
        }
    }

    function addAssetUI()
    {
        var tab_group = new FlxUI(null, UI_box);
        tab_group.name = "Assets";

        var loadBtn = new FlxButton(10, 20, "Import PNGs", function() {
            var coolDialog = new FileDialog();
            coolDialog.browse(FileDialogType.OPEN_MULTIPLE, "png", null, "Select Stage Assets");
			coolDialog.onSelectMultiple.add(function(paths:Array<String>) {
				epicFiles = paths;

				#if sys
				for (path in paths) {
					if (!loadedBitmaps.exists(path)) {
						try {
							var bmp = openfl.display.BitmapData.fromFile(path);
							loadedBitmaps.set(path, bmp);
						} catch (e) {
							trace("Failed to load: " + path);
						}
					}
				}
				#end

				refreshAssetList();
			});
        });

        tab_group.add(loadBtn);
        UI_box.addGroup(tab_group);
    }

	function updateSelectionBox()
	{
		if (selectedSprite == null)
		{
			selectionBox.visible = false;
			return;
		}

		selectionBox.visible = true;

		var w = Std.int(selectedSprite.width);
		var h = Std.int(selectedSprite.height);

		selectionBox.makeGraphic(w + 4, h + 4, FlxColor.TRANSPARENT);
		selectionBox.x = selectedSprite.x - 2;
		selectionBox.y = selectedSprite.y - 2;
		selectionBox.pixels.fillRect(new openfl.geom.Rectangle(0, 0, w + 4, 2), FlxColor.BLUE);
		selectionBox.pixels.fillRect(new openfl.geom.Rectangle(0, h + 2, w + 4, 2), FlxColor.BLUE);
		selectionBox.pixels.fillRect(new openfl.geom.Rectangle(0, 0, 2, h + 4), FlxColor.BLUE);
		selectionBox.pixels.fillRect(new openfl.geom.Rectangle(w + 2, 0, 2, h + 4), FlxColor.BLUE);

		selectionBox.dirty = true;
	}

	function updateHandles()
	{
		if (selectedSprite == null)
		{
			for (h in handles) h.visible = false;
			return;
		}

		var x = selectedSprite.x;
		var y = selectedSprite.y;
		var w = selectedSprite.width;
		var h = selectedSprite.height;

		handles[0].setPosition(x - 3, y - 3);
		handles[1].setPosition(x + w - 3, y - 3);
		handles[2].setPosition(x - 3, y + h - 3);
		handles[3].setPosition(x + w - 3, y + h - 3);

		for (h in handles) h.visible = true;
	}

    function refreshAssetList()
    {
        assetGroup.clear();
        var yOff = 100;
        for (path in epicFiles) {
            #if sys
            var spr = new FlxSprite(UI_box.x + 10, yOff);
			var bmp = loadedBitmaps.get(path);
			if (bmp != null) {
				spr.loadGraphic(bmp);
			}
            spr.setGraphicSize(50, 50);
            spr.updateHitbox();
            assetGroup.add(spr);
            yOff += 60;
            #end
        }
    }

	function isNearCorner(handle:FlxSprite):Bool
	{
		var dx = FlxG.mouse.x - handle.x;
		var dy = FlxG.mouse.y - handle.y;
		return Math.sqrt(dx * dx + dy * dy) < 10;
	}

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        handleKeyboardShortcuts();
        if (FlxG.mouse.justPressedMiddle) {
            isPanning = true;
            lastMousePos.set(FlxG.mouse.x, FlxG.mouse.y);
        }
        
        if (isPanning && FlxG.mouse.pressedMiddle) {
            FlxG.camera.x -= (FlxG.mouse.x - lastMousePos.x) / FlxG.camera.zoom;
            FlxG.camera.y -= (FlxG.mouse.y - lastMousePos.y) / FlxG.camera.zoom;
            lastMousePos.set(FlxG.mouse.x, FlxG.mouse.y);
            drawGrid();
        }
        
        if (FlxG.mouse.justReleasedMiddle) {
            isPanning = false;
        }
        
		if (FlxG.mouse.justPressed) {
            // Check if clicking on handles first
            var clickedHandle = false;
            for (i in 0...handles.length) {
                if (FlxG.mouse.overlaps(handles[i])) {
                    activeHandle = i;
                    transformMode = "scale";
                    clickedHandle = true;
                    break;
                }
            }
            
            var clickedEditor = false;
            
            if (!clickedHandle) {
                // Check editor group in reverse (top to bottom)
                var sprites = editorGroup.members.copy();
                sprites.reverse();
                
                for (spr in sprites) {
                    if (spr != null && FlxG.mouse.overlaps(spr)) {
                        selectedSprite = spr;
                        clickedEditor = true;
                        transformMode = "move";
                        updateObjectProperties();
                        break;
                    }
                }
                if (!clickedEditor) {
                    for (i in 0...assetGroup.members.length) {
                        var spr = assetGroup.members[i];

                        if (spr != null && FlxG.mouse.overlaps(spr)) {
                            var newObj = new FlxSprite(FlxG.mouse.x, FlxG.mouse.y);
                            newObj.loadGraphic(spr.graphic);
                            spritePaths.set(newObj, epicFiles[i]);
                            newObj.updateHitbox();
                            if (snapToGrid) {
                                newObj.x = Math.round(newObj.x / gridSize) * gridSize;
                                newObj.y = Math.round(newObj.y / gridSize) * gridSize;
                            }
                            
                            editorGroup.add(newObj);
                            selectedSprite = newObj;
                            transformMode = "move";
                            updateObjectProperties();
                            addToHistory({type: "add", sprite: newObj, data: null});
                            break;
                        }
                    }
                }
                if (!clickedEditor) {
                    for (h in handles) {
                        if (FlxG.mouse.overlaps(h)) {
                            clickedEditor = true;
                            break;
                        }
                    }
                }
                
                if (!clickedEditor && !isPanning) {
                    var mouseX = FlxG.mouse.x;
                    var mouseY = FlxG.mouse.y;
                    // Check if clicking outside UI box and toolbar area
                    if (mouseX < UI_box.x && mouseY > 50 && mouseY < FlxG.height - 30) {
                        // Clicked on empty space in editor - deselect
                        selectedSprite = null;
                        transformMode = "none";
                        updateObjectProperties();
                        updateSelectionBox();
                        updateHandles();
                    }
                }
            }
		}

		if (FlxG.mouse.justPressed && selectedSprite != null)
		{
			activeHandle = -1;

			for (i in 0...handles.length)
			{
				if (FlxG.mouse.overlaps(handles[i]))
				{
					activeHandle = i;
					transformMode = "scale";
					break;
				}
			}

			if (activeHandle == -1 && FlxG.mouse.overlaps(selectedSprite))
			{
				transformMode = "move";
			}
		}

		if (selectedSprite != null && FlxG.mouse.pressed && !isPanning)
		{
			switch (transformMode)
			{
				case "move":
                    var newX = FlxG.mouse.x - selectedSprite.width / 2;
                    var newY = FlxG.mouse.y - selectedSprite.height / 2;
                    if (snapToGrid) {
                        newX = Math.round(newX / gridSize) * gridSize;
                        newY = Math.round(newY / gridSize) * gridSize;
                    }
                    
					selectedSprite.x = newX;
					selectedSprite.y = newY;

				case "scale":
                    var cx = selectedSprite.x + selectedSprite.width / 2;
                    var cy = selectedSprite.y + selectedSprite.height / 2;
                    
                    var dx = (FlxG.mouse.x - cx) / (selectedSprite.width / 2);
                    var dy = (FlxG.mouse.y - cy) / (selectedSprite.height / 2);
                    var minScale = 0.1;
                    selectedSprite.scale.set(
                        Math.max(minScale, Math.abs(dx)),
                        Math.max(minScale, Math.abs(dy))
                    );
					selectedSprite.updateHitbox();

				case "rotate":
					var cx = selectedSprite.x + selectedSprite.width / 2;
					var cy = selectedSprite.y + selectedSprite.height / 2;

					var angle = Math.atan2(FlxG.mouse.y - cy, FlxG.mouse.x - cx);
					selectedSprite.angle = angle * 180 / Math.PI;
			}
            
            updateSelectionBox();
            updateHandles();
            updateObjectProperties();
            updateStatus();
		}
        
        // Mouse wheel zoom
        if (FlxG.mouse.wheel != 0) {
            FlxG.camera.zoom = Math.max(0.1, Math.min(5, FlxG.camera.zoom - FlxG.mouse.wheel * 0.1));
            drawGrid();
            updateStatus();
        }
    }
    
    function handleKeyboardShortcuts()
    {
        if (FlxG.keys.justPressed.DELETE || FlxG.keys.justPressed.BACKSPACE) {
            deleteSelected();
        }
        
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.D) {
            duplicateSelected();
        }
        
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z) {
            undo();
        }
        
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y) {
            redo();
        }
        
        var nudgeAmount = FlxG.keys.pressed.SHIFT ? 10 : 1;
        if (selectedSprite != null) {
            if (FlxG.keys.justPressed.LEFT) {
                selectedSprite.x -= nudgeAmount;
                updateSelectionBox();
                updateHandles();
                updateObjectProperties();
                updateStatus();
            }
            if (FlxG.keys.justPressed.RIGHT) {
                selectedSprite.x += nudgeAmount;
                updateSelectionBox();
                updateHandles();
                updateObjectProperties();
                updateStatus();
            }
            if (FlxG.keys.justPressed.UP) {
                selectedSprite.y -= nudgeAmount;
                updateSelectionBox();
                updateHandles();
                updateObjectProperties();
                updateStatus();
            }
            if (FlxG.keys.justPressed.DOWN) {
                selectedSprite.y += nudgeAmount;
                updateSelectionBox();
                updateHandles();
                updateObjectProperties();
                updateStatus();
            }
        }
        
        if (FlxG.keys.justPressed.G) {
            showGrid = !showGrid;
            drawGrid();
            updateStatus();
        }
        
        if (FlxG.keys.justPressed.S && !FlxG.keys.pressed.CONTROL) {
            snapToGrid = !snapToGrid;
            updateStatus();
        }
        
        if (FlxG.keys.justPressed.ESCAPE) {
            selectedSprite = null;
            updateObjectProperties();
            updateSelectionBox();
            updateHandles();
        }
        
        if (FlxG.keys.justPressed.PAGEUP) {
            moveLayerUp();
        }
        if (FlxG.keys.justPressed.PAGEDOWN) {
            moveLayerDown();
        }
        
        if (FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) {
            FlxG.camera.zoom = 1;
            FlxG.camera.x = 0;
            FlxG.camera.y = 0;
            drawGrid();
            updateStatus();
        }
    }
    
    function deleteSelected()
    {
        if (selectedSprite != null) {
            addToHistory({type: "delete", sprite: selectedSprite, data: null});
            editorGroup.remove(selectedSprite, true);
            selectedSprite = null;
            updateSelectionBox();
            updateHandles();
            updateObjectProperties();
            updateStatus();
        }
    }
    
    function duplicateSelected()
    {
        if (selectedSprite != null) {
            var newObj = new FlxSprite(selectedSprite.x + 20, selectedSprite.y + 20);
            newObj.loadGraphic(selectedSprite.graphic);
            newObj.scale.set(selectedSprite.scale.x, selectedSprite.scale.y);
            newObj.angle = selectedSprite.angle;
            newObj.flipX = selectedSprite.flipX;
            newObj.flipY = selectedSprite.flipY;
            newObj.updateHitbox();
            editorGroup.add(newObj);
            selectedSprite = newObj;
            transformMode = "move";
            updateSelectionBox();
            updateHandles();
            updateObjectProperties();
            addToHistory({type: "add", sprite: newObj, data: null});
            updateStatus();

            var originalPath = spritePaths.get(selectedSprite);
            if (originalPath != null) {
                spritePaths.set(newObj, originalPath);
            }
            editorGroup.add(newObj);
        }
    }
    
    function moveLayerUp()
    {
        if (selectedSprite != null) {
            var idx = editorGroup.members.indexOf(selectedSprite);
            if (idx < editorGroup.members.length - 1) {
                var temp = editorGroup.members[idx];
                editorGroup.members[idx] = editorGroup.members[idx + 1];
                editorGroup.members[idx + 1] = temp;
            }
        }
    }
    
    function moveLayerDown()
    {
        if (selectedSprite != null) {
            var idx = editorGroup.members.indexOf(selectedSprite);
            if (idx > 0) {
                var temp = editorGroup.members[idx];
                editorGroup.members[idx] = editorGroup.members[idx - 1];
                editorGroup.members[idx - 1] = temp;
            }
        }
    }

	function safeCopy(src:String, dest:String):String
	{
		#if sys
		var finalDest = dest;
		var i = 1;

		while (FileSystem.exists(finalDest))
		{
			var p = Path.withoutExtension(dest);
			var ext = Path.extension(dest);
			finalDest = p + "_" + i + "." + ext;
			i++;
		}

		File.copy(src, finalDest);
		return finalDest;
		#end

		return dest;
	}

	function writeCharacters() {
		#if sys
        var pathDir2 = SUtil.getPath() + 'assets/images/custom_stages/';
		var pathDir = pathDir2 + nameText.text;

		if (!FileSystem.exists(pathDir)) {
			FileSystem.createDirectory(pathDir);
		}
		for (epicFile in epicFiles)
		{
			var coolPath:Path = new Path(epicFile);
			var dest = pathDir + '/' + coolPath.file + '.' + coolPath.ext;
			safeCopy(epicFile, dest);
		}
		var hscriptContent = '// Stage: ${nameText.text}\n';
		hscriptContent += '// Generated by Stage Editor\n\n';

		hscriptContent += 'function start(song) {\n';
		hscriptContent += '    setDefaultZoom(${zoomStepper.value});\n\n';

		var id = 0;

		for (spr in editorGroup.members)
		{
			if (spr == null || spr.graphic == null) continue;

			var fileName = "unknown.png";

            #if sys
            var originalPath = spritePaths.get(spr);

            if (originalPath != null) {
                var p = new Path(originalPath);
                fileName = p.file + "." + p.ext;
            }
            #end

			hscriptContent += '    var spr$id = new FlxSprite(${spr.x}, ${spr.y}).loadGraphic(hscriptPath + "$fileName");\n';
			hscriptContent += '    spr$id.scale.set(${spr.scale.x}, ${spr.scale.y});\n';
			hscriptContent += '    spr$id.angle = ${spr.angle};\n';
			hscriptContent += '    spr$id.scrollFactor.set(${spr.scrollFactor.x}, ${spr.scrollFactor.y});\n';
			hscriptContent += '    spr$id.flipX = ${spr.flipX};\n';
			hscriptContent += '    spr$id.flipY = ${spr.flipY};\n';
			hscriptContent += '    addSprite(spr$id, BEHIND_ALL);\n\n';

			id++;
		}

		hscriptContent += '}\n\n';
		hscriptContent += 'function update(elapsed) {}\n';
		hscriptContent += 'function beatHit(beat) {}\n';

		var hscriptPath = pathDir2 + '${nameText.text}.hscript';
		File.saveContent(hscriptPath, hscriptContent);

		trace("generated i suppose");
		#end
	}
	
	function loadStage() {
		#if sys
		var jsonPath = SUtil.getPath() + 'assets/images/custom_stages/custom_stages.json';
		if (!FileSystem.exists(jsonPath)) {
			trace("No stages found!");
			return;
		}
		
		var rawJson = File.getContent(jsonPath);
		if (rawJson == null || StringTools.trim(rawJson) == "") {
			trace("Empty stages file!");
			return;
		}
		
		var stages:Dynamic = Json.parse(rawJson);
		var stageNames = Reflect.fields(stages);
		
		if (stageNames.length == 0) {
			trace("No stages to load!");
			return;
		}
		
		// Load first available stage (could add UI to select)
		var stageName = stageNames[0];
		var stageData:Dynamic = Reflect.field(stages, stageName);
		
		nameText.text = stageName;
		zoomStepper.value = stageData.zoom;
		
		// Load assets from stage folder
		var pathDir = SUtil.getPath() + 'assets/images/custom_stages/' + stageName;
		if (FileSystem.exists(pathDir)) {
			var files = FileSystem.readDirectory(pathDir);
			epicFiles = [];
			for (f in files) {
				if (f.toLowerCase().endsWith('.png')) {
					epicFiles.push(pathDir + '/' + f);
				}
			}
			refreshAssetList();
		}
		
		trace('Loaded stage: $stageName');
		updateStatus();
		#end
	}
	
	// History system for undo/redo
	function addToHistory(action:EditorAction) {
		// Remove any redo history
		while (historyIndex < history.length - 1) {
			history.pop();
		}
		
		history.push(action);
		historyIndex = history.length - 1;
		
		// Limit history size
		while (history.length > maxHistory) {
			history.shift();
			historyIndex--;
		}
	}
	
	function undo() {
		if (historyIndex < 0) return;
		
		var action = history[historyIndex];
		historyIndex--;
		
		switch (action.type) {
			case "add":
				if (action.sprite != null) {
					editorGroup.remove(action.sprite, true);
					if (selectedSprite == action.sprite) {
						selectedSprite = null;
						updateSelectionBox();
						updateHandles();
						updateObjectProperties();
					}
				}
			case "delete":
				if (action.sprite != null) {
					editorGroup.add(action.sprite);
				}
		}
		
		updateStatus();
	}
	
	function redo() {
		if (historyIndex >= history.length - 1) return;
		
		historyIndex++;
		var action = history[historyIndex];
		
		switch (action.type) {
			case "add":
				if (action.sprite != null) {
					editorGroup.add(action.sprite);
				}
			case "delete":
				if (action.sprite != null) {
					editorGroup.remove(action.sprite, true);
					if (selectedSprite == action.sprite) {
						selectedSprite = null;
						updateSelectionBox();
						updateHandles();
						updateObjectProperties();
					}
				}
		}
		
		updateStatus();
	}
}

typedef EditorAction = {
	var type:String; // "add", "delete", "move", "scale", "rotate"
	var sprite:FlxSprite;
	var data:Dynamic; // For storing old state for undo
}
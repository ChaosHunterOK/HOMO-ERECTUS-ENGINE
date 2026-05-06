package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class Fake3D extends FlxSpriteGroup {
    public var yaw:Float = 0;
    public var pitch:Float = 0;
    public var fov:Float = 90;
    public var aspect:Float = FlxG.width / FlxG.height;
    
    public var pos3D:Array<Float> = [0, 0, 0];
    public var sunDir:Array<Float> = [0.5, 0.7, 0.5];
    
    public var layers:Array<FlxSprite> = [];
    public var depth:Int;
    public var spacing:Float = 2.0;
    public var baseColor:FlxColor = FlxColor.WHITE;

    public function new(x:Float, y:Float, asset:String, depth:Int = 10, isText:Bool = false, textStr:String = "", ?font:String = null, textColor:FlxColor = FlxColor.WHITE, fontSize:Int = 32) {
        super(x, y);
        this.depth = depth;
        this.pos3D = [x, y, 500]; 
        this.baseColor = textColor;

        for (i in 0...depth) {
            var layer:FlxSprite;
            
            if (isText) {
                var t = new FlxText(0, 0, 0, textStr, fontSize);
                var borderStyle = (i == 0) ? FlxTextBorderStyle.OUTLINE : FlxTextBorderStyle.NONE;
                var borderSize = (i == 0) ? 2 : 0; 

                t.setFormat(font, fontSize, baseColor, "center", borderStyle, FlxColor.BLACK);
                if(borderStyle != NONE) t.borderSize = borderSize;
                
                layer = t;
            } else {
                layer = new FlxSprite(0, 0).loadGraphic(asset);
                layer.color = baseColor;
            }
            
            add(layer);
            layers.push(layer);
        }
    }
    public function changeColor(newColor:FlxColor):Void {
        baseColor = newColor;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        apply3DTransform();
    }

    public function apply3DTransform() {
        var radYaw = yaw * (Math.PI / 180);
        var radPitch = pitch * (Math.PI / 180);
        var cp = Math.cos(radPitch);
        var sp = Math.sin(radPitch);
        var cy = Math.cos(radYaw);
        var sy = Math.sin(radYaw);
        
        var dot = (sy * cp * sunDir[0]) + (-sp * sunDir[1]) + (cy * cp * sunDir[2]);
        var brightness = Math.max(0.4, dot);

        for (i in 0...layers.length) {
            var layer = layers[i];
            
            var zOffset = i * spacing;
            var localZ = pos3D[2] + zOffset;
            
            var rx = pos3D[0] * cy - localZ * sy;
            var rz = pos3D[0] * sy + localZ * cy;
            var ry = pos3D[1] * cp - rz * sp;
            var finalZ = pos3D[1] * sp + rz * cp;
            var f = 1 / Math.tan(fov * 0.5 * (Math.PI / 180));
            var scale = f / (finalZ * 0.001);
            
            layer.x = (rx * scale) + (FlxG.width / 2);
            layer.y = (ry * scale) + (FlxG.height / 2);
            layer.scale.set(scale * 0.1, scale * 0.1);
            
            var r = Std.int(baseColor.red * brightness);
            var g = Std.int(baseColor.green * brightness);
            var b = Std.int(baseColor.blue * brightness);
            
            layer.color = FlxColor.fromRGB(r, g, b);
        }
    }
}
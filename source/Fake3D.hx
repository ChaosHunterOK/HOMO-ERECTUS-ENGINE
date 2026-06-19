package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import openfl.Vector;
import openfl.utils.Assets;
import openfl.display.TriangleCulling;
import openfl.display.BitmapData;

class Fake3D extends FlxSpriteGroup
{
    public static inline var CUBE_DATA:String =
        "v -1 -1 -1\n" +
        "v 1 -1 -1\n" +
        "v 1 1 -1\n" +
        "v -1 1 -1\n" +
        "v -1 -1 1\n" +
        "v 1 -1 1\n" +
        "v 1 1 1\n" +
        "v -1 1 1\n" +
        "f 1 2 3 4\n" +
        "f 5 6 7 8\n" +
        "f 1 5 8 4\n" +
        "f 2 6 7 3\n" +
        "f 1 2 6 5\n" +
        "f 4 3 7 8";

    public var posX:Float = 0;
    public var posY:Float = 0;
    public var posZ:Float = 0;

    public var rotX:Float = 0;
    public var rotY:Float = 0;
    public var rotZ:Float = 0;

    public var modelScale:Float = 100;
    public var camX:Float = 0;
    public var camY:Float = 0;
    public var camZ:Float = -500;

    public var camPitch:Float = 0;
    public var camYaw:Float = 0;
    public var camRoll:Float = 0;

    public var fov:Float = 90;
    public var texture:BitmapData;

    var vertices = new Vector<Float>();
    var projected = new Vector<Float>();
    var indices = new Vector<Int>(); 
    var uvtData = new Vector<Float>();
    var zDepths:Array<Float> = [];

    public function new(x:Float, y:Float, ?objPath:String, ?texturePath:String)
    {
        super(x, y);
        
        if (texturePath != null && Assets.exists(texturePath))
            texture = Assets.getBitmapData(texturePath);
        else {
            texture = new BitmapData(64, 64, false, 0xFFFFFFFF);
            for (ty in 0...64) {
                for (tx in 0...64) {
                    if (((tx >> 3) + (ty >> 3)) % 2 == 0)
                        texture.setPixel(tx, ty, 0xFF888888);
                }
            }
        }

        if (objPath == null)
            parseOBJ(CUBE_DATA);
        else
            loadOBJ(path);
    }

    public function parseOBJ(data:String)
    {
        var rawVertices:Array<Float> = [];
        var rawFaces:Array<Array<Int>> = [];

        for (line in data.split("\n"))
        {
            line = StringTools.trim(line);

            if (StringTools.startsWith(line, "v "))
            {
                var p = line.split(" ");
                rawVertices.push(Std.parseFloat(p[1]));
                rawVertices.push(Std.parseFloat(p[2]));
                rawVertices.push(Std.parseFloat(p[3]));
            }
            else if (StringTools.startsWith(line, "f "))
            {
                var face:Array<Int> = [];
                var p = line.split(" ");

                for (i in 1...p.length)
                {
                    if (p[i] == "") continue;
                    face.push(Std.parseInt(p[i].split("/")[0]) - 1);
                }

                if (face.length >= 3)
                    rawFaces.push(face);
            }
        }
        
        vertices = new Vector<Float>();
        indices = new Vector<Int>();
        uvtData = new Vector<Float>();

        var vIdx = 0;
        for (face in rawFaces)
        {
            var localUVs = [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]];

            for (i in 1...face.length - 1)
            {
                var fIdx = [0, i, i + 1];
                for (j in 0...3) {
                    var currentVert = face[fIdx[j]];
                    vertices.push(rawVertices[currentVert * 3]);
                    vertices.push(rawVertices[currentVert * 3 + 1]);
                    vertices.push(rawVertices[currentVert * 3 + 2]);

                    var uv = localUVs[fIdx[j] % 4];
                    uvtData.push(uv[0]);
                    uvtData.push(uv[1]);
                    uvtData.push(1.0);

                    indices.push(vIdx);
                    vIdx++;
                }
            }
        }

        projected = new Vector<Float>(Std.int(vertices.length / 3) * 2, true);
        zDepths = [for (i in 0...Std.int(vertices.length / 3)) 1.0];
    }

    public function loadOBJ(path:String)
    {
        if (Assets.exists(path))
        {
            var data = Assets.getText(path);
            parseOBJ(data);
        }
        else
        {
            trace('OBJ not found: $path');
        }
    }

    override function draw()
    {
        projectVertices();
        super.draw();

        for (camera in cameras)
        {
            if (!camera.visible || !camera.exists) continue;
            
            var gfx = camera.canvas.graphics;
            gfx.beginBitmapFill(texture, null, true, true);
            gfx.drawTriangles(projected, indices, uvtData, TriangleCulling.NEGATIVE);
            gfx.endFill();
        }
    }

    function projectVertices()
    {
        var cx = FlxG.width * 0.5;
        var cy = FlxG.height * 0.5;

        var focal = (FlxG.height * 0.5) / Math.tan(fov * Math.PI / 360);
        
        var sx = Math.sin(rotX * Math.PI / 180);
        var sy = Math.sin(rotY * Math.PI / 180);
        var sz = Math.sin(rotZ * Math.PI / 180);
        var cxr = Math.cos(rotX * Math.PI / 180);
        var cyr = Math.cos(rotY * Math.PI / 180);
        var czr = Math.cos(rotZ * Math.PI / 180);

        var csx = Math.sin(camPitch * Math.PI / 180);
        var csy = Math.sin(camYaw * Math.PI / 180);
        var csz = Math.sin(camRoll * Math.PI / 180);
        var ccx = Math.cos(camPitch * Math.PI / 180);
        var ccy = Math.cos(camYaw * Math.PI / 180);
        var ccz = Math.cos(camRoll * Math.PI / 180);

        var vi = 0;
        var pi = 0;
        var uvi = 0;

        while (vi < vertices.length)
        {
            var x = vertices[vi] * modelScale;
            var y = vertices[vi + 1] * modelScale;
            var z = vertices[vi + 2] * modelScale;
            
            var ty = y * cxr - z * sx;
            var tz = y * sx + z * cxr;
            y = ty; z = tz;

            var tx = x * cyr + z * sy;
            tz = -x * sy + z * cyr;
            x = tx; z = tz;

            tx = x * czr - y * sz;
            ty = x * sz + y * czr;
            x = tx; y = ty;

            x += posX - camX;
            y += posY - camY;
            z += posZ - camZ;

            tx = x * ccy - z * csy;
            tz = x * csy + z * ccy;
            x = tx; z = tz;

            ty = y * ccx - z * csx;
            tz = y * csx + z * ccx;
            y = ty; z = tz;

            tx = x * ccz - y * csz;
            ty = x * csz + y * ccz;
            x = tx; y = ty;

            if (z < 1) z = 1;

            var s = focal / z;
            projected[pi] = cx + x * s;
            projected[pi + 1] = cy + y * s;
            uvtData[uvi + 2] = 1.0 / z;

            vi += 3;
            pi += 2;
            uvi += 3;
        }
    }
}
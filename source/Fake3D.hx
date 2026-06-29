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
        "vt 0 0\n" +
        "vt 1 0\n" +
        "vt 1 1\n" +
        "vt 0 1\n" +
        "f 1/1 2/2 3/3 4/4\n" +
        "f 5/1 6/2 7/3 8/4\n" +
        "f 1/1 5/2 8/3 4/4\n" +
        "f 2/1 6/2 7/3 3/4\n" +
        "f 1/1 2/2 6/3 5/4\n" +
        "f 4/1 3/2 7/3 8/4";

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
    public static var sharedCamX:Float = 0;
    public static var sharedCamY:Float = 0;
    public static var sharedCamZ:Float = 0;
    public static var sharedCamPitch:Float = 0;
    public static var sharedCamYaw:Float = 0;
    public static var sharedCamRoll:Float = 0;
    public static var camMoveSpeed:Float = 300;
    public static var camLookSpeed:Float = 90;
    public static var camPitchLimit:Float = 89;
    public static function updateSharedCamera(elapsed:Float):Void
    {
        if (FlxG.keys.pressed.LEFT) sharedCamYaw -= camLookSpeed * elapsed;
        if (FlxG.keys.pressed.RIGHT) sharedCamYaw += camLookSpeed * elapsed;
        if (FlxG.keys.pressed.UP) sharedCamPitch -= camLookSpeed * elapsed;
        if (FlxG.keys.pressed.DOWN) sharedCamPitch += camLookSpeed * elapsed;

        if (sharedCamPitch > camPitchLimit) sharedCamPitch = camPitchLimit;
        if (sharedCamPitch < -camPitchLimit) sharedCamPitch = -camPitchLimit;

        var moveX = 0.0;
        var moveZ = 0.0;
        if (FlxG.keys.pressed.W) moveZ += 1;
        if (FlxG.keys.pressed.S) moveZ -= 1;
        if (FlxG.keys.pressed.D) moveX += 1;
        if (FlxG.keys.pressed.A) moveX -= 1;

        if (moveX != 0 || moveZ != 0)
        {
            var rad = sharedCamYaw * Math.PI / 180;
            var sinY = Math.sin(rad);
            var cosY = Math.cos(rad);
            var dx = moveX * cosY + moveZ * sinY;
            var dz = -moveX * sinY + moveZ * cosY;
            var len = Math.sqrt(dx * dx + dz * dz);

            sharedCamX += dx / len * camMoveSpeed * elapsed;
            sharedCamZ += dz / len * camMoveSpeed * elapsed;
        }

        if (FlxG.keys.pressed.SPACE) sharedCamY -= camMoveSpeed * elapsed;
        if (FlxG.keys.pressed.CONTROL) sharedCamY += camMoveSpeed * elapsed;
    }
    public var texture:BitmapData;
    public var materialBitmaps:Map<String, BitmapData> = new Map();

    var vertices = new Vector<Float>();
    var projected = new Vector<Float>();
    var indices = new Vector<Int>();
    var uvtData = new Vector<Float>();
    var zDepths:Array<Float> = [];

    var materialIndices:Map<String, Vector<Int>> = new Map();
    var materialOrder:Array<String> = [];
    public function new(x:Float, y:Float, ?objPath:String, ?texturePath:String, ?texturePaths:Array<String>, ?materialTextures:Map<String, String>)
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
            loadOBJ(objPath);
        if (materialTextures != null)
            for (matName in materialTextures.keys())
                setMaterialTexture(matName, materialTextures.get(matName));
        if (texturePaths != null)
            setTexturesInOrder(texturePaths);
    }

    public function parseOBJ(data:String)
    {
        var rawVertices:Array<Float> = [];
        var rawUVs:Array<Float> = [];
        var rawFaces:Array<Array<Array<Int>>> = [];
        var rawFaceMaterial:Array<String> = [];

        var currentMaterial:String = "default";

        for (line in data.split("\n"))
        {
            line = StringTools.trim(line);

            if (StringTools.startsWith(line, "v "))
            {
                var p = tokenize(line);
                rawVertices.push(Std.parseFloat(p[1]));
                rawVertices.push(Std.parseFloat(p[2]));
                rawVertices.push(Std.parseFloat(p[3]));
            }
            else if (StringTools.startsWith(line, "vt "))
            {
                var p = tokenize(line);
                rawUVs.push(Std.parseFloat(p[1]));
                rawUVs.push(p.length > 2 ? Std.parseFloat(p[2]) : 0.0);
            }
            else if (StringTools.startsWith(line, "usemtl "))
            {
                var p = tokenize(line);
                if (p.length > 1)
                    currentMaterial = p[1];
            }
            else if (StringTools.startsWith(line, "f "))
            {
                var face:Array<Array<Int>> = [];
                var p = tokenize(line);

                for (i in 1...p.length)
                {
                    var comps = p[i].split("/");
                    var posCount = Std.int(rawVertices.length / 3);
                    var vIdx = Std.parseInt(comps[0]);
                    vIdx = (vIdx < 0) ? (posCount + vIdx) : (vIdx - 1);

                    var vtIdx = -1;
                    if (comps.length > 1 && comps[1] != "")
                    {
                        var uvCount = Std.int(rawUVs.length / 2);
                        vtIdx = Std.parseInt(comps[1]);
                        vtIdx = (vtIdx < 0) ? (uvCount + vtIdx) : (vtIdx - 1);
                    }

                    face.push([vIdx, vtIdx]);
                }

                if (face.length >= 3)
                {
                    rawFaces.push(face);
                    rawFaceMaterial.push(currentMaterial);
                }
            }
        }
        materialOrder = [];
        for (m in rawFaceMaterial)
            if (materialOrder.indexOf(m) == -1)
                materialOrder.push(m);

        vertices = new Vector<Float>();
        indices = new Vector<Int>();
        uvtData = new Vector<Float>();
        materialIndices = new Map();

        var fallbackUVs = [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]];
        var groupBuilders = new Map<String, Array<Int>>();

        var vIdxOut = 0;
        for (faceIdx in 0...rawFaces.length)
        {
            var face = rawFaces[faceIdx];
            var matName = rawFaceMaterial[faceIdx];

            if (!groupBuilders.exists(matName))
                groupBuilders.set(matName, []);
            var group = groupBuilders.get(matName);

            for (i in 1...face.length - 1)
            {
                var fIdx = [0, i, i + 1];
                for (j in 0...3) {
                    var vert = face[fIdx[j]];
                    var posIndex = vert[0];
                    var uvIndex = vert[1];

                    vertices.push(rawVertices[posIndex * 3]);
                    vertices.push(rawVertices[posIndex * 3 + 1]);
                    vertices.push(rawVertices[posIndex * 3 + 2]);

                    var u:Float;
                    var v:Float;

                    if (uvIndex >= 0 && (uvIndex * 2 + 1) < rawUVs.length)
                    {
                        u = rawUVs[uvIndex * 2];
                        v = 1.0 - rawUVs[uvIndex * 2 + 1];
                    }
                    else
                    {
                        var fb = fallbackUVs[fIdx[j] % 4];
                        u = fb[0];
                        v = fb[1];
                    }

                    uvtData.push(u);
                    uvtData.push(v);
                    uvtData.push(1.0);

                    indices.push(vIdxOut);
                    group.push(vIdxOut);
                    vIdxOut++;
                }
            }
        }

        for (matName in groupBuilders.keys())
            materialIndices.set(matName, arrayToVector(groupBuilders.get(matName)));

        projected = new Vector<Float>(Std.int(vertices.length / 3) * 2, true);
        zDepths = [for (i in 0...Std.int(vertices.length / 3)) 1.0];
    }

    public function loadOBJ(path:String)
    {
        if (Assets.exists(path))
        {
            var data = Assets.getText(path);
            parseOBJ(data);
            var dir = path.substring(0, path.lastIndexOf("/") + 1);
            for (line in data.split("\n"))
            {
                var trimmed = StringTools.trim(line);
                if (StringTools.startsWith(trimmed, "mtllib "))
                {
                    var mtlFile = StringTools.trim(trimmed.substr(7));
                    loadMTL(dir + mtlFile);
                    break;
                }
            }
        }
        else
        {
            trace('OBJ not found: $path');
        }
    }
    public function loadMTL(path:String):Void
    {
        if (!Assets.exists(path))
        {
            trace('MTL not found: $path');
            return;
        }

        var data = Assets.getText(path);
        var dir = path.substring(0, path.lastIndexOf("/") + 1);
        var currentName:String = null;

        for (rawLine in data.split("\n"))
        {
            var line = StringTools.trim(rawLine);

            if (StringTools.startsWith(line, "newmtl "))
                currentName = StringTools.trim(line.substr(7));
            else if (StringTools.startsWith(line, "map_Kd ") && currentName != null)
            {
                var texFile = StringTools.trim(line.substr(7));
                setMaterialTexture(currentName, dir + texFile);
            }
        }
    }
    public function setMaterialTexture(materialName:String, path:String):Void
    {
        if (Assets.exists(path))
            materialBitmaps.set(materialName, Assets.getBitmapData(path));
        else
            trace('Texture not found for material "$materialName": $path');
    }
    public function setMaterialBitmap(materialName:String, bitmap:BitmapData):Void
        materialBitmaps.set(materialName, bitmap);

    public function setTexturesInOrder(paths:Array<String>):Void
    {
        for (i in 0...paths.length)
        {
            if (i < materialOrder.length)
                setMaterialTexture(materialOrder[i], paths[i]);
        }
    }
    public function getMaterialNames():Array<String>
        return materialOrder.copy();

    function arrayToVector(arr:Array<Int>):Vector<Int>
    {
        var vec = new Vector<Int>(arr.length, true);
        for (i in 0...arr.length)
            vec[i] = arr[i];
        return vec;
    }

    function tokenize(line:String):Array<String>
        return [for (t in ~/\s+/g.split(line)) if (t.length > 0) t];

    override function draw()
    {
        projectVertices();
        super.draw();

        for (camera in cameras)
        {
            if (!camera.visible || !camera.exists) continue;

            var gfx = camera.canvas.graphics;

            for (matName in materialIndices.keys())
            {
                var idx = materialIndices.get(matName);
                var tex = materialBitmaps.exists(matName) ? materialBitmaps.get(matName) : texture;

                gfx.beginBitmapFill(tex, null, true, true);
                gfx.drawTriangles(projected, idx, uvtData, TriangleCulling.NEGATIVE);
                gfx.endFill();
            }
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

        var totalCamPitch = camPitch + sharedCamPitch;
        var totalCamYaw = camYaw + sharedCamYaw;
        var totalCamRoll = camRoll + sharedCamRoll;

        var csx = Math.sin(totalCamPitch * Math.PI / 180);
        var csy = Math.sin(totalCamYaw * Math.PI / 180);
        var csz = Math.sin(totalCamRoll * Math.PI / 180);
        var ccx = Math.cos(totalCamPitch * Math.PI / 180);
        var ccy = Math.cos(totalCamYaw * Math.PI / 180);
        var ccz = Math.cos(totalCamRoll * Math.PI / 180);

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

            x += posX - (camX + sharedCamX);
            y += posY - (camY + sharedCamY);
            z += posZ - (camZ + sharedCamZ);

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
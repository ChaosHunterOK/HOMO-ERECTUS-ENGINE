package backend.assets;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.Vector;

class PerspectiveWarp extends Sprite
{
    public var segments:Int;
    var vertices:Vector<Float>;
    var indices:Vector<Int>;
    var uvtData:Vector<Float>;
    var lastWidth:Int = -1;
    var lastHeight:Int = -1;
    var dirtyIndices:Bool = true;

    public function new(segments:Int = 10)
    {
        super();
        this.segments = segments;
        vertices = new Vector<Float>();
        indices = new Vector<Int>();
        uvtData = new Vector<Float>();
    }
    
    public function render(bmd:BitmapData, corners:Array<{x:Float, y:Float}>, canvas:BitmapData = null)
    {
        if (bmd == null) return;
        var g = graphics;
        
        if (bmd.width != lastWidth || bmd.height != lastHeight || dirtyIndices)
        {
            buildUVsAndIndices();
            lastWidth = bmd.width;
            lastHeight = bmd.height;
            dirtyIndices = false;
        }
        updateVertices(corners);

        g.clear();
        g.beginBitmapFill(bmd, null, false, true);
        g.drawTriangles(vertices, indices, uvtData);
        g.endFill();
        if (canvas != null) {
            canvas.fillRect(canvas.rect, 0x00000000);
            canvas.draw(this);
        }
    }

    function buildUVsAndIndices()
    {
        vertices.length = 0;
        indices.length = 0;
        uvtData.length = 0;

        for (py in 0...segments + 1)
        {
            for (px in 0...segments + 1)
            {
                var ux:Float = px / segments;
                var uy:Float = py / segments;

                vertices.push(0);
                vertices.push(0);

                uvtData.push(ux);
                uvtData.push(uy);

                if (px < segments && py < segments)
                {
                    var r = py * (segments + 1) + px;
                    indices.push(r);
                    indices.push(r + 1);
                    indices.push(r + segments + 1);

                    indices.push(r + 1);
                    indices.push(r + segments + 2);
                    indices.push(r + segments + 1);
                }
            }
        }
    }

    function updateVertices(corners:Array<{x:Float, y:Float}>)
    {
        var i = 0;
        for (py in 0...segments + 1)
        {
            for (px in 0...segments + 1)
            {
                var ux:Float = px / segments;
                var uy:Float = py / segments;

                var topX = corners[0].x + ux * (corners[1].x - corners[0].x);
                var topY = corners[0].y + ux * (corners[1].y - corners[0].y);

                var botX = corners[3].x + ux * (corners[2].x - corners[3].x);
                var botY = corners[3].y + ux * (corners[2].y - corners[3].y);

                var posX = topX + uy * (botX - topX);
                var posY = topY + uy * (botY - topY);

                vertices[i++] = posX;
                vertices[i++] = posY;
            }
        }
    }
}
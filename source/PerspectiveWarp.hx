import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.Vector;

class PerspectiveWarp extends Sprite {
    public function new() {
        super();
    }
    public function render(bmd:BitmapData, corners:Array<{x:Float, y:Float}>, segments:Int = 10) {
        var g = this.graphics;
        g.clear();
        g.beginBitmapFill(bmd, null, false, true);

        var vertices = new Vector<Float>();
        var indices = new Vector<Int>();
        var uvtData = new Vector<Float>();

        for (py in 0...segments + 1) {
            for (px in 0...segments + 1) {
                var ux = px / segments;
                var uy = py / segments;
                var topX = corners[0].x + ux * (corners[1].x - corners[0].x);
                var topY = corners[0].y + ux * (corners[1].y - corners[0].y);
                var botX = corners[3].x + ux * (corners[2].x - corners[3].x);
                var botY = corners[3].y + ux * (corners[2].y - corners[3].y);

                var posX = topX + uy * (botX - topX);
                var posY = topY + uy * (botY - topY);

                vertices.push(posX);
                vertices.push(posY);
                uvtData.push(ux);
                uvtData.push(uy);

                if (px < segments && py < segments) {
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

        g.drawTriangles(vertices, indices, uvtData);
        g.endFill();
    }
}
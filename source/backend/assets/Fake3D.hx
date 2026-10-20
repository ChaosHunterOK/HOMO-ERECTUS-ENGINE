package backend.assets;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import openfl.Vector;
import openfl.utils.Assets;
import openfl.display.TriangleCulling;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import flixel.addons.display.FlxRuntimeShader;
import openfl.display3D.Context3DTextureFilter;
import openfl.display3D.Context3DWrapMode;
import openfl.Lib;
import flixel.FlxBasic;

//the most insane bs i made bro
//some stuff were taken from other pieces of code which
//tuff
class Fake3DLight
{
    public static inline var DIRECTIONAL:Int = 0;
    public static inline var POINT:Int = 1;

    public var type:Int;
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var color:Int;
    public var intensity:Float;
    public var range:Float;
    public var enabled:Bool = true;

    public function new(type:Int, x:Float, y:Float, z:Float, color:Int = 0xFFFFFF, intensity:Float = 1.0, range:Float = 0.0)
    {
        this.type = type;
        this.x = x;
        this.y = y;
        this.z = z;
        this.color = color;
        this.intensity = intensity;
        this.range = range;
    }
}

class Fake3DMaterial
{
    public static inline var NORMALS_FLAT:Int = 0;
    public static inline var NORMALS_SPHERE:Int = 1;
    public static inline var NORMALS_CYLINDER:Int = 2;
    public var specular:Float = 0.15;
    public var shininess:Float = 40;
    public var reflectivity:Float = 0;
    public var fresnel:Float = 0.6;
    public var opacity:Float = 1;
    public var emissive:Float = 0;
    public var tint:Int = 0xFFFFFF;
    public var normalMode:Int = 0;
    public var smoothAmount:Float = 1;
    public var proceduralChecker:Bool = false;
    public var isFloor:Bool = false;
    public var receiveShadow:Bool = false;

    public function new() {}

    public static function matte():Fake3DMaterial
    {
        var m = new Fake3DMaterial();
        m.specular = 0.0;
        return m;
    }

    public static function plastic():Fake3DMaterial
    {
        var m = new Fake3DMaterial();
        m.specular = 0.7;
        m.shininess = 70;
        m.reflectivity = 0.12;
        m.fresnel = 1.0;
        return m;
    }

    public static function chrome():Fake3DMaterial
    {
        var m = new Fake3DMaterial();
        m.specular = 1.0;
        m.shininess = 200;
        m.reflectivity = 0.95;
        m.fresnel = 0.25;
        m.normalMode = NORMALS_SPHERE;
        return m;
    }

    public static function glass(tint:Int = 0xBFEFFF):Fake3DMaterial
    {
        var m = new Fake3DMaterial();
        m.specular = 1.0;
        m.shininess = 250;
        m.reflectivity = 0.25;
        m.fresnel = 1.0;
        m.opacity = 0.42;
        m.tint = tint;
        m.normalMode = NORMALS_SPHERE;
        return m;
    }

    public static function floor():Fake3DMaterial
    {
        var m = new Fake3DMaterial();
        m.specular = 0.5;
        m.shininess = 120;
        m.reflectivity = 0.45;
        m.fresnel = 1.0;
        m.proceduralChecker = true;
        m.isFloor = true;
        m.receiveShadow = true;
        return m;
    }
}

class Fake3DBlob
{
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var radius:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, radius:Float = 50)
    {
        this.x = x;
        this.y = y;
        this.z = z;
        this.radius = radius;
    }
}

class Fake3DEnv
{
    public static var skyZenith:Int = 0x2F6FCB;
    public static var skyHorizon:Int = 0xCFE3F5;
    public static var skyGround:Int = 0x8D98A6;
    public static var sunColor:Int = 0xFFF3DC;
    public static var sunIntensity:Float = 1.0;
    public static var sunX:Float = -0.45;
    public static var sunY:Float = -0.70;
    public static var sunZ:Float = 0.55;
    public static var sunFromLights:Bool = true;

    public static var cloudCover:Float = 0.55;
    public static var cloudScale:Float = 1.4;
    public static var cloudSpeed:Float = 0.012;
    public static var cloudBrightness:Float = 1.15;
    public static var envMap:BitmapData = null;

    public static var floorEnabled:Bool = false;
    public static var floorY:Float = 0;
    public static var checkerA:Int = 0xF4F4F4;
    public static var checkerB:Int = 0x151515;
    public static var checkerSize:Float = 220;

    public static var fogDensity:Float = 0.00022;
    public static var exposure:Float = 1.0;
    public static var aoStrength:Float = 0.45;
    public static var aoHeight:Float = 90;

    public static var mirrorEnabled:Bool = true;
    public static var mirrorStrength:Float = 0.55;
    public static var mirrorFalloff:Float = 0.0035;
    public static var mirrorMinFresnel:Float = 0.35;

    public static var shadowStrength:Float = 0.5;
    public static var shadowBlobs:Array<Fake3DBlob> = [];

    static var dummyEnv:BitmapData;
    static var SHADOW_NAMES:Array<String> = ["uShadow0", "uShadow1", "uShadow2"];
    static var cachedColors:Map<Int, Array<Float>> = new Map();

    public static function lin(c:Int):Array<Float>
    {
        var r = cachedColors.get(c);
        if (r == null)
        {
            r = [
                Math.pow(((c >> 16) & 0xFF) / 255, 2.2),
                Math.pow(((c >> 8) & 0xFF) / 255, 2.2),
                Math.pow((c & 0xFF) / 255, 2.2)
            ];
            cachedColors.set(c, r);
        }
        return r;
    }

    public static function apply(sh:Fake3DShader, ambientColor:Int, ambientIntensity:Float, ?sunOverride:Array<Float>):Void
    {
        var z = lin(skyZenith);
        var h = lin(skyHorizon);
        var g = lin(skyGround);

        sh.v3("uSkyZenith", z[0], z[1], z[2]);
        sh.v3("uSkyHorizon", h[0], h[1], h[2]);
        sh.v3("uSkyGround", g[0], g[1], g[2]);

        var sx = sunX; var sy = sunY; var sz = sunZ;
        if (sunFromLights && sunOverride != null)
        {
            sx = sunOverride[0]; sy = sunOverride[1]; sz = sunOverride[2];
        }
        var sl = Math.sqrt(sx * sx + sy * sy + sz * sz);
        if (sl < 1e-6) { sx = 0; sy = -1; sz = 0; sl = 1; }
        sh.v3("uSunDir", sx / sl, sy / sl, sz / sl);
        var s = lin(sunColor);
        sh.v3("uSunCol", s[0] * sunIntensity, s[1] * sunIntensity, s[2] * sunIntensity);

        sh.v4("uCloud", cloudCover, cloudScale, (Lib.getTimer() / 1000) * cloudSpeed, cloudBrightness);
        sh.v4("uEnv", envMap != null ? 1 : 0, floorEnabled ? 1 : 0, floorY, fogDensity);
        sh.v4("uCheck", 1 / Math.max(checkerSize, 0.001), exposure, aoStrength, aoHeight);

        var ca = lin(checkerA);
        var cb = lin(checkerB);
        sh.v3("uCheckA", ca[0], ca[1], ca[2]);
        sh.v3("uCheckB", cb[0], cb[1], cb[2]);

        var amb = lin(ambientColor);
        sh.v3("uAmbient", amb[0] * ambientIntensity, amb[1] * ambientIntensity, amb[2] * ambientIntensity);

        var sl0 = (z[0] + h[0] * 2) / 3;
        var sl1 = (z[1] + h[1] * 2) / 3;
        var sl2 = (z[2] + h[2] * 2) / 3;
        var skyLum = Math.max(sl0 * 0.2126 + sl1 * 0.7152 + sl2 * 0.0722, 1e-4);
        var gLum = Math.max(g[0] * 0.2126 + g[1] * 0.7152 + g[2] * 0.0722, 1e-4);
        sh.v3("uHemiSky", sl0 / skyLum * 1.15, sl1 / skyLum * 1.15, sl2 / skyLum * 1.15);
        sh.v3("uHemiGround", g[0] / gLum * 0.55, g[1] / gLum * 0.55, g[2] / gLum * 0.55);

        for (i in 0...3)
        {
            var b = i < shadowBlobs.length ? shadowBlobs[i] : null;
            if (b != null)
                sh.v4(SHADOW_NAMES[i], b.x, b.y, b.z, b.radius);
            else
                sh.v4(SHADOW_NAMES[i], 0, 0, 0, 0);
        }
        sh.f1("uShadowK", shadowStrength);

        if (envMap != null)
            sh.tex("uEnvMap", envMap);
        else
        {
            if (dummyEnv == null) dummyEnv = new BitmapData(2, 2, false, 0xFF808080);
            sh.tex("uEnvMap", dummyEnv);
        }
    }
}

class Fake3DShader extends FlxRuntimeShader
{
    //@:param("uCamPos")
    //public var uCamPos:ShaderParameter<Float>;
    static var meshInstance:Fake3DShader;
    static var skyInstance:Fake3DShader;

    public static function mesh():Fake3DShader
    {
        if (meshInstance == null) meshInstance = new Fake3DShader(MESH_VERT, F3D_LIB + MESH_FRAG);
        return meshInstance;
    }

    public static function sky():Fake3DShader
    {
        if (skyInstance == null) skyInstance = new Fake3DShader(SKY_VERT, F3D_LIB + SKY_FRAG);
        return skyInstance;
    }

    var cache:Map<String, Dynamic> = new Map();

    public function new(vertex:String, fragment:String)
    {
        super(fragment, vertex);
    }

    inline function param(name:String):Dynamic
    {
        var p = cache.get(name);
        if (p == null)
        {
            p = Reflect.field(data, name);
            if (p != null) cache.set(name, p);
        }
        return p;
    }

    var last:Map<String, Array<Float>> = new Map();
    var lastTex:Map<String, BitmapData> = new Map();

    public function f1(name:String, a:Float):Void
    {
        var l = last.get(name);
        if (l != null && l[0] == a) return;
        var p = param(name);
        if (p == null) return;
        var arr = [a];
        last.set(name, arr);
        Reflect.setProperty(p, "value", arr);
    }

    public function v2(name:String, a:Float, b:Float):Void
    {
        var l = last.get(name);
        if (l != null && l[0] == a && l[1] == b) return;
        var p = param(name);
        if (p == null) return;
        var arr = [a, b];
        last.set(name, arr);
        Reflect.setProperty(p, "value", arr);
    }

    public function v3(name:String, a:Float, b:Float, c:Float):Void
    {
        var l = last.get(name);
        if (l != null && l[0] == a && l[1] == b && l[2] == c) return;
        var p = param(name);
        if (p == null) return;
        var arr = [a, b, c];
        last.set(name, arr);
        Reflect.setProperty(p, "value", arr);
    }

    public function v4(name:String, a:Float, b:Float, c:Float, d:Float):Void
    {
        var l = last.get(name);
        if (l != null && l[0] == a && l[1] == b && l[2] == c && l[3] == d) return;
        var p = param(name);
        if (p == null) return;
        var arr = [a, b, c, d];
        last.set(name, arr);
        Reflect.setProperty(p, "value", arr);
    }

    public function tex(name:String, bmp:BitmapData):Void
    {
        if (lastTex.get(name) == bmp) return;
        var p = param(name);
        if (p != null)
        {
            Reflect.setProperty(p, "input", bmp);
            Reflect.setProperty(p, "filter", Context3DTextureFilter.LINEAR);
            Reflect.setProperty(p, "wrap", Context3DWrapMode.CLAMP);
            lastTex.set(name, bmp);
        }
    }

    static inline var F3D_LIB:String = "#ifdef GL_ES
#ifdef GL_OES_standard_derivatives
#extension GL_OES_standard_derivatives : enable
#define F3D_DERIV
#endif
#else
#define F3D_DERIV
#endif

uniform vec3 uCamPos;
uniform vec3 uProj;
uniform vec3 uSkyZenith;
uniform vec3 uSkyHorizon;
uniform vec3 uSkyGround;
uniform vec3 uSunDir;
uniform vec3 uSunCol;
uniform vec4 uCloud;
uniform vec4 uEnv;
uniform vec4 uCheck;
uniform vec3 uCheckA;
uniform vec3 uCheckB;
uniform vec3 uAmbient;
uniform vec4 uShadow0;
uniform vec4 uShadow1;
uniform vec4 uShadow2;
uniform float uShadowK;
uniform sampler2D uEnvMap;

const float PI = 3.14159265;

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm3(vec2 p)
{
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++)
    {
        v += a * vnoise(p);
        p = p * 2.03 + vec2(17.1, 9.2);
        a *= 0.5;
    }
    return v;
}

float fbm5(vec2 p)
{
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++)
    {
        v += a * vnoise(p);
        p = p * 2.03 + vec2(17.1, 9.2);
        a *= 0.5;
    }
    return v;
}

vec3 envSky(vec3 d, float detail)
{
    if (uEnv.x > 0.5)
    {
        float u = atan(d.z, d.x) / (2.0 * PI) + 0.5;
        float v = acos(clamp(-d.y, -1.0, 1.0)) / PI;
        return pow(texture2D(uEnvMap, vec2(u, v)).rgb, vec3(2.2));
    }

    float h = -d.y;
    vec3 col;
    if (h >= 0.0)
        col = mix(uSkyHorizon, uSkyZenith, pow(clamp(h, 0.0, 1.0), 0.45));
    else
        col = mix(uSkyHorizon, uSkyGround, clamp(-h * 3.0, 0.0, 1.0));

    float sd = max(dot(d, uSunDir), 0.0);
    col += uSunCol * (pow(sd, 6.0) * 0.10 + pow(sd, 90.0) * 0.45 + pow(sd, 1800.0) * 6.0);

    if (h > 0.01 && uCloud.x > 0.001)
    {
        vec2 p = d.xz / (h + 0.16) * uCloud.y + vec2(uCloud.z, uCloud.z * 0.37);
        float n;
        float lightK = 0.75;
        if (detail > 0.5)
        {
            n = fbm5(p);
            float n2 = fbm3(p + uSunDir.xz * 0.18);
            lightK = clamp(0.62 + (n - n2) * 2.6, 0.0, 1.0);
        }
        else
            n = fbm3(p);

        float c = smoothstep(1.0 - uCloud.x, 1.0 - uCloud.x + 0.32, n);
        c *= smoothstep(0.0, 0.16, h);
        vec3 shadowCol = uSkyHorizon * 0.55 + vec3(0.12, 0.14, 0.2);
        vec3 litCol = vec3(1.0, 0.98, 0.95) * uCloud.w;
        col = mix(col, mix(shadowCol, litCol, lightK), c * 0.96);
    }
    return col;
}

float checkerMask(vec2 p, float w)
{
    vec2 ww = vec2(max(w, 0.0001));
    vec2 i = 2.0 * (abs(fract((p - 0.5 * ww) * 0.5) - 0.5) - abs(fract((p + 0.5 * ww) * 0.5) - 0.5)) / ww;
    return 0.5 - 0.5 * i.x * i.y;
}

float blobShadow(vec4 b, vec3 P)
{
    if (b.w <= 0.0 || uSunDir.y > -0.08)
        return 1.0;
    float h = max(uEnv.z - b.y, 0.0);
    float t = (b.y - uEnv.z) / uSunDir.y;
    vec2 S = b.xz - t * uSunDir.xz;
    float pen = 0.25 + clamp(h / (b.w * 5.0), 0.0, 1.0) * 0.9;
    float d = length(P.xz - S);
    float s = smoothstep(b.w * (1.0 - pen * 0.5), b.w * (1.0 + pen), d);
    return 1.0 - uShadowK * (1.0 - s);
}

float shadowAt(vec3 P)
{
    return blobShadow(uShadow0, P) * blobShadow(uShadow1, P) * blobShadow(uShadow2, P);
}

float fogAmount(float dist)
{
    return 1.0 - exp(-dist * uEnv.w);
}

vec3 floorColor(vec3 ro, vec3 rd)
{
    float t = (uEnv.z - ro.y) / rd.y;
    vec3 H = ro + rd * t;
    float cosT = max(rd.y, 0.04);
    float footprint = (t / uProj.z + 0.0015 * t) / cosT;
    float m = checkerMask(H.xz * uCheck.x, footprint * uCheck.x);
    vec3 base = mix(uCheckA, uCheckB, m);

    float sunL = max(-uSunDir.y, 0.0);
    float sh = shadowAt(H);
    vec3 lightF = uAmbient * 1.6 + uSunCol * sunL * 0.85 * sh;
    vec3 col = base * lightF;

    float fres = 0.04 + 0.96 * pow(1.0 - cosT, 5.0);
    float gloss = 0.22 + 0.78 * fres;
    vec3 R = vec3(rd.x, -rd.y, rd.z);
    col = mix(col, envSky(R, 0.0), gloss * 0.7);

    col = mix(col, uSkyHorizon, fogAmount(t));
    return col;
}

vec3 envColor(vec3 d, vec3 P)
{
    if (uEnv.y > 0.5 && d.y > 0.002 && P.y < uEnv.z)
        return floorColor(P, d);
    return envSky(d, 0.0);
}

vec3 tonemap(vec3 c)
{
    c *= uCheck.y;
    return (1.0 - exp(-c * 1.35)) / (1.0 - exp(-1.35));
}

vec3 toSRGB(vec3 c)
{
    return pow(clamp(c, 0.0, 1.0), vec3(1.0 / 2.2));
}
";
    static inline var MESH_VERT:String = "attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;
uniform mat4 openfl_Matrix;
uniform vec3 uCamPos;
uniform vec3 uCamRight;
uniform vec3 uCamUp;
uniform vec3 uCamFwd;
uniform vec3 uProj;
varying vec2 vUV;
varying vec3 vWorld;

void main(void)
{
    float z = openfl_Position.w;
    vec2 s = openfl_Position.xy / z;
    vec3 vp = vec3((s.x - uProj.x) * z / uProj.z, (s.y - uProj.y) * z / uProj.z, z);
    vWorld = uCamPos + uCamRight * vp.x + uCamUp * vp.y + uCamFwd * vp.z;
    vUV = openfl_TextureCoord;
    gl_Position = openfl_Matrix * openfl_Position;
}
";
    static inline var MESH_FRAG:String = "uniform sampler2D uAlbedo;
uniform vec2 uTexSize;
uniform float uAA;
uniform vec3 uCamFwd;
uniform vec4 uMatA;
uniform vec4 uMatB;
uniform vec4 uMatC;
uniform vec3 uTint;
uniform vec3 uCenter;
uniform vec3 uHemiSky;
uniform vec3 uHemiGround;
uniform vec4 uLPos0;
uniform vec4 uLCol0;
uniform vec4 uLPos1;
uniform vec4 uLCol1;
uniform vec4 uLPos2;
uniform vec4 uLCol2;
uniform vec4 uMirror;

varying vec2 vUV;
varying vec3 vWorld;

const float WRAP = 0.2;

float wrap1(float x)
{
    return (x >= 0.0 && x <= 1.0) ? x : fract(x);
}

vec3 safeNormalize(vec3 v, vec3 fallback)
{
    float l = length(v);
    return l > 1e-8 ? v / l : fallback;
}

vec4 fetchAlbedo(vec2 uv)
{
    vec2 hTex = 0.5 / max(uTexSize, vec2(1.0));
    uv = vec2(wrap1(uv.x), wrap1(uv.y));
    uv = clamp(uv, hTex, vec2(1.0) - hTex);
    return texture2D(uAlbedo, uv);
}

vec4 accum(vec2 uv)
{
    vec4 c = fetchAlbedo(uv);
    return vec4(c.rgb * c.a, c.a);
}

vec4 sampleAlbedo(vec2 uv, vec2 dx, vec2 dy)
{
    if (uAA < 0.5)
        return fetchAlbedo(uv);

    vec2 tx = dx * uTexSize;
    vec2 ty = dy * uTexSize;
    float fp = max(dot(tx, tx), dot(ty, ty));
    if (fp < 1.5)
        return fetchAlbedo(uv);

    vec4 s = accum(uv + dx * 0.125 + dy * 0.375)
           + accum(uv - dx * 0.125 - dy * 0.375)
           + accum(uv + dx * 0.375 - dy * 0.125)
           + accum(uv - dx * 0.375 + dy * 0.125);
    float n = 4.0;
    if (fp > 6.0)
    {
        s += accum(uv + dx * 0.45)
           + accum(uv - dx * 0.45)
           + accum(uv + dy * 0.45)
           + accum(uv - dy * 0.45);
        n = 8.0;
    }
    return vec4(s.rgb / max(s.a, 1e-4), s.a / n);
}

void addLight(vec4 lp, vec4 lc, vec3 N, vec3 V, vec3 P, float shin, inout vec3 diff, inout vec3 spec)
{
    if (lc.r + lc.g + lc.b <= 0.0)
        return;

    vec3 L;
    float att = 1.0;
    if (lp.w < 0.5)
        L = lp.xyz;
    else
    {
        vec3 d = lp.xyz - P;
        float dist = length(d);
        L = d / max(dist, 1e-4);
        if (lc.a > 0.0)
        {
            att = clamp(1.0 - dist / lc.a, 0.0, 1.0);
            att *= att;
        }
    }

    float ndl = dot(N, L);
    float wrapped = clamp((ndl + WRAP) / (1.0 + WRAP), 0.0, 1.0);
    diff += lc.rgb * (wrapped * att);

    if (ndl > 0.0)
    {
        vec3 H = normalize(L + V);
        spec += lc.rgb * (pow(max(dot(N, H), 0.0), shin) * att);
    }
}

void main(void)
{
#ifdef F3D_DERIV
    vec2 uvDx = dFdx(vUV);
    vec2 uvDy = dFdy(vUV);
#else
    vec2 uvDx = vec2(0.0);
    vec2 uvDy = vec2(0.0);
#endif
    vec3 Pw = vWorld;
    vec3 P = Pw;
    vec3 camEff = uCamPos;
    float mirrorPass = uMirror.x;

    if (mirrorPass > 0.5)
    {
        P.y = 2.0 * uEnv.z - Pw.y;
        camEff.y = 2.0 * uEnv.z - uCamPos.y;
        if (P.y > uEnv.z + 0.5)
            discard;
    }

    vec3 V = normalize(camEff - P);

    vec3 N;
    if (uMatC.y > 0.5)
        N = vec3(0.0, -1.0, 0.0);
    else
    {
#ifdef F3D_DERIV
        N = safeNormalize(cross(dFdx(P), dFdy(P)), vec3(0.0, -1.0, 0.0));
#else
        N = safeNormalize(P - uCenter, vec3(0.0, -1.0, 0.0));
#endif
        float mode = uMatB.w;
        if (mode > 0.5)
        {
            vec3 rad = P - uCenter;
            if (mode > 1.5)
            {
                rad.y = 0.0;
                rad = safeNormalize(rad, N);
                if (dot(N, rad) < 0.0) N = -N;
                float cap = smoothstep(0.55, 0.85, abs(N.y));
                rad = normalize(mix(rad, N, cap));
            }
            else
                rad = safeNormalize(rad, N);
            if (dot(N, rad) < 0.0) N = -N;
            N = safeNormalize(mix(N, rad, uMatB.z), N);
        }
    }
    if (dot(N, V) < 0.0)
        N = -N;

    vec4 tex = sampleAlbedo(vUV, uvDx, uvDy);
    if (tex.a < 0.02)
        discard;

    vec3 albedo = pow(tex.rgb, vec3(2.2)) * uTint;
    float cosV = clamp(dot(N, V), 0.0, 1.0);

    if (uMatC.x > 0.5)
    {
        float zc = max(dot(Pw - uCamPos, uCamFwd), 1.0);
        float footprint = (zc / uProj.z) / max(cosV, 0.06);
        float m = checkerMask(P.xz * uCheck.x, footprint * uCheck.x);
        albedo = mix(uCheckA, uCheckB, m) * uTint;
    }

    float lit = uMatC.w;
    float hgt = max(uEnv.z - P.y, 0.0);
    vec3 diff = vec3(0.0);
    vec3 spec = vec3(0.0);
    vec3 amb = vec3(1.0);
    float ao = 1.0;
    float shin = max(uMatA.y, 1.0);

    if (lit > 0.5)
    {
        float up = -N.y * 0.5 + 0.5;
        amb = mix(uHemiGround, uHemiSky, up) * uAmbient;

        addLight(uLPos0, uLCol0, N, V, P, shin, diff, spec);
        addLight(uLPos1, uLCol1, N, V, P, shin, diff, spec);
        addLight(uLPos2, uLCol2, N, V, P, shin, diff, spec);

        if (uMatC.z > 0.5 && uEnv.y > 0.5)
        {
            float sh = shadowAt(P);
            diff *= sh;
            spec *= sh;
        }

        if (uEnv.y > 0.5 && uMatC.y < 0.5)
            ao = mix(1.0 - uCheck.z, 1.0, smoothstep(0.0, max(uCheck.w, 1.0), hgt));
    }

    float refl = uMatA.z;
    float fres = pow(1.0 - cosV, 5.0);
    float F = clamp(mix(refl, refl + (1.0 - refl) * fres, uMatA.w), 0.0, 1.0);
    if (refl <= 0.001)
        F = 0.0;

    vec3 surface = albedo * (amb + diff) * mix(1.0, ao, 0.9) + albedo * uMatB.y;
    vec3 col = surface;

    if (F > 0.001)
    {
        vec3 R = reflect(-V, N);
        col = mix(surface, envColor(R, P), F);
    }

    vec3 specAdd = spec * uMatA.x * mix(1.0, ao, 0.5);
    float alpha = mix(uMatB.x, 1.0, F);

    if (mirrorPass > 0.5)
    {
        vec3 Vr = normalize(uCamPos - Pw);
        float fm = mix(uMirror.w, 1.0, pow(1.0 - abs(Vr.y), 2.0));
        alpha *= uMirror.y * exp(-hgt * uMirror.z) * fm;
    }

    col = col * 1.0 + specAdd;

    float fog = fogAmount(length(Pw - uCamPos));
    col = mix(col, uSkyHorizon, fog);

    if (lit > 0.5)
        col = tonemap(col);
    col = toSRGB(col);

    gl_FragColor = vec4(col * alpha, alpha);
}
";
    static inline var SKY_VERT:String = "attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;
uniform mat4 openfl_Matrix;
varying vec2 vPix;

void main(void)
{
    vPix = openfl_Position.xy;
    gl_Position = openfl_Matrix * openfl_Position;
}
";
    static inline var SKY_FRAG:String = "uniform vec3 uCamRight;
uniform vec3 uCamUp;
uniform vec3 uCamFwd;
uniform float uDrawFloor;
varying vec2 vPix;

void main(void)
{
    vec3 vd = vec3((vPix.x - uProj.x) / uProj.z, (vPix.y - uProj.y) / uProj.z, 1.0);
    vec3 d = normalize(uCamRight * vd.x + uCamUp * vd.y + uCamFwd * vd.z);

    vec3 col;
    if (uDrawFloor > 0.5 && uEnv.y > 0.5 && d.y > 0.0005 && uCamPos.y < uEnv.z)
    {
        col = floorColor(uCamPos, d);
    }
    else
    {
        col = envSky(d, 1.0);
    }

    col = tonemap(col);
    col = toSRGB(col);
    gl_FragColor = vec4(col, 1.0);
}
";
}

class Fake3DSky extends FlxBasic
{
    public var camX:Float = 0;
    public var camY:Float = 0;
    public var camZ:Float = -500;
    public var camPitch:Float = 0;
    public var camYaw:Float = 0;
    public var camRoll:Float = 0;
    public var fov:Float = 90;
    public var drawFloor:Bool = true;
    public var ambientColor:Int = 0xFFFFFF;
    public var ambientIntensity:Float = 0.45;

    var quadVerts:Vector<Float> = new Vector<Float>(8);
    var quadIdx:Vector<Int> = Vector.ofArray([0, 1, 2, 0, 2, 3]);

    public function new() {super();}

    public function matchCamera(o:Fake3D):Void
    {
        camX = o.camX; camY = o.camY; camZ = o.camZ;
        camPitch = o.camPitch; camYaw = o.camYaw; camRoll = o.camRoll;
        fov = o.fov;
    }

    override function draw():Void
    {
        super.draw();

        var sh = Fake3DShader.sky();
        var basis = Fake3D.camBasis(camPitch + Fake3D.sharedCamPitch, camYaw + Fake3D.sharedCamYaw, camRoll + Fake3D.sharedCamRoll);

        for (camera in cameras)
        {
            if (!camera.visible || !camera.exists) continue;

            var zoom = camera.zoom;
            var cx = camera.width * 0.5 - camera.scroll.x * zoom;
            var cy = camera.height * 0.5 - camera.scroll.y * zoom;
            var focal = (camera.height * 0.5) / Math.tan(fov * Math.PI / 360) * zoom;

            Fake3DEnv.apply(sh, ambientColor, ambientIntensity);
            sh.v3("uCamPos", camX + Fake3D.sharedCamX, camY + Fake3D.sharedCamY, camZ + Fake3D.sharedCamZ);
            sh.v3("uProj", cx, cy, focal);
            sh.v3("uCamRight", basis[0], basis[1], basis[2]);
            sh.v3("uCamUp", basis[3], basis[4], basis[5]);
            sh.v3("uCamFwd", basis[6], basis[7], basis[8]);
            sh.f1("uDrawFloor", drawFloor ? 1 : 0);

            var w = camera.width;
            var h = camera.height;
            quadVerts[0] = -w; quadVerts[1] = -h;
            quadVerts[2] = w * 2; quadVerts[3] = -h;
            quadVerts[4] = w * 2; quadVerts[5] = h * 2;
            quadVerts[6] = -w; quadVerts[7] = h * 2;

            var gfx = camera.canvas.graphics;
            gfx.beginShaderFill(sh);
            gfx.drawTriangles(quadVerts, quadIdx, null, TriangleCulling.NONE);
            gfx.endFill();
        }
    }
}

//live
class Fake3D extends FlxSpriteGroup
{
    public static inline var NEAR_CLIP:Float = 0.5;
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

            sharedCamX += (dx / len) * camMoveSpeed * elapsed;
            sharedCamZ += (dz / len) * camMoveSpeed * elapsed;
        }

        if (FlxG.keys.pressed.SPACE) sharedCamY -= camMoveSpeed * elapsed;
        if (FlxG.keys.pressed.CONTROL) sharedCamY += camMoveSpeed * elapsed;
    }

    public var useShader:Bool = true;
    public var textureAA:Bool = true;
    public var guardBand:Float = 1.5;
    public var subdivideRatio:Float = 0.75;
    public var maxSubdivLevel:Int = 3;
    public var sortKey:Float = 0;
    public var castReflection:Bool = true;
    public var materials:Map<String, Fake3DMaterial> = new Map();
    public var defaultMaterial:Fake3DMaterial = new Fake3DMaterial();
    var matIsFloor:Array<Bool> = [];
    var blob:Fake3DBlob = null;

    public var texture:BitmapData;
    public var materialBitmaps:Map<String, BitmapData> = new Map();
    public var sortAcrossMaterials:Bool = true;
    public var lightingEnabled:Bool = false;
    public var ambientColor:Int = 0xFFFFFF;
    public var ambientIntensity:Float = 0.25;
    public var maxBrightness:Float = 1.0;
    public var lightSteps:Int = 8;
    public var maxLitCacheEntries:Int = 256;
    public var twoSidedLighting:Bool = true;
    public var lights:Array<Fake3DLight> = [];

    var litCache:Map<Int, BitmapData> = new Map();
    var litCacheCount:Int = 0;
    var litCacheSteps:Int = 0;
    var lightData:Array<Float> = [];
    var lightCount:Int = 0;
    var vertices:Vector<Float> = new Vector<Float>();
    var indices:Vector<Int> = new Vector<Int>();
    var uvtData:Vector<Float> = new Vector<Float>();

    var materialIndices:Map<String, Vector<Int>> = new Map();
    var materialOrder:Array<String> = [];
    var srcTriCount:Int = 0;
    var triMaterial:Array<Int> = [];
    var worldPos:Vector<Float> = new Vector<Float>();
    var camBuf:Vector<Float> = new Vector<Float>();
    var outTriIdx:Vector<Int> = new Vector<Int>();
    var outTriMat:Vector<Int> = new Vector<Int>();
    var outTriShade:Vector<Int> = new Vector<Int>();
    var outTriDepth:Vector<Float> = new Vector<Float>();
    var outVertCount:Int = 0;
    var outTriCount:Int = 0;
    var projected:Vector<Float> = new Vector<Float>();
    var clipUVT:Vector<Float> = new Vector<Float>();

    var polyIn:Vector<Float> = new Vector<Float>(50);
    var polyOut:Vector<Float> = new Vector<Float>(50);
    var gL:Float = -4; var gR:Float = 4;
    var gT:Float = -4; var gB:Float = 4;
    var spCx:Float = 0; var spCy:Float = 0; var spFocal:Float = 1;
    static var LPOS_NAMES:Array<String> = ["uLPos0", "uLPos1", "uLPos2"];
    static var LCOL_NAMES:Array<String> = ["uLCol0", "uLCol1", "uLCol2"];
    var mSx:Float = 0; var mCx:Float = 1;
    var mSy:Float = 0; var mCy:Float = 1;
    var mSz:Float = 0; var mCz:Float = 1;
    var kSx:Float = 0; var kCx:Float = 1;
    var kSy:Float = 0; var kCy:Float = 1;
    var kSz:Float = 0; var kCz:Float = 1;
    var rX:Float = 0;
    var rY:Float = 0;
    var rZ:Float = 0;

    public function new(x:Float, y:Float, ?objPath:String, ?texturePath:String, ?texturePaths:Array<String>, ?materialTextures:Map<String, String>)
    {
        super(x, y);

        if (texturePath != null && FNFAssets.exists(texturePath))
            texture = FNFAssets.getBitmapData(texturePath);
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

        triMaterial = [];
        var matIdMap = new Map<String, Int>();
        for (i in 0...materialOrder.length)
            matIdMap.set(materialOrder[i], i);

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
                triMaterial.push(matIdMap.get(matName));
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

        srcTriCount = triMaterial.length;
        allocBuffers();
        clearLightCache();
    }

    function allocBuffers():Void
    {
        worldPos = new Vector<Float>(vertices.length);
        camBuf = new Vector<Float>(srcTriCount * 4 * 5);
        outTriIdx = new Vector<Int>(srcTriCount * 2 * 3);
        outTriMat = new Vector<Int>(srcTriCount * 2);
        outTriShade = new Vector<Int>(srcTriCount * 2);
        outTriDepth = new Vector<Float>(srcTriCount * 2);
        projected = new Vector<Float>(srcTriCount * 4 * 2);
        clipUVT = new Vector<Float>(srcTriCount * 4 * 3);
    }

    public function loadOBJ(path:String)
    {
        if (FNFAssets.exists(path))
        {
            var data = FNFAssets.getText(path);
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
            trace('OBJ not found: $path');
    }

    public function loadMTL(path:String):Void
    {
        if (!FNFAssets.exists(path))
        {
            trace('MTL not found: $path');
            return;
        }

        var data = FNFAssets.getText(path);
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
        if (FNFAssets.exists(path))
        {
            materialBitmaps.set(materialName, FNFAssets.getBitmapData(path));
            clearLightCache();
        }
        else
            trace('Texture not found for material "$materialName": $path');
    }

    public function setMaterialBitmap(materialName:String, bitmap:BitmapData):Void
    {
        materialBitmaps.set(materialName, bitmap);
        clearLightCache();
    }

    public function setTexturesInOrder(paths:Array<String>):Void
    {
        for (i in 0...paths.length)
        {
            if (i < materialOrder.length)
                setMaterialTexture(materialOrder[i], paths[i]);
        }
    }

    public function getMaterial(name:String):Fake3DMaterial
    {
        var m = materials.get(name);
        if (m == null)
        {
            m = new Fake3DMaterial();
            materials.set(name, m);
        }
        return m;
    }

    public function setMaterial(name:String, mat:Fake3DMaterial):Fake3DMaterial
    {
        materials.set(name, mat);
        return mat;
    }

    public function setAllMaterials(mat:Fake3DMaterial):Void
    {
        defaultMaterial = mat;
        for (n in materialOrder) materials.set(n, mat);
    }

    public function enableBlobShadow(radius:Float):Fake3DBlob
    {
        if (blob == null)
        {
            blob = new Fake3DBlob(posX, posY, posZ, radius);
            Fake3DEnv.shadowBlobs.push(blob);
        }
        blob.radius = radius;
        return blob;
    }

    public function disableBlobShadow():Void
    {
        if (blob != null) Fake3DEnv.shadowBlobs.remove(blob);
        blob = null;
    }

    public function getMaterialNames():Array<String>
        return materialOrder.copy();

    function arrayToVector(arr:Array<Int>):Vector<Int>
    {
        var vec = new Vector<Int>(arr.length);
        for (i in 0...arr.length)
            vec[i] = arr[i];
        return vec;
    }

    function tokenize(line:String):Array<String>
        return [for (t in ~/\s+/g.split(line)) if (t.length > 0) t];

    public function addLight(light:Fake3DLight):Fake3DLight
    {
        lights.push(light);
        lightingEnabled = true;
        return light;
    }
    public function addDirectionalLight(dx:Float, dy:Float, dz:Float, color:Int = 0xFFFFFF, intensity:Float = 1.0):Fake3DLight
        return addLight(new Fake3DLight(Fake3DLight.DIRECTIONAL, dx, dy, dz, color, intensity));

    public function addPointLight(x:Float, y:Float, z:Float, color:Int = 0xFFFFFF, intensity:Float = 1.0, range:Float = 0):Fake3DLight
        return addLight(new Fake3DLight(Fake3DLight.POINT, x, y, z, color, intensity, range));

    public function removeLight(light:Fake3DLight):Void
        lights.remove(light);

    public function clearLights():Void
        lights = [];

    public function setAmbient(color:Int, intensity:Float):Void
    {
        ambientColor = color;
        ambientIntensity = intensity;
    }
    public function clearLightCache():Void
    {
        for (bmp in litCache)
            bmp.dispose();
        litCache = new Map();
        litCacheCount = 0;
    }

    override function destroy():Void
    {
        disableBlobShadow();
        clearLightCache();
        super.destroy();
    }
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (blob != null)
        {
            blob.x = posX;
            blob.y = posY;
            blob.z = posZ;
        }
    }

    override function draw()
    {
        super.draw();

        if (useShader)
        {
            drawShaded();
            return;
        }

        computeWorld();
        buildGeometry(0, false, true);
        if (outTriCount == 0) return;

        var order = sortTriangles();
        projected.length = outVertCount * 2;
        clipUVT.length = outVertCount * 3;

        for (camera in cameras)
        {
            if (!camera.visible || !camera.exists) continue;

            projectOutput(camera);
            drawSorted(camera.canvas.graphics, order);
        }
    }
    public function cameraDistSq():Float
    {
        updateTransformCache();
        worldToCamera(posX, posY, posZ);
        return rX * rX + rY * rY + rZ * rZ;
    }
    public static function sortGroupByDepth(group:flixel.group.FlxGroup):Void
    {
        for (m in group.members)
        {
            var f = Std.downcast(m, Fake3D);
            if (f != null) f.sortKey = f.cameraDistSq();
        }

        group.sort(function(order:Int, a:FlxBasic, b:FlxBasic):Int
        {
            var da = depthKeyOf(a);
            var db = depthKeyOf(b);
            return (da > db) ? -1 : ((da < db) ? 1 : 0);
        }, flixel.util.FlxSort.ASCENDING);
    }

    static function depthKeyOf(o:FlxBasic):Float
    {
        if (o == null) return -1;
        var f = Std.downcast(o, Fake3D);
        if (f != null) return f.sortKey;
        if (Std.downcast(o, Fake3DSky) != null) return 1e30;
        return -1;
    }

    function updateTransformCache():Void
    {
        var radX = rotX * Math.PI / 180;
        var radY = rotY * Math.PI / 180;
        var radZ = rotZ * Math.PI / 180;
        mSx = Math.sin(radX); mCx = Math.cos(radX);
        mSy = Math.sin(radY); mCy = Math.cos(radY);
        mSz = Math.sin(radZ); mCz = Math.cos(radZ);

        var camPitchRad = -(camPitch + sharedCamPitch) * Math.PI / 180;
        var camYawRad = -(camYaw + sharedCamYaw) * Math.PI / 180;
        var camRollRad = -(camRoll + sharedCamRoll) * Math.PI / 180;
        kSy = Math.sin(camYawRad); kCy = Math.cos(camYawRad);
        kSx = Math.sin(camPitchRad); kCx = Math.cos(camPitchRad);
        kSz = Math.sin(camRollRad); kCz = Math.cos(camRollRad);
    }
    inline function modelToWorld(lx:Float, ly:Float, lz:Float):Void
    {
        var x = lx * modelScale;
        var y = ly * modelScale;
        var z = lz * modelScale;

        var ty = y * mCx - z * mSx;
        var tz = y * mSx + z * mCx;
        y = ty; z = tz;

        var tx = x * mCy + z * mSy;
        tz = -x * mSy + z * mCy;
        x = tx; z = tz;

        tx = x * mCz - y * mSz;
        ty = x * mSz + y * mCz;
        x = tx; y = ty;

        rX = x + posX;
        rY = y + posY;
        rZ = z + posZ;
    }
    inline function worldToCamera(wx:Float, wy:Float, wz:Float):Void
    {
        var x = wx - (camX + sharedCamX);
        var y = wy - (camY + sharedCamY);
        var z = wz - (camZ + sharedCamZ);

        var tx = x * kCy - z * kSy;
        var tz = x * kSy + z * kCy;
        x = tx; z = tz;

        var ty = y * kCx - z * kSx;
        tz = y * kSx + z * kCx;
        y = ty; z = tz;

        tx = x * kCz - y * kSz;
        ty = x * kSz + y * kCz;
        x = tx; y = ty;

        rX = x; rY = y; rZ = z;
    }

    function transformToCameraSpace(lx:Float, ly:Float, lz:Float):Array<Float>
    {
        updateTransformCache();
        modelToWorld(lx, ly, lz);
        worldToCamera(rX, rY, rZ);
        return [rX, rY, rZ];
    }
    function computeWorld():Void
    {
        updateTransformCache();

        var vertTotal = Std.int(vertices.length / 3);
        for (i in 0...vertTotal)
        {
            var o = i * 3;
            modelToWorld(vertices[o], vertices[o + 1], vertices[o + 2]);
            worldPos[o] = rX;
            worldPos[o + 1] = rY;
            worldPos[o + 2] = rZ;
        }

        if (lightSteps < 2) lightSteps = 2;
        if (lightSteps > 16) lightSteps = 16;
        if (lightSteps != litCacheSteps || litCacheCount > maxLitCacheEntries)
        {
            clearLightCache();
            litCacheSteps = lightSteps;
        }

        computeGuard();
    }

    inline function updateScreenParams(camera:FlxCamera):Void
    {
        var camZoom = camera.zoom;
        spCx = camera.width * 0.5 - camera.scroll.x * camZoom;
        spCy = camera.height * 0.5 - camera.scroll.y * camZoom;
        spFocal = (camera.height * 0.5) / Math.tan(fov * Math.PI / 360) * camZoom;
    }

    //side clip planes
    function computeGuard():Void
    {
        var l = 1e30; var r = -1e30; var tp = 1e30; var bt = -1e30;
        var any = false;
        for (camera in cameras)
        {
            if (!camera.visible || !camera.exists) continue;
            any = true;
            updateScreenParams(camera);
            var gw = camera.width * guardBand;
            var gh = camera.height * guardBand;
            l = Math.min(l, (-gw - spCx) / spFocal);
            r = Math.max(r, (camera.width + gw - spCx) / spFocal);
            tp = Math.min(tp, (-gh - spCy) / spFocal);
            bt = Math.max(bt, (camera.height + gh - spCy) / spFocal);
        }
        if (!any) { l = -4; r = 4; tp = -4; bt = 4; }
        gL = l; gR = r; gT = tp; gB = bt;
    }


    function clipPoly(src:Vector<Float>, n:Int, dst:Vector<Float>, a:Float, b:Float, c:Float, d:Float):Int
    {
        var m = 0;
        var prev = n - 1;
        var po = prev * 5;
        var dp = a * src[po] + b * src[po + 1] + c * src[po + 2] + d;

        for (i in 0...n)
        {
            var o = i * 5;
            var di = a * src[o] + b * src[o + 1] + c * src[o + 2] + d;

            if ((dp >= 0) != (di >= 0))
            {
                var f = dp / (dp - di);
                var w = m * 5;
                po = prev * 5;
                for (k in 0...5)
                    dst[w + k] = src[po + k] + (src[o + k] - src[po + k]) * f;
                m++;
            }
            if (di >= 0)
            {
                var w = m * 5;
                for (k in 0...5) dst[w + k] = src[o + k];
                m++;
            }
            prev = i;
            dp = di;
        }
        return m;
    }

    function buildGeometry(pass:Int = 0, mirrored:Bool = false, legacy:Bool = false):Void
    {
        var lit = legacy && lightingEnabled;
        if (lit) prepareLights();
        var mirrorY2 = 2 * Fake3DEnv.floorY;

        outVertCount = 0;
        outTriCount = 0;

        for (t in 0...srcTriCount)
        {
            var mat = triMaterial[t];
            if (pass == 1 && !matIsFloor[mat]) continue;
            if (pass == 2 && matIsFloor[mat]) continue;
            var orCode = 0;
            var andCode = 31;
            for (k in 0...3)
            {
                var vi = (t * 3 + k) * 3;
                var wy = worldPos[vi + 1];
                worldToCamera(worldPos[vi], mirrored ? mirrorY2 - wy : wy, worldPos[vi + 2]);

                var o = k * 5;
                polyIn[o] = rX;
                polyIn[o + 1] = rY;
                polyIn[o + 2] = rZ;
                polyIn[o + 3] = uvtData[vi];
                polyIn[o + 4] = uvtData[vi + 1];

                var code = 0;
                if (rZ < NEAR_CLIP) code |= 1;
                if (rX - gL * rZ < 0) code |= 2;
                if (gR * rZ - rX < 0) code |= 4;
                if (rY - gT * rZ < 0) code |= 8;
                if (gB * rZ - rY < 0) code |= 16;
                orCode |= code;
                andCode &= code;
            }

            if (andCode != 0) continue;

            var shade = lit ? computeShade(t) : -1;
            var cur = polyIn;
            var oth = polyOut;
            var n = 3;

            if (orCode != 0)
            {
                if ((orCode & 1) != 0)
                {
                    n = clipPoly(cur, n, oth, 0, 0, 1, -NEAR_CLIP);
                    var tmp = cur; cur = oth; oth = tmp;
                    if (n < 3) continue;
                }
                if ((orCode & 2) != 0)
                {
                    n = clipPoly(cur, n, oth, 1, 0, -gL, 0);
                    var tmp = cur; cur = oth; oth = tmp;
                    if (n < 3) continue;
                }
                if ((orCode & 4) != 0)
                {
                    n = clipPoly(cur, n, oth, -1, 0, gR, 0);
                    var tmp = cur; cur = oth; oth = tmp;
                    if (n < 3) continue;
                }
                if ((orCode & 8) != 0)
                {
                    n = clipPoly(cur, n, oth, 0, 1, -gT, 0);
                    var tmp = cur; cur = oth; oth = tmp;
                    if (n < 3) continue;
                }
                if ((orCode & 16) != 0)
                {
                    n = clipPoly(cur, n, oth, 0, -1, gB, 0);
                    var tmp = cur; cur = oth; oth = tmp;
                    if (n < 3) continue;
                }
            }

            emitPolygon(cur, n, mat, shade);
        }
    }

    inline function ensureVerts(extra:Int):Void
    {
        var need = (outVertCount + extra) * 5;
        if (need > camBuf.length)
            camBuf.length = Std.int(Math.max(need, camBuf.length * 2));
    }

    inline function ensureTris():Void
    {
        var cap = Std.int(outTriIdx.length / 3);
        if (outTriCount >= cap)
        {
            var newCap = Std.int(Math.max(cap * 2, 16));
            outTriIdx.length = newCap * 3;
            outTriMat.length = newCap;
            outTriShade.length = newCap;
            outTriDepth.length = newCap;
        }
    }

    function emitPolygon(poly:Vector<Float>, n:Int, mat:Int, shade:Int):Void
    {
        ensureVerts(n);
        var baseV = outVertCount;
        for (i in 0...n * 5)
            camBuf[baseV * 5 + i] = poly[i];
        outVertCount += n;

        for (k in 1...n - 1)
            emitTri(baseV, baseV + k, baseV + k + 1, mat, shade, 0);
    }

    inline function edge2(oa:Int, ob:Int):Float
    {
        var dx = camBuf[oa] - camBuf[ob];
        var dy = camBuf[oa + 1] - camBuf[ob + 1];
        var dz = camBuf[oa + 2] - camBuf[ob + 2];
        return dx * dx + dy * dy + dz * dz;
    }

    function midVert(a:Int, b:Int):Int
    {
        ensureVerts(1);
        var v = outVertCount;
        outVertCount++;
        var o = v * 5; var oa = a * 5; var ob = b * 5;
        for (c in 0...5)
            camBuf[o + c] = (camBuf[oa + c] + camBuf[ob + c]) * 0.5;
        return v;
    }
    function emitTri(a:Int, b:Int, c:Int, mat:Int, shade:Int, level:Int):Void
    {
        var oa = a * 5; var ob = b * 5; var oc = c * 5;

        if (level < maxSubdivLevel && subdivideRatio > 0)
        {
            var minZ = camBuf[oa + 2];
            if (camBuf[ob + 2] < minZ) minZ = camBuf[ob + 2];
            if (camBuf[oc + 2] < minZ) minZ = camBuf[oc + 2];
            var lim = subdivideRatio * minZ;
            var lim2 = lim * lim;

            if (edge2(oa, ob) > lim2 || edge2(ob, oc) > lim2 || edge2(oc, oa) > lim2)
            {
                var ab = midVert(a, b);
                var bc = midVert(b, c);
                var ca = midVert(c, a);
                emitTri(a, ab, ca, mat, shade, level + 1);
                emitTri(ab, b, bc, mat, shade, level + 1);
                emitTri(ca, bc, c, mat, shade, level + 1);
                emitTri(ab, bc, ca, mat, shade, level + 1);
                return;
            }
        }

        ensureTris();
        var ti = outTriCount * 3;
        outTriIdx[ti] = a;
        outTriIdx[ti + 1] = b;
        outTriIdx[ti + 2] = c;
        outTriMat[outTriCount] = mat;
        outTriShade[outTriCount] = shade;
        var cx = (camBuf[oa] + camBuf[ob] + camBuf[oc]) / 3;
        var cy = (camBuf[oa + 1] + camBuf[ob + 1] + camBuf[oc + 1]) / 3;
        var cz = (camBuf[oa + 2] + camBuf[ob + 2] + camBuf[oc + 2]) / 3;
        outTriDepth[outTriCount] = cx * cx + cy * cy + cz * cz;
        outTriCount++;
    }

    function sortTriangles():Array<Int>
    {
        var order:Array<Int> = [for (i in 0...outTriCount) i];
        var byMaterial = !sortAcrossMaterials;

        order.sort(function(a, b)
        {
            if (byMaterial)
            {
                var ma = outTriMat[a];
                var mb = outTriMat[b];
                if (ma != mb) return (ma < mb) ? -1 : 1;
            }
            var za = outTriDepth[a];
            var zb = outTriDepth[b];
            return (za < zb) ? 1 : ((za > zb) ? -1 : 0);
        });
        return order;
    }
    public static function camBasis(pitch:Float, yaw:Float, roll:Float):Array<Float>
    {
        var pr = -pitch * Math.PI / 180;
        var yr = -yaw * Math.PI / 180;
        var rr = -roll * Math.PI / 180;
        var sx = Math.sin(pr); var cx = Math.cos(pr);
        var sy = Math.sin(yr); var cy = Math.cos(yr);
        var sz = Math.sin(rr); var cz = Math.cos(rr);
        var out:Array<Float> = [];
        for (v in [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]])
        {
            var x = v[0]; var y = v[1]; var z = v[2];
            var tx = x * cz + y * sz;
            var ty = -x * sz + y * cz;
            x = tx; y = ty;
            ty = y * cx + z * sx;
            var tz = -y * sx + z * cx;
            y = ty; z = tz;
            tx = x * cy + z * sy;
            tz = -x * sy + z * cy;
            x = tx; z = tz;
            out.push(x); out.push(y); out.push(z);
        }
        return out;
    }

    function drawShaded():Void
    {
        var sh = Fake3DShader.mesh();

        var anyFloor = false;
        matIsFloor = [];
        for (i in 0...materialOrder.length)
        {
            var isF = getMaterialByIndex(i).isFloor;
            matIsFloor.push(isF);
            if (isF) anyFloor = true;
        }
        if (matIsFloor.length == 0) matIsFloor.push(false);

        var camWorldY = camY + sharedCamY;
        var mirrorOn = castReflection && Fake3DEnv.mirrorEnabled && Fake3DEnv.floorEnabled && camWorldY < Fake3DEnv.floorY;
        var passes:Array<Array<Int>> = [];
        if (anyFloor)
        {
            passes.push([1, 0]);
            if (mirrorOn) passes.push([2, 1]);
            passes.push([2, 0]);
        }
        else
        {
            if (mirrorOn) passes.push([0, 1]);
            passes.push([0, 0]);
        }

        var basis = camBasis(camPitch + sharedCamPitch, camYaw + sharedCamYaw, camRoll + sharedCamRoll);
        computeWorld();
        var sunDir:Array<Float> = null;
        for (l in lights)
        {
            if (l.enabled && l.intensity > 0 && l.type == Fake3DLight.DIRECTIONAL)
            {
                sunDir = [-l.x, -l.y, -l.z];
                break;
            }
        }

        for (p in passes)
        {
            buildGeometry(p[0], p[1] == 1, false);
            if (outTriCount == 0) continue;

            var order = sortTriangles();
            projected.length = outVertCount * 2;
            clipUVT.length = outVertCount * 3;

            for (camera in cameras)
            {
                if (!camera.visible || !camera.exists) continue;

                projectOutput(camera);

                Fake3DEnv.apply(sh, ambientColor, ambientIntensity, sunDir);
                uploadLights(sh);
                sh.v3("uCamPos", camX + sharedCamX, camWorldY, camZ + sharedCamZ);
                sh.v3("uProj", spCx, spCy, spFocal);
                sh.v3("uCamRight", basis[0], basis[1], basis[2]);
                sh.v3("uCamUp", basis[3], basis[4], basis[5]);
                sh.v3("uCamFwd", basis[6], basis[7], basis[8]);
                sh.v3("uCenter", posX, posY, posZ);
                sh.v4("uMirror", p[1], Fake3DEnv.mirrorStrength, Fake3DEnv.mirrorFalloff, Fake3DEnv.mirrorMinFresnel);

                drawSortedShaded(camera.canvas.graphics, order, sh);
            }
        }
    }

    function getMaterialByIndex(mat:Int):Fake3DMaterial
    {
        var name = materialOrder[mat];
        var m = (name != null) ? materials.get(name) : null;
        return m != null ? m : defaultMaterial;
    }

    function uploadLights(sh:Fake3DShader):Void
    {
        var n = 0;
        for (l in lights)
        {
            if (n >= 3) break;
            if (!l.enabled || l.intensity <= 0) continue;

            var x = l.x; var y = l.y; var z = l.z;
            if (l.type == Fake3DLight.DIRECTIONAL)
            {
                var len = Math.sqrt(x * x + y * y + z * z);
                if (len < 1e-9) continue;
                x = -x / len; y = -y / len; z = -z / len;
            }

            var c = Fake3DEnv.lin(l.color);
            sh.v4(LPOS_NAMES[n], x, y, z, l.type);
            sh.v4(LCOL_NAMES[n], c[0] * l.intensity, c[1] * l.intensity, c[2] * l.intensity, l.range);
            n++;
        }
        while (n < 3)
        {
            sh.v4(LPOS_NAMES[n], 0, 0, 0, 0);
            sh.v4(LCOL_NAMES[n], 0, 0, 0, 0);
            n++;
        }
    }

    function buildRun(order:Array<Int>, from:Int, to:Int):Vector<Int>
    {
        var run = new Vector<Int>((to - from) * 3);
        var w = 0;
        for (i in from...to)
        {
            var ti = order[i] * 3;
            run[w] = outTriIdx[ti];
            run[w + 1] = outTriIdx[ti + 1];
            run[w + 2] = outTriIdx[ti + 2];
            w += 3;
        }
        return run;
    }

    function drawSortedShaded(gfx:openfl.display.Graphics, order:Array<Int>, sh:Fake3DShader):Void
    {
        var total = order.length;
        var i = 0;
        while (i < total)
        {
            var m = outTriMat[order[i]];
            var j = i + 1;
            while (j < total && outTriMat[order[j]] == m) j++;
            flushShaded(gfx, buildRun(order, i, j), m, sh);
            i = j;
        }
    }

    function flushShaded(gfx:openfl.display.Graphics, run:Vector<Int>, mat:Int, sh:Fake3DShader):Void
    {
        var name = materialOrder[mat];
        var base = (name != null && materialBitmaps.exists(name)) ? materialBitmaps.get(name) : texture;
        var mt = getMaterialByIndex(mat);
        var tint = Fake3DEnv.lin(mt.tint);

        sh.tex("uAlbedo", base);
        sh.v2("uTexSize", base.width, base.height);
        sh.f1("uAA", textureAA ? 1 : 0);
        sh.v3("uTint", tint[0], tint[1], tint[2]);
        sh.v4("uMatA", mt.specular, mt.shininess, mt.reflectivity, mt.fresnel);
        sh.v4("uMatB", mt.opacity, mt.emissive, mt.smoothAmount, mt.normalMode);
        sh.v4("uMatC", mt.proceduralChecker ? 1 : 0, mt.isFloor ? 1 : 0, mt.receiveShadow ? 1 : 0, lightingEnabled ? 1 : 0);

        gfx.beginShaderFill(sh);
        gfx.drawTriangles(projected, run, clipUVT, TriangleCulling.NONE);
        gfx.endFill();
    }

    function projectOutput(camera:FlxCamera):Void
    {
        updateScreenParams(camera);
        var cx = spCx;
        var cy = spCy;
        var focal = spFocal;

        for (v in 0...outVertCount)
        {
            var o = v * 5;
            var z = camBuf[o + 2];
            if (z < NEAR_CLIP) z = NEAR_CLIP;

            var s = focal / z;
            projected[v * 2] = cx + camBuf[o] * s;
            projected[v * 2 + 1] = cy + camBuf[o + 1] * s;

            clipUVT[v * 3] = camBuf[o + 3];
            clipUVT[v * 3 + 1] = camBuf[o + 4];
            clipUVT[v * 3 + 2] = 1.0 / z;
        }
    }

    function drawSorted(gfx:openfl.display.Graphics, order:Array<Int>):Void
    {
        var total = order.length;
        var i = 0;
        while (i < total)
        {
            var t0 = order[i];
            var m = outTriMat[t0];
            var s = outTriShade[t0];
            var j = i + 1;
            while (j < total && outTriMat[order[j]] == m && outTriShade[order[j]] == s) j++;
            flushRun(gfx, buildRun(order, i, j), m, s);
            i = j;
        }
    }

    function flushRun(gfx:openfl.display.Graphics, run:Vector<Int>, mat:Int, shade:Int):Void
    {
        gfx.beginBitmapFill(getRunTexture(mat, shade), null, true, true);
        gfx.drawTriangles(projected, run, clipUVT, TriangleCulling.NONE);
        gfx.endFill();
    }

    function prepareLights():Void
    {
        lightData = [];
        lightCount = 0;

        for (l in lights)
        {
            if (!l.enabled || l.intensity <= 0) continue;

            var x = l.x;
            var y = l.y;
            var z = l.z;
            if (l.type == Fake3DLight.DIRECTIONAL)
            {
                var len = Math.sqrt(x * x + y * y + z * z);
                if (len < 1e-9) continue;
                x = -x / len;
                y = -y / len;
                z = -z / len;
            }

            lightData.push(l.type);
            lightData.push(x);
            lightData.push(y);
            lightData.push(z);
            lightData.push(((l.color >> 16) & 0xFF) / 255 * l.intensity);
            lightData.push(((l.color >> 8) & 0xFF) / 255 * l.intensity);
            lightData.push((l.color & 0xFF) / 255 * l.intensity);
            lightData.push(l.range);
            lightCount++;
        }
    }

    function quantChannel(v:Float):Int
    {
        if (v < 0) v = 0;
        if (v > maxBrightness) v = maxBrightness;
        return Std.int(v / maxBrightness * (lightSteps - 1) + 0.5);
    }

    function computeShade(t:Int):Int
    {
        var o = t * 9;
        var ax = worldPos[o];     var ay = worldPos[o + 1]; var az = worldPos[o + 2];
        var bx = worldPos[o + 3]; var by = worldPos[o + 4]; var bz = worldPos[o + 5];
        var cx = worldPos[o + 6]; var cy = worldPos[o + 7]; var cz = worldPos[o + 8];

        var lr = ((ambientColor >> 16) & 0xFF) / 255 * ambientIntensity;
        var lg = ((ambientColor >> 8) & 0xFF) / 255 * ambientIntensity;
        var lb = (ambientColor & 0xFF) / 255 * ambientIntensity;

        var e1x = bx - ax; var e1y = by - ay; var e1z = bz - az;
        var e2x = cx - ax; var e2y = cy - ay; var e2z = cz - az;
        var nx = e1y * e2z - e1z * e2y;
        var ny = e1z * e2x - e1x * e2z;
        var nz = e1x * e2y - e1y * e2x;
        var nLen = Math.sqrt(nx * nx + ny * ny + nz * nz);

        if (nLen > 1e-9)
        {
            nx /= nLen; ny /= nLen; nz /= nLen;

            var mx = (ax + bx + cx) / 3;
            var my = (ay + by + cy) / 3;
            var mz = (az + bz + cz) / 3;
            var toCamX = (camX + sharedCamX) - mx;
            var toCamY = (camY + sharedCamY) - my;
            var toCamZ = (camZ + sharedCamZ) - mz;
            if (twoSidedLighting && nx * toCamX + ny * toCamY + nz * toCamZ < 0)
            {
                nx = -nx; ny = -ny; nz = -nz;
            }

            for (i in 0...lightCount)
            {
                var li = i * 8;
                var lx = lightData[li + 1];
                var ly = lightData[li + 2];
                var lz = lightData[li + 3];
                var atten = 1.0;

                if (lightData[li] == Fake3DLight.POINT)
                {
                    lx -= mx; ly -= my; lz -= mz;
                    var dist = Math.sqrt(lx * lx + ly * ly + lz * lz);
                    if (dist < 1e-9) continue;
                    lx /= dist; ly /= dist; lz /= dist;

                    var range = lightData[li + 7];
                    if (range > 0)
                    {
                        if (dist >= range) continue;
                        atten = 1 - dist / range;
                        atten *= atten;
                    }
                }

                var ndl = nx * lx + ny * ly + nz * lz;
                if (ndl <= 0) continue;

                var k = ndl * atten;
                lr += lightData[li + 4] * k;
                lg += lightData[li + 5] * k;
                lb += lightData[li + 6] * k;
            }
        }

        return (quantChannel(lr) * lightSteps + quantChannel(lg)) * lightSteps + quantChannel(lb);
    }

    function getRunTexture(mat:Int, shade:Int):BitmapData
    {
        var name = materialOrder[mat];
        var base = (name != null && materialBitmaps.exists(name)) ? materialBitmaps.get(name) : texture;
        if (shade < 0) return base;

        var key = (mat << 16) | shade;
        var cached = litCache.get(key);
        if (cached != null) return cached;

        var steps = lightSteps;
        var bi = shade % steps;
        var gi = Std.int(shade / steps) % steps;
        var ri = Std.int(shade / (steps * steps));
        var f = maxBrightness / (steps - 1);

        var tinted = base.clone();
        tinted.colorTransform(tinted.rect, new ColorTransform(ri * f, gi * f, bi * f, 1, 0, 0, 0, 0));
        litCache.set(key, tinted);
        litCacheCount++;
        return tinted;
    }

    public function projectPoint(localX:Float, localY:Float, localZ:Float, ?camera:FlxCamera):Dynamic
    {
        if (camera == null) camera = FlxG.camera;

        var cam = transformToCameraSpace(localX, localY, localZ);
        var z = cam[2];
        if (z < NEAR_CLIP) return null;

        updateScreenParams(camera);
        var s = spFocal / z;

        return {
            x: spCx + cam[0] * s,
            y: spCy + cam[1] * s,
            scale: s,
            z: z
        };
    }
}
import openfl.display3D.Program3D;
import flixel.system.FlxAssets.FlxShader;

@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
class FlxShaderFix extends FlxShader
{
    public var custom:Bool = false;

    public override function new()
    {
        super();
    }

    @:noCompletion
    private override function __initGL():Void
    {
        if (__glSourceDirty || __paramBool == null)
        {
            __glSourceDirty = false;
            program = null;

            __inputBitmapData = [];
            __paramBool = [];
            __paramFloat = [];
            __paramInt = [];

            __processGLData(glVertexSource, "attribute");
            __processGLData(glVertexSource, "uniform");
            __processGLData(glFragmentSource, "uniform");
        }

        if (__context == null || program != null)
            return;

        var gl = __context.gl;

        var vertex = buildPrefix() + glVertexSource;
        var fragment = buildPrefix() + glFragmentSource;

        var id = vertex + fragment;

        if (__context.__programs.exists(id))
        {
            program = __context.__programs.get(id);
        }
        else
        {
            program = __context.createProgram(GLSL);
            program.__glProgram = __createGLProgram(vertex, fragment);
            __context.__programs.set(id, program);
        }

        if (program == null)
            return;

        glProgram = program.__glProgram;

        bindLocations(__inputBitmapData, gl);
        bindLocations(__paramBool, gl);
        bindLocations(__paramFloat, gl);
        bindLocations(__paramInt, gl);
    }

    inline function buildPrefix():String
    {
        var precision = switch (precisionHint)
        {
            case FULL:
                "#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif";

            default:
                "precision lowp float;";
        }

        return "#version 120\n"
            + "#ifdef GL_ES\n"
            + precision + "\n"
            + "#endif\n";
    }

    inline function bindLocations(list:Array<Dynamic>, gl:Dynamic):Void
    {
        for (item in list)
        {
            item.index = item.__isUniform
                ? gl.getUniformLocation(glProgram, item.name)
                : gl.getAttribLocation(glProgram, item.name);
        }
    }
}
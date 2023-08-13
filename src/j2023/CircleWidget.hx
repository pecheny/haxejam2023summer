package j2023;

import Axis2D;
import ColorTexSet;
import al.al2d.Placeholder2D;
import data.IndexCollection;
import data.aliases.AttribAliases;
import gl.AttribSet;
import gl.ValueWriter;
import graphics.shapes.RectWeights;
import graphics.shapes.Shape;
import haxe.io.Bytes;
import macros.AVConstructor;
import mesh.providers.AttrProviders.SolidColorProvider;
import transform.Transformer;
import widgets.ShapeWidget;


class CircleWidget extends ShapeWidget<ColorTexSet> {
    var c:CircleView<ColorTexSet>;
    var color:Int;

    public function new(fuiBuilder:FuiBuilder, w:Placeholder2D, color) {
        super(ColorTexSet.instance, w);
        c = new CircleView(attrs);
        this.color = color;
        c.setColor(color, 255);
        addChild(c);
    }

    public function setAreaCoef(a:Float) {
        c.setAreaCoef(a);
    }

    public function setAlpha(a:Int) {
        c.setColor(color, a);
    }

    public function setOffset(o) {
        c.setOffset(o);
    }
}

class CircleView<T:AttribSet> implements Shape {
    var writers:AttributeWriters;
    var colorWriters:AttributeWriters;
    var uvWriters:AttributeWriters;
    var cp = SolidColorProvider.fromInt(0xf05034);
    var offset:AVector2D<Float> = AVConstructor.create(0., 0.);

    public var weights:AVector2D<Array<Float>>;
    public var r = 0.5;

    public function setAreaCoef(s:Float) {
        r = 1 / Math.sqrt(1 / s);
        // r = Math.sqrt(2*s/Math.PI);
    }

    public function new(attrs:T) {
        weights = RectWeights.identity();
        writers = attrs.getWriter(AttribAliases.NAME_POSITION);
        colorWriters = attrs.getWriter(AttribAliases.NAME_COLOR_IN);
        uvWriters = attrs.getWriter(AttribAliases.NAME_UV_0);
        setColor(0xd54a04, 100);
    }

    public function writePostions(target:Bytes, vertOffset:Int = 0, transformer:Transformer) {
        var scale = r; //*2;
        var padding = (1 - scale) / 2;
        inline function writeAxis(axis:Axis2D, i) {
            var wg = weights[axis][i];
            writers[axis].setValue(target, vertOffset + i, transformer(axis, offset[axis] + padding + scale * wg));
            uvWriters[axis].setValue(target, vertOffset + i, wg);
        }
        for (i in 0...4) {
            writeAxis(horizontal, i);
            writeAxis(vertical, i);
            for (ci in 0...4)
                colorWriters[ci].setValue(target, vertOffset + i, cp.getValue(0, ci));
        }
    }

    public function setOffset(o) {
        offset[vertical] = o;
    }

    public function getVertsCount():Int {
        return 4;
    }

    public function setColor(c:Int, a) {
        cp.setColor(c).setAlpha(a);
    }

    public inline function getIndices():IndexCollection {
        return IndexCollections.QUAD_ODD;
    }
}
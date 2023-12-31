package j2023;

import Axis2D;
import ColorTexSet;
import al.al2d.Placeholder2D;
import data.IndexCollection;
import data.aliases.AttribAliases;
import ec.CtxWatcher;
import ecbind.InputBinder;
import gl.AttribSet;
import gl.ValueWriter;
import graphics.shapes.Shape;
import haxe.io.Bytes;
import hxGeomAlgo.EarCut as Earcut;
import mesh.providers.AttrProviders.SolidColorProvider;
import openfl.Lib;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.Assets;
import shimp.InputSystem;
import utils.Data;
import utils.MathUtil;
import widgets.ShapeWidget;
import widgets.Slider.ToWidgetSpace;
import widgets.utils.WidgetHitTester;

class SplittingWidget extends ShapeWidget<ColorTexSet> {
    var aestimator = new AreaEstimator();
    var trap:Trapezoid<ColorTexSet>;

    public function new(fuiBuilder:FuiBuilder, w:Placeholder2D, filename) {
        super(ColorTexSet.instance, w);
        trap = new Trapezoid(attrs);
        addChild(trap);
        var inp = new SplitInput(w, fuiBuilder.ar, (x, y) -> {
            if(trap.alpha < 255)
                return;
            trap.setCrop(x, y);
            shapeRenderer.fillIndices();
        });
        w.entity.addComponentByType(InputSystemTarget, inp);
        new CtxWatcher(InputBinder, w.entity);
    }

    public function getRatio():Float {
        return aestimator.checkArea(trap.pathSplittedRaw, trap.indsRaw);
    }

    public function setAlpha(a:Int) {
        trap.setAlpha(a);
    }

    // public function setFade(t:Float) {}
}

class AreaEstimator {
    var bdata:BitmapData;
    var refImg:BitmapData;
    var canvas = new Sprite();
    var rect = new Rectangle(0, 0, 256, 256);
    var mat:Matrix;
    var refCoverage:Float;

    public function new() {
        bdata = new BitmapData(256, 256, false, 0);
        mat = new Matrix();
        mat.scale(256, 256);
        refImg = Assets.getBitmapData("Assets/c-256.png");
        // Lib.current.addChild(new Bitmap(bdata));
        // Lib.current.addChild(canvas);
        refCoverage = getCoverage(refImg);
    }

    var inds:Vector<Int> = new Vector();
    var verts:Vector<Float> = new Vector();

    // var uv:Vector<Float> = new Vector();
    function getCoverage(bdata:BitmapData) {
        var hist = bdata.histogram()[2];
        return hist[hist.length - 1];
    }

    public function checkArea(v:Array<Float>, ind:Array<Int>) {
        inds.length = 0;
        for (i in ind)
            inds.push(i);
        verts.length = 0;
        for (i in v)
            verts.push(i);
        canvas.graphics.clear();
        canvas.graphics.beginBitmapFill(refImg);
        canvas.graphics.drawTriangles(verts, inds, verts);
        canvas.graphics.endFill();
        canvas.scaleX = canvas.scaleY = 256;
        bdata.fillRect(rect, 0);
        bdata.draw(canvas, mat);
        var cvr = getCoverage(bdata);
        var ratio = (cvr / refCoverage);
        // trace(cvr + " " + refCoverage + " " + ratio);
        return ratio;
    }
}


class Trapezoid<T:AttribSet> implements Shape {
    var locPointer = new Vec2D();
    var secFrom = new Vec2D(-0.1, -0.20);
    var lastIntersection = new Vec2D();
    var writers:AttributeWriters;
    var colorWriters:AttributeWriters;
    var uvWriters:AttributeWriters;
    // var canvas = new FigureRender2();
    var pathOrig:Array<Vec2D> = [];
    var pathSplitted:Array<Vec2D> = [];
    var cp = SolidColorProvider.fromInt(0xf05034);

    public var pathSplittedRaw:Array<Float> = [];
    public var indsRaw:Array<Int> = [];

    var indices = new IndexCollection(12);

    public function new(attrs:T) {
        // Lib.current.addChild(canvas);
        writers = attrs.getWriter(AttribAliases.NAME_POSITION);
        uvWriters = attrs.getWriter(AttribAliases.NAME_UV_0);
        colorWriters = attrs.getWriter(AttribAliases.NAME_COLOR_IN);
        pathOrig.push(new Vec2D(0, 0));
        pathOrig.push(new Vec2D(1, 0));
        pathOrig.push(new Vec2D(1, 1));
        pathOrig.push(new Vec2D(0.0, 1.0));
    }

    public function setCrop(x, y:Float) {
        locPointer.init(x, 1 - y);
        buildIntersectedPath(secFrom, locPointer);
    }

    public inline function getIndices():IndexCollection {
        return indices;
    }

    function getLineIntersection(a1:Vec2DRO, a2:Vec2DRO, b1:Vec2DRO, b2:Vec2DRO) {
        return MathUtil.get_line_intersection(a1.x, a1.y, a2.x, a2.y, b1.x, b1.y, b2.x, b2.y, lastIntersection, false);
    }

    function buildIntersectedPath(secator1:Vec2D, secator2:Vec2D) {
        var afterVert = [];
        var intersections = [];
        secator1.init(0.5, 1.1);
        secator2.remove(secator1);
        secator2.normalize(2);
        secator2.add(secator1);

        function checkEdge(pi1, pi2) {
            var p1 = pathOrig[pi1];
            var p2 = pathOrig[pi2];
            if (getLineIntersection(p1, p2, secator1, secator2)) {
                afterVert.push(pi1);
                intersections.push(lastIntersection.clone());
            }
        }
        for (i in 1...pathOrig.length)
            checkEdge(i - 1, i);
        checkEdge(pathOrig.length - 1, 0);

        pathSplitted.resize(0);
        if (intersections.length < 1)
            return;

        if (afterVert[0] < 2) {
            for (i in 0...afterVert[0] + 1)
                pathSplitted.push(pathOrig[i]);
            pathSplitted.push(intersections[0]);
            pathSplitted.push(intersections[1]);
            for (i in afterVert[1] + 1...pathOrig.length)
                pathSplitted.push(pathOrig[i]);
        } else {
            for (i in afterVert[0] + 1...afterVert[1] + 1)
                pathSplitted.push(pathOrig[i]);
            pathSplitted.push(intersections[1]);
            pathSplitted.push(intersections[0]);
        }

        // canvas.render(pathSplitted);
        // canvas.setText("" + afterVert);

        var ep = pathSplittedRaw;
        ep.resize(0);
        for (p in pathSplitted) {
            ep.push(p.x);
            ep.push(p.y);
        }
        indsRaw = Earcut.earcut(ep);

        for (i in 0...indsRaw.length)
            indices[i] = indsRaw[i];
    }

    public function writePostions(target:Bytes, vertOffset = 0, transformer) {
        var i = 0;
        function writePoint(x, y) {
            writers[horizontal].setValue(target, vertOffset + i, transformer(horizontal, x));
            writers[vertical].setValue(target, vertOffset + i, transformer(vertical, y));
            uvWriters[horizontal].setValue(target, vertOffset + i, x);
            uvWriters[vertical].setValue(target, vertOffset + i, y);
            for (ci in 0...4)
                colorWriters[ci].setValue(target, vertOffset + i, cp.getValue(0, ci));
            i++;
        }

        for (i in 0...getVertsCount()) {
            if (i < pathSplitted.length) {
                var p = pathSplitted[i];
                writePoint(p.x, 1 - p.y);
            } else
                writePoint(0, 0);
        }
    }

    public function setColor(c:Int) {
        cp.setColor(c);
    }

    public var alpha (default, null):Int = 255;
    public function setAlpha(a:Int) {
        cp.setAlpha(a);
        alpha = a;
    }

    public function getVertsCount():Int {
        return 12;
    }
}

class SplitInput implements InputSystemTarget<Point> {
    var hitTester:HitTester<Point>;
    var pos:Point;
    var pressed = false;
    var toLocal:ToWidgetSpace;
    var a:Axis2D;
    var handler:(Float, Float) -> Void;

    public function new(w, stage, h) {
        this.hitTester = new WidgetHitTester(w);
        this.toLocal = new ToWidgetSpace(w, stage);
        this.handler = h;
    }

    public function setPos(pos:Point):Void {
        this.pos = pos;
        var x = toLocal.transformValue(horizontal, posVal(pos, horizontal));
        var y = toLocal.transformValue(vertical, posVal(pos, vertical));
        handler(MathUtil.clamp(x, 0, 1), MathUtil.clamp(y, 0, 1));
    }

    inline function posVal(p:Point, a:Axis2D) {
        return switch a {
            case horizontal: p.x;
            case vertical: p.y;
        }
    }

    public function isUnder(pos:Point):Bool {
        return hitTester.isUnder(pos);
    }

    public function setActive(val:Bool):Void {
        if (!val)
            pressed = false;
    }

    public function press():Void {
        pressed = true;
        setPos(pos);
    }

    public function release():Void {
        pressed = false;
    }
}

// class FigureRender2 extends Sprite {
//     var tf = new TextField();

//     public function new() {
//         super();
//         addChild(tf);
//         tf.multiline = true;
//         tf.width = 600;
//     }

//     public function setText(t) {
//         tf.text = t;
//     }

//     public function render(figures:Array<Vec2D>) {
//         var s = 300;
//         graphics.clear();
//         var path = figures;
//         graphics.lineStyle(1, 0xffffff);
//         graphics.moveTo(100 + s * path[0].x, 100 + s * path[0].y);
//         for (i in 1...path.length)
//             graphics.lineTo(100 + s * path[i].x, 100 + s * path[i].y);
//         graphics.lineTo(100 + s * path[0].x, 100 + s * path[0].y);
//     }
// }

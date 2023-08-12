package j2023;

// import earcut.Earcut;
import gl.RenderTarget;
import hxGeomAlgo.EarCut as Earcut;
import openfl.text.TextField;
import utils.MathUtil;
import utils.Data;
import macros.AVConstructor;
import data.IndexCollection;
import haxe.io.Bytes;
import haxe.ds.ReadOnlyArray;
import data.IndexCollection.IndexCollections;
import graphics.shapes.RectWeights;
import Axis2D;
import gl.ValueWriter;
import gl.AttribSet;
import graphics.shapes.Shape;
import ecbind.InputBinder;
import utils.Mathu;
import ec.CtxWatcher;
import widgets.utils.WidgetHitTester;
import shimp.InputSystem.HitTester;
import widgets.Slider.ToWidgetSpace;
import shimp.InputSystem.InputSystemTarget;
import openfl.display.Bitmap;
import openfl.utils.Assets;
import openfl.display.Sprite;
import openfl.Lib;
import graphics.shapes.QuadGraphicElement;
import data.aliases.AttribAliases;
import al.al2d.Placeholder2D;
import gl.sets.TexSet;
import widgets.ShapeWidget;

class DebugQuadRender extends ShapeWidget<TexSet> {
    public function new(fuiBuilder:FuiBuilder, w:Placeholder2D, filename, createGldo = false) {
        var attrs = TexSet.instance;
        super(attrs, w);
        // var shw = new ShapeWidget(attrs, w);
        var trap = new Trapezoid(attrs);
        addChild(trap);
        var uvs = new graphics.DynamicAttributeAssigner(attrs, getBuffer());
        var inp = new SplitInput(w, fuiBuilder.ar, trap.setCrop);
        w.entity.addComponentByType(InputSystemTarget, inp);
        new CtxWatcher(InputBinder, w.entity);
    }

    override function render(targets:RenderTarget<TexSet>) {
        shapeRenderer.fillIndices();
        super.render(targets);
    }
}

class Trapezoid<T:AttribSet> implements Shape {
    public var weights:AVector2D<Array<Float>>;
    public var mul:AVector2D<Float> = AVConstructor.create(1, 1);

    var locPointer = new Vec2D();
    var secFrom = new Vec2D(-0.1, -0.20);
    var writers:AttributeWriters;
    var uvWriters:AttributeWriters;
    var canvas = new FigureRender2();

    public function new(attrs:T) {
        Lib.current.addChild(canvas);
        weights = RectWeights.identity();
        // var writers:AttributeWriters;
        writers = attrs.getWriter(AttribAliases.NAME_POSITION);
        uvWriters = attrs.getWriter(AttribAliases.NAME_UV_0);
        updateShape();
    }

    public function setCrop(x, y) {
        // trace("crop", x, y);
        // mul[horizontal] = x;
        // mul[vertical] = y;
        // lineFromPoints(0.5, 0, x, y);
        locPointer.init(x, y);
        buildIntersectedPath(secFrom, locPointer);
    }

    // var splittingLine = {a: .0, b: .0, c: .0};
    // inline function lineFromPoints(x1:Float, y1:Float, x2:Float, y2:Float) {
    //     var a = y1 - y2;
    //     var b = x2 - x1;
    //     var c = -a * x1 - b * y1;
    //     splittingLine.a = a;
    //     splittingLine.b = b;
    //     splittingLine.c = c;
    // }
    // inline function getDistance(x:Float, y:Float) {
    //     var l = splittingLine;
    //     var d = (x * l.a + y * l.b + l.c);
    //     return d;
    // }
    var f = false;
    var pathOrig:Array<Vec2D> = [];
    var pathSplitted:Array<Vec2D> = [];

    var indices = new IndexCollection(12);

    public inline function getIndices():IndexCollection {
        return indices;
    }

    function updateShape() {
        if (f)
            return;
        f = true;

        pathOrig.push(new Vec2D(0, 0));
        pathOrig.push(new Vec2D(1, 0));
        pathOrig.push(new Vec2D(1, 1));
        pathOrig.push(new Vec2D(0.001, 0.9999));
        // pathOrig.push(new Vec2D(0.0, 1.0));

        var ep = [];
        for (p in pathOrig) {
            ep.push(p.x);
            ep.push(p.y);
        }
        var inds = Earcut.earcut(ep);
        trace(inds);
        // for (i in 0...inds.length)
        //     indices[i] = inds[i];
    }

    var lastIntersection = new Vec2D();

    function getLineIntersection(a1:Vec2DRO, a2:Vec2DRO, b1:Vec2DRO, b2:Vec2DRO) {
        return MathUtil.get_line_intersection(a1.x, a1.y, a2.x, a2.y, b1.x, b1.y, b2.x, b2.y, lastIntersection, false);
    }

    function buildIntersectedPath(secator1:Vec2D, secator2:Vec2D) {
        var afterVert = [];
        var intersections = [];
        secator1.init(1.1, 0.5);
        secator2.remove(secator1);
        secator2.normalize(2);
        secator2.add(secator1);
        secator2.y = 1 - secator2.y;
        for (i in 1...pathOrig.length) {
            var p1 = pathOrig[i - 1];
            var p2 = pathOrig[i];
            if (getLineIntersection(p1, p2, secator1, secator2)) {
                afterVert.push(i - 1);
                intersections.push(lastIntersection.clone());
            }
        }
        var p1 = pathOrig[pathOrig.length - 1];
        var p2 = pathOrig[0];
        if (getLineIntersection(p1, p2, secator1, secator2)) {
            afterVert.push(pathOrig.length - 1);
            intersections.push(lastIntersection.clone());
        }
        var newPath = [];
        var oinds = [];
        // trace (afterVert);
        // trace(intersections);
        if (intersections.length < 1)
            return;
        for (i in 0...afterVert[0] + 1)
            newPath.push(pathOrig[i]);
        newPath.push(intersections[0]);
        newPath.push(intersections[1]);
        for (i in afterVert[1] + 1...pathOrig.length)
            newPath.push(pathOrig[i]);
        // newPath.push(pathOrig[0]);

        canvas.render(newPath);

        trace(newPath);

        pathSplitted = newPath;
        var ep = [];
        for (p in pathSplitted) {
            ep.push(p.x);
            ep.push(p.y);
        }
        var inds = Earcut.earcut(ep);
        canvas.setText("" + inds + "\n " + pathSplitted);

        for (i in 0...inds.length)
            indices[i] = inds[i];
    }

    public function writePostions(target:Bytes, vertOffset = 0, transformer) {
        var i = 0;
        function writePoint(x, y) {
            trace("writing ", x, y);
            writers[horizontal].setValue(target, vertOffset + i, transformer(horizontal, x));
            writers[vertical].setValue(target, vertOffset + i, transformer(vertical, y));
            uvWriters[horizontal].setValue(target, vertOffset + i, x);
            uvWriters[vertical].setValue(target, vertOffset + i, y);
            i++;
        }
        // var inds = [3, 4, 0];
        // // var inds = [3, 4, 0, 0, 1, 2, 2, 3, 0];
        // for (i in 0...inds.length)
        //     indices[i] = inds[i];
        // var pathSplitted = [
        //     [0., 0],
        //     [1., 0],
        //     [1., 0.575221872316061],
        //     [0.435374850993543, 0.999943480966065],
        //     [0.001, 0.9999]
        // ];
        // for (p in pathSplitted)
        //     writePoint(p[0], 1 - p[1]);
        for (p in pathSplitted)
            writePoint(p.x, 1 - p.y);
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
        // handler(Mathu.clamp(v, 0, 1));
        trace(Mathu.clamp(x, 0, 1), Mathu.clamp(y, 0, 1));
        handler(Mathu.clamp(x, 0, 1), Mathu.clamp(y, 0, 1));
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

class FigureRender2 extends Sprite {
    var tf = new TextField();

    public function new() {
        super();
        addChild(tf);
        tf.multiline = true;
        tf.width = 600;
    }

    public function setText(t) {
        tf.text = t;
    }

    // var canvas:Sprite;
    // var model:PolySplittingModel;
    // public function new(canvas:Sprite, model) {
    //     this.canvas = canvas;
    //     this.model = model;
    //     model.onFigureSplitted.listen(render);
    // }
    public function render(figures:Array<Vec2D>) {
        var s = 300;
        graphics.clear();
        var path = figures;
        // for (fi in 0...figures.length) {
        //     var path = figures[fi];
        graphics.lineStyle(1, 0xffffff);
        graphics.moveTo(100 + s * path[0].x, 100 + s * path[0].y);
        for (i in 1...path.length)
            graphics.lineTo(100 + s * path[i].x, 100 + s * path[i].y);
        graphics.lineTo(100 + s * path[0].x, 100 + s * path[0].y);
        // }
    }
}

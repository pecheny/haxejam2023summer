package j2023;

import utils.MathUtil;
import ec.Signal;
import ginp.DefaultInput.OneButton;
import states.States;
import utils.Data;
import openfl.display.Sprite;
import update.Updatable;

interface PolySplittingModel {
    public var figures:Array<Array<Vec2D>>;
    public var activeFigure:Int;
    public var onFigureSplitted:Signal<Void->Void>;
}

class PolyLineSystem implements Updatable extends StateMachine implements PolySplittingModel {
    public var figures:Array<Array<Vec2D>> = [];
    public var activeFigure:Int;
    public var onFigureSplitted:Signal<Void->Void> = new Signal();

    var input:J23Input;

    public var canvas:Sprite;

    var path:Array<Vec2D> = [];
    var pointer:Vec2DRO;
    var last = new Vec2D();

    public function new(canvas:Sprite, inp, pointer) {
        super();

        verbose = true;
        this.input = inp;
        this.canvas = canvas;
        this.pointer = pointer;
        addState(new IdleState(this));
        addState(new DrawingState(this));
        addState(new SplittingState(this));
        changeState(IdleState);
    }

    override public function update(dt:Float) {
        super.update(dt);
        if (last.distance(pointer) > 15)
            last.copyFrom(pointer);
    }

    function figUnder() {
        for (i in 0...figures.length) {
            var poly = figures[i];
            if (MathUtil.pnpoly(poly, pointer)) {
                return i;
            }
        }
        return -1;
    }

    function addFigure() {
        var figure = path.slice(intersectedIdx);
        figure.push(lastIntersection.clone());
        figures.push(figure);
    }

    function checkPath() {
        var last = path[path.length - 1];
        for (i in 1...path.length - 1)
            if (getLineIntersection(last, pointer, path[i - 1], path[i])) {
                intersectedIdx = i;
                return true;
            }
        return false;
    }

    function checkFigure(p1:Vec2DRO, p2:Vec2DRO) {
        if (activeFigure < 0)
            return false;
        var path = figures[activeFigure];
        // var last = this.path[path.length - 1];
        for (i in 1...path.length)
            if (getLineIntersection(p1, p2, path[i - 1], path[i])) {
                intersectedIdx = i;
                return true;
            }
        return false;
    }

    function getLineIntersection(a1:Vec2DRO, a2:Vec2DRO, b1:Vec2DRO, b2:Vec2DRO) {
        return MathUtil.get_line_intersection(a1.x, a1.y, a2.x, a2.y, b1.x, b1.y, b2.x, b2.y, lastIntersection);
    }

    var lastIntersection = new Vec2D();
    var intersectedIdx = -1;

   
}

@:access(j2023.PolyLineSystem)
class IdleState extends State {
    var fsm:PolyLineSystem;

    public function new(fsm) {
        this.fsm = fsm;
    }

    var leaving = false;

    override function onEnter() {
        var figUnder = fsm.figUnder();
        leaving = (figUnder > -1);

        trace("Leaving " + leaving);
    }

    override function update(t:Float) {
        var figUnder = fsm.figUnder();
        if (leaving) {
            if (figUnder < 0)
                leaving = false;
            return;
            // /todo update fsm.last
        }
        if (fsm.input.pressed(OneButton.button))
            fsm.changeState(DrawingState);

        if (figUnder > -1) {
            fsm.activeFigure = figUnder;
            fsm.changeState(SplittingState);
        }
    }
}

@:access(j2023.PolyLineSystem)
class SplittingState extends State {
    // var path:Array<Vec2D> = [];
    var fsm:PolyLineSystem;

    public function new(fsm) {
        this.fsm = fsm;
    }

    var firstSplitIdx = -1;

    override function onEnter() {
        if (!fsm.checkFigure(fsm.last, fsm.pointer)) {
            trace(fsm.last + " " + MathUtil.pnpoly(fsm.figures[fsm.activeFigure], fsm.last));
            trace(fsm.pointer + " " + MathUtil.pnpoly(fsm.figures[fsm.activeFigure], fsm.pointer));
            trace("wrong");
        }
        // throw "Wrong!";

        firstSplitIdx = fsm.intersectedIdx;
        fsm.canvas.graphics.clear();
        fsm.path.resize(0);
        fsm.path.push(fsm.lastIntersection.clone());
        fsm.canvas.graphics.lineStyle(2, 0);
        fsm.canvas.graphics.moveTo(fsm.path[0].x, fsm.path[0].y);
    }

    override function update(t:Float) {
        var path = fsm.path;
        var last = path[path.length - 1];
        // if pointer outside and path < 2 - cancel
        if (!MathUtil.pnpoly(fsm.figures[fsm.activeFigure], fsm.pointer)) {
            if (path.length < 2)
                fsm.changeState(IdleState);
            // cancel
            else if (fsm.checkFigure(last, fsm.pointer)) {
                trace("found new intersection, trying to split " + fsm.path);
                fsm.path.push(fsm.lastIntersection.clone());
                splitFigure();
                path.resize(0);
                fsm.changeState(IdleState);
                fsm.onFigureSplitted.dispatch();
            } else
                throw "wrong;";
        }
        if (last.distance(fsm.pointer) < 15)
            return;
        // todo !1111
        if (fsm.checkPath()) {
            trace("path intersection - > new fig");
            fsm.addFigure();
            path.resize(0);
            fsm.changeState(IdleState);
            fsm.onFigureSplitted.dispatch();
        } else {
            fsm.path.push(fsm.pointer.clone());
            fsm.canvas.graphics.lineTo(fsm.pointer.x, fsm.pointer.y);
        }
    }

    override function onExit() {
        fsm.canvas.graphics.clear();
    }

    function splitFigure() {
        var fig = fsm.figures[fsm.activeFigure];
        fsm.figures.remove(fig);

        var path = fsm.path;
        function writePath(trg)
            for (i in 0...path.length)
                trg.push(path[i].clone());

        function writePathRev(trg) {
            var i = path.length - 1;
            while (i >= 0) {
                trg.push(path[i].clone());
                i--;
            }
        }

        function combineFigureAlongWithPath(firstSplitIdx, secondSplitIdx) {
            var sameSeg = firstSplitIdx == secondSplitIdx;
            var reversePath = false;
            if (sameSeg) {
                var endOfOrigFigPart1 = fig[firstSplitIdx - 1];
                reversePath = path[0].distance(endOfOrigFigPart1) > path[path.length - 1].distance(endOfOrigFigPart1);
            } else {
                if (firstSplitIdx > secondSplitIdx) {
                    reversePath = true;
                    var t = firstSplitIdx;
                    firstSplitIdx = secondSplitIdx;
                    secondSplitIdx = t;
                }
            }
            var newfig1 = [];
            for (i in 0...firstSplitIdx - 1)
                newfig1.push(fig[i]);

            if (reversePath)
                writePathRev(newfig1);
            else
                writePath(newfig1);

            for (i in secondSplitIdx...fig.length)
                newfig1.push(fig[i]);

            fsm.figures.push(newfig1);

            var newfig2 = [];
            if (!reversePath)
                writePathRev(newfig2);
            else
                writePath(newfig2);
            for (i in firstSplitIdx...secondSplitIdx-1)
                newfig2.push(fig[i]);

            fsm.figures.push(newfig2);
        }

        combineFigureAlongWithPath(firstSplitIdx, fsm.intersectedIdx);
    }
}

@:access(j2023.PolyLineSystem)
class DrawingState extends State {
    // var path:Array<Vec2D> = [];
    var fsm:PolyLineSystem;

    public function new(fsm) {
        this.fsm = fsm;
    }

    override function onEnter() {
        fsm.canvas.graphics.clear();
        fsm.path.resize(0);
        fsm.path.push(fsm.pointer.clone());
        fsm.canvas.graphics.lineStyle(2, 0);
        fsm.canvas.graphics.moveTo(fsm.pointer.x, fsm.pointer.y);
    }

    override function update(t:Float) {
        // if (!fsm.input.pressed(OneButton.button)) {
        //     fsm.changeState(IdleState);
        //     return;
        // }

        var path = fsm.path;
        var last = path[path.length - 1];
        if (last.distance(fsm.pointer) < 15)
            return;
        if (fsm.checkPath()) {
            fsm.addFigure();
            fsm.changeState(IdleState);
            fsm.onFigureSplitted.dispatch();
        } else {
            fsm.path.push(fsm.pointer.clone());
            fsm.canvas.graphics.lineTo(fsm.pointer.x, fsm.pointer.y);
        }
    }
    override function onExit() {
        fsm.canvas.graphics.clear();
    }
}

class FigureRender {
    var canvas:Sprite;
    var model:PolySplittingModel;

    public function new(canvas:Sprite, model) {
        this.canvas = canvas;
        this.model = model;
        model.onFigureSplitted.listen(render);
    }

    function render() {
        canvas.graphics.clear();
        for (fi in 0...model.figures.length) {
            var path = model.figures[fi];
            canvas.graphics.lineStyle(1, Std.int(Math.random() * 0xffffff));
            canvas.graphics.moveTo(path[0].x, path[0].y);
            for (i in 1...path.length)
                canvas.graphics.lineTo(path[i].x, path[i].y);
            canvas.graphics.lineTo(path[0].x, path[0].y);
        }
    }
}

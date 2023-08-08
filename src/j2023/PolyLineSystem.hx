package j2023;

import ginp.DefaultInput.OneButton;
import states.States;
import utils.Data.Vec2D;
import openfl.display.Sprite;
import update.Updatable;

class PolyLineSystem implements Updatable extends StateMachine{
    var input:J23Input;
    public var canvas:Sprite;
    var path:Array<Vec2D> = [];
    var pointer:Vec2D;

    public function new(canvas:Sprite, inp, pointer) {
        super();
        this.input = inp;
        this.canvas = canvas;
        this.pointer = pointer;
        addState(new IdleState(this));
        addState(new DrawingState(this));
        changeState(IdleState);
    }

    // override public function update(dt:Float) {}
}

@:access(j2023.PolyLineSystem)
class IdleState extends State {
    var fsm:PolyLineSystem;
    public function new(fsm) {
        this.fsm = fsm;
    }
    override function update(t:Float) {
        if (fsm.input.pressed(OneButton.button))
            fsm.changeState(DrawingState);
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
        // cur.init(fsm.canvas.mouseX, fsm.canvas.mouseY);
        cur.copyFrom(fsm.pointer);
        fsm.path.push(cur.clone());
        fsm.canvas.graphics.lineStyle(2, 0);
        fsm.canvas.graphics.moveTo(cur.x, cur.y);
    }

    var cur = new Vec2D(0, 0);

    override function update(t:Float) {
        if (!fsm.input.pressed(OneButton.button)) {
            fsm.changeState(IdleState);
            return;
        }

        var path = fsm.path;
        var last = path[path.length - 1];
        // cur.init(fsm.canvas.mouseX, fsm.canvas.mouseY);
        cur.copyFrom(fsm.pointer);
        if (last.distance(cur) < 15)
            return;
        path.push(cur.clone());
        fsm.canvas.graphics.lineTo(cur.x, cur.y);
    }
}

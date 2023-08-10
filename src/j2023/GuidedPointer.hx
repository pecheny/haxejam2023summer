package j2023;

import haxe.Timer;
import openfl.Lib;
import openfl.display.Sprite;
import utils.Data.Vec2D;
import update.Updatable;

class GuidedPointer implements Updatable {
    public var guide:Vec2D = new Vec2D(0, 0);
    public var guidePrev:Vec2D = new Vec2D(0, 0);
    public var pointer:Vec2D = new Vec2D(0, 0);
    public var direction:Vec2D = new Vec2D(0, 0);
    public var pointerDirection:Vec2D = new Vec2D(0, 0); // = dL
    public var targetDirection:Vec2D = new Vec2D(0, 0);

    var rend : GuidedPointerRender;
    public function new() {
        var spr = new Sprite();
        Lib.current.addChild(spr);
        rend = new GuidedPointerRender(this, spr);
    }

    public function update(dt:Float) {
        guidePrev.copyFrom(guide);
        var st = Lib.current.stage;
        guide.init(st.mouseX, st.mouseY);
        var path = guidePrev.distance(guide);
        targetDirection.copyFrom(guide);
        targetDirection.remove(guidePrev);
        targetDirection.normalize(1);
        var time = path / spd;
        var dt = 1 / 30;
        while (time > 0) {
            time -= dt;
            movePointer(dt);
        }
        rend.update(dt);
    }

    var spd = 10;
    var cordLength = 100;

    inline function movePointer(dt:Float) {
        if (guide.distance(pointer) < cordLength) {
            rotateTowardTarget(dt);
            // rotTow
        } else {
            rotateTowardTarget(dt);
            pointer.add(pointerDirection);
        }
        pointerDirection.normalize(10);
    }

    function rotateTowardTarget(dt:Float) {
        pointerDirection.copyFrom(guide);
        pointerDirection.remove(pointer);
        pointerDirection.normalize(spd * dt);
    }
}

class GuidedPointerRender implements Updatable {
    var canvas:Sprite;
    var model:GuidedPointer;

    public function new(model, canvas) {
        this.canvas = canvas;
        this.model = model;
    }

    var dirmark = new Vec2D(0,0);
    public function update(dt:Float) {
        canvas.graphics.clear();
        mark(model.guide, 0xff0000, true);
        mark(model.pointer, 0x000000, true);
        dirmark.copyFrom(model.pointer);
        dirmark.add(model.pointerDirection);
        mark(dirmark, 0xff0000, true);
    }

    function mark(pos:Vec2D, c, isRect) {
        canvas.graphics.beginFill(c);
        var w = 4;
        if (isRect)
            canvas.graphics.drawRect(pos.x - w / 2, pos.y - w / 2, w, w);
        else
            canvas.graphics.drawCircle(pos.x, pos.y, 5);
        canvas.graphics.endFill();
    }
}

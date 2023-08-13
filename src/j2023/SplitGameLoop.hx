package j2023;

import j2023.Main.SplitGameState;
import states.States;
import utils.MathUtil;
import j2023.SplittingWidget.CircleWidget;

class SplitGameLoop extends StateMachine {
    public var statusGui:StatusWidget;
    public var c1:CircleWidget;
    public var c2:CircleWidget;
    public var c1r:CircleWidget;
    public var c2r:CircleWidget;
    public var splitter:SplittingWidget;
    public var currentRatio:Float;
    public var health(default, set):Float;
    public var score:Int;

    // public var reverseParts
    public function new() {
        super();
        addState(new SplittingGameState(this));
        addState(new ResultPresentation(this));
        init();
    }

    public function init() {
        health = 100;
        score = 0;
    }

    public function gameOver() {
        init();
    }

    public function setUserRatio(ratio:Float) {
        c1r.setAreaCoef(ratio);
        c2r.setAreaCoef(1 - ratio);
    }

    function set_health(value:Float):Float {
        this.health = value;
        if (statusGui != null)
            statusGui.setHealth(value / 100);
        return value;
    }

    public function fade(a:Float) {
        var usrAlpha = Std.int(a * 255);
        var splitterAlpha = Std.int((1-a) * 255);
        c1r.setAlpha(usrAlpha);
        c1r.setOffset(1-a);
        c2r.setAlpha(usrAlpha);
        c2r.setOffset(1-a);
        splitter.setAlpha(splitterAlpha);
        
    }
}

class SplitStateBase extends State {
    var t:Float;
    var duration = 1.;
    var fsm:SplitGameLoop;

    public function new(fsm) {
        this.fsm = fsm;
    }
}

class SplittingGameState extends SplitStateBase {
    override function onEnter() {
        t = duration;
        fsm.fade(0);
        fsm.currentRatio = Math.random() * 0.9 + 0.05;
        fsm.c1.setAreaCoef(fsm.currentRatio);
        fsm.c2.setAreaCoef(1 - fsm.currentRatio);
        // generate challange
        // animate challange discovery
    }

    override function update(dt:Float) {
        t -= dt;
        fsm.statusGui.setProgress(t / duration);
        if (t <= 0) {
            var userRatio = fsm.splitter.getRatio();
            // if ((userRatio - 0.5)*(userRatio - 0.5) <0) {
            //     ///todo verify!11111111111111111111111111111111111111111111111111
            // }

            fsm.setUserRatio(userRatio);
            var error:Float = Math.abs(userRatio - fsm.currentRatio) * 10;
            var deltaHealth = if (error < 0.1) 10 else -error * 10;
            fsm.health = MathUtil.clamp(fsm.health + deltaHealth, 0, 100);

            if (fsm.health == 0)
                fsm.gameOver();
            else
                fsm.changeState(ResultPresentation);
        }

        // upd timer
        // animate splitter
        // check timer and results
        // check health
    }
}

class ResultPresentation extends SplitStateBase {
    override function onEnter() {
        t = duration;
        fsm.score++;
    }

    override function update(dt:Float) {
        t -= dt;
        var tp = (t/duration);
        fsm.fade(1-tp*tp);
        // fsm.statusGui.setProgress(t / duration);
        if (t <= 0)
            fsm.changeState(SplittingGameState);
    }
}

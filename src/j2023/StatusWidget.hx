package j2023;

import widgets.Label;
import al.core.Align;
import graphics.ShapesColorAssigner;
import al.Builder;
import widgets.ShapeWidget;
import gl.sets.ColorSet;
import graphics.shapes.ProgressBar;
import al.ec.WidgetSwitcher;
import widgets.Widget;

using al.Builder;
using transform.LiquidTransformer;
using widgets.utils.Utils;

class StatusWidget extends Widget {
    var pbw:ProgressBarWidget;
    var healthRed:ProgressBarWidget;
    var healthbar:ProgressBarWidget;
    // var model:SplitGameLoop;
    var switcher:WidgetSwitcher<Axis2D>;
    var label:Label;
    var score:Label;

    public function new(w, ar, fui:FuiBuilder) {
        super(w);
        // this.model = m;
        var sww = Builder.widget();
        switcher = new WidgetSwitcher(sww);

        label = new Label(Builder.widget(), fui.s("center"));
        label.withText("foo");
        score = new Label(Builder.widget(), fui.s("fit"));
        pbw = new ProgressBarWidget(Builder.widget().withLiquidTransform(ar));
        var hbw =Builder.widget().withLiquidTransform(ar);
        healthRed = new ProgressBarWidget(hbw, 0xff0000);
        healthbar = new ProgressBarWidget(hbw);

        pbw.setPtogress(0.75);
        Builder.createContainer(w, vertical, Align.Center).withChildren([score.widget(), sww, healthbar.widget()]);
    }

    public function setProgress(v:Float) {
        if (v == 1) {
            switcher.switchTo(pbw.widget());
            healthRed.setPtogress(health);
            healthbar.setPtogress(health);
        }

        pbw.setPtogress(v);
    }

    var health:Float;

    public function setHealth(v:Float, error:Float) {
        label.withText('Misfit ${Std.int(error * 100)}%, health : ${Std.int(v * 100)}');
        health = v;
        switcher.switchTo(label.widget());
        healthbar.setPtogress(v);
    }
    public function setScore(v:Int) {
        score.withText('Score: $v');
    }
}

class ProgressBarWidget extends ShapeWidget<ColorSet> {
    var pb = new ProgressBar(ColorSet.instance);

    public function new(w, color=0xffffff) {
        super(ColorSet.instance, w);
        addChild(pb);
        var colors = new ShapesColorAssigner(ColorSet.instance, color, getBuffer());
    }

    public function setPtogress(v) {
        pb.setVal(horizontal, v);
        pb.setVal(vertical, 1);
    }
}

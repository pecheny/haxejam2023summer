package j2023;

import graphics.ShapesColorAssigner;
import al.Builder;
import widgets.ShapeWidget;
import gl.sets.ColorSet;
import graphics.shapes.ProgressBar;
import al.ec.WidgetSwitcher;
import widgets.Widget;

class StatusWidget extends Widget {
    var pbw : ProgressBarWidget;
    // var model:SplitGameLoop;
    var switcher:WidgetSwitcher<Axis2D>;

    public function new(w) {
        super(w);
        // this.model = m;
        switcher = new WidgetSwitcher(w);
        pbw = new ProgressBarWidget(Builder.widget());
        switcher.switchTo(pbw.widget());
        pbw.setPtogress(0.75);
    }

    public function setProgress(v) {
        pbw.setPtogress(v);
    }
}

class ProgressBarWidget extends ShapeWidget<ColorSet> {
    var pb = new ProgressBar(ColorSet.instance);

    public function new(w) {
        super(ColorSet.instance, w);
        addChild(pb);
        var colors = new ShapesColorAssigner(ColorSet.instance, 0xffffff, getBuffer());
    }

    public function setPtogress(v) {
        pb.setVal(horizontal, v);
        pb.setVal(vertical, 0.5);
    }
}

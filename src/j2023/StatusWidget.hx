package j2023;

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
    var pbw : ProgressBarWidget;
    var healthbar : ProgressBarWidget;
    // var model:SplitGameLoop;
    var switcher:WidgetSwitcher<Axis2D>;

    public function new(w, ar) {
        super(w);
        // this.model = m;
        // var sww = Builder.widget();
        // switcher = new WidgetSwitcher(sww);

        pbw = new ProgressBarWidget(Builder.widget().withLiquidTransform(ar));
        healthbar = new ProgressBarWidget(Builder.widget().withLiquidTransform(ar));
        
        // switcher.switchTo(pbw.widget());
        pbw.setPtogress(0.75);
        Builder.createContainer(w, vertical, Align.Center).withChildren([
            pbw.widget(),
             Builder.widget(),
             healthbar.widget()
            ]);
    }

    public function setProgress(v) {
        pbw.setPtogress(v);
    }

    public function setHealth(v) {
        healthbar.setPtogress(v);
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
        pb.setVal(vertical, 1);
    }
}

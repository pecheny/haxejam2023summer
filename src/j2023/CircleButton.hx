package j2023;

import widgets.Label;
import widgets.ButtonBase;

class CircleButton extends ButtonBase{
    
    public function new(w, h, text, style,fui) {
        super(w, h);
        // ColouredQuad.flatClolorQuad(w);
        var cw = new CircleWidget(fui, w, 0x404040);
        new Label(w, style).withText(text);
    }
}
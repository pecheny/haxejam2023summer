package j2023;

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
    public function new(fuiBuilder:FuiBuilder, w:Placeholder2D, filename, createGldo = true) {
        var attrs = TexSet.instance;
        super(attrs, w);
        // var shw = new ShapeWidget(attrs, w);
        addChild(new QuadGraphicElement(attrs));
        var uvs = new graphics.DynamicAttributeAssigner(attrs, getBuffer());
        uvs.fillBuffer = (attrs:TexSet, buffer) -> {
            var writer = attrs.getWriter(AttribAliases.NAME_UV_0);
            QuadGraphicElement.writeQuadPostions(buffer.getBuffer(), writer, 0, (a, wg) -> wg);
        };
        if (createGldo) {
            fuiBuilder.createContainer(w.entity, Xml.parse('<container><drawcall type="image" path="Assets/$filename" /></container>').firstElement());
            var spr:Sprite = w.entity.getComponent(Sprite);
            Lib.current.addChild(spr);
        }

        // var bm = Assets.getBitmapData("Assets/" + filename);
        // Lib.current.addChild(new Bitmap(bm));
        // trace(bm.histogram());
    }
}

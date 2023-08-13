package j2023;

import update.RealtimeUpdater;
import gl.aspects.TextureBinder;
import shaderbuilder.TextureFragment;
import shaderbuilder.SnaderBuilder;
import ColorTexSet;
import Axis2D;
import al.al2d.Placeholder2D;
import al.core.Align;
import al.ec.WidgetSwitcher;
import al.openfl.display.DrawcallDataProvider;
import al.openfl.display.FlashDisplayRoot;
import ec.CtxWatcher;
import ec.Entity;
import j2023.SplitGameLoop;
import j2023.SplittingWidget;
import openfl.display.Sprite;
import states.States;
import ui.GameplayUIMock;
import update.FixedUpdater;
import utils.AbstractEngine;
import widgets.Button;

using al.Builder;
using transform.LiquidTransformer;
using widgets.utils.Utils;

class Main extends AbstractEngine {
    var fui = new FuiBuilder();
    var rootEntity:Entity;
    var stateSwitcher:StateSwitcher;

    public function new() {
        super();
        // addChild(new FPS());
        var wnd = openfl.Lib.application.window;
        if (wnd.y < 0)
            wnd.y = 20;
        wnd.x = 800;
        renderingStuff();
        var drawcallsLayout = '<container>
        <drawcall type="color"/>
        <drawcall type="circles" path="Assets/c-256.png" />
        <drawcall type="text" font=""/>
        </container>';
        rootEntity = fui.createDefaultRoot(drawcallsLayout);
        var flashCanvas = new Sprite();
        addChild(flashCanvas);
        rootEntity.addComponent(new FlashDisplayRoot(flashCanvas));

        var container:Sprite = rootEntity.getComponent(Sprite);
        addChild(container);

        var machine = new StateMachine();
        rootEntity.addComponent(machine);
        machine.addState(new MetaGameState(Builder.widget(), rootEntity));
        machine.addState(new GameOverState(Builder.widget(), rootEntity));
        machine.addState(new SplitGameState(Builder.widget(), rootEntity));
        machine.changeState(MetaGameState);
        addUpdatable(machine);
    }

    function renderingStuff() {
        fui.regDrawcallType("circles", {
            type: "circles",
            attrs: ColorTexSet.instance,
            vert: [Uv0Passthrough.instance, PosPassthrough.instance, ColorPassthroughVert.instance],
            frag: [ColorTextureFragment.instance],
        }, (e, xml) -> {
            if (!xml.exists("path"))
                throw '<image /> gldo should have path property';
            // todo image name to gldo
            return fui.createGldo(ColorTexSet.instance, e, "circles", new TextureBinder(fui.textureStorage, xml.get("path")), "");
        });
    }
}

class GameOverState extends StateBase {
    public function new(w:Placeholder2D, root:Entity) {
        super(w,root);

        var fui = root.getComponentUpward(FuiBuilder);
        var b = fui.placeholderBuilder;
        root.getComponent(FuiBuilder).makeClickInput(w);

        var shViewSz = 0.33;


        var stw = b.h(pfr, 1).v(sfr, 0.2).b().withLiquidTransform(fui.ar.getAspectRatio());

        var splWdg = b.h(sfr, shViewSz)
        .v(sfr, shViewSz)
        .b()
        .withLiquidTransform(fui.ar.getAspectRatio());

        var bg = new CircleButton(splWdg,startGame, "go!", fui.s("fit") , fui);
        // bg.setColor();


        var refCrcles = Builder.createContainer(b.v(sfr, shViewSz).b(), horizontal, Align.Center).withChildren([]);

        var splittingCrcle = Builder.createContainer(b.v(sfr, shViewSz).b(), horizontal, Align.Center).withChildren([splWdg]);
        Builder.createContainer(w, vertical, Align.Center).withChildren([stw, refCrcles, splittingCrcle]);

    }


    function welcomeScreen(w) {
        var fui = root.getComponentUpward(FuiBuilder);
        var b = fui.placeholderBuilder;
        var pnl = Builder.createContainer(w, vertical, Align.Center).withChildren([
            new Button(b.h(sfr, 1).v(px, 60).b().withLiquidTransform(fui.ar.getAspectRatio()), startGame, "Button caption", fui.s("fit")).widget(),
        ]);
        fui.makeClickInput(pnl);
        return pnl;
    }

    function startGame() {
        // () -> rootEntity.getComponent(WidgetSwitcher).switchTo(null)
        root.getComponentUpward(StateMachine).changeState(SplitGameState);
    }

    function sty(name) {
        var fui = root.getComponentUpward(FuiBuilder);
        return fui.textStyles.getStyle(name);
    }
}
class MetaGameState extends StateBase {
    public function new(w:Placeholder2D, root:Entity) {
        super(w,root);

        var fui = root.getComponentUpward(FuiBuilder);
        var b = fui.placeholderBuilder;
        root.getComponent(FuiBuilder).makeClickInput(w);

        var shViewSz = 0.33;


        var stw = b.h(pfr, 1).v(sfr, 0.2).b().withLiquidTransform(fui.ar.getAspectRatio());

        var splWdg = b.h(sfr, shViewSz)
        .v(sfr, shViewSz)
        .b()
        .withLiquidTransform(fui.ar.getAspectRatio());

        var bg = new CircleButton(splWdg,startGame, "go!", fui.s("fit") , fui);
        // bg.setColor();


        var refCrcles = Builder.createContainer(b.v(sfr, shViewSz).b(), horizontal, Align.Center).withChildren([]);

        var splittingCrcle = Builder.createContainer(b.v(sfr, shViewSz).b(), horizontal, Align.Center).withChildren([splWdg]);
        Builder.createContainer(w, vertical, Align.Center).withChildren([stw, refCrcles, splittingCrcle]);

    }


    function welcomeScreen(w) {
        var fui = root.getComponentUpward(FuiBuilder);
        var b = fui.placeholderBuilder;
        var pnl = Builder.createContainer(w, vertical, Align.Center).withChildren([
            new Button(b.h(sfr, 1).v(px, 60).b().withLiquidTransform(fui.ar.getAspectRatio()), startGame, "Button caption", fui.s("fit")).widget(),
        ]);
        fui.makeClickInput(pnl);
        return pnl;
    }

    function startGame() {
        // () -> rootEntity.getComponent(WidgetSwitcher).switchTo(null)
        root.getComponentUpward(StateMachine).changeState(SplitGameState);
    }

    function sty(name) {
        var fui = root.getComponentUpward(FuiBuilder);
        return fui.textStyles.getStyle(name);
    }
}


class SplitGameState extends StateBase implements ui.GameplayUIMock.GameMock {
    var input:J23Input;
    var switcher:WidgetSwitcher<Axis2D>;
    var gpScreen:Placeholder2D;
    var pauseScreen:Placeholder2D;
    var game:RealtimeUpdater;
    var loop:SplitGameLoop;
    var _pause = false;

    public function new(w:Placeholder2D, root:Entity) {
        super(w,root);

        var fui = root.getComponentUpward(FuiBuilder);
        var b = fui.placeholderBuilder;
        this.game = new RealtimeUpdater();
        switcher = new WidgetSwitcher(w);
        root.getComponent(FuiBuilder).makeClickInput(w);
        input = new J23Input();
        initScreens();

        var shViewSz = 0.33;

        loop = new SplitGameLoop();
        game.addUpdatable(loop);

        var stw = b.h(pfr, 1).v(sfr, 0.2).b().withLiquidTransform(fui.ar.getAspectRatio());
        loop.statusGui = new StatusWidget(stw,fui.ar.getAspectRatio());
        var fsm =root.getComponentUpward(StateMachine);
        loop.metaGame = fsm;

        var refColor = 0x3090ff;
        var usrColor = 0xf51340;
        var lw = b.h(sfr, shViewSz)
            .v(sfr, shViewSz)
            .b()
            .withLiquidTransform(fui.ar.getAspectRatio());
        loop.c1 = new CircleWidget(fui, lw, 0xd54a04);
        loop.c1.setAreaCoef(1);
        loop.c1r = new CircleWidget(fui, lw, usrColor);

        var rw = b.h(sfr, shViewSz)
            .v(sfr, shViewSz)
            .b()
            .withLiquidTransform(fui.ar.getAspectRatio());
        loop.c2 = new CircleWidget(fui, rw, refColor);
        loop.c2r = new CircleWidget(fui, rw, usrColor);

        var splWdg = b.h(sfr, shViewSz)
        .v(sfr, shViewSz)
        .b()
        .withLiquidTransform(fui.ar.getAspectRatio());

        var bg = new CircleWidget(fui, splWdg, 0x404040);
        bg.setAreaCoef(1);
        loop.splitter = new SplittingWidget(fui, splWdg, "c-256.png");


        var refCrcles = Builder.createContainer(b.v(sfr, shViewSz).b(), horizontal, Align.Center).withChildren([lw, rw]);

        var splittingCrcle = Builder.createContainer(b.v(sfr, shViewSz).b(), horizontal, Align.Center).withChildren([loop.splitter.widget()]);

        Builder.createContainer(gpScreen, vertical, Align.Center).withChildren([stw, refCrcles, splittingCrcle]);

    }

    function initScreens() {
        gpScreen = Builder.widget(); //new GameplayScreen(, root, this).widget();
        pauseScreen = new GameplayPauseScreen(Builder.widget(), root, this).widget();
    }

    override function update(t:Float) {
        if(_pause)
            return;
        input.beforeUpdate(t);
        game.update();
        input.afterUpdate();
    }

    function spriteAdapter(w:Placeholder2D, spr:Sprite) {
        var dp = DrawcallDataProvider.get(w.entity);
        new CtxWatcher(FlashDisplayRoot, w.entity);
        dp.views.push(spr);
    }

    public function pause(v) {
        _pause = v;
        if (v)
            switcher.switchTo(pauseScreen);
        else
            switcher.switchTo(gpScreen);
    }

    override function onEnter() {
        super.onEnter();
        switcher.switchTo(gpScreen);
        loop.init();
        loop.changeState(SplittingGameState);
    }

}

class StateBase extends State {

    var w:Placeholder2D;
    var root:Entity;
    public function new(w:Placeholder2D, root:Entity) {
        this.w = w;
        this.root = root;
    }

    override function onExit() {
        super.onExit();
        var sw = root.getComponentUpward(WidgetSwitcher);
        if (sw == null)
            throw 'WThere is no WigetSwitcher';
        sw.switchTo(null);
    }

    override function onEnter() {
        var sw = root.getComponentUpward(WidgetSwitcher);
        if (sw == null)
            throw 'WThere is no WigetSwitcher';
        sw.switchTo(w);
    }
}
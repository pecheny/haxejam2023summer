package j2023;

import j2023.PolyLineSystem.FigureRender;
import openfl.Lib;
import openfl.display.FPS;
import update.Updater;
import Axis2D;
import FuiBuilder.XmlLayerLayouts;
import a2d.Boundbox;
import al.al2d.Placeholder2D;
import al.core.Align;
import al.ec.WidgetSwitcher;
import al.openfl.display.DrawcallDataProvider;
import al.openfl.display.FlashDisplayRoot;
import ec.CtxWatcher;
import ec.Entity;
import openfl.SpriteAspectKeeper;
import openfl.display.Sprite;
import states.States;
import ui.GameplayUIMock;
import update.FixedUpdater;
import update.Updatable;
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

        var drawcallsLayout = '<container>
        <drawcall type="color"/>
        <drawcall type="text" font=""/>
        <drawcall type="image" path="Assets/c-256.png" />
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
        machine.addState(new SplitGameState(Builder.widget(), rootEntity));
        machine.changeState(SplitGameState);
        addUpdatable(machine);
    }
}

class MetaGameState extends State {
    var w:Placeholder2D;
    var root:Entity;

    public function new(w, root) {
        this.w = w;
        this.root = root;
        welcomeScreen(w);
    }

    override function onEnter() {
        var sw = root.getComponentUpward(WidgetSwitcher);
        if (sw == null)
            throw 'WThere is no WigetSwitcher';
        sw.switchTo(w);
    }

    override function onExit() {
        super.onExit();
        var sw = root.getComponentUpward(WidgetSwitcher);
        if (sw == null)
            throw 'WThere is no WigetSwitcher';
        sw.switchTo(null);
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

class SplitGameState extends State implements ui.GameplayUIMock.GameMock {
    // var game:NextFloorGame;
    // var rend:NextFloorRender;
    var input:J23Input;
    var w:Placeholder2D;
    var root:Entity;
    var switcher:WidgetSwitcher<Axis2D>;
    var gpScreen:Placeholder2D;
    var pauseScreen:Placeholder2D;
    var game:FixedUpdater;

    public function new(w:Placeholder2D, root:Entity) {
        this.w = w;
        this.root = root;

        var fui = root.getComponentUpward(FuiBuilder);
        var b = fui.placeholderBuilder;
        var shViewSz = 0.33;
        var refCrcles = Builder.createContainer(b.v(sfr, shViewSz).b(), horizontal, Align.Center).withChildren([
            new Button(b.h(sfr, shViewSz)
                .v(sfr, shViewSz)
                .b()
                .withLiquidTransform(fui.ar.getAspectRatio()), null, "O", fui.s("fit")).widget(),
            new Button(b.h(sfr, shViewSz)
                .v(sfr, shViewSz)
                .b()
                .withLiquidTransform(fui.ar.getAspectRatio()), null, "O", fui.s("fit")).widget(),
        ]);

        var splittingCrcle = Builder.createContainer(b.v(sfr, shViewSz).b(), horizontal, Align.Center).withChildren([
            // new Button(b.h(sfr, shViewSz) .v(sfr, shViewSz) .b() .withLiquidTransform(fui.ar.getAspectRatio()), null, "O", fui.s("fit")).widget(),
            new DebugQuadRender(fui, b.h(sfr, shViewSz).v(sfr, shViewSz).b().withLiquidTransform(fui.ar.getAspectRatio()), "c-256.png").widget()
        ]);
        var pnl = Builder.createContainer(w, vertical, Align.Center).withChildren([refCrcles, splittingCrcle]);

        this.game = new FixedUpdater();
        switcher = new WidgetSwitcher(w);
        root.getComponent(FuiBuilder).makeClickInput(w);
        input = new J23Input();
        // game = new NextFloorGame(640, 960, input);
        // rend = new NextFloorRender();
        // rend.init(game.model);

        // var pointer = new GuidedPointer();
        // this.game.addUpdatable(pointer);

        // var poly = new PolyLineSystem(new Sprite(), input, pointer.pointer);
        // spriteAdapter(w, poly.canvas);
        // this.game.addUpdatable(poly);

        // var figures = new Sprite();
        // Lib.current.addChild(figures);
        // new FigureRender(figures, poly);
        initScreens();
    }

    function initScreens() {
        gpScreen = new GameplayScreen(Builder.widget(), root, this).widget();
        pauseScreen = new GameplayPauseScreen(Builder.widget(), root, this).widget();
    }

    override function update(t:Float) {
        // if (game.p)
        //     return;
        input.beforeUpdate(t);
        game.update();
        // rend.update(t);
        input.afterUpdate();
    }

    function spriteAdapter(w:Placeholder2D, spr:Sprite) {
        var dp = DrawcallDataProvider.get(w.entity);
        new CtxWatcher(FlashDisplayRoot, w.entity);
        dp.views.push(spr);
        // var size = game.model.bounds.size;
        // return new SpriteAspectKeeper(w, spr, new Boundbox(0, 0, size[horizontal], size[vertical]));
    }

    public function pause(v) {
        // game.p = v;
        if (v)
            switcher.switchTo(pauseScreen);
        else
            switcher.switchTo(gpScreen);
    }

    override function onEnter() {
        var sw = root.getComponentUpward(WidgetSwitcher);
        if (sw == null)
            throw 'WThere is no WigetSwitcher';
        sw.switchTo(w);
        switcher.switchTo(gpScreen);
    }

    override function onExit() {
        super.onExit();
        var sw = root.getComponentUpward(WidgetSwitcher);
        if (sw == null)
            throw 'WThere is no WigetSwitcher';
        sw.switchTo(null);
    }
}

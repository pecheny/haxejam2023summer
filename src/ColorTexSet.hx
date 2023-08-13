package ;
import data.aliases.AttribAliases;
import data.DataType;
import gl.AttribSet;
class ColorTexSet extends AttribSet {
    public static var instance(default, null):ColorTexSet = new ColorTexSet();

    function new() {
        super();
        addAttribute(AttribAliases.NAME_POSITION, 2, DataType.float32);
        addAttribute(AttribAliases.NAME_UV_0, 2, DataType.float32);
        addAttribute(AttribAliases.NAME_COLOR_IN, 4, DataType.uint8, true);
        createWriters();
    }
}


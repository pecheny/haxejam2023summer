package ;

import data.aliases.VaryingAliases;
import data.aliases.AttribAliases;
import shaderbuilder.ShaderElement;

class ColorTextureFragment implements ShaderElement {
    public static var  instance = new ColorTextureFragment();
   
    var uv:String;
    var sampler:String;
    function new() {
        this.uv = "vUv0";AttribAliases.NAME_UV_0;
        this.sampler = "uImg0";
    }

    public function getDecls():String {
        return '
        varying vec4 ${AttribAliases.NAME_COLOR_OUT};
        varying vec2 ${uv};
        uniform sampler2D ${sampler};';
    }

    public function getExprs():String {
        return '
            vec4 color = ${AttribAliases.NAME_COLOR_OUT};
            vec4 sampled = texture2D (${sampler}, ${uv});
    	    gl_FragColor = color *  vec4(1., 1., 1., sampled.g);';
    }
}


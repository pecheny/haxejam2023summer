package utils;

import utils.Data;

class MathUtil {
    // Standard epsilon value
    public static inline var eps = 1e-6;

    public static inline function intMax(a:Int, b:Int):Int {
        return b > a ? b : a;
    }

    public static inline function intMin(a:Int, b:Int):Int {
        return b < a ? b : a;
    }

    public inline static function clamp(value:Float, min:Float, max:Float):Float {
        if (value < min) {
            return min;
        } else if (value > max) {
            return max;
        } else {
            return value;
        }
    }

    // https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
    public static inline function get_line_intersection(p0_x:Float, p0_y:Float, p1_x:Float, p1_y:Float, p2_x:Float, p2_y:Float, p3_x:Float, p3_y:Float, lastIntersection:Vec2D, treatSecondSegmentAsLine = false) {
        // var i_x:Float, i_y:Float;
        var s1_x, s1_y, s2_x, s2_y;
        s1_x = p1_x - p0_x;
        s1_y = p1_y - p0_y;
        s2_x = p3_x - p2_x;
        s2_y = p3_y - p2_y;

        var s, t;
        s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y);
        t = (s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / (-s2_x * s1_y + s1_x * s2_y);

        var sinrange = s >= 0 && s <= 1;
        var tinrange = t >= 0 && t <= 1;

        // if ( && (treatSecondSegmentAsLine || (t >= 0 && t <= 1))) {
        if(sinrange && ( treatSecondSegmentAsLine || tinrange )){
            // Collision detected
            lastIntersection.x = p0_x + (t * s1_x);
            lastIntersection.y = p0_y + (t * s1_y);
            return true;
        }
        return false; // No collision
    }

    // https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon
    public static inline function pnpoly(poly:Array<Vec2D>, test:Vec2DRO) {
        var i = 0;
        var c = false;
        var j = poly.length - 1;
        while (i < poly.length) {
            if (((poly[i].y > test.y) != (poly[j].y > test.y))
                && (test.x < (poly[j].x - poly[i].x) * (test.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x))
                c = !c;

            j = i++;
        }
        return c;
    }
}

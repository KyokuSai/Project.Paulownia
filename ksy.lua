--[[by HanaCream]]
aegisub = _G.aegisub
pairs = _G.pairs
ipairs = _G.ipairs
type = _G.type
tonumber = _G.tonumber
tostring = _G.tostring
next = _G.next
select = _G.select
pcall = _G.pcall
unpack = _G.unpack
os = _G.os
require = _G.require
re = require("re")
string = require("string")
table = require("table")
util = require("aegisub.util")
karaskel = require("karaskel")
unicode = require("unicode")
json = require("json")
ffi = require("ffi")
pcall(function()
    ffi.cdef([[
enum{CP_UTF8 = 65001};
enum{MM_TEXT = 1};
enum{TRANSPARENT = 1};
enum{PT_MOVETO = 0x6,PT_LINETO = 0x2,PT_BEZIERTO = 0x4,PT_CLOSEFIGURE = 0x1};
enum{FW_NORMAL = 400,FW_BOLD = 700};
enum{DEFAULT_CHARSET = 1};
enum{OUT_TT_PRECIS = 4};
enum{CLIP_DEFAULT_PRECIS = 0};
enum{ANTIALIASED_QUALITY = 4};
enum{DEFAULT_PITCH = 0x0};
enum{FF_DONTCARE = 0x0};
]])
end)
ffi.cdef([[
typedef unsigned int UINT;
typedef unsigned long DWORD;
typedef DWORD* LPDWORD;
typedef const char* LPCSTR;
typedef const wchar_t* LPCWSTR;
typedef wchar_t* LPWSTR;
typedef char* LPSTR;
typedef void* HANDLE;
typedef HANDLE HDC;
typedef int BOOL;
typedef BOOL* LPBOOL;
typedef unsigned int size_t;
typedef HANDLE HFONT;
typedef HANDLE HGDIOBJ;
typedef long LONG;
typedef wchar_t WCHAR;
typedef unsigned char BYTE;
typedef BYTE* LPBYTE;
typedef int INT;
typedef long LPARAM;
typedef struct{LONG cx;LONG cy;}SIZE, *LPSIZE;
typedef struct{LONG left;LONG top;LONG right;LONG bottom;}RECT;
typedef const RECT* LPCRECT;
typedef struct{LONG x;LONG y;}POINT, *LPPOINT;
BOOL AbortPath(HDC);
BOOL GetTextExtentPoint32W(HDC, LPCWSTR, int, LPSIZE);
BOOL BeginPath(HDC);
BOOL ExtTextOutW(HDC, int, int, UINT, LPCRECT, LPCWSTR, UINT, const INT*);
BOOL EndPath(HDC);
BOOL DeleteObject(HGDIOBJ);
BOOL DeleteDC(HDC);
int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
int SetMapMode(HDC, int);
int SetBkMode(HDC, int);
int GetPath(HDC, LPPOINT, LPBYTE, int);
HDC CreateCompatibleDC(HDC);
HFONT CreateFontW(int, int, int, int, int, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
HGDIOBJ SelectObject(HDC, HGDIOBJ);
size_t wcslen(const wchar_t*);
]])

ksy = {
    c2c = function(str) --[[HEX颜色代码与ASS颜色代码互转]]
        local color = ""
        if re.find(str, "#") ~= nil then
            match = re.match(str, "#([A-Za-z0-9]{2})([A-Za-z0-9]{2})([A-Za-z0-9]{2})")
            color = "&H" .. match[4]["str"] .. match[3]["str"] .. match[2]["str"] .. "&"
        else
            match = re.match(str, "&H([A-Za-z0-9]{2})([A-Za-z0-9]{2})([A-Za-z0-9]{2})&")
            color = "#" .. match[4]["str"] .. match[3]["str"] .. match[2]["str"]
        end
        return color
    end,
    len = function(str) --[[获取字符串长度]]
        local tmp = str
        local count = 0
        local byteCount = 0
        while (string.len(tmp) > 0) do
            local code = string.byte(tmp)
            if (code <= 127) then
                byteCount = byteCount + 1
            elseif (code <= 223) then
                byteCount = byteCount + 2
            elseif (code <= 239) then
                byteCount =
                    byteCount + 3
            else
                byteCount = byteCount + 4
            end
            tmp = string.sub(str, byteCount + 1)
            count = count + 1
        end
        return count
    end,
    sub = function(str, start, length) --[[截取字符串]]
        start = start - 1
        if (length <= 0) then return "" end
        local tmp = str
        local count = 0
        local byteCount = 0
        local byteSubStart = 1
        local byteSubEnd = -1
        while (string.len(tmp) > 0) do
            if (count == start) then
                byteSubStart = byteCount + 1
            elseif (count == start + length) then
                byteSubEnd = byteCount
                break
            end
            local code = string.byte(tmp)
            if (code <= 127) then
                byteCount = byteCount + 1
            elseif (code <= 223) then
                byteCount = byteCount + 2
            elseif (code <= 239) then
                byteCount =
                    byteCount + 3
            else
                byteCount = byteCount + 4
            end
            tmp = string.sub(str, byteCount + 1)
            count = count + 1
        end
        return string.sub(str, byteSubStart, byteSubEnd)
    end,
    rep = function(str, search, replace) --[[替换字符串]]
        local res = ""
        for i = 0, ksy.len(str) - 1 do
            local current = ksy.sub(str, i + 1, 1)
            if current == search then res = res .. replace else res = res .. current end
        end
        return res
    end,
    _rotate = function(x, y, z, center_x, center_y, center_z, theta1, theta2, theta3)
        x, y, z = ksy._rotate_x(x - center_x, y - center_y, z - center_z, theta1)
        x, y, z = ksy._rotate_y(x, y, z, theta2)
        x, y, z = ksy._rotate_z(x, y, z, theta3)
        x, y, z = x + center_x, y + center_y, z + center_z
        return x, y
    end,
    _rotate_x = function(x, y, z, a)
        local rad = math.rad(a)
        local cos_a = math.cos(rad)
        local sin_a = math.sin(rad)
        local y1 = y * cos_a - z * sin_a
        local z1 = y * sin_a + z * cos_a
        return x, y1, z1
    end,
    _rotate_y = function(x, y, z, a)
        local rad = math.rad(a)
        local cos_a = math.cos(rad)
        local sin_a = math.sin(rad)
        local x1 = x * cos_a + z * sin_a
        local z1 = -x * sin_a + z * cos_a
        return x1, y, z1
    end,
    _rotate_z = function(x, y, z, a)
        local rad = math.rad(a)
        local cos_a = math.cos(rad)
        local sin_a = math.sin(rad)
        local x1 = x * cos_a - y * sin_a
        local y1 = x * sin_a + y * cos_a
        return x1, y1, z
    end,
    circle = function(r) --[[贝塞尔圆]]
        local x = r * (2 ^ .5 - 1) * 4 / 3
        local c = string.format(
            "m 0 -%s b -%s -%s -%s -%s -%s 0 b -%s %s -%s %s 0 %s b %s %s %s %s %s 0 b %s -%s %s -%s 0 -%s ",
            r, x, r, r, x, r, r, x, x, r, r, x, r, r, x, r, r, x, x, r, r)
        return c
    end,
    star = function(angles, majorAxis, minorAxis, frz) --[[等边半正凹多边形]]
        if frz == nil then frz = 0 end
        local points = {}
        local angle = math.pi / angles
        for i = 0, angles * 2 - 1 do
            local r = (i % 2 == 0) and majorAxis or minorAxis
            local theta = i * angle
            local x = r * math.cos(theta)
            local y = r * math.sin(theta)
            ksy.table(points).add(string.format("%.2f %.2f", x, y))
        end
        draw = "m " .. ksy.table(points).join(" l ")
        draw = ksy.rotate(draw, 0, 0, 0, 0, frz - 90)
        return draw
    end,
    deg = function(x1, y1, x2, y2) --[[相对角度]]
        local dx = x2 - x1
        local dy = y2 - y1
        local angle = math.atan2(dy, dx)
        return math.deg(angle)
    end,
    debug = function(e)
        if type(e) == "table" then
            e = json.encode(e)
        elseif e == nil then
            e = "nil"
        elseif e == true then
            e = "true"
        elseif e == false then
            e = "false"
        end
        aegisub.debug.out(2, e .. "\n")
    end,
    copy = function(tbl, depth) --[[深拷贝]]
        if type(tbl) ~= "table" then
            return tbl
        end
        if depth ~= nil and depth <= 0 then
            return tbl
        end
        local new_tbl = {}
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                new_tbl[k] = ksy.copy(v, depth and (depth - 1) or nil)
            else
                new_tbl[k] = v
            end
        end
        return new_tbl
    end,
    round = function(value, precision)
        value = tonumber(value) or 0
        return precision and math.floor(value * 10 ^ precision + .5) / 10 ^ precision or math.floor(value + .5)
    end,
    utf8_to_utf16 = function(str)
        local wlen = ffi.C.MultiByteToWideChar(ffi.C.CP_UTF8, 0x0, str, -1, nil, 0)
        local ws = ffi.new("wchar_t[?]", wlen)
        ffi.C.MultiByteToWideChar(ffi.C.CP_UTF8, 0x0, str, -1, ws, wlen)
        return ws
    end,
    str = function(str, styleref)
        styleref = styleref ~= nil and styleref or line.styleref
        return {
            info = function() --[[获取指定字符串的几何属性]]
                local width, height, descent, extlead = aegisub.text_extents(styleref, str)
                return { width = width, height = height, descent = descent, extlead = extlead }
            end,
            getw = function() --[[获取指定字符串的宽度]]
                return ksy.str(str, styleref).info().width
            end,
            geth = function() --[[获取指定字符串的高度]]
                return ksy.str(str, styleref).info().height
            end,
            toshape = function(font_precision, fp_precision) --[[文字转绘图, 主要代码来自Yutils]]
                font_precision = font_precision ~= nil and font_precision or 64
                fp_precision = fp_precision ~= nil and fp_precision or 2
                local resources_deleter
                local dc = ffi.gc(ffi.C.CreateCompatibleDC(nil), function() resources_deleter() end)
                ffi.C.SetMapMode(dc, ffi.C.MM_TEXT)
                ffi.C.SetBkMode(dc, ffi.C.TRANSPARENT)
                local font = ffi.C.CreateFontW(
                    styleref.fontsize * font_precision, 0, 0, 0,
                    styleref.bold and ffi.C.FW_BOLD or ffi.C.FW_NORMAL,
                    styleref.italic and 1 or 0,
                    styleref.underline and 1 or 0,
                    styleref.strikeout and 1 or 0,
                    ffi.C.DEFAULT_CHARSET,
                    ffi.C.OUT_TT_PRECIS,
                    ffi.C.CLIP_DEFAULT_PRECIS,
                    ffi.C.ANTIALIASED_QUALITY,
                    ffi.C.DEFAULT_PITCH + ffi.C.FF_DONTCARE,
                    ksy.utf8_to_utf16(styleref.fontname)
                )
                local old_font = ffi.C.SelectObject(dc, font)
                resources_deleter = function()
                    ffi.C.SelectObject(dc, old_font)
                    ffi.C.DeleteObject(font)
                    ffi.C.DeleteDC(dc)
                end
                local shape, shape_n = {}, 0
                text = ksy.utf8_to_utf16(str)
                local text_len = tonumber(ffi.C.wcslen(text))
                local char_widths
                if styleref.spacing ~= 0 then
                    char_widths = ffi.new("INT[?]", text_len)
                    local size, space = ffi.new("SIZE[1]"), styleref.spacing * font_precision
                    for i = 0, text_len - 1 do
                        ffi.C.GetTextExtentPoint32W(dc, text + i, 1, size)
                        char_widths[i] = size[0].cx + space
                    end
                end
                ffi.C.BeginPath(dc)
                ffi.C.ExtTextOutW(dc, 0, 0, 0x0, nil, text, text_len, char_widths)
                ffi.C.EndPath(dc)
                local points_n = ffi.C.GetPath(dc, nil, nil, 0)
                if points_n > 0 then
                    local points, types = ffi.new("POINT[?]", points_n), ffi.new("BYTE[?]", points_n)
                    ffi.C.GetPath(dc, points, types, points_n)
                    local i = 0
                    local cur_type, cur_point
                    while i < points_n do
                        cur_type, cur_point = types[i], points[i]
                        if cur_type == ffi.C.PT_MOVETO then
                            shape_n = shape_n + 1
                            shape[shape_n] = "m"
                            shape[shape_n + 1] = ksy.round(cur_point.x / font_precision * styleref.scale_x * .01,
                                fp_precision)
                            shape[shape_n + 2] = ksy.round(cur_point.y / font_precision * styleref.scale_y * .01,
                                fp_precision)
                            shape_n = shape_n + 2
                            i = i + 1
                        elseif cur_type == ffi.C.PT_LINETO or cur_type == (ffi.C.PT_LINETO + ffi.C.PT_CLOSEFIGURE) then
                            shape_n = shape_n + 1
                            shape[shape_n] = "l"
                            shape[shape_n + 1] = ksy.round(cur_point.x / font_precision * styleref.scale_x * .01,
                                fp_precision)
                            shape[shape_n + 2] = ksy.round(cur_point.y / font_precision * styleref.scale_y * .01,
                                fp_precision)
                            shape_n = shape_n + 2
                            i = i + 1
                        elseif cur_type == ffi.C.PT_BEZIERTO or cur_type == (ffi.C.PT_BEZIERTO + ffi.C.PT_CLOSEFIGURE) then
                            shape_n = shape_n + 1
                            shape[shape_n] = "b"
                            shape[shape_n + 1] = ksy.round(cur_point.x / font_precision * styleref.scale_x * .01,
                                fp_precision)
                            shape[shape_n + 2] = ksy.round(cur_point.y / font_precision * styleref.scale_y * .01,
                                fp_precision)
                            shape[shape_n + 3] = ksy.round(points[i + 1].x / font_precision * styleref.scale_x * .01,
                                fp_precision)
                            shape[shape_n + 4] = ksy.round(points[i + 1].y / font_precision * styleref.scale_y * .01,
                                fp_precision)
                            shape[shape_n + 5] = ksy.round(points[i + 2].x / font_precision * styleref.scale_x * .01,
                                fp_precision)
                            shape[shape_n + 6] = ksy.round(points[i + 2].y / font_precision * styleref.scale_y * .01,
                                fp_precision)
                            shape_n = shape_n + 6
                            i = i + 3
                        else
                            i = i + 1
                        end
                    end
                end
                ffi.C.AbortPath(dc)
                return ksy.shape(ksy.table(shape).join(" "))
            end
        }
    end,
    table = function(tbl)
        return {
            contains = function(value, ...) --[[判断是否包含指定值]]
                if value == nil then
                    return true
                end
                local lookup = {}
                for _, v in ipairs(tbl) do
                    lookup[v] = true
                end
                for i = 1, select("#", value, ...) do
                    local _value = select(i, value, ...)
                    if not lookup[_value] then
                        return false
                    end
                end
                return true
            end,
            containsKey = function(key, ...) --[[判断是否包含指定键]]
                if key == nil then
                    return true
                end
                for i = 1, select("#", key, ...) do
                    local _key = select(i, key, ...)
                    if tbl[_key] == nil then
                        return false
                    end
                end
                return true
            end,
            join = function(separator) --[[转字符串]]
                return table.concat(tbl, separator)
            end,
            dedup = function() --[[去重]]
                local seen = {}
                local removeindices = {}
                for i, value in ipairs(tbl) do
                    if seen[value] then
                        ksy.table(removeindices).add(i)
                    else
                        seen[value] = true
                    end
                end
                return ksy.table(tbl).removeAt(unpack(removeindices))
            end,
            remove = function(value, ...) --[[移除指定值]]
                for i = #tbl, 1, -1 do
                    for _i = 1, select("#", value, ...) do
                        local _value = select(_i, value, ...)
                        if tbl[i] == _value then
                            table.remove(tbl, i)
                        end
                    end
                end
                return ksy.table(tbl)
            end,
            removeAt = function(index, ...) --[[移除指定索引]]
                local indices = { index, ... }
                table.sort(indices, function(a, b)
                    return a > b
                end)
                local _prev
                for _, _index in ipairs(indices) do
                    if _index ~= _prev then
                        table.remove(tbl, _index)
                    end
                    _prev = _index
                end
                return ksy.table(tbl)
            end,
            removeKey = function(key, ...) --[[移除指定键]]
                for i = 1, select("#", key, ...) do
                    local _key = select(i, key, ...)
                    tbl[_key] = nil
                end
                return ksy.table(tbl)
            end,
            removeValue = function(value, ...) --[[移除指定值]]
                for k, v in pairs(tbl) do
                    for i = 1, select("#", value, ...) do
                        local _value = select(i, value, ...)
                        if v == _value then
                            tbl[k] = nil
                        end
                    end
                end
                return ksy.table(tbl)
            end,
            add = function(value, ...) --[[添加指定值]]
                for i = 1, select("#", value, ...) do
                    local _value = select(i, value, ...)
                    table.insert(tbl, _value)
                end
                return ksy.table(tbl)
            end,
            copy = function(depth) --[[深拷贝]]
                return ksy.table(ksy.copy(tbl, depth))
            end,
            value = tbl,
        }
    end,
    func = function(func)
        return {
            partial = function(param, ...)
                local fixedparams = { param, ... }
                return function(...)
                    func(unpack(fixedparams), ...)
                end
            end,
            run = function()
                local value = func()
                if value ~= nil then
                    return value
                end
                return ""
            end,
        }
    end,
    clock = function(start_time, end_time)
        if start_time == nil then
            start_time = os.clock()
        end
        return {
            fin = function()
                end_time = os.clock()
                return ksy.clock(start_time, end_time)
            end,
            dur = function()
                return end_time - start_time
            end,
        }
    end,
    shape = function(shape)
        local points, commands = {}, {}
        if type(shape) == "table" then
            points = shape.points
            commands = shape.commands
        else
            local tokens = {}
            for token in string.gmatch(shape, "%S+") do
                ksy.table(tokens).add(token)
                if tonumber(token) then
                    if points[#points] == nil or points[#points].y ~= nil then
                        ksy.table(points).add({ x = tonumber(token) })
                    else
                        points[#points].y = tonumber(token)
                    end
                    if #points > #commands then
                        ksy.table(commands).add(commands[#commands])
                    end
                else
                    ksy.table(commands).add(token)
                end
            end
        end
        local _out = function(move, precision)
            local _commands, _points = ksy.copy(move.commands), ksy.copy(move.points)
            local _shape = {}
            for i = 1, #_commands do
                if _commands[i] == nil then
                    goto continue
                elseif _commands[i] == "b" then
                    _commands[i + 1] = nil
                    _commands[i + 2] = nil
                    ksy.table(_shape).add(_commands[i])
                else
                    ksy.table(_shape).add(_commands[i])
                end
                ::continue::
                local x, y = _points[i].x, _points[i].y
                if precision then
                    x = ksy.round(x, precision)
                    y = ksy.round(y, precision)
                end
                ksy.table(_shape).add(tostring(x))
                ksy.table(_shape).add(tostring(y))
                _commands[i] = nil
            end
            return ksy.table(_shape).join(" ")
        end
        local _out1 = function(precision)
            return _out({ commands = commands, points = points }, precision)
        end
        local moves = {}
        local _out2 = function(precision)
            local _shapes = {}
            for _, move in ipairs(moves) do
                ksy.table(_shapes).add(_out(move, precision))
            end
            return _shapes
        end
        local function _calc_windings(vertex, move, precision) --[[计算环绕数]]
            local _vertex, _commands, _points = ksy.copy(vertex), ksy.copy(move.commands), ksy.copy(move.points)
            local x, y = _vertex.x, _vertex.y
            local windings = 0
            local xmin, xmax, ymin, ymax = _points[1].x, _points[1].x, _points[1].y, _points[1].y
            for i = 2, #_points do
                local _x, _y = _points[i].x, _points[i].y
                if _x > xmax then
                    xmax = _x
                elseif _x < xmin then
                    xmin = _x
                end
                if _y > ymax then
                    ymax = _y
                elseif _y < ymin then
                    ymin = _y
                end
            end
            if x < xmin or x > xmax or y > ymax then
                return windings
            end
            for i = 1, #_commands do
                if i == 1 then
                    goto continue
                end
                if _commands[i] == nil then
                    goto continue
                elseif _commands[i] == "b" then
                    _commands[i + 1] = nil
                    _commands[i + 2] = nil
                    if x < math.min(_points[i - 1].x, _points[i].x, _points[i + 1].x, _points[i + 2].x) or x > math.max(_points[i - 1].x, _points[i].x, _points[i + 1].x, _points[i + 2].x) then
                        goto continue
                    end
                    local _bezier = ksy.shape(("m %s %s b %s %s %s %s %s %s"):format(_points[i - 1].x, _points[i - 1].y,
                        _points[i].x, _points[i].y, _points[i + 1].x, _points[i + 1].y, _points[i + 2].x, _points[i + 2]
                        .y))
                    local __commands = {}
                    local __points = {}
                    ksy.table(__commands).add("m")
                    ksy.table(__points).add({ x = _points[i - 1].x, y = _points[i - 1].y })
                    for _t = 1, precision do
                        local _x, _y = _bezier.bezier(_t / precision)
                        ksy.table(__commands).add("l")
                        ksy.table(__points).add({ x = _x, y = _y })
                    end
                    windings = windings +
                        _calc_windings(_vertex, { commands = __commands, points = __points }, precision)
                else
                    local x1, y1 = _points[i - 1].x, _points[i - 1].y
                    local x2, y2 = _points[i].x, _points[i].y
                    if x < math.min(x1, x2) or x > math.max(x1, x2) then
                        goto continue
                    end
                    local y0 = y1 + (y2 - y1) * (x - x1) / (x2 - x1)
                    if y0 >= y then
                        if x == math.min(x1, x2) then
                            windings = windings + (x2 > x1 and 1 or -1)
                        elseif x == math.max(x1, x2) then
                            windings = windings + 0
                        else
                            windings = windings + (x2 > x1 and 1 or -1)
                        end
                    end
                end
                ::continue::
                _commands[i] = nil
            end
            return windings
        end
        local function _separate_moves() --[[分离绘图]]
            for i, command in ipairs(commands) do
                if command == "m" then
                    ksy.table(moves).add({ commands = {}, points = {} })
                end
                ksy.table(moves[#moves].commands).add(command)
                ksy.table(moves[#moves].points).add(ksy.copy(points[i]))
            end
            for _, move in ipairs(moves) do
                if move.points[#move.points].x ~= move.points[1].x or move.points[#move.points].y ~= move.points[1].y then
                    ksy.table(move.commands).add("l")
                    ksy.table(move.points).add(ksy.copy(move.points[1]))
                end
            end
        end
        local function _separate_domains(precision) --[[分离连通域]]
            local _intersects = {}
            for i, move in ipairs(moves) do
                _intersects[i] = {}
                local _vertex = move.points[1]
                for _i, _move in ipairs(moves) do
                    if i == _i then
                        goto continue
                    end
                    if _calc_windings(_vertex, _move, precision) ~= 0 then
                        ksy.table(_intersects[i]).add(_i)
                    end
                    ::continue::
                end
            end
            local removeindices = {}
            for i, move in ipairs(moves) do
                if #_intersects[i] % 2 == 0 then
                    goto continue
                end
                for _, index in ipairs(_intersects[i]) do
                    if #_intersects[index] == #_intersects[i] - 1 and ksy.table(_intersects[index]).contains(unpack(ksy.table(_intersects[i]).copy().remove(index).value)) then
                        ksy.table(moves[index].commands).add(unpack(move.commands))
                        ksy.table(moves[index].points).add(unpack(move.points))
                        ksy.table(removeindices).add(i)
                        break
                    end
                end
                ::continue::
            end
            ksy.table(moves).removeAt(unpack(removeindices))
        end
        return {
            bezier = function(t) --[[计算贝塞尔曲线在参数t处的值]]
                local x1, y1 = points[1].x, points[1].y
                local x2, y2 = points[2].x, points[2].y
                local x3, y3 = points[3].x, points[3].y
                local x4, y4 = points[4].x, points[4].y
                local u = 1 - t
                local uu = u * u
                local uuu = uu * u
                local tt = t * t
                local ttt = tt * t
                local pX = uuu * x1 + 3 * uu * t * x2 + 3 * u * tt * x3 + ttt * x4
                local pY = uuu * y1 + 3 * uu * t * y2 + 3 * u * tt * y3 + ttt * y4
                return pX, pY
            end,
            is_intersect = function(x, y, precision) --[[是否相交]]
                precision = precision ~= nil and precision or 50
                return _calc_windings({ x = x, y = y }, { commands = commands, points = points }, precision) == 0
            end,
            filter = function(filter) --[[对图形进行自定义处理]]
                for i, point in ipairs(points) do
                    local x, y = filter(point.x, point.y)
                    points[i] = { x = x, y = y }
                end
                return ksy.shape({ commands = commands, points = points })
            end,
            rotate = function(center_x, center_y, theta1, theta2, theta3) --[[旋转绘图]]
                return ksy.shape(shape).filter(function(x, y)
                    return ksy._rotate(x, y, 0, center_x, center_y, 0, theta1, theta2, theta3)
                end)
            end,
            split = function(precision) --[[拆分连通域]]
                precision = precision ~= nil and precision or 10
                _separate_moves()
                _separate_domains(precision)
                return { out = _out2 }
            end,
            out = _out1,
        }
    end,
}

--[[極彩花夢 - 正文字幕样式配置自动化]]
--[[———————————————————————————————]]
--[[为不同角色配置不同的效果]]
--[[修正标点符号显示效果，为句首、句尾含有标点符号的行调整重心]]
--[[将开始时间、结束时间设为最近的帧]]
--[[添加\furi(num,text,fsc,fsp)]]
--[[检查字幕是否超出画布或接近边缘]]
--[[检查字幕持续时间是否过短]]
--[[检查字幕开始时间、结束时间周围是否有关键帧]]
--[[检查字幕是否闪轴]]
--[[为特殊对话框样式进行适配]]

function ksy_shuusei()
    if meta["language"] == "ENG" then
        local res = characters["Basic"]
        res = res .. ksy_character()
        res = res .. orgline.text
        ksy_time()
        return res
    end
    line.text = orgline.text
    if type(ksy_fix) == "function" then
        ksy_fix()
    end
    ksy_style()
    local res = ksy_effect(true)
    res = res .. characters["Basic"]
    res = res .. ksy_character()
    res = res .. ksy_content()
    ksy_layer()
    ksy_margin()
    ksy_time()
    res = ksy_relocate(res)
    ksy_check()
    return res
end

function ksy_menu()
    local function _generate_dropdown(menu, name, label, items, description)
        menu[#menu + 1] = {
            class  = "label",
            x      = 0,
            y      = menu[#menu].y + menu[#menu].height + 1,
            width  = 4,
            height = 1,
            label  = label .. "："
        }
        menu[#menu + 1] = {
            name   = name,
            class  = "dropdown",
            x      = 5,
            y      = menu[#menu].y,
            width  = 4,
            height = 1,
            items  = items,
            value  = items[1]
        }
        menu[#menu + 1] = {
            class  = "label",
            x      = 0,
            y      = menu[#menu].y + 1,
            width  = 9,
            height = select(2, description:gsub("\n", "")) + 1,
            label  = description
        }
    end

    local menu = {
        {
            class  = "label",
            x      = 2,
            y      = 0,
            width  = 5,
            height = 1,
            label  = "極彩花夢 - 正文字幕样式配置自动化v241001"
        }
    }
    local function _add(_list, _elements)
        for _, _value in ipairs(_elements) do
            if _value ~= _list[1] then
                table.insert(_list, _value)
            end
        end
        return _list
    end
    local _lang = {}
    if meta["language"] ~= nil and meta["language"] == "JPN" then
        table.insert(_lang, "日语字幕")
    end
    _lang = _add(_lang, { "中日双语", "日语字幕" })
    local _styles = {}
    table.insert(_styles, " ")
    _styles = _add(_styles, { "kawaii", "sans", "serif" })
    _generate_dropdown(menu, "lang", "选择字幕配置", _lang, "将双语字幕按照预设转变为日语字幕。\n如果字幕贴近边缘、超出画布会进行提示。")
    _generate_dropdown(menu, "style", "应用样式", _styles,
        "忽略默认配置强制应用预设的字幕样式，如果与默认配置相同则此选项不会生效。\n仅用于调试，部分标签会表达出错误的效果。")
    _generate_dropdown(menu, "check_duration", "字幕持续时间检测阈值", { "10帧", "15帧", "12帧" }, "如果持续时间低于设定帧数会提示。")
    _generate_dropdown(menu, "check_start_frame", "字幕开始时间关键帧检测阈值", { "3帧", "5帧", "7帧" }, "如果开始时间离最近的关键帧的差值小于设定帧数会提示。")
    _generate_dropdown(menu, "check_end_frame", "字幕结束时间关键帧检测阈值", { "4帧", "8帧", "12帧" }, "如果结束时间离最近的关键帧的差值小于设定帧数会提示。")
    _generate_dropdown(menu, "check_time_interval", "字幕闪轴检测阈值", { "6帧", "10帧", "15帧" }, "如果开始时间与前一行字幕的结束时间差值小于设定帧数会提示。")
    menu[#menu + 1] = {
        name   = "change_characters",
        class  = "checkbox",
        x      = 0,
        y      = menu[#menu].y + menu[#menu].height + 1,
        width  = 1,
        height = 1,
        label  = "修改效果表",
        value  = false
    }
    menu[#menu + 1] = {
        class  = "label",
        x      = 0,
        y      = menu[#menu].y + menu[#menu].height,
        width  = 1,
        height = 1,
        label  = "基础效果："
    }
    menu[#menu + 1] = {
        name   = "characters_Basic",
        class  = "edit",
        x      = 1,
        y      = menu[#menu].y,
        width  = 2,
        height = 1,
        text   = re.match(characters["Basic"], "\\{(.+)\\}")[2]["str"]
    }
    menu[#menu + 1] = {
        class  = "label",
        x      = 3,
        y      = menu[#menu].y,
        width  = 1,
        height = 1,
        label  = "空白效果："
    }
    menu[#menu + 1] = {
        name   = "characters_Blank",
        class  = "color",
        x      = 4,
        y      = menu[#menu].y,
        width  = 2,
        height = 1,
        value  = ksy.c2c(re.match(characters["Blank"], "\\\\3c(&H[0-9A-F]{6}&)")[2]["str"])
    }
    for _character, _effect in pairs(characters) do
        if _character ~= "Basic" and _character ~= "Blank" then
            menu[#menu + 1] = {
                class  = "label",
                x      = menu[#menu - 1].x + 3 > 6 and 0 or menu[#menu - 1].x + 3,
                y      = menu[#menu].y + (menu[#menu - 1].x + 3 > 6 and 1 or 0),
                width  = 1,
                height = 1,
                label  = _character .. "："
            }
            menu[#menu + 1] = {
                name   = "characters_" .. _character,
                class  = "color",
                x      = menu[#menu].x + 1,
                y      = menu[#menu].y,
                width  = 2,
                height = 1,
                value  = ksy.c2c(re.match(_effect, "\\\\3c(&H[0-9A-F]{6}&)")[2]["str"])
            }
        end
    end

    local space = string.rep("\xE3\x80\x80", 9)
    local button, _config = aegisub.dialog.display(
        menu,
        {
            space .. "应用" .. space,
            space .. "取消" .. space
        }
    )
    if button == space .. "取消" .. space then
        aegisub.cancel()
    end

    local function _generate_style(str)
        local _styleref = {
            ["name"] = "Sx-jp",
            ["fontname"] = "",
            ["fontsize"] = 0,
            ["color1"] = "&H00FFFFFF&",
            ["color2"] = "&HFFFFFFFF&",
            ["color3"] = "&H00000000&",
            ["color4"] = "&H00000000&",
            ["bold"] = false,
            ["italic"] = false,
            ["underline"] = false,
            ["strikeout"] = false,
            ["scale_x"] = 100,
            ["scale_y"] = 100,
            ["spacing"] = 0,
            ["angle"] = 0,
            ["borderstyle"] = 1,
            ["outline"] = 0,
            ["shadow"] = 0,
            ["align"] = 2,
            ["margin_l"] = 0,
            ["margin_r"] = 0,
            ["margin_v"] = 0,
            ["margin_t"] = 0,
            ["margin_b"] = 0,
            ["encoding"] = 1,
            ["class"] = "style",
            ["raw"] = str,
            ["section"] = "[V4+ Styles]",
            ["relative_to"] = 2,
        }
        local _asstag = {
            ["name"] = false,
            ["fontname"] = "fn",
            ["fontsize"] = "fs",
            ["color1"] = "1c",
            ["color2"] = "2c",
            ["color3"] = "3c",
            ["color4"] = "4c",
            ["bold"] = "b",
            ["italic"] = "i",
            ["underline"] = "u",
            ["strikeout"] = "s",
            ["scale_x"] = "fscx",
            ["scale_y"] = "fscy",
            ["spacing"] = "fsp",
            ["angle"] = "frz",
            ["borderstyle"] = false,
            ["outline"] = "bord",
            ["shadow"] = "shad",
            ["align"] = "an",
            ["margin_l"] = function(_value)
                line.margin_l = _value + line.margin_l
            end,
            ["margin_r"] = function(_value)
                line.margin_r = _value + line.margin_r
            end,
            ["margin_v"] = function(_value)
                line.margin_v = _value + line.margin_v
                line.margin_t = line.margin_v
                line.margin_b = line.margin_v
            end,
            ["margin_t"] = false,
            ["margin_b"] = false,
            ["encoding"] = "fe",
        }
        match = re.match(str,
            "^Style: ?([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")
        table.remove(match, 1)
        local _keys = { "name", "fontname", "fontsize", "color1", "color2", "color3", "color4", "bold", "italic",
            "underline", "strikeout", "scale_x", "scale_y", "spacing", "angle", "borderstyle", "outline", "shadow",
            "align", "margin_l", "margin_r", "margin_v", "encoding" }
        local _effect = "{"
        local _margin = {}
        for _index in pairs(_keys) do
            if type(_styleref[_keys[_index]]) == "string" then
                _styleref[_keys[_index]] = match[_index]["str"]
            elseif type(_styleref[_keys[_index]]) == "boolean" then
                _styleref[_keys[_index]] = match[_index]["str"] == "1"
            elseif type(_styleref[_keys[_index]]) == "number" then
                if _keys[_index] == "margin_v" then
                    _styleref["margin_t"] = tonumber(match[_index]["str"])
                    _styleref["margin_b"] = tonumber(match[_index]["str"])
                end
                _styleref[_keys[_index]] = tonumber(match[_index]["str"])
            end
            if _asstag[_keys[_index]] == false then
                goto continue
            elseif type(_asstag[_keys[_index]]) == "string" then
                _effect = _effect ..
                    "\\" ..
                    _asstag[_keys[_index]] ..
                    ((_index >= 4 and _index <= 7) and util.color_from_style(match[_index]["str"]) or match[_index]["str"])
            elseif type(_asstag[_keys[_index]]) == "function" then
                _margin[#_margin + 1] = { _asstag[_keys[_index]], tonumber(match[_index]["str"]) }
            end
            ::continue::
        end
        _effect = _effect .. "}"
        return _styleref, _effect, _margin
    end

    local _generated_style_jp = { {}, "", {} }
    local _generated_style_zh = { {}, "", {} }
    config = {
        ["JPN_only"] = _config["lang"] ~= "中日双语",
        ["style_force"] = _config["style"] ~= " ",
        ["style"] = "",
        ["styleref"] = {
            ["Sx-jp"] = {},
            ["Sx-zh"] = {},
        },
        ["stylerefs"] = {
            ["kawaii"] = {
                ["Sx-jp"] =
                    _generate_style(
                        "Style: Sx-jp,A-OTF Shin Maru Go Pr6N DB,65,&H00FFFFFF,&HFFFFFFFF,&H00000000,&H64000000,0,0,0,0,99,100,0.5,0,1,2.42,0,2,0,0,15,128"),
                ["Sx-zh"] =
                    _generate_style(
                        "Style: Sx-zh,方正兰亭圆_GBK_中,62,&H00FFFFFF,&HFFFFFFFF,&H00000000,&H64000000,0,0,0,0,100,100,0,0,1,2.42,0,2,0,0,65,1"),
            },
            ["sans"] = {
                ["Sx-jp"] =
                    _generate_style(
                        "Style: Sx-jp,Noto Sans JP Medium,64,&H00FFFFFF,&HFFFFFFFF,&H00000000,&H00000000,0,0,0,0,99,100,0.5,0,1,2.42,0,2,0,0,15,128"),
                ["Sx-zh"] =
                    _generate_style(
                        "Style: Sx-zh,Noto Sans SC Medium,78,&H00FFFFFF,&HFFFFFFFF,&H00000000,&H64000000,0,0,0,0,99,100,0.5,0,1,2.42,0,2,0,0,65,1"),
            },
            ["serif"] = {
                ["Sx-jp"] =
                    _generate_style(
                        "Style: Sx-jp,A-OTF Ryumin Pr6N H-KL,60,&H00FFFFFF,&HFFFFFFFF,&H00000000,&H64000000,0,0,0,0,99,100,1,0,1,2.42,0,2,0,0,15,128"),
                ["Sx-zh"] =
                    _generate_style(
                        "Style: Sx-zh,方正中粗雅宋_GBK,66,&H00FFFFFF,&HFFFFFFFF,&H00000000,&H64000000,0,0,0,0,95,100,2,0,1,2.42,0,2,0,0,65,1"),
            },
        },
        ["effect"] = {
            ["Sx-jp"] = _generated_style_jp[2],
            ["Sx-zh"] = _generated_style_zh[2],
        },
        ["margin"] = {
            ["Sx-jp"] = _generated_style_jp[3],
            ["Sx-zh"] = _generated_style_zh[3],
        },
        ["check_duration"] = tonumber(re.match(_config["check_duration"], "(\\d+)")[1]["str"]),
        ["check_start_frame"] = tonumber(re.match(_config["check_start_frame"], "(\\d+)")[1]["str"]),
        ["check_end_frame"] = tonumber(re.match(_config["check_end_frame"], "(\\d+)")[1]["str"]),
        ["check_time_interval"] = tonumber(re.match(_config["check_time_interval"], "(\\d+)")[1]["str"]),
    }
    if _config["change_characters"] == true then
        for key, value in pairs(_config) do
            if re.find(key, "^characters_") ~= nil then
                local _character = re.match(key, "^characters_(.+)$")[2]["str"]
                if _character == "Basic" then
                    characters["Basic"] = re.sub(characters["Basic"], "\\{(.+)\\}",
                        "{" .. re.sub(value, "\\\\", "\\\\\\\\") .. "}")
                else
                    characters[_character] = re.sub(characters[_character], "\\\\3c(&H[0-9A-F]{6}&)",
                        "\\\\3c" .. ksy.c2c(value))
                end
            end
        end
    end
end

ksy_menu()

keyframes = {}
for _, v in pairs(aegisub.keyframes()) do
    keyframes[v] = true
end

prev_end_frame = 0

ksy_pandora = {
    ["A-OTF Shin Maru Go Pr6N DB"] = {
        ["style"] = "kawaii",
        ["margin_t"] = 8,
        ["contentrep"] = {
            ["？"] = "？",
            ["！"] = "！",
            ["…"] = "…",
            ["「"] = "「",
            [" "] = "{\\fscx180} {\\fscx}",
            ["」"] = "」",
            ["・"] = "・",
        },
        ["relocate"] = {
        },
        ["furigana"] = {
            ["content"] = "{\\an%s\\fs%s\\fscx%s\\fscy%s\\fsp%s\\pos(%s,%s)}%s",
            ["Yoffset"] = 12,
            ["Yoffset2"] = -12,
            ["Yoffset3"] = -6,
            ["fscx"] = 84,
            ["fscy"] = 82,
        },
        ["JPN_only"] = {
            ["fs"] = 78,
            ["Yoffset"] = 8,
            ["Yoffset2"] = 6,
        },
    },
    ["方正兰亭圆_GBK_中"] = {
        ["style"] = "kawaii",
        ["margin_t"] = 64,
        ["contentrep"] = {
            ["？"] = "{\\alpha&HFF&}喵{\\alpha}",
            ["！"] = "{\\fscx50} {\\fscx110}!{\\fscx150} {\\fscx0}!{\\fscx}",
            ["…"] = "{\\alpha&HFF&\\fscx90}喵{\\alpha\\fscx}",
            ["「"] = "「",
            [" "] = "{\\fscx160} {\\fscx}",
            ["」"] = "」",
            ["・"] = "{\\alpha&HFF&}喵{\\alpha}",
        },
        ["relocate"] = {
            ["？"] = {
                ["content"] = "{\\an4\\fnA-OTF Shin Maru Go Pr6N DB\\fscx116\\fscy128\\pos(%s,%s)}？",
                ["Xoffset"] = -3,
                ["Yoffset"] = -2,
                ["Yoffset2"] = -2,
            },
            ["…"] = {
                ["content"] = "{\\an4\\fnA-OTF Shin Maru Go Pr6N DB\\fscx78\\fscy78\\pos(%s,%s)\\fsp-22}・・・",
                ["Xoffset"] = -8,
                ["Yoffset"] = 0,
                ["Yoffset2"] = 0,
            },
            ["・"] = {
                ["content"] = "{\\an5\\fnA-OTF Shin Maru Go Pr6N DB\\fscx116\\fscy116\\pos(%s,%s)}・",
                ["Xoffset"] = 0,
                ["Yoffset"] = 0,
                ["Yoffset2"] = 0,
            },
        },
        ["furigana"] = {
            ["content"] = "{\\an%s\\fs%s\\fscx%s\\fscy%s\\fsp%s\\pos(%s,%s)}%s",
            ["Yoffset"] = 6,
            ["Yoffset2"] = -10,
            ["Yoffset3"] = -8,
            ["fscx"] = 82,
            ["fscy"] = 80,
        },
    },
    ["Noto Sans JP Medium"] = {
        ["style"] = "sans",
        ["margin_t"] = 4,
        ["contentrep"] = {
            ["？"] = "{\\fscx20} {\\fscx}?{\\fscx80} {\\fscx0}?{\\fscx}",
            ["！"] = "{\\fscx30} {\\fscx}!{\\fscx70} {\\fscx0}!{\\fscx}",
            ["…"] = "…",
            ["「"] = "「",
            [" "] = "{\\fscx200} {\\fscx}",
            ["」"] = "」",
            ["・"] = "・",
        },
        ["relocate"] = {
        },
        ["furigana"] = {
            ["content"] = "{\\an%s\\fs%s\\fscx%s\\fscy%s\\fsp%s\\pos(%s,%s)}%s",
            ["Yoffset"] = 8,
            ["Yoffset2"] = -10,
            ["Yoffset3"] = -8,
            ["fscx"] = 84,
            ["fscy"] = 82,
        },
        ["JPN_only"] = {
            ["fs"] = 74,
            ["Yoffset"] = 8,
            ["Yoffset2"] = 6,
        },
    },
    ["Noto Sans SC Medium"] = {
        ["style"] = "sans",
        ["margin_t"] = 50,
        ["contentrep"] = {
            ["？"] = "{\\fscx20} {\\fscx}?{\\fscx80} {\\fscx0}?{\\fscx}",
            ["！"] = "{\\fscx30} {\\fscx}!{\\fscx70} {\\fscx0}!{\\fscx}",
            ["…"] = "{\\alpha&HFF&}喵{\\alpha}",
            ["「"] = "「",
            [" "] = "{\\fscx180} {\\fscx}",
            ["」"] = "」",
            ["・"] = "{\\alpha&HFF&\\fscx72}喵{\\alpha\\fscx}",
        },
        ["relocate"] = {
            ["…"] = {
                ["content"] = "{\\an4\\fnNoto Sans JP Medium\\fscx55\\fscy55\\pos(%s,%s)\\fsp-25}・・・",
                ["Xoffset"] = -6,
                ["Yoffset"] = 0,
                ["Yoffset2"] = 0,
            },
            ["・"] = {
                ["content"] = "{\\an5\\fnNoto Sans JP Medium\\fscx76\\fscy76\\pos(%s,%s)}・",
                ["Xoffset"] = 0,
                ["Yoffset"] = 0,
                ["Yoffset2"] = 0,
            },
        },
        ["furigana"] = {
            ["content"] = "{\\an%s\\fs%s\\fscx%s\\fscy%s\\fsp%s\\pos(%s,%s)}%s",
            ["Yoffset"] = 22,
            ["Yoffset2"] = -27,
            ["Yoffset3"] = -8,
            ["fscx"] = 84,
            ["fscy"] = 82,
        },
    },
    ["A-OTF Ryumin Pr6N H-KL"] = {
        ["style"] = "serif",
        ["margin_t"] = 10,
        ["contentrep"] = {
            ["？"] = "？",
            ["！"] = "！",
            ["…"] = "…",
            ["「"] = "「",
            [" "] = "{\\fscx180} {\\fscx}",
            ["」"] = "」",
            ["・"] = "・",
        },
        ["relocate"] = {
        },
        ["furigana"] = {
            ["content"] = "{\\an%s\\fs%s\\fscx%s\\fscy%s\\fsp%s\\pos(%s,%s)}%s",
            ["Yoffset"] = 7,
            ["Yoffset2"] = -12,
            ["Yoffset3"] = -7,
            ["fscx"] = 80,
            ["fscy"] = 78,
        },
        ["JPN_only"] = {
            ["fs"] = 68,
            ["Yoffset"] = 8,
            ["Yoffset2"] = 6,
        },
    },
    ["方正中粗雅宋_GBK"] = {
        ["style"] = "serif",
        ["margin_t"] = 62,
        ["contentrep"] = {
            ["？"] = "？",
            ["！"] = "{\\fscx10} {\\fscx}!{\\fscx90} {\\fscx0}!{\\fscx}",
            ["…"] = "{\\alpha&HFF&}喵{\\alpha}",
            ["「"] = "「",
            [" "] = " ",
            ["」"] = "」",
            ["・"] = "{\\alpha&HFF&}喵{\\alpha}",
        },
        ["relocate"] = {
            ["…"] = {
                ["content"] = "{\\an4\\fnA-OTF Ryumin Pr6N H-KL\\fscx80\\fscy80\\pos(%s,%s)\\fsp-24.5}・・・",
                ["Xoffset"] = -8,
                ["Yoffset"] = 0,
                ["Yoffset2"] = 0,
            },
            ["・"] = {
                ["content"] = "{\\an5\\fnA-OTF Ryumin Pr6N H-KL\\fscx96\\fscy96\\pos(%s,%s)}・",
                ["Xoffset"] = 0,
                ["Yoffset"] = 0,
                ["Yoffset2"] = 0,
            },
        },
        ["furigana"] = {
            ["content"] = "{\\an%s\\fs%s\\fscx%s\\fscy%s\\fsp%s\\pos(%s,%s)}%s",
            ["Yoffset"] = 8,
            ["Yoffset2"] = -10,
            ["Yoffset3"] = -7,
            ["fscx"] = 76,
            ["fscy"] = 74,
        },
    },
}
ksy_pandora["Noto Sans TC Medium"] = ksy_pandora["Noto Sans SC Medium"]

local function _calwidth(str)
    local styleref = ksy.copy(line.styleref, 1)
    if config.JPN_only == true then
        styleref.fontsize = ksy_pandora[line.styleref.fontname]["JPN_only"]["fs"]
    end
    if orgline.styleref["align"] == 7 then
        str = re.sub(str, "^.*\\\\N", "")
    end
    local width = ksy.str(str, styleref).getw()
    for _search, _replace in pairs(ksy_pandora[line.styleref.fontname]["contentrep"]) do
        if re.find(str, _search) ~= nil then
            local _styleref = ksy.copy(line.styleref, 1)
            if config.JPN_only == true then
                _styleref.fontsize = ksy_pandora[line.styleref.fontname]["JPN_only"]["fs"]
            end
            local _width = 0
            for _part in re.gsplit(_replace, "\\{", true) do
                match = re.match(_part, "\\\\fn(.+)\\}")
                if match ~= nil then
                    _styleref.fontname = match[2]["str"]
                end
                match = re.match(_part, "\\\\fscx(\\d*)")
                if match ~= nil then
                    _styleref.scale_x = tonumber(match[2]["str"]) ~= nil and tonumber(match[2]["str"]) or
                        _styleref.scale_x
                    if match[2]["str"] == "" then
                        _styleref.scale_x = line.styleref.scale_x
                    end
                end
                _width = _width + ksy.str(re.sub(_part, ".+\\}", ""), _styleref).getw()
            end
            width = width + (_width - ksy.str(_search, line.styleref).getw()) * #re.find(str, _search)
        end
    end
    return width
end

local function _callineleft(init)
    init = init ~= nil and init or false
    if init == true then
        ksy_margin()
    end
    if orgline.styleref["align"] == 7 then
        return orgline.styleref["margin_l"]
    end
    local _lineleft = 0
    _lineleft = (meta.res_x - _calwidth(line.text_stripped)) * .5
    return _lineleft + (line.margin_l - line.margin_r) / 2
end

local function _getlineeffects()
    local _effects = ""
    local _text = line.text
    while re.match(_text, "^({[^}]+})") ~= nil do
        _effects = _effects .. re.match(_text, "^({[^}]+})")[2]["str"]
        _text = string.sub(_text, re.match(_text, "^({[^}]+})")[2]["last"] + 1)
    end
    _effects = re.sub(_effects, "\\\\an\\d", "")
    _effects = re.sub(_effects, "\\{\\}", "")
    return _effects
end

function ksy_effect(fix_margin)
    if fix_margin then
        for _, exec in pairs(config["margin"][line.styleref.name]) do
            exec[1](exec[2])
        end
    end
    local effect = config["effect"][line.styleref.name]
    effect = re.sub(effect, "\\\\an\\d+", "")
    return effect
end

function ksy_character()
    local actor = characters[line.actor] and line.actor or "Blank"
    if config.JPN_only == true then
        return characters[actor] ..
            string.format("{\\fs%s}", ksy_pandora[line.styleref.fontname]["JPN_only"]["fs"])
    end
    return characters[actor]
end

function ksy_content()
    local content = line.text
    local effects = re.find(content, "\\{[^\\}]+\\}")
    if effects ~= nil then
        content = re.sub(content, "\\{[^\\}]+\\}", "{}")
    end
    if orgline.styleref["align"] == 7 then
        content = re.sub(content, "^([{}]*)(\\\\N)+", "\\1")
        line.text_stripped = re.sub(line.text_stripped, "^([{}]*)(\\\\N)+", "\\1")
    end
    if orgline.styleref["align"] == 7 and orgline.actor ~= "" then
        if orgline.layer ~= 9 then
            content = content .. "」"
            line.text_stripped = line.text_stripped .. "」"
        end
        content = re.sub(content, "^([\\{\\}]*)", "\\1「")
        line.text_stripped = "「" .. line.text_stripped
    end
    content = ksy.rep(content, " ", ksy_pandora[line.styleref.fontname]["contentrep"][" "])
    for search, replace in pairs(ksy_pandora[line.styleref.fontname]["contentrep"]) do
        if search ~= " " then
            content = ksy.rep(content, search, replace)
        end
    end
    if effects ~= nil then
        content = re.sub(content, "\\{\\}", function()
            return table.remove(effects, 1)["str"]
        end)
    end
    if orgline.styleref["align"] == 7 and re.find(content, "\\\\N") ~= nil then
        content = re.split(content, "\\\\N")
        content = content[j] ~= nil and content[j] or content[1]
    end
    return content
end

function ksy_style()
    if orgline.styleref["align"] == 7 then
        return
    end
    config["style"] = ksy_pandora[line.styleref.fontname]["style"]
    line.styleref = config["stylerefs"][config["style"]][line.styleref.name]
    config["styleref"]["Sx-jp"] = config["stylerefs"][config["style"]]["Sx-jp"]
    config["styleref"]["Sx-zh"] = config["stylerefs"][config["style"]]["Sx-zh"]
end

function ksy_layer()
    if line.styleref.name == "Sx-zh" then
        line.layer = 1
    end
    if orgline.styleref["align"] == 7 and re.find(line.text_stripped, "\\\\N") ~= nil then
        line.layer = j > #re.find(line.text_stripped, "\\\\N") + 1 and 1 or j
    end
end

function ksy_margin()
    if orgline.styleref["align"] == 7 then
        if line.margin_t == 0 and re.find(line.text_stripped, "\\\\N") ~= nil then
            line.margin_t = line.styleref.margin_t +
                ksy_pandora[line.styleref.fontname]["line_height"] * #re.find(line.text_stripped, "\\\\N")
            line.margin_t = line.margin_t +
                ksy_pandora[line.styleref.fontname]["line_height"] *
                ((j > #re.find(line.text_stripped, "\\\\N") + 1 and 1 or j) - 1)
        end
        return
    end
    if line.margin_t ~= 0 then
        if line.styleref.name == "Sx-zh" then
            local margin_t_diff = config["styleref"]["Sx-zh"]["margin_t"]
            margin_t_diff = margin_t_diff - config["styleref"]["Sx-jp"]["margin_t"]
            line.margin_t = line.margin_t + margin_t_diff
        end
    end
    if re.find(line.text, "\\\\an8") ~= nil then
        line.margin_t = line.margin_t + ksy_pandora[line.styleref.fontname]["margin_t"]
    end
    local dialog_start = ksy.sub(line.text_stripped, 1, 1)
    if dialog_start == "…" then
        line.margin_r = line.margin_r + _calwidth(dialog_start) + .5
    end
    if dialog_start == "「" then
        line.margin_r = line.margin_r + _calwidth(dialog_start) * .5 + .5
    end
    local dialog_end = ksy.sub(line.text_stripped, ksy.len(line.text_stripped), 1)
    if dialog_end == "？" or dialog_end == "！" or dialog_end == "…" then
        line.margin_l = line.margin_l + _calwidth(dialog_end) + .5
    end
    if dialog_end == "」" then
        line.margin_l = line.margin_l + _calwidth(dialog_end) * .5 + .5
    end
    if config.JPN_only == true then
        line.margin_t = (line.margin_t == 0 and line.styleref.margin_t or line.margin_t) +
            (re.find(line.text, "\\\\an8") ~= nil and ksy_pandora[line.styleref.fontname]["JPN_only"]["Yoffset2"] or ksy_pandora[line.styleref.fontname]["JPN_only"]["Yoffset"])
    end
end

function ksy_time()
    local start_time = line.start_time
    local end_time = line.end_time
    local start_frame = aegisub.frame_from_ms(start_time)
    local end_frame = aegisub.frame_from_ms(end_time)
    local start_time_fix = aegisub.ms_from_frame(start_frame)
    local end_time_fix = aegisub.ms_from_frame(end_frame)
    line.start_time = math.floor(start_time_fix / 10 + 0.5) * 10
    line.end_time = math.floor(end_time_fix / 10 + 0.5) * 10
end

function ksy_relocate(res)
    local relocates = { res }
    if orgline.styleref["align"] == 7 then
        for i = 1, (re.find(line.text_stripped, "\\\\N") ~= nil and #re.find(line.text_stripped, "\\\\N") or 0) + 1 do
            relocates[i] = res
        end
    end
    for i = 1, ksy.len(line.text_stripped) do
        for search, relocate in pairs(ksy_pandora[line.styleref.fontname]["relocate"]) do
            if ksy.sub(line.text_stripped, i, 1) == search then
                local befores = ksy.sub(line.text_stripped, 1, i - 1)
                local twidth, theight = _calwidth(befores),
                    ksy.str(line.text_stripped, line.styleref).geth()
                local x = _callineleft() + twidth
                if re.find(relocate["content"], "\\\\an5") ~= nil then
                    x = x + _calwidth(search) / 2
                elseif re.find(relocate["content"], "\\\\an6") ~= nil then
                    x = x + _calwidth(search)
                end
                local y = meta.res_y - theight / 2 - (line.margin_t == 0 and line.styleref.margin_t or line.margin_t)
                if orgline.styleref["align"] == 7 then
                    y = meta.res_y - y
                    y = y +
                        ksy_pandora[line.styleref.fontname]["line_height"] *
                        (re.find(befores, "\\\\N") ~= nil and #re.find(befores, "\\\\N") or 0)
                end
                x = x + relocate["Xoffset"]
                y = y + relocate["Yoffset"]
                if re.find(line.text, "\\\\an8") ~= nil then
                    y = meta.res_y - y + relocate["Yoffset"] + relocate["Yoffset2"]
                end
                relocates[#relocates + 1] = characters["Basic"] .. ksy_effect(false) ..
                    ksy_character() .. _getlineeffects() .. string.format(relocate["content"], x, y)
            end
        end
    end
    local furiganas = re.find(line.text, "\\\\furi\\(\\d+,.+?\\)")
    if config.JPN_only ~= true and ksy_pandora[line.styleref.fontname]["JPN_only"] ~= nil then
        furiganas = nil
    end
    if furiganas ~= nil then
        for _, part in pairs(furiganas) do
            local befores, length, furigana, fsc, fsp = "", 0, "", 100, 0
            part = string.sub(line.text, 1, part["first"] - 1) .. part["str"]
            match = re.match(part, "\\\\furi\\((\\d+),([^\\)]+?)\\)$")
            length = tonumber(match[2]["str"]) ~= nil and tonumber(match[2]["str"]) or 0
            furigana = match[3]["str"]
            if re.find(furigana, ",\\d+$") ~= nil then
                match = re.match(furigana, "(.+),(\\d+)$")
                furigana = match[2]["str"]
                fsc = tonumber(match[3]["str"]) ~= nil and tonumber(match[3]["str"]) or 0
                if re.find(furigana, ",\\d+$") ~= nil then
                    match = re.match(furigana, "(.+),(\\d+)$")
                    furigana = match[2]["str"]
                    fsp = fsc
                    fsc = tonumber(match[3]["str"]) ~= nil and tonumber(match[3]["str"]) or 0
                end
            end
            befores = re.sub(part .. "}", "\\{.+?\\}", "")
            local x = _callineleft() + _calwidth(befores) -
                _calwidth(ksy.sub(befores, ksy.len(befores) - length + 1, length)) / 2
            local y = meta.res_y - ksy.str(line.text_stripped, line.styleref).geth() -
                (line.margin_t == 0 and line.styleref.margin_t or line.margin_t)
            y = y + ksy_pandora[line.styleref.fontname]["furigana"]["Yoffset"]
            if re.find(line.text, "\\\\an8") ~= nil then
                y = meta.res_y - y + ksy_pandora[line.styleref.fontname]["furigana"]["Yoffset"] +
                    ksy_pandora[line.styleref.fontname]["furigana"]["Yoffset2"]
            elseif re.find(furigana, "[gjpqy]") ~= nil then
                y = y + ksy_pandora[line.styleref.fontname]["furigana"]["Yoffset3"]
            end
            relocates[#relocates + 1] = characters["Basic"] .. ksy_effect(false) ..
                ksy_character() .. _getlineeffects() ..
                string.format(ksy_pandora[line.styleref.fontname]["furigana"]["content"],
                    re.find(line.text, "\\\\an8") ~= nil and "8" or "2",
                    (fsc == 0 and 100 or fsc) * .01 *
                    (config.JPN_only == true and ksy_pandora[line.styleref.fontname]["JPN_only"]["fs"] or line.styleref.fontsize),
                    ksy_pandora[line.styleref.fontname]["furigana"]["fscx"] * line.styleref.scale_x * .01,
                    ksy_pandora[line.styleref.fontname]["furigana"]["fscy"] * line.styleref.scale_y * .01,
                    (fsp == 0 and "" or fsp), x, y, furigana)
        end
    end
    if orgline.styleref["align"] == 7 and orgline.actor ~= "" then
        fad = re.find(line.text, "\\\\fad") ~= nil and
            "{\\fad" .. re.match(line.text, "\\\\fad(\\([^\\)]+\\))")[2]["str"] .. "}" or ""
        relocates[#relocates + 1] = characters["actor"] .. fad .. line.actor
        if j == #relocates then
            restyle("Rx-actor")
        end
    end
    res = relocates[j]
    maxloop(#relocates)
    return res
end

function output_info(str)
    function _formatMilliseconds(milliseconds)
        local seconds = math.floor(milliseconds / 1000)
        local minutes = math.floor(seconds / 60)
        local hours = math.floor(minutes / 60)
        local remainingMinutes = minutes % 60
        local remainingSeconds = seconds % 60
        local millisecondsPart = milliseconds % 1000
        local formattedTime = string.format("%d:%02d:%02d.%02d", hours, remainingMinutes, remainingSeconds,
            millisecondsPart / 10)
        return formattedTime
    end

    local _info = _formatMilliseconds(line.start_time) .. ": " .. str
    ksy.debug(_info)
end

function ksy_check()
    if orgline.styleref["align"] == 7 then
        return
    end
    local width = _calwidth(line.text_stripped)
    if width > meta.res_x * .9 then
        output_info("※Invalid width")
    end
    if width > meta.res_x * .8 then
        output_info("Dangerous width")
    end
    local x = (meta.res_x - width) / 2
    if x - math.abs((line.margin_l - line.margin_r) / 2) < 0 then
        output_info("※Invalid edge")
    end
    if x - math.abs((line.margin_l - line.margin_r) / 2) < meta.res_x / 2 * (1 - .8) then
        output_info("Dangerous edge")
    end
    if aegisub.frame_from_ms(line.end_time) - aegisub.frame_from_ms(line.start_time) <= 6 then
        output_info("※Invalid duration")
    end
    if aegisub.frame_from_ms(line.end_time) - aegisub.frame_from_ms(line.start_time) <= config["check_duration"] then
        output_info("Dangerous duration")
    end
    local start_frame = aegisub.frame_from_ms(line.start_time)
    local end_frame = aegisub.frame_from_ms(line.end_time)
    local start_frame_min_diff = config["check_start_frame"]
    local end_frame_min_diff = config["check_end_frame"]
    if keyframes[start_frame] ~= true then
        for i = start_frame - start_frame_min_diff, start_frame + start_frame_min_diff, 1 do
            if keyframes[i] then
                output_info("Dangerous start_frame")
            end
        end
    end
    if keyframes[end_frame] ~= true then
        for i = end_frame - end_frame_min_diff, end_frame + end_frame_min_diff, 1 do
            if keyframes[i] then
                output_info("Dangerous end_frame")
            end
        end
    end
    if start_frame - prev_end_frame > 0 and start_frame - prev_end_frame <= 4 then
        output_info("※Invalid time_interval")
    end
    if start_frame - prev_end_frame > 0 and start_frame - prev_end_frame <= config["check_time_interval"] then
        output_info("Dangerous time_interval")
    end
    prev_end_frame = end_frame
end

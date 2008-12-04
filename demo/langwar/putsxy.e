--  file    : putsxy.e
--  author  : jiri babor
--  project : variation on David Alan Gay's putsxy include
--  tool    : euphoria 2.2
--  email   : jbabor@paradise.net.nz
--  http    : homepages.paradise.net.nz/~jbabor/euphoria.html
--  date    : 00-01-12

----------------------------------------------------------------------
--  The previous version of putsxy with Rob's enhancements did not  --
--  work in mode 19, could be initialized only while in graphics    --
--  mode and on my NT machine it took forever to load the images... --
----------------------------------------------------------------------

without type_check
without warning

include std/image.e
include std/dos/interrup.e
include std/dos/pixels.e
include vars.e

public constant CLEAR = -1  -- transparent background 'color'
public sequence font_index  -- for compatibility with original putsxy.e (Rob)

function rtrim(sequence s)
    -- trim (discard) trailing zeros of sequence s
    integer i
    i=length(s)
    while i do
    if s[i] then exit end if
    i=i-1
    end while
    return s[1..i]
end function -- rtrim

procedure load_font()   -- load 8x16 font
    sequence cb,regs
    integer a

    regs = repeat(0,10)
    regs[REG_AX]=#1130
    regs[REG_BX]=#600
    regs=dos_interrupt(#10,regs)
    a=#10*regs[REG_ES]+regs[REG_BP]
    font_index={}
    for i=1 to 256 do
    cb=rtrim(peek({a,16}))              -- char bytes, right trimmed
    for j=1 to length(cb) do
        cb[j]=rtrim(and_bits(cb[j],{128,64,32,16,8,4,2,1}) and 1)
    end for
    a += 16
    font_index = append(font_index,cb)
    end for
end procedure -- load_font

public procedure putsxy(
    sequence loc,   -- {x,y} text pointer, top left pixel
    sequence text,  -- text to be displayed
    atom fc,        -- foreground color
    atom bc,        -- background color
    atom dir        -- print direction
    )
    -- Display text at an {x,y} pixel location, using the specified
    -- foreground and background colors. If direction is 'd' then text is
    -- printed down the screen, otherwise it is printed across the screen.

    sequence c,cj,s
    integer col,len,row,u,x,y

    len = length(text)
    x = loc[1]
    y = loc[2]
    if dir = 'd' or dir = 'D' then      -- down, vertical print
    if bc = CLEAR then
        s = save_image({x,y},{x+7,y+16*len-1})
    else
        s = repeat(repeat(bc, 8), 16*len)
    end if
    row = 1
    for i=1 to len do
        c = font_index[1+text[i]]   -- trimmed char image
        u = row
        for j=1 to length(c) do
        cj = c[j]
        for k=1 to length(cj) do
            if cj[k] then
            s[u][k] = fc
            end if
        end for
        u += 1
        end for
        row += 16
    end for
    else                                -- across, left-to-right
    if bc = CLEAR then
        s = save_image({x,y},{x+8*len-1,y+15})
    else
        s = repeat(repeat(bc, 8*len), 16)
    end if
    col = 1
    for i=1 to len do
        c = font_index[1+text[i]]   -- trimmed char image
        for j=1 to length(c) do
        cj = c[j]
        u = col
        for k=1 to length(cj) do
            if cj[k] then
            s[j][u] = fc
            end if
            u += 1
        end for
        end for
        col += 8
    end for
    end if
    display_image({x,y},s)
end procedure -- putsxy

load_font()



import math, sys, os
INK="#4A3B2C"; HONEY="#F6C152"; HONEY_D="#E59F22"; HONEY_L="#FBDB8C"; MILK="#FFF9EC"
LEAF="#5DBB84"; LEAF_D="#3E9A66"; PEACH="#F4A0B4"; PEACH_D="#EC7290"; SKY="#8FC8F0"
SW=4.5
CX, CY = 120, 128

def f(v): return f"{v:.1f}".rstrip('0').rstrip('.')

def scallops(R, r, n, fill, extra=0, rot=0):
    s=[]
    for i in range(n):
        a=rot+2*math.pi*i/n
        s.append(f'<circle cx="{f(CX+R*math.cos(a))}" cy="{f(CY+R*math.sin(a))}" r="{f(r+extra)}" fill="{fill}"/>')
    s.append(f'<circle cx="{CX}" cy="{CY}" r="{f(R+extra)}" fill="{fill}"/>')
    return ''.join(s)

def pleats(n, rot=0):
    s=[]
    for i in range(n):
        a=rot+2*math.pi*(i+.5)/n
        x1,y1=CX+54*math.cos(a),CY+54*math.sin(a); x2,y2=CX+70*math.cos(a),CY+70*math.sin(a)
        s.append(f'<path d="M{f(x1)} {f(y1)}L{f(x2)} {f(y2)}" stroke="{HONEY_D}" stroke-width="3" stroke-linecap="round"/>')
    return ''.join(s)

def spark(x,y,s,c):
    return (f'<path d="M{f(x)} {f(y-s)}Q{f(x+s*.18)} {f(y-s*.18)} {f(x+s)} {f(y)}Q{f(x+s*.18)} {f(y+s*.18)} {f(x)} {f(y+s)}'
            f'Q{f(x-s*.18)} {f(y+s*.18)} {f(x-s)} {f(y)}Q{f(x-s*.18)} {f(y-s*.18)} {f(x)} {f(y-s)}Z" fill="{c}"/>')

def heart(x,y,s,fill=PEACH,stroke=True):
    d="M0 -4C-4 -14 -20 -12 -20 1C-20 12 -6 19 0 25C6 19 20 12 20 1C20 -12 4 -14 0 -4Z"
    st=f' stroke="{INK}" stroke-width="{f(3.5/s)}" stroke-linejoin="round"' if stroke else ''
    return f'<path transform="translate({f(x)} {f(y)}) scale({s})" d="{d}" fill="{fill}"{st}/>'

def ribbons(flutter=False):
    dl = 10 if flutter else 0
    L=f'<path d="M104 170L{86-dl} 240L{100-dl} 229L114 243L124 176Z" fill="{LEAF}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>'
    R=f'<path d="M136 170L{154+dl} 240L{140+dl} 229L126 243L116 176Z" fill="{LEAF_D}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>'
    return L+R

def body():
    return (scallops(64,19,16,INK,SW) + scallops(64,19,16,HONEY) + pleats(16)
            + f'<circle cx="{CX}" cy="{CY}" r="52" fill="{HONEY_D}"/>'
            + f'<circle cx="{CX}" cy="{CY}" r="46" fill="{MILK}" stroke="{INK}" stroke-width="3.5"/>'
            + f'<path d="M{CX-30} {CY-22}A38 38 0 0 1 {CX-8} {CY-38}" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" fill="none" opacity=".9"/>')

def sprout():
    return (f'<path d="M120 46Q119 34 124 24" stroke="{LEAF_D}" stroke-width="{SW}" stroke-linecap="round" fill="none"/>'
            f'<path d="M124 26Q140 8 156 16Q142 34 124 26Z" fill="{LEAF}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
            f'<path d="M126 25Q140 19 150 17" stroke="{LEAF_D}" stroke-width="2" stroke-linecap="round" fill="none"/>'
            f'<path d="M121 32Q108 22 98 28Q108 40 121 32Z" fill="{LEAF}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>')

def arm(x,y,rot=0):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({rot})">'
            f'<ellipse cx="0" cy="0" rx="13" ry="10" fill="{HONEY}" stroke="{INK}" stroke-width="{SW}"/></g>')

def parm(deg, d=95):
    a=math.radians(deg)
    return arm(CX+d*math.cos(a), CY+d*math.sin(a), deg)

def face(expr):
    cx, cy = CX, CY+2
    o=[]; ex=17; ey=cy-5
    sw=lambda w=4.5: f'stroke="{INK}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" fill="none"'
    def dot(x): return (f'<ellipse cx="{x}" cy="{ey}" rx="5.2" ry="7.2" fill="{INK}"/>'
                        f'<circle cx="{f(x+1.8)}" cy="{f(ey-2.8)}" r="2" fill="#FFFFFF"/>')
    def happy(x): return f'<path d="M{x-7} {ey+3}Q{x} {ey-8} {x+7} {ey+3}" {sw()}/>'
    def closed(x): return f'<path d="M{x-7} {ey}Q{x} {ey+7} {x+7} {ey}" {sw()}/>'
    if expr in ('praise','thanks','cheer','heart'):
        o += [happy(cx-ex), happy(cx+ex)]
    elif expr=='rest':
        o += [closed(cx-ex), closed(cx+ex)]
    elif expr=='puzzled':
        o += [dot(cx-ex), f'<path d="M{cx+ex-7} {ey}L{cx+ex+7} {ey}" {sw()}/>',
              f'<path d="M{cx-ex-8} {ey-14}L{cx-ex+6} {ey-11}" {sw(3.5)}/>']
    else:
        o += [dot(cx-ex), dot(cx+ex)]
    o += [f'<ellipse cx="{cx-31}" cy="{cy+9}" rx="8.5" ry="5.5" fill="{PEACH}" opacity=".85"/>',
          f'<ellipse cx="{cx+31}" cy="{cy+9}" rx="8.5" ry="5.5" fill="{PEACH}" opacity=".85"/>']
    my=cy+10
    if expr in ('praise','cheer'):
        o.append(f'<path d="M{cx-10} {my}Q{cx} {my+17} {cx+10} {my}Z" fill="{INK}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
                 f'<path d="M{cx-5} {my+8}Q{cx} {my+4} {cx+5} {my+8}Q{cx} {my+12} {cx-5} {my+8}Z" fill="{PEACH_D}"/>')
    elif expr=='puzzled':
        o.append(f'<path d="M{cx-9} {my+4}Q{cx-4.5} {my-1} {cx} {my+4}Q{cx+4.5} {my+9} {cx+9} {my+4}" {sw(3.5)}/>')
    elif expr=='rest':
        o.append(f'<path d="M{cx-5} {my+3}Q{cx} {my+7} {cx+5} {my+3}" {sw(3.5)}/>')
    else:
        o.append(f'<path d="M{cx-8} {my}Q{cx} {my+9} {cx+8} {my}" {sw(4)}/>')
    return ''.join(o)

def zz():
    return (f'<text x="170" y="62" font-family="Helvetica, Arial, sans-serif" font-weight="700" font-size="24" fill="{LEAF_D}">z</text>'
            f'<text x="190" y="42" font-family="Helvetica, Arial, sans-serif" font-weight="700" font-size="16" fill="{LEAF_D}">z</text>')

def motion(x,y,flip=1):
    return ''.join(f'<path d="M{f(x+flip*a)} {f(y+b)}l{f(flip*c)} {f(d)}" stroke="{INK}" stroke-width="3.5" stroke-linecap="round"/>'
                   for a,b,c,d in [(0,0,10,-6),(4,14,11,0)])

def build(name):
    pre=[]; post=[]; arms=[]; flutter=False; expr=name; rot=0
    if name=='normal':
        arms=[parm(155), parm(25)]
    elif name=='praise':
        arms=[parm(215), parm(-35)]; flutter=True
        pre=[spark(30,52,14,HONEY_D), spark(214,40,10,HONEY_D), spark(212,170,8,LEAF_D), spark(26,160,7,LEAF_D)]
    elif name=='thanks':
        arms=[parm(155), parm(25)]
        pre=[heart(206,48,.9), heart(34,72,.6)]
    elif name=='rest':
        arms=[parm(160,93), parm(20,93)]; post=[zz()]
    elif name=='cheer':
        arms=[parm(155), parm(-40)]
        pre=[spark(218,52,10,LEAF_D), spark(206,30,6,HONEY_D)]
    elif name=='puzzled':
        arms=[parm(155), parm(30,93)]
        pre=[f'<path d="M188 60q10 15 0 20q-10-5 0-20z" fill="{SKY}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>',
             f'<text x="24" y="70" font-family="Helvetica, Arial, sans-serif" font-weight="700" font-size="34" fill="{INK}">?</text>']
    elif name=='wave':
        expr='normal'; arms=[parm(155), parm(-45)]; pre=[motion(204,42)]
    elif name=='holdHeart':
        expr='heart'; arms=[]; 
        post=[heart(120,170,1.25), arm(96,180,-20), arm(144,180,20)]
        pre=[spark(36,60,9,PEACH), spark(206,54,11,PEACH)]
    elif name=='point':
        expr='normal'; arms=[parm(155), parm(0,97)]

    g = ''.join(pre)+ribbons(flutter)+''.join(arms)+body()+sprout()+face(expr)+''.join(post)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 256" width="240" height="256">{g}</svg>'

NAMES=['normal','praise','thanks','rest','cheer','puzzled','wave','holdHeart','point']
os.makedirs('svg',exist_ok=True)
for n in NAMES:
    open(f'svg/homette_{n}.svg','w').write(build(n))
sheet=''.join(f'<figure><img src="svg/homette_{n}.svg"><figcaption>{n}</figcaption></figure>' for n in NAMES)
open('sheet.html','w').write('<style>body{margin:0;background:#FBF8F2;display:flex;flex-wrap:wrap;gap:8px;padding:16px;width:1100px;font:14px sans-serif}figure{margin:0;background:#fff;border-radius:16px;padding:8px;text-align:center}img{width:240px}</style>'+sheet+
  '<div style="background:#161A17;display:flex;gap:8px;padding:8px;border-radius:16px">'+''.join(f'<img style="width:120px" src="svg/homette_{n}.svg">' for n in NAMES[:4])+'</div>')

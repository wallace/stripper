import math, sys
# Peeled banana icon. Peel strips grow out of the top edge of the unpeeled
# body (so the joins are continuous), fold outward and droop. The front strip
# is a trapezoid hanging down the face of the body.
# Usage: python3 Resources/banana.py -10 36 0.50 0.40 > Resources/AppIcon.svg
#   args: curve (negative = curves up), rotation in degrees, and how far the
#   left and right sides are peeled (fraction of the banana from the tip).
#   Add --menubar for the single-colour menu bar glyph: solid peel, outlined
#   fruit, cropped to the banana.
b, rot, tL, tR = (float(a) for a in sys.argv[1:5])
MENUBAR = "--menubar" in sys.argv
P0, P1, P2 = (54, 13), (54 - 2*b, 53), (54, 93)
SC, CEN = 8.9, (536, 500)
cr, sr = math.cos(math.radians(rot)), math.sin(math.radians(rot))

def frame(t):
    x = (1-t)**2*P0[0] + 2*t*(1-t)*P1[0] + t*t*P2[0]
    y = (1-t)**2*P0[1] + 2*t*(1-t)*P1[1] + t*t*P2[1]
    dx = 2*(1-t)*(P1[0]-P0[0]) + 2*t*(P2[0]-P1[0])
    dy = 2*(1-t)*(P1[1]-P0[1]) + 2*t*(P2[1]-P1[1])
    L = math.hypot(dx, dy); nx, ny = dy/L, -dx/L
    if nx < 0: nx, ny = -nx, -ny
    return x, y, nx, ny
PIV = (frame(0.52)[0] - 2, 53)
def W(p):
    x, y = p[0] - PIV[0], p[1] - PIV[1]
    return (CEN[0] + SC*(x*cr - y*sr), CEN[1] + SC*(x*sr + y*cr))
def Wv(v): return (v[0]*cr - v[1]*sr, v[0]*sr + v[1]*cr)   # rotate a direction

t0 = min(tL, tR)
def wf(t): return 2.6 + 4.6*min(1, t/0.32)**0.6
def wb(t): return 1.8 + 7.4*((1-t)/(1-t0))**0.38
def edge(t, s, w):
    x, y, nx, ny = frame(t); return W((x + s*nx*w, y + s*ny*w))
def rng(a, c, n=48): return [a + (c-a)*i/n for i in range(n+1)]
def poly(pts): return "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts) + " Z"
f = lambda p: f"{p[0]:.1f} {p[1]:.1f}"
def add(p, *vk):
    x, y = p
    for v, k in vk: x += v[0]*k; y += v[1]*k
    return (x, y)
def unit(v): m = math.hypot(*v); return (v[0]/m, v[1]/m)

out = []
# fruit
t_end = max(tL, tR) + 0.03
fl = [edge(t, -1, wf(t)) for t in rng(0.02, t_end)]
fr = [edge(t, 1, wf(t)) for t in rng(0.02, t_end)]
x, y, nx, ny = frame(0.02); w = wf(0.02); a0 = math.atan2(ny, nx)
cap = [W((x + w*math.cos(a0 - math.pi*k/12), y + w*math.sin(a0 - math.pi*k/12))) for k in range(13)]
out.append(f'<path d="{poly(fl + fr[::-1] + cap)}" fill="#FFF3D1"/>')
out.append(f'<path d="{poly([edge(t, 1, 0.45*wf(t)) for t in rng(0.02, t_end)] + fr[::-1])}" fill="#F1DDA8"/>')

# unpeeled body; its top edge runs from the left tear (tL) to the right tear (tR)
bl = [edge(t, -1, wb(t)) for t in rng(tL, 1)]
br = [edge(t, 1, wb(t)) for t in rng(tR, 1)]
out.append(f'<path d="{poly(bl + br[::-1])}" fill="#FFC928"/>')
out.append(f'<path d="{poly([edge(t, 1, 0.35*wb(t)) for t in rng(tR, 1)] + br[::-1])}" fill="#E9AA0A"/>')
x, y, _, _ = frame(0.995); nub = W((x, y))
out.append(f'<ellipse cx="{nub[0]:.1f}" cy="{nub[1]:.1f}" rx="19" ry="15" transform="rotate({rot:.0f} {nub[0]:.1f} {nub[1]:.1f})" fill="#4A2A06"/>')

def side_flap(t, s, L, outer, inner, out_k, down_k):
    """Strip rooted on the body's top edge between the rim edge and 40% in."""
    x, y, nx, ny = frame(t)
    o = Wv((s*nx, s*ny)); dx = 2*(1-t)*(P1[0]-P0[0]) + 2*t*(P2[0]-P1[0])
    dy = 2*(1-t)*(P1[1]-P0[1]) + 2*t*(P2[1]-P1[1]); u = unit(Wv((-dx, -dy)))  # toward fruit tip
    down = (0, 1)
    Ro, Ri = edge(t, s, wb(t)), edge(t, s, 0.4*wb(t))
    L *= SC
    T = add(Ro, (o, out_k*L), (down, down_k*L))
    # outer edge: rises a little from the rim, then arcs out and down to the tip
    c1, c2 = add(Ro, (u, 0.18*L), (o, 0.25*L)), add(T, (u, 0.55*L), (o, -0.05*L))
    # inner edge: back from the tip to the root, hugging closer to the body
    c3, c4 = add(T, (u, 0.35*L), (o, -0.25*L)), add(Ri, (u, 0.22*L), (o, 0.05*L))
    out.append(f'<path d="M{f(Ri)} L{f(Ro)} C{f(c1)} {f(c2)} {f(T)} C{f(c3)} {f(c4)} {f(Ri)} Z" fill="{outer}"/>')
    # pale inside of the peel, visible along the fold
    c5, c6 = add(T, (u, 0.48*L), (o, -0.12*L)), add(Ri, (u, 0.3*L), (o, 0.12*L))
    out.append(f'<path d="M{f(Ri)} L{f(Ro)} C{f(c1)} {f(c2)} {f(T)} C{f(c5)} {f(c6)} {f(Ri)} Z" fill="{inner}"/>')

side_flap(tL, -1, 85*tL, "#FFC928", "#FFEDA8", 0.72, 0.5)
side_flap(tR, 1, 85*tR, "#E9AA0A", "#FBDA6A", 0.6, 0.3)

# front strip: a trapezoid hanging down the face of the body from the tear
tF = (tL + tR)/2; tB = tF + 0.2
A, B = edge(tL, -1, 0.72*wb(tL)), edge(tR, 1, 0.72*wb(tR))
C, D = edge(tB, 1, 0.32*wb(tB)), edge(tB, -1, 0.32*wb(tB))
mA, mB = edge(tF + 0.1, -1, 0.6*wb(tF + 0.1)), edge(tF + 0.1, 1, 0.6*wb(tF + 0.1))
lip = edge(tB + 0.012, 1, 0)
out.append(f'<path d="M{f(A)} Q{f(mA)} {f(D)} Q{f(lip)} {f(C)} Q{f(mB)} {f(B)} Z" fill="#E6A600"/>')
h = lambda p, q, k: (p[0] + (q[0]-p[0])*k, p[1] + (q[1]-p[1])*k)
out.append(f'<path d="M{f(A)} Q{f(h(A, mA, 1))} {f(h(A, D, 0.5))} L{f(h(B, C, 0.5))} Q{f(h(B, mB, 1))} {f(B)} Z" fill="#F4C02A"/>')

def bbox(paths, pad):
    """Bounding box of our generated paths (absolute M/L/C/Q/Z), sampling curves."""
    import re
    xs, ys = [], []
    for d in paths:
        toks = re.findall(r"[MLCQZ]|-?[\d.]+", d)
        cur, i, cmd = (0, 0), 0, None
        while i < len(toks):
            if toks[i] in "MLCQZ": cmd = toks[i]; i += 1; continue
            n = {"M": 1, "L": 1, "Q": 2, "C": 3}[cmd]
            pts = [(float(toks[i + 2*k]), float(toks[i + 2*k + 1])) for k in range(n)]
            i += 2*n
            for k in range(11):
                t = k/10
                if n == 1: p = pts[0]
                elif n == 2: p = tuple((1-t)**2*cur[j] + 2*t*(1-t)*pts[0][j] + t*t*pts[1][j] for j in (0, 1))
                else: p = tuple((1-t)**3*cur[j] + 3*t*(1-t)**2*pts[0][j] + 3*t*t*(1-t)*pts[1][j] + t**3*pts[2][j] for j in (0, 1))
                xs.append(p[0]); ys.append(p[1])
            cur = pts[-1]
    return min(xs) - pad, min(ys) - pad, max(xs) - min(xs) + 2*pad, max(ys) - min(ys) + 2*pad

if MENUBAR:
    import re
    del out[1]                                   # fruit shading
    out = [re.sub(r'fill="[^"]+"', 'fill="#000"', l) for l in out]
    stroke = 44
    out[0] = out[0].replace('fill="#000"', f'fill="none" stroke="#000" stroke-width="{stroke}" stroke-linejoin="round"')
    x, y, w, h = bbox(re.findall(r' d="([^"]+)"', "\n".join(out)), stroke/2)
    print(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x:.0f} {y:.0f} {w:.0f} {h:.0f}" width="{w:.0f}" height="{h:.0f}">')
else:
    print('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">')
    print('<rect x="100" y="100" width="824" height="824" rx="185" fill="#2A78C8"/>')
print("\n".join(out)); print('</svg>')

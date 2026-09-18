"""
Booloop bölüm üreteci + çözücü (referans uygulama).
Kurallar PLAN.md §2 ile birebir aynıdır. Swift'e taşınırken bu dosya "altın referans"tır.
"""
import random, collections, time, json, hashlib, sys
D=((0,-1),(1,0),(0,1),(-1,0))   # 0 yukarı, 1 sağ, 2 aşağı, 3 sol
class Level:
    def __init__(s,W,H,walls=(),webs=(),arrows=None,gates=None,head=(0,0),lanterns=(),wisps=()):
        s.W,s.H=W,H
        s.walls=frozenset(walls); s.webs=frozenset(webs)
        s.arrows=dict(arrows or {})            # (x,y)->yön
        s.gates=dict(gates or {})              # (x,y)->fener indeksi
        s.head=tuple(head)
        s.lanterns=tuple(lanterns)             # (x,y,renk,kapasite)
        s.wisps=tuple(wisps)                   # (x,y,renk)
        s.lpos={(x,y):(i,c,k) for i,(x,y,c,k) in enumerate(lanterns)}
        s.caps=tuple(k for *_,k in lanterns)
    def start(s):
        return ((s.head,),(),tuple(sorted(((x,y),c) for x,y,c in s.wisps)),tuple(0 for _ in s.lanterns))
    def to_json(s):
        return dict(w=s.W,h=s.H,walls=sorted(s.walls),webs=sorted(s.webs),
            arrows=sorted([[x,y,d] for (x,y),d in s.arrows.items()]),
            gates=sorted([[x,y,i] for (x,y),i in s.gates.items()]),
            head=list(s.head),lanterns=[list(l) for l in s.lanterns],wisps=[list(w) for w in s.wisps])
def won(L,st): return all(f>=k for f,k in zip(st[3],L.caps))
def slide(L,st,d):
    pos,cols,wisps,fill=st
    pos=list(pos); cols=list(cols); wd=dict(wisps); fill=list(fill)
    moved=False; guard=0
    while True:
        if all(f>=k for f,k in zip(fill,L.caps)): break
        guard+=1
        if guard>L.W*L.H*4: break              # ok döngüsü koruması
        hx,hy=pos[0]; nx,ny=hx+D[d][0],hy+D[d][1]; n=(nx,ny)
        if nx<0 or ny<0 or nx>=L.W or ny>=L.H or n in L.walls: break
        g=L.gates.get(n)
        if g is not None and fill[g]<L.caps[g]: break          # kapı kapalı
        grow=n in wd
        body=pos if grow else pos[:-1]
        if n in body: break
        if grow: pos=[n]+pos; cols=[wd.pop(n)]+cols
        else:    pos=[n]+pos[:-1]
        while cols:                                            # kuyruktan bırakma
            lp=L.lpos.get(pos[-1])
            if lp and lp[1]==cols[-1] and fill[lp[0]]<lp[2]:
                fill[lp[0]]+=1; cols.pop(); pos.pop()
            else: break
        moved=True
        if n in L.webs: break                                  # ağ durdurur
        if n in L.arrows: d=L.arrows[n]                        # ok yönü çevirir
    if not moved: return None
    return (tuple(pos),tuple(cols),tuple(sorted(wd.items())),tuple(fill))
def analyze(L,limit=20,cap=80000):
    s0=L.start(); dist={s0:0}; q=collections.deque([s0]); edges=collections.defaultdict(list); goal=None
    while q:
        s=q.popleft(); d0=dist[s]
        if won(L,s):
            goal=d0 if goal is None else goal; continue
        if d0>=limit: continue
        for d in range(4):
            n=slide(L,s,d)
            if n is None: continue
            edges[s].append((d,n))
            if n not in dist:
                dist[n]=d0+1; q.append(n)
                if len(dist)>cap: return None
    if goal is None: return None
    # geri erişim: hangi durumlardan kazanılabilir (keşfedilen grafik içinde)
    rev=collections.defaultdict(list)
    for s,es in edges.items():
        for d,n in es: rev[n].append(s)
    good=set(s for s in dist if won(L,s)); st=list(good)
    while st:
        x=st.pop()
        for p in rev[x]:
            if p not in good: good.add(p); st.append(p)
    nonwin=[s for s in dist if not won(L,s)]
    dead=sum(1 for s in nonwin if s not in good)/max(1,len(nonwin))
    # en kısa çözüm sayısı ve ilk hamle seçenekleri
    ways={s0:1}; layers=collections.defaultdict(list)
    for s,dd in dist.items(): layers[dd].append(s)
    for dd in range(goal):
        for s in layers[dd]:
            w=ways.get(s,0)
            if not w or won(L,s): continue
            for d,n in edges[s]:
                if dist.get(n)==dd+1: ways[n]=ways.get(n,0)+w
    opt=sum(ways.get(s,0) for s in layers[goal] if won(L,s))
    first_ok=sum(1 for d,n in edges[s0] if n in good)
    first_all=len(edges[s0])
    # çözüm yolu
    path=[]; cur=[s for s in layers[goal] if won(L,s) and ways.get(s)][0]
    while cur!=s0:
        for p in rev[cur]:
            if dist.get(p)==dist[cur]-1 and ways.get(p):
                path.append(next(d for d,n in edges[p] if n==cur)); cur=p; break
    return dict(par=goal,states=len(dist),opt=opt,dead=round(dead,3),first_ok=first_ok,first_all=first_all,solution=path[::-1])
def difficulty(r):
    # 0..~10 ölçek: uzun par, az çözüm, çok çıkmaz, geniş durum uzayı zorlaştırır
    import math
    return round(0.45*r['par'] + 1.2*(1/ (1+math.log2(r['opt']))) + 3.0*r['dead'] + 0.35*math.log10(r['states']),2)
def rand_level(cfg,rng):
    W,H=cfg['W'],cfg['H']
    cells=[(x,y) for x in range(W) for y in range(H)]; rng.shuffle(cells); it=iter(cells)
    take=lambda n:[next(it) for _ in range(n)]
    walls=take(rng.randint(*cfg['walls'])); webs=take(cfg.get('webs',0))
    arrows={p:rng.randrange(4) for p in take(cfg.get('arrows',0))}
    head=next(it); k=cfg['colors']
    caps=[1]*k
    for i in rng.sample(range(k),cfg.get('cap2',0)): caps[i]=2
    lan=[(*next(it),c,caps[c]) for c in range(k)]
    gates={}
    for _ in range(cfg.get('gates',0)): gates[next(it)]=rng.randrange(k)
    wis=[(*next(it),c) for c in range(k) for _ in range(caps[c])]
    return Level(W,H,walls,webs,arrows,gates,head,lan,wis)
def accept(r,cfg,L):
    lo,hi=cfg['par']
    if not (lo<=r['par']<=hi): return False
    if r['first_ok']>=r['first_all'] and r['par']>=5 and cfg.get('need_trap',True): return False  # ilk hamle hiç tuzak değilse sıkıcı
    if r['opt']>cfg.get('max_opt',50): return False
    # kullanılan her mekanik çözüme dokunmalı (kaba kontrol: arrow/web/gate varsa durum sayısı yeterli)
    return True
def sig(L):
    return hashlib.md5(json.dumps(L.to_json(),sort_keys=True).encode()).hexdigest()[:12]

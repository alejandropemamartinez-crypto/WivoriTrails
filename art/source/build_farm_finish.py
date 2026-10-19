"""Original agricultural architecture and open paddock rails for v0.16."""
import bpy,math,importlib.util
from pathlib import Path
P=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('wivori_art',P/'build_assets.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)

def farm(kind):
    a.clean();bpy.data.orphans_purge(do_recursive=True)
    cream=a.mat('Painted ivory joinery','f3dfb8',.9);wood=a.mat('Warm oak','9d6848',.92)
    deep=a.mat('Interior shadow','38454b',.95);glass=a.mat('Sea glass window','94c9c4',.3)
    stone=a.mat('Sandstone footing','d0b98c',.93);gold=a.mat('Aged brass','e4b15d',.4,.25)
    wallcolor,roofcolor={'barn':('b7654f','5d8b98'),'coop':('d7a956','9d6b62'),'corral':('8ea99d','ba735b')}[kind]
    wall=a.mat('Weathered painted boards',wallcolor,.92);roof=a.mat('Glazed roof',roofcolor,.75)
    w=4.35;d=3.6;h=2.7;peak=3.85
    a.block('Beveled masonry base',(0,0,.17),(w+.25,d+.25,.34),stone,.11)
    a.block('Timber wall',(0,0,1.58),(w,d,2.5),wall,.09)
    a.mesh('Solid barn gables',[(-w/2,-d/2,h),(w/2,-d/2,h),(0,-d/2,peak-.12),(-w/2,d/2,h),(w/2,d/2,h),(0,d/2,peak-.12)],[(0,1,2),(3,5,4)],wall,False)
    a.roof(w+.70,d+.64,h,peak,roof,wood)
    for x in [-w/2,w/2]:
        for y in [-d/2,d/2]:a.block('Corner timber',(x,y,1.54),(.14,.14,2.55),cream,.025)
    for i in range(13):
        x=(i-6)*.33
        if abs(x)>1.02:a.block('Painted front slat',(x,-d/2-.025,1.54),(.028,.035,2.40),wood,.008)
    a.block('Doorway recess',(0,-d/2-.09,1.26),(1.90,.10,1.94),deep,.12)
    for x in [-1.02,1.02]:a.block('Door jamb',(x,-d/2-.16,1.24),(.16,.14,2.05),cream,.035)
    a.block('Door lintel',(0,-d/2-.16,2.30),(2.18,.18,.20),cream,.03)
    for s in [-1,1]:
        x=s*.50
        a.block('Lower stable door',(x,-d/2-.20,.81),(.94,.13,.99),wall,.05)
        a.tube('Stable door diagonal',[(x-.37,-d/2-.28,.40),(x+.37,-d/2-.28,1.21)],.045,cream,8)
        a.block('Lower door top cap',(x,-d/2-.22,1.28),(.98,.18,.10),cream,.03)
        a.bean('Door brass handle',(s*.10,-d/2-.30,1.04),(.07,.06,.16),gold,2,12,0)
        a.arch('Side arched window',(s*1.57,-d/2-.08,1.48),.52,.69,.08,cream)
        a.arch('Side turquoise glazing',(s*1.57,-d/2-.13,1.52),.39,.56,.04,glass)
        a.block('Window mullion',(s*1.57,-d/2-.17,1.84),(.035,.03,.55),cream,.008)
    a.arch('Loft window border',(0,-d/2-.07,2.73),.58,.55,.09,cream)
    a.arch('Loft glazing',(0,-d/2-.13,2.79),.43,.40,.04,glass)
    a.block('Loft sill',(0,-d/2-.16,2.72),(.70,.22,.10),cream,.03)
    for y in [-.8,.7]:
        a.block('Side window trim',(w/2+.04,y,1.8),(.14,.70,.76),cream,.05)
        a.block('Side window pane',(w/2+.12,y,1.82),(.03,.53,.59),glass,.02)
    hay=a.mat('Golden straw','dbc47a',.96)
    for s in [-1,1]:
        a.bean('Hay bale',(s*1.60,-1.9,.46),(.75,.68,.53),hay,3.6,20,1)
        a.tube('Hay bale twine',[(s*1.60-.24,-2.17,.30),(s*1.60-.24,-2.17,.65),(s*1.60-.24,-1.66,.65)],.014,wood,6)
    # Roof finial marks the farm from a distance; small weathervane is original.
    a.tube('Weather vane post',[(0,.25,peak),(0,.25,peak+.48)],.035,gold,10)
    a.mesh('Weather vane pennant',[(0,.25,peak+.48),(.47,.25,peak+.39),(0,.25,peak+.28)],[(0,1,2)],gold,False)
    a.save_export('farm_'+kind)
for kind in ['barn','coop','corral']:farm(kind)
a.clean();bpy.data.orphans_purge(do_recursive=True)
paint=a.mat('Fence warm ivory','ead8ad',.91);wood=a.mat('Fence cap oak','aa7954',.9)
for z in [-3,-1,1,3]:
    a.block('Tapered paddock post',(0,z,.56),(.19,.19,1.12),paint,.045)
    a.bean('Rounded post cap',(0,z,1.13),(.25,.25,.12),wood,3,16,1)
for height in [.37,.80]:a.block('Continuous open rail',(0,0,height),(.13,6.15,.15),paint,.035)
a.save_export('farm_fence')

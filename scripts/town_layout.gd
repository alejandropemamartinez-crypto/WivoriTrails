extends RefCounted

# One layout feeds buying, signage and navigation. Minimum distance between
# upgrade targets is five metres; two-metre lanes remain between footprints.
const UPGRADES={"helper":Vector3(4,0,10),"collector":Vector3(9.5,0,14.5),
	"bag":Vector3(-.8,0,20),"speed":Vector3(7,0,22.5),
	"checkout":Vector3(15,0,-3.5),"expand":Vector3(13.5,0,-19.5),
	"lock":Vector3(7.5,0,-9),"alarm":Vector3(15,0,6),
	"guard":Vector3(22,0,4),"pier":Vector3(23,0,14)}
const BANK=Vector3(-5,0,11)
const DOCK=Vector3(23,0,20)

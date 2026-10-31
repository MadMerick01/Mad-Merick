# Mad Merick — Design

Status: **design only, nothing built yet.** This doc collects what Rowan decided in the project thread on 31 Oct 2026 and marks what is still open. Open questions are tagged **❓ OPEN** inline and gathered in [Open questions](#open-questions) at the end.

## The pitch

A hardcore post-apocalyptic trucking game for BeamNG.drive, played across the real Australian outback on [BeamNG.Earth](https://github.com/TecnaGamer/BeamNG.Earth). You start in a fuel tanker built from the worst parts there are, at the edge of the desert near Adelaide, and you try to drive it 1,500 km north to Pine Gap. There are almost no stops. Every litre of fuel, every round of ammunition and every spare part comes from someone else: marauders in hot rods who chase you down, or other tankers you chase down yourself. You defend yourself with a VR revolver.

It is a separate game from Earth Freight (Worldwide Trucking Career). It reuses Earth Freight's plumbing by copying it, the same way Earth Freight was built from Earth Enduro, and changes the game on top: Earth Freight is about choosing what to carry for pay, Mad Merick is about surviving the road and taking what you need.

## The story

The year is 2027. The fuel wars have started. The world's fuel was rationed by an AI, and when the wars broke out it locked every reserve. The billionaires went into their bunkers, and everyone left outside turned on each other for whatever fuel was still moving on the roads.

The AI's ground link sits under Pine Gap, the old American base outside Alice Springs. Whoever reaches it can open the reserves. You can give them to everyone, or hand them to the bunker billionaires for a place inside.

The goal of the game is the thing you have been fighting over the whole way: fuel. That is why the AI story was picked over nuclear codes. **❓ OPEN — Q1:** confirm the AI story, and whether the ending is a choice (open the reserves or sell out) or a single ending.

Pine Gap is a real facility. Everything about it in the game is fiction.

## The route

The game is one very long trip up the Stuart Highway, about 1,500 km from the edge of the desert north of Adelaide to Pine Gap, which is roughly 18 hours of real driving. It is split into legs, and the game saves at the end of each one. Each leg is harder than the last.

| Leg | From → to | Roughly | Character |
|---|---|---|---|
| 1 | Edge of the desert → Port Augusta | 300 km | The learning leg. Few marauders, slow ones. |
| 2 | Port Augusta → Woomera | 180 km | The old rocket range. First tanker convoys. |
| 3 | Woomera → Coober Pedy | 370 km | Long empty stretch. Fuel gets tight. |
| 4 | Coober Pedy → NT border | 320 km | Coober Pedy is the underground town, the one safe place on the route. |
| 5 | NT border → Alice Springs | 290 km | Heavy marauder country. |
| 6 | Alice Springs → Pine Gap | 20 km | The final run to the base. |

Distances are rough, from the real highway, and to be checked in game. **❓ OPEN — Q2:** is 18 hours the right length, or should legs be shortened (for example by skipping ahead between legs)?

### The map

There is no map to build. BeamNG.Earth streams real terrain anywhere on the planet, and Earth Freight already has an index of real towns that covers Australia. Mad Merick fences play to the mainland: the ocean is the edge of the world, and the route keeps the player heading north.

Two things need testing before anything else, because the whole game depends on them:

- **Streaming at speed.** How fast Earth loads terrain while driving a tanker at 100 km/h for hours.
- **AI on Earth roads.** Whether BeamNG's AI can chase and flee on Earth's streamed roads, and on dirt beside them.

## Core loop

1. **Drive north.** Burn fuel. The tanker is slow and drinks a lot.
2. **Get found, or go hunting.** Marauders in hot rods come for your tank. Or you spot a tanker convoy and go after it.
3. **Fight.** Shoot out tyres, shoot engines, ram. A car is **down** when it stops: flat tyres, heavy damage or a dead engine.
4. **Loot.** Pull up next to a downed car and take its fuel, ammo and parts.
5. **Siphon.** Fuel takes time to move from a downed tanker into yours, and its escorts keep coming while you wait. This is where the tension comes from.
6. **Rebuild.** Swap the parts you looted onto your own truck, one at a time.
7. **Reach the end of the leg** and save.

There is **no buying or selling for now** (Rowan, 31 Oct). Everything comes from marauders and tankers.

## The tanker

You start in a fuel tanker with the worst parts: a slow leak in the tank, bald tyres, soft brakes and a tired engine. Progression is rebuilding that truck, not buying a bigger vehicle.

The tank is three things at once:

- **Your fuel.** The truck's own tank keeps you moving.
- **Your store.** The cargo tank holds the fuel you have taken. You top up your own tank from it.
- **The target.** It is what every marauder is after.

Running dry ends the game, unless you can raid your way out. **❓ OPEN — Q3:** what "game over" means. Options: restart the leg from its save, lose the truck and start over from Adelaide, or permadeath with one save.

**❓ OPEN — Q4:** which tanker? It needs to be a BeamNG truck with a fluid tank, slow enough that you cannot outrun hot rods, and sturdy enough to survive a ramming.

## Marauders

Baddies in hot rods who chase your truck using BeamNG's AI in chase mode. They spawn behind or ahead of you, close in, and ram or box you in. Early legs have few and weak ones; later legs have more, faster ones, and some work in packs.

Each downed marauder carries a little loot: some fuel, some ammo, sometimes a part.

The chase code is not in Earth Freight. It is the CarKov hostiles in Earth Enduro, which will be copied over and given hot rods. **❓ OPEN — Q5:** which hot rods (vanilla configs, or mod cars), and do marauders also shoot back, or only ram?

## Tankers

Other tankers drive the highway, alone or in convoys with escorts. When they see you coming they run, using BeamNG's AI in flee mode. You stop them by shooting out their tyres or forcing them off the road.

A downed tanker is the big prize: a lot of fuel, but it takes time to siphon, and the escorts arrive while you do. **❓ OPEN — Q6:** how many litres a siphon moves a second, and whether you can drive away mid-siphon with what you have so far.

## The VR revolver

Rowan's [BeamngVRcontrollerPoses](https://github.com/MadMerick01/BeamngVRcontrollerPoses) mod. Hold the right grip to draw the revolver, pull the trigger to shoot.

What it does today:

- Each shot is a ray. The car it hits gets pushed and dented where it was hit.
- A hit near a wheel hub flattens that tyre, so shooting out a fleeing tanker's tyres already works.
- Every hit reports back to the game with which car was hit and where.
- There are no drivers to hit, so a car is stopped by its tyres, its damage or its engine.

What it needs for Mad Merick (two small changes in the pistol mod, so Mad Merick never touches its code):

1. **Ammo.** It currently fires without limit, every 0.12 s. It needs a six-round cylinder, a reload, and a way for Mad Merick to refuse a shot when you are out of ammo.
2. **A hit event** other mods can listen to, so Mad Merick hears every hit and decides when a marauder is down.

Mad Merick needs the pistol installed. **❓ OPEN — Q7:** is the game playable without VR (for example, shooting from the camera with a key or mouse), or is it VR only?

## What carries over from Earth Freight

Copied, then adapted. Nothing is shared at run time.

| Earth Freight | In Mad Merick |
|---|---|
| `earthAdapter.lua`, `location.lua`, `odometer.lua` | As is: where you are on Earth, distance driven, teleports. |
| `places.lua` and the tiles | Cut down to Australia, used for the route and leg ends. |
| `fuel.lua` | As is: reads and sets the tank. Gains siphoning and the leak. |
| `cargo.lua` | Adapted: the cargo tank and its weight on the truck. |
| `garage.lua`, `workshop.lua` | Adapted: fitting looted parts instead of buying them. |
| `persistence.lua` | Adapted: saves hold the leg, the truck, fuel, ammo and spare parts. |
| `punctures.lua` | As is: the road still bursts tyres. |
| `hud.lua` and the UI | Adapted: fuel, ammo, leg progress and threats. |

## What gets dropped

The job board and pay, towns and their boards, used cars, the helicopter, flights, shipping, beacons and the dangerous road contracts. Money goes too, since there is no buying or selling.

## What gets built fresh

- **Marauders:** spawning, chase AI (from Earth Enduro's CarKov), when a car counts as down, and loot.
- **Tankers and convoys:** spawning, flee AI, escorts.
- **Siphoning:** moving fuel over time from a downed tanker.
- **Ammo** and the hookup to the pistol's hit event.
- **Legs:** the route, the leg ends, saving, and difficulty rising leg by leg.
- **The story:** an intro, something at each leg end, and the ending at Pine Gap.

## First playable slice

The smallest version that shows whether the game is fun:

1. Start in the rust tanker at the edge of the desert, on leg 1.
2. One marauder in a hot rod chases you.
3. The VR revolver can stop it, with ammo counting down.
4. Pull up to the downed car and loot its fuel and ammo.
5. One AI tanker that flees, and a siphon from it once it is stopped.

Before step 2, test BeamNG's chase and flee AI on Earth's roads, because the rest depends on it.

## Open questions

- **Q1:** AI story confirmed? One ending or a choice at Pine Gap?
- **Q2:** Is about 18 hours of driving the right length, or should legs be shorter?
- **Q3:** What happens when you run dry or get wrecked: restart the leg, start over, or permadeath?
- **Q4:** Which BeamNG truck is the starting tanker?
- **Q5:** Which hot rods for marauders, and do they shoot back or only ram?
- **Q6:** Siphon speed, and can you drive off mid-siphon?
- **Q7:** VR only, or a non-VR way to shoot too?

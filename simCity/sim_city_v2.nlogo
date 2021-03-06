breed [ cars car ]
breed [ houses house ]
breed [ water-towers water-tower ]
breed [ factories factory ]
breed [ drops drop ]
breed [ recruteurs ]

globals [ water-need pib ]
houses-own [ number water ]
drops-own [ capacity ]
factories-own [ employees ]
patches-own [ dist ]

to setup
  ca
  set population 0 ;population globale
  set water-need 3 ;besoin en eau d'une personne
  set pib 0 ;au début le pib est nul
  ask patches [ set pcolor yellow ]
  ask patches with [ pxcor = max-pxcor or pxcor = min-pxcor or pycor = max-pycor or pycor = min-pycor or pxcor = 0 or pycor = 0 or pycor = max-pycor / 2 or pycor = max-pycor / (- 2) ] [ set pcolor grey ] ;génération des routes
  crt 50 [
    set shape "tree"
    set size 2
    set color green
    move-to one-of patches with [ pcolor = yellow and not any? turtles-here ]
  ]
  generate-houses
  generate-water-tower
  generate-factory
  reset-ticks
end


;crée nb-houses maisons et les place aléatoirement sur un patch jaune à côté d'un patch gris
to generate-houses
  create-houses nb-houses [
    set shape "house"
    set size 2
    set number random 6 + 1 ;à l'initialisation le nombre d'habitants est entre 1 et 6
    set population population + number ;qu'on ajoute à la population globale
    set water number * water-need + water-need - 1 ;initialisation du nombre d'unités d'eau en fonction du nombre d'habitants
    move-to one-of patches with [ pcolor = yellow and any? neighbors with [ pcolor = grey ] and not any? turtles-here ] ;placement sur un patch jaune à côté d'un patch gris s'il n y a rien sur le patch
    face one-of (neighbors4 with [ pcolor = grey ]) ;la maison est face à la route
  ]
end


;crée un chateau d'eau et le place aléatoirement sur un patch jaune à côté d'un patch gris
to generate-water-tower
  create-water-towers 1 [
    set shape "cylinder"
    set size 3
    set color blue
    move-to one-of patches with [ pcolor = yellow and any? neighbors with [ pcolor = grey ] and not any? turtles-here ] ;placement sur un patch jaune à côté d'un patch gris s'il n y a rien sur le patch
    face one-of (neighbors4 with [ pcolor = grey ]) ;le château d'eau est face à la route
  ]
end


;crée une usine et la place aléatoirement sur un patch jaune à côté d'un patch gris
to generate-factory
  create-factories 1 [
    set employees 0 ;au début le nombre d'employés est nul
    set shape "factory"
    set size 4
    set color brown
    move-to one-of patches with [ pcolor = yellow and any? neighbors with [ pcolor = grey ] and not any? turtles-here ] ;placement sur un patch jaune à côté d'un patch gris s'il n y a rien sur le patch
    face one-of (neighbors4 with [ pcolor = grey ]) ;l'usine est face à la route
  ]
end


;permet d'avancer au hasard sur les routes
to advance
  let f patch-ahead 1 ;le patch en face
  let r patch-right-and-ahead 90 1 ;le patch à droite
  let l patch-left-and-ahead 90 1 ;le patch à gauche
  ifelse (not any? ((patch-set f r l) with [ pcolor = grey ])) ;s'il n'y a pas de route ni en face ni à gauche ni à droite
    [ right 180 ] ;demi tour
    [ move-to one-of ((patch-set f r l) with [ pcolor = grey ]) ;sinon déplacement sur un des patches autour
    ifelse (patch-here = r)
      [ right 90 ]
      [ if (patch-here = l) [ left 90 ] ]
   ]
end


;comportement d'une maison
to decide-for-houses
  if (water > 0 and ticks mod 100 = 0) [ set water water - 1 ] ;tous les 100 tours consommation d'une unité eau

  if (number > 0 and water < number * water-need) [ ;s'il n y a pas assez d'eau pour les habitants de la maison
    set number number - 1 ;décrémentation du nombre d'habitants
    set population population - 1 ;décrémentation de la population globale
  ]
  if (number < 10 and water = (number + 1) * water-need) [ ;s'il y assez d'eau pour un habitant en plus et que la limite du nombre d'habitants n'est pas atteinte
    set number number + 1 ;incrémentation du nombre d'habitants
    set population population + 1 ;incrémentation de la population globale
  ]
end


;comportement des voitures
to decide-for-cars
  advance ;avance au hasard
  let f patch-ahead 1 ;le patch en face
  let r patch-right-and-ahead 90 1 ;le patch à droite
  let l patch-left-and-ahead 90 1 ;le patch à gauche
  if (any? factories-on (patch-set f r l)) [ ;s'il y a une usine à côté
     ask factories with [ employees < 100 ] [ set employees employees + 1 ] ;incrémentation du nombre d'employés dans l'usine si le nombre d'employés est inférieur à 100
  ]
end


;comportement d'une goutte d'eau
to decide-for-drops
  if (capacity < 0) [ die ] ;si la goutte d'eau n'a plus d'unité d'eau alors elle disparaît
  advance ;elle avance au hasard sur les routes
  let f patch-ahead 1
  let r patch-right-and-ahead 90 1
  let l patch-left-and-ahead 90 1
  if (any? houses-on (patch-set f r l)) [ ;s'il y a une ou des maisons autour
      ask houses-on neighbors4 [
        if ([water] of self < 10 * water-need + water-need - 1) [ ;si la limite d'eau n'est pas atteinte
          set water water + 1 ;ajout d'une unité d'eau dans les maisons autour
        ]
      ]
      set capacity capacity - (count houses-on (patch-set f r l)) ;diminution d'autant d'unités d'eau qu'elle en a distribuées
  ]
end


;comportement du château d'eau
to decide-for-water-towers
  if (ticks mod drop-freq = 0) [ ;tous les drop-freq tours
    hatch-drops 1 [ ;création d'une goutte d'eau
      set shape "drop"
      set color blue
      set size 2
      set capacity 10  ;capacité de 10 unités d'eau
      move-to patch-ahead 1 ;la goutte d'eau est créée sur le patch en face du château d'eau
    ]
  ]
end


;comportement de l'usine
to decide-for-factories
  if (ticks mod scout-freq = 0) [ ;tous les scout-freq tours
    hatch-recruteurs 1 [ ;création d'un recruteur
      set shape "person"
      set color [color] of one-of factories ;de la même couleur que l'usine
      set size 2
      move-to patch-ahead 1 ;le recruteur est créée sur le patch en face de l'usine
    ]
  ]
  if (ticks mod retire-freq = 0 and employees > 0) [ ;tous les retire-freq ticks et si le nombre d'employés est > 0
    set employees employees - 1 ;décrémentation du nombre d'employés
  ]
  if (ticks mod prod-freq = 0) [ ;tous les prod-freq tours
    set pib pib + employees ;création d'autant de richesses qu'il y a d'employés, richesses qu'on ajoute au pib
  ]
end


;comportement d'un recruteur
to decide-for-recruteurs
  advance ;le recruteur avance au hasard sur les routes
  let f patch-ahead 1 ;le patch en face
  let r patch-right-and-ahead 90 1 ;le patch à droite
  let l patch-left-and-ahead 90 1 ;le patch à gauche
  ifelse (any? houses-on (patch-set f)) ;s'il y a une maison sur le patch en face
  [
    if (random 10 < 3 and [number] of one-of houses-on f > 0) [ ;probabilité de 30% de recruter une personne s'il y a au moins une personne dans la maison
      hatch-cars 1 [ ;création d'une voiture
        set shape "car"
        set color [color] of one-of houses-on f ;même couleur que la maison d'où elle sort
        move-to patch-here
      ]
      die ;le recruteur disparaît
    ]
  ]
  [
    ifelse (any? houses-on (patch-set r)) [ ;s'il y a une maison sur le patch à droite
      if (random 10 < 3 and [number] of one-of houses-on r > 0) [ ;probabilité de 30% de recruter une personne s'il y a au moins une personne dans la maison
        hatch-cars 1 [ ;création d'une voiture
          set shape "car"
          set color [color] of one-of houses-on r ;même couleur que la maison d'où elle sort
          move-to patch-here
        ]
        die ;le recruteur disparaît
      ]
    ]
    [
      if (any? houses-on (patch-set l)) [ ;s'il y a une maison sur le patch à gauche
        if (random 10 < 3 and [number] of one-of houses-on l > 0) [ ;probabilité de 30% de recruter une personne s'il y a au moins une personne dans la maison
          hatch-cars 1 [ ;création d'une voiture
            set shape "car"
            set color [color] of one-of houses-on l ;même couleur que la maison d'où elle sort
            move-to patch-here
          ]
          die ;le recruteur disparaît
        ]
      ]
    ]
  ]
end


to go
  ask water-towers [ decide-for-water-towers ]
  ask drops [ decide-for-drops ]
  ask factories [ decide-for-factories ]
  ask recruteurs [ decide-for-recruteurs ]
  ask cars [ decide-for-cars ]
  ask houses [ decide-for-houses ]
  ask houses [ set label number ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
713
27
1742
742
30
20
16.705
1
10
1
1
1
0
0
0
1
-30
30
-20
20
0
0
1
ticks
30.0

BUTTON
16
116
79
149
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
14
70
77
103
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
135
39
370
72
nb-houses
nb-houses
10
100
50
1
1
NIL
HORIZONTAL

PLOT
73
259
579
588
population
ticks
population
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot population"

INPUTBOX
133
110
370
170
population
21
1
0
Number

SLIDER
414
41
586
74
drop-freq
drop-freq
0
100
20
10
1
NIL
HORIZONTAL

SLIDER
413
87
585
120
scout-freq
scout-freq
0
1000
100
100
1
NIL
HORIZONTAL

SLIDER
412
134
584
167
retire-freq
retire-freq
100
1000
500
500
1
NIL
HORIZONTAL

SLIDER
414
180
586
213
prod-freq
prod-freq
100
1000
200
200
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@

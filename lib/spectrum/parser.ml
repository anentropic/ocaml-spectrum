exception InvalidStyleName of string
exception InvalidColorName of string

module Style = struct
  type t =
    | Bold
    | Dim
    | Italic
    | Underline
    | Blink
    | RapidBlink
    | Inverse
    | Hidden
    | Strikethru

  (*
    see: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
  *)
  let of_string = function
    | "bold" -> Bold
    | "dim" -> Dim
    | "italic" -> Italic
    | "underline" -> Underline
    | "blink" -> Blink
    | "rapid-blink"-> RapidBlink
    | "inverse" -> Inverse
    | "hidden" -> Hidden
    | "strikethru" -> Strikethru
    | name -> raise @@ InvalidStyleName name

  let to_code = function
    | Bold -> 1
    | Dim -> 2
    | Italic -> 3
    | Underline -> 4
    | Blink -> 5
    | RapidBlink-> 5
    | Inverse -> 7
    | Hidden -> 8
    | Strikethru -> 9
end

module Basic = struct
  type t =
    | Black
    | Red
    | Green
    | Yellow
    | Blue
    | Magenta
    | Cyan
    | White
    | BrightBlack
    | BrightRed
    | BrightGreen
    | BrightYellow
    | BrightBlue
    | BrightMagenta
    | BrightCyan
    | BrightWhite

  (*
    see: https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
    the non-bright color names have been prefixed with "basic-" to
    disambiguate from xterm-256 colors of the same name
  *)
  let of_string = function
    | "basic-black" -> Black
    | "basic-red" -> Red
    | "basic-green" -> Green
    | "basic-yellow" -> Yellow
    | "basic-blue" -> Blue
    | "basic-magenta" -> Magenta
    | "basic-cyan" -> Cyan
    | "basic-white" -> White
    | "basic-grey" -> BrightBlack
    | "bright-black" -> BrightBlack
    | "bright-red" -> BrightRed
    | "bright-green" -> BrightGreen
    | "bright-yellow" -> BrightYellow
    | "bright-blue" -> BrightBlue
    | "bright-magenta" -> BrightMagenta
    | "bright-cyan" -> BrightCyan
    | "bright-white" -> BrightWhite
    | name -> raise @@ InvalidColorName name

  (* these are the fg codes, +10 to get bg codes *)
  let to_code = function
    | Black -> 30
    | Red -> 31
    | Green -> 32
    | Yellow -> 33
    | Blue -> 34
    | Magenta -> 35
    | Cyan -> 36
    | White -> 37
    | BrightBlack -> 90
    | BrightRed -> 91
    | BrightGreen -> 92
    | BrightYellow -> 93
    | BrightBlue -> 94
    | BrightMagenta -> 95
    | BrightCyan -> 96
    | BrightWhite -> 97

  let to_color = function
    | Black -> Color.of_rgb 0 0 0
    | Red -> Color.of_rgb 128 0 0
    | Green -> Color.of_rgb 0 128 0
    | Yellow -> Color.of_rgb 128 128 0
    | Blue -> Color.of_rgb 0 0 128
    | Magenta -> Color.of_rgb 128 0 128
    | Cyan -> Color.of_rgb 0 128 128
    | White -> Color.of_rgb 128 128 128
    | BrightBlack -> Color.of_rgb 192 192 192
    | BrightRed -> Color.of_rgb 255 0 0
    | BrightGreen -> Color.of_rgb 0 255 0
    | BrightYellow -> Color.of_rgb 255 255 0
    | BrightBlue -> Color.of_rgb 0 0 255
    | BrightMagenta -> Color.of_rgb 255 0 255
    | BrightCyan -> Color.of_rgb 0 255 255
    | BrightWhite -> Color.of_rgb 255 255 255

  let color_list = [
    Color.of_rgb 0 0 0;
    Color.of_rgb 128 0 0;
    Color.of_rgb 0 128 0;
    Color.of_rgb 128 128 0;
    Color.of_rgb 0 0 128;
    Color.of_rgb 128 0 128;
    Color.of_rgb 0 128 128;
    Color.of_rgb 128 128 128;
    Color.of_rgb 192 192 192;
    Color.of_rgb 255 0 0;
    Color.of_rgb 0 255 0;
    Color.of_rgb 255 255 0;
    Color.of_rgb 0 0 255;
    Color.of_rgb 255 0 255;
    Color.of_rgb 0 255 255;
    Color.of_rgb 255 255 255;
  ]
end

module Xterm256 = struct
  type t =
    | Black
    | Maroon
    | Green
    | Olive
    | Navy
    | Purple
    | Teal
    | Silver
    | Grey
    | Red
    | Lime
    | Yellow
    | Blue
    | Fuchsia
    | Aqua
    | White
    | Grey0
    | NavyBlue
    | DarkBlue
    | Blue3a
    | Blue3b
    | Blue1
    | DarkGreen
    | DeepSkyBlue4a
    | DeepSkyBlue4b
    | DeepSkyBlue4c
    | DodgerBlue3
    | DodgerBlue2
    | Green4
    | SpringGreen4
    | Turquoise4
    | DeepSkyBlue3a
    | DeepSkyBlue3b
    | DodgerBlue1
    | Green3a
    | SpringGreen3a
    | DarkCyan
    | LightSeaGreen
    | DeepSkyBlue2
    | DeepSkyBlue1
    | Green3b
    | SpringGreen3b
    | SpringGreen2a
    | Cyan3
    | DarkTurquoise
    | Turquoise2
    | Green1
    | SpringGreen2b
    | SpringGreen1
    | MediumSpringGreen
    | Cyan2
    | Cyan1
    | DarkRed1
    | DeepPink4a
    | Purple4a
    | Purple4b
    | Purple3
    | BlueViolet
    | Orange4a
    | Grey37
    | MediumPurple4
    | SlateBlue3a
    | SlateBlue3b
    | RoyalBlue1
    | Chartreuse4
    | DarkSeaGreen4a
    | PaleTurquoise4
    | SteelBlue
    | SteelBlue3
    | CornflowerBlue
    | Chartreuse3a
    | DarkSeaGreen4b
    | CadetBlue2
    | CadetBlue1
    | SkyBlue3
    | SteelBlue1a
    | Chartreuse3b
    | PaleGreen3a
    | SeaGreen3
    | Aquamarine3
    | MediumTurquoise
    | SteelBlue1b
    | Chartreuse2a
    | SeaGreen2
    | SeaGreen1a
    | SeaGreen1b
    | Aquamarine1a
    | DarkSlateGray2
    | DarkRed2
    | DeepPink4b
    | DarkMagenta1
    | DarkMagenta2
    | DarkViolet1a
    | Purple1a
    | Orange4b
    | LightPink4
    | Plum4
    | MediumPurple3a
    | MediumPurple3b
    | SlateBlue1
    | Yellow4a
    | Wheat4
    | Grey53
    | LightSlateGrey
    | MediumPurple
    | LightSlateBlue
    | Yellow4b
    | DarkOliveGreen3a
    | DarkGreenSea
    | LightSkyBlue3a
    | LightSkyBlue3b
    | SkyBlue2
    | Chartreuse2b
    | DarkOliveGreen3b
    | PaleGreen3b
    | DarkSeaGreen3a
    | DarkSlateGray3
    | SkyBlue1
    | Chartreuse1
    | LightGreen2
    | LightGreen3
    | PaleGreen1a
    | Aquamarine1b
    | DarkSlateGray1
    | Red3a
    | DeepPink4c
    | MediumVioletRed
    | Magenta3a
    | DarkViolet1b
    | Purple1b
    | DarkOrange3a
    | IndianRed1a
    | HotPink3a
    | MediumOrchid3
    | MediumOrchid
    | MediumPurple2a
    | DarkGoldenrod
    | LightSalmon3a
    | RosyBrown
    | Grey63
    | MediumPurple2b
    | MediumPurple1
    | Gold3a
    | DarkKhaki
    | NavajoWhite3
    | Grey69
    | LightSteelBlue3
    | LightSteelBlue
    | Yellow3a
    | DarkOliveGreen3
    | DarkSeaGreen3b
    | DarkSeaGreen2
    | LightCyan3
    | LightSkyBlue1
    | GreenYellow
    | DarkOliveGreen2
    | PaleGreen1b
    | DarkSeaGreen5b
    | DarkSeaGreen5a
    | PaleTurquoise1
    | Red3b
    | DeepPink3a
    | DeepPink3b
    | Magenta3b
    | Magenta3c
    | Magenta2a
    | DarkOrange3b
    | IndianRed1b
    | HotPink3b
    | HotPink2
    | Orchid
    | MediumOrchid1a
    | Orange3
    | LightSalmon3b
    | LightPink3
    | Pink3
    | Plum3
    | Violet
    | Gold3b
    | LightGoldenrod3
    | Tan
    | MistyRose3
    | Thistle3
    | Plum2
    | Yellow3b
    | Khaki3
    | LightGoldenrod2a
    | LightYellow3
    | Grey84
    | LightSteelBlue1
    | Yellow2
    | DarkOliveGreen1a
    | DarkOliveGreen1b
    | DarkSeaGreen1
    | Honeydew2
    | LightCyan1
    | Red1
    | DeepPink2
    | DeepPink1a
    | DeepPink1b
    | Magenta2b
    | Magenta1
    | OrangeRed1
    | IndianRed1c
    | IndianRed1d
    | HotPink1a
    | HotPink1b
    | MediumOrchid1b
    | DarkOrange
    | Salmon1
    | LightCoral
    | PaleVioletRed1
    | Orchid2
    | Orchid1
    | Orange1
    | SandyBrown
    | LightSalmon1
    | LightPink1
    | Pink1
    | Plum1
    | Gold1
    | LightGoldenrod2b
    | LightGoldenrod2c
    | NavajoWhite1
    | MistyRose1
    | Thistle1
    | Yellow1
    | LightGoldenrod1
    | Khaki1
    | Wheat1
    | Cornsilk1
    | Grey100
    | Grey3
    | Grey7
    | Grey11
    | Grey15
    | Grey19
    | Grey23
    | Grey27
    | Grey30
    | Grey35
    | Grey39
    | Grey42
    | Grey46
    | Grey50
    | Grey54
    | Grey58
    | Grey62
    | Grey66
    | Grey70
    | Grey74
    | Grey78
    | Grey82
    | Grey85
    | Grey89
    | Grey93

  (*
    see: https://www.ditig.com/256-colors-cheat-sheet
  *)
  let of_string = function
    | "black" -> Black
    | "maroon" -> Maroon
    | "green" -> Green
    | "olive" -> Olive
    | "navy" -> Navy
    | "purple" -> Purple
    | "teal" -> Teal
    | "silver" -> Silver
    | "grey" -> Grey
    | "red" -> Red  (* potential name clash with mis-matching Basic color *)
    | "lime" -> Lime
    | "yellow" -> Yellow  (* potential name clash with mis-matching Basic color *)
    | "blue" -> Blue  (* potential name clash with mis-matching Basic color *)
    | "fuchsia" -> Fuchsia
    | "aqua" -> Aqua
    | "white" -> White  (* potential name clash with mis-matching Basic color *)
    | "grey-0" -> Grey0
    | "navy-blue" -> NavyBlue
    | "dark-blue" -> DarkBlue
    | "blue-3a" -> Blue3a
    | "blue-3b" -> Blue3b
    | "blue-1" -> Blue1
    | "dark-green" -> DarkGreen
    | "deep-sky-blue-4a" -> DeepSkyBlue4a
    | "deep-sky-blue-4b" -> DeepSkyBlue4b
    | "deep-sky-blue-4c" -> DeepSkyBlue4c
    | "dodger-blue-3" -> DodgerBlue3
    | "dodger-blue-2" -> DodgerBlue2
    | "green-4" -> Green4
    | "spring-green-4" -> SpringGreen4
    | "turquoise-4" -> Turquoise4
    | "deep-sky-blue-3a" -> DeepSkyBlue3a
    | "deep-sky-blue-3b" -> DeepSkyBlue3b
    | "dodger-blue-1" -> DodgerBlue1
    | "green-3a" -> Green3a
    | "spring-green-3a" -> SpringGreen3a
    | "dark-cyan" -> DarkCyan
    | "light-sea-green" -> LightSeaGreen
    | "deep-sky-blue-2" -> DeepSkyBlue2
    | "deep-sky-blue-1" -> DeepSkyBlue1
    | "green-3b" -> Green3b
    | "spring-green-3b" -> SpringGreen3b
    | "spring-green-2a" -> SpringGreen2a
    | "cyan-3" -> Cyan3
    | "dark-turquoise" -> DarkTurquoise
    | "turquoise-2" -> Turquoise2
    | "green-1" -> Green1
    | "spring-green-2b" -> SpringGreen2b
    | "spring-green-1" -> SpringGreen1
    | "medium-spring-green" -> MediumSpringGreen
    | "cyan-2" -> Cyan2
    | "cyan-1" -> Cyan1
    | "dark-red-1" -> DarkRed1
    | "deep-pink-4a" -> DeepPink4a
    | "purple-4a" -> Purple4a
    | "purple-4b" -> Purple4b
    | "purple-3" -> Purple3
    | "blue-violet" -> BlueViolet
    | "orange-4a" -> Orange4a
    | "grey-37" -> Grey37
    | "medium-purple-4" -> MediumPurple4
    | "slate-blue-3a" -> SlateBlue3a
    | "slate-blue-3b" -> SlateBlue3b
    | "royal-blue-1" -> RoyalBlue1
    | "chartreuse-4" -> Chartreuse4
    | "dark-sea-green-4a" -> DarkSeaGreen4a
    | "pale-turquoise-4" -> PaleTurquoise4
    | "steel-blue" -> SteelBlue
    | "steel-blue-3" -> SteelBlue3
    | "cornflower-blue" -> CornflowerBlue
    | "chartreuse-3a" -> Chartreuse3a
    | "dark-sea-green-4b" -> DarkSeaGreen4b
    | "cadet-blue-2" -> CadetBlue2
    | "cadet-blue-1" -> CadetBlue1
    | "sky-blue-3" -> SkyBlue3
    | "steel-blue-1a" -> SteelBlue1a
    | "chartreuse-3b" -> Chartreuse3b
    | "pale-green-3a" -> PaleGreen3a
    | "sea-green-3" -> SeaGreen3
    | "aquamarine-3" -> Aquamarine3
    | "medium-turquoise" -> MediumTurquoise
    | "steel-blue-1b" -> SteelBlue1b
    | "chartreuse-2a" -> Chartreuse2a
    | "sea-green-2" -> SeaGreen2
    | "sea-green-1a" -> SeaGreen1a
    | "sea-green-1b" -> SeaGreen1b
    | "aquamarine-1a" -> Aquamarine1a
    | "dark-slate-gray-2" -> DarkSlateGray2
    | "dark-red-2" -> DarkRed2
    | "deep-pink-4b" -> DeepPink4b
    | "dark-magenta-1" -> DarkMagenta1
    | "dark-magenta-2" -> DarkMagenta2
    | "dark-violet-1a" -> DarkViolet1a
    | "purple-1a" -> Purple1a
    | "orange-4b" -> Orange4b
    | "light-pink-4" -> LightPink4
    | "plum-4" -> Plum4
    | "medium-purple-3a" -> MediumPurple3a
    | "medium-purple-3b" -> MediumPurple3b
    | "slate-blue-1" -> SlateBlue1
    | "yellow-4a" -> Yellow4a
    | "wheat-4" -> Wheat4
    | "grey-53" -> Grey53
    | "light-slate-grey" -> LightSlateGrey
    | "medium-purple" -> MediumPurple
    | "light-slate-blue" -> LightSlateBlue
    | "yellow-4b" -> Yellow4b
    | "dark-olive-green-3a" -> DarkOliveGreen3a
    | "dark-green-sea" -> DarkGreenSea
    | "light-sky-blue-3a" -> LightSkyBlue3a
    | "light-sky-blue-3b" -> LightSkyBlue3b
    | "sky-blue-2" -> SkyBlue2
    | "chartreuse-2b" -> Chartreuse2b
    | "dark-olive-green-3b" -> DarkOliveGreen3b
    | "pale-green-3b" -> PaleGreen3b
    | "dark-sea-green-3a" -> DarkSeaGreen3a
    | "dark-slate-gray-3" -> DarkSlateGray3
    | "sky-blue-1" -> SkyBlue1
    | "chartreuse-1" -> Chartreuse1
    | "light-green-2" -> LightGreen2
    | "light-green-3" -> LightGreen3
    | "pale-green-1a" -> PaleGreen1a
    | "aquamarine-1b" -> Aquamarine1b
    | "dark-slate-gray-1" -> DarkSlateGray1
    | "red-3a" -> Red3a
    | "deep-pink-4c" -> DeepPink4c
    | "medium-violet-red" -> MediumVioletRed
    | "magenta-3a" -> Magenta3a
    | "dark-violet-1b" -> DarkViolet1b
    | "purple-1b" -> Purple1b
    | "dark-orange-3a" -> DarkOrange3a
    | "indian-red-1a" -> IndianRed1a
    | "hot-pink-3a" -> HotPink3a
    | "medium-orchid-3" -> MediumOrchid3
    | "medium-orchid" -> MediumOrchid
    | "medium-purple-2a" -> MediumPurple2a
    | "dark-goldenrod" -> DarkGoldenrod
    | "light-salmon-3a" -> LightSalmon3a
    | "rosy-brown" -> RosyBrown
    | "grey-63" -> Grey63
    | "medium-purple-2b" -> MediumPurple2b
    | "medium-purple-1" -> MediumPurple1
    | "gold-3a" -> Gold3a
    | "dark-khaki" -> DarkKhaki
    | "navajo-white-3" -> NavajoWhite3
    | "grey-69" -> Grey69
    | "light-steel-blue-3" -> LightSteelBlue3
    | "light-steel-blue" -> LightSteelBlue
    | "yellow-3a" -> Yellow3a
    | "dark-olive-green-3" -> DarkOliveGreen3
    | "dark-sea-green-3b" -> DarkSeaGreen3b
    | "dark-sea-green-2" -> DarkSeaGreen2
    | "light-cyan-3" -> LightCyan3
    | "light-sky-blue-1" -> LightSkyBlue1
    | "green-yellow" -> GreenYellow
    | "dark-olive-green-2" -> DarkOliveGreen2
    | "pale-green-1b" -> PaleGreen1b
    | "dark-sea-green-5b" -> DarkSeaGreen5b
    | "dark-sea-green-5a" -> DarkSeaGreen5a
    | "pale-turquoise-1" -> PaleTurquoise1
    | "red-3b" -> Red3b
    | "deep-pink-3a" -> DeepPink3a
    | "deep-pink-3b" -> DeepPink3b
    | "magenta-3b" -> Magenta3b
    | "magenta-3c" -> Magenta3c
    | "magenta-2a" -> Magenta2a
    | "dark-orange-3b" -> DarkOrange3b
    | "indian-red-1b" -> IndianRed1b
    | "hot-pink-3b" -> HotPink3b
    | "hot-pink-2" -> HotPink2
    | "orchid" -> Orchid
    | "medium-orchid-1a" -> MediumOrchid1a
    | "orange-3" -> Orange3
    | "light-salmon-3b" -> LightSalmon3b
    | "light-pink-3" -> LightPink3
    | "pink-3" -> Pink3
    | "plum-3" -> Plum3
    | "violet" -> Violet
    | "gold-3b" -> Gold3b
    | "light-goldenrod-3" -> LightGoldenrod3
    | "tan" -> Tan
    | "misty-rose-3" -> MistyRose3
    | "thistle-3" -> Thistle3
    | "plum-2" -> Plum2
    | "yellow-3b" -> Yellow3b
    | "khaki-3" -> Khaki3
    | "light-goldenrod-2a" -> LightGoldenrod2a
    | "light-yellow-3" -> LightYellow3
    | "grey-84" -> Grey84
    | "light-steel-blue-1" -> LightSteelBlue1
    | "yellow-2" -> Yellow2
    | "dark-olive-green-1a" -> DarkOliveGreen1a
    | "dark-olive-green-1b" -> DarkOliveGreen1b
    | "dark-sea-green-1" -> DarkSeaGreen1
    | "honeydew-2" -> Honeydew2
    | "light-cyan-1" -> LightCyan1
    | "red-1" -> Red1
    | "deep-pink-2" -> DeepPink2
    | "deep-pink-1a" -> DeepPink1a
    | "deep-pink-1b" -> DeepPink1b
    | "magenta-2b" -> Magenta2b
    | "magenta-1" -> Magenta1
    | "orange-red-1" -> OrangeRed1
    | "indian-red-1c" -> IndianRed1c
    | "indian-red-1d" -> IndianRed1d
    | "hot-pink-1a" -> HotPink1a
    | "hot-pink-1b" -> HotPink1b
    | "medium-orchid-1b" -> MediumOrchid1b
    | "dark-orange" -> DarkOrange
    | "salmon-1" -> Salmon1
    | "light-coral" -> LightCoral
    | "pale-violet-red-1" -> PaleVioletRed1
    | "orchid-2" -> Orchid2
    | "orchid-1" -> Orchid1
    | "orange-1" -> Orange1
    | "sandy-brown" -> SandyBrown
    | "light-salmon-1" -> LightSalmon1
    | "light-pink-1" -> LightPink1
    | "pink-1" -> Pink1
    | "plum-1" -> Plum1
    | "gold-1" -> Gold1
    | "light-goldenrod-2b" -> LightGoldenrod2b
    | "light-goldenrod-2c" -> LightGoldenrod2c
    | "navajo-white-1" -> NavajoWhite1
    | "misty-rose1" -> MistyRose1
    | "thistle-1" -> Thistle1
    | "yellow-1" -> Yellow1
    | "light-goldenrod-1" -> LightGoldenrod1
    | "khaki-1" -> Khaki1
    | "wheat-1" -> Wheat1
    | "cornsilk-1" -> Cornsilk1
    | "grey-100" -> Grey100
    | "grey-3" -> Grey3
    | "grey-7" -> Grey7
    | "grey-11" -> Grey11
    | "grey-15" -> Grey15
    | "grey-19" -> Grey19
    | "grey-23" -> Grey23
    | "grey-27" -> Grey27
    | "grey-30" -> Grey30
    | "grey-35" -> Grey35
    | "grey-39" -> Grey39
    | "grey-42" -> Grey42
    | "grey-46" -> Grey46
    | "grey-50" -> Grey50
    | "grey-54" -> Grey54
    | "grey-58" -> Grey58
    | "grey-62" -> Grey62
    | "grey-66" -> Grey66
    | "grey-70" -> Grey70
    | "grey-74" -> Grey74
    | "grey-78" -> Grey78
    | "grey-82" -> Grey82
    | "grey-85" -> Grey85
    | "grey-89" -> Grey89
    | "grey-93" -> Grey93
    | name -> raise @@ InvalidColorName name

  let to_code = function
    | Black -> 0
    | Maroon -> 1
    | Green -> 2
    | Olive -> 3
    | Navy -> 4
    | Purple -> 5
    | Teal -> 6
    | Silver -> 7
    | Grey -> 8
    | Red -> 9
    | Lime -> 10
    | Yellow -> 11
    | Blue -> 12
    | Fuchsia -> 13
    | Aqua -> 14
    | White -> 15
    | Grey0 -> 16
    | NavyBlue -> 17
    | DarkBlue -> 18
    | Blue3a -> 19
    | Blue3b -> 20
    | Blue1 -> 21
    | DarkGreen -> 22
    | DeepSkyBlue4a -> 23
    | DeepSkyBlue4b -> 24
    | DeepSkyBlue4c -> 25
    | DodgerBlue3 -> 26
    | DodgerBlue2 -> 27
    | Green4 -> 28
    | SpringGreen4 -> 29
    | Turquoise4 -> 30
    | DeepSkyBlue3a -> 31
    | DeepSkyBlue3b -> 32
    | DodgerBlue1 -> 33
    | Green3a -> 34
    | SpringGreen3a -> 35
    | DarkCyan -> 36
    | LightSeaGreen -> 37
    | DeepSkyBlue2 -> 38
    | DeepSkyBlue1 -> 39
    | Green3b -> 40
    | SpringGreen3b -> 41
    | SpringGreen2a -> 42
    | Cyan3 -> 43
    | DarkTurquoise -> 44
    | Turquoise2 -> 45
    | Green1 -> 46
    | SpringGreen2b -> 47
    | SpringGreen1 -> 48
    | MediumSpringGreen -> 49
    | Cyan2 -> 50
    | Cyan1 -> 51
    | DarkRed1 -> 52
    | DeepPink4a -> 53
    | Purple4a -> 54
    | Purple4b -> 55
    | Purple3 -> 56
    | BlueViolet -> 57
    | Orange4a -> 58
    | Grey37 -> 59
    | MediumPurple4 -> 60
    | SlateBlue3a -> 61
    | SlateBlue3b -> 62
    | RoyalBlue1 -> 63
    | Chartreuse4 -> 64
    | DarkSeaGreen4a -> 65
    | PaleTurquoise4 -> 66
    | SteelBlue -> 67
    | SteelBlue3 -> 68
    | CornflowerBlue -> 69
    | Chartreuse3a -> 70
    | DarkSeaGreen4b -> 71
    | CadetBlue2 -> 72
    | CadetBlue1 -> 73
    | SkyBlue3 -> 74
    | SteelBlue1a -> 75
    | Chartreuse3b -> 76
    | PaleGreen3a -> 77
    | SeaGreen3 -> 78
    | Aquamarine3 -> 79
    | MediumTurquoise -> 80
    | SteelBlue1b -> 81
    | Chartreuse2a -> 82
    | SeaGreen2 -> 83
    | SeaGreen1a -> 84
    | SeaGreen1b -> 85
    | Aquamarine1a -> 86
    | DarkSlateGray2 -> 87
    | DarkRed2 -> 88
    | DeepPink4b -> 89
    | DarkMagenta1 -> 90
    | DarkMagenta2 -> 91
    | DarkViolet1a -> 92
    | Purple1a -> 93
    | Orange4b -> 94
    | LightPink4 -> 95
    | Plum4 -> 96
    | MediumPurple3a -> 97
    | MediumPurple3b -> 98
    | SlateBlue1 -> 99
    | Yellow4a -> 100
    | Wheat4 -> 101
    | Grey53 -> 102
    | LightSlateGrey -> 103
    | MediumPurple -> 104
    | LightSlateBlue -> 105
    | Yellow4b -> 106
    | DarkOliveGreen3a -> 107
    | DarkGreenSea -> 108
    | LightSkyBlue3a -> 109
    | LightSkyBlue3b -> 110
    | SkyBlue2 -> 111
    | Chartreuse2b -> 112
    | DarkOliveGreen3b -> 113
    | PaleGreen3b -> 114
    | DarkSeaGreen3a -> 115
    | DarkSlateGray3 -> 116
    | SkyBlue1 -> 117
    | Chartreuse1 -> 118
    | LightGreen2 -> 119
    | LightGreen3 -> 120
    | PaleGreen1a -> 121
    | Aquamarine1b -> 122
    | DarkSlateGray1 -> 123
    | Red3a -> 124
    | DeepPink4c -> 125
    | MediumVioletRed -> 126
    | Magenta3a -> 127
    | DarkViolet1b -> 128
    | Purple1b -> 129
    | DarkOrange3a -> 130
    | IndianRed1a -> 131
    | HotPink3a -> 132
    | MediumOrchid3 -> 133
    | MediumOrchid -> 134
    | MediumPurple2a -> 135
    | DarkGoldenrod -> 136
    | LightSalmon3a -> 137
    | RosyBrown -> 138
    | Grey63 -> 139
    | MediumPurple2b -> 140
    | MediumPurple1 -> 141
    | Gold3a -> 142
    | DarkKhaki -> 143
    | NavajoWhite3 -> 144
    | Grey69 -> 145
    | LightSteelBlue3 -> 146
    | LightSteelBlue -> 147
    | Yellow3a -> 148
    | DarkOliveGreen3 -> 149
    | DarkSeaGreen3b -> 150
    | DarkSeaGreen2 -> 151
    | LightCyan3 -> 152
    | LightSkyBlue1 -> 153
    | GreenYellow -> 154
    | DarkOliveGreen2 -> 155
    | PaleGreen1b -> 156
    | DarkSeaGreen5b -> 157
    | DarkSeaGreen5a -> 158
    | PaleTurquoise1 -> 159
    | Red3b -> 160
    | DeepPink3a -> 161
    | DeepPink3b -> 162
    | Magenta3b -> 163
    | Magenta3c -> 164
    | Magenta2a -> 165
    | DarkOrange3b -> 166
    | IndianRed1b -> 167
    | HotPink3b -> 168
    | HotPink2 -> 169
    | Orchid -> 170
    | MediumOrchid1a -> 171
    | Orange3 -> 172
    | LightSalmon3b -> 173
    | LightPink3 -> 174
    | Pink3 -> 175
    | Plum3 -> 176
    | Violet -> 177
    | Gold3b -> 178
    | LightGoldenrod3 -> 179
    | Tan -> 180
    | MistyRose3 -> 181
    | Thistle3 -> 182
    | Plum2 -> 183
    | Yellow3b -> 184
    | Khaki3 -> 185
    | LightGoldenrod2a -> 186
    | LightYellow3 -> 187
    | Grey84 -> 188
    | LightSteelBlue1 -> 189
    | Yellow2 -> 190
    | DarkOliveGreen1a -> 191
    | DarkOliveGreen1b -> 192
    | DarkSeaGreen1 -> 193
    | Honeydew2 -> 194
    | LightCyan1 -> 195
    | Red1 -> 196
    | DeepPink2 -> 197
    | DeepPink1a -> 198
    | DeepPink1b -> 199
    | Magenta2b -> 200
    | Magenta1 -> 201
    | OrangeRed1 -> 202
    | IndianRed1c -> 203
    | IndianRed1d -> 204
    | HotPink1a -> 205
    | HotPink1b -> 206
    | MediumOrchid1b -> 207
    | DarkOrange -> 208
    | Salmon1 -> 209
    | LightCoral -> 210
    | PaleVioletRed1 -> 211
    | Orchid2 -> 212
    | Orchid1 -> 213
    | Orange1 -> 214
    | SandyBrown -> 215
    | LightSalmon1 -> 216
    | LightPink1 -> 217
    | Pink1 -> 218
    | Plum1 -> 219
    | Gold1 -> 220
    | LightGoldenrod2b -> 221
    | LightGoldenrod2c -> 222
    | NavajoWhite1 -> 223
    | MistyRose1 -> 224
    | Thistle1 -> 225
    | Yellow1 -> 226
    | LightGoldenrod1 -> 227
    | Khaki1 -> 228
    | Wheat1 -> 229
    | Cornsilk1 -> 230
    | Grey100 -> 231
    | Grey3 -> 232
    | Grey7 -> 233
    | Grey11 -> 234
    | Grey15 -> 235
    | Grey19 -> 236
    | Grey23 -> 237
    | Grey27 -> 238
    | Grey30 -> 239
    | Grey35 -> 240
    | Grey39 -> 241
    | Grey42 -> 242
    | Grey46 -> 243
    | Grey50 -> 244
    | Grey54 -> 245
    | Grey58 -> 246
    | Grey62 -> 247
    | Grey66 -> 248
    | Grey70 -> 249
    | Grey74 -> 250
    | Grey78 -> 251
    | Grey82 -> 252
    | Grey85 -> 253
    | Grey89 -> 254
    | Grey93 -> 255

  (* TODO *)
  let to_color = function
    | _ -> Color.of_rgb 0 0 0
end

module Rgb = struct
  let to_code color =
    let c = Color.to_rgba color in
    (string_of_int c.r) ^ ";"
    ^ (string_of_int c.g) ^ ";"
    ^ (string_of_int c.b)
end

type color_def =
  | NamedBasicColor of Basic.t
  | Named256Color of Xterm256.t
  | RgbColor of Gg.v4

let rgbcolor c = RgbColor c

type token =
  | Foreground of color_def
  | Background of color_def
  | Control of Style.t

exception InvalidTag of string
exception InvalidHexColor of string
exception InvalidRgbColor of string
exception InvalidPercentage of string
exception InvalidQualifier of string
exception Eof

(*
  Will use the xterm-256 color names by default, falling back to Basic
  Note that Basic names have been prefixed to disambiguate
*)
let from_name name =
  try Named256Color (Xterm256.of_string name)
  with InvalidColorName _ -> NamedBasicColor (Basic.of_string name)

let from_hex hex =
  match Color.of_hexstring hex with
  | Some color -> color |> rgbcolor
  | None -> raise @@ InvalidHexColor hex  (* unreachable *)

let parse_int_256 s =
  match int_of_string s with
  | i when i < 256 -> i
  | _ -> raise @@ InvalidRgbColor s

let from_rgb r g b =
  let r = parse_int_256 r in
  let g = parse_int_256 g in
  let b = parse_int_256 b in
  Color.of_rgb r g b
  |> rgbcolor

let parse_float_percent s =
  match float_of_string s with
  | i when i <= 100. -> i
  | _ -> raise @@ InvalidPercentage s

let from_hsl h s l =
  let h = float_of_string h in
  let s = parse_float_percent s /. 100. in
  let l = parse_float_percent l /. 100. in
  Color.of_hsl h s l
  |> rgbcolor

let qualified q color =
  match q with
  | Some "bg" -> Background color
  | Some "fg" -> Foreground color
  | None -> Foreground color
  | Some q -> raise @@ InvalidQualifier q  (* unreachable *)

let qualified_color_from_name q name = from_name name |> qualified q
let qualified_color_from_hex q hex = from_hex hex |> qualified q
let qualified_color_from_rgb q r g b = from_rgb r g b |> qualified q
let qualified_color_from_hsl q h s l = from_hsl h s l |> qualified q

type compound_tag = {
  bold : bool;
  dim : bool;
  italic : bool;
  underline : bool;
  blink : bool;
  rapid_blink : bool;
  inverse : bool;
  hidden : bool;
  strikethru : bool;
  fg_color : color_def option;
  bg_color : color_def option;
}

let compound_of_tokens tokens =
  let bold = ref false
  and dim = ref false
  and italic = ref false
  and underline = ref false
  and blink = ref false
  and rapid_blink = ref false
  and inverse = ref false
  and hidden = ref false
  and strikethru = ref false
  and fg_color = ref None
  and bg_color = ref None
  in
  List.iter (
    function
    | Control Bold -> bold := true
    | Control Dim -> dim := true
    | Control Italic -> italic := true
    | Control Underline -> underline := true
    | Control Blink -> blink := true
    | Control RapidBlink -> rapid_blink := true
    | Control Inverse -> inverse := true
    | Control Hidden -> hidden := true
    | Control Strikethru -> strikethru := true
    | Foreground c -> fg_color := Some c
    | Background c -> bg_color := Some c
  ) tokens;
  {
    bold = !bold;
    dim = !dim;
    italic = !italic;
    underline = !underline;
    blink = !blink;
    rapid_blink = !rapid_blink;
    inverse = !inverse;
    hidden = !hidden;
    strikethru = !strikethru;
    fg_color = !fg_color;
    bg_color = !bg_color;
  }

## Or maybe it's a roadmap...

- Implement "256 from 16 palette" as per >https://github.com/jake-stewart/color256/>
  - ...users typically define custom 16-color palettes (rather than full 256), it's nice if you can then auto expand this to a full 256-color xterm custom palette so that all colours complement each other.
  - iTerm2 added support for this, we have to be aware when testing <https://github.com/gnachman/iTerm2/commit/39bafa8d665186595151872a22659d4a701b00f4>
  - See also this 16-color palette for users eith impaired colour vision: <https://ctx.graphics/terminal/ametameric/>
- Parse palettes from terminal theme files, such as:
  - [iTerm2](https://github.com/mbadolato/iTerm2-Color-Schemes/blob/master/terminator/Aardvark%20Blue.config) (this site has lots of themes - install from GitHub?)
  - [Warp](https://github.com/warpdotdev/themes/blob/main/warp_bundled/cyber_wave.yaml) (lots of themes here)
  - [asciicinema](https://github.com/catppuccin/asciinema/blob/main/themes/frappe.json)
  - [Kitty](https://github.com/dexpota/kitty-themes/blob/master/themes/Afterglow.conf)

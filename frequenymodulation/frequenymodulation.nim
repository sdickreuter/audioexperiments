import os
import illwill, ../illwidgets

import audiotypes
import audiogenerator
import audioplayer_sdl2

# 1. Initialise terminal in fullscreen mode and make sure we restore the state
# of the terminal state when exiting.
proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  stopAudio()
  stopThread()
  quit(0)


InitSDL()
startThread()
startAudio()

illwillInit(fullscreen = true)
setControlCHook(exitProc)
hideCursor()

# 2. We will construct the next frame to be displayed in this buffer and then
# just instruct the library to display its contents to the actual terminal
# (double buffering is enabled by default; only the differences from the
# previous frame will be actually printed to the terminal).
var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

# 3. Display some simple static UI that doesn't change from frame to frame.
tb.setForegroundColor(fgWhite, true)
tb.setBackgroundColor(bgBlack)

tb.fill(0, 0, tb.width-1, tb.height-1)
tb.drawHorizLine(2, 38, 3, doubleStyle = true)

#tb.write(2, 1, fgWhite, "Plays f(t) = f₀ + Δf sin(2π ν t)")
tb.write(2, 1, fgWhite, "Plays f(t) = f0 + df sin(2pi nu t)")
tb.write(2, 2, "Press ", fgYellow, "ESC", fgWhite,
               " or ", fgYellow, "Q", fgWhite, " to quit")

var g = newUIGroup()

var
  y = 5
#[ startbut = newToggleButton(toggled = false, x = 1,
      y = y, width = 15, label = " Start playing ")
  freqslider = newSlider(min = 10, max = 1000, step = 5, value = 440, x = 1,
      y = y+3, width = 25, label = " f₀ / Hz ")
  deltaslider = newSlider(min = 0, max = 100, step = 1, value = 20, x = 1,
      y = y+6, width = 25, label = " Δf / Hz ")
  nuslider = newSlider(min = 1, max = 10, step = 1, value = 5, x = 1,
      y = y+9, width = 25, label = " ν / Hz ")
  volumeslider = newSlider(min = 0, max = 100, step = 1, value = 10, x = 1,
      y = y+12, width = 25, label = "Volume")
]#
  startbut = newToggleButton(toggled = false, x = 1,
      y = y, width = 15, label = " Start playing ")
  deltaslider = newFloatSlider(min = 0.0, max = 10.0, step = 0.1, value = 0.0, x = 1,
      y = y+3, width = 25, label = " df / Hz ")
  nuslider = newSlider(min = 1, max = 10, step = 1, value = 5, x = 1,
      y = y+6, width = 25, label = " nu / Hz ")
  freqslider = newSlider(min = 10, max = 1000, step = 5, value = 440, x = 1,
      y = y+9, width = 25, label = " f0 / Hz ")
  volumeslider = newFloatSlider(min = 0, max = 1, step = 0.01, value = 0.1, x = 1,
      y = y+12, width = 25, label = "Volume")

proc ontoggle_start(but: ToggleButton) =
  if but.toggled:
    controlchannel.send(ControlMessage(kind: setactive))
  else:
    controlchannel.send(ControlMessage(kind: setinactive))

startbut.ontoggle = ontoggle_start

proc onchange_freq(slider: Slider) =
  controlchannel.send(ControlMessage(kind: cmf0, f0: float(freqslider.value)))

freqslider.onchange = onchange_freq

proc onchange_delta(slider: FloatSlider) =
  controlchannel.send(ControlMessage(kind: cmdeltaf, deltaf: deltaslider.value))

deltaslider.onchange = onchange_delta

proc onchange_nu(slider: Slider) =
  controlchannel.send(ControlMessage(kind: cmnu, nu: float(nuslider.value)))

nuslider.onchange = onchange_nu

proc onchange_volume(slider: FloatSlider) =
  controlchannel.send(ControlMessage(kind: cmvol, vol: volumeslider.value))

volumeslider.onchange = onchange_volume


g.add(startbut)
g.add(deltaslider)
g.add(nuslider)
g.add(freqslider)
g.add(volumeslider)

g.setFocusto(0)

# 4. This is how the main event loop typically looks like: we keep polling for
# user input (keypress events), do something based on the input, modify the
# contents of the terminal buffer (if necessary), and then display the new
# frame.
while true:
  var key = getKey()
  case key
  of Key.None: discard
  of Key.Escape, Key.Q: exitProc()
  else:
    g.handleinput(key)

  tb.draw(g)
  tb.display()
  sleep(15)

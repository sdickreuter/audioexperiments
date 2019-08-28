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
tb.drawHorizLine(2, 37, 3, doubleStyle = true)

tb.write(2, 1, fgWhite, "Just-noticeable difference Generator")
tb.write(2, 2, "Press ", fgYellow, "ESC", fgWhite,
               " or ", fgYellow, "Q", fgWhite, " to quit")
tb.write(2, 2, "Change any parameter to play sounds")


var g = newUIGroup()

var
  y = 5
  freqslider = newSlider(min = 10, max = 1000, step = 5, value = 440, x = 1,
      y = y+0, width = 25, label = " f₀ / Hz ")
  deltaslider = newSlider(min = 0, max = 100, step = 1, value = 20, x = 1,
      y = y+3, width = 25, label = " Δ Volume * 10 ")
  volumeslider = newSlider(min = 0, max = 100, step = 1, value = 10, x = 1,
      y = y+6, width = 25, label = "Volume")
  resetbut = newButton(x = 1,
      y = y+9, width = 18, label = " Reset Parameters ")


proc onchange(slider: Slider) =
  controlchannel.send(ControlMessage(kind: cmf0, f0: float(freqslider.value)))
  controlchannel.send(ControlMessage(kind: cmdeltavol, deltavol: float(0.0)))
  controlchannel.send(ControlMessage(kind: setactive))
  sleep(1000)
  controlchannel.send(ControlMessage(kind: setinactive))
  sleep(100)
  controlchannel.send(ControlMessage(kind: cmf0, f0: float(freqslider.value)))
  controlchannel.send(ControlMessage(kind: cmdeltavol, deltavol: float(
      deltaslider.value)/10))
  controlchannel.send(ControlMessage(kind: setactive))
  sleep(1000)
  controlchannel.send(ControlMessage(kind: setinactive))


freqslider.onchange = onchange
deltaslider.onchange = onchange

proc onchange_volume(slider: Slider) =
  controlchannel.send(ControlMessage(kind: cmvol, vol: float(
      volumeslider.value)/100))

volumeslider.onchange = onchange_volume

proc onpress_reset(but: Button) =
  freqslider.value = 440
  deltaslider.value = 20
  volumeslider.value = 10
  controlchannel.send(ControlMessage(kind: cmf0, f0: float(freqslider.value)))
  controlchannel.send(ControlMessage(kind: cmdeltavol, deltavol: float(
      deltaslider.value)/10))
  controlchannel.send(ControlMessage(kind: cmvol, vol: float(
      volumeslider.value)/100))

resetbut.onpress = onpress_reset

g.add(freqslider)
g.add(deltaslider)
g.add(volumeslider)
g.add(resetbut)


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

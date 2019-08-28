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

illwillInit(fullscreen=true)
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
tb.drawHorizLine(2, 52, 4, doubleStyle=true)

tb.write(2, 1, fgWhite, "Binaural Tone Generator")
tb.write(2, 2, "Press ", fgYellow, "ESC", fgWhite,
               " or ", fgYellow, "Q", fgWhite, " to quit")
tb.write(2, 3, "Use ", fgYellow, "↑↓", fgWhite,
               " to navigate and ", fgYellow, "←→",
                fgWhite, " or " , fgYellow, "Enter", fgWhite, " to change values")


var g = newUIGroup()

var 
  y = 5
  startbut = newToggleButton(toggled = false, x = 1, y = y, width = 15, label=" Start playing ")
  freqslider = newSlider(min= 10,max= 1000,step= 5,value= 440,x= 1,y= y+3,width= 25,label="Frequency/Hz")
  octavebut = newToggleButton(toggled = false, x = 1, y = y+6, width = 19, label=" Detune one Octave ")
  detuneslider = newSlider(min= -100,max= 100,step= 1,value= 0,x= 1,y= y+9,width= 25,label="Detune/Hz")
  volumeslider = newFloatSlider(min= 0,max= 1,step= 0.01,value= 0.1,x= 1,y= y+12,width= 25,label="Volume")
  detune_octave : bool = false
  monobut = newToggleButton(toggled = false, x = 1, y = y+15, width = 15, label=" Activate Mono ")


proc ontoggle_start(but: ToggleButton) =
  if but.toggled:
    controlchannel.send(ControlMessage(kind: setactive))
  else:
    controlchannel.send(ControlMessage(kind: setinactive))

startbut.ontoggle = ontoggle_start 

proc onchange_freq(slider: Slider) =
  if detune_octave:
    controlchannel.send(ControlMessage(kind: leftfreq, lfreq: float(freqslider.value)))
    controlchannel.send(ControlMessage(kind: rightfreq, rfreq: float(freqslider.value*2 + detuneslider.value)))
  else:
    controlchannel.send(ControlMessage(kind: leftfreq, lfreq: float(freqslider.value)))
    controlchannel.send(ControlMessage(kind: rightfreq, rfreq: float(freqslider.value + detuneslider.value)))

freqslider.onchange = onchange_freq 
detuneslider.onchange = onchange_freq 

proc ontoggle_octave(but: ToggleButton) =
  detune_octave = but.toggled
  onchange_freq(freqslider)

octavebut.ontoggle = ontoggle_octave 


proc onchange_volume(slider: FloatSlider) =
    controlchannel.send(ControlMessage(kind: rightvol, rvol: volumeslider.value))
    controlchannel.send(ControlMessage(kind: leftvol, lvol: volumeslider.value))

volumeslider.onchange = onchange_volume 

proc ontoggle_mono(but: ToggleButton) =
    controlchannel.send(ControlMessage(kind: switchmono))


monobut.ontoggle = ontoggle_mono 

g.add(startbut)
g.add(freqslider)
g.add(octavebut)
g.add(detuneslider)
g.add(volumeslider)
g.add(monobut)

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

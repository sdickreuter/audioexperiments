import os, strformat, strutils 
import illwill, illwidgets

import audiotypes
import audiogenerator
import audioplayer

# 1. Initialise terminal in fullscreen mode and make sure we restore the state
# of the terminal state when exiting.
proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  stopThread()
  terminatestream() 
  quit(0)


initstream()
startThread()
startstream()

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()

  initstream()
  echo("stream initiated")
  startThread()
  echo("thread started")
  startstream()
  echo("stream started")

# 3. Display some simple static UI that doesn't change from frame to frame.
tb.setForegroundColor(fgBlack, true)
tb.drawRect(0, 0, 40, 4)
tb.drawHorizLine(2, 38, 3, doubleStyle=true)

tb.write(2, 1, fgWhite, "Binaural Tone Generator")
tb.write(2, 2, "Press ", fgYellow, "ESC", fgWhite,
               " or ", fgYellow, "Q", fgWhite, " to quit")

var g = newUIGroup()

  let buttonbox = newHorizontalBox(true)
  box.add(buttonbox)
  
  

  proc onstartbutton() =
    #echo("start pressed")
    #startThread()
    var msg = ControlMessage(kind: setactive)
    controlchannel.send(msg)

startbut.ontoggle = ontoggle_start 

  proc onstopbutton() =
    #echo("stop pressed")
    #stopThread()
    var msg = ControlMessage(kind: setinactive)
    controlchannel.send(msg)

freqslider.onchange = onchange_freq 
detuneslider.onchange = onchange_freq 

proc ontoggle_octave(but: ToggleButton) =
  detune_octave = but.toggled
  onchange_freq(freqslider)

octavebut.ontoggle = ontoggle_octave 


proc onchange_volume(slider: Slider) =
    controlchannel.send(ControlMessage(kind: rightvol, rvol: float(volumeslider.value)/100))
    controlchannel.send(ControlMessage(kind: leftvol, lvol: float(volumeslider.value)/100))

volumeslider.onchange = onchange_volume 


g.add(startbut)
g.add(freqslider)
g.add(octavebut)
g.add(detuneslider)
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
  sleep(10)

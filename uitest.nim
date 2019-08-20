# This is the example code from the README.

import os, strformat, strutils 
import illwill, illwidgets


# 1. Initialise terminal in fullscreen mode and make sure we restore the state
# of the terminal state when exiting.
proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()

# 2. We will construct the next frame to be displayed in this buffer and then
# just instruct the library to display its contents to the actual terminal
# (double buffering is enabled by default; only the differences from the
# previous frame will be actually printed to the terminal).
var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

# 3. Display some simple static UI that doesn't change from frame to frame.
tb.setForegroundColor(fgBlack, true)
tb.drawRect(0, 0, 40, 5)
tb.drawHorizLine(2, 38, 4, doubleStyle=true)

tb.write(2, 1, fgWhite, "Binaural Tone Generator")
tb.write(2, 2, "Press ", fgYellow, "ESC", fgWhite,
               " or ", fgYellow, "Q", fgWhite, " to quit")
tb.write(2, 3, "Press ", fgYellow, "S", fgWhite, " to Start/Stop Playback")

var g = newUIGroup()

var 
  startbut = newToggleButton(toggled = false, x = 1, y = 6, width = 15, label=" Start playing ")
  freqslider = newSlider(min= 10,max= 1000,step= 5,value= 440,x= 1,y= 9,width= 25,label="Frequency")
  octavebut = newToggleButton(toggled = false, x = 1, y = 12, width = 19, label=" Detune one octave ")
  detuneslider = newSlider(min= -100,max= 100,step= 1,value= 0,x= 1,y= 15,width= 25,label="Detune")
  volumeslider = newSlider(min= 0,max= 100,step= 1,value= 10,x= 1,y= 18,width= 25,label="Volume")

proc ontoggle_startbut(but: ToggleButton) =
  but.label = "toggled"

startbut.ontoggle = ontoggle_startbut 

#proc ontoggle_octavebut(but: ToggleButton) =
#  if but.toggled:
#    detuneslider.min     
#
#octavebut.ontoggle = ontoggle_octavebut 


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
  #slider.draw(tb)
  tb.display()
  sleep(10)
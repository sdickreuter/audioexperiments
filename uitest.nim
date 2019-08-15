# This is the example code from the README.

import os, strformat, unicode 
import illwill


type
  UIObject = ref object of RootObj
    x,y,width: int
    focus: bool

proc setFocus*(obj: UIObject, focus: bool) =
  obj.focus = focus

method handleinput(obj: UIObject, key: Key) {.base.} =
  echo("handleinput")
  #quit("please overwrite method handleinput")


method draw(obj:UIObject, tb: var TerminalBuffer) {.base.} =
  echo("draw")
  #quit("please overwrite method draw")

type
  Slider* = ref object of UIObject
    min, max, value: int
    step: int

proc newSlider*(min, max, step, value: int; x,y,width: int): Slider =
  result = new(Slider)
  result.min = min
  result.max = max
  result.step = step
  result.value = value
  result.x = x
  result.y = y
  result. width = width
  result.focus = false

proc inc*(slider: Slider) =
  slider.value += slider.step
  if slider.value > slider.max:
    slider.value = slider.max

proc dec*(slider: Slider) =
  slider.value -= slider.step
  if slider.value < slider.min:
    slider.value = slider.min

method handleinput(slider: Slider, key: Key) =
  case key  
  of Key.Right:
    slider.inc()
  of Key.Left:
    slider.dec()
  else:
    discard

method draw*(slider:Slider, tb: var TerminalBuffer) =
  var 
    pos: int

  tb.setForegroundColor(fgBlack, true)
  tb.drawRect(slider.x, slider.y, slider.x+slider.width+1, slider.y+2,doubleStyle=true)
  pos = int( ( (slider.value - slider.min) / (slider.max - slider.min) ) * float(slider.width))
  if slider.focus:
    tb.setForegroundColor(fgBlue)
  else:
    tb.setForegroundColor(fgYellow)
 
  for i in 0..<pos:
    tb.write(slider.x+1+i, slider.y+1,"█")
  
  tb.setForegroundColor(fgWhite)
  for i in pos..<slider.width:
    tb.write(slider.x+1+i, slider.y+1,"█")

  tb.setForegroundColor(fgBlack)
  tb.write(slider.x+int(slider.width/2), slider.y,fmt"{slider.value:>10}")



type
  UIGroup = ref object
    members : seq[UIObject]
    focus_index: int

proc newUIGroup(): UIGroup =
  result = new(UIGroup)
  result.members = @[]
  result.focus_index = 0

proc add(g: UIGroup, obj: UIObject) =
  g.members.add(obj)

proc unfocusall(g: UIGroup) =
  for obj in g.members:
    obj.setFocus(false)

proc setFocusto(g: UIGroup, index: int) =
  if index >= low(g.members) and index <= high(g.members):
    g.unfocusall()
    g.members[index].setFocus(true)
    g.focus_index = index

proc incFocus(g: UIGroup) =
  var index: int
  index = g.focus_index + 1
  if index > high(g.members):
    index = low(g.members) 
  g.unfocusall()
  g.members[index].setFocus(true)
  g.focus_index = index

proc decFocus(g: UIGroup) =
  var index: int  
  index = g.focus_index - 1
  if index < low(g.members):
    index = high(g.members)
  g.unfocusall()
  g.members[index].setFocus(true)
  g.focus_index = index

proc handleinput(g: UIGroup, key: Key) =
  case key 
  of Key.Up:
    g.incFocus()
  of Key.Down:
    g.decFocus()
  else:
    for obj in g.members:
      if obj.focus:
        obj.handleinput(key)

proc draw(tb: var TerminalBuffer, g: UIGroup) =
  for obj in g.members:
    obj.draw(tb)



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

var freqslider = newSlider(min= 10,max= 1000,step= 1,value= 440,x= 1,y= 10,width= 25)
g.add(freqslider)
               
var detuneslider = newSlider(min= -100,max= 100,step= 1,value= 0,x= 1,y= 14,width= 25)
g.add(detuneslider)


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
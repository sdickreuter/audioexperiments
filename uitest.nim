# This is the example code from the README.

import os, strutils, unicode 
import illwill


type
  UIObject = ref object of RootObj
    x,y,width: int
    focus: bool

proc setFocus*(obj: UIObject, focus: bool) =
  obj.focus = focus

proc handleinput(obj: UIObject, key: Key) {.base.} =
  echo("handleinput")
#  discard

proc draw(tb: var TerminalBuffer, obj:UIObject) {.base.} =
  echo("draw")
#  discard

type
  Slider*[T] = ref object of UIObject
    min, max, value: T
    step: T

proc newSlider*[T](min, max, step, value: T; x,y,width: int): Slider[T] =
  result = new(Slider[T])
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

method draw*[T](tb: var TerminalBuffer, slider:Slider[T]) =
  var 
    pos: int

  tb.setForegroundColor(fgBlack, true)
  tb.drawRect(slider.x, slider.y, slider.x+slider.width+1, slider.y+2,doubleStyle=true)
  pos = int( ( (slider.value - slider.min) / (slider.max - slider.min) ) * float(slider.width))
  tb.setForegroundColor(fgYellow)
  for i in 0..<pos:
    tb.write(slider.x+1+i, slider.y+1,"█")
  
  tb.setForegroundColor(fgWhite)
  for i in pos..<slider.width:
    tb.write(slider.x+1+i, slider.y+1,"█")

  #tb.drawHorizLine(slider.x+1, slider.x+1+pos, slider.y+1, doubleStyle=false)
  tb.setForegroundColor(fgBlack)
  tb.write(slider.x+int(slider.width/2), slider.y,$slider.value)



type
  UIGroup = ref object
    members : seq[UIObject]

proc newUIGroup(): UIGroup =
  result = new(UIGroup)
  result.members = @[]

proc add(g: UIGroup, obj: UIObject) =
  g.members.add(obj)

proc unfocusall(g: UIGroup) =
  for obj in g.members:
    obj.setFocus(false)

method handleinput(g: UIGroup, key: Key) =
  for obj in g.members:
    if obj.focus:
      obj.handleinput(key)

method draw(tb: var TerminalBuffer, g: UIGroup) =
  for obj in g.members:
    tb.draw(obj)



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
var slider = newSlider[int](min=0,max=100,step=1,value=60,x=1,y=10,width=25)

g.add(slider)
               

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
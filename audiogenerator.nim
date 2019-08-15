import strutils, times, locks
import audiotypes
import audioplayer
import math

# modified from https://github.com/jlp765/seqmath
proc linspace(start, stop: int, endpoint = true): seq[float32] =
  var 
    step = float(start)
    diff: float
  if endpoint == true:
    diff = float(stop - start) / float(framesPerBuffer - 1)
  else:
    diff = float(stop - start) / float(framesPerBuffer)
  if diff < 0:
    # in case start is bigger than stop, return an empty sequence
    return 
  else:
    for i in 0..<framesPerBuffer:
      result.add(step)
      # for every element calculate new value for next iteration
      step += diff


const freq = 440
const pi = 3.141592653589

var
  generatorthread: Thread[void]
  currentframe: int = 0
  params = GeneratorParams(leftfreq:440,rightfreq:440,leftvol:1.0,rightvol:1.0)


proc runthread {.thread.} =
  var 
    t : seq[float32]
    leftdata : seq[float32]
    rightdata : seq[float32]
    success: bool
    msg : ControlMessage 
    active: bool = false

  while true:
    (success, msg)= controlchannel.tryRecv()
    if success:
      case msg.kind
      of leftfreq:
        params.leftfreq = msg.lfreq
      of rightfreq:
        params.rightfreq = msg.rfreq
      of leftvol:
        params.leftvol = msg.lvol
      of rightvol:
        params.rightvol = msg.rvol
      of setactive:
        currentframe = 0
        active = true
      of setinactive:
        active = false
      of terminate:
        audiochannel.send(AudioMessage(kind: stop))
        break
    
    if audiochannel.peek() < 5:
      t = linspace(currentframe, currentframe + int(framesPerBuffer))
      for i in 0..<framesPerBuffer: 
        t[i] /= float32(sampleRate)

      if active:
        for i in 0..<framesPerBuffer: 
          leftdata.add( sin(params.leftfreq*(2*pi)*t[i])*params.leftvol)
          rightdata.add( sin(params.rightfreq*(2*pi)*t[i])*params.rightvol)

        var msg = AudioMessage(kind: audio)
        msg.left = leftdata
        msg.right = rightdata
        audiochannel.send(msg)
        echo("audio sent")
        currentframe += int(framesPerBuffer)
      else:
        var msg = AudioMessage(kind: silent)
        audiochannel.send(msg)


proc stopThread* {.noconv.} =
  joinThread(generatorthread)
  audiochannel.send(AudioMessage(kind: stop))
  #close(audiochannel)
  
proc startThread* {.noconv.} =
  generatorthread.createThread(runthread)
  if audiochannel.peek() > 3: 
    startstream()

# Initialize module
#addQuitProc(stopThread)
audiochannel.open()
controlchannel.open()

when isMainModule:
  var t : seq[float32] 
  t = linspace(currentframe, currentframe + int(framesPerBuffer))
  echo(len(t))
  startThread()
  
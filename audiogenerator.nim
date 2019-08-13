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
      result[i] = step
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
        echo("bla")
      of setinactive:
        echo("bla")
      of terminate:
        audiochannel.send(AudioMessage(kind: stop))
        break
    
    if audiochannel.peek() < 10:
      
      t = linspace(currentframe, currentframe + int(framesPerBuffer))
      for i in 0..<framesPerBuffer: 
        t[i] /= float32(sampleRate)
      
      for i in 0..<framesPerBuffer: 
        leftdata[i] = sin(params.leftfreq*(2*pi)*t[i])*params.leftvol*0.15
        rightdata[i] = sin(params.rightfreq*(2*pi)*t[i])*params.rightvol*0.15

      var msg = AudioMessage(kind: audio)
      msg.left = leftdata
      msg.right = rightdata
      audiochannel.send(msg)
      currentframe += int(framesPerBuffer)


    if t[framesPerBuffer-1] > 2:
      var msg = ControlMessage(kind: rightfreq)
      msg.rfreq = 444
      controlchannel.send(msg)

    if t[framesPerBuffer-1] > 5:
      controlchannel.send(ControlMessage(kind: terminate))


proc stopThread* {.noconv.} =
  joinThread(generatorthread)
  audiochannel.send(AudioMessage(kind: stop))
  #close(audiochannel)
  
proc startThread* {.noconv.} =
  generatorthread.createThread(runthread)
  initstream()
  if audiochannel.peek() > 8: 
    startstream()

# Initialize module
addQuitProc(stopThread)
audiochannel.open()
controlchannel.open()

when isMainModule:
  startThread()
import strutils, times, locks, os
import audiotypes
import audioplayer
import math

# modified from https://github.com/jlp765/seqmath
proc linspace(start, stop: int, endpoint = true): array[framesPerBuffer, float32] =
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
  params = GeneratorParams(leftfreq:440,rightfreq:440,leftvol:0.1,rightvol:0.1)


proc runthread {.thread.} =
  var 
    t : array[framesPerBuffer, float32]
    leftdata : array[framesPerBuffer, float32]
    rightdata : array[framesPerBuffer, float32]
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
          leftdata[i] = sin(params.leftfreq*(2*pi)*t[i])*params.leftvol
          rightdata[i] = sin(params.rightfreq*(2*pi)*t[i])*params.rightvol

        var msg = AudioMessage(kind: audio)
        msg.left = leftdata
        msg.right = rightdata
        audiochannel.send(msg)
        echo("audio sent")
        currentframe += int(framesPerBuffer)
      else:
        var msg = AudioMessage(kind: silent)
        audiochannel.send(msg)
        #echo("silent sent")


proc stopThread* {.noconv.} =
  controlchannel.send(ControlMessage(kind: terminate))
  joinThread(generatorthread)
  #sleep(200)

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
  echo("thread started")
  startstream()
  echo("stream started")
  sleep(200)
  var msg = ControlMessage(kind: setactive)
  controlchannel.send(msg)
  sleep(2000) 

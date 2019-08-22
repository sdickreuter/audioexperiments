import audiotypes
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


var
  generatorthread: Thread[void]
  currentframe: int = 0


proc runthread {.thread.} =
  var 
    t : array[framesPerBuffer, float32]
    leftdata : array[framesPerBuffer, float32]
    rightdata : array[framesPerBuffer, float32]
    success: bool
    msg : ControlMessage 
    active: bool = false
    params: GeneratorParams
    
  params = newGeneratorParams(leftfreq=440,rightfreq=440,leftvol=0.1,rightvol=0.1)

  while true:
    (success, msg)= controlchannel.tryRecv()
    if success:
      case msg.kind
      of leftfreq:
        params.leftfreq.set(msg.lfreq)
      of rightfreq:
        params.rightfreq.set(msg.rfreq)
      of leftvol:
        params.leftvol.set(msg.lvol)
      of rightvol:
        params.rightvol.set(msg.rvol)
      of setactive:
        currentframe = 0
        active = true
        params.fade.set(1.0)
      of setinactive:
        #active = false
        params.fade.set(0.0)
      of terminate:
        audiochannel.send(AudioMessage(kind: stop))
        break
    
    if audiochannel.peek() < numberofBuffers:
      t = linspace(currentframe, currentframe + int(framesPerBuffer))
      for i in 0..<framesPerBuffer: 
        t[i] /= float32(sampleRate)

      if active:
        for i in 0..<framesPerBuffer: 
          leftdata[i] = sin(params.leftfreq.get()*(2*PI)*t[i])*params.leftvol.get()*params.fade.get()
          rightdata[i] = sin(params.rightfreq.get()*(2*PI)*t[i])*params.rightvol.get()*params.fade.get()
          #echo( $leftdata[i] & "  " & $rightdata[i])
          #echo( $params.leftfreq.get() & "  " & $params.rightfreq.get())

          params.iterateParams()

        if params.fade.get() < 0.0001:
          active = false

        var msg = AudioMessage(kind: audio)
        msg.left = leftdata
        msg.right = rightdata
        audiochannel.send(msg)
        currentframe += int(framesPerBuffer)

      else:
        var msg = AudioMessage(kind: silent)
        audiochannel.send(msg)


proc stopThread* {.noconv.} =
  controlchannel.send(ControlMessage(kind: terminate))
  joinThread(generatorthread)
  #sleep(200)

  #close(audiochannel)
  
proc startThread* {.noconv.} =
  generatorthread.createThread(runthread)


# Initialize module
#addQuitProc(stopThread)
audiochannel.open()
controlchannel.open()

when isMainModule:
  import audioplayer
  import os

  initstream()
  echo("stream initiated")
  startThread()
  echo("thread started")
  startstream()
  echo("stream started")
  sleep(50)
  controlchannel.send(ControlMessage(kind: setactive))
  sleep(1000)
  controlchannel.send(ControlMessage(kind: leftfreq, lfreq: 450))
  sleep(1000)
  controlchannel.send(ControlMessage(kind: rightfreq, rfreq: 450))
  sleep(1000) 

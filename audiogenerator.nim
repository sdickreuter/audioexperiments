#import strutils, times, locks
import audiotypes
#import audioplayer
import math
#import os

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


const pi = 3.141592653589

var
  generatorthread: Thread[void]
  currentframe: int = 0
  params = GeneratorParams(leftfreq:440,rightfreq:440,leftvol:0.3,rightvol:0.3)


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
        if active==false: 
          active = true
          currentframe = 0
      of setinactive: 
          if active:
            active = false 
      of terminate:
        audiochannel.send(AudioMessage(kind: stop))
        break
    
    if active:
      if audiochannel.peek() < 10:
        
        t = linspace(currentframe, currentframe + int(framesPerBuffer))
        for i in 0..<framesPerBuffer: 
          t[i] /= float32(sampleRate)
        
        for i in 0..<framesPerBuffer: 
          leftdata[i] = sin(params.leftfreq*(2*pi)*t[i])*params.leftvol
          rightdata[i] = sin(params.rightfreq*(2*pi)*t[i])*params.rightvol

        var msg = AudioMessage(kind: audio)
        msg.left = leftdata
        msg.right = rightdata
        audiochannel.send(msg)
        currentframe += int(framesPerBuffer)
    else:
      if audiochannel.peek() < 2:
        audiochannel.send(AudioMessage(kind: silent))

    # if t[framesPerBuffer-1] > 2:
    #   var msg = ControlMessage(kind: rightfreq)
    #   msg.rfreq = 348
    #   controlchannel.send(msg)

    # if t[framesPerBuffer-1] > 5:
    #   controlchannel.send(ControlMessage(kind: stopthread))


proc terminateThread* {.noconv.} =
  audiochannel.send(AudioMessage(kind: stop))
  if generatorthread.running():
    controlchannel.send(ControlMessage(kind: terminate))
    joinThread(generatorthread)
  #close(audiochannel)


#proc stopThread* {.noconv.} =
#  if generatorthread.running():
#    joinThread(generatorthread)
#  audiochannel.send(AudioMessage(kind: stop))
#  #close(audiochannel)

  
proc startThread* {.noconv.} =
  if generatorthread.running == false:
    generatorthread.createThread(runthread)
    #if audiochannel.peek() > 8: 



# Initialize module
addQuitProc(terminateThread)
audiochannel.open()
controlchannel.open()

when isMainModule:
  initstream()
  startThread()
  startstream()

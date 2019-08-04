import strutils, times, locks
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
  thread: Thread[void]
  currentframe: int = 0

proc runthread {.thread.} =
  var 
    t : array[framesPerBuffer, float32]
    audiodata : array[framesPerBuffer, float32]

  while true:
    #let msg : AudioMessage = audiochannel.()
    #case msg.kind
    #of audio:
    #  echo(msg.left[0])
    #of stop:
    #  break
    if audiochannel.peek() < 20:
      
      t = linspace(currentframe, currentframe + int(framesPerBuffer))
      for i in 0..<framesPerBuffer: 
        t[i] /= float32(sampleRate)
      
      for i in 0..<framesPerBuffer: 
        audiodata[i] = sin(freq*(2*pi)*t[i])*0.15

      var msg = AudioMessage(kind: audio)
      msg.left = audiodata
      audiochannel.send(msg)
      currentframe += int(framesPerBuffer)


    if t[framesPerBuffer-1] > 5:
      var msg = AudioMessage(kind: stop)
      audiochannel.send(msg)
      #terminateaudio()
      break

proc stopThread {.noconv.} =
  joinThread(thread)
  audiochannel.send(AudioMessage(kind: stop))
  close(audiochannel)
  


# Initialize module
addQuitProc(stopThread)
audiochannel.open()
thread.createThread(runthread)
initaudio()
if audiochannel.peek() > 15: 
  startaudio()
import strutils, times, locks

const framesPerBuffer* : culong = 2048


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



type
  AudioMessageKind* = enum
    audio, silent, stop

  AudioMessage* = object
    case kind*: AudioMessageKind
    of audio:
      left*: seq[float32]
      right*: seq[float32]
    of silent:
      nil
    of stop:
      nil

var
  channel: Channel[AudioMessage]
  thread: Thread[void]

proc runthread {.thread.} =

  while true:
    let msg = recv(channel)
    echo(msg.kind)
    case msg.kind
    of audio:
      echo( $msg.left[1000] & "  " & $msg.right[1000]  )
    of silent:
      discard
    of stop:
      break

proc stopthread {.noconv.} =
  channel.send(AudioMessage(kind: stop))
  joinThread(thread)
  close(channel)


channel.open()
thread.createThread(runthread)
addQuitProc(stopthread)

var msg = AudioMessage(kind: audio)
msg.left = linspace(0,1)
msg.right = linspace(1,2)

channel.send(msg)
channel.send(msg)
channel.send(msg)


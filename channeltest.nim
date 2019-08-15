import strutils, times, locks

const framesPerBuffer = 2048
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
  MessageKind = enum
    write, update, stop

  Message = object
    case kind: MessageKind
    of write:
      data1: seq[float32]
      data2: seq[float32]
    of update:
      nil
    of stop:
      nil

var
  channel: Channel[Message]
  thread: Thread[void]
  L: Lock

proc runthread {.thread.} =
  while true:
    let msg = recv(channel)
    echo(msg.kind)
    case msg.kind
    of write:
      acquire(L)# lock stdout
      for i in 0 ..< 3:
        echo(msg.data1[i])
      release(L)
    of update:
      echo("update")
    of stop:
      break

proc stopLog {.noconv.} =
  channel.send(Message(kind: stop))
  joinThread(thread)
  close(channel)


proc send(data: seq[float32]) =
  var msg = Message(kind: write, data1: data, data2: data)
  channel.send(msg)


# Initialize module
L.initLock()
channel.open()
thread.createThread(runthread)
addQuitProc(stopLog)

var t: seq[float32]
t = linspace(0,1)

for i in 0..100:
  t[0]+=1
  send(t)


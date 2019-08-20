import strutils, times, locks

type
  AudioMessageKind* = enum
    audio, silent, stop

  Message = object
    case kind: MessageKind
    of write:
      text: string
    of update:
      loggers: string
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
    of write:
      acquire(L)# lock stdout
      echo(msg.text)
      release(L)
    of update:
      echo("update")
    of stop:
      break

proc stopthread {.noconv.} =
  channel.send(AudioMessage(kind: stop))
  joinThread(thread)
  close(channel)


proc send(text: string) =
  var msg = Message(kind: write, text: text)
  channel.send(msg)


# Initialize module
L.initLock()
channel.open()
thread.createThread(runthread)
addQuitProc(stopthread)

send("Bananas")
send("Bananas")
send("Bananas")


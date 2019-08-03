import strutils, times, locks

type
  MessageKind = enum
    write, update, stop

  Message = object
    case kind: MessageKind
    of write:
      text: string
    of update:
      loggers: string
    of stop:
      nil

var
  channel: Channel[Message]
  thread: Thread[void]
  L: Lock

proc runthread {.thread.} =

  while true:
    let msg = recv(channel)
    case msg.kind
    of write:
      acquire(L)# lock stdout
      echo(msg.text)
      release(L)
    of update:
      echo("update")
    of stop:
      break

proc stopLog {.noconv.} =
  channel.send(Message(kind: stop))
  joinThread(thread)
  close(channel)


proc send(text: string) =
  var msg = Message(kind: write, text: text)
  channel.send(msg)


# Initialize module
L.initLock()
channel.open()
thread.createThread(runthread)
addQuitProc(stopLog)

send("Bananas")
send("Bananas")
send("Bananas")


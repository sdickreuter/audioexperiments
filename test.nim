import locks, os, strformat, threadpool

var sblock: Lock
var sharedbuff {.guard: sblock.}: seq[string] = newSeq[string](50)
var ptrsharedbuff {.guard: sblock.}: ptr seq[string] = addr(sharedbuff)

sharedbuff.add("") # init seq
initLock(sblock)

var begin = true

proc setProc (thrName:string, pause: int, buff : ptr seq[string]) =
  var i = 0
  while begin:
    {.locks: [sblock].}:
      for j in 1..5:
        buff[].add(fmt"{thrName}-{i}-{j}")
    sleep(pause)
    i += 1

proc outProc (pause: int, buff : ptr seq[string]) =
  var i = 0
  while begin:
    {.locks: [sblock].}:
      while ptrsharedbuff[].len > 0:
        echo buff[].pop()
      sleep(pause)
    i += 1

echo "PRESS [ENTER] TO STOP AND EXIT..."

spawn setProc("Thread One", 1000, ptrsharedbuff)
spawn setProc("Thread Two", 2000, ptrsharedbuff)
spawn outProc(3000, ptrsharedbuff)

discard stdin.readLine()

begin = false
sync()

deinitLock(sblock)

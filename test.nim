const framesPerBuffer = 32

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

var t : seq[float32]
t = linspace(0, 1)

echo(len(t))

for x in t:
  echo(x)
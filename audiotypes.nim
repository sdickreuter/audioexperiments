
const sampleRate* : cdouble = 44100
const framesPerBuffer* : culong = 2048

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

  GeneratorParams* = object
    leftfreq*: float32
    rightfreq*: float32

    leftvol*: float32
    rightvol*: float32

  ControlMessageKind* = enum
    leftfreq, rightfreq, leftvol, rightvol, setactive, setinactive, terminate

  ControlMessage* = object
    case kind*: ControlMessageKind
    of leftfreq:
      lfreq*: float32
    of rightfreq:
      rfreq*: float32
    of leftvol:
      lvol*: float32
    of rightvol:
      rvol*: float32
    of setactive:
      nil
    of setinactive:
      nil
    of terminate:
      nil

var audiochannel*: Channel[AudioMessage]
var controlchannel*: Channel[ControlMessage]
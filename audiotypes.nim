
const sampleRate* : cdouble = 44100
const framesPerBuffer* : culong = 2048

type
  AudioMessageKind* = enum
    audio, stop

  AudioMessage* = object
    case kind*: AudioMessageKind
    of audio:
      left*: array[framesPerBuffer, float32]
      right*: array[framesPerBuffer, float32]
    of stop:
      nil

var audiochannel*: Channel[AudioMessage]

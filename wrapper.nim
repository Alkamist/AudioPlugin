import ./vst2
export vst2

type
  HostAudioBuffer* = ptr UncheckedArray[ptr UncheckedArray[cdouble]]

  AudioPluginInitializer* = object
    version*: int
    programCount*: int
    parameterCount*: int
    inputCount*: int
    outputCount*: int
    processBlock*: proc(inputs, outputs: HostAudioBuffer, channelCount, blockSize: int)

template audioPluginEntry*(initializer: AudioPluginInitializer): untyped =
  proc vstDispatcher(effect: ptr AEffect, opcode, index: int32, value: int, `ptr`: pointer, opt: cfloat): int {.cdecl} =
    case opCode:

    of effClose.int32:
      dealloc(effect)

    of effGetVendorVersion.int32:
      return effect.version

    else:
      discard

  proc vstGetParameter(effect: ptr AEffect, index: int32): cfloat {.cdecl.} =
    discard

  proc vstSetParameter(effect: ptr AEffect, index: int32, parameter: cfloat) {.cdecl.} =
    discard

  proc vstProcessDoubleReplacing(effect: ptr AEffect, inputs, outputs: ptr ptr cdouble, sampleFrames: int32) {.cdecl.} =
    var inputs = cast[HostAudioBuffer](inputs)
    var outputs = cast[HostAudioBuffer](outputs)
    initializer.processBlock(inputs, outputs, effect.numInputs, sampleFrames)

  proc VSTPluginMain(vstHostCallback: AEffect): ptr AEffect {.exportc, dynlib.} =
    var effect = create(AEffect)

    effect.magic = CCONST('V', 's', 't', 'P')
    effect.flags = effFlagsCanDoubleReplacing
    effect.uniqueID = CCONST('A', 'S', 'D', 'F')
    effect.version = initializer.version.int32
    effect.numParams = initializer.parameterCount.int32
    effect.numPrograms = initializer.programCount.int32
    effect.numInputs = initializer.inputCount.int32
    effect.numOutputs = initializer.outputCount.int32
    effect.dispatcher =  vstDispatcher
    effect.getParameter = vstGetParameter
    effect.setParameter = vstSetParameter
    effect.processDoubleReplacing = vstProcessDoubleReplacing

    return effect
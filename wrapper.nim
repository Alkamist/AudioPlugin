import ./vst2
export vst2

type
  HostAudioBuffer* = ptr UncheckedArray[ptr UncheckedArray[cdouble]]

  AudioPlugin* = ref object
    version*: int
    programCount*: int
    parameterCount*: int
    inputCount*: int
    outputCount*: int
    processBlock*: proc(plugin: AudioPlugin, inputs, outputs: HostAudioBuffer, channelCount, blockSize: int)
    effect: AEffect

proc vstDispatcher(effect: ptr AEffect, opcode, index: int32, value: int, `ptr`: pointer, opt: cfloat): int {.cdecl} =
  let plugin = cast[AudioPlugin](effect.`object`)

  case opCode:

  of effClose.int32:
    GC_unref(plugin)

  of effGetVendorVersion.int32:
    return effect.version

  else:
    discard

proc vstGetParameter(effect: ptr AEffect, index: int32): cfloat {.cdecl.} =
  discard

proc vstSetParameter(effect: ptr AEffect, index: int32, parameter: cfloat) {.cdecl.} =
  discard

proc vstProcessDoubleReplacing(effect: ptr AEffect, inputs, outputs: ptr ptr cdouble, sampleFrames: int32) {.cdecl.} =
  let plugin = cast[AudioPlugin](effect.`object`)
  var inputs = cast[HostAudioBuffer](inputs)
  var outputs = cast[HostAudioBuffer](outputs)
  plugin.processBlock(plugin, inputs, outputs, effect.numInputs, sampleFrames)

proc newAudioPlugin*(version: int,
                     programCount: int,
                     parameterCount: int,
                     inputCount: int,
                     outputCount: int): AudioPlugin =
  result = AudioPlugin(
    effect: AEffect(
      magic: CCONST('V', 's', 't', 'P'),
      flags: effFlagsCanDoubleReplacing,
      uniqueID: CCONST('A', 'S', 'D', 'F'),
      version: version.int32,
      numParams: parameterCount.int32,
      numPrograms: programCount.int32,
      numInputs: inputCount.int32,
      numOutputs: outputCount.int32,
      dispatcher:  vstDispatcher,
      getParameter: vstGetParameter,
      setParameter: vstSetParameter,
      processDoubleReplacing: vstProcessDoubleReplacing,
    ),
  )
  result.effect.`object` = cast[pointer](result)

template exportAudioPlugin*(p: AudioPlugin): untyped =
  proc VSTPluginMain(vstHostCallback: AEffect): ptr AEffect {.exportc, dynlib.} =
    let pluginRef = p
    GC_ref(pluginRef)
    return pluginRef.effect.addr
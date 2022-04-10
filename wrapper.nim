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
    # onOpen*: proc(plugin: AudioPlugin)
    openEditor*: proc(plugin: AudioPlugin, parent: pointer)
    closeEditor*: proc(plugin: AudioPlugin)
    processBlock*: proc(plugin: AudioPlugin, inputs, outputs: HostAudioBuffer, channelCount, blockSize: int)
    effect*: AEffect

proc vstDispatcher(effect: ptr AEffect, opcode, index: int32, value: int, `ptr`: pointer, opt: cfloat): int {.cdecl} =
  let plugin = cast[AudioPlugin](effect.`object`)

  case opCode:

  # of effOpen.int32:
  #   if plugin.onOpen != nil:
  #     plugin.onOpen(plugin)

  of effClose.int32:
    GC_unref(plugin)

  # of effGetParamLabel.int32:
  #   discard
  # of effGetParamDisplay.int32:
  #   discard
  # of effGetParamName.int32:
  #   discard
  # of effGetParameterProperties.int32:
  #   discard
  # of effString2Parameter.int32:
  #   discard
  # of effSetSampleRate.int32:
  #   discard
  # of effSetBlockSize.int32:
  #   discard
  # of effMainsChanged.int32:
  #   discard
  # of effEditGetRect.int32:
  #   discard

  of effEditOpen.int32:
    if plugin.openEditor != nil:
      plugin.openEditor(plugin, `ptr`)

  of effEditClose.int32:
    if plugin.closeEditor != nil:
      plugin.closeEditor(plugin)

  # of __effIdentifyDeprecated.int32:
  #   discard
  # of effGetChunk.int32:
  #   discard
  # of effSetChunk.int32:
  #   discard
  # of effProcessEvents.int32:
  #   discard
  # of effCanBeAutomated.int32:
  #   discard
  # of effGetInputProperties.int32:
  #   discard
  # of effGetOutputProperties.int32:
  #   discard
  # of effGetPlugCategory.int32:
  #   discard
  # of effProcessVarIo.int32:
  #   discard
  # of effSetSpeakerArrangement.int32:
  #   discard
  # of effGetSpeakerArrangement.int32:
  #   discard
  # of effGetEffectName.int32:
  #   discard
  # of effGetProductString.int32:
  #   discard
  # of effGetVendorString.int32:
  #   discard

  of effGetVendorVersion.int32:
    return effect.version

  # of effCanDo.int32:
  #   discard
  # of effGetTailSize.int32:
  #   discard
  # of effVendorSpecific.int32:
  #   discard
  # of effGetProgram.int32:
  #   discard
  # of effSetProgram.int32:
  #   discard
  # of effGetProgramNameIndexed.int32:
  #   discard
  # of effSetProgramName.int32:
  #   discard
  # of effGetProgramName.int32:
  #   discard
  # of effGetMidiKeyName.int32:
  #   discard
  # of effGetVstVersion.int32:
  #   discard
  # of effEditKeyDown.int32,
  #    effEditKeyUp.int32:
  #   discard
  # of effEndSetProgram.int32,
  #    effBeginSetProgram.int32,
  #    effGetMidiProgramName.int32,
  #    effHasMidiProgramsChanged.int32,
  #    effGetMidiProgramCategory.int32,
  #    effGetCurrentMidiProgram.int32,
  #    effSetBypass.int32:
  #   discard

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
  if plugin.processBlock != nil:
    plugin.processBlock(plugin, inputs, outputs, effect.numInputs, sampleFrames)

proc newAudioPlugin*(version: int,
                     programCount: int,
                     parameterCount: int,
                     inputCount: int,
                     outputCount: int): AudioPlugin =
  result = AudioPlugin(
    effect: AEffect(
      magic: CCONST('V', 's', 't', 'P'),
      flags: effFlagsCanDoubleReplacing.int32 or effFlagsHasEditor.int32,
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

# template forwardDeclareReaperFunctions*(): untyped =
#   var ShowConsoleMsg {.inject.}: proc(msg: cstring) {.cdecl.}

# type
#   HostCallbackFn* = proc(effect: ptr AEffect, a, b: cint, arg: cint, data: pointer, c: cfloat)

# template exportAudioPlugin*(p: AudioPlugin): untyped =
#   proc VSTPluginMain(vstHostCallback: AEffect): ptr AEffect {.exportc, dynlib.} =
#     let pluginRef = p
#     GC_ref(pluginRef)

#     let callback = cast[HostCallbackFn](vstHostCallback)

#     ShowConsoleMsg = callback(nil, 0xdeadbeef.cint, 0xdeadf00d.cint, 0.cin, cast[pointer](cstring"ShowConsoleMsg"), 0.cfloat)

#     return pluginRef.effect.addr
import 'dart:ffi';
import 'dart:io';

final DynamicLibrary nativeVad = Platform.isAndroid
    ? DynamicLibrary.open("libnative_vad.so")
    : throw UnsupportedError("Only Android is currently supported");

final Pointer<Void> Function() vadCreate = nativeVad
    .lookup<NativeFunction<Pointer<Void> Function()>>("vad_create")
    .asFunction();

final int Function(Pointer<Void>, int) vadInit = nativeVad
    .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>("vad_init")
    .asFunction();

final int Function(Pointer<Void>, int) vadSetMode = nativeVad
    .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>("vad_set_mode")
    .asFunction();

final int Function(Pointer<Void>, int, Pointer<Int16>, int) vadProcess = nativeVad
    .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32, Pointer<Int16>, Int32)>>("vad_process")
    .asFunction();

final void Function(Pointer<Void>) vadFree = nativeVad
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>("vad_free")
    .asFunction();
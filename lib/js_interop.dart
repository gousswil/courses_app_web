@JS()
library js_interop;

import 'package:js/js.dart';
import 'dart:js_util';

@JS('recognizeFromFile')
external dynamic recognizeFromFile();

Future<T> jsPromiseToFuture<T>(dynamic jsPromise) =>
    promiseToFuture<T>(jsPromise);

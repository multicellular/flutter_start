import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastType {
  var type;
  var textColor;
  var backgroundColor;
  ToastType.error() {
    this.textColor = Colors.white;
    this.backgroundColor = Colors.red;
  }
  ToastType.success() {
    this.textColor = Colors.white;
    this.backgroundColor = Colors.blueAccent;
  }
  ToastType.tip() {
    this.textColor = Colors.white;
    this.backgroundColor = Colors.black;
  }
  factory ToastType(type) {
    if (type == 'error') {
      return new ToastType.error();
    } else if (type == 'success') {
      return new ToastType.success();
    } else {
      return new ToastType.tip();
    }
  }
}

void showToast(String msg, {ToastType type}) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIos: 1,
      backgroundColor: type.backgroundColor,
      textColor: type.textColor,
      fontSize: 16.0);
}

void cancelToast() {
  Fluttertoast.cancel();
}

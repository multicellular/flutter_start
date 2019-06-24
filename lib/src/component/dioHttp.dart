import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/config.dart';
import './toast.dart';

String baseUrl = DefaultConfig.baseUrl;

class DioHttp {
  DioHttp.person();

  static DioHttp _dioHttp = new DioHttp.person();
  factory DioHttp() => _dioHttp;
  Dio dio = new Dio();

  httpGet(path, {req, needToken = false, showTip = true}) async {
    Options options;
    // TODO 目前普遍传uid，后期修改
    if (needToken) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        options = Options(headers: {HttpHeaders.authorizationHeader: token});
      } else {
        if (showTip) {
          showToast('please login!', type: ToastType.error());
        }
        return Future.value();
      }
      int uid = prefs.get('uid');
      if (req == null) {
        req = <String, dynamic>{};
      }
      req['uid'] = uid;
    }
    return await dio
        .get('$baseUrl$path', queryParameters: req, options: options)
        .then((Response response) {
      if (response.data['code'] == 0) {
        return Future.value(response.data);
      } else {
        String msg = response.data['msg'] ?? 'server error !';
        showToast(msg, type: ToastType.error());
        // return Future.error(msg);
      }
    }).catchError((error) {
      // print(error);
    });
  }

  httpPost(path, {req, needToken = false, showTip = true}) async {
    Options options;
    // TODO 目前普遍传uid，后期修改
    if (needToken) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        options = Options(headers: {HttpHeaders.authorizationHeader: token});
      } else {
        if (showTip) {
          showToast('please login!', type: ToastType.error());
        }
        return Future.value();
      }

      int uid = prefs.get('uid');
      req['uid'] = uid;
    }
    return await dio
        .post('$baseUrl$path', data: req, options: options)
        .then((Response response) {
      if (response.data['code'] == 0) {
        // return response.data;
        return response.data;
      } else {
        String msg = response.data['msg'] ?? 'server error !';
        showToast(msg, type: ToastType.error());
        // return Future.error(msg);
      }
    }).catchError((error) {
      // return Future.error(error);
    });
  }
}

var dioHttp = new DioHttp();

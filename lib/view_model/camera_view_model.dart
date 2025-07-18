import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart'; // 新增EXIF导入

import 'package:image_picker/image_picker.dart';

class CameraViewModel extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isReady = false;
  double? _brightness1; // 第一张图亮度
  double? _brightness2; // 第二张图亮度
  bool _isFirstCapture = true; // 标记是否是第一次拍摄

  File? _file1; // 第一张照片文件
  File? _file2; // 第二张照片文件

  // EXIF参数字段
  double? _focalLength;
  double? _aperture;
  double? _exposureTime;
  double? _ISO; // ISO参数字段

  // Getter for focal length
  double? get focalLength => _focalLength;
  // Getter for aperture
  double? get aperture => _aperture;
  // Getter for exposure time
  double? get exposureTime => _exposureTime;
  // Getter for ISO
  double? get ISO => _ISO;

  // 新增getter
  File? get file1 => _file1;
  File? get file2 => _file2;
  double? get brightness1 => _brightness1;
  double? get brightness2 => _brightness2;
  bool get isFirstCapture => _isFirstCapture;

  bool get isReady => _isReady;
  double? get relativeBrightness => // 相对亮度百分比
  (_brightness1 != null && _brightness2 != null)
      ? (_brightness2! / _brightness1!) * 100
      : null;
  CameraController? get controller => _controller;

  Future<void> initCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras![0], ResolutionPreset.medium);
    await _controller!.initialize();
    _isReady = true;
    notifyListeners();
  }

  Future<void> uploadImage(BuildContext context, bool isFirst) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return; // 用户取消选择

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        // 计算平均亮度
        double sum = 0;
        for (var p in image) {
          sum += img.getLuminanceRgb(p.r, p.g, p.b);
        }
        final avgBrightness = sum / (image.width * image.height);

        // 存储数据
        if (isFirst) {
          _file1 = file;
          _brightness1 = avgBrightness;
        } else {
          _file2 = file;
          _brightness2 = avgBrightness;
        }
        notifyListeners();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('上传失败: ${e.toString()}')));
    }
  }

  double? _parseExifDouble(dynamic exifValue) {
    if (exifValue == null) return null;
    final valueStr = exifValue.toString();
    // 处理分数形式（如"35/10"）
    if (valueStr.contains('/')) {
      final parts = valueStr.split('/').map(double.parse).toList();
      return parts[0] / parts[1];
    }
    return double.tryParse(valueStr);
  }

  Future<void> captureAndAnalyze(BuildContext context) async {
    try {
      if (!_controller!.value.isInitialized || !_isReady) {
        throw Exception('相机未初始化完成');
      }

      final file = await _controller!.takePicture().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('拍照超时'),
      );

      final bytes = await File(file.path).readAsBytes();
      final image = img.decodeImage(bytes);
      final exifData = await readExifFromBytes(bytes); // 读取EXIF数据

      final currentFile = File(file.path);

      if (image != null) {
        // 解析EXIF参数（示例处理，需根据实际标签调整）
        _focalLength = _parseExifDouble(exifData['EXIF FocalLength']);
        _aperture = _parseExifDouble(exifData['EXIF FNumber']);
        _exposureTime = _parseExifDouble(exifData['EXIF ExposureTime']);
        _ISO = _parseExifDouble(exifData['EXIF ISOSpeedRatings']);

        // 计算平均亮度
        double sum = 0;
        for (var p in image) {
          sum += img.getLuminanceRgb(p.r, p.g, p.b);
        }
        final avgBrightness = sum / (image.width * image.height);

        // 曝光三要素归一化亮度（标准条件：ISO=100, f/1.0, t=1s）
        double? normalizedBrightness;
        if (_exposureTime != null &&
            _aperture != null &&
            _ISO != null &&
            _aperture! > 0 &&
            _exposureTime! > 0 &&
            _ISO! > 0) {
          normalizedBrightness =
              avgBrightness *
              (100 / _ISO!) *
              (_aperture! * _aperture!) /
              (_exposureTime!);
        } else {
          normalizedBrightness = avgBrightness;
        }

        // 根据当前拍摄状态存储数据
        if (_isFirstCapture) {
          _file1 = currentFile;
          _brightness1 = normalizedBrightness;
        } else {
          _file2 = currentFile;
          _brightness2 = normalizedBrightness;
        }
        _isFirstCapture = !_isFirstCapture; // 切换拍摄状态
        notifyListeners();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败: ${e.toString()}')));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart'; // 新增EXIF导入

class CameraViewModel extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isReady = false;
  double? _brightness1; // 第一张图亮度
  double? _brightness2; // 第二张图亮度
  bool _isFirstCapture = true; // 标记是否是第一次拍摄

  bool get isReady => _isReady;
  double? get brightness1 => _brightness1;
  double? get brightness2 => _brightness2;
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

      if (image != null) {
        // 计算平均亮度
        double sum = 0;
        for (var p in image) {
          sum += img.getLuminanceRgb(p.r, p.g, p.b);
        }
        final avgBrightness = sum / (image.width * image.height);

        // 存储亮度值（根据拍摄顺序）
        if (_isFirstCapture) {
          _brightness1 = avgBrightness;
        } else {
          _brightness2 = avgBrightness;
        }
        _isFirstCapture = !_isFirstCapture; // 切换拍摄状态

        // 打印调试获取的EXIF参数（可选）
        print('EXIF焦距: ${exifData['EXIF FocalLength']}');
        print('EXIF光圈: ${exifData['EXIF FNumber']}');
        print('EXIF曝光时间: ${exifData['EXIF ExposureTime']}');

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

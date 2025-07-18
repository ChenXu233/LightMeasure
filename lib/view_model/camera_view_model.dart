import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraViewModel extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isReady = false;
  double? _brightness;
  double? _lux;

  // 相机参数
  final TextEditingController focalLenController = TextEditingController(
    text: '4.0',
  );
  final TextEditingController apertureController = TextEditingController(
    text: '2.0',
  );
  final TextEditingController exposureController = TextEditingController(
    text: '0.01',
  );
  final TextEditingController kController = TextEditingController(text: '1.0');

  bool get isReady => _isReady;
  double? get brightness => _brightness;
  double? get lux => _lux;
  CameraController? get controller => _controller;

  Future<void> initCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras![0], ResolutionPreset.medium);
    await _controller!.initialize();

    // 初始化相机参数
    final camera = cameras![0];
    focalLenController.text = _getFocalLength(camera).toStringAsFixed(1);
    apertureController.text = _getAperture(camera).toStringAsFixed(1);

    // 设置初始曝光参数
    await _configureExposure();

    _isReady = true;
    notifyListeners();
  }

  Future<void> _configureExposure() async {
    try {
      await _controller!.setExposureMode(ExposureMode.auto);
      await _controller!.setExposurePoint(Offset.zero);
      exposureController.text = '0.01'; // 默认值
    } catch (e) {
      exposureController.text = '0.01'; // 回退默认值
    }
  }

  // 新增曝光时间设置方法
  Future<void> setExposureTime(double seconds) async {
    try {
      await _controller!.setExposureOffset(seconds);
      exposureController.text = seconds.toStringAsFixed(3);
      notifyListeners();
    } catch (e) {
      throw Exception('曝光设置失败: ${e.toString()}');
    }
  }

  // 添加获取相机参数的私有方法
  double _getFocalLength(CameraDescription camera) {
    // 实际设备可能返回不同值，这里使用典型手机摄像头参数
    return camera.sensorOrientation == 90 ? 4.0 : 5.2; // 根据传感器方向返回不同值
  }

  double _getAperture(CameraDescription camera) {
    // 大多数手机摄像头光圈在f/1.7到f/2.2之间
    return camera.lensDirection == CameraLensDirection.back ? 1.8 : 2.0;
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

      if (!File(file.path).existsSync()) {
        throw Exception('照片文件未生成');
      }

      final bytes = await File(file.path).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        double sum = 0;
        for (var p in image) {
          sum += img.getLuminanceRgb(p.r, p.g, p.b);
        }
        _brightness = sum / (image.width * image.height);
        _calculateLux(_brightness!);
        notifyListeners();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('拍照失败: ${e.toString()}')));
    }
  }

  void _calculateLux(double avgBrightness) {
    double f = double.tryParse(focalLenController.text) ?? 4.0;
    double a = double.tryParse(apertureController.text) ?? 2.0;
    double t = double.tryParse(exposureController.text) ?? 0.01;
    double k = double.tryParse(kController.text) ?? 1.0;
    _lux = k * avgBrightness * (f * f) / (a * t);
  }

  @override
  void dispose() {
    _controller?.dispose();
    focalLenController.dispose();
    apertureController.dispose();
    exposureController.dispose();
    kController.dispose();
    super.dispose(); // 添加父类方法调用
  }
}

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isReady = false;
  double? _brightness;
  double? _lux;

  // 相机内参
  final TextEditingController _focalLenController = TextEditingController(
    text: '4.0',
  ); // mm
  final TextEditingController _apertureController = TextEditingController(
    text: '2.0',
  ); // f-number
  final TextEditingController _exposureController = TextEditingController(
    text: '0.01',
  ); // s
  final TextEditingController _kController = TextEditingController(
    text: '1.0',
  ); // 校准系数

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras![0], ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() => _isReady = true);
  }

  Future<void> _captureAndAnalyze() async {
    try {
      if (!_controller!.value.isInitialized || !_isReady) {
        throw Exception('相机未初始化完成');
      }

      // 添加相机准备状态检查
      if (_controller!.value.isTakingPicture) return;
      await _controller!.lockCaptureOrientation(); // Windows平台需要锁定方向

      final file = await _controller!.takePicture().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('拍照超时'),
      );

      // 添加文件存在性检查
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
        double avg = sum / (image.width * image.height);
        setState(() => _brightness = avg);
        _calculateLux(avg);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('拍照失败: ${e.toString()}')));
    }
  }

  void _calculateLux(double avgBrightness) {
    double f = double.tryParse(_focalLenController.text) ?? 4.0;
    double a = double.tryParse(_apertureController.text) ?? 2.0;
    double t = double.tryParse(_exposureController.text) ?? 0.01;
    double k = double.tryParse(_kController.text) ?? 1.0;
    double lux = k * avgBrightness * (f * f) / (a * t);
    setState(() => _lux = lux);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: Text('相机亮度测量')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _focalLenController,
                          decoration: InputDecoration(labelText: '焦距 f (mm)'),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _apertureController,
                          decoration: InputDecoration(labelText: '光圈 f-number'),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _exposureController,
                          decoration: InputDecoration(labelText: '曝光时间 t (秒)'),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _kController,
                          decoration: InputDecoration(labelText: '校准系数 K'),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _captureAndAnalyze,
                    child: Text('拍照并分析亮度'),
                  ),
                  if (_brightness != null)
                    Text('平均像素亮度: ${_brightness!.toStringAsFixed(2)}'),
                  if (_lux != null)
                    Text('估算勒克斯: ${_lux!.toStringAsFixed(2)} lx'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _focalLenController.dispose();
    _apertureController.dispose();
    _exposureController.dispose();
    _kController.dispose();
    super.dispose();
  }
}

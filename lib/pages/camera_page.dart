import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../view_model/camera_view_model.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CameraViewModel()..initCamera(),
      child: _CameraPageView(),
    );
  }
}

class _CameraPageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CameraViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('亮度对比测量')),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, CameraViewModel vm) {
    if (!vm.isReady) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        children: [
          // 实时相机预览
          AspectRatio(
            aspectRatio: vm.controller != null
                ? vm.controller!.value.aspectRatio
                : 1.0,
            child: vm.controller != null
                ? CameraPreview(vm.controller!)
                : const SizedBox(),
          ),
          // 第一张照片预览（拍摄后显示）
          if (vm.file1 != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text('第一张照片'),
                  Image.file(vm.file1!, height: 150),
                  Text('亮度: ${vm.brightness1?.toStringAsFixed(2)}'),
                ],
              ),
            ),
          // 第二张照片预览（拍摄后显示）
          if (vm.file2 != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text('第二张照片'),
                  Image.file(vm.file2!, height: 150),
                  Text('亮度: ${vm.brightness2?.toStringAsFixed(2)}'),
                ],
              ),
            ),
          _buildControlPanel(context, vm),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, CameraViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton(
            // 按钮文本根据当前拍摄状态变化
            onPressed: () => vm.captureAndAnalyze(context),
            child: Text(vm.isFirstCapture ? '拍摄第一张' : '拍摄第二张'),
          ),
        ],
      ),
    );
  }
}

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
          AspectRatio(
            aspectRatio: vm.controller!.value.aspectRatio,
            child: CameraPreview(vm.controller!),
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
            onPressed: () => vm.captureAndAnalyze(context),
            child: Text(vm.brightness1 == null ? '拍摄第一张' : '拍摄第二张'),
          ),
          if (vm.brightness1 != null)
            Text('第一张亮度: ${vm.brightness1!.toStringAsFixed(2)}'),
          if (vm.brightness2 != null)
            Text('第二张亮度: ${vm.brightness2!.toStringAsFixed(2)}'),
          if (vm.relativeBrightness != null)
            Text('相对亮度: ${vm.relativeBrightness!.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

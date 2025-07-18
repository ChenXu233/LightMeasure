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
          // 第一张照片区域（未拍摄时显示全黑占位）
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text('第一张照片'),
                // 未拍摄时显示黑色容器
                vm.file1 != null
                    ? Image.file(vm.file1!, height: 150)
                    : Container(color: Colors.black, height: 150),
                Text('亮度: ${vm.brightness1?.toStringAsFixed(2) ?? '未获取'}'),
              ],
            ),
          ),
          // 第二张照片区域（未拍摄时显示全黑占位）
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text('第二张照片'),
                // 未拍摄时显示黑色容器
                vm.file2 != null
                    ? Image.file(vm.file2!, height: 150)
                    : Container(color: Colors.black, height: 150),
                Text('亮度: ${vm.brightness2?.toStringAsFixed(2) ?? '未获取'}'),
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
          // 拍摄按钮
          ElevatedButton(
            onPressed: () => vm.captureAndAnalyze(context),
            child: Text(vm.isFirstCapture ? '拍摄第一张' : '拍摄第二张'),
          ),
          const SizedBox(height: 8),
          // 上传按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => vm.uploadImage(context, true),
                child: const Text('上传第一张'),
              ),
              ElevatedButton(
                onPressed: () => vm.uploadImage(context, false),
                child: const Text('上传第二张'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

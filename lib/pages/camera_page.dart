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
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: AspectRatio(
                  aspectRatio: vm.controller != null
                      ? vm.controller!.value.aspectRatio
                      : 1.0,
                  child: vm.controller != null
                      ? CameraPreview(vm.controller!)
                      : const SizedBox(),
                ),
              ),
            ),
          ),
          // 第一张照片区域（未拍摄时显示全黑占位）
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text('第一张照片'),
                // 未拍摄时显示黑色容器
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: vm.file1 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: vm.controller!.value.aspectRatio,
                            child: Image.file(vm.file1!, fit: BoxFit.contain),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white38,
                            size: 40,
                          ),
                        ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '亮度: ${vm.brightness1?.toStringAsFixed(2) ?? '未获取'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: vm.file2 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: vm.controller!.value.aspectRatio,
                            child: Image.file(vm.file2!, fit: BoxFit.contain),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white38,
                            size: 40,
                          ),
                        ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '亮度: ${vm.brightness2?.toStringAsFixed(2) ?? '未获取'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
          // 拍摄按钮
          ElevatedButton(
            onPressed: () => vm.captureAndAnalyze(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
            ),
            child: Text(
              vm.isFirstCapture ? '拍摄第一张' : '拍摄第二张',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 上传按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => vm.uploadImage(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  '上传第一张',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white10,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => vm.uploadImage(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                ),
                child: const Text('上传第二张'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

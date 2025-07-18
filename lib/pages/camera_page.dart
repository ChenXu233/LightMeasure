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
      appBar: AppBar(title: const Text('相机亮度测量')),
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
          _buildParameterInputs(context, vm),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => vm.captureAndAnalyze(context),
            child: const Text('拍照并分析亮度'),
          ),
          if (vm.brightness != null)
            Text('平均像素亮度: ${vm.brightness!.toStringAsFixed(2)}'),
          if (vm.lux != null) Text('估算勒克斯: ${vm.lux!.toStringAsFixed(2)} lx'),
        ],
      ),
    );
  }

  Widget _buildParameterInputs(BuildContext context, CameraViewModel vm) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                context,
                vm.focalLenController,
                '焦距 f (mm)',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                context,
                vm.apertureController,
                '光圈 f-number',
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                context,
                vm.exposureController,
                '曝光时间 t (秒)',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(context, vm.kController, '校准系数 K')),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: _getSuffixIcon(controller, context),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) => _handleInputChange(controller, value, context),
    );
  }

  Widget? _getSuffixIcon(TextEditingController c, BuildContext context) {
    final vm = context.read<CameraViewModel>();
    if (c == vm.exposureController) {
      return IconButton(
        icon: const Icon(Icons.timer, size: 20),
        onPressed: () => _showExposureDialog(context),
      );
    }
    return const Tooltip(
      message: '自动获取参数',
      child: Icon(Icons.auto_awesome, size: 16),
    );
  }

  void _handleInputChange(
    TextEditingController c,
    String value,
    BuildContext context,
  ) {
    if (c == context.read<CameraViewModel>().exposureController) {
      final val = double.tryParse(value);
      if (val != null && val > 0) {
        context.read<CameraViewModel>().setExposureTime(val);
      }
    }
  }

  void _showExposureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('曝光时间设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('推荐范围：0.001s - 1.0s\n实际支持范围取决于设备'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                context.read<CameraViewModel>().setExposureTime(0.01);
                Navigator.pop(ctx);
              },
              child: const Text('重置默认值 (0.01s)'),
            ),
          ],
        ),
      ),
    );
  }
}

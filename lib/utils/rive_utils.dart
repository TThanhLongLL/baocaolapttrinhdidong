import 'package:rive/rive.dart';

class RiveUtils {
  static SMIBool? getRiveInput(Artboard artboard,
      {required String stateMachineName}) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, stateMachineName);

    if (controller == null) {
      print('⚠️ StateMachineController không tìm thấy: $stateMachineName');
      return null;
    }

    artboard.addController(controller);

    final input = controller.findInput<bool>("active") as SMIBool?;
    if (input == null) {
      print('⚠️ Input "active" không tìm thấy trong: $stateMachineName');
    }
    return input;
  }

  static void chnageSMIBoolState(SMIBool? input) {
    if (input == null) return;
    input.change(true);
    Future.delayed(
      const Duration(seconds: 1),
      () {
        input.change(false);
      },
    );
  }
}
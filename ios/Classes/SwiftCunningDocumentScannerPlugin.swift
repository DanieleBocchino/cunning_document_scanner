import Flutter
import UIKit
import Vision
import VisionKit

@available(iOS 13.0, *)
public class SwiftCunningDocumentScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
   var resultChannel :FlutterResult?
   var presentingController: VNDocumentCameraViewController?
   var noOfImages: Int = 0

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cunning_document_scanner", binaryMessenger: registrar.messenger())
    let instance = SwiftCunningDocumentScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getPictures" {

            guard let args = call.arguments as? [String: Any],
                  let noOfPagesArg = args["noOfPages"] as? Int else {
                result(FlutterError(code: "BAD_ARGS", message: "Missing argument 'noOfPages'", details: nil))
                return
            }
            noOfPages = noOfPagesArg 
            self.resultChannel = result

            let presentedVC: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
            self.presentingController = VNDocumentCameraViewController()
            self.presentingController!.delegate = self
            presentedVC?.present(self.presentingController!, animated: true)
        } else {
            result(FlutterMethodNotImplemented)
            return
        }
  }


    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        if noOfPages == 1 && scan.pageCount >= 1 {
            let tempDirPath = self.getDocumentsDirectory()
            let currentDateTime = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd-HHmmss"
            let formattedDate = df.string(from: currentDateTime)
            var filenames: [String] = []
            
            let page = scan.imageOfPage(at: 0)
            let url = tempDirPath.appendingPathComponent(formattedDate + "-0.png")
            try? page.pngData()?.write(to: url)
            filenames.append(url.path)
            
            resultChannel?(filenames)
        } else {
            let tempDirPath = self.getDocumentsDirectory()
            let currentDateTime = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd-HHmmss"
            let formattedDate = df.string(from: currentDateTime)
            var filenames: [String] = []
            for i in 0 ..< scan.pageCount {
                let page = scan.imageOfPage(at: i)
                let url = tempDirPath.appendingPathComponent(formattedDate + "-\(i).png")
                try? page.pngData()?.write(to: url)
                filenames.append(url.path)
            }
            resultChannel?(filenames)
        }
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }
}

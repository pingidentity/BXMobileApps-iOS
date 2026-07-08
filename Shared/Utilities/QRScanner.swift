//
//  QRScannerController.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 10/2/24.
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @EnvironmentObject var qrScannerModel: QRScannerViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            QRScanner(result: $qrScannerModel.scanResult, loadingCamera: $qrScannerModel.loadingCamera)
                .onChange(of: qrScannerModel.scanResult) { oldValue, newValue in
                    if let result = newValue {
                        qrScannerModel.handleScanResult(result)
                    }
                }
            
            if (qrScannerModel.loadingCamera) {
                VStack {
                    Spacer()
                    Text(LocalizedStringKey(qrScannerModel.loadingMessageKey))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .font(.system(size: 20))
                    ProgressView()
                        .controlSize(.large)
                    Spacer()
                }
            } else {
                Text(LocalizedStringKey(qrScannerModel.instructionMessageKey))
                    .padding()
                    .background(Color.bxPrimary)
                    .foregroundColor(.white)
                    .padding(.bottom, 66)
            }
        }
    }
}

struct QRScanner: UIViewControllerRepresentable {
    
    @Binding var result: String?
    @Binding var loadingCamera: Bool

    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController($loadingCamera)
        controller.delegate = context.coordinator

        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($result)
    }
}

class QRScannerController: UIViewController {
    
    @Binding var loadingCamera: Bool
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?

    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
    static var shared: QRScannerController?
    
    init(_ loadingCamera: Binding<Bool>, nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        self._loadingCamera = loadingCamera
        super.init(nibName:nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCameraLoading(loading: Bool) {
        DispatchQueue.main.async {
            self.loadingCamera = loading
        }
    }
    
    func closeCameraSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        QRScannerController.shared = self
        
        updateCameraLoading(loading: true)

        // Get the back-facing camera for capturing videos
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            updateCameraLoading(loading: false)
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            videoInput = try AVCaptureDeviceInput(device: captureDevice)

        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            updateCameraLoading(loading: false)
            return
        }

        // Set the input device on the capture session.
        captureSession.addInput(videoInput)

        // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)

        // Set delegate and use the default dispatch queue to execute the call back
        captureMetadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [ .qr ]

        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)

        // Start video capture.
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
            self.updateCameraLoading(loading: false)
        }

    }

}

class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    @Binding var scanResult: String?

    init(_ scanResult: Binding<String?>) {
        self._scanResult = scanResult
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            scanResult = nil
            return
        }

        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr,
           let result = metadataObj.stringValue {
            scanResult = result
        }
    }
}

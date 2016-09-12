//
//  ViewController.m
//  photographDemo
//
//  Created by liguohuai on 16/4/3.
//  Copyright © 2015年 Renford. All rights reserved.
//
#define kScreenBounds   [UIScreen mainScreen].bounds
#define kScreenWidth  kScreenBounds.size.width*1.0
#define kScreenHeight kScreenBounds.size.height*1.0

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate,
UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
}

//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic)AVCaptureDevice *device;

//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property(nonatomic)AVCaptureDeviceInput *input;

//当启动摄像头开始捕获输入
@property(nonatomic)AVCaptureMetadataOutput *output;

@property (nonatomic)AVCaptureStillImageOutput *ImageOutPut;

//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property(nonatomic)AVCaptureSession *session;

//图像预览层，实时显示捕获的图像
@property(nonatomic)AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic)UIButton *wineButton;
@property (nonatomic)UIButton *PhotoButton;
@property (nonatomic)UIButton *flashButton;
@property (nonatomic)UIButton *rightButton;
@property (nonatomic)UIImageView *imageView;
@property (nonatomic)UIView *focusView;
@property (nonatomic)BOOL isflashOn;
@property (nonatomic)UIImage *image;
@property (nonatomic)UISegmentedControl *segmentControl;
@property (nonatomic, weak)UIView *firstview;
@property (nonatomic, weak)UIView *thirdview;

@property (nonatomic)CAShapeLayer *loopLayer;

@property (nonatomic)BOOL canCa;
@property (nonatomic) UIImagePickerController *imagePicker;

@property (nonatomic)NSArray *mySegments;
@property (nonatomic)NSInteger tag;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _mySegments = [[NSArray alloc] initWithObjects: @"White",
                   @"Yellow", @"Orange", nil];
    

    _tag = 2;
    _canCa = [self canUserCamear];
    if (_canCa) {
        [self customCamera];
        [self customUI];
        
    }else{
        return;
    }
}

- (void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear: animated];
    if (self.session) {
        [self.session stopRunning];
    }
}

- (void)customUI{
    //底部背景颜色
    UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight*0.8, kScreenWidth, kScreenHeight*0.2)];
    footView.backgroundColor= [UIColor colorWithRed:(175/255.0) green:(18/255.0) blue:(38/255.0) alpha:1] ;
    [self.view addSubview:footView];
    
    _PhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _PhotoButton.frame = CGRectMake(kScreenWidth*1/2.0-30, kScreenHeight-80, 60, 60);
    [_PhotoButton setImage:[UIImage imageNamed:@"photograph"] forState: UIControlStateNormal];
    [_PhotoButton setImage:[UIImage imageNamed:@"photograph_Select"] forState:UIControlStateNormal];
    [_PhotoButton addTarget:self action:@selector(shutterCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_PhotoButton];
    
    _segmentControl= [[UISegmentedControl alloc] initWithItems:_mySegments];
    _segmentControl.frame = CGRectMake(kScreenWidth*1/3.0-30, kScreenHeight*1/2.0+60, 150.0f, 30.0f);
    _segmentControl.tintColor = [UIColor whiteColor];
    _segmentControl.layer.cornerRadius = 15.0;
    [_segmentControl setSelectedSegmentIndex:1];
    [_segmentControl addTarget:self action:@selector(valueChanged:)
              forControlEvents:UIControlEventValueChanged];
    
    [self drawIrrugularRect];
    [self startAnimationForSetupIrregular];
    [self.view addSubview:_segmentControl];
    
    _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _flashButton.frame = CGRectMake(kScreenWidth-55, kScreenHeight*1/2.0+60, 60, 60);
    [_flashButton setTitle:@"闪光灯" forState:UIControlStateNormal];
    [_flashButton addTarget:self action:@selector(FlashOn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_flashButton];
    
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(kScreenWidth*1/4.0-30, kScreenHeight-80, 60, 60);
    [leftButton setTitle:@"取消" forState:UIControlStateNormal];
    leftButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [leftButton addTarget:self action:@selector(cancle) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:leftButton];
    
    _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _rightButton.frame = CGRectMake(kScreenWidth*3/4.0, kScreenHeight-80, 60, 60);
    
    [_rightButton setTitle:@"相册" forState:UIControlStateNormal];
    _rightButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_rightButton addTarget:self action:@selector(pickOrUseImageFromAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_rightButton];
}

- (void)customCamera{
    self.view.backgroundColor = [UIColor whiteColor];
    
    //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //使用设备初始化输入
    self.input = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
    
    //生成输出对象
    self.output = [[AVCaptureMetadataOutput alloc]init];
    self.ImageOutPut = [[AVCaptureStillImageOutput alloc] init];
 
    //生成会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc]init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        
        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
        
    }
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    
    if ([self.session canAddOutput:self.ImageOutPut]) {
        [self.session addOutput:self.ImageOutPut];
    }
    
    //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    self.previewLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight*0.8);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    //开始启动
    [self.session startRunning];
    if ([_device lockForConfiguration:nil]) {
        if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [_device setFlashMode:AVCaptureFlashModeAuto];
        }
        //自动白平衡
        if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [_device unlockForConfiguration];
    }
}
- (void)FlashOn{
    if ([_device lockForConfiguration:nil]) {
        if (_isflashOn) {
            if ([_device isFlashModeSupported:AVCaptureFlashModeOff]) {
                [_device setFlashMode:AVCaptureFlashModeOff];
                _isflashOn = NO;
            }
        }else{
            if ([_device isFlashModeSupported:AVCaptureFlashModeOn]) {
                [_device setFlashMode:AVCaptureFlashModeOn];
                _isflashOn = YES;
            }
        }
        [_device unlockForConfiguration];
    }
}

-(void)pickImageFromAlbum{
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.delegate=self;
    _imagePicker.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;
    _imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    _imagePicker.allowsEditing = YES;
    [self presentViewController:_imagePicker animated:YES completion:nil];

}

-(void)useImageFromAlbum{
    NSLog(@"upload action is waiting");
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}

#pragma mark - 截取照片
- (void) shutterCamera{
    AVCaptureConnection * videoConnection = [self.ImageOutPut connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    
    [self.ImageOutPut captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        self.image = [UIImage imageWithData:imageData];
        [self.session stopRunning];
        [self saveImageToPhotoAlbum:self.image];
        
        [self imageViewPreview:_image];
        [self animationPreview];
        

//        self.imageView = [[UIImageView alloc]initWithFrame:self.previewLayer.frame];
//        [self.view insertSubview:_imageView belowSubview:_PhotoButton];
//        self.imageView.layer.masksToBounds = YES;
//        self.imageView.image = _image;
        NSLog(@"image size = %@",NSStringFromCGSize(self.imageView.image.size));
    }];
}

#pragma - 保存至相册
- (void)saveImageToPhotoAlbum:(UIImage*)savedImage{
//    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
    UIImageWriteToSavedPhotosAlbum(savedImage, self, NULL, NULL);
}

// 指定回调方法
- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo{
    UIImage *resizedImage = [self thumbnailWithImageWithoutScale:image size:CGSizeMake(480,640)];
    
    //对图片大小进行压缩
    UIImageJPEGRepresentation(resizedImage, 0.7);
    NSLog(@"保存图片的大小：%lu", [UIImageJPEGRepresentation(resizedImage, 0.7) length]);
}

-(void)cancle{
    [self.imageView removeFromSuperview];
    [self.session startRunning];
}

#pragma mark - 检查相机权限
- (BOOL)canUserCamear{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"请打开相机权限" message:@"设置-隐私-相机" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        alertView.tag = 100;
        [alertView show];
        return NO;
    }else{
        return YES;
    }
    return YES;
}

#pragma mark -- 实现imagePicker的代理方法

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    //取得所选取的图片,原大小,可编辑等，info是选取的图片的信息字典
    UIImage *selectImage = [info objectForKey:UIImagePickerControllerEditedImage];
    
    [self imageViewPreview:selectImage];
    [self animationPreview];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark -- 缩略图
- (UIImage *)thumbnailWithImageWithoutScale:(UIImage *)image size:(CGSize)asize
{
    UIImage *newimage;
    if (nil == image) {
        newimage = nil;
    }else{
        CGSize oldsize = image.size;
        CGRect rect;
        if (asize.width/asize.height > oldsize.width/oldsize.height) {
            rect.size.width = asize.height*oldsize.width/oldsize.height;
            rect.size.height = asize.height;
            rect.origin.x = (asize.width - rect.size.width)/2;
            rect.origin.y = 0;
        }else{
            rect.size.width = asize.width;
            rect.size.height = asize.width*oldsize.height/oldsize.width;
            rect.origin.x = 0;
            rect.origin.y = (asize.height - rect.size.height)/2;
        }
        UIGraphicsBeginImageContext(asize);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
        UIRectFill(CGRectMake(0, 0, asize.width, asize.height));//clear background
        [image drawInRect:rect];
        newimage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return newimage;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0 && alertView.tag == 100) {
        NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (void) valueChanged:(UISegmentedControl *)paramSender{
    if (_loopLayer != nil) {
        [_loopLayer removeFromSuperlayer];
        _loopLayer = nil;
    }
    switch (paramSender.selectedSegmentIndex) {
        case 0:{
            [self.thirdview removeFromSuperview];
            [self firstview];
            
            [self startAnimationForSegment:_tag compareIndex:0 forView:_firstview];
            break;
        }
        case 1:{
            [self.firstview removeFromSuperview];
            [self.thirdview removeFromSuperview];
//            [self startAnimationForSegment:_tag compareIndex:1 forView:_loopLayer.layer];
            [self drawIrrugularRect];
            break;
        }
        case 2:{
            [self.firstview removeFromSuperview];
            [self thirdview];
            
            [self startAnimationForSegment:_tag compareIndex:2 forView:_thirdview];
            break;
        }
    }
    _tag = paramSender.selectedSegmentIndex;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)pickOrUseImageFromAlbum:(UIButton*)sender {
    if ([sender.titleLabel.text isEqualToString:@"相册"]) {
        [sender setTitle: @"相册" forState: UIControlStateNormal];
        [self pickImageFromAlbum];
    }
    else {
        [sender setTitle: @"USE" forState: UIControlStateNormal];
        [self useImageFromAlbum];
    }
}

-(UIView *)firstview {
    if(_firstview == nil){
        UIView *myBox  = [[UIView alloc] initWithFrame:CGRectMake(18, 35, kScreenWidth-18*2, kScreenHeight-35*2-kScreenHeight*0.2)];
        myBox.layer.borderColor = [UIColor whiteColor].CGColor;
        myBox.layer.borderWidth = 2.0;
        _firstview = myBox;
        [self.view insertSubview:_firstview belowSubview:_segmentControl];
    }
    return _firstview;
}

-(UIView *)thirdview{
    if(_thirdview == nil){
        UIView *myBox  = [[UIView alloc] initWithFrame:CGRectMake(18, 35, kScreenWidth-18*2, kScreenHeight-35*2-kScreenHeight*0.2)];
        myBox.layer.borderColor = [UIColor orangeColor].CGColor;
        myBox.layer.borderWidth = 2.0;
        _thirdview = myBox;
        [self.view insertSubview:_thirdview belowSubview:_segmentControl];
    }
    return _thirdview;
}

-(void)drawIrrugularRect{
    // 创建layer并设置属性
    _loopLayer=[CAShapeLayer new];
    _loopLayer.frame=CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    _loopLayer.fillColor=nil;
    _loopLayer.lineCap = kCALineCapRound;
    _loopLayer.strokeColor = [UIColor whiteColor].CGColor;
    _loopLayer.lineWidth = 2;
    [self.view.layer addSublayer:_loopLayer];
    
    // 创建贝赛尔路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(18,35)];
    [path addLineToPoint:CGPointMake(18,kScreenHeight*0.8-40-35)];
    [path addQuadCurveToPoint:CGPointMake(kScreenWidth - 18,kScreenHeight*0.8-40-35)
                 controlPoint: CGPointMake((kScreenWidth - 18)*1/2.0,kScreenHeight*0.8-40)];
    [path addLineToPoint:CGPointMake(kScreenWidth - 18,35)];
    [path addQuadCurveToPoint:CGPointMake(18,35)
                 controlPoint: CGPointMake((kScreenWidth - 18)*1/2.0,0)];
    
    // 关联layer和贝赛尔路径
    _loopLayer.path = path.CGPath;
}

// 第一次进入segmentIndex ＝ 1 时启动动画
-(void)startAnimationForSetupIrregular{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @(0.0);
    animation.toValue = @(1.0);
    _loopLayer.autoreverses = NO;
    animation.duration = 1.0;
    
    // 设置layer的animation
    [_loopLayer addAnimation:animation forKey:nil];
}

-(void)startAnimationForSegment:(NSInteger)before compareIndex:(NSInteger)after forView:(UIView*)view{
    //创建CATransition对象
    CATransition *animation = [CATransition animation];
    animation.duration = 3.0f;
    animation.type = @"kCATransitionMoveIn";
    if (before < after)
        animation.subtype = kCATransitionFromRight;
    else
        animation.subtype = kCATransitionFromLeft;
    animation.timingFunction = UIViewAnimationOptionCurveEaseInOut;
    [view.layer addAnimation:animation forKey:@"animation"];
}

-(void)animationPreview{
    [UIView animateWithDuration:0.5f animations:^{
        // 放大并模糊
        self.imageView.alpha = 0.5f;
        self.imageView.layer.transform = CATransform3DMakeScale(1.2f, 1.2f, 1.f);
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.5f animations:^{
            // 恢复并清晰
            self.imageView.alpha = 1.f;
            self.imageView.layer.transform = CATransform3DMakeScale(1.f, 1.f, 1.f);
        }];
    }];
}

-(void)compressImageView:(UIImage *)selectImage{
    //设置image的尺寸
    UIImage *resizedImage = [self thumbnailWithImageWithoutScale:selectImage size:CGSizeMake(480,640)];
    self.imageView.image = resizedImage;
    //对图片大小进行压缩
    UIImageJPEGRepresentation(resizedImage, 0.7);
}

#pragma grammer 设置预览的图片
-(void)imageViewPreview:(UIImage*) selectImage{
    [self.previewLayer removeFromSuperlayer];
    _segmentControl.hidden = TRUE;
    _flashButton.hidden = TRUE;
    _firstview.layer.hidden = TRUE;
    _loopLayer.hidden = FALSE;
    _thirdview.layer.hidden = TRUE;
    
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(18, 10, kScreenWidth-18*2, kScreenHeight-20*1-kScreenHeight*0.2-20)];
    [self.view insertSubview:_imageView belowSubview:_PhotoButton];
    [self compressImageView:selectImage];
    self.imageView.layer.masksToBounds = YES;
    
    UILabel *nameLab = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight*0.8-60, kScreenWidth, 25)];
    nameLab.text = @"Preview";
    nameLab.textColor = [UIColor colorWithRed:(82/255.0) green:(82/255.0) blue:(82/255.0) alpha:1] ;
    nameLab.textAlignment = NSTextAlignmentCenter;
    [self.view insertSubview:nameLab belowSubview:_PhotoButton];
    
    [_rightButton setTitle:@"USE" forState:UIControlStateNormal];
    [_loopLayer setOpacity:0];
    [CATransaction setDisableActions:YES];
}
@end

//
//  ViewController.m
//  ios-app-download
//
//  Created by zhangrongwu on 2017/12/13.
//  Copyright © 2017年 ENN. All rights reserved.
//

#import "ViewController.h"
#import "ICSectorProgressView.h"
#import "ZipArchive.h"
#import "AFNetworking.h"
#define UNZIPPATH  [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
#define BASEURL  @"服务器api"
@interface ViewController ()
@property (nonatomic, strong) UIView *weexView;
@property (nonatomic, assign) CGFloat weexHeight;

/** 下载进度条 */
@property (strong, nonatomic)UIProgressView * progressView;
/** 下载进度条Lable */
@property (strong, nonatomic)UILabel * progressLabel;

/** AFN 断点下载  需要的属性*/
/** 文件的总长度 */
@property (nonatomic , assign)NSInteger fileLength;
/** 当前下载长度 */
@property (nonatomic , assign)NSInteger currentLength;
/** 文件对象*/
@property (nonatomic , strong)NSFileHandle * fileHandle;
/** 下载任务 */
@property (nonatomic , strong)NSURLSessionDataTask * downloadTask;
/**  AFURLSessionManager */
@property (nonatomic , strong)AFURLSessionManager * manager;

@property (nonatomic , strong)UIButton * openDownload;

@property (nonatomic , strong)UIButton * topDownload;

@property (nonatomic, strong)ICSectorProgressView *sectorView;
@property (nonatomic, strong)UIImageView *appImageView;

@property (nonatomic, strong)UIImageView *appleAppImageView;
@end

@implementation ViewController
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self canBecomeFirstResponder])
    {
        [[UIApplication sharedApplication] setApplicationSupportsShakeToEdit:YES];
        [self becomeFirstResponder];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _weexHeight = self.view.frame.size.height;
    
    //    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    //    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    //    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
    //        statusBar.backgroundColor = [UIColor colorWithRed:1.00 green:0.40 blue:0.00 alpha:1.0];
    //    }
    [self.view addSubview:self.appImageView];
    [self.view addSubview:self.openDownload];
    
    [self.view addSubview:self.appleAppImageView];
    [self.progressView setProgress:0.0 animated:YES];
    self.progressLabel.text = @"文件未下载";
    // icon_job_appBG
    NSString *path = [NSString stringWithFormat:@"%@/%@",UNZIPPATH,@"jandan"];
    NSLog(@"File downloaded to:%@",path);
    if([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        self.openDownload.highlighted = YES;
        self.progressLabel.text = @"文件已下载";
    }
    // Do any additional setup after loading the view, typically from a nib.
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
/**
 *  manager  懒加载
 */
-(AFURLSessionManager *)manager
{
    if(!_manager)
    {
        NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 创建会话管理者
        _manager = [[AFURLSessionManager alloc]initWithSessionConfiguration:configuration];
    }
    return _manager;
}


/**
 *  downloadTask 懒加载
 */
-(NSURLSessionDataTask *)downloadTask
{
    if(!_downloadTask)
    {
        //        NSURL * url = [NSURL URLWithString:@"https://icome.enncloud.cn:44184/icomeapps/ios/test/jandan.zip"];
        //        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/icomeapps/ios/test/jandan.zip", BASEURL]];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/icomeapps/ios/test/ICome.ipa", BASEURL]];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
        
        NSString * range = [NSString stringWithFormat:@"bytes-%zd-",self.currentLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        __weak typeof(self) weakSelf = self;
        
        _downloadTask = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            NSLog(@"dataTaskWithRequest");
            
            weakSelf.currentLength = 0;
            weakSelf.fileLength = 0;
            
            
            //      关闭fileHandle
            
            [weakSelf.fileHandle closeFile];
            weakSelf.fileHandle = nil;
            [weakSelf UnzipCloseWFile];
            
        }];
        
        [self.manager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
            NSLog(@"NSURLSessionResponseDisposition");
            NSLog(@"response.expectedContentLength = %lld",response.expectedContentLength);
            weakSelf.fileLength = response.expectedContentLength;
            NSLog(@"fileLength = %ld,currentLength = %ld",weakSelf.fileLength,weakSelf.currentLength);
            NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"jandan.zip"];;
            //[NSString stringWithFormat:@"/Users/linchuanbin/Desktop/mlqFile/%@",@"img.zip"];
            //[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"QQ_V5.4.0.dmg"];
            NSLog(@"File downloaded to:%@",path);
            NSFileManager * manager = [NSFileManager defaultManager];
            if(![manager fileExistsAtPath:path])
            {
                [manager createFileAtPath:path contents:nil attributes:nil];
            }
            //创建空的文件
            //            [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
            weakSelf.fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
            return NSURLSessionResponseAllow;
        }];
        
        [self.manager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
            if(weakSelf.currentLength < weakSelf.fileLength){
                NSLog(@"setDataTaskDidReceiveDataBlock");
                //指定数据的写入位置 -- 文件内容的最后面
                [weakSelf.fileHandle seekToEndOfFile];
                //向沙盒写入数据
                [weakSelf.fileHandle writeData:data];
                // 拼接文件总长度
                weakSelf.currentLength += data.length;
                //获取主线程，不然无法正确显示进度。
                
                NSOperationQueue * mainQueue = [NSOperationQueue mainQueue];
                [mainQueue addOperationWithBlock:^{
                    //下载进度
                    if(weakSelf.fileLength == 0){
                        weakSelf.progressView.progress = 0.0;
                        weakSelf.progressLabel.text = [NSString stringWithFormat:@"当前下载进度：00.00%%"];
                    }else{
                        weakSelf.progressView.progress = 1.0 * weakSelf.currentLength/weakSelf.fileLength;
                        weakSelf.progressLabel.text = [NSString stringWithFormat:@"当前下载进度：%.2f%%",100.0*weakSelf.currentLength/weakSelf.fileLength];
                    }
                    // 以下操作可根据实际情况提前写一遍
                    weakSelf.sectorView.progress = weakSelf.progressView.progress;
                    weakSelf.sectorView.hidden = NO;
                    
                }];
            }
        }];
        
    }
    return _downloadTask;
}


-(UIProgressView *)progressView
{
    if(!_progressView)
    {
        _progressView = [[UIProgressView alloc]initWithFrame:CGRectMake(50, 80, 200, 30)];
        _progressView.transform = CGAffineTransformMakeScale(1.0f, 4.0f);
        _progressView.backgroundColor = [UIColor clearColor];
        _progressView.progressViewStyle = UIProgressViewStyleDefault;
        _progressView.alpha = 1.0;
        _progressView.progressTintColor = [UIColor yellowColor];
        _progressView.trackTintColor = [UIColor cyanColor];
        _progressView.hidden = YES;
        //        _progressView.progress = 0.0;
        [self.view addSubview:_progressView];
    }
    return _progressView;
}

-(UILabel *)progressLabel
{
    if(!_progressLabel)
    {
        _progressLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 30, 200, 50)];
        [self.view addSubview:_progressLabel];
    }
    return _progressLabel;
}

-(UIButton *)openDownload
{
    if(!_openDownload)
    {
        _openDownload = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 100, 50)];
        
        [_openDownload setTitle:@"下载" forState:UIControlStateNormal];
        [_openDownload setTitle:@"暂停" forState:UIControlStateSelected];
        [_openDownload setTitle:@"打开" forState:UIControlStateHighlighted];
        [_openDownload setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_openDownload addTarget:self action:@selector(openDownload:) forControlEvents:UIControlEventTouchUpInside];
        //        [_openDownload addTarget:self action:@selector(UnzipCloseFile:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _openDownload;
}


-(ICSectorProgressView *)sectorView {
    if (!_sectorView) {
        _sectorView = [[ICSectorProgressView alloc] initWithFrame:self.appImageView.bounds];
        _sectorView.borderWidth = 20; //  默认为20
        [_sectorView beginSetDefault];
        _sectorView.hidden = YES;
    }
    return _sectorView;
}

-(UIImageView *)appImageView {
    if (!_appImageView) {
        _appImageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
        _appImageView.layer.cornerRadius = 8;
        _appImageView.layer.masksToBounds = YES;
        _appImageView.image = [UIImage imageNamed:@"icon_job_appBG"];
        [_appImageView addSubview:self.sectorView];
    }
    return _appImageView;
}

-(UIImageView *)appleAppImageView {
    if (!_appleAppImageView) {
        _appleAppImageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 300, 100, 100)];
        _appleAppImageView.layer.cornerRadius = 8;
        _appleAppImageView.layer.masksToBounds = YES;
        _appleAppImageView.image = [UIImage imageNamed:@"icon_job_appBG"];
    }
    return _appleAppImageView;
}

-(void)openDownload:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if(sender.selected)
    {
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"jandan.zip"];
        //[NSString stringWithFormat:@"%@/%@",UNZIPPATH,@"wx_sample_module.zip"];
        //[NSString stringWithFormat:@"/Users/linchuanbin/Desktop/mlqFile/%@",@"img.zip"];
        
        NSInteger currentLength = [self fileLengthForPath:path];
        if(currentLength > 0)
        {
            if(self.currentLength <  currentLength)
            {
                self.currentLength = currentLength;
            }
            
        }
        [self.downloadTask resume];
    }else if(sender.highlighted){
    }else {
        [self.downloadTask suspend];
        self.downloadTask = nil;
    }
}

- (void)UnzipCloseWFile{
    
    
    //源文件路径
    NSString *sourceFilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"jandan.zip"];
    //目的文件路径
    NSString *destinationPath = [NSString stringWithFormat:@"%@",UNZIPPATH];
    
    ZipArchive* zip = [[ZipArchive alloc] init];
    if( [zip UnzipOpenFile:sourceFilePath] ){
        BOOL result = [zip UnzipFileTo:destinationPath overWrite:YES];
        if( NO==result ){
            //添加代码
            NSLog(@"解压失败");
        }else{
            NSLog(@"解压成功");
        }
        [zip UnzipCloseFile];
    }
    
}

-(NSInteger)fileLengthForPath:(NSString *)path
{
    NSInteger fileLength = 0;
    NSFileManager * fileManager = [[NSFileManager alloc] init];
    if([fileManager fileExistsAtPath:path])
    {
        NSError * error = nil;
        NSDictionary * fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if(!error&&fileDict){
            fileLength = [fileDict fileSize];
            
        }
    }
    return fileLength;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end

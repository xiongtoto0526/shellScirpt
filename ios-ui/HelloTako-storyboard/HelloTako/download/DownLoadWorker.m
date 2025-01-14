
#import "DownloadWorker.h"

#import "UIHelper.h"
#import "Constant.h"
#import "Server.h"

@interface DownloadWorker ()<NSURLConnectionDataDelegate>

// 文件句柄对象
@property (nonatomic, strong) NSFileHandle *writeHandle;

// 文件的总长度
@property (nonatomic, assign) long long totalLength;

// 当前已经写入的总大小
@property (nonatomic, assign) long long  currentLength;

// 下载进度百分比
@property (nonatomic, assign) long long  progress;

@property (nonatomic, strong) NSURLConnection *connection;

// 本地home路径
@property (nonatomic, copy) NSString  *homePath;

// 下载到本地的路径
@property (nonatomic, copy) NSString  *localPath;

// 下载文件保存到本地时的文件名
@property (nonatomic, copy) NSString  *filename;

@end



@implementation DownloadWorker


-(id)init{
    if ((self = [super init])){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.homePath =[paths firstObject];
    }
    return self;
}

#pragma mark - NSURLConnectionDataDelegate代理方法

/**
 *  请求失败时调用（请求超时、网络异常）
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSString *messageString = [error localizedDescription];
    //    NSString *moreString = [error localizedFailureReason];
    NSLog(@"下载结束，结果为失败。错误信息: %@",messageString);
    self.isFree=YES;
    [self.delegate downloadFinish:NO msg:@"无法连接到服务器，请重试。" tag:self.tag];
}



/**
 *  1.接收到服务器的响应就会进入该回调
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
    // 校验下载链接是否为ipa文件。
    if (![[response.suggestedFilename pathExtension] isEqualToString:@"ipa"]) {
        [self.connection cancel];
        self.connection = nil;
        self.isFree = YES;
        [self.delegate downloadFinish:NO msg:@"文件格式错误。" tag:self.tag];
        return;
    }
    
    
    self.filename = [NSString stringWithFormat:@"%@.ipa",self.tag];
    //    self.homePath = [self.homePath  stringByAppendingPathComponent:@"xgtakofiles"]; // todo:该目录不可写,暂不设置子目录
    NSString* filepath = [self.homePath stringByAppendingPathComponent:self.filename];
    NSLog(@"local file path is:%@",filepath);
    self.localPath = filepath;
    
    // 若文件不存在，则创建一个空的文件到沙盒中。只有首次下载时,才会创建新文件。
    NSFileManager* mgr = [NSFileManager defaultManager];
    if (![mgr fileExistsAtPath:filepath]) {
        [mgr createFileAtPath:filepath contents:nil attributes:nil];
    }
    
    // 创建一个用来写数据的文件句柄对象
    self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:filepath];
    
    // 只有首次下载时，才需要刷新总大小。
    if (self.currentLength==0) {
        self.totalLength = response.expectedContentLength;
    }
}


/**
 *  2.当接收到服务器返回的实体数据时调用（这个方法可能会被调用多次）
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // 移动到文件的最后面
    [self.writeHandle seekToEndOfFile];
    
    // 将数据写入沙盒
    [self.writeHandle writeData:data];
    
    // 累计写入文件的长度
    self.currentLength += data.length;
    
    // 下载进度
    self.progress = (double)self.currentLength / self.totalLength;
    NSLog(@"当前下载进度:%lld",self.progress);
    [self.delegate downloadingWithTotal:self.totalLength complete:self.currentLength tag:self.tag];
}


/**
 *  3.加载完毕后调用（服务器的数据已经完全返回后）
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"download worker:下载完成。");
    
    [self isDevicefileExist];// 调试用
    
    NSString* itermServiceUrl = [TakoServer fetchItermUrl:self.tag password:self.password];
    NSLog(@"will install,iterm url is:%@",itermServiceUrl);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itermServiceUrl]];
    
    // 重置状态
    self.currentLength = 0;
    self.totalLength = 0;
    
    // 关闭文件
    [self.writeHandle closeFile];
    self.writeHandle = nil;
    self.isFree = YES;
    
    [self.delegate downloadFinish:YES msg:nil tag:self.tag];
    
    NSLog(@"下载结束，结果为成功...");
    
}

/*
 启动
 */
- (void)startWithUrl:(NSURL*) url appid:(NSString*)appid password:(NSString*)password tag:(NSString*)tag delegate:(id<XHtDownLoadDelegate>)delegate {
    
    if (![self isDelegateAvailable:delegate]) {
        return;
    }
    
    self.delegate=delegate;
    self.tag = tag;
    self.appid = appid;
    self.password = password;
    self.isFree = NO;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // 若之前有下载记录，则直接读取之前的进度。
    if([XHTUIHelper readNSUserDefaultsObjectWithkey:self.tag]!=nil){
        NSDictionary* t = (NSDictionary*)[XHTUIHelper readNSUserDefaultsObjectWithkey:self.tag];
        self.currentLength = [(NSString*)[t objectForKey:DOWNLOAD_CURRENT_LENGTH_KEY] longLongValue];
        self.totalLength = [(NSString*)[t objectForKey:DOWNLOAD_TOTAL_LENGTH_KEY] longLongValue];
        self.appid = (NSString*)[t objectForKey:DOWNLOAD_APPID_KEY];
        self.password = (NSString*)[t objectForKey:DOWNLOAD_PASSWORD_KEY];
    }else{
        self.currentLength = 0;
    }
    
    // 请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%lld-", self.currentLength];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // todo:connectionWithRequest is deprecated in ios9.0, 需要改为 NSURLSession.
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

/*
 暂停
 */
-(void)pause:(NSString*)tag{
    [self.connection cancel];
    self.connection = nil;
    self.isFree = YES;
    self.tag=tag;
    
    
    [self saveCurrentProgress];
}

// 保存当前进度，以便下次退出应用后，仍可继续。
-(void)saveCurrentProgress{
    NSMutableDictionary* dict = [NSMutableDictionary new];
    NSString* currentLength = [NSString stringWithFormat:@"%qi",self.currentLength];
    NSString* totalLength = [NSString stringWithFormat:@"%qi",self.totalLength];
    [dict setObject:currentLength forKey:DOWNLOAD_CURRENT_LENGTH_KEY];
    [dict setObject:totalLength forKey:DOWNLOAD_TOTAL_LENGTH_KEY];
    [dict setObject:self.appid forKeyedSubscript:DOWNLOAD_APPID_KEY];
    [XHTUIHelper writeNSUserDefaultsWithKey:self.tag withObject:dict];
}

/*
 取消
 */
- (void)stop:(NSString*)tag{
    [self.connection cancel];
    self.connection=nil;
    self.currentLength=0;
    self.isFree = YES;
    self.tag=tag;
    
    [self saveCurrentProgress];
}

-(BOOL) isDelegateAvailable:(id<XHtDownLoadDelegate>) delegate{
    BOOL isAllAvailable = YES;
    
    if(![delegate respondsToSelector:@selector(downloadingWithTotal:complete:tag:)]){
        NSLog(@"Error!!! Please implement mehtod < downloadingWithTotal:complete:tag: > in <XHtDownLoadDelegate> first!");
        isAllAvailable = NO;
    }
    
    if(![delegate respondsToSelector:@selector(downloadFinish:msg:tag:)]){
        NSLog(@"Error!!! Please implement mehtod < downloadFinish:msg:tag: > in <XHtDownLoadDelegate> first!");
        isAllAvailable = NO;
    }
    return isAllAvailable;
}



// t:调试用
-(void)isDevicefileExist{
    NSFileManager* mgr = [NSFileManager defaultManager];
    if ([mgr fileExistsAtPath:self.localPath]==YES) {
        NSLog(@"device File exists");
        NSLog(@"file is:%@",self.localPath);
    }else{
        NSLog(@"device File not exists");
    }
}



@end
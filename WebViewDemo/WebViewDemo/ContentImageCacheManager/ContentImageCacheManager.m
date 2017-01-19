//
//  ContentImageCacheManager.m
//  MierMilitaryNews
//
//  Created by 李响 on 2016/11/4.
//  Copyright © 2016年 miercn. All rights reserved.
//

#import "ContentImageCacheManager.h"
#include <CommonCrypto/CommonCrypto.h>


@interface ContentImageCacheManager ()<NSURLSessionTaskDelegate , NSURLSessionDataDelegate>

@property (nonatomic , strong ) NSURLSession *session;

@property (nonatomic , strong ) NSURLSessionDataTask *dataTask;

@end

@implementation ContentImageCacheManager
{
    
    dispatch_queue_t queue;
}

+ (void)initData{
    
    //获取资源文件
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *jqueryJS = [NSString stringWithContentsOfFile:[mainBundle pathForResource:@"jquery-1.12.3.min" ofType:@"js"] encoding:NSUTF8StringEncoding error:NULL]; //jqueryJS
    
    NSString *webContentHandleJS = [NSString stringWithContentsOfFile:[mainBundle pathForResource:@"WebContentHandle" ofType:@"js"] encoding:NSUTF8StringEncoding error:NULL]; //web内容处理JS
    
    NSString *webContentWhiteStyleCSS = [NSString stringWithContentsOfFile:[mainBundle pathForResource:@"WebContentStyle-White" ofType:@"css"] encoding:NSUTF8StringEncoding error:NULL]; //web内容白色样式CSS
    
    NSString *webContentBlackStyleCSS = [NSString stringWithContentsOfFile:[mainBundle pathForResource:@"WebContentStyle-Black" ofType:@"css"] encoding:NSUTF8StringEncoding error:NULL]; //web内容黑色样式CSS
    
    //获取临时缓存目录
    
    NSString *jqueryJSPath = [[ContentImageCacheManager getCachePath:@"js"] stringByAppendingPathComponent:@"jquery-1.12.3.min.js"];
    
    NSString *webContentHandleJSPath = [[ContentImageCacheManager getCachePath:@"js"] stringByAppendingPathComponent:@"WebContentHandle.js"];
    
    NSString *webContentWhiteStyleCSSPath = [[ContentImageCacheManager getCachePath:@"css"] stringByAppendingPathComponent:@"WebContentStyle-White.css"];
    
    NSString *webContentBlackStyleCSSPath = [[ContentImageCacheManager getCachePath:@"css"] stringByAppendingPathComponent:@"WebContentStyle-Black.css"];
    
    NSLog(@"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~path = %@", webContentBlackStyleCSSPath);
    
    //写入临时缓存目录
    
    [jqueryJS writeToFile:jqueryJSPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    [webContentHandleJS writeToFile:webContentHandleJSPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    [webContentWhiteStyleCSS writeToFile:webContentWhiteStyleCSSPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    [webContentBlackStyleCSS writeToFile:webContentBlackStyleCSSPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

#pragma mark - 获取缓存路径

+ (NSString *)getCachePath:(NSString *)folder{
    
    //缓存目录结构: temp/com.miercn.miercn/[folder]
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *filePath = [NSString stringWithFormat:@"%@%@/%@" , NSTemporaryDirectory() , @"com.micai.com" , folder ? folder : @""];
    
    //判断该文件夹是否存在
    
    if(![fileManager fileExistsAtPath:filePath]){
        
        //不存在创建文件夹 创建文件夹
        
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return filePath;
}

+ (NSString *)getCachePath{
    
    return [self getCachePath:nil];
}

+ (NSString *)getImageCachePath{
    
    //缓存目录结构: temp/com.micai.com/contentimage/
    
    return [self getCachePath:@"contentimage"];
}

#pragma mark - 获取缓存文件路径

+ (NSString *)getCacheImageFilePath:(NSString *)urlString{
    
    //缓存目录结构: temp/com.miercn.miercn/contentimage/md5url.jpg
    
    return [[self getImageCachePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@" , [self md5String:[urlString dataUsingEncoding:NSUTF8StringEncoding]] , @".jpg"]];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        /*
         
         加载流程
         1.查询临时缓存目录是否存在
         2.存在则直接返回缓存路径
         3.不存在则查询YYWebImage缓存目录是否存在
         4.存在则添加到临时缓存目录
         5.不存则开始请求图片资源并添加到YYWebImage缓存目录和临时缓存目录
         
         注: wkwebview只能加载出temp临时缓存目录下的本地资源 所以这里将图片缓存移到temp目录下
         
         */
        
        // 加载状态图片处理
        
        NSString *imagePath_Initload = [[ContentImageCacheManager getImageCachePath] stringByAppendingPathComponent:@"load_image_initload.png"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath_Initload]) {
            
            [UIImagePNGRepresentation([UIImage imageNamed:@"load_image_initload"]) writeToFile:imagePath_Initload atomically:YES];
        }
        
        NSString *imagePath_Loading = [[ContentImageCacheManager getImageCachePath] stringByAppendingPathComponent:@"load_image_loading.png"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath_Loading]) {
            
            [UIImagePNGRepresentation([UIImage imageNamed:@"load_image_loading"]) writeToFile:imagePath_Loading atomically:YES];
        }
        
        NSString *imagePath_Loadfail = [[ContentImageCacheManager getImageCachePath] stringByAppendingPathComponent:@"load_image_loadfail.png"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath_Loadfail]) {
            
            [UIImagePNGRepresentation([UIImage imageNamed:@"load_image_loadfail"]) writeToFile:imagePath_Loadfail atomically:YES];
        }
        
        NSString *imagePath_Clickload = [[ContentImageCacheManager getImageCachePath] stringByAppendingPathComponent:@"load_image_clickload.png"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath_Clickload]) {
            
            [UIImagePNGRepresentation([UIImage imageNamed:@"load_image_clickload"]) writeToFile:imagePath_Clickload atomically:YES];
        }
        
        //创建串行队列
        
        queue = dispatch_queue_create("contentImageLoadQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - 加载图片

- (void)loadImage:(NSURL *)url ResultBlock:(void (^)(NSString * ,BOOL))resultBlock{
    
    if (!url) return;
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(queue, ^{
        
        if (weakSelf) {
            
            NSString *cachePath = [ContentImageCacheManager getCacheImageFilePath:url.absoluteString];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (resultBlock) resultBlock(cachePath , YES);
                });
                
            } else {
                
                //                NSData *imageData = [[YYWebImageManager sharedManager].cache getImageDataForKey:url.absoluteString];
                //
                //                if (imageData.length) {
                //
                //                    //写入临时缓存目录
                //
                //                    [imageData writeToFile:cachePath atomically:YES];
                //
                //                    dispatch_async(dispatch_get_main_queue(), ^{
                //
                //                        if (resultBlock) resultBlock(cachePath , YES);
                //                    });
                //
                //                } else
                
                {
                    
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0f];
                    
                    weakSelf.dataTask = [weakSelf.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        
                        if (weakSelf) {
                            
                            if (error) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    if (resultBlock) resultBlock(nil , NO);
                                });
                                
                            } else {
                                
                                //写入YYWebImage缓存
                                
                                //[[YYWebImageManager sharedManager].cache setImage:[UIImage imageWithData:data] forKey:response.URL.absoluteString];
                                
                                //写入临时缓存目录
                                
                                [data writeToFile:cachePath atomically:YES];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    if (resultBlock) resultBlock(cachePath , YES);
                                });
                            }
                            
                        }
                        
                    }];
                    
                    [weakSelf.dataTask resume];
                }
                
            }
            
        }
        
    });
    
}

- (void)cancel{
    
    if (self.dataTask) [self.dataTask cancel];
}

+ (NSString *)md5String:(NSData *)data {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark - LazyLoading

- (NSURLSession *)session{
    
    if (!_session) {
        
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    
    return _session;
}

@end

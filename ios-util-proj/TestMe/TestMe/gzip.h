//
//  NSString+Gzip.h
//  Anghami
//
//  Created by Ben Baron on 9/6/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import <Foundation/Foundation.h>

//
//  NSData+Gzip.h
//  Anghami
//
//  Created by Ben Baron on 9/6/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import <Foundation/Foundation.h>
//
//@interface NSData (Gzip)
//
//- (NSData *)gzipCompress;
//- (NSData *)gzipDecompress;
//
//@end

@interface NSString (Gzip)

+ (NSString *)stringFromGzipData:(NSData *)data;
+ (NSString *)stringFromGzipData:(NSData *)data encoding:(NSStringEncoding)encoding;

- (NSData *)gzipCompress;
- (NSData *)gzipCompressWithEncoding:(NSStringEncoding)encoding;

@end
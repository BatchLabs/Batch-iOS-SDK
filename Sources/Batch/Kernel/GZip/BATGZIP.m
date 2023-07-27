//
//  BATGZIP.m
//  Batch
//
//  Copyright © 2020 Batch. All rights reserved.
//

#import <Batch/BALogger.h>
#import <Batch/BATGZIP.h>
#import <zlib.h>

#define LOCAL_DEBUG_DOMAIN @"com.batch.core.gzip"

// Work with 32k chunks
#define CHUNK_SIZE 32768

@implementation BATGZIP

+ (nullable NSData *)dataByGzipping:(nullable NSData *)data {
    if ([data length] == 0) {
        return nil;
    }

    if ([self isGzippedData:data]) {
        return data;
    }

    z_stream zstream;
    zstream.zfree = NULL;
    zstream.zalloc = NULL;
    zstream.avail_in = (uint)data.length;
    zstream.next_in = (Bytef *)data.bytes;

    // Init zlib in gzip mode (15 | xxx)
    if (deflateInit2(&zstream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 | 16, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        return nil;
    }

    NSMutableData *outputData = [NSMutableData new];

    // Ask zlib to decompress chunk by chunk
    // Loop until there's more data to consume (avail_out = 0)
    // According to the documentation this is how it should be consumed
    Bytef outputBuffer[CHUNK_SIZE];
    int result = 0;
    do {
        zstream.avail_out = CHUNK_SIZE;
        zstream.next_out = outputBuffer;
        result = deflate(&zstream, Z_FINISH);
        if (result != Z_OK && result != Z_STREAM_END) {
            // See decompression for more info about what we do with Z_BUF_ERROR
            if (result != Z_BUF_ERROR || zstream.avail_out != 0) {
                [BALogger
                    debugForDomain:LOCAL_DEBUG_DOMAIN
                           message:@"Gzip error: deflating didn't return Z_OK | Z_STREAM_END | Z_BUF_ERROR, bailing."];
                return nil;
            }
        }
        // avail_out is the number of bytes that zlib didn't use in the buffer
        [outputData appendBytes:outputBuffer length:CHUNK_SIZE - zstream.avail_out];
    } while (zstream.avail_out == 0);

    if (deflateEnd(&zstream) != Z_OK) {
        [BALogger debugForDomain:LOCAL_DEBUG_DOMAIN message:@"Gzip error: deflating didn't return Z_OK on closing"];
        return nil;
    }

    if (result != Z_STREAM_END) {
        // zlib isn't happy
        [BALogger debugForDomain:LOCAL_DEBUG_DOMAIN
                         message:@"Gzip error: deflating didn't return Z_STREAM_END after completion"];
        return nil;
    }

    return [outputData copy];
}

+ (nullable NSData *)dataByGunzipping:(nullable NSData *)data {
    if (![self isGzippedData:data]) {
        return data;
    }

    z_stream zstream;
    zstream.zfree = NULL;
    zstream.zalloc = NULL;
    zstream.avail_in = (uint)data.length;
    zstream.next_in = (Bytef *)data.bytes;
    zstream.total_out = 0;

    NSMutableData *outputData = [NSMutableData new];
    if (inflateInit2(&zstream, 47) != Z_OK) {
        return nil;
    }

    // Ask zlib to compress chunk by chunk
    // Loop until there's more data to consume (avail_out = 0)
    // According to the documentation this is how it should be consumed
    Bytef outputBuffer[CHUNK_SIZE];
    int result = 0;
    do {
        zstream.avail_out = CHUNK_SIZE;
        zstream.next_out = outputBuffer;
        result = inflate(&zstream, Z_FINISH);
        if (result != Z_OK && result != Z_STREAM_END) {
            // Z_BUF_ERROR means that zlib couln't find anything to inflate, but that doesn't mean that we have
            // to stop, as compressed data might be found down the road. If avail_out was 0 we can continue as it means
            // that zlib is progressing. Condition is an inverted (result == Z_BUF_ERROR && avail_out == 0)
            if (result != Z_BUF_ERROR || zstream.avail_out != 0) {
                [BALogger
                    debugForDomain:LOCAL_DEBUG_DOMAIN
                           message:@"Gzip error: inflating didn't return Z_OK | Z_STREAM_END | Z_BUF_ERROR, bailing."];
                return nil;
            }
        }
        // avail_out is the number of bytes that zlib didn't use in the buffer
        [outputData appendBytes:outputBuffer length:CHUNK_SIZE - zstream.avail_out];
    } while (zstream.avail_out == 0);

    if (inflateEnd(&zstream) != Z_OK) {
        [BALogger debugForDomain:LOCAL_DEBUG_DOMAIN message:@"Gzip error: inflating didn't return Z_OK on closing"];
        return nil;
    }

    if (result != Z_STREAM_END) {
        // zlib isn't happy
        [BALogger debugForDomain:LOCAL_DEBUG_DOMAIN
                         message:@"Gzip error: inflating didn't return Z_STREAM_END after completion"];
        return nil;
    }

    return [outputData copy];
}

+ (BOOL)isGzippedData:(nullable NSData *)data {
    if ([data length] >= 2) {
        uint8_t magic[2];
        [data getBytes:&magic length:2];
        return magic[0] == 0x1f && magic[1] == 0x8b;
    }
    return false;
}

@end

// 
// Copyright (c) 2011, Shun Takebayashi
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 

#import "STFacebook.h"

#import "FBConnect.h"

static STFacebook *STFacebookSharedInstance = nil;
static NSString *STFacebookGetRequestKey(FBRequest *request);

@interface STFacebook () <FBRequestDelegate>

- (void)request:(FBRequest *)request didLoad:(id)result;
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error;

- (void)addHandler:(STFacebookRequestHandler)handler
        forRequest:(FBRequest *)request;
- (STFacebookRequestHandler)handlerForRequest:(FBRequest *)request;
- (void)removeHandlerForRequest:(FBRequest *)request;

@end

@implementation STFacebook

// MARK: Accessor Methods

@synthesize facebook = _facebook;

// MARK: FBRequestDelegate

- (void)sendRequestWithGraphPath:(NSString *)graphPath
                      parameters:(NSDictionary *)parameters
                      httpMethod:(NSString *)httpMethod
               completionHandler:(STFacebookRequestHandler)completionHandler {
    NSMutableDictionary *params = [[parameters mutableCopy] autorelease];
    if (!params) {
        params = [NSMutableDictionary dictionary];
    }
    FBRequest *request = [self.facebook requestWithGraphPath:graphPath
                                                   andParams:params
                                               andHttpMethod:httpMethod
                                                 andDelegate:self];
    [self addHandler:completionHandler forRequest:request];
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    STFacebookRequestHandler handler = [self handlerForRequest:request];
    while (!handler) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    handler(result, nil);
    [self removeHandlerForRequest:request];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    STFacebookRequestHandler handler = [self handlerForRequest:request];
    while (!handler) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    handler(nil, error);
    [self removeHandlerForRequest:request];
}

// MARK: Private Methods

- (void)addHandler:(STFacebookRequestHandler)handler
        forRequest:(FBRequest *)request {
    @synchronized (self) {
        [_handlers setObject:[[handler copy] autorelease]
                      forKey:STFacebookGetRequestKey(request)];
    }
}

- (STFacebookRequestHandler)handlerForRequest:(FBRequest *)request {
    NSString *key = STFacebookGetRequestKey(request);
    STFacebookRequestHandler handler;
    @synchronized (self) {
        handler = [_handlers objectForKey:key];
    }
    return handler;
}

- (void)removeHandlerForRequest:(FBRequest *)request {
    NSString *key = STFacebookGetRequestKey(request);
    @synchronized (self) {
        [_handlers removeObjectForKey:key];
    }
}

// MARK: Initializer And Singleton Methods

- (id)init {
    self = [super init];
    if (self) {
        _handlers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (STFacebook *)sharedInstance {
    @synchronized (self) {
        if (!STFacebookSharedInstance) {
            [[self alloc] init];
        }
    }
    return STFacebookSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (!STFacebookSharedInstance) {
            STFacebookSharedInstance = [super allocWithZone:zone];
            return STFacebookSharedInstance;
        }
    }
    return nil;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (oneway void)release {
}

- (id)autorelease {
    return self;
}

@end

// MARK: Private Functions

static NSString *STFacebookGetRequestKey(FBRequest *request) {
    return [FBRequest serializeURL:request.url
                            params:request.params
                        httpMethod:request.httpMethod];
}

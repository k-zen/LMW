/*
 * Copyright (c) 2014, Andreas P. Koenzen <akc at apkc.net>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <XCTest/XCTest.h>
#import "AKMosquittoClient.h"

@interface AKTest : XCTestCase
// MARK: Properties
@property AKMosquittoClient *client;
@end

@implementation AKTest
- (void)setUp
{
    [super setUp];
    
    [self setClient:[AKMosquittoClient newBuild:@"aMobile"
                                           host:@"devel.apkc.net"
                                           port:1883
                                       username:nil
                                       password:nil
                                      keepAlive:60
                                   cleanSession:YES]];
    [[self client] connect];
}

- (void)tearDown
{
    // Teardown the parser here.
    [[self client] disconnect];
    
    [super tearDown];
}

- (void)testExample
{
    // Put validations here.
    
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample
{
    [self measureBlock:^{
        for (int k = 0; k < 100000; k++) {
            [[self client] publish:[NSString stringWithFormat:@"Test %i from aMobile!", k] toTopic:@"test" withQos:0 retain:NO];
        }
    }];
}
@end

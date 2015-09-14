/*
 * Copyright (c) 2015, Andreas P. Koenzen <akc at apkc.net>
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

#import <Foundation/Foundation.h>
#import "AKMosquittoMessage.h"

/// Callback delegate for the client.
///
/// \author Andreas P. Koenzen <akc at apkc.net>
@protocol AKMosquittoClientDelegate
/// Called when the connection has been established.
///
/// \param code The connection code.
- (void)didConnect:(NSUInteger)code;

/// Called when the connection has been terminated.
- (void)didDisconnect;

/// Called when a message has been published.
///
/// \param messageID The message ID.
- (void)didPublish:(NSUInteger)messageID;

/// Called when a message has been received.
///
/// \param msg The received message.
- (void)didReceiveMessage:(AKMosquittoMessage *)msg;

/// Called when a subscription has been made.
///
/// \param messageID The message ID.
/// \param qos       The message's QoS.
- (void)didSubscribe:(NSUInteger)messageID grantedQos:(NSArray *)qos;

/// Called when a subscription has been terminated.
///
/// \param messageID The message ID.
- (void)didUnsubscribe:(NSUInteger)messageId;
@end

@interface AKMosquittoClient : NSObject <AKMosquittoClientDelegate> {
    struct mosquitto *mosq;
}

@property(getter=getHost)         NSString                      *host;
@property(getter=getPort)         unsigned short                 port;
@property(getter=getUsername)     NSString                      *username;
@property(getter=getPassword)     NSString                      *password;
@property(getter=getKeepAlive)    unsigned short                 keepAlive;
@property(getter=getCleanSession) BOOL                           cleanSession;
@property                         id<AKMosquittoClientDelegate>  delegate;
@property(getter=getTimer)        NSTimer                       *timer;

// MARK: Builders
/// Build a new AKMosquittoClient instance.
///
/// \param clientID The ID of the client.
+ (AKMosquittoClient *)newBuild:(NSString *)clientID;

/// Build a new AKMosquittoClient instance.
///
/// \param clientID     The ID of the client.
/// \param host         The host to connect.
/// \param port         The port to connect.
/// \param username     The username of the connection. In case of Authentication support.
/// \param password     The password of the connection. In case of Authentication support.
/// \param keepAlive    The keep alive interval.
/// \param cleanSession If clean session must be active or not.
+ (AKMosquittoClient *)newBuild:(NSString *)clientID
                           host:(NSString *)host
                           port:(unsigned short)port
                       username:(NSString *)username
                       password:(NSString *)password
                      keepAlive:(unsigned short)keepAlive
                   cleanSession:(BOOL)cleanSession;

+ (NSString *)version;

- (void)connect;

- (void)connectWithSSL:(const char *)tlsVer
                 caCrt:(const char *)caCrt
            caLocation:(const char *)caLocation
             clientCrt:(const char *)clientCrt
             clientKey:(const char *)clientKey;

- (void)reconnect;

- (void)disconnect;

- (void)setWill:(NSString *)payload
        toTopic:(NSString *)willTopic
        withQos:(NSUInteger)willQos
         retain:(BOOL)retain;

- (void)clearWill;

- (void)publish:(NSString *)payload
        toTopic:(NSString *)topic
        withQos:(NSUInteger)qos
         retain:(BOOL)retain;

- (void)subscribe:(NSString *)topic;

- (void)subscribe:(NSString *)topic withQos:(NSUInteger)qos;

- (void)unsubscribe:(NSString *)topic;

- (void)setMessageRetry:(NSUInteger)seconds;

- (void)setMosq:(struct mosquitto *)m;

- (struct mosquitto *)getMosq;
@end

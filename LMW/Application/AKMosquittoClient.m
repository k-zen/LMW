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

#import "AKMosquittoClient.h"
#import "mosquitto.h"

static NSString *pass;

@implementation AKMosquittoClient
static void on_connect(struct mosquitto *mosq, void *obj, int rc)
{
    AKMosquittoClient* client = (__bridge AKMosquittoClient *)obj;
    [client.delegate didConnect:(NSUInteger)rc];
}

static void on_disconnect(struct mosquitto *mosq, void *obj, int rc)
{
    AKMosquittoClient* client = (__bridge AKMosquittoClient *)obj;
    [client.delegate didDisconnect];
}

static void on_publish(struct mosquitto *mosq, void *obj, int message_id)
{
    AKMosquittoClient* client = (__bridge AKMosquittoClient *)obj;
    [client.delegate didPublish:(NSUInteger)message_id];
}

static void on_message(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message)
{
    AKMosquittoMessage *mosq_msg = [AKMosquittoMessage newBuild];
    
    mosq_msg.topic   = [NSString stringWithUTF8String:message->topic];
    mosq_msg.payload = [[NSString alloc] initWithBytes:message->payload
                                                length:message->payloadlen
                                              encoding:NSUTF8StringEncoding];
    
    AKMosquittoClient* client = (__bridge AKMosquittoClient *)obj;
    [client.delegate didReceiveMessage:mosq_msg];
}

static void on_subscribe(struct mosquitto *mosq, void *obj, int message_id, int qos_count, const int *granted_qos)
{
    AKMosquittoClient* client = (__bridge AKMosquittoClient *)obj;
    [client.delegate didSubscribe:message_id grantedQos:nil];
}

static void on_unsubscribe(struct mosquitto *mosq, void *obj, int message_id)
{
    AKMosquittoClient* client = (__bridge AKMosquittoClient *)obj;
    [client.delegate didUnsubscribe:message_id];
}

static int on_password_callback(char *buf, int size, int rwflag, void *userdata)
{
    //char *passwd = "client";
    const char *passwd = [pass cStringUsingEncoding:NSASCIIStringEncoding];
    memcpy(buf, passwd, strlen(passwd));
    
    return size = (int)strlen(passwd);
}

+ (AKMosquittoClient *)newBuild:(NSString *)clientID
{
    return [AKMosquittoClient newBuild:clientID
                                  host:@""
                                  port:1883
                              username:@""
                              password:@""
                             keepAlive:60
                          cleanSession:YES];
}

+ (AKMosquittoClient *)newBuild:(NSString *)clientID
                           host:(NSString *)host
                           port:(unsigned short)port
                       username:(NSString *)username
                       password:(NSString *)password
                      keepAlive:(unsigned short)keepAlive
                   cleanSession:(BOOL)cleanSession
{
    mosquitto_lib_init();
    
    pass = password;
    
    AKMosquittoClient *instance = [[AKMosquittoClient alloc] init];
    if (instance) {
        const char *cstrClientId = [clientID cStringUsingEncoding:NSUTF8StringEncoding];
        
        [instance setHost:host];
        [instance setPort:port];
        [instance setUsername:username];
        [instance setPassword:password];
        [instance setKeepAlive:keepAlive];
        [instance setCleanSession:cleanSession];
        [instance setDelegate:instance];
        [instance setMosq:mosquitto_new(cstrClientId, (bool)cleanSession, (__bridge void *)(instance))];
        
        const char *cUserName = [username cStringUsingEncoding:NSASCIIStringEncoding];
        const char *cPassword = [password cStringUsingEncoding:NSASCIIStringEncoding];
        if(username != nil){
            mosquitto_username_pw_set([instance getMosq], cUserName, cPassword);
        }
        mosquitto_connect_callback_set([instance getMosq], on_connect);
        mosquitto_disconnect_callback_set([instance getMosq], on_disconnect);
        mosquitto_publish_callback_set([instance getMosq], on_publish);
        mosquitto_message_callback_set([instance getMosq], on_message);
        mosquitto_subscribe_callback_set([instance getMosq], on_subscribe);
        mosquitto_unsubscribe_callback_set([instance getMosq], on_unsubscribe);
    }
    else {
        return nil;
    }
    
    return instance;
}

+ (NSString *)version
{
    int major, minor, revision;
    mosquitto_lib_version(&major, &minor, &revision);
    
    return [NSString stringWithFormat:@"%d.%d.%d", major, minor, revision];
}

- (void)connect
{
    const char *cstrHost = [[self getHost] cStringUsingEncoding:NSASCIIStringEncoding];
    
    mosquitto_connect([self getMosq], cstrHost, [self getPort], [self getKeepAlive]);
    
    [self setTimer:[NSTimer scheduledTimerWithTimeInterval:0.01 // 10ms
                                                    target:self
                                                  selector:@selector(loop:)
                                                  userInfo:nil
                                                   repeats:YES]];
}

- (void)connectWithSSL:(const char *)tlsVer
                 caCrt:(const char *)caCrt
            caLocation:(const char *)caLocation
             clientCrt:(const char *)clientCrt
             clientKey:(const char *)clientKey
{
    const char *cstrHost = [[self getHost] cStringUsingEncoding:NSASCIIStringEncoding];
    
    mosquitto_tls_opts_set([self getMosq], 1, tlsVer, NULL);
    mosquitto_tls_set([self getMosq], caCrt, caLocation, clientCrt, clientKey, on_password_callback);
    mosquitto_connect([self getMosq], cstrHost, [self getPort], [self getKeepAlive]);
    
    [self setTimer:[NSTimer scheduledTimerWithTimeInterval:0.01 // 10ms
                                                    target:self
                                                  selector:@selector(loop:)
                                                  userInfo:nil
                                                   repeats:YES]];
}

- (void)reconnect
{
    mosquitto_reconnect([self getMosq]);
}

- (void)disconnect
{
    mosquitto_disconnect([self getMosq]);
}

- (void)loop:(NSTimer *)timer
{
    mosquitto_loop([self getMosq], 1, 1);
}

- (void)setWill:(NSString *)payload
        toTopic:(NSString *)willTopic
        withQos:(NSUInteger)willQos
         retain:(BOOL)retain
{
    const char    *cstrTopic   = [willTopic cStringUsingEncoding:NSUTF8StringEncoding];
    const uint8_t *cstrPayload = (const uint8_t *)[payload cStringUsingEncoding:NSUTF8StringEncoding];
    size_t         cstrlen     = [payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    mosquitto_will_set([self getMosq], cstrTopic, (int)cstrlen, cstrPayload, (int)willQos, retain);
}


- (void)clearWill
{
    mosquitto_will_clear([self getMosq]);
}

- (void)publish:(NSString *)payload
        toTopic:(NSString *)topic
        withQos:(NSUInteger)qos
         retain:(BOOL)retain
{
    const char    *cstrTopic   = [topic cStringUsingEncoding:NSUTF8StringEncoding];
    const uint8_t *cstrPayload = (const uint8_t *)[payload cStringUsingEncoding:NSUTF8StringEncoding];
    size_t         cstrlen     = [payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    mosquitto_publish([self getMosq], NULL, cstrTopic, (int)cstrlen, cstrPayload, (int)qos, retain);
}

- (void)subscribe:(NSString *)topic
{
    [self subscribe:topic withQos:0];
}

- (void)subscribe:(NSString *)topic withQos:(NSUInteger)qos
{
    const char *cstrTopic = [topic cStringUsingEncoding:NSUTF8StringEncoding];
    
    mosquitto_subscribe([self getMosq], NULL, cstrTopic, (int)qos);
}

- (void)unsubscribe:(NSString *)topic
{
    const char *cstrTopic = [topic cStringUsingEncoding:NSUTF8StringEncoding];
    
    mosquitto_unsubscribe([self getMosq], NULL, cstrTopic);
}

- (void)setMessageRetry:(NSUInteger)seconds
{
    mosquitto_message_retry_set([self getMosq], (unsigned int)seconds);
}

- (void)dealloc
{
    if ([self getMosq]) {
        mosquitto_destroy([self getMosq]);
        mosquitto_lib_cleanup();
        [self setMosq:NULL];
    }
    
    if ([self getTimer]) {
        [[self getTimer] invalidate];
        [self setTimer:nil];
    }
}

- (void)setMosq:(struct mosquitto *)m { self->mosq = m; }

- (struct mosquitto *)getMosq { return self->mosq; }

// MARK: AKMosquittoClientDelegate Implementation
- (void)didConnect:(NSUInteger)code
{
    NSLog(@"=> CONNECTED.");
}

- (void)didDisconnect
{
    NSLog(@"=> DISCONNECTED.");
}

- (void)didPublish:(NSUInteger)messageID
{
    NSLog(@"=> PUBLISHED.");
}

- (void)didReceiveMessage:(AKMosquittoMessage *)msg
{
    NSLog(@"=> RECEIVED.");
}

- (void)didSubscribe:(NSUInteger)messageID grantedQos:(NSArray *)qos
{
    NSLog(@"=> SUBSCRIBED.");
}

- (void)didUnsubscribe:(NSUInteger)messageId
{
    NSLog(@"=> UNSUBSCRIBED.");
}
@end

//
//  Server.m
//  VKPC
//
//  Created by Eugene on 11/29/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "Server.h"
#import "Controller.h"

#include <libwebsockets.h>
#include <pthread.h>

#define CUSTOM_LOG 0

enum {
    LWS_LOG_ERR         = 1,
    LWS_LOG_WARN        = 2,
    LWS_LOG_NOTICE      = 4,
    LWS_LOG_INFO        = 8,
    LWS_LOG_DEBUG       = 16,
    LWS_LOG_PARSER      = 32,
    LWS_LOG_HEADER      = 64,
    LWS_LOG_EXTENSION   = 128,
    LWS_LOG_CLIENT      = 256,
    LWS_LOG_LATENCY     = 512
};

#ifdef DEBUG
static const char *lws_callback_reasons[] = {
    "LWS_CALLBACK_ESTABLISHED",
    "LWS_CALLBACK_CLIENT_CONNECTION_ERROR",
    "LWS_CALLBACK_CLIENT_FILTER_PRE_ESTABLISH",
    "LWS_CALLBACK_CLIENT_ESTABLISHED",
    "LWS_CALLBACK_CLOSED",
    "LWS_CALLBACK_CLOSED_HTTP",
    "LWS_CALLBACK_RECEIVE",
    "LWS_CALLBACK_CLIENT_RECEIVE",
    "LWS_CALLBACK_CLIENT_RECEIVE_PONG",
    "LWS_CALLBACK_CLIENT_WRITEABLE",
    "LWS_CALLBACK_SERVER_WRITEABLE",
    "LWS_CALLBACK_HTTP",
    "LWS_CALLBACK_HTTP_BODY",
    "LWS_CALLBACK_HTTP_BODY_COMPLETION",
    "LWS_CALLBACK_HTTP_FILE_COMPLETION",
    "LWS_CALLBACK_HTTP_WRITEABLE",
    "LWS_CALLBACK_FILTER_NETWORK_CONNECTION",
    "LWS_CALLBACK_FILTER_HTTP_CONNECTION",
    "LWS_CALLBACK_SERVER_NEW_CLIENT_INSTANTIATED",
    "LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION",
    "LWS_CALLBACK_OPENSSL_LOAD_EXTRA_CLIENT_VERIFY_CERTS",
    "LWS_CALLBACK_OPENSSL_LOAD_EXTRA_SERVER_VERIFY_CERTS",
    "LWS_CALLBACK_OPENSSL_PERFORM_CLIENT_CERT_VERIFICATION",
    "LWS_CALLBACK_CLIENT_APPEND_HANDSHAKE_HEADER",
    "LWS_CALLBACK_CONFIRM_EXTENSION_OKAY",
    "LWS_CALLBACK_CLIENT_CONFIRM_EXTENSION_SUPPORTED",
    "LWS_CALLBACK_PROTOCOL_INIT",
    "LWS_CALLBACK_PROTOCOL_DESTROY",
    "LWS_CALLBACK_WSI_CREATE",
    "LWS_CALLBACK_WSI_DESTROY",
    "LWS_CALLBACK_GET_THREAD_ID",
    "LWS_CALLBACK_ADD_POLL_FD",
    "LWS_CALLBACK_DEL_POLL_FD",
    "LWS_CALLBACK_CHANGE_MODE_POLL_FD",
    "LWS_CALLBACK_LOCK_POLL",
    "LWS_CALLBACK_UNLOCK_POLL",
};
#endif

static BOOL started = NO;
static NSMutableArray *sessions;
static NSMutableDictionary *connected;
static struct libwebsocket_context *context;

static NSThread *thread;
static pthread_mutex_t mutex;
static struct {
    char *command;
    NSInteger browser;
} nextCommandToSend;

static void ServerSession_Init(struct libwebsocket *wsi, ServerSession *s);
static void ServerSession_CreateString(ServerSession *session);
static void ServerSession_AppendString(ServerSession *session, const char *in);
static void ServerSession_DestroyString(ServerSession *session);
static void ServerSession_RecreateString(ServerSession *session);
static void AddSession(ServerSession *session);
static void DeleteSession(ServerSession *session);
static void incrConnected(NSInteger browser);
static void decrConnected(NSInteger browser);
static int SignalingCallback(struct libwebsocket_context *this,
                             struct libwebsocket *wsi,
                             enum libwebsocket_callback_reasons reason,
                             void *user,
                             void *in,
                             size_t len);
static void SendCommand(const char *command, NSInteger browser);
static void ServerStart();

//
// ServerSession
//
static void ServerSession_Init(struct libwebsocket *wsi, ServerSession *s) {
    s->wsi = wsi;
    s->browser = 0;
    s->commandToSend = NULL;
    s->commandToSendLength = 0;
}

static void ServerSession_CreateString(ServerSession *session) {
    session->buffer = NULL;
    session->receivedLength = 0;
}

static void ServerSession_AppendString(ServerSession *session, const char *in) {
    unsigned long incLength = strlen(in);
    unsigned long newLength = session->receivedLength + incLength;
    
    if (session->buffer == NULL) {
        session->buffer = (char *)malloc(newLength + 1);
        session->buffer[0] = '\0';
    } else {
        session->buffer = realloc(session->buffer, newLength + 1);
    }
    
    strcat(session->buffer, in);
    session->receivedLength += incLength;
}

static void ServerSession_DestroyString(ServerSession *session) {
    if (session->buffer != NULL)
        free(session->buffer);
    session->receivedLength = 0;
}

static void ServerSession_RecreateString(ServerSession *session) {
    ServerSession_DestroyString(session);
    ServerSession_CreateString(session);
}

//
// Sessions
//
static void AddSession(ServerSession *session) {
    [sessions addObject:[NSValue valueWithBytes:&session objCType:@encode(ServerSession*)]];
//    NSLog(@"[Server] AddSession, wsi points to: %p", session->wsi);
}

static void DeleteSession(ServerSession *session) {
    for (int i = 0; i < sessions.count; i++) {
        ServerSession *s = (ServerSession *)[(NSValue *)sessions[i] pointerValue];
        if (s != NULL && s == session) {
#ifdef DEBUG
//            NSLog(@"[DeleteSession] found, i=%d\n", i);
#endif
            [sessions removeObjectAtIndex:i];
            decrConnected(s->browser);
            break;
        }
    }
}

static void incrConnected(NSInteger browser) {
    NSNumber *key = [NSNumber numberWithInteger:browser];
    if (connected[key] == nil) {
        connected[key] = @1;
    } else {
        NSNumber *count = (NSNumber *)connected[key];
        connected[key] = [NSNumber numberWithInteger:[count integerValue]+1];
    }
}

static void decrConnected(NSInteger browser) {
    NSNumber *key = [NSNumber numberWithInteger:browser];
    if (connected[key] != nil) {
        NSNumber *count = (NSNumber *)connected[key];
        if ([count integerValue] > 0) {
            connected[key] = [NSNumber numberWithInteger:[count integerValue]-1];
        }
    }
}

// server callbacks
static int SignalingCallback(struct libwebsocket_context *this,
                                   struct libwebsocket *wsi,
                                   enum libwebsocket_callback_reasons reason,
                                   void *user,
                                   void *in,
                                   size_t len) {
#ifdef DEBUG
    if (reason != LWS_CALLBACK_GET_THREAD_ID) {
        printf("[SignalingCallback] >>> %s\n", lws_callback_reasons[reason]);
    }
#endif
    
    ServerSession *session = (ServerSession *)user;
    switch (reason) {
        case LWS_CALLBACK_ESTABLISHED: {
#ifdef DEBUG
//            lwsl_info("Connection established");
#endif
    
//            session = ServerSession_Create(wsi);
            ServerSession_Init(wsi, session);
            ServerSession_CreateString(session);
            AddSession(session);
        
            libwebsocket_callback_on_writable(context, wsi);
            break;
        }
        
        case LWS_CALLBACK_SERVER_WRITEABLE: {
            if (session->commandToSend != NULL) {
                unsigned char buf[LWS_SEND_BUFFER_PRE_PADDING + session->commandToSendLength + LWS_SEND_BUFFER_POST_PADDING];
                unsigned char *p = &buf[LWS_SEND_BUFFER_PRE_PADDING];
                strcpy((char *)p, session->commandToSend);
                
//                NSLog(@"[Server] LWS_CALLBACK_SERVER_WRITEABLE, commandToSend=%s", session->commandToSend);
                
                int m = libwebsocket_write(wsi, p, session->commandToSendLength, LWS_WRITE_TEXT);
                if (m < session->commandToSendLength) {
                    lwsl_err("ERROR while writing %d bytes to socket\n", session->commandToSendLength);
                    return -1;
                }
                
//                NSLog(@"before free() in writable callback");
                free(session->commandToSend);
//                NSLog(@"after free() in writable callback");
                session->commandToSend = NULL;
                session->commandToSendLength = 0;
            }
            break;
        }
        
        case LWS_CALLBACK_RECEIVE: {
#ifdef DEBUG
//            printf("[lws_callback_receive] \n");
//            printf("... received string: %s\n", (const char *)in);
//            printf("... of length: %lu\n", strlen((const char *)in));
//            printf("... remaning packet: %lu\n", libwebsockets_remaining_packet_payload(wsi));
#endif
        
            ServerSession_AppendString(session, (const char *)in);
#ifdef DEBUG
//            printf("... after strcat: length: %lu\n", strlen(session->buffer));
#endif
            if (libwebsockets_remaining_packet_payload(wsi) == 0) {
                if (session->receivedLength == 0) {
                    //
                } else if (session->buffer != NULL && strcmp(session->buffer, "PING") == 0) {
                    ServerSession_RecreateString(session);
                } else {
                    NSString *copy = [NSString stringWithUTF8String:session->buffer];
                    
                    ServerSession_RecreateString(session);
                    
                    NSData *data = [copy dataUsingEncoding:NSUTF8StringEncoding];
                    if (data != nil) {
                        NSError *error;
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                        if (error || !json || ![json isKindOfClass:[NSDictionary class]]) {
                            NSLog(@"[Server] Parse JSON error: %@; string was: %@", error, copy);
                            break;
                        }
                        
                        NSString *command = json[@"command"];
                        if (command && ![command isEqual:[NSNull null]] && [command isEqualToString:@"setBrowser"]) {
                            NSInteger browserID = [(NSNumber *)json[@"_browser"] integerValue];
                            session->browser = browserID;
                            
                            incrConnected(browserID);
                            
                            if (![Controller isASBrowser:browserID]) {
                                [Server send:[Controller JSONForCommand:@"set_sid" data:[NSNumber numberWithInt:VKPCSessionID]] forBrowser:browserID];
                            }
                        } else {
    #ifdef DEBUG
                            NSLog(@"in LWS_CALLBACK_RECEIVE: dispatch_async() now");
    #endif
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [Controller handleClient:json];
                            });
                        }
                    }
                }
            }
            break;
        }
        
        case LWS_CALLBACK_CLOSED: {
#ifdef DEBUG
//            lwsl_info("Connection closed\n");
#endif
            DeleteSession(session);
            ServerSession_DestroyString(session);
            break;
        }
        
        default:
            break;
    }
    
    return 0;
}

static void SendCommand(const char *command, NSInteger browser) {
    unsigned long cstrlen = strlen(command);
    for (int i = 0; i < sessions.count; i++) {
        ServerSession *s = (ServerSession *)[(NSValue *)sessions[i] pointerValue];
        if (s != NULL && (s->browser == browser || browser == -1)) {
            s->commandToSend = malloc(cstrlen + 1);
            strcpy(s->commandToSend, command);
            s->commandToSendLength = cstrlen;
            
//            NSLog(@"[Server] ready to send, wsi points to: %p", s->wsi);
            libwebsocket_callback_on_writable(context, s->wsi);
        }
    }
}

#ifdef DEBUG
#ifdef CUSTOM_LOG
static NSMutableString *syslog = nil;
static void emit_syslog(int level, const char *line) {
    if (syslog == nil) {
        syslog = [[NSMutableString alloc] init];
    }
    
    lwsl_emit_syslog(level, line);
    [syslog appendString:[NSString stringWithFormat:@"[%d] %s", level, line]];
//    [syslog appendString:[NSString stringWithUTF8String:line]];
//    [syslog appendString:@"\n"];
}
#endif
#endif

static void ServerStart() {
    sessions = [[NSMutableArray alloc] init];
    connected = [[NSMutableDictionary alloc] init];
    struct libwebsocket_protocols protocols[] = {
        { "signaling-protocol", SignalingCallback, sizeof(ServerSession), 0 },
        { NULL, NULL, 0, 0 }
    };
    
    pthread_mutex_init(&mutex, NULL);
    
    nextCommandToSend.command = NULL;
    nextCommandToSend.browser = 0;
    
    struct lws_context_creation_info info;
    memset(&info, 0, sizeof(info));
    
#ifdef DEBUG
#ifdef CUSTOM_LOG
    lws_set_log_level(LWS_LOG_ERR | LWS_LOG_WARN | LWS_LOG_NOTICE | LWS_LOG_INFO | LWS_LOG_DEBUG | LWS_LOG_HEADER, emit_syslog);
#else
    lws_set_log_level(LWS_LOG_ERR | LWS_LOG_WARN | LWS_LOG_NOTICE | LWS_LOG_INFO | LWS_LOG_DEBUG | LWS_LOG_HEADER, NULL);
#endif
#else
    lws_set_log_level(0, NULL);
#endif
    
    info.port = VKPCWSServerPort;
    info.iface = VKPCWSServerHost;
    info.protocols = protocols;
    info.extensions = libwebsocket_get_internal_extensions();
//    info.ssl_cert_filepath = NULL;
//    info.ssl_private_key_filepath = NULL;
    info.ssl_cert_filepath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ssl_bundle.crt"] UTF8String];
    info.ssl_private_key_filepath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"vkpc-local.ch1p.com.key"] UTF8String];
    info.gid = -1;
    info.uid = -1;
#ifdef DEBUG
    info.options = LWS_SERVER_OPTION_ALLOW_NON_SSL_ON_SSL_PORT;
#else
    info.options = 0;
#endif
    
    context = libwebsocket_create_context(&info);
    if (context == NULL) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"VKPC Error"];
#ifdef DEBUG
#ifdef CUSTOM_LOG
        [alert setInformativeText:[NSString stringWithFormat:@"Local server failed to start on port %d\n\n%@", VKPCWSServerPort, syslog]];
#else
        [alert setInformativeText:[NSString stringWithFormat:@"Local server failed to start on port %d", VKPCWSServerPort]];
#endif
#endif
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        
        return;
    }
    
    started = YES;
    
    while (1) {
        pthread_mutex_lock(&mutex);
        if (nextCommandToSend.command != NULL) {
            SendCommand(nextCommandToSend.command, nextCommandToSend.browser);
            free(nextCommandToSend.command);
            nextCommandToSend.command = NULL;
            nextCommandToSend.browser = 0;
        }
        pthread_mutex_unlock(&mutex);
        libwebsocket_service(context, 50);
    }
    
    libwebsocket_context_destroy(context);
}

@implementation Server

+ (void)start {
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(startThread) object:nil];
    [thread setName:@"server_thread"];
    [thread start];
}

+ (void)startThread {
//    NSLog(@"[Server startThread] current thread: %@", [[NSThread currentThread] name]);
    ServerStart();
}

+ (BOOL)send:(NSString *)command forBrowser:(NSInteger)browser {
    if (!started) {
        NSLog(@"[Server send:] server is not started yet, exising");
        return NO;
    }
    
    pthread_mutex_lock(&mutex);
    
    const char *command_cstr = [command UTF8String];
    nextCommandToSend.command = malloc(strlen(command_cstr) + 1);
    strcpy(nextCommandToSend.command, command_cstr);
    nextCommandToSend.browser = browser;
    
    pthread_mutex_unlock(&mutex);
    
    return YES;
}

+ (NSThread *)thread {
    return thread;
}

+ (NSInteger)connectedCount:(NSInteger)browser {
    NSNumber *key = [NSNumber numberWithInteger:browser];
    return connected[key] == nil ? 0 : [(NSNumber *)connected[key] integerValue];
}

@end
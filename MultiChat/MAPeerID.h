//
//  MAPeerID.h
//  MultiChat
//
//  Created by Donald Pae on 5/27/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MAPeerID : NSObject

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) NSString *uid;

@end

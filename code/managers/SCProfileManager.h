//
//  SCProfileManager.h
//  Poison
//
//  Created by stal on 22/2/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "tox.h"
#import "data.h"

@interface SCToxProfile : NSObject

@end

@interface SCProfileManager : NSObject
+ (BOOL)profileNameExists:(NSString *)aProfile;
+ (NSURL *)profileDirectory;
+ (BOOL)deleteProfileName:(NSString *)aProfile;
+ (BOOL)saveProfile:(txd_intermediate_t)aProfile name:(NSString *)name password:(NSString *)password;
+ (txd_intermediate_t)attemptDecryptionOfProfileName:(NSString *)aProfile password:(NSString *)password error:(NSError **)err;
@end

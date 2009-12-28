//
//  MGTwitterEngineFactory.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 11/5/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserAccount, MGTwitterEngine;
@interface MGTwitterEngineFactory : NSObject {
}

+ (MGTwitterEngine*)createTwitterEngineForCurrentUser:(id)del;

- (MGTwitterEngine*)createTwitterEngineForUserAccount:(UserAccount*)account delegate:(id)del;

@end

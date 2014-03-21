//
//  DESMacros.h
//  Poison
//
//  Created by stal on 26/2/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#ifndef DESMacros
#define DESMacros

#define DESInfo(fmt, ...)  NSLog(@"%s (%s:%i): [i] " fmt, __func__, __FILE__, __LINE__, ##__VA_ARGS__)
#define DESWarn(fmt, ...)  NSLog(@"%s (%s:%i): [w] " fmt, __func__, __FILE__, __LINE__, ##__VA_ARGS__)
#define DESError(fmt, ...) NSLog(@"%s (%s:%i): [e] " fmt, __func__, __FILE__, __LINE__, ##__VA_ARGS__)

#define DESAbstractWarning (DESWarn(@"Calling methods on an abstract class is not allowed! I'll let you off this once, but fix your code, please."))

#endif

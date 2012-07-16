//
//  TPSpellCheckFileOperation.h
//  TeXnicle
//
//  Created by Martin Hewitson on 16/7/12.
//  Copyright (c) 2012 bobsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPSpellCheckedFile.h"

@interface TPSpellCheckFileOperation : NSOperation {
  TPSpellCheckedFile *file;  
  NSArray *words;
}

@property (retain) TPSpellCheckedFile *file;
@property (retain) NSArray *words;

- (id) initWithFile:(TPSpellCheckedFile*)aFile;

@end
//
//  TPMetadataOperation.m
//  TeXnicle
//
//  Created by Martin Hewitson on 16/7/12.
//  Copyright (c) 2012 bobsoft. All rights reserved.
//

#import "TPMetadataOperation.h"
#import "NSString+LaTeX.h"
#import "NSString+SectionsOutline.h"
#import "FileDocument.h"
#import "BibliographyEntry.h"
#import "TPNewCommand.h"
#import "TPLabel.h"
#import "TPRegularExpression.h"

@interface TPMetadataOperation ()

@end

@implementation TPMetadataOperation

- (id) initWithFile:(FileEntity*)aFile
{
  self = [super init];
  if (self) {
    self.text = [aFile workingContentString];
    self.file = aFile;
  }
  return self;
}



-(void)main {
  @try {
    
    if (self.text == nil || [self.text length] ==0)
      return;
    
    NSMutableArray *newCommands = [[NSMutableArray alloc] init];
    NSMutableArray *newCitations = [[NSMutableArray alloc] init];
    NSMutableArray *newLabels = [[NSMutableArray alloc] init];
    
    @autoreleasepool {
    
//    NSLog(@"Generating meta data for %@", self.file.name);
    
      //-------------- get commands
      if ([self isCancelled]) return;
      NSArray *parsedCommands = [TPRegularExpression stringsMatching:@"\\\\newcommand\\{\\\\[a-zA-Z]*\\}" inText:self.text];
      for (NSString *str in parsedCommands) {
        TPNewCommand *c = [[TPNewCommand alloc] initWithSource:str];
        [newCommands addObject:c];
      }
      
      parsedCommands = [TPRegularExpression stringsMatching:@"\\\\renewcommand\\{\\\\[a-zA-Z]*\\}" inText:self.text];
      for (NSString *str in parsedCommands) {
        TPNewCommand *c = [[TPNewCommand alloc] initWithSource:str];
        [newCommands addObject:c];
      }
      
      parsedCommands = [TPRegularExpression stringsMatching:@"\\\\providecommand\\{\\\\[a-zA-Z]*\\}" inText:self.text];
      for (NSString *str in parsedCommands) {
        TPNewCommand *c = [[TPNewCommand alloc] initWithSource:str];
        [newCommands addObject:c];
      }
      
      //-------------- get citatations
      if ([self isCancelled]) return;
      
      // don't check bst files.
      if ([self.file.extension isEqualToString:@"bst"] == NO) {
        // get \bibitem entries
        NSArray *citationsFound = [self.text citations];
        [newCitations addObjectsFromArray:citationsFound];
        
        // citations from any bib files included in this file but not in the project
        if ([self isCancelled]) return;
        NSArray *entries = [self.text citationsFromBibliographyIncludedFromPath:self.file.pathOnDisk];
        [newCitations addObjectsFromArray:entries];
      }
      
      // add any citations from any bib files
      if ([self isCancelled]) return;
      if ([self.file.extension isEqualToString:@"bib"]) {
        NSArray *entries = [BibliographyEntry bibtexEntriesFromString:self.text];
        [newCitations addObjectsFromArray:entries];
      }
      
      //--------------- Labels    
      if ([self isCancelled]) return;
      
      NSArray *parsedLabels = [self.text referenceLabels];
      for (NSString *str in parsedLabels) {
        TPLabel *l = [[TPLabel alloc] initWithFile:self.file text:str];
        [newLabels addObject:l];
      }
    
    }
    
    self.commands = newCommands;
    self.citations = newCitations;
    self.labels = newLabels;
    
  }
  @catch(...) {
    // Do not rethrow exceptions.
  }
}



@end

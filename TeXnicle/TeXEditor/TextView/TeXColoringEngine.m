//
//  TeXColouringEngine.m
//  TeXnicle
//
//  Created by hewitson on 27/3/11.
//  Copyright 2011 bobsoft. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL MARTIN HEWITSON OR BOBSOFT SOFTWARE BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "TeXColoringEngine.h"
#import "externs.h"
#import "TeXTextView.h"
#import "NSArray+Color.h"


@interface TeXColoringEngine ()

@property (strong) NSColor *textColor;
@property (strong) NSFont *textFont;

@property (strong) NSColor *commentL2Color;
@property (strong) NSColor *commentL3Color;
@property (assign) BOOL colorCommentsL2;
@property (assign) BOOL colorCommentsL3;

@property (assign) BOOL colorMarkupL1;
@property (assign) BOOL colorMarkupL2;
@property (assign) BOOL colorMarkupL3;

@property (strong) NSColor *markupL1Color;
@property (strong) NSColor *markupL2Color;
@property (strong) NSColor *markupL3Color;

@property (strong) NSColor *specialCharsColor;
@property (assign) BOOL colorSpecialChars;

@property (strong) NSColor *dollarColor;
@property (assign) BOOL colorDollarChars;

@property (assign) BOOL colorMultilineArguments;

@end

@implementation TeXColoringEngine


+ (TeXColoringEngine*)coloringEngineWithTextView:(NSTextView*)aTextView
{
  return [[TeXColoringEngine alloc] initWithTextView:aTextView];
}
           
- (id) initWithTextView:(NSTextView*)aTextView
{
  self = [super init];
  if (self) {
    self.textView = aTextView;
    newLineCharacterSet = [NSCharacterSet newlineCharacterSet];
    whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];	
    specialChars = [NSCharacterSet characterSetWithCharactersInString:@"{}[]()\"'"];
    
    keys = @[TEDocumentFont, TESyntaxTextColor,
             TESyntaxCommentsColor, TESyntaxCommentsL2Color, TESyntaxCommentsL3Color, 
             TESyntaxColorComments, TESyntaxColorCommentsL2, TESyntaxColorCommentsL3, 
             TESyntaxSpecialCharsColor, TESyntaxColorSpecialChars, 
             TESyntaxCommandColor, TESyntaxColorCommand, 
             TESyntaxDollarCharsColor, TESyntaxColorDollarChars, 
             TESyntaxArgumentsColor, TESyntaxColorArguments, TESyntaxColorMultilineArguments,
             TESyntaxColorMarkupL1, TESyntaxColorMarkupL2, TESyntaxColorMarkupL3, 
             TESyntaxMarkupL1Color, TESyntaxMarkupL2Color, TESyntaxMarkupL3Color];

    [self readColorsAndFontsFromPreferences];
    [self observePreferences];
    
  }
  return self;
}

- (void) awakeFromNib
{
}

- (void)dealloc
{
  [self stopObserving];
  
  
}

- (unichar)commentCharacter
{
  return '%';
}

#pragma mark -
#pragma mark KVO 

- (void) stopObserving
{
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  for (NSString *str in keys) {
    [defaults removeObserver:self forKeyPath:[NSString stringWithFormat:@"values.%@", str]];
  }
}

- (void) observePreferences
{  
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  
  for (NSString *str in keys) {
    [defaults addObserver:self
               forKeyPath:[NSString stringWithFormat:@"values.%@", str]
                  options:NSKeyValueObservingOptionNew
                  context:NULL];		
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
											ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  for (NSString *str in keys) {
    if ([keyPath hasPrefix:[NSString stringWithFormat:@"values.%@", str]]) {
      [self readColorsAndFontsFromPreferences];
      if ([self.textView respondsToSelector:@selector(colorVisibleText)]) {
        [self.textView performSelector:@selector(colorVisibleText)];
      }
      self.lastHighlight = nil;
      if ([self.textView respondsToSelector:@selector(colorWholeDocument)]) {
        [self.textView performSelector:@selector(colorWholeDocument) withObject:nil afterDelay:0];
      }
    }    
  }
}


- (void) readColorsAndFontsFromPreferences
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  // basic text
  self.textFont = [NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:TEDocumentFont]];
  self.textColor = [[defaults valueForKey:TESyntaxTextColor] colorValue];
  
  // comments
  self.commentColor    = [[defaults valueForKey:TESyntaxCommentsColor] colorValue];
  self.commentL2Color  = [[defaults valueForKey:TESyntaxCommentsL2Color] colorValue];
  self.commentL3Color  = [[defaults valueForKey:TESyntaxCommentsL3Color] colorValue];
  self.colorComments   = [[defaults valueForKey:TESyntaxColorComments] boolValue];
  self.colorCommentsL2 = [[defaults valueForKey:TESyntaxColorCommentsL2] boolValue];
  self.colorCommentsL3 = [[defaults valueForKey:TESyntaxColorCommentsL3] boolValue];

  // markup
  self.colorMarkupL1 = [[defaults valueForKey:TESyntaxColorMarkupL1] boolValue];
  self.colorMarkupL2 = [[defaults valueForKey:TESyntaxColorMarkupL2] boolValue];
  self.colorMarkupL3 = [[defaults valueForKey:TESyntaxColorMarkupL3] boolValue];
  self.markupL1Color = [[defaults valueForKey:TESyntaxMarkupL1Color] colorValue];
  self.markupL2Color = [[defaults valueForKey:TESyntaxMarkupL2Color] colorValue];
  self.markupL3Color = [[defaults valueForKey:TESyntaxMarkupL3Color] colorValue];
  
  // math
  self.specialCharsColor = [[defaults valueForKey:TESyntaxSpecialCharsColor] colorValue];
  self.colorSpecialChars = [[defaults valueForKey:TESyntaxColorSpecialChars] boolValue];
  
  // command
  self.commandColor = [[defaults valueForKey:TESyntaxCommandColor] colorValue];
  self.colorCommand = [[defaults valueForKey:TESyntaxColorCommand] boolValue];
  
  // command
  self.dollarColor = [[defaults valueForKey:TESyntaxDollarCharsColor] colorValue];
  self.colorDollarChars = [[defaults valueForKey:TESyntaxColorDollarChars] boolValue];
  
  // arguments
  self.argumentsColor = [[defaults valueForKey:TESyntaxArgumentsColor] colorValue];
  self.colorArguments = [[defaults valueForKey:TESyntaxColorArguments] boolValue];
  self.colorMultilineArguments = [[defaults valueForKey:TESyntaxColorMultilineArguments] boolValue];
  
}


- (void) colorTextView:(NSTextView*)aTextView textStorage:(NSTextStorage*)textStorage layoutManager:(NSLayoutManager*)layoutManager inRange:(NSRange)aRange
{
//  NSLog(@"Starting coloring...");
  if (self.lastHighlight) {
    if ([[NSDate date] timeIntervalSinceDate:self.lastHighlight] < kHighlightInterval) {
      return;
    }
  }
  
//  NSLog(@"Coloring %@", NSStringFromRange(aRange));
  
  NSString *text = [[textStorage string] substringWithRange:aRange];
//  NSLog(@"\n\n=======================================================================================");
//  NSLog(@"Coloring %@", text);
//  NSLog(@"=======================================================================================");
  NSInteger strLen = [text length];
  if (strLen == 0) {
    return;
  }
  
//  NSLog(@"Str length %ld", strLen);
  // make sure the glyphs are present otherwise colouring gives errors
  [layoutManager ensureGlyphsForCharacterRange:aRange];
  
  // remove existing temporary attributes
	[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:aRange];
    
  // scan each character in the string
  NSUInteger idx;
  unichar cc;
  unichar nextChar;
  NSRange lineRange;
  NSRange colorRange;
  NSInteger start;
  for (idx = 0; idx < strLen; idx++) {
    
    cc  = [text characterAtIndex:idx];
    if ([whitespaceCharacterSet characterIsMember:cc]) {
      continue;
    }
    if ([newLineCharacterSet characterIsMember:cc]) {
      continue;
    }
//    NSLog(@"Checking idx: %ld, %c", idx, cc);
//    NSLog(@"idx 182 == %c'", [text characterAtIndex:182]);
    
    // color comments
    if (cc == '%' && (self.colorComments || self.colorCommentsL2 || self.colorCommentsL3)) {
      // comment rest of the line
      lineRange = [text lineRangeForRange:NSMakeRange(idx, 0)];
//      NSLog(@"   idx %ld", idx);
//      NSLog(@"   line range %@", NSStringFromRange(lineRange));
      colorRange = NSMakeRange(aRange.location+idx, NSMaxRange(lineRange)-idx);
//      NSLog(@"   color range %@", NSStringFromRange(colorRange));
      unichar c = 0;
			if (idx>0) {
				c = [text characterAtIndex:idx-1];
			}
			if (idx==0 || c != '\\') {
        NSColor *color = nil;
        if (self.colorComments)
          color = self.commentColor;
        
        if (idx < strLen-1) {
          if ([text characterAtIndex:idx+1] == '%') {
            if (self.colorCommentsL2) {
              color = self.commentL2Color;
            }
            
            if (idx < strLen-2) {
              if ([text characterAtIndex:idx+2] == '%') {
                if (self.colorCommentsL3) {
                  color = self.commentL3Color;
                }
              }
            }
            
          }
        }
        if (color != nil) {
//          NSLog(@"Comment: %@", NSStringFromRange(colorRange));
          [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:color forCharacterRange:colorRange];
        }
        idx = NSMaxRange(lineRange)-1;
//        NSLog(@"   advanced index to %ld", idx);
			}
    } else if (cc == '<' && (self.colorMarkupL1 || self.colorMarkupL2 || self.colorMarkupL3)) {
      int jump = 1;
      unichar c = 0;
			if (idx>0) {
				c = [text characterAtIndex:idx-1];
			}
			if (idx==0 || c != '\\') {
        NSColor *color = nil;
        if (self.colorMarkupL1)
          color = self.markupL1Color;
        
        if (idx < strLen-1) {
          if ([text characterAtIndex:idx+1] == '<') {
            jump++;
            if (self.colorMarkupL2) {
              color = self.markupL2Color;
            }
            
            if (idx < strLen-2) {
              if ([text characterAtIndex:idx+2] == '<') {
                jump++;
                if (self.colorMarkupL3) {
                  color = self.markupL3Color;
                }
              }
            }
            
          }
        }
        
        // look for the closing >
        start = idx;
        idx++;
        NSInteger argCount = 1;
        while(idx < strLen) {
          nextChar = [text characterAtIndex:idx];
          if (nextChar == '<') {
            argCount++;
          }
          if (nextChar == '>') {
            argCount--;
          }
          if (argCount == 0) {
            NSRange argRange = NSMakeRange(aRange.location+start,idx-start+1);
            if (color != nil) {
              [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:color forCharacterRange:argRange];
            }
            break;
          }
          idx++;
        }
        
        // if we didn't match an ending } then there's not much we can do
        if (argCount>0) {
          idx = start+jump;
        }
                
			}
    } else if ((cc == '{') && self.colorArguments) {      
      start = idx;
      // look for the closing bracket
      idx++;
      NSInteger argCount = 1;
      NSInteger newLineCount = 0;
//      NSLog(@"  looking for closing bracket starting at %ld", idx);
      while(idx < strLen) {
        nextChar = [text characterAtIndex:idx];
//        NSLog(@"   checking next char '%c'", nextChar);
        if ([newLineCharacterSet characterIsMember:nextChar]) {
          newLineCount++;
        }
        if (nextChar == '{') {
          argCount++;
        }
        if (nextChar == '}') {
          argCount--;
        }
//        NSLog(@"Arg count %ld", argCount);
        if (argCount == 0) {
//          NSLog(@"New line count %ld", newLineCount);
          NSRange argRange = NSMakeRange(aRange.location+start,idx-start+1);
//          NSLog(@"Argument: %@", NSStringFromRange(argRange));
          if (newLineCount == 0 || self.colorMultilineArguments) {
//            NSLog(@"Coloring argument");
            if (self.argumentsColor != nil) {
              [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.argumentsColor forCharacterRange:argRange];
            }
            break;
          } else {
//            NSLog(@"Not coloring argument");
            // if the argument spans multiple lines, color the first char
            [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.textColor forCharacterRange:argRange];
            if (self.specialCharsColor) {
              [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.specialCharsColor forCharacterRange:NSMakeRange(aRange.location+start, 1)];
            }
            idx = start;
            break;
          }
        }
        
        idx++;
      } // end while loop
      
      // if we didn't match an ending } then there's not much we can do
      if (argCount>0) {
        idx = start+1;
      }
      
      
    } else if ((cc == '[') && self.colorArguments) {      
      start = idx;
      // look for the closing bracket
      idx++;
      NSInteger argCount = 1;
      NSInteger newLineCount = 0;
      while(idx < strLen) {
        nextChar = [text characterAtIndex:idx];
        if ([newLineCharacterSet characterIsMember:nextChar]) {
          newLineCount++;
        }
        if (nextChar == '[') {
          argCount++;
        }
        if (nextChar == ']') {
          argCount--;
        }
        if (argCount == 0) {
          NSRange argRange = NSMakeRange(aRange.location+start,idx-start+1);
          if (newLineCount == 0 || self.colorMultilineArguments) {
            //          NSLog(@"Argument: %@", NSStringFromRange(argRange));
            if (self.argumentsColor != nil) {
              [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.argumentsColor forCharacterRange:argRange];
            }
            break;
          } else {
            // if the argument spans multiple lines, color the first char
            [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.textColor forCharacterRange:argRange];
            if (self.specialCharsColor) {
              [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.specialCharsColor forCharacterRange:NSMakeRange(aRange.location+start, 1)];
            }
            idx = start+1;
            break;
          }
        }
        idx++;
      }
      
      // if we didn't match an ending } then there's not much we can do
      if (argCount>0) {
        idx = start+1;
      }
      
    } else if (cc == '$' && self.colorDollarChars) { 
      
      colorRange = NSMakeRange(aRange.location+idx, 1);
      if (self.dollarColor != nil) {
        [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.dollarColor forCharacterRange:colorRange];
      }
      
    } else if ([specialChars characterIsMember:cc] && self.colorSpecialChars) { // (cc == '$' || cc == '{'&& self.colorMath) {
      
      colorRange = NSMakeRange(aRange.location+idx, 1);
      if (self.specialCharsColor != nil) {
        [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.specialCharsColor forCharacterRange:colorRange];
      }
            
    } else if ((cc == '\\' || cc == '@') && self.colorCommand) {      
      // if we find \ we start a command unless we have \, or whitespace
      if (idx < strLen-1) {
        nextChar = [text characterAtIndex:idx+1];
        if (nextChar == ',' || [whitespaceCharacterSet characterIsMember:nextChar]) {
          // do nothing
        } else {
          // highlight word
          NSRange wordRange = [textStorage doubleClickAtIndex:aRange.location+idx+1];
          colorRange = NSMakeRange(wordRange.location-1, wordRange.length+1);
//          NSLog(@"Command: %@", NSStringFromRange(colorRange));
          if (self.commandColor != nil) {
            [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:self.commandColor forCharacterRange:colorRange];
          }
          idx += colorRange.length-1;
        }
      }            
//    } else if ((cc == '[') && self.colorArguments) {      
    } else {
      // do nothing
    }    
  } 
  self.lastHighlight = [NSDate date];
}



@end

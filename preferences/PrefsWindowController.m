//
//  PrefsWindowController.m
//  Strongbox
//
//  Created by Martin Hewitson on 12/11/09.
//  Copyright 2009 AEI Hannover . All rights reserved.
//

#import "PrefsWindowController.h"
#import "externs.h"
#import "NSArray+Color.h"
#import "TeXTextView.h"

@implementation PrefsWindowController


- (void) awakeFromNib
{
	
	// Comments controller
	commentsController = [[SyntaxHighlightControlController alloc] initWithTag:@"Comments" name:@"Comments"];
	[commentsView addSubview:[commentsController view]];
	
	// math controller
	mathController = [[SyntaxHighlightControlController alloc] initWithTag:@"SpecialChars" name:@"Special Characters"];
	[mathView addSubview:[mathController view]];
	
	// commands controller
	commandsController = [[SyntaxHighlightControlController alloc] initWithTag:@"Command" name:@"Commands"];
	[commandsView addSubview:[commandsController view]];
	
	// arguments controller
	argumentsController = [[SyntaxHighlightControlController alloc] initWithTag:@"Arguments" name:@"Arguments"];
	[argumentsView addSubview:[argumentsController view]];
	
	// keywords controller
//	keywordsController = [[SyntaxHighlightControlController alloc] initWithTag:@"Keywords"];
//	[keywordsView addSubview:[keywordsController view]];
	
	[self wrapStyleChanged:self];
  
  
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc addObserver:self
         selector:@selector(templateSelectionChanged:) 
             name:NSTableViewSelectionDidChangeNotification
           object:templatesTable];  
  
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
	[commentsController release];
	[mathController release];
	[commandsController release];
	[argumentsController release];
//	[keywordsController release];
	
	[super dealloc];
}

- (void) windowWillClose:(NSNotification *)notification
{
  // This is needed to force the text-editor to commit changes to the user defaults.
  [templatesController commitEditing];
  [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setupToolbar
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	NSFont *f = [NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:TEDocumentFont]];
	if (!f) {
		f = [NSFont systemFontOfSize:14];
	}
	[docFont setValue:f forKey:@"font"];	
	[docFont setStringValue:[NSString stringWithFormat:@"%@ - %0.0f pt", [f displayName], [f pointSize]]];
	
  [self addView:generalPrefsView 
					label:@"General" 
					image:[NSImage imageNamed:NSImageNamePreferencesGeneral]];	
	
  [self addView:engineView 
					label:@"LaTeX" 
					image:[NSImage imageNamed:@"engine"]];		
	
  [self addView:syntaxColorsView 
					label:@"Font & Colors" image:[NSImage imageNamed:@"fontsAndColors"]];	
	
  [self addView:templatesView 
					label:@"Templates" image:[NSImage imageNamed:@"templates"]];	
	
	[templateEditor setFont:f];
	
	[templatesController setSelectsInsertedObjects:YES];

	
}

#pragma mark -
#pragma mark Templates Control

- (IBAction) newTemplate:(id)sender
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setValue:[NSString stringWithFormat:@"New Template %d", [[templatesController arrangedObjects] count]]
					forKey:@"Name"];
	[dict setValue:@"New empty template" forKey:@"Description"];
	
	[templatesController insertObject:dict atArrangedObjectIndex:0];
	[templatesController setSelectionIndex:0];
	//[templatesController addObject:dict];
}

- (void) templateSelectionChanged:(NSNotification*)aNote
{
  
  NSArray *selectedObjects = [templatesController selectedObjects];
  if ([selectedObjects count] == 1) {
    
    NSDictionary *selected = [selectedObjects objectAtIndex:0];
    NSString *code = [selected valueForKey:@"Code"];
    
    [templateEditor scrollRectToVisible:NSZeroRect];
    
    [templateEditor setString:code];
    [templateEditor didChangeText];
    [templateEditor performSelector:@selector(colorVisibleText)
                         withObject:nil
                         afterDelay:0.1];
    [templateEditor performSelector:@selector(colorWholeDocument)
                         withObject:nil
                         afterDelay:0.2];    
  }
}

- (void) handleCodeDidChange:(NSNotification*)aNote
{
//  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark Control 

- (IBAction) insertSpacesForTabsChanged:(id)sender
{
  if ([sender state] == NSOffState) {
    [spacesLabel setTextColor:[NSColor disabledControlTextColor]];
    [numSpacesEdit setEnabled:NO];
    [numSpacesStepper setEnabled:NO];
  } else {
    [spacesLabel setTextColor:[NSColor controlTextColor]];
    [numSpacesEdit setEnabled:YES];
    [numSpacesStepper setEnabled:YES];
  }
}

- (IBAction) wrapStyleChanged:(id)sender
{
	if ([wrapStylePopup indexOfSelectedItem] == TPNoWrap) {
		[wrapWidthEdit setEnabled:NO];
		[wrapWidthStepper setEnabled:NO];
		[wrapAtWidthLabel setTextColor:[NSColor disabledControlTextColor]];
		[wrapCharsLabel setTextColor:[NSColor disabledControlTextColor]];
	} else {
		[wrapWidthEdit setEnabled:YES];
		[wrapWidthStepper setEnabled:YES];
		[wrapAtWidthLabel setTextColor:[NSColor controlTextColor]];
		[wrapCharsLabel setTextColor:[NSColor controlTextColor]];
	}
}

- (void)selectDocFont:(id)sender
{
	
	NSFontPanel *fp = [NSFontPanel sharedFontPanel];
	[fp setPanelFont:[docFont font] isMultiple:YES];
	[fp makeKeyAndOrderFront:self];
	
	NSFontManager *fm = [NSFontManager sharedFontManager];
	[fm setTarget:self];
	[fm setAction:@selector(docFontChanged:)];
}

- (void)docFontChanged:(id)sender
{
	NSFont *f = [sender convertFont:[docFont font]];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setValue:[NSArchiver archivedDataWithRootObject:f] forKey:TEDocumentFont];
	[defaults synchronize];
	[docFont setValue:f forKey:@"font"];	
	[docFont setStringValue:[NSString stringWithFormat:@"%@ - %0.0f pt", [f displayName], [f pointSize]]];
	[templateEditor setFont:f];
}


- (void) colorClick: (id) sender 
{	// sender is the table view
	NSColorPanel* panel;
	panel = [NSColorPanel sharedColorPanel];
  [panel setAction:NULL];
}


- (void) browseForGSExecutable:(id)sender
{
	// get user to choose file
	NSOpenPanel *openPanel = [NSOpenPanel openPanel]; 
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setTitle:@"Locate Ghostscript (gs) binary"];
	
	SEL select = @selector(locateGSDidEnd:returnCode:contextInfo:);
	[openPanel beginSheetForDirectory:[[NSUserDefaults standardUserDefaults] valueForKey:TPGSPath]
															 file:nil 
										 modalForWindow:[self window]
											modalDelegate:self 
										 didEndSelector:select
												contextInfo:nil];
	
}

- (void)locateGSDidEnd:(NSSavePanel*)savePanel 
							returnCode:(NSInteger)returnCode
						 contextInfo:(void*)context
{
	if (returnCode == NSCancelButton) 
		return;
	
	NSString *path = [savePanel filename];
	
	// set the path to the item
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:TPGSPath];
	
}	

- (void) browseForPDFLatexExecutable:(id)sender
{
	// get user to choose file
	NSOpenPanel *openPanel = [NSOpenPanel openPanel]; 
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setTitle:@"Locate pdflatex binary"];
	
	SEL select = @selector(locatePDFLatexDidEnd:returnCode:contextInfo:);
	[openPanel beginSheetForDirectory:[[NSUserDefaults standardUserDefaults] valueForKey:TPPDFLatexPath]
															 file:nil 
										 modalForWindow:[self window]
											modalDelegate:self 
										 didEndSelector:select
												contextInfo:nil];	
}

- (void)locatePDFLatexDidEnd:(NSSavePanel*)savePanel 
									returnCode:(NSInteger)returnCode
								 contextInfo:(void*)context
{
	if (returnCode == NSCancelButton) 
		return;
	
	NSString *path = [savePanel filename];
	
	// set the path to the item
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:TPPDFLatexPath];
	
}

- (void) browseForLatexExecutable:(id)sender
{
	// get user to choose file
	NSOpenPanel *openPanel = [NSOpenPanel openPanel]; 
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setTitle:@"Locate latex binary"];
	
	SEL select = @selector(locateLatexDidEnd:returnCode:contextInfo:);
	[openPanel beginSheetForDirectory:[[NSUserDefaults standardUserDefaults] valueForKey:TPLatexPath]
															 file:nil 
										 modalForWindow:[self window]
											modalDelegate:self 
										 didEndSelector:select
												contextInfo:nil];	
}

- (void)locateLatexDidEnd:(NSSavePanel*)savePanel 
							 returnCode:(NSInteger)returnCode
							contextInfo:(void*)context
{
	if (returnCode == NSCancelButton) 
		return;
	
	NSString *path = [savePanel filename];
	
	// set the path to the item
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:TPLatexPath];
	
}	

- (void) browseForDvipsExecutable:(id)sender
{
	// get user to choose file
	NSOpenPanel *openPanel = [NSOpenPanel openPanel]; 
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setTitle:@"Locate dvips binary"];
	
	SEL select = @selector(locateDvipsDidEnd:returnCode:contextInfo:);
	[openPanel beginSheetForDirectory:[[NSUserDefaults standardUserDefaults] valueForKey:TPDvipsPath]
															 file:nil 
										 modalForWindow:[self window]
											modalDelegate:self 
										 didEndSelector:select
												contextInfo:nil];	
}

- (void)locateDvipsDidEnd:(NSSavePanel*)savePanel 
							 returnCode:(NSInteger)returnCode
							contextInfo:(void*)context
{
	if (returnCode == NSCancelButton) 
		return;
	
	NSString *path = [savePanel filename];
	
	// set the path to the item
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:TPDvipsPath];
	
}	

- (void) browseForBibTeXExecutable:(id)sender
{
	// get user to choose file
	NSOpenPanel *openPanel = [NSOpenPanel openPanel]; 
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setTitle:@"Locate bibtex binary"];
	
	SEL select = @selector(locateBibTeXDidEnd:returnCode:contextInfo:);
	[openPanel beginSheetForDirectory:[[NSUserDefaults standardUserDefaults] valueForKey:TPBibTeXPath]
															 file:nil 
										 modalForWindow:[self window]
											modalDelegate:self 
										 didEndSelector:select
												contextInfo:nil];	
}

- (void)locateBibTeXDidEnd:(NSSavePanel*)savePanel 
								returnCode:(NSInteger)returnCode
							 contextInfo:(void*)context
{
	if (returnCode == NSCancelButton) 
		return;
	
	NSString *path = [savePanel filename];
	
	// set the path to the item
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:TPBibTeXPath];
	
}	
@end

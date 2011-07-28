//
//  TPOutlineView.m
//  TeXnicle
//
//  Created by Martin Hewitson on 30/1/10.
//  Copyright 2010 AEI Hannover . All rights reserved.
//

#import "TPOutlineView.h"
#import "FolderEntity.h"
#import "TeXFileEntity.h"

@implementation TPOutlineView

@synthesize dragLeftView;


-(NSMenu*)menuForEvent:(NSEvent*)evt 
{
	NSPoint pt = [self convertPoint:[evt locationInWindow] fromView:nil];
	NSInteger row=[self rowAtPoint:pt];
	
	// Main tree context menu
	if (row < 0) {
		return [self defaultMenu];
	}
	return [self defaultMenuForRow:row];
}
						

#pragma mark -
#pragma mark Main Context Menu

- (NSMenu*)defaultMenu
{
	
	NSMenu *theMenu = [[[NSMenu alloc] 
											initWithTitle:@"Project Tree Context Menu"] 
										 autorelease];
	
	[theMenu setAutoenablesItems:NO];
	
	//------ Add existing file
	NSMenuItem *menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Add existing files..."
																				action:@selector(addExistingFile:)
																 keyEquivalent:@""];
	[theMenu addItem:menuItem];
	[menuItem release];
	
	//------ Add existing folder	
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Add existing folder..."
																				action:@selector(addExistingFolder:)
																 keyEquivalent:@""];
	[theMenu addItem:menuItem];
	[menuItem release];
	
	return theMenu;
}

- (IBAction) addExistingFolder:(id)sender
{
	[treeController addExistingFolder:self];
}


- (IBAction) addExistingFile:(id)sender
{
	[treeController addExistingFile:self toFolder:nil];
}

- (IBAction) addExistingFileToSelectedFolder:(id)sender
{
	[treeController addExistingFile:self toFolder:(FolderEntity*)selectedItem];
}


#pragma mark -
#pragma mark Menu for item

-(NSMenu*)defaultMenuForRow:(NSInteger)row
{
	if (row < 0) return nil;
	
	selectedRow = row;
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
//  [treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:row]];

	// get the object for this row
//	NSArray *items = [treeController selectedObjects]; //[treeController flattenedContent];
	selectedItem = [[self itemAtRow:row] representedObject];
  [treeController selectItem:selectedItem];
	
	NSMenu *theMenu = [[[NSMenu alloc] 
											initWithTitle:@"Project Item Context Menu"] 
										 autorelease];
	
	[theMenu setAutoenablesItems:NO];
	
	NSString *itemName = [selectedItem valueForKey:@"name"];
	
	
	//--------- add existing file
	if ([selectedItem isKindOfClass:[FolderEntity class]]) {
		
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Add existing files..."
																									action:@selector(addExistingFileToSelectedFolder:)
																					 keyEquivalent:@""];
		[theMenu addItem:item];
		[item release];		
		
		//------ Add existing folder	
		item = [[NSMenuItem alloc] initWithTitle:@"Add existing folder..."
																					action:@selector(addExistingFolder:)
																	 keyEquivalent:@""];
		[theMenu addItem:item];
		[item release];
		
	}
	
	//--------- set main file
	if ([selectedItem isKindOfClass:[TeXFileEntity class]]) {
		NSMenuItem *mainItem;
		if ([[treeController project] valueForKey:@"mainFile"] == selectedItem) {
			mainItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Unset \u201c%@\u201d as main file", itemName]
																												action:@selector(setMainItem:)
																								 keyEquivalent:@""];
		} else {
			mainItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Set \u201c%@\u201d as main file", itemName]
																												action:@selector(setMainItem:)
																								 keyEquivalent:@""];
		}
		[theMenu addItem:mainItem];
		[mainItem release];
	}
	
	//--------- rename item
	if ([selectedItem isKindOfClass:[ProjectItemEntity class]]) {
		NSMenuItem *renameItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Rename \u201c%@\u201d", itemName]
																												action:@selector(renameItem:)
																								 keyEquivalent:@""];
		[theMenu addItem:renameItem];
		[renameItem release];
	}
	
	//--------- remove item
	NSMenuItem *removeItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Remove \u201c%@\u201d", itemName]
																											action:@selector(removeItem:)
																							 keyEquivalent:@""];
	[theMenu addItem:removeItem];
	[removeItem release];
	
  //--------- Reveal in Finder
	if ([selectedItem isKindOfClass:[FileEntity class]] || 
      ([selectedItem isKindOfClass:[FolderEntity class]] && [selectedItem valueForKey:@"pathOnDisk"]) ) {
    NSString *path = [selectedItem valueForKey:@"pathOnDisk"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
      NSMenuItem *revealItem = [[NSMenuItem alloc] initWithTitle:@"Reveal in Finder"
                                                          action:@selector(revealItem:)
                                                   keyEquivalent:@""];
      [theMenu addItem:revealItem];
      [revealItem release];
    }
		
  }
  
  //--------- Locate on disk
  if ([selectedItem isKindOfClass:[FileEntity class]]){
    //--------- locate item
		NSFileManager *fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:[selectedItem valueForKey:@"pathOnDisk"]]) {
			[theMenu addItem:[NSMenuItem separatorItem]];
			NSMenuItem *locateItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Locate '%@' on disk", itemName]
																													action:@selector(locateItem:) 
																									 keyEquivalent:@""];
			[theMenu addItem:locateItem];
			[locateItem release];
			[theMenu addItem:[NSMenuItem separatorItem]];
		}
	}
	
	//--------- New Subfolder
	if ([selectedItem isKindOfClass:[FolderEntity class]]) {
		NSMenuItem *newSubfolder = [[NSMenuItem alloc] initWithTitle:@"New Folder"
																													action:@selector(newSubfolder:)
																									 keyEquivalent:@""];
		[theMenu addItem:newSubfolder];
		[newSubfolder release];
	}
	
	
	//--------- New TeX file
	
	//--------- Add menu
	
	return theMenu;        
}

- (IBAction) newSubfolder:(id)sender
{
	NSManagedObjectContext *moc = [treeController managedObjectContext];
	
	NSManagedObject *newFolder = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Folder"
																																									 inManagedObjectContext:moc]
																				insertIntoManagedObjectContext:moc];
	[newFolder setValue:[NSString stringWithFormat:@"New Folder %02d", [[treeController flattenedContent] count]]
							 forKey:@"name"];
		
	[treeController addObject:newFolder];
	[self editColumn:0 row:[self selectedRow] withEvent:nil select:YES];
	[newFolder release];
}

- (IBAction) setMainItem:(id)sender
{
	ProjectEntity *project = [treeController project];
	if ([project valueForKey:@"mainFile"] == selectedItem) {
		[project setValue:nil forKey:@"mainFile"];
	} else {
		[project setValue:selectedItem forKey:@"mainFile"];
	}
	[self setNeedsDisplay:YES];
}

- (IBAction) revealItem:(id)sender
{
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSString *fullpath = [selectedItem valueForKey:@"pathOnDisk"];
	[ws selectFile:fullpath inFileViewerRootedAtPath:[fullpath stringByDeletingLastPathComponent]];
}

- (IBAction) renameItem:(id)sender
{
	if ([mainDocument respondsToSelector:@selector(renameItemAtRow:)]) {		
		[mainDocument renameItemAtRow:selectedRow];
	}
//	[treeController renameItemAtRow:selectedRow];
//	[self editColumn:0 row:selectedRow withEvent:nil select:YES];
}


- (IBAction) removeItem:(id)sender
{
	[treeController remove:self];
}

- (IBAction) locateItem:(id)sender
{
	// get user to choose file
	NSOpenPanel *openPanel = [NSOpenPanel openPanel]; 
	if ([selectedItem isKindOfClass:[FolderEntity class]]) {
		[openPanel setCanChooseFiles:NO];
		[openPanel setCanChooseDirectories:YES];
	} else {
		[openPanel setCanChooseFiles:YES];
		[openPanel setCanChooseDirectories:NO];
	}
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	
	SEL select = @selector(locateItemDidEnd:returnCode:contextInfo:);
	[openPanel beginSheetForDirectory:nil
															 file:nil 
										 modalForWindow:[[[NSDocumentController sharedDocumentController] currentDocument] windowForSheet]
											modalDelegate:self 
										 didEndSelector:select
												contextInfo:nil];
	
	
}

- (void)locateItemDidEnd:(NSSavePanel*)savePanel 
											returnCode:(NSInteger)returnCode
										 contextInfo:(void*)context
{
	if (returnCode == NSCancelButton) 
		return;
	
	NSString *path = [savePanel filename];
	
	// set the path to the item
	[selectedItem setValue:path forKey:@"filepath"];
	
}	

//- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal 
//{
////  NSLog(@"draggingSourceOperationMaskForLocal: %d", isLocal);
//  if (isLocal) return NSDragOperationMove;
//  else return NSDragOperationCopy | NSDragOperationLink;
//}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
//  NSLog(@"prepareForDragOperation: %d", dragLeftView);
  if (dragLeftView)
    return NO;
  
  return [super prepareForDragOperation:sender];
}

- (void)draggingEnded:(id < NSDraggingInfo >)sender
{
//  NSLog(@"Dragging ended");
  if (dragLeftView) {
    [self reloadData];
  }
  dragLeftView = NO;
  [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender 
{
//  NSLog(@"performDragOperation: %d", dragLeftView);
  if (dragLeftView)
    return NO;
  
  return [super performDragOperation:sender];
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
  dragLeftView = YES;
  
//  NSLog(@"Dragging from %@", sender);
  NSPasteboard *pboard = [sender draggingPasteboard];
//  NSLog(@"Dragging exited %@", [pboard types]);
  
  NSArray *droppedIndexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:[[sender draggingPasteboard] dataForType:OutlineViewNodeType]];
  
//  NSFileManager *fm = [NSFileManager defaultManager];
  
  // collect array of file paths
  NSMutableArray *paths = [NSMutableArray array];
  
  for (NSIndexPath *indexPath in droppedIndexPaths) {      
    NSManagedObject *item = [[treeController nodeAtIndexPath:indexPath] representedObject];
    if ([item isKindOfClass:[FileEntity class]]) {
      NSString *path = [item valueForKey:@"pathOnDisk"];
      [paths addObject:path];
    }
  }
  
  [pboard setPropertyList:paths forType:NSFilenamesPboardType];
  
//  [pboard writeObjects:paths forType:NSFilenamesPboardType];
  
//  NSString *fileString = @"";
//  for (NSIndexPath *indexPath in droppedIndexPaths) {      
//    NSManagedObject *item = [[treeController nodeAtIndexPath:indexPath] representedObject];
//    if ([item isKindOfClass:[FileEntity class]]) {
//      NSString *filename = [item valueForKey:@"filepath"];
//      NSString *path = [item valueForKey:@"pathOnDisk"];
//      CFStringRef fileExtension = (CFStringRef) [path pathExtension];
////      NSLog(@"Extension %@", fileExtension);
//      CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
////      NSLog(@"UTI %@, %d", fileUTI, UTTypeConformsTo(fileUTI, kUTTypeImage));
//      if (UTTypeConformsTo(fileUTI, kUTTypeImage) || UTTypeConformsTo(fileUTI, kUTTypePDF)) {
//        NSString *str = [NSString stringWithFormat:@"\\begin{figure}[htbp]\n\\centering\n\\includegraphics[width=1.0\\textwidth]{%@}\n\\caption{My Nice Figure.}\n\\label{fig:myfigure}\n\\end{figure}\n", filename];
//        fileString = [fileString stringByAppendingString:str];
//      } else {
//        fileString = [fileString stringByAppendingFormat:@"\\input{%@}\n", filename];
//      }
//      
//    }
//  }
//  
//  
//  [pboard setString:fileString forType:NSPasteboardTypeString];
  //  [self setFile:[[pboard propertyListForType:NSFilenamesPboardType]objectAtIndex:0]];
  
}


@end

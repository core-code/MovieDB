//
//  IMDBSheetController.m
//
//  Created by CoreCode on 24.10.09.
/*	Copyright (c) 2005 - 2012 CoreCode
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "IMDBSheetController.h"
#import "InfoHelper.h"

@implementation IMDBSheetController

- (void)awakeFromNib
{
	//[imdbTableView setTarget:self];
	[imdbTableView setDoubleAction:@selector(selectAction:)];
	
	[super awakeFromNib];
}	

#pragma mark *** IBAction action-methods ***

- (IBAction)lookupAction:(id)sender
{
	[imdbTitleTextField setStringValue:[[movieArrayController selection] valueForKey:@"title"]];
	
	[NSApp beginSheet:imdbSheetWindow modalForWindow:[owner windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];

	[self searchAgainAction:self];
}

- (IBAction)searchAgainAction:(id)sender
{
	[progressIndicator startAnimation:self];
	
	if ([sender isKindOfClass:[NSString class]])
	{
		[imdbTitleTextField setStringValue:sender];
		[NSApp beginSheet:imdbSheetWindow modalForWindow:[owner windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
	
	if (answers != nil)
	{
		[answers release];
		answers = nil;
	}
	
	answers = [[imdb performSelector:@selector(searchForTitle:) withObject:[imdbTitleTextField stringValue]] retain];
	
	[imdbTableView reloadData];
	
	[progressIndicator stopAnimation:self];
}

- (IBAction)selectAction:(id)sender
{
	if ([[sender title] isEqualToString:@"Select"])
	{
		NSNumber *num;
		if ([imdbButtonCell state] == NSOnState)
		{		
			num = [[answers objectAtIndex:1] objectAtIndex:[imdbTableView selectedRow]];
		}
		else
		{
			int imdbNumber = [[imdbDefineTextField stringValue] intValue];
			if (imdbNumber == 0)
			{
				NSArray *list = [NSArray arrayWithArray:[[imdbDefineTextField stringValue] componentsSeparatedByString:@"/"]];
				
				for (NSString *component in list)
				{
					if ([component hasPrefix:@"tt"])
					{
						imdbNumber = [[component substringFromIndex:2] intValue];
						break;
					}
				}
				
				if (imdbNumber == 0)
				{
					NSBeep();
					return;
				}
			}
			[defineButtonCell setState:NSOffState];
			[imdbButtonCell setState:NSOnState];
			num = [NSNumber numberWithInt:imdbNumber];
		}
		
		[NSApp endSheet:imdbSheetWindow];
		[imdbSheetWindow orderOut:self];
		
		
		[owner doProgressSheet:YES];
		
		[InfoHelper retrieveInfo:num forMovie:[movieArrayController selection]];
		
		[movieArrayController rearrangeObjects];
		[owner tableViewSelectionDidChange:nil];

		[owner doProgressSheet:NO];
	}
	else
	{
		[NSApp endSheet:imdbSheetWindow];
		[imdbSheetWindow orderOut:self];	
	}
	
	[answers release];
	answers = nil;
}

- (IBAction)openAction:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.imdb.com"]];
}

#pragma mark *** NSTableDataSource protocol-methods ***

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [(NSArray *)[answers objectAtIndex:0] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [[answers objectAtIndex:0] objectAtIndex:row];
}
@end
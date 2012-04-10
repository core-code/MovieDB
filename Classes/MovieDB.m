//
//  MovieDB.m
//  MovieDB
//
//  Created by CoreCode on 07.11.05.
/*	Copyright (c) 2005 - 2012 CoreCode
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "JMApp.h"
#import "MovieDB.h"
#import "CrashReporter.h"

@implementation MovieDB

+ (void)initialize
{
	TimeValueTransformer *timetransformer = [[[TimeValueTransformer alloc] init] autorelease];
	SizeValueTransformer *sizetransformer = [[[SizeValueTransformer alloc] init] autorelease];
	LanguageValueTransformer *languagetransformer = [[[LanguageValueTransformer alloc] init] autorelease];
	RatingValueTransformer *ratingtransformer = [[[RatingValueTransformer alloc] init] autorelease];
	TitleLinkValueTransformer *titlelinktransformer = [[[TitleLinkValueTransformer alloc] init] autorelease];
	PeopleLinkValueTransformer *peoplelinktransformer = [[[PeopleLinkValueTransformer alloc] init] autorelease];
	CastLinkValueTransformer *castlinktransformer = [[[CastLinkValueTransformer alloc] init] autorelease];
	ImageDataValueTransformer *imagedatatransformer = [[[ImageDataValueTransformer alloc] init] autorelease];
	AudioCodecValueTransformer *audiocodectransformer = [[[AudioCodecValueTransformer alloc] init] autorelease];

	[NSValueTransformer setValueTransformer:castlinktransformer forName:@"CastLinkValueTransformer"];
	[NSValueTransformer setValueTransformer:peoplelinktransformer forName:@"PeopleLinkValueTransformer"];
	[NSValueTransformer setValueTransformer:titlelinktransformer forName:@"TitleLinkValueTransformer"];
	[NSValueTransformer setValueTransformer:ratingtransformer forName:@"RatingValueTransformer"];
	[NSValueTransformer setValueTransformer:languagetransformer forName:@"LanguageValueTransformer"];
	[NSValueTransformer setValueTransformer:timetransformer forName:@"TimeValueTransformer"];
	[NSValueTransformer setValueTransformer:sizetransformer forName:@"SizeValueTransformer"];
	[NSValueTransformer setValueTransformer:imagedatatransformer forName:@"ImageDataValueTransformer"];
	[NSValueTransformer setValueTransformer:audiocodectransformer forName:@"AudioCodecValueTransformer"];


	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];

	[defaultValues setObject:[NSNumber numberWithInt:1] forKey:kAgreedToIMDBConditionsKey];
	[defaultValues setObject:[NSNumber numberWithInt:1] forKey:kBetaNoticeKey];
	[defaultValues setObject:[NSNumber numberWithInt:2] forKey:kUpdatecheckMenuindexKey];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (id)init
{
	self = [super init];

	if (self != nil)
	{
		NSString *pluginPath = [[NSBundle mainBundle] pathForResource:@"IMDB" ofType:@"plugin"];
		NSBundle *pluginBundle = [NSBundle bundleWithPath:pluginPath];

		[pluginBundle load];

		if (pluginBundle)
		{
			Class imdbclass = [pluginBundle principalClass];
			if (imdbclass)
			{
				imdb = [[imdbclass alloc] init];
			}
		}
	}
	return self;
}

- (void)awakeFromNib
{
	if ([[NSUserDefaults standardUserDefaults] integerForKey:kAgreedToIMDBConditionsKey])
	{
		[NSApp activateIgnoringOtherApps:YES];

		[NSApp runModalForWindow:imdbAgreementWindow];

		[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kAgreedToIMDBConditionsKey];
	}

	if ([[NSUserDefaults standardUserDefaults] integerForKey:kBetaNoticeKey])
	{
		[NSApp activateIgnoringOtherApps:YES];

		if (NSRunAlertPanel(@"MovieDB", @"Welcome to MovieDB. Please note that MovieDB is still in beta status and only provided as a technology preview for advanced users. There are bugs, features are missing and the saved files probably won't be forward compatible. USE AT YOUR OWN RISK!", @"Understood", @"I want out!", nil) != NSOKButton)
			[NSApp terminate:self];

		[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kBetaNoticeKey];
		[[NSDocumentController sharedDocumentController] newDocument:self];
	}


	CheckAndReportCrashes(@"crashreports@corecode.at", [NSArray arrayWithObjects:@"ValueTransformer", @"[Movie", @"[IMDB", @"[Info", @"[SU", @"[NSException", @"uncaught exception", nil]);


	plugins = [[NSMutableDictionary alloc] init];
	NSArray *bundlePaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"plugin" inDirectory:@"PlugIns"];

	for (NSString *bundlePath in bundlePaths)
	{
		NSMenuItem *mi = [[NSMenuItem alloc] init];
		NSString *title = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
		[mi setTitle:title];
		[mi setTarget:self];
		[mi setAction:@selector(pluginAction:)];
		[pluginMenu addItem:mi];

		NSBundle *pluginBundle = [NSBundle bundleWithPath:bundlePath];

		if (pluginBundle && [pluginBundle load])
		{
			Class pluginclass = [pluginBundle principalClass];
			if (pluginclass)
			{
				id plugin = [[pluginclass alloc] init];

				[plugins setObject:plugin forKey:title];

				[plugin release];
			}
		}
	}
}

- (void)dealloc
{
	[super dealloc];

	[imdb release];
	imdb = nil;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}


#pragma mark *** IBAction action-methods ***

- (IBAction)pluginAction:(id)sender
{
	[[[NSDocumentController sharedDocumentController] currentDocument] pluginAction:[plugins objectForKey:[sender title]]];
}

- (IBAction)lookupAction:(id)sender
{
	[[[NSDocumentController sharedDocumentController] currentDocument] lookupAction:sender];
}

- (IBAction)refreshAction:(id)sender
{
	[[[NSDocumentController sharedDocumentController] currentDocument] refreshAction:sender];
}

- (IBAction)refreshAllAction:(id)sender
{
	[[[NSDocumentController sharedDocumentController] currentDocument] refreshAllAction:sender];
}

- (IBAction)updatecheckAction:(id)sender
{
	[self setUpdateCheck:[sender indexOfSelectedItem]];
}

- (IBAction)checkForUpdatesAction:(id)sender
{
	if (updater)
		[updater checkForUpdates:self];
	else
		NSLog(@"Warning: the sparkle updater is not available!");
}

- (IBAction)preferencesAction:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)acceptIMDBAction:(id)sender
{
	[NSApp stopModal];
	[imdbAgreementWindow close];
}

- (IBAction)declineIMDBAction:(id)sender
{
	[NSApp terminate:self];
}

@end
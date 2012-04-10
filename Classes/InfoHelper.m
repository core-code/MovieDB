//
//  InfoHelper.m
//  MovieDB
//
//  Created by CoreCode on 24.10.09.
/*	Copyright (c) 2005 - 2012 CoreCode
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "InfoHelper.h"
#import "HostInformation.h"


@implementation InfoHelper

+ (void)retrieveInfo:(NSNumber *)title forMovie:(id)movie
{
	NSDictionary *info = [imdb performSelector:@selector(getInfoForID:) withObject:title];
	NSArray *itemarray = [NSArray arrayWithObjects:@"imdb_poster", @"imdb_rating", @"imdb_title", @"imdb_plot", @"imdb_year", @"imdb_director", @"imdb_writer", @"imdb_genre", @"imdb_cast", nil];
	
	for (uint32_t v = 0; v < [itemarray count]; v++) // set all items to nil
		[movie setValue:nil forKey:[itemarray objectAtIndex:v]];	
	
	if ([info objectForKey:@"imdb_cover_url"] != nil)
	{
		NSImage *image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[info objectForKey:@"imdb_cover_url"]]];

		[movie setValue:[image TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1.0] forKey:@"imdb_poster"];
		[image release];
	}
	
	[movie setValue:title forKey:@"imdb_id"];	
	[movie setValue:[info objectForKey:@"imdb_rating"] forKey:@"imdb_rating"];
	[movie setValue:[info objectForKey:@"imdb_title"] forKey:@"imdb_title"];
	[movie setValue:[info objectForKey:@"imdb_plot"] forKey:@"imdb_plot"];
	[movie setValue:[NSNumber numberWithInt:[[info objectForKey:@"imdb_year"] intValue]] forKey:@"imdb_year"];	
	
	NSArray *valuearray = [NSArray arrayWithObjects:@"imdb_writer", @"imdb_director", @"imdb_genre", @"imdb_cast", nil];
	
	for (uint32_t v = 0; v < [valuearray count]; v++)
	{
		NSArray *array = [info objectForKey:[valuearray objectAtIndex:v]];
		NSMutableString *string = [NSMutableString string];
		
		for (uint32_t i = 0; i < [array count]; i++)
		{
			[string appendString:[array objectAtIndex:i]];
			if ([array count] > i + 1)
				[[valuearray objectAtIndex:v] isEqualToString:@"imdb_cast"] ? [string appendString:@"\n"] : [string appendString:@", "];
		}		
		[movie setValue:string forKey:[valuearray objectAtIndex:v]];
	}
	
}


+ (char)addPathToObject:(NSManagedObject *)obj withPath:(NSString *)path andFilesController:(NSArrayController *)movieFilesArrayController
{
	NSString *bsdPath = @"";
	long byterate = 0;

	// 1. determine the type of object to add
	BOOL isVCD = FALSE;
	BOOL isSVCD = FALSE;
	BOOL isDVD = FALSE;
	BOOL isFile = TRUE;
	BOOL isDir = FALSE;
	
	if (([path length] > 9)&& [path hasPrefix:@"/Volumes/"])
	{
		NSRange range = [[path substringFromIndex:9] rangeOfString:@"/"];
		
		if (range.location == NSNotFound)
		{			
			if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingString:@"/VCD/"] isDirectory:&isDir] && isDir)
				isVCD = TRUE;
			else if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingString:@"/SVCD/"] isDirectory:&isDir] && isDir)
				isSVCD = TRUE;
			else if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingString:@"/VIDEO_TS/"] isDirectory:&isDir] && isDir)
				isDVD = TRUE;
			
			isFile = FALSE;
			
			bsdPath = [HostInformation bsdPathForVolume:[path substringFromIndex:9]];
		}
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
		return 1;
	
	// 2. run midentify on the movie to add
	id newObject = [movieFilesArrayController newObject];
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSTask *task = [[NSTask alloc] init];	
	NSPipe *pipe = [NSPipe pipe];
	NSFileHandle *fileHandle = [pipe fileHandleForReading];
	
	[task setCurrentDirectoryPath: resourcePath];
	[task setLaunchPath: [resourcePath stringByAppendingPathComponent:@"midentify"]];
	[task setStandardOutput: pipe];	
	
	if (isFile == TRUE)
		[task setArguments: [NSArray arrayWithObjects: path, nil]];
	else if (isVCD == TRUE)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingString:@"/MPEGAV/AVSEQ01.DAT"]])
			[task setArguments: [NSArray arrayWithObjects: [path stringByAppendingString:@"/MPEGAV/AVSEQ01.DAT"], nil]];
		else
			[task setArguments: [NSArray arrayWithObjects: @"vcd://1", @"-cdrom-device", bsdPath, nil]];
	}	
	else if (isDVD == TRUE)
		[task setArguments: [NSArray arrayWithObjects: @"dvd://1", @"-dvd-device", bsdPath, nil]];	
	else if (isSVCD == TRUE)
		[task setArguments: [NSArray arrayWithObjects: @"vcd://1", @"-cdrom-device", bsdPath, nil]];
	
	[task launch];
	[task waitUntilExit];
	
	NSData *data = [fileHandle readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
	NSArray *list = [string componentsSeparatedByString:@"\n"];
	
	[fileHandle closeFile];
	[task terminate];	
	[string release];
	[task release];
	
	// 3. parse output of midentify
	for (uint32_t i = 0; i < [list count]; i++)
	{
		NSArray *components = [[list objectAtIndex:i] componentsSeparatedByString:@"="];
		
		if ([[components objectAtIndex:0] isEqualToString:@"ID_DEMUXER"])
		{
			if (([obj valueForKey:@"file_container"] == nil) || ([(NSString *)[obj valueForKey:@"file_container"] length] == 0))
				[obj setValue:[components objectAtIndex:1] forKey:@"file_container"];
		}
		else if ([[components objectAtIndex:0] isEqualToString:@"ID_VIDEO_FORMAT"])
		{
			if (([obj valueForKey:@"file_video_codec"] == nil) || ([(NSString *)[obj valueForKey:@"file_video_codec"] length] == 0))
			{
				if ([[components objectAtIndex:1] isEqualToString:@"0x10000001"])
					[obj setValue:@"MPG1" forKey:@"file_video_codec"];				
				else if ([[components objectAtIndex:1] isEqualToString:@"0x10000002"])
					[obj setValue:@"MPG2" forKey:@"file_video_codec"];								
				else
					[obj setValue:[components objectAtIndex:1] forKey:@"file_video_codec"];
			}
		}
		else if ([[components objectAtIndex:0] isEqualToString:@"ID_VIDEO_WIDTH"])
		{
			if (([obj valueForKey:@"file_video_width"] == nil) || ([obj valueForKey:@"file_video_width"] == 0))
				[obj setValue:[NSNumber numberWithInt:[[components objectAtIndex:1] intValue]] forKey:@"file_video_width"];
		}
		else if ([[components objectAtIndex:0] isEqualToString:@"ID_VIDEO_HEIGHT"])
		{
			if (([obj valueForKey:@"file_video_height"] == nil) || ([obj valueForKey:@"file_video_height"] == 0))				
				[obj setValue:[NSNumber numberWithInt:[[components objectAtIndex:1] intValue]] forKey:@"file_video_height"];
		}
		else if ([[components objectAtIndex:0] isEqualToString:@"ID_AUDIO_FORMAT"])
		{
			if (([obj valueForKey:@"file_audio_codec"] == nil) || ([(NSString *)[obj valueForKey:@"file_audio_codec"] length] == 0))
				[obj setValue:[components objectAtIndex:1] forKey:@"file_audio_codec"];
		}
		else if ([[components objectAtIndex:0] isEqualToString:@"ID_LENGTH"])
		{
			int length = [[components objectAtIndex:1] intValue];
			
			if (length > 0)
				[newObject setValue:[NSNumber numberWithInt:length] forKey:@"length"];
		}
		else if ([[components objectAtIndex:0] isEqualToString:@"ID_VIDEO_BITRATE"])
		{
			static BOOL addedVideo = FALSE;
			
			if (!addedVideo)
			{
				byterate += [[components objectAtIndex:1] intValue] / 8;
				addedVideo = TRUE;
			}
		}
		else if ([[components objectAtIndex:0] isEqualToString:@"ID_AUDIO_BITRATE"])
		{
			static BOOL addedAudio = FALSE;
			
			if (!addedAudio)
			{
				byterate += [[components objectAtIndex:1] intValue] / 8;
				addedAudio = TRUE;
			}
		}
	}
	
	// 4. set title if it isn't set already
	if (([obj valueForKey:@"title"] == nil) || ([(NSString *)[obj valueForKey:@"title"] length] == 0) || ([[obj valueForKey:@"title"] isEqualToString:@"Untitled Movie"]))
	{
		NSString *title = [[path stringByDeletingPathExtension] lastPathComponent]; // this heuristic for cutting of postfixes like (cd 1) could be improved
		NSArray *components = [title componentsSeparatedByString:@" ("];
		title = [components objectAtIndex:0];
		
		title = [title stringByReplacingOccurrencesOfString:@"." withString:@" "];
		title = [title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
		title = [title stringByReplacingOccurrencesOfString:@"cd1" withString:@""];
		title = [title stringByReplacingOccurrencesOfString:@"cd2" withString:@""];
		title = [title stringByReplacingOccurrencesOfString:@"CD1" withString:@""];
		title = [title stringByReplacingOccurrencesOfString:@"CD2" withString:@""];
		
		[obj setValue:title forKey:@"title"];		
	}
	// 5. determine size of movie
	if ((isVCD == TRUE) || (isSVCD == TRUE))
	{
		(isVCD == TRUE) ? [obj setValue:[NSNumber numberWithInt:1] forKey:@"file_type"] : [obj setValue:[NSNumber numberWithInt:2] forKey:@"file_type"];
		
		task = [[NSTask alloc] init];	
		
		[task setCurrentDirectoryPath: resourcePath];
		[task setLaunchPath: [resourcePath stringByAppendingPathComponent:@"cdsize"]];
		[task setArguments: [NSArray arrayWithObjects: bsdPath, nil]];
		
		pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];	
		fileHandle = [pipe fileHandleForReading];
		
		[task launch];
		
		data = [fileHandle readDataToEndOfFile];
		
		NSString *str = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		NSArray *list2 = [str componentsSeparatedByString:@"\n"];
		
		long size = 0;
		
		for (uint32_t i = 0; i < [list2 count]; i++)
		{
			size += ([[list2 objectAtIndex:i] intValue] * 1024); // TODO: this doesn't have to be all MBs
		}
		
		[newObject setValue:[NSNumber numberWithInt:size] forKey:@"size"];
		
		[fileHandle closeFile];
		[task terminate];
		[task release];
		[str release];	
	}
	else if (isDVD == TRUE)
	{
		long long size = 0;
		NSString *file, *fpath;
		NSDictionary *fattrs;
		
		[obj setValue:[NSNumber numberWithInt:3] forKey:@"file_type"];	
		fpath = [path stringByAppendingString:@"/VIDEO_TS/"];
		
		NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath: fpath];
		while ((file = [enumerator nextObject]))
		{
			fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[fpath stringByAppendingString:file] error:NULL];
			
			if (fattrs)
				size += [fattrs fileSize];			
		}
		fpath = [path stringByAppendingString:@"/AUDIO_TS/"];
		enumerator = [[NSFileManager defaultManager] enumeratorAtPath: fpath];
		while ((file = [enumerator nextObject]))
		{
			fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[fpath stringByAppendingString:file] error:NULL];
			if (fattrs)
				size += [fattrs fileSize];			
		}
		
		[newObject setValue:[NSNumber numberWithInteger:(NSInteger)(size / (long long)1024)] forKey:@"size"];
	}
	else if (isFile == TRUE)
	{
		[obj setValue:[NSNumber numberWithInt:0] forKey:@"file_type"];
		NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
		
		if (fattrs)
			[newObject setValue:[NSNumber numberWithInt:[[fattrs objectForKey:NSFileSize] longValue] / 1024] forKey:@"size"];
	}
	
	// 6. calculate length if it wasn't given
	if ((([newObject valueForKey:@"length"] == nil) || ([newObject valueForKey:@"length"] == 0)) && (byterate != 0))
	{
		int calulatedLength = [[newObject valueForKey:@"size"] longValue] / (byterate / 1024);
		
		[newObject setValue:[NSNumber numberWithInt:calulatedLength] forKey:@"length"];
	}	

	// 7. set remaining values and add new movie object
	[newObject setValue:[[path stringByDeletingPathExtension] lastPathComponent] forKey:@"name"];
	
	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	NSImage *smallIcon = [[[NSImage alloc] initWithSize:NSMakeSize(16, 16)] autorelease];
	[smallIcon lockFocus];
	[icon setScalesWhenResized:YES];
	[icon setSize:NSMakeSize(16, 16)];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[icon compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	[smallIcon unlockFocus];
	
	[newObject setValue:[smallIcon TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0.5] forKey:@"icon"];
	[newObject setValue:[path stringByDeletingLastPathComponent] forKey:@"path"];
	
	[movieFilesArrayController addObject:newObject];
	
	[newObject release]; // "new" -- returned with retain count of 1
	
	return 0;
}
@end
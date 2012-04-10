//
//  Movie.h
//  MovieDB
//
//  Created by CoreCode on 19.12.05.
/*	Copyright (c) 2005 - 2012 CoreCode
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

@interface Movie : NSManagedObject
{
	NSInteger totalLength;
	NSInteger totalSize;	
}

@property (readonly) NSInteger totalLength;
@property (readonly) NSInteger totalSize;

@property (retain) NSString * file_audio_codec;
@property (retain) NSString * file_container;
@property (retain) NSNumber * file_type;
@property (retain) NSString * file_video_codec;
@property (retain) NSNumber * file_video_height;
@property (retain) NSNumber * file_video_width;
@property (retain) NSString * imdb_cast;
@property (retain) NSString * imdb_director;
@property (retain) NSString * imdb_genre;
@property (retain) NSNumber * imdb_id;
@property (retain) NSString * imdb_plot;
@property (retain) NSData * imdb_poster;
@property (retain) NSNumber * imdb_rating;
@property (retain) NSString * imdb_title;
@property (retain) NSString * imdb_writer;
@property (retain) NSNumber * imdb_year;
@property (retain) NSNumber * language;
@property (retain) NSNumber * rating;
@property (retain) NSString * title;
@property (retain) NSSet* files;
@end

@interface Movie (CoreDataGeneratedAccessors)
- (void)addFilesObject:(NSManagedObject *)value;
- (void)removeFilesObject:(NSManagedObject *)value;
- (void)addFiles:(NSSet *)value;
- (void)removeFiles:(NSSet *)value;
@end
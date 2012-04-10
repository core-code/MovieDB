#
#  IMDB.py
#  MovieDB
#
#  Created by CoreCode on 07.11.05.
#	Copyright (c) 2005 - 2012 CoreCode
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


from Foundation import *
import sys

try:
	import imdb
except ImportError:
	print 'You need to install the IMDbPY package!'
	sys.exit(1)

class IMDB (NSObject):
	def searchForTitle_(self, obj):
		titles = []
		imdbids = []
		
		i = imdb.IMDb()

		try:
			results = i.search_movie(obj)
		except imdb.IMDbError, e:
			print "searchForTitle_: Probably you're not connected to Internet.  Complete error report:"
			print e
			return

		for movie in results:
			titles.append(movie['long imdb title'])
			imdbids.append(int(i.get_imdbID(movie)))
		
		return [titles, imdbids]

	def getInfoForID_(self, obj):
		info = {}

		i = imdb.IMDb()

		try:
			movie = i.get_movie(obj)
		except imdb.IMDbError, e:
			print "getInfoForID_: Probably you're not connected to Internet.  Complete error report:"
			print e
			sys.exit(3)
		
		if not movie:
			print 'It seems that there\'s no movie with imdbID "%s"' % obj
			return
			
		#genres
		genres = movie.get('genres')
		if genres:
			info['imdb_genre'] = genres
		
		#title
		title = movie.get('long imdb canonical title', u'')
		if title:
			info['imdb_title'] = title
		
		#year
		year = movie.get('year')
		if year:
			info['imdb_year'] = year
					
		#rating
		rating = movie.get('rating')
		if rating:			
			info['imdb_rating'] = rating

		#coverURL
		cover = movie.get('cover url')
		if cover:			
			info['imdb_cover_url'] = cover
			
		#directors		
		info['imdb_director'] = []
		directors = movie.get('director')
		if directors:
			for director in directors:
				info['imdb_director'].append(director['name'])
				
		#writers		
		info['imdb_writer'] = []
		writers = movie.get('writer')
		if writers:
			for writer in writers:
				info['imdb_writer'].append(writer['name'])

		#cast
		info['imdb_cast'] = []
		actors = movie.get('cast')
		if actors:
			for actor in actors:
				if actor.currentRole:
					info['imdb_cast'].append('%s (%s)' % (actor['name'], actor.currentRole))
				else:
					info['imdb_cast'].append(actor['name'])
		
		#plot
		plot = movie.get('plot')
		if plot:
			plot = plot[0]
			i = plot.find('::')
			if i != -1:
				plot = plot[:i]
			info['imdb_plot'] = plot
		else:
			po = movie.get('plot outline')
			i.update(movie, 'synopsis') # fetch the 'synopsis' data set.
			s = movie.get('synopsis')
			if po:
				if (len(s) < 700):
					info['imdb_plot'] = po + "\n\n" + s
				else:
					info['imdb_plot'] = po
			elif (len(s) < 700):
				info['imdb_plot'] = s
					
		return info
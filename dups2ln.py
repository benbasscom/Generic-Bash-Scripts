#!/usr/bin/env python
# removes dupes by symlinking them.
# taken from http://www.libertypages.com/clarktech/?p=350
# to run select the directories you wish to scan; ie ./dups2ln.py  dir1 dir2 dir3
 
import dupes
import os
 
def make_ln( file_list ):
	main_file = file_list[0]	# make the first file the "master" file
	file_list = file_list[1:]	# all the files we'll replace with links
 
	for del_f in file_list:
		os.system("ln -sf '" + main_file + "' '" + del_f +"'")		# Use this for symlinks
# 		os.system("ln -f '" + main_file + "' '" + del_f +"'")		# Use this for hardlinks
 
def convert(paths):
	# paths is a list of paths to convert duplicates to links
 
	d = dupes.dupfinder()
	d.add_dirs(paths)
 
	for dups in d.find_dups():
		make_ln( dups )
 
 
if __name__ == '__main__':
	import sys
 
	convert(sys.argv[1:])
	sys.exit( 1 )
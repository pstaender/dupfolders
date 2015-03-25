# Dupfolders
## Finds duplicate folders on UNIX systems

The script checks for duplicate folder sizes. This includes checking also their file content (sha1 hashed).

For now it's running exclusively on UNIX systems (tested on Ubtuntu and Mac OS X so far) since it's using the `du` and `find` commands.

** Dupfolders does not modify

### Usage / Syntax

```sh
  $ dupfolders.rb [ options ] path
```

A good way to start measuring a folder could be:

```sh
  $ dupfolders.rb --excludeFolders=.git --displayParentFolderSize=true ~/Desktop > duplicates.log
```

### Options

  * `--progress`: true|false (displays progress on stderr, default is `true`)
  * `--minFolderSize`: int.value (sizes will be displayed + interpreted in kbyte, default is `1`)
  * `--minFilesCount`: int.value (ignore folders with less than this files count, default is `1`)
  * `--excludeFolders`: comma seperated string (exclude folders with this name from comparing, e.g. `.git,.temp`)
  * `--displayFolderSizes`: true|false (display folder sizes in kbyte in the summary, default is `true`)
  * `--sortBySize`: desc|asc (sort found folders by their size, default is `desc`)
  * `--displayParentFolderSize`: true|false (display parent folder sizes to duplicate folders, default is `false`)

### Exclude specific files, e.g. .DS_Store

Although folders can be excluded (see option `--excludeFolders` above), files cannot.

Most os store meta informations in hidden files: `.DS_Store` on Mac OS, `Desktop.ini` on Windows for instance. Unfortunately there is now option to exclude specific files, because they are included in measuring the folder sizes.

A "workaround" would simply to delete those files (or move them somewhere else and replace with a symbolic link) to get a adequate folder comparing.

### TODO

  * more OS independent
  * consider parent folders and find the most above lying folder with duplicates

### License

See `LICENSE` file

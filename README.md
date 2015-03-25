# Dupfolders
## Finds duplicate folders on UNIX systems

The script checks for duplicate folder sizes. This includes checking also their file content (sha1 hashed).

For now it's running exclusively on UNIX systems (tested on Ubtuntu and Mac OS X so far) since it's using the `du` and `find` commands.

### Usage / Syntax

```sh
  $ ./dupfolders.rb [ options ] path
```

So a good way to start to measure a larger folder could be:

```sh
  $ ./dupfolders.rb --excludeFolders=.git --displayParentFolderSize=true ~/Desktop > du
```

### Options

  * `--progress`: true|false (displays progress on stderr, default is `true`)
  * `--minFolderSize`: int.value (sizes will be displayed + interpreted in kbyte, default is `1`)
  * `--minFilesCount`: int.value (ignore folders with less than this files count, default is `1`)
  * `--excludeFolders`: comma seperated string (exclude folders with this name from comparing, e.g. `.git,.temp`)
  * `--displayFolderSizes`: true|false (display folder sizes in kbyte in the summary, default is `true`)
  * `--sortBySize`: desc|asc (sort found folders by their size, default is `desc`)
  * `--displayParentFolderSize`: true|false (display parent folder sizes to duplicate folders, default is `false`)

### TODO

  * more OS independent
  * consider parent folders and find the most above lying folder with duplicates

### License

See `LICENSE` file

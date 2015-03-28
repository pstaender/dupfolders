#!/usr/bin/ruby

require "digest"

# Default Options
options = {
  "progress" => "true",
  "minFolderSize" => 1, #kbyte
  "minFilesCount" => 1,
  "excludeFolders" => '',#.split(','),
  "displayFolderSizes" => "true",
  "sortBySize" => "desc",
  "displayParentFolderSize" => "false",
  "displayIntermediateResults" => "false",
}

class String

  def to_bool
    case
    when self == true || self =~ /^(true|t|yes|y|1)$/i
      true
    when self == false || self =~ /^(false|f|no|n|0)$/i
      false
    else
      raise ArgumentError.new "invalid value for Boolean: '#{self}'"
    end
  end

  alias :to_b :to_bool

end

args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]

if ARGV.length < 1 or ARGV[0] == '-h' or ARGV[0] == '--help'
  $stderr.puts "usage: #{File.basename(__FILE__)} [ --#{options.keys.join('= | --')}= ] path"
  $stderr.puts "e.g.:  #{File.basename(__FILE__)} --progress=true --minFolderSize=10 --excludeFolder=.git,.tmp --sortBySize=desc ~/directory_to_check > result.log"
  exit(1)
end

options.merge!(args)
# type casting for specific options values
options['progress'] = options['progress'].to_b
options['displayFolderSizes'] = options['displayFolderSizes'].to_b
options['displayParentFolderSize'] = options['displayParentFolderSize'].to_b
options['displayIntermediateResults'] = options['displayIntermediateResults'].to_b
options['minFolderSize'] = options['minFolderSize'].to_i
options['minFilesCount'] = options['minFilesCount'].to_i
options['excludeFolders'] = options['excludeFolders'].split(',')

root = ARGV[ARGV.length-1]

unless Dir.exists?(root)
  $stderr.puts "Directory '#{root}' doesn't exists"
  exit(1)
end


$stderr.puts "Searching for duplicate folders in '#{root}'"

folderHashes = Hash.new
folderSizes = Hash.new
folderBySizes = Hash.new
folderWithSameSize = Hash.new

def updateProgress(perc, msg = "")
  $stderr.print(perc.to_f.round(2).to_s+"% \t#{msg}\r")
end

# calculate all folder sizes and find folder with same sizes
$stderr.puts "Comparing folder sizes"

folderSize = `du -k #{root}`.strip!

if folderSize
  n = 0
  folders = folderSize.split("\n")
  foldersCount = folders.length.to_f
  folders.each do |folder|
    # check that folder is not be excluded
    ignoreFolder = false
    options["excludeFolders"].each do |excludePattern|
      ignoreFolder = true if folder.include?("/#{excludePattern}/") or folder.index(excludePattern) == 0 or folder.index(excludePattern) == (folder.length - excludePattern.length) or folder == excludePattern
    end
    next if ignoreFolder # folder should be exluded
    n = n+1
    parts = folder.scan(/^(\d+)\s*(.+)*$/)
    if parts[0]
      size = parts[0][0].to_i
      path = parts[0][1]
      filesInFolder = `find '#{path}' -maxdepth 1 -type f`.strip!
      #key = Digest::SHA2.hexdigest(size.to_s)
      if size >= options['minFolderSize'] and filesInFolder and filesInFolder.split("\n").length >= options["minFilesCount"]
        folderSizes[size] = [] if folderSizes[size].nil?
        folderSizes[size].push(path)
        if folderSizes[size].length > 1
          folderWithSameSize[size] = folderSizes[size]
        end
      end
    updateProgress((100/foldersCount)*n) if options["progress"]
    end
  end
else
  $stderr.puts "No folders found"
end

$stderr.puts "Found #{folderWithSameSize.length} folder(s) with identical size"
$stderr.puts "Now looking for identical content (i.e. files). This may take a while..."

hashes = Hash.new
duplicateFolders = Hash.new

n = 0
duplicateFoldersCount = 0
folderWithSameSizeCount = folderWithSameSize.length.to_f
folderWithSameSize.each do |size, folders|
  n += 1
  folders.each do |folder|
    folderHash = ""
    files = `find '#{folder}' -type f`.strip!
    if files then files.split("\n").each do |file|
        begin
          sha1 = Digest::SHA2.file(file).hexdigest
          folderHash += sha1
        rescue Exception => e
          $stderr.puts "Error on hashing file '#{file}': #{e.message}"
        end
      end
    end
    # folder hash is content hash + size
    begin
      folderHash = Digest::SHA2.hexdigest(folderHash+size.to_s)
    rescue Exception => e
      $stderr.puts "Error on building folder hash: #{e.message}"
    end

    hashes[folderHash] = [] if hashes[folderHash].nil?
    hashes[folderHash].push(folder)
    if hashes[folderHash].length > 1
      # we have more than one folder with the same size and the same content
      duplicateFolders[size] = Hash.new if duplicateFolders[size].nil?
      duplicateFolders[size][folderHash] = [] if duplicateFolders[size][folderHash].nil?
      duplicateFoldersCount += hashes[folderHash].length - duplicateFolders[size][folderHash].length
      duplicateFolders[size][folderHash] = hashes[folderHash]
      updateProgress((100/folderWithSameSizeCount)*n, "found #{duplicateFoldersCount} identical folder(s)") if options["progress"]
      puts("(#{size} kbyte)\n#{hashes[folderHash].join("\n")}\n") if options['displayIntermediateResults']
    end
  end
  updateProgress((100/folderWithSameSizeCount)*n, "found #{duplicateFoldersCount} duplicate folder(s)") if options["progress"]
end

# summary

duplicateFoldersCount = 0
sizesSum = 0
parentFolderSizes = Hash.new

puts ""

if duplicateFolders.length > 0
  puts "### Summary ###" if options['displayIntermediateResults']
  duplicateFolders = Hash[duplicateFolders.sort_by{|k,v| k}] if options["sortBySize"]
  duplicateFolders = Hash[duplicateFolders.to_a.reverse] if options["sortBySize"] and options["sortBySize"].downcase == 'desc'
  duplicateFolders.each do |size, hashes|
    sizesSum += size
    hashes.each do |folder, folders|
      duplicateFoldersCount += folders.length
      puts "(#{size} kbyte)" if options["displayFolderSizes"]
      parentFolders = []
      folders.each do |folder|
        puts folder
        if options['displayParentFolderSize']
          parentPath = File.expand_path(folder + '/..')
          if parentFolderSizes[parentPath]
            parentFolderSizeSummary = parentFolderSizes[parentPath]
          else
            parentFolderSizeSummary = parentFolderSizes[parentPath] = `du -hs '#{parentPath}'`
          end
          parentFolderSizeSummary.strip!
          if parentFolderSizeSummary
            parentFolderSizeSummary = "=> #{parentFolderSizeSummary}"
            parentFolders.push(parentFolderSizeSummary)
          end
          #$stderr.puts "du -hs '#{path}'"
          # puts "=> #{parentFolderSize}"
        end
      end
      if options["displayParentFolderSize"]
        parentFolders = parentFolders.uniq
        puts parentFolders.join("\n")
      end
      puts "\n\n"
    end
  end
  $stderr.puts "Found #{duplicateFoldersCount} duplicate folder(s)"
  $stderr.puts "Size: #{sizesSum} kbytes"
else
  $stderr.puts "Found no duplicate folders"
end

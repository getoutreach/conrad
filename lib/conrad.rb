Gem.find_files("conrad/processors/*.rb").each {|file| require file }
Gem.find_files("conrad/formatters/*.rb").each {|file| require file }
Gem.find_files("conrad/emitters/*.rb").each {|file| require file }
Gem.find_files("conrad/*.rb").each {|file| require file }

# :nodoc:
module Conrad
end
